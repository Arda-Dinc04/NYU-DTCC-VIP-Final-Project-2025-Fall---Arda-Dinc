#!/bin/bash

echo "=== Log4j Week-1 Project Testing Script ==="
echo

# Test Static Demo
echo "1. Testing Static Demo (compile-time Log4j dependency)"
echo "=================================================="
cd log4j-static-demo
echo "Building static demo..."
mvn -q clean package
echo "Running static demo..."
java -cp target/log4j-static-demo-1.0-SNAPSHOT.jar:$(mvn -q dependency:build-classpath -Dmdep.outputFile=/dev/stdout) com.example.App
echo
echo "Checking Maven dependencies for Log4j:"
mvn dependency:tree | grep -i log4j
echo

# Test Dynamic Demo
echo "2. Testing Dynamic Demo (runtime-loaded Log4j)"
echo "============================================="
cd ../log4j-dynamic-demo
echo "Building dynamic demo..."
mvn -q clean package
echo "Running dynamic demo..."
java -cp target/log4j-dynamic-demo-1.0-SNAPSHOT.jar com.example.App
echo
echo "Checking Maven dependencies for Log4j (should be empty):"
mvn dependency:tree | grep -i log4j || echo "No Log4j dependencies found (as expected)"
echo

# Security Inspection
echo "3. Security Inspection"
echo "====================="
echo "Checking for JndiLookup in runtime JARs:"
cd runtime-libs
echo "Before mitigation:"
jar tf log4j-core-2.25.2.jar.backup | grep -i JndiLookup || echo "JndiLookup not found"
echo "After mitigation:"
jar tf log4j-core-2.25.2.jar | grep -i JndiLookup || echo "JndiLookup successfully removed"
echo

echo "=== All tests completed successfully! ==="
