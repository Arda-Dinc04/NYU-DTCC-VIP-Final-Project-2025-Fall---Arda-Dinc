# Log4j Week-1 Deliverable

This project demonstrates two different approaches to using Apache Log4j 2.x in Java applications:

## Static vs Dynamic Log4j Usage

**Static Approach (log4j-static-demo):** Log4j is included as a compile-time dependency in the Maven POM file. The application directly imports and uses Log4j classes, requiring Log4j to be present during compilation and at runtime.

**Dynamic Approach (log4j-dynamic-demo):** Log4j is NOT included as a compile-time dependency. Instead, the application loads Log4j JARs at runtime using URLClassLoader and invokes logging methods through Java reflection. This allows the application to compile without Log4j present, but requires the JARs to be available at runtime.

## Project Structure

```
log4j-week1/
├── log4j-static-demo/          # Static Log4j usage
│   ├── pom.xml                 # Includes Log4j dependencies
│   ├── src/main/java/com/example/App.java
│   └── src/main/resources/log4j2.xml
├── log4j-dynamic-demo/         # Dynamic Log4j usage
│   ├── pom.xml                 # NO Log4j dependencies
│   ├── src/main/java/com/example/App.java
│   ├── src/main/resources/log4j2.xml
│   └── runtime-libs/           # Log4j JARs loaded at runtime
│       ├── log4j-api-2.25.2.jar
│       ├── log4j-core-2.25.2.jar
│       └── README.md
└── README.md                   # This file
```

## Build and Run Instructions

### Static Demo

```bash
cd log4j-week1/log4j-static-demo

# Build the project
mvn clean package

# Run the application
java -cp target/log4j-static-demo-1.0-SNAPSHOT.jar:$(mvn -q dependency:build-classpath -Dmdep.outputFile=/dev/stdout) com.example.App
```

Expected output:

```
[14:00:00] INFO  com.example.App - Hello from STATIC Log4j app!
[14:00:00] WARN  com.example.App - This is a warning message from static Log4j
[14:00:00] ERROR com.example.App - This is an error message from static Log4j
Static app: logger call completed.
```

### Dynamic Demo

```bash
cd log4j-week1/log4j-dynamic-demo

# Build the project (compiles without Log4j dependencies)
mvn clean package

# Run the application (requires runtime-libs/ JARs)
java -cp target/log4j-dynamic-demo-1.0-SNAPSHOT.jar com.example.App
```

Expected output:

```
[14:05:00] INFO  com.example.App - Hello from DYNAMIC Log4j app!
[14:05:00] WARN  com.example.App - This is a warning message from dynamic Log4j
[14:05:00] ERROR com.example.App - This is an error message from dynamic Log4j
Dynamic app: logger invocation done.
```

## Verification Commands

### Check Maven Dependencies

```bash
# Static project should show Log4j dependencies
cd log4j-week1/log4j-static-demo
mvn dependency:tree | grep -i log4j

# Dynamic project should show NO Log4j dependencies
cd log4j-week1/log4j-dynamic-demo
mvn dependency:tree | grep -i log4j
```

### Inspect JAR Contents for Security

```bash
# Check for JndiLookup class (security concern)
cd log4j-week1/log4j-dynamic-demo/runtime-libs
jar tf log4j-core-2.25.2.jar | grep -i JndiLookup || echo "JndiLookup not found (good!)"

# List all classes in the core JAR
jar tf log4j-core-2.25.2.jar | head -20
```

### Mitigation Demo (Optional)

If JndiLookup is present, demonstrate safe removal:

```bash
# Create backup
cp log4j-core-2.25.2.jar log4j-core-2.25.2.jar.backup

# Remove JndiLookup class
zip -q -d log4j-core-2.25.2.jar org/apache/logging/log4j/core/lookup/JndiLookup.class

# Verify removal
jar tf log4j-core-2.25.2.jar | grep -i JndiLookup || echo "JndiLookup successfully removed"
```

## Deliverable Requirements

### What to Submit

1. **Screenshots or console logs** showing both applications running successfully
2. **Maven dependency tree output** for both projects
3. **JAR inspection results** showing presence/absence of JndiLookup
4. **Version information** (Log4j 2.25.2 used in this demo)

### Week 2 Preparation

- **SBOM Generation:** Next week, generate CycloneDX SBOMs for:
  - Static build using Maven CycloneDX plugin
  - Dynamic runtime folder using Syft
- **Vulnerability Scanning:** Use Grype to scan both projects for known vulnerabilities

## Safety Statement

**No exploit testing was performed.** This deliverable only demonstrates:

- Static vs dynamic library loading approaches
- Safe inspection of JAR contents
- Non-destructive mitigation techniques
- Local testing without network exposure

All testing was conducted in a controlled, local environment with no external network connections or exploit attempts. The focus is on understanding library loading mechanisms and security inspection techniques.

## Log4j Version Used

- **Version:** 2.25.2 (latest patched release as of 2024)
- **Source:** Apache Maven Central Repository
- **Security Status:** Contains all known security patches
- **Download Date:** $(date)

---

_This project was created for educational purposes to demonstrate different approaches to library loading in Java applications._
