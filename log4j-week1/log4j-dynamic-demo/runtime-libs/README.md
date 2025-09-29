# Runtime Libraries for Dynamic Log4j Demo

This directory should contain the following JAR files for the dynamic Log4j demo to work:

- `log4j-api-2.25.2.jar`
- `log4j-core-2.25.2.jar`

## Download Instructions

1. Visit the Apache Log4j download page: https://logging.apache.org/log4j/2.x/download.html
2. Download the latest 2.25.2 version (or newer patched version)
3. Extract the JAR files from the downloaded archive
4. Place both JAR files in this directory

## Alternative Download Commands

You can also download the JARs directly using curl or wget:

```bash
# Download log4j-api-2.25.2.jar
curl -L -o log4j-api-2.25.2.jar "https://repo1.maven.org/maven2/org/apache/logging/log4j/log4j-api/2.25.2/log4j-api-2.25.2.jar"

# Download log4j-core-2.25.2.jar
curl -L -o log4j-core-2.25.2.jar "https://repo1.maven.org/maven2/org/apache/logging/log4j/log4j-core/2.25.2/log4j-core-2.25.2.jar"
```

## Verification

After downloading, verify the files exist:

```bash
ls -la *.jar
```

The dynamic demo will check for these files and provide helpful error messages if they're missing.
