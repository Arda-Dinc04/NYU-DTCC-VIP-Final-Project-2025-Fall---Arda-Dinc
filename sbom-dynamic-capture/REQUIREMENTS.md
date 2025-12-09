# Requirements

## System Requirements

- **Operating System:** Linux or macOS
- **Shell:** Bash 4.0+
- **Python:** Python 3.6+

## Required Tools

### 1. SBOM Generator (Choose One)

#### Option A: Syft (Recommended)
```bash
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
```

#### Option B: Trivy
```bash
# macOS
brew install trivy

# Linux
# See: https://aquasecurity.github.io/trivy/latest/getting-started/installation/
```

### 2. System Call Tracer

#### Linux: strace
```bash
sudo apt-get install strace
# or
sudo yum install strace
```

#### macOS: dtruss (Built-in)
- No installation needed (built into macOS)
- Requires `sudo` to run
- Alternative: `brew install strace`

### 3. JSON Processor: jq

```bash
# macOS
brew install jq

# Linux
sudo apt-get install jq
# or
sudo yum install jq
```

### 4. Python 3

Usually pre-installed. Verify:
```bash
python3 --version
```

### 5. Optional but Recommended

- **unzip** - For JAR metadata extraction (usually pre-installed)
- **sha1sum/shasum** - For hash calculation (usually pre-installed)
- **sha256sum/shasum** - For hash calculation (usually pre-installed)

## Verification

Run this to check all requirements:

```bash
echo "Checking requirements..."
command -v syft >/dev/null && echo "✓ Syft" || echo "✗ Syft (or install Trivy)"
command -v trivy >/dev/null && echo "✓ Trivy" || echo "✗ Trivy (or install Syft)"
command -v strace >/dev/null && echo "✓ strace" || echo "✗ strace"
command -v dtruss >/dev/null && echo "✓ dtruss" || echo "✗ dtruss (macOS only)"
command -v jq >/dev/null && echo "✓ jq" || echo "✗ jq"
command -v python3 >/dev/null && echo "✓ Python 3" || echo "✗ Python 3"
```

## Minimum Requirements

At minimum, you need:
- ✅ One SBOM tool (Syft OR Trivy)
- ✅ One system tracer (strace OR dtruss)
- ✅ jq
- ✅ Python 3

## Platform-Specific Notes

### Linux
- `strace` works natively
- May need `sudo` for some operations
- All tools available via package managers

### macOS
- `dtruss` is built-in but requires `sudo`
- `strace` available via Homebrew (may have limitations)
- Homebrew recommended for other tools

## Installation Script

Quick install for common systems:

```bash
# Detect OS and install
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    sudo apt-get update
    sudo apt-get install -y strace jq
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    brew install jq strace
fi

# Install Syft (works on both)
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
```

