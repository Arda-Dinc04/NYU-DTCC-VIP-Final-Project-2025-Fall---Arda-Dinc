# Usage Examples

## Example 1: Java Application with Dynamic JARs

This example demonstrates capturing Log4j JARs loaded at runtime.

```bash
cd log4j-week1/log4j-dynamic-demo

# Run the tool
../../sbom-dynamic-capture/sbom-with-dynamic.sh . \
  "java -cp target/log4j-dynamic-demo-1.0-SNAPSHOT.jar com.example.App"
```

**Expected Output:**
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

## Example 2: Static Java Application

For applications with compile-time dependencies:

```bash
cd log4j-week1/log4j-static-demo

../../sbom-dynamic-capture/sbom-with-dynamic.sh . \
  "java -cp target/log4j-static-demo-1.0-SNAPSHOT.jar:$(mvn -q dependency:build-classpath -Dmdep.outputFile=/dev/stdout) com.example.App"
```

**Expected Output:**
- Static SBOM will show Log4j from Maven dependencies
- Dynamic capture may show JARs from Maven cache
- Final SBOM combines both (with deduplication)

## Example 3: Directory Scan Only (No Runtime)

If you just want a static SBOM without running the application:

```bash
./sbom-with-dynamic.sh ./myproject ""
```

This generates only the static SBOM.

## Example 4: Maven Exec Plugin

```bash
./sbom-with-dynamic.sh ./myproject "mvn exec:java -Dexec.mainClass=com.example.App"
```

## Example 5: Custom Classpath

```bash
./sbom-with-dynamic.sh ./target/app.jar \
  "java -cp target/app.jar:libs/*:external/*.jar com.example.Main"
```

## Troubleshooting

### strace Permission Denied

On some systems, you may need sudo:

```bash
sudo ./sbom-with-dynamic.sh <target> "<command>"
```

### macOS dtruss Issues

If `dtruss` doesn't work, try installing `strace` via Homebrew:

```bash
brew install strace
```

### No Dynamic Libraries Found

If no dynamic libraries are captured:
1. Check that your run command actually executes
2. Verify libraries are loaded from paths outside the classpath
3. Check strace log in `.tmp/strace.log`

### JAR Metadata Extraction Fails

If Maven coordinates aren't extracted:
- The tool will still capture the JAR with generic package URL
- Check that `unzip` is available
- Verify JAR has Maven manifest (`META-INF/maven/`)

