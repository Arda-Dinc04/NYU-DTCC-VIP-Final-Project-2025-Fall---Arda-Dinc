# Project Summary

## NYU DTCC VIP Final Project 2025 Fall

**Project:** SBOM Generator with Dynamic Dependency Capture

## Problem Statement

Traditional SBOM (Software Bill of Materials) generation tools only capture **static dependencies** - those declared in build files like `pom.xml`, `package.json`, etc. However, many applications **dynamically load libraries at runtime** that are not declared in build files. This creates a critical security gap:

- **Static SBOMs miss runtime dependencies**
- **Vulnerability scanners can't find hidden libraries**
- **Compliance audits are incomplete**

## Solution

This tool bridges the gap by:

1. **Generating static SBOMs** using industry-standard tools (Syft/Trivy)
2. **Capturing dynamic dependencies** at runtime using `strace` system call tracing
3. **Merging everything** into a comprehensive SBOM

## Key Features

✅ **Automatic SBOM Generation**
- Uses Syft or Trivy for static analysis
- Supports multiple target types (directories, files, containers)

✅ **Runtime Dependency Capture**
- Uses `strace`/`dtruss` to trace file operations
- Captures JAR files, shared libraries (.so, .dylib)
- Extracts metadata (Maven coordinates, hashes)

✅ **Intelligent Merging**
- Combines static and dynamic components
- Deduplicates entries
- Preserves all metadata

✅ **Production Ready**
- Error handling and logging
- Cross-platform support (Linux, macOS)
- Comprehensive documentation

## Technical Implementation

### Architecture

```
┌─────────────────┐
│  Target App     │
└────────┬────────┘
         │
         ├─────────────────┐
         │                  │
         ▼                  ▼
┌──────────────┐   ┌──────────────────┐
│  Static SBOM │   │  Dynamic Capture │
│  (Syft/Trivy)│   │  (strace)        │
└──────┬───────┘   └────────┬─────────┘
       │                    │
       └──────────┬─────────┘
                  │
                  ▼
         ┌─────────────────┐
         │  SBOM Merger     │
         │  (Python)        │
         └────────┬────────┘
                  │
                  ▼
         ┌─────────────────┐
         │  Final SBOM     │
         │  (CycloneDX)    │
         └─────────────────┘
```

### Components

1. **`sbom-with-dynamic.sh`** - Main orchestration script
   - Checks prerequisites
   - Generates static SBOM
   - Captures dynamic dependencies
   - Calls merger

2. **`merge-sbom.py`** - SBOM merger
   - Parses JSON SBOMs
   - Merges components
   - Handles duplicates
   - Updates metadata

3. **Supporting files**
   - `README.md` - Full documentation
   - `EXAMPLES.md` - Usage examples
   - `QUICKSTART.md` - Quick setup guide
   - `test-demo.sh` - Test script

## Use Cases

### 1. Security Audits
- Find all libraries actually loaded at runtime
- Identify hidden dependencies
- Complete vulnerability scanning

### 2. Compliance
- Generate comprehensive SBOMs for compliance
- Prove what actually runs in production
- Document all dependencies

### 3. Forensics
- Investigate unexpected library loading
- Trace dependency sources
- Analyze runtime behavior

## Real-World Example

**Scenario:** Java application loads Log4j dynamically (not in pom.xml)

**Without this tool:**
- Static SBOM: 0 Log4j components ❌
- Vulnerability scanner: No Log4j found ❌
- Security risk: Unknown Log4j version ❌

**With this tool:**
- Static SBOM: 0 Log4j components (expected)
- Dynamic capture: 2 Log4j JARs found ✅
- Final SBOM: 2 Log4j components with full metadata ✅
- Security: Can now scan for vulnerabilities ✅

## Testing

Tested with:
- Log4j dynamic loading scenario
- Java applications with Maven
- Various library loading patterns

## Limitations & Future Work

**Current Limitations:**
- Best support for Java/JAR files
- Platform-specific (strace works best on Linux)
- Requires running the application

**Future Enhancements:**
- Support for more languages (Python, Node.js, Go)
- Containerized application support
- CI/CD integration
- Web UI for visualization
- Better shared library metadata extraction

## Technologies Used

- **Bash** - Main orchestration
- **Python 3** - SBOM merging
- **Syft/Trivy** - Static SBOM generation
- **strace/dtruss** - System call tracing
- **jq** - JSON processing
- **CycloneDX** - SBOM format

## Deliverables

✅ Complete tool implementation
✅ Comprehensive documentation
✅ Usage examples
✅ Test scripts
✅ GitHub repository setup guide

## Submission

- **Repository Name:** `NYU-DTCC-VIP Final Project 2025 Fall - Your Name`
- **Deadline:** December 12, 2025
- **Format:** Public GitHub repository

## Impact

This tool addresses a critical gap in software supply chain security by ensuring that **all dependencies** - both static and dynamic - are captured in SBOMs. This enables:

- Complete vulnerability scanning
- Accurate compliance reporting
- Better security posture
- Full dependency visibility

## Conclusion

This project demonstrates a practical solution to a real-world security problem. By combining static analysis with runtime tracing, we create a comprehensive view of application dependencies that traditional tools miss.

---

**Author:** NYU DTCC VIP Student  
**Course:** NYU DTCC VIP 2025 Fall  
**Date:** 2025

