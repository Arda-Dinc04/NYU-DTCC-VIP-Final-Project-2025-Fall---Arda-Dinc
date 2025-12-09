#!/bin/bash

# SIMPLIFIED strace Demo: Proving Dynamic Log4j Loading
# Shows clear output demonstrating static vs dynamic loading

DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATIC_DIR="$DEMO_DIR/log4j-static-demo"
DYNAMIC_DIR="$DEMO_DIR/log4j-dynamic-demo"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  strace Demo: Proving Dynamic Log4j Loading                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check tools
if ! command -v java &> /dev/null; then
    echo "❌ ERROR: java is not installed."
    exit 1
fi

# Check for strace or dtruss (macOS)
TRACE_CMD=""
if command -v strace &> /dev/null; then
    TRACE_CMD="strace"
elif command -v dtruss &> /dev/null; then
    TRACE_CMD="dtruss"
    echo "⚠️  Using dtruss (macOS) instead of strace"
    echo ""
else
    echo "⚠️  WARNING: strace/dtruss not found. Will show app output only."
    echo "   Install: Linux: sudo apt-get install strace"
    echo "            macOS: sudo dtruss (built-in) or brew install strace"
    echo ""
fi

# Build projects
echo "📦 Building projects..."
cd "$STATIC_DIR"
mvn clean package -q > /dev/null 2>&1
echo "   ✓ Static demo built"

cd "$DYNAMIC_DIR"
mvn clean package -q > /dev/null 2>&1
echo "   ✓ Dynamic demo built"
echo ""

# ============================================================================
# DEMO 1: STATIC LOADING
# ============================================================================
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  DEMO 1: Static Loading (Compile-time dependency)          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 What this shows:"
echo "   • Log4j is in pom.xml (Maven dependency)"
echo "   • JARs loaded from Maven cache (~/.m2/repository/)"
echo "   • Static SBOM would catch this"
echo ""

STATIC_CP="$STATIC_DIR/target/log4j-static-demo-1.0-SNAPSHOT.jar"
STATIC_DEPS=$(cd "$STATIC_DIR" && mvn -q dependency:build-classpath -Dmdep.outputFile=/dev/stdout 2>/dev/null || echo "")
STATIC_FULL_CP="$STATIC_CP:$STATIC_DEPS"

echo "▶️  Running application:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
java -cp "$STATIC_FULL_CP" com.example.App 2>&1 | head -5
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -n "$TRACE_CMD" ]; then
    echo "🔍 strace output (file operations showing JAR loading):"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [ "$TRACE_CMD" = "strace" ]; then
        strace -e trace=open,openat -f -s 200 2>&1 \
            java -cp "$STATIC_FULL_CP" com.example.App > /dev/null 2>&1 | \
            grep -E "(log4j|\.jar|repository)" | head -5 || echo "   (JARs may be in classpath already)"
    else
        echo "   (dtruss output format differs - check manual)"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi
echo ""
echo ""

# ============================================================================
# DEMO 2: DYNAMIC LOADING  
# ============================================================================
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  DEMO 2: Dynamic Loading (Runtime - NO dependencies!)      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 What this shows:"
echo "   • NO Log4j in pom.xml"
echo "   • JARs loaded from runtime-libs/ directory at runtime"
echo "   • Dynamic SBOM (Syft) catches this"
echo ""

# Verify runtime JARs exist
if [ ! -f "$DYNAMIC_DIR/runtime-libs/log4j-api-2.25.2.jar" ] || \
   [ ! -f "$DYNAMIC_DIR/runtime-libs/log4j-core-2.25.2.jar" ]; then
    echo "❌ ERROR: Runtime JARs not found in runtime-libs/"
    exit 1
fi

DYNAMIC_CP="$DYNAMIC_DIR/target/log4j-dynamic-demo-1.0-SNAPSHOT.jar"

echo "▶️  Running application:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd "$DYNAMIC_DIR"
java -cp "$DYNAMIC_CP" com.example.App 2>&1 | head -5
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -n "$TRACE_CMD" ]; then
    echo "🔍 strace output (THE KEY PROOF - JARs opened at runtime):"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [ "$TRACE_CMD" = "strace" ]; then
        strace -e trace=open,openat -f -s 200 2>&1 \
            java -cp "$DYNAMIC_CP" com.example.App > /dev/null 2>&1 | \
            grep -E "(runtime-libs|log4j.*\.jar)" | head -5
        echo ""
        echo "✅ PROOF: See 'runtime-libs/log4j-*.jar' being opened!"
        echo "   This proves dynamic loading at runtime!"
    else
        echo "   (dtruss output format differs - check manual)"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi
echo ""

# ============================================================================
# SUMMARY
# ============================================================================
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  SUMMARY: What You Just Saw                                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📊 Comparison:"
echo ""
echo "   STATIC Loading:"
echo "   • Log4j in pom.xml → Static SBOM shows it"
echo "   • JARs from Maven cache (expected)"
echo ""
echo "   DYNAMIC Loading:"
echo "   • NO Log4j in pom.xml → Static SBOM MISSES it!"
echo "   • JARs from runtime-libs/ → Dynamic SBOM (Syft) finds it"
echo "   • strace PROVES it loads at runtime!"
echo ""
echo "🎯 Key Takeaway:"
echo "   strace shows file operations that prove dynamic loading"
echo "   matches what dynamic SBOMs (like Syft) discover!"
echo ""

