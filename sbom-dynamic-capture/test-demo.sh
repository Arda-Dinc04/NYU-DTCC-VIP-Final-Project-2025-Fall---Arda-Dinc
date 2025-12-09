#!/bin/bash

# Test script to demonstrate the tool with the log4j demos

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG4J_DIR="${SCRIPT_DIR}/../log4j-week1"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Testing SBOM Dynamic Capture Tool                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Test 1: Dynamic demo (should capture Log4j from runtime-libs/)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 1: Dynamic Loading Demo"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cd "${LOG4J_DIR}/log4j-dynamic-demo"

# Build if needed
if [ ! -f "target/log4j-dynamic-demo-1.0-SNAPSHOT.jar" ]; then
    echo "Building dynamic demo..."
    mvn clean package -q
fi

# Run the tool
"${SCRIPT_DIR}/sbom-with-dynamic.sh" . \
    "java -cp target/log4j-dynamic-demo-1.0-SNAPSHOT.jar com.example.App"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Show results
if [ -f "${SCRIPT_DIR}/output/sbom-with-dynamic.json" ]; then
    echo "Final SBOM components:"
    jq '.components[] | {name: .name, version: .version, purl: .purl}' \
        "${SCRIPT_DIR}/output/sbom-with-dynamic.json" 2>/dev/null || echo "Could not parse SBOM"
fi

echo ""
echo "✅ Test complete! Check output/sbom-with-dynamic.json"

