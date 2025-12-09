# Quick Start Guide

Get up and running in 5 minutes!

## 1. Install Prerequisites

```bash
# Install Syft (recommended SBOM tool)
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin

# Install jq (JSON processor)
# macOS:
brew install jq

# Linux:
sudo apt-get install jq

# Install strace (Linux) or use dtruss (macOS)
# Linux:
sudo apt-get install strace

# macOS: dtruss is built-in, or:
brew install strace
```

## 2. Make Scripts Executable

```bash
chmod +x sbom-with-dynamic.sh merge-sbom.py test-demo.sh
```

## 3. Test with Log4j Demo

```bash
# Navigate to the log4j dynamic demo
cd ../log4j-week1/log4j-dynamic-demo

# Build if needed
mvn clean package -q

# Run the tool
../../sbom-dynamic-capture/sbom-with-dynamic.sh . \
  "java -cp target/log4j-dynamic-demo-1.0-SNAPSHOT.jar com.example.App"
```

## 4. Check Results

```bash
# View the generated SBOM
cat ../../sbom-dynamic-capture/output/sbom-with-dynamic.json | jq '.components[] | {name, version, purl}'
```

## Expected Output

You should see:
- Static SBOM generation (may be empty for dynamic demo)
- Dynamic capture finding Log4j JARs from `runtime-libs/`
- Final merged SBOM with 2 Log4j components

## Troubleshooting

**"strace not found"**
- Linux: `sudo apt-get install strace`
- macOS: Use `dtruss` (built-in) or `brew install strace`

**"jq not found"**
- macOS: `brew install jq`
- Linux: `sudo apt-get install jq`

**"syft not found"**
- Run the install script above, or download from: https://github.com/anchore/syft/releases

**Permission denied**
- Some systems require `sudo` for strace/dtruss
- Try: `sudo ./sbom-with-dynamic.sh ...`

## Next Steps

- Read [README.md](README.md) for full documentation
- Check [EXAMPLES.md](EXAMPLES.md) for more use cases
- See [GITHUB-SETUP.md](GITHUB-SETUP.md) for repository setup

