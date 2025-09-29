# Week 2: Software Bill of Materials (SBOM) Generation

This document describes the generation of SBOMs for both the static and dynamic Log4j projects from Week 1, demonstrating different approaches to dependency inventory and security analysis.

## Overview

We generated two distinct SBOMs using different methodologies:

- **Static SBOM**: Generated from Maven build-time dependencies using CycloneDX Maven plugin
- **Dynamic SBOM**: Generated from runtime artifacts using Syft filesystem scanner

## Tooling Used

- **Maven**: 3.9.11 (with CycloneDX Maven plugin 2.8.0)
- **Syft**: 1.33.0 (filesystem scanner)
- **Grype**: 0.100.0 (vulnerability scanner)
- **CycloneDX Schema**: 1.5

## Static SBOM Generation

### Method: CycloneDX Maven Plugin

The static SBOM enumerates **declared** build-time dependencies from Maven's dependency resolution, showing what the application is compiled and linked against.

### Commands Used

```bash
# Navigate to static project
cd ./log4j-week1/log4j-static-demo

# Generate SBOM using Maven plugin
mvn -q clean package org.cyclonedx:cyclonedx-maven-plugin:makeBom
```

### Output Location

- **SBOM File**: `./log4j-week1/log4j-static-demo/target/bom.json`
- **Size**: 8,720 bytes
- **Format**: CycloneDX JSON 1.5

### Verification

```bash
# Check Maven dependencies
mvn dependency:tree | grep -i log4j

# Verify SBOM exists
test -f target/bom.json && echo "Static SBOM exists."
```

**Expected Maven output:**

```
[INFO] +- org.apache.logging.log4j:log4j-api:jar:2.25.2:compile
[INFO] \- org.apache.logging.log4j:log4j-core:jar:2.25.2:compile
```

## Dynamic SBOM Generation

### Method: Syft Filesystem Scanner

The dynamic SBOM enumerates **runtime** artifacts actually present in the `runtime-libs/` directory, even if not declared in `pom.xml`.

### Commands Used

```bash
# Navigate to dynamic project
cd ./log4j-week1/log4j-dynamic-demo

# Generate SBOM using Syft
syft dir:runtime-libs -o cyclonedx-json > sbom-dynamic.json
```

### Output Location

- **SBOM File**: `./log4j-week1/log4j-dynamic-demo/sbom-dynamic.json`
- **Size**: 3,648 bytes
- **Format**: CycloneDX JSON

### Verification

```bash
# List runtime artifacts
ls runtime-libs

# Verify SBOM exists
test -f sbom-dynamic.json && echo "Dynamic SBOM exists."
```

**Expected runtime artifacts:**

```
log4j-api-2.25.2.jar
log4j-core-2.25.2.jar
log4j-core-2.25.2.jar.backup
README.md
```

## Vulnerability Scanning

### Commands Used

```bash
# Scan static SBOM
cd ./log4j-week1/log4j-static-demo
grype sbom:target/bom.json -o table > ../static-sbom-vulns.txt

# Scan dynamic SBOM
cd ../log4j-dynamic-demo
grype sbom:sbom-dynamic.json -o table > ../dynamic-sbom-vulns.txt
```

### Output Locations

- **Static Vulnerabilities**: `./log4j-week1/static-sbom-vulns.txt`
- **Dynamic Vulnerabilities**: `./log4j-week1/dynamic-sbom-vulns.txt`

### Scan Results

Both SBOMs showed **0 vulnerability matches** across all severity levels (critical, high, medium, low, negligible), confirming that Log4j 2.25.2 is properly patched.

## Key Differences Between Static and Dynamic SBOMs

### Static SBOM Characteristics

- **Source**: Maven's declared dependencies in `pom.xml`
- **Scope**: Build-time dependencies only
- **Completeness**: May miss runtime-only dependencies
- **Accuracy**: Reflects what the build system knows about
- **Size**: Larger (8,720 bytes) due to transitive dependencies

### Dynamic SBOM Characteristics

- **Source**: Actual files present in `runtime-libs/` directory
- **Scope**: Runtime artifacts only
- **Completeness**: Shows what's actually available at runtime
- **Accuracy**: Reflects the true runtime environment
- **Size**: Smaller (3,648 bytes) as it only includes direct JARs

### Why They Differ

The two SBOMs can differ significantly because:

1. **Hidden Dependencies**: Runtime JARs may contain dependencies not declared in `pom.xml`
2. **Transitive Dependencies**: Maven includes all transitive dependencies, while filesystem scan only shows direct artifacts
3. **Build vs Runtime**: Build-time dependencies may differ from what's actually loaded at runtime
4. **Version Mismatches**: Runtime JARs might be different versions than declared dependencies

### Security Implications

- **Static SBOM**: Good for compliance and build reproducibility
- **Dynamic SBOM**: Critical for runtime security analysis
- **Risk**: "Hidden" runtime components may contain vulnerabilities not visible in build-time analysis
- **Best Practice**: Generate both SBOMs and compare them regularly

## Safety Statement

**No exploit testing was performed.** This deliverable only demonstrates:

- SBOM generation using industry-standard tools
- Vulnerability scanning of generated SBOMs
- Comparison of build-time vs runtime dependency inventory
- Safe, non-destructive analysis techniques

All testing was conducted in a controlled, local environment with no external network connections or exploit attempts. The focus is on dependency inventory and security compliance.

## File Structure

```
log4j-week1/
├── log4j-static-demo/
│   ├── target/
│   │   └── bom.json                    # Static SBOM (8,720 bytes)
│   └── pom.xml                         # Updated with CycloneDX plugin
├── log4j-dynamic-demo/
│   ├── sbom-dynamic.json               # Dynamic SBOM (3,648 bytes)
│   └── runtime-libs/                   # Runtime artifacts
├── static-sbom-vulns.txt               # Static vulnerability report
├── dynamic-sbom-vulns.txt              # Dynamic vulnerability report
└── SBOM-README.md                      # This file
```

## Next Steps

1. **Regular SBOM Updates**: Regenerate SBOMs when dependencies change
2. **Automated Scanning**: Integrate SBOM generation into CI/CD pipelines
3. **Compliance Reporting**: Use SBOMs for security compliance documentation
4. **Dependency Monitoring**: Set up alerts for new vulnerabilities in SBOM components

---

_This SBOM analysis was generated for educational purposes to demonstrate different approaches to dependency inventory and security analysis in Java applications._
