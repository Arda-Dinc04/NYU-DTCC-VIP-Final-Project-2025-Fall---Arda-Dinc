#!/bin/bash

###############################################################################
# SBOM Generator with Dynamic Dependency Capture
# 
# This tool:
# 1. Generates a static SBOM using Syft or Trivy
# 2. Captures dynamically loaded libraries using strace
# 3. Merges dynamic dependencies back into the SBOM
#
# Usage: ./sbom-with-dynamic.sh <target> <command-to-run>
# Example: ./sbom-with-dynamic.sh ./myapp "java -jar myapp.jar"
###############################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-}"
RUN_COMMAND="${2:-}"
OUTPUT_DIR="${SCRIPT_DIR}/output"
TEMP_DIR="${SCRIPT_DIR}/.tmp"
STATIC_SBOM="${TEMP_DIR}/static-sbom.json"
DYNAMIC_LIBS="${TEMP_DIR}/dynamic-libs.json"
FINAL_SBOM="${OUTPUT_DIR}/sbom-with-dynamic.json"
STRACE_LOG="${TEMP_DIR}/strace.log"

# Tools
SBOM_TOOL=""
STRACE_CMD=""

###############################################################################
# Helper Functions
###############################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

cleanup() {
    log_info "Cleaning up temporary files..."
    rm -rf "${TEMP_DIR}"
}

trap cleanup EXIT

###############################################################################
# Check Prerequisites
###############################################################################

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check for SBOM tool
    if command -v syft &> /dev/null; then
        SBOM_TOOL="syft"
        log_success "Found Syft"
    elif command -v trivy &> /dev/null; then
        SBOM_TOOL="trivy"
        log_success "Found Trivy"
    else
        log_error "Neither Syft nor Trivy found. Please install one:"
        echo "  Syft: https://github.com/anchore/syft"
        echo "  Trivy: https://github.com/aquasecurity/trivy"
        exit 1
    fi
    
    # Check for strace/dtruss
    if command -v strace &> /dev/null; then
        STRACE_CMD="strace"
        log_success "Found strace"
    elif command -v dtruss &> /dev/null; then
        STRACE_CMD="dtruss"
        log_warn "Using dtruss (macOS) - output format may differ"
    else
        log_error "strace/dtruss not found. Cannot capture dynamic dependencies."
        echo "  Linux: sudo apt-get install strace"
        echo "  macOS: sudo dtruss (built-in) or brew install strace"
        exit 1
    fi
    
    # Check for jq (JSON processor)
    if ! command -v jq &> /dev/null; then
        log_error "jq not found. Please install:"
        echo "  macOS: brew install jq"
        echo "  Linux: sudo apt-get install jq"
        exit 1
    fi
    
    # Check for Python (for SBOM merger)
    if ! command -v python3 &> /dev/null; then
        log_error "python3 not found. Required for SBOM merging."
        exit 1
    fi
}

###############################################################################
# Generate Static SBOM
###############################################################################

generate_static_sbom() {
    log_info "Generating static SBOM using ${SBOM_TOOL}..."
    
    if [ -z "$TARGET_DIR" ] || [ ! -e "$TARGET_DIR" ]; then
        log_error "Target directory/file not found: ${TARGET_DIR}"
        exit 1
    fi
    
    mkdir -p "$(dirname "$STATIC_SBOM")"
    
    if [ "$SBOM_TOOL" = "syft" ]; then
        if [ -d "$TARGET_DIR" ]; then
            syft dir:"$TARGET_DIR" -o cyclonedx-json > "$STATIC_SBOM" 2>/dev/null || {
                log_warn "Syft directory scan failed, trying package scan..."
                syft packages dir:"$TARGET_DIR" -o cyclonedx-json > "$STATIC_SBOM" 2>/dev/null
            }
        elif [ -f "$TARGET_DIR" ]; then
            syft file:"$TARGET_DIR" -o cyclonedx-json > "$STATIC_SBOM" 2>/dev/null || {
                syft packages file:"$TARGET_DIR" -o cyclonedx-json > "$STATIC_SBOM" 2>/dev/null
            }
        fi
    elif [ "$SBOM_TOOL" = "trivy" ]; then
        trivy fs --format cyclonedx --output "$STATIC_SBOM" "$TARGET_DIR" 2>/dev/null || {
            log_warn "Trivy scan failed, creating empty SBOM structure..."
            create_empty_sbom "$STATIC_SBOM"
        }
    fi
    
    if [ ! -s "$STATIC_SBOM" ]; then
        log_warn "Static SBOM is empty, creating minimal structure..."
        create_empty_sbom "$STATIC_SBOM"
    fi
    
    log_success "Static SBOM generated: ${STATIC_SBOM}"
}

create_empty_sbom() {
    local sbom_file="$1"
    cat > "$sbom_file" <<EOF
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:$(uuidgen 2>/dev/null || echo $(date +%s))",
  "version": 1,
  "metadata": {
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "tools": {
      "components": []
    }
  },
  "components": [],
  "dependencies": []
}
EOF
}

###############################################################################
# Capture Dynamic Dependencies with strace
###############################################################################

capture_dynamic_deps() {
    log_info "Capturing dynamically loaded libraries using ${STRACE_CMD}..."
    
    if [ -z "$RUN_COMMAND" ]; then
        log_warn "No run command provided. Skipping dynamic dependency capture."
        echo "[]" > "$DYNAMIC_LIBS"
        return
    fi
    
    mkdir -p "$(dirname "$STRACE_LOG")"
    
    log_info "Running: ${RUN_COMMAND}"
    log_info "Tracing file operations..."
    
    # Run with strace/dtruss and capture file opens
    if [ "$STRACE_CMD" = "strace" ]; then
        strace -e trace=open,openat -f -s 200 -o "$STRACE_LOG" \
            bash -c "$RUN_COMMAND" > /dev/null 2>&1 || true
    elif [ "$STRACE_CMD" = "dtruss" ]; then
        # dtruss requires sudo on macOS
        sudo dtruss -n java -f bash -c "$RUN_COMMAND" > "$STRACE_LOG" 2>&1 || {
            log_warn "dtruss failed (may need sudo). Trying alternative method..."
            # Fallback: just run and try to parse output
            bash -c "$RUN_COMMAND" > /dev/null 2>&1 || true
        }
    fi
    
    # Parse strace output to extract libraries
    parse_strace_output
    
    log_success "Dynamic dependencies captured"
}

parse_strace_output() {
    log_info "Parsing strace output for dynamic libraries..."
    
    local libs_json="[]"
    local seen_libs=()
    
    if [ ! -f "$STRACE_LOG" ] || [ ! -s "$STRACE_LOG" ]; then
        log_warn "strace log is empty or missing"
        echo "[]" > "$DYNAMIC_LIBS"
        return
    fi
    
    # Extract JAR files and shared libraries from strace output
    while IFS= read -r line || [ -n "$line" ]; do
        # Look for JAR files
        if [[ $line =~ \.jar ]]; then
            # Extract file path
            local file_path=$(echo "$line" | grep -oE '"[^"]+\.jar"' | tr -d '"' | head -1)
            
            if [ -n "$file_path" ] && [ -f "$file_path" ]; then
                # Check if we've seen this library
                local seen=0
                for seen_lib in "${seen_libs[@]}"; do
                    if [ "$seen_lib" = "$file_path" ]; then
                        seen=1
                        break
                    fi
                done
                
                if [ $seen -eq 0 ]; then
                    seen_libs+=("$file_path")
                    log_info "Found dynamic library: $file_path"
                    
                    # Extract library metadata
                    local lib_info=$(extract_library_info "$file_path")
                    if [ -n "$lib_info" ]; then
                        libs_json=$(echo "$libs_json" | jq --argjson lib "$lib_info" '. += [$lib]')
                    fi
                fi
            fi
        fi
        
        # Look for .so files (shared libraries on Linux)
        if [[ $line =~ \.so ]]; then
            local so_path=$(echo "$line" | grep -oE '"[^"]+\.so[^"]*"' | tr -d '"' | head -1)
            if [ -n "$so_path" ] && [ -f "$so_path" ]; then
                local seen=0
                for seen_lib in "${seen_libs[@]}"; do
                    if [ "$seen_lib" = "$so_path" ]; then
                        seen=1
                        break
                    fi
                done
                
                if [ $seen -eq 0 ]; then
                    seen_libs+=("$so_path")
                    log_info "Found dynamic library: $so_path"
                    local lib_info=$(extract_library_info "$so_path")
                    if [ -n "$lib_info" ]; then
                        libs_json=$(echo "$libs_json" | jq --argjson lib "$lib_info" '. += [$lib]')
                    fi
                fi
            fi
        fi
    done < "$STRACE_LOG"
    
    echo "$libs_json" > "$DYNAMIC_LIBS"
    
    local count=$(echo "$libs_json" | jq 'length')
    log_success "Found ${count} dynamically loaded libraries"
}

extract_library_info() {
    local lib_path="$1"
    
    if [ ! -f "$lib_path" ]; then
        return
    fi
    
    # Calculate hashes
    local sha1_hash=$(sha1sum "$lib_path" 2>/dev/null | cut -d' ' -f1 || shasum -a 1 "$lib_path" 2>/dev/null | cut -d' ' -f1 || echo "")
    local sha256_hash=$(sha256sum "$lib_path" 2>/dev/null | cut -d' ' -f1 || shasum -a 256 "$lib_path" 2>/dev/null | cut -d' ' -f1 || echo "")
    
    # Extract filename
    local filename=$(basename "$lib_path")
    
    # Try to extract Maven coordinates from JAR
    local group_id=""
    local artifact_id=""
    local version=""
    local purl=""
    
    if [[ $filename =~ \.jar$ ]]; then
        # Try to parse Maven coordinates from JAR manifest or filename
        # Pattern: groupId-artifactId-version.jar or artifactId-version.jar
        if [[ $filename =~ ^(.+)-([0-9]+\.[0-9]+\.[0-9]+.*)\.jar$ ]]; then
            artifact_id="${BASH_REMATCH[1]}"
            version="${BASH_REMATCH[2]}"
            
            # Try to extract from JAR if it's a Maven JAR
            if command -v unzip &> /dev/null; then
                local pom_path=$(unzip -l "$lib_path" 2>/dev/null | grep -oE 'META-INF/maven/[^/]+/[^/]+/pom\.properties' | head -1)
                if [ -n "$pom_path" ]; then
                    local props=$(unzip -p "$lib_path" "$pom_path" 2>/dev/null)
                    group_id=$(echo "$props" | grep "^groupId=" | cut -d'=' -f2 | tr -d '\r\n' || echo "")
                    artifact_id=$(echo "$props" | grep "^artifactId=" | cut -d'=' -f2 | tr -d '\r\n' || echo "$artifact_id")
                    version=$(echo "$props" | grep "^version=" | cut -d'=' -f2 | tr -d '\r\n' || echo "$version")
                fi
            fi
            
            if [ -n "$group_id" ] && [ -n "$artifact_id" ] && [ -n "$version" ]; then
                purl="pkg:maven/${group_id}/${artifact_id}@${version}"
            else
                purl="pkg:generic/${filename}@unknown"
            fi
        else
            purl="pkg:generic/${filename}@unknown"
        fi
    else
        # Shared library (.so, .dylib, .dll)
        purl="pkg:generic/${filename}@unknown"
    fi
    
    # Create component JSON
    local component_json=$(jq -n \
        --arg type "library" \
        --arg name "$filename" \
        --arg version "${version:-unknown}" \
        --arg purl "$purl" \
        --arg path "$lib_path" \
        --arg sha1 "$sha1_hash" \
        --arg sha256 "$sha256_hash" \
        --arg group "$group_id" \
        --arg artifact "$artifact_id" \
        '{
            "type": $type,
            "name": $name,
            "version": $version,
            "purl": $purl,
            "path": $path,
            "hashes": [
                {"alg": "SHA-1", "content": $sha1},
                {"alg": "SHA-256", "content": $sha256}
            ],
            "properties": [
                {"name": "dynamic:capturedBy", "value": "strace"},
                {"name": "dynamic:source", "value": "runtime"}
            ]
        } + (if $group != "" and $artifact != "" then {"group": $group, "name": $artifact} else {} end)')
    
    echo "$component_json"
}

###############################################################################
# Merge Dynamic Dependencies into SBOM
###############################################################################

merge_sbom() {
    log_info "Merging dynamic dependencies into SBOM..."
    
    python3 "${SCRIPT_DIR}/merge-sbom.py" "$STATIC_SBOM" "$DYNAMIC_LIBS" "$FINAL_SBOM" || {
        log_error "Failed to merge SBOMs. Check merge-sbom.py"
        exit 1
    }
    
    log_success "Final SBOM created: ${FINAL_SBOM}"
    
    # Show summary
    local static_count=$(jq '.components | length' "$STATIC_SBOM" 2>/dev/null || echo "0")
    local dynamic_count=$(jq 'length' "$DYNAMIC_LIBS" 2>/dev/null || echo "0")
    local final_count=$(jq '.components | length' "$FINAL_SBOM" 2>/dev/null || echo "0")
    
    echo ""
    log_info "Summary:"
    echo "  Static components: ${static_count}"
    echo "  Dynamic components: ${dynamic_count}"
    echo "  Total in final SBOM: ${final_count}"
}

###############################################################################
# Main
###############################################################################

main() {
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  SBOM Generator with Dynamic Dependency Capture            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    if [ -z "$TARGET_DIR" ]; then
        echo "Usage: $0 <target-dir-or-file> [run-command]"
        echo ""
        echo "Examples:"
        echo "  $0 ./myapp \"java -jar myapp.jar\""
        echo "  $0 ./target/myapp.jar \"java -cp target/myapp.jar com.example.App\""
        echo "  $0 ./project-dir \"mvn exec:java\""
        exit 1
    fi
    
    mkdir -p "$OUTPUT_DIR" "$TEMP_DIR"
    
    check_prerequisites
    generate_static_sbom
    capture_dynamic_deps
    merge_sbom
    
    echo ""
    log_success "Complete! Final SBOM: ${FINAL_SBOM}"
}

main "$@"

