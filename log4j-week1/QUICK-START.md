# Quick Start: strace Demo

## What You'll See

When you run `./demo-strace.sh`, you'll see output like this:

### Part 1: Static Loading Demo

```
╔════════════════════════════════════════════════════════════╗
║  DEMO 1: Static Loading (Compile-time dependency)          ║
╚════════════════════════════════════════════════════════════╝

▶️  Running application:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[14:00:00] INFO  com.example.App - Hello from STATIC Log4j app!
[14:00:00] WARN  com.example.App - This is a warning message from static Log4j
[14:00:00] ERROR com.example.App - This is an error message from static Log4j
Static app: logger call completed.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 strace output (file operations showing JAR loading):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
openat(AT_FDCWD, "/home/user/.m2/repository/.../log4j-core-2.25.2.jar", ...)
openat(AT_FDCWD, "/home/user/.m2/repository/.../log4j-api-2.25.2.jar", ...)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**What this shows:** JARs loaded from Maven cache (expected for static loading)

---

### Part 2: Dynamic Loading Demo

```
╔════════════════════════════════════════════════════════════╗
║  DEMO 2: Dynamic Loading (Runtime - NO dependencies!)      ║
╚════════════════════════════════════════════════════════════╝

▶️  Running application:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[14:05:00] INFO  com.example.App - Hello from DYNAMIC Log4j app!
[14:05:00] WARN  com.example.App - This is a warning message from dynamic Log4j
[14:05:00] ERROR com.example.App - This is an error message from dynamic Log4j
Dynamic app: logger invocation done.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 strace output (THE KEY PROOF - JARs opened at runtime):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
openat(AT_FDCWD, "runtime-libs/log4j-api-2.25.2.jar", O_RDONLY|O_CLOEXEC) = 15
openat(AT_FDCWD, "runtime-libs/log4j-core-2.25.2.jar", O_RDONLY|O_CLOEXEC) = 16

✅ PROOF: See 'runtime-libs/log4j-*.jar' being opened!
   This proves dynamic loading at runtime!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**What this shows:** JARs opened from `runtime-libs/` directory - **THIS IS THE PROOF!**

---

## The Key Difference

| Aspect           | Static Loading                | Dynamic Loading           |
| ---------------- | ----------------------------- | ------------------------- |
| **pom.xml**      | Has Log4j dependency          | NO Log4j dependency       |
| **SBOM**         | Static SBOM shows it          | Static SBOM MISSES it     |
| **strace shows** | JARs from `~/.m2/repository/` | JARs from `runtime-libs/` |
| **When loaded**  | At compile time               | At runtime                |

---

## How to Run

```bash
cd log4j-week1
./demo-strace.sh
```

That's it! The script shows everything automatically.

---

## What the Output Means

### Static Loading Output:

- App runs successfully ✅
- strace shows JARs from Maven cache
- Expected behavior for compile-time dependencies

### Dynamic Loading Output:

- App runs successfully ✅
- **strace shows JARs from `runtime-libs/`** ← THIS IS THE PROOF!
- This proves the JARs are loaded at runtime, not compile-time
- Matches what dynamic SBOM (Syft) finds in `sbom-dynamic.json`

---

## Where Are the Outputs?

1. **Console output** - Everything prints to your terminal
2. **App output** - Shows the log messages from running the Java apps
3. **strace output** - Shows the system calls (file operations) that prove dynamic loading

All outputs are shown **directly in your terminal** when you run the script!


