# Testing Guide

## Quick Test (Recommended)

The easiest way to test the tool is using the provided test script:

```bash
cd sbom-dynamic-capture
./test-demo.sh
```

This will automatically:
1. Build the log4j dynamic demo (if needed)
2. Run the SBOM tool
3. Show the results

## Manual Testing Steps

### Step 1: Check Prerequisites

```bash
# Check if all required tools are installed
command -v syft >/dev/null && echo "✓ Syft" || echo "✗ Syft - Install: curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin"
command -v strace >/dev/null && echo "✓ strace" || echo "✗ strace - Install: sudo apt-get install strace (Linux) or brew install strace (macOS)"
command -v dtruss >/dev/null && echo "✓ dtruss" || echo "✗ dtruss (macOS only)"
command -v jq >/dev/null && echo "✓ jq" || echo "✗ jq - Install: brew install jq (macOS) or sudo apt-get install jq (Linux)"
command -v python3 >/dev/null && echo "✓ Python 3" || echo "✗ Python 3"
```

### Step 2: Test with Log4j Dynamic Demo

```bash
# Navigate to tool directory
cd sbom-dynamic-capture

# Navigate to log4j dynamic demo
cd ../log4j-week1/log4j-dynamic-demo

# Build the project (if not already built)
mvn clean package -q

# Run the SBOM tool
../../sbom-dynamic-capture/sbom-with-dynamic.sh . \
  "java -cp target/log4j-dynamic-demo-1.0-SNAPSHOT.jar com.example.App"
```

### Step 3: Verify Results

```bash
# Check if SBOM was generated
ls -lh ../../sbom-dynamic-capture/output/sbom-with-dynamic.json

# View the components found
cat ../../sbom-dynamic-capture/output/sbom-with-dynamic.json | jq '.components[] | {name, version, purl}'

# Count components
cat ../../sbom-dynamic-capture/output/sbom-with-dynamic.json | jq '.components | length'

# Check for Log4j components
cat ../../sbom-dynamic-capture/output/sbom-with-dynamic.json | jq '.components[] | select(.name | contains("log4j"))'
```

## Expected Results

### Successful Test Output

You should see output like:

```
[INFO] Checking prerequisites...
[SUCCESS] Found Syft
[SUCCESS] Found strace
[INFO] Generating static SBOM using syft...
[SUCCESS] Static SBOM generated
[INFO] Capturing dynamically loaded libraries using strace...
[INFO] Found dynamic library: runtime-libs/log4j-api-2.25.2.jar
[INFO] Found dynamic library: runtime-libs/log4j-core-2.25.2.jar
[SUCCESS] Found 2 dynamically loaded libraries
[INFO] Merging dynamic dependencies into SBOM...
[SUCCESS] Final SBOM created: output/sbom-with-dynamic.json

Summary:
  Static components: 0
  Dynamic components: 2
  Total in final SBOM: 2
```

### Expected SBOM Contents

The final SBOM should contain:
- **2 Log4j components** (log4j-api and log4j-core)
- **Version 2.25.2** for both
- **PURLs** like `pkg:maven/org.apache.logging.log4j/log4j-api@2.25.2`
- **Properties** indicating dynamic capture:
  - `dynamic:capturedBy: strace`
  - `dynamic:source: runtime`
  - `dynamic:filePath: runtime-libs/log4j-*.jar`

## Test Scenarios

### Test 1: Dynamic Loading (Primary Test)

**Purpose:** Verify the tool captures dynamically loaded JARs

```bash
cd log4j-week1/log4j-dynamic-demo
../../sbom-dynamic-capture/sbom-with-dynamic.sh . \
  "java -cp target/log4j-dynamic-demo-1.0-SNAPSHOT.jar com.example.App"
```

**Expected:** Should find 2 Log4j JARs from `runtime-libs/`

### Test 2: Static Loading (Comparison)

**Purpose:** Compare with static dependencies

```bash
cd log4j-week1/log4j-static-demo
../../sbom-dynamic-capture/sbom-with-dynamic.sh . \
  "java -cp target/log4j-static-demo-1.0-SNAPSHOT.jar:$(mvn -q dependency:build-classpath -Dmdep.outputFile=/dev/stdout) com.example.App"
```

**Expected:** Should find Log4j from Maven dependencies

### Test 3: Static SBOM Only (No Runtime)

**Purpose:** Test static SBOM generation without running app

```bash
cd log4j-week1/log4j-static-demo
../../sbom-dynamic-capture/sbom-with-dynamic.sh . ""
```

**Expected:** Should generate static SBOM only

## Troubleshooting Tests

### Issue: "strace not found"

**Solution:**
```bash
# Linux
sudo apt-get install strace

# macOS - use dtruss or install strace
sudo dtruss ...  # or
brew install strace
```

### Issue: "No dynamic libraries found"

**Possible causes:**
1. Application didn't run successfully
2. Libraries already in classpath (not dynamically loaded)
3. strace output format different (macOS dtruss)

**Solution:**
- Check that the run command works without strace first
- Verify JARs exist in expected location
- Check `.tmp/strace.log` for captured output

### Issue: "jq parse error"

**Solution:**
- Ensure jq is installed: `brew install jq` or `sudo apt-get install jq`
- Check JSON is valid: `cat output/sbom-with-dynamic.json | jq .`

### Issue: "Permission denied" with strace

**Solution:**
- On macOS, dtruss requires sudo: `sudo ./sbom-with-dynamic.sh ...`
- On Linux, strace usually works without sudo, but may need it for some operations

### Issue: "Syft/Trivy not found"

**Solution:**
```bash
# Install Syft
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin

# Or install Trivy
brew install trivy  # macOS
# See Trivy docs for Linux
```

## Validation Checklist

After running tests, verify:

- [ ] SBOM file is created in `output/` directory
- [ ] SBOM is valid JSON (can be parsed with `jq`)
- [ ] SBOM follows CycloneDX format
- [ ] Dynamic components have `dynamic:capturedBy` property
- [ ] File paths are correct in `dynamic:filePath` property
- [ ] PURLs are generated correctly
- [ ] Hashes (SHA-1, SHA-256) are present
- [ ] No duplicate components in final SBOM

## Advanced Testing

### Test with Custom Application

```bash
# Create a test app that loads JARs dynamically
# Then run:
./sbom-with-dynamic.sh ./myapp "java -jar myapp.jar"
```

### Test with Different SBOM Tools

```bash
# If both Syft and Trivy are installed, the tool will use Syft by default
# You can modify the script to prefer Trivy if needed
```

### Test Error Handling

```bash
# Test with invalid target
./sbom-with-dynamic.sh /nonexistent "echo test"

# Test with invalid command
./sbom-with-dynamic.sh . "nonexistent-command"
```

## Performance Testing

```bash
# Time the execution
time ./sbom-with-dynamic.sh . "java -cp target/app.jar com.example.App"

# Check output sizes
ls -lh output/*.json
```

## Success Criteria

A successful test should demonstrate:

1. ✅ Tool runs without errors
2. ✅ Static SBOM is generated
3. ✅ Dynamic libraries are captured
4. ✅ Final SBOM contains both static and dynamic components
5. ✅ No duplicates in final SBOM
6. ✅ All metadata is preserved
7. ✅ SBOM is valid CycloneDX format

## Next Steps After Testing

Once testing is successful:

1. Review the generated SBOM
2. Compare with expected results
3. Document any issues or improvements
4. Update documentation if needed
5. Prepare for submission

