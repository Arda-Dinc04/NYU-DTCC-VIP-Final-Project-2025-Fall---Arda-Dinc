# SBOM Generator with Dynamic Dependency Capture

**NYU DTCC VIP Final Project 2025 Fall**

A tool that automatically generates Software Bill of Materials (SBOMs) and captures dynamically linked dependencies at runtime, then merges them back into the SBOM.

## 📊 Demo Results

See [DEMO-RESULTS.md](DEMO-RESULTS.md) for actual test results and performance metrics from running the tool.

## Overview

This tool addresses a critical gap in SBOM generation: **static SBOMs miss dynamically loaded libraries**. Many applications load libraries at runtime that aren't declared in build files (e.g., `pom.xml`, `package.json`). This tool:

1. **Generates static SBOM** using industry-standard tools (Syft or Trivy)
2. **Captures dynamic dependencies** using `strace` to monitor file operations at runtime
3. **Merges everything** into a comprehensive SBOM that includes both static and dynamic dependencies

## Features

- ✅ Automatic SBOM generation (Syft/Trivy)
- ✅ Runtime dependency capture via `strace`
- ✅ Intelligent merging of static + dynamic components
- ✅ Duplicate detection and deduplication
- ✅ Support for Java (JAR files) and shared libraries (.so, .dylib)
- ✅ Maven coordinate extraction from JARs
- ✅ Hash calculation (SHA-1, SHA-256)

## Prerequisites

### Required Tools

- **SBOM Generator** (one of):
  - [Syft](https://github.com/anchore/syft) - Recommended
  - [Trivy](https://github.com/aquasecurity/trivy)
  
- **System Call Tracer**:
  - Linux: `strace` (`sudo apt-get install strace`)
  - macOS: `dtruss` (built-in, requires sudo) or `strace` via Homebrew

- **Utilities**:
  - `jq` - JSON processor (`brew install jq` or `sudo apt-get install jq`)
  - `python3` - For SBOM merging
  - `unzip` - For JAR inspection (usually pre-installed)

### Installation

```bash
# Install Syft (recommended)
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin

# Install jq
# macOS:
brew install jq

# Linux:
sudo apt-get install jq

# Install strace (Linux)
sudo apt-get install strace

# macOS: dtruss is built-in, or:
brew install strace
```

## Usage

### Basic Usage

```bash
./sbom-with-dynamic.sh <target> <run-command>
```

### Examples

#### Java Application

```bash
# Generate SBOM for a Java app and capture dynamic JARs
./sbom-with-dynamic.sh ./myapp "java -jar myapp.jar"

# With classpath
./sbom-with-dynamic.sh ./target/myapp.jar "java -cp target/myapp.jar:libs/* com.example.App"
```

#### Maven Project

```bash
# Scan project directory and run with Maven
./sbom-with-dynamic.sh ./myproject "mvn exec:java -Dexec.mainClass=com.example.App"
```

#### Directory Scan

```bash
# Just generate static SBOM (no runtime capture)
./sbom-with-dynamic.sh ./project-dir ""
```

## How It Works

### 1. Static SBOM Generation

The tool uses Syft or Trivy to scan the target directory/file and generate a CycloneDX SBOM of all discoverable components.

```bash
syft dir:./myapp -o cyclonedx-json > static-sbom.json
```

### 2. Dynamic Dependency Capture

When you provide a run command, the tool:

1. Runs your application with `strace`/`dtruss` to trace system calls
2. Filters for file open operations (`open`, `openat`)
3. Extracts JAR files and shared libraries (.so, .dylib)
4. Parses library metadata:
   - Extracts Maven coordinates from JAR manifests
   - Calculates file hashes (SHA-1, SHA-256)
   - Identifies library paths

```bash
strace -e trace=open,openat -f java -jar myapp.jar
```

### 3. SBOM Merging

The Python merger script:
- Combines static and dynamic components
- Detects and removes duplicates
- Preserves all metadata
- Updates timestamps and tool information

## Output

The tool generates:

- **`output/sbom-with-dynamic.json`** - Final merged SBOM (CycloneDX format)

Example structure:

```json
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "components": [
    {
      "type": "library",
      "group": "org.apache.logging.log4j",
      "name": "log4j-core",
      "version": "2.25.2",
      "purl": "pkg:maven/org.apache.logging.log4j/log4j-core@2.25.2",
      "properties": [
        {"name": "dynamic:capturedBy", "value": "strace"},
        {"name": "dynamic:source", "value": "runtime"},
        {"name": "dynamic:filePath", "value": "runtime-libs/log4j-core-2.25.2.jar"}
      ]
    }
  ]
}
```

## Real-World Example

### Log4j Dynamic Loading Demo

This tool was tested with the Log4j dynamic loading scenario:

```bash
cd log4j-week1/log4j-dynamic-demo

# Generate SBOM with dynamic capture
../../sbom-dynamic-capture/sbom-with-dynamic.sh . "java -cp target/log4j-dynamic-demo-1.0-SNAPSHOT.jar com.example.App"
```

**Result:**
- Static SBOM: 0 Log4j components (not in pom.xml)
- Dynamic capture: 2 Log4j JARs found (from runtime-libs/)
- Final SBOM: 2 Log4j components with full metadata

## Project Structure

```
sbom-dynamic-capture/
├── sbom-with-dynamic.sh    # Main tool script
├── merge-sbom.py           # SBOM merger (Python)
├── README.md               # This file
├── output/                 # Generated SBOMs (gitignored)
│   └── sbom-with-dynamic.json
└── .tmp/                   # Temporary files (gitignored)
```

## Limitations

1. **Platform-specific**: `strace` works best on Linux. macOS `dtruss` has different output format
2. **Java-focused**: Best support for Java/JAR files. Other languages may need adjustments
3. **Runtime requirement**: Dynamic capture requires running the application
4. **Permission requirements**: `strace`/`dtruss` may require sudo on some systems

## Future Enhancements

- [ ] Support for more languages (Python, Node.js, Go)
- [ ] Better shared library (.so) metadata extraction
- [ ] Integration with CI/CD pipelines
- [ ] Vulnerability scanning integration
- [ ] Support for containerized applications
- [ ] Web UI for visualization

## Contributing

This is a final project for NYU DTCC VIP 2025 Fall. Contributions and improvements are welcome!

## License

Educational project - see course guidelines.

## References

- [CycloneDX SBOM Specification](https://cyclonedx.org/)
- [Syft Documentation](https://github.com/anchore/syft)
- [strace Manual](https://man7.org/linux/man-pages/man1/strace.1.html)
- [OWASP SBOM](https://owasp.org/www-community/SBOM)

## Author

NYU DTCC VIP Final Project 2025 Fall

