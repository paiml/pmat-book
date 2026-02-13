# Chapter 46: Rust Best Practices (CB-500 to CB-518)

The CB-500 series detects generic Rust defect patterns that apply to **any** Rust project. These checks were motivated by cross-stack fault analysis of 10 batuta projects that revealed systematic gaps: extreme unwrap density (14.7/file in trueno-rag), missing clippy/deny configurations (5/10 projects), string byte indexing panics on non-ASCII input, and universally low Rust Tooling scores (<55%).

## Overview

```bash
# Run all compliance checks including CB-500 series
pmat comply check

# Example output:
# ⚠ CB-500: Rust Best Practices (CB-500 to CB-518): [Advisory] 0 errors, 189 warnings, 160 info:
# CB-506: String byte indexing (&str[n..m]) can panic on non-ASCII input (src/lib.rs:214)
# CB-501: 8 unwrap() calls in production code (threshold: 5) (src/parser.rs:0)
# ...
```

The CB-500 series is **advisory** — it reports with `Warn` status but does not block CI or commits. Violations are categorized into three severity tiers:

| Severity | Meaning | Example |
|----------|---------|---------|
| Error | Likely defect in production | >10 unwrap() per file |
| Warning | Code smell, should fix | String byte indexing, panic macros |
| Info | Suggestion, low priority | Missing clippy.toml, no deny.toml |

## Defect Taxonomy

### Project Configuration (CB-500, CB-503, CB-504, CB-505)

| ID | Check | Severity | What it detects |
|----|-------|----------|-----------------|
| CB-500 | Publish Hygiene | Warning | Missing `exclude` in Cargo.toml |
| CB-503 | Clippy Configuration | Info | Missing `.clippy.toml` or no `disallowed-methods` |
| CB-504 | Deny Configuration | Info | Missing `deny.toml` for supply chain security |
| CB-505 | Workspace Lint Hygiene | Warning | Missing `[lints]` or `[workspace.lints]` section |

### Code Quality (CB-501, CB-502, CB-506, CB-507, CB-508)

| ID | Check | Severity | What it detects |
|----|-------|----------|-----------------|
| CB-501 | Unwrap Density | Warning/Error | >5 (Warn) or >10 (Error) `unwrap()` per file |
| CB-502 | Expect Quality | Warning | `.expect("")`, `.expect("failed")` — lazy messages |
| CB-506 | String Byte Indexing | Warning | `&str[n..m]` can panic on non-ASCII input |
| CB-507 | Panic Macros | Warning | `todo!()`, `unimplemented!()` in production code |
| CB-508 | Lossy Numeric Casts | Warning | >10 `as u8`/`as i32`/etc. casts per file |

### Testing & Architecture (CB-509, CB-510, CB-511, CB-512)

| ID | Check | Severity | What it detects |
|----|-------|----------|-----------------|
| CB-509 | Feature Gate Coverage | Info | Features defined but no CI matrix testing |
| CB-510 | include!() Macro Hygiene | Info | Non-standalone files included via `include!()` |
| CB-511 | Flaky Timing Tests | Warning | `Instant::now()` with duration assertions in tests |
| CB-512 | Error Propagation Gap | Warning | Functions returning `Result` but using `unwrap()` internally |

### Error Handling & Debug Hygiene (CB-513, CB-514, CB-517)

| ID | Check | Severity | What it detects |
|----|-------|----------|-----------------|
| CB-513 | Silent Error Swallowing | Warning | `.unwrap_or_else(\|_\|` and `.map_err(\|_\|` discarding error context |
| CB-514 | Debug Eprintln Leaks | Warning | `eprintln!("[DEBUG`/`[DBG`/`[TRACE` in production code |
| CB-517 | Stale Debug Artifacts | Warning | `static AtomicUsize`/`AtomicBool` counters, `#[allow(unused)]` on statics |

### Pattern Safety (CB-515, CB-516, CB-518)

| ID | Check | Severity | What it detects |
|----|-------|----------|-----------------|
| CB-515 | Catch-All Match Default | Warning | `_ =>` returning concrete values instead of errors |
| CB-516 | Hardcoded Magic Numbers | Info | Large numeric literals in `Some()` or struct field contexts |
| CB-518 | Expensive Clone in Loop | Info | >3 `.clone()` calls inside `for`/`while`/`loop` bodies |

## Detection Algorithms

### CB-500: Publish Hygiene

Checks `Cargo.toml` for the `exclude` field that prevents publishing unnecessary files to crates.io:

```toml
# ✅ Good: Critical patterns excluded
[package]
exclude = [
    "target/",
    ".profraw",
    ".profdata",
    ".vscode/",
    ".idea/",
    ".pmat",
    "proptest-regressions",
]

# ❌ Bad: No exclude field - publishes everything
[package]
name = "my-crate"
version = "0.1.0"
```

Three sub-checks:
1. **Missing `exclude`**: If neither `exclude` nor `include` is present → Warning
2. **Include+Exclude conflict**: If both are present → Warning (Cargo ignores `exclude` when `include` is set)
3. **Insufficient patterns**: If `exclude` exists but covers <3 of 7 critical patterns → Info

### CB-501: Unwrap Density

Counts `.unwrap()` calls per file in production code, excluding test files and `#[cfg(test)]` regions:

```rust
// ❌ High density (CB-501 Warning at >5, Error at >10):
fn process(data: &str) -> String {
    let parsed = serde_json::from_str(data).unwrap();
    let field = parsed.get("key").unwrap();
    let value = field.as_str().unwrap();
    let num = value.parse::<i32>().unwrap();
    let result = compute(num).unwrap();
    format_output(result).unwrap()
}

// ✅ Better: Use ? operator or contextual errors
fn process(data: &str) -> Result<String, Error> {
    let parsed: Value = serde_json::from_str(data)?;
    let field = parsed.get("key").ok_or(Error::MissingField("key"))?;
    let value = field.as_str().ok_or(Error::TypeMismatch)?;
    let num: i32 = value.parse().map_err(Error::Parse)?;
    let result = compute(num)?;
    Ok(format_output(result))
}
```

### CB-502: Expect Quality

Detects lazy or uninformative `.expect()` messages. A good expect message explains **why** the invariant should hold, not just that it failed:

```rust
// ❌ Lazy messages detected by CB-502:
let config = load_config().expect("");
let handle = open_file().expect("failed");
let conn = connect().expect("error");
let val = parse().expect("unexpected");
let item = lookup().expect("should not happen");

// ✅ Informative messages:
let config = load_config().expect("config.toml must exist in project root");
let handle = open_file().expect("log file was verified writable in init()");
let conn = connect().expect("database URL validated at startup");
```

Flagged patterns: `""`, `"failed"`, `"error"`, `"unexpected"`, `"should not happen"`, `"todo"`, `"bug"`, `"impossible"`.

### CB-506: String Byte Indexing

Detects `&str[n..m]` patterns that panic on multi-byte UTF-8 input:

```rust
// ❌ Panics on non-ASCII (CB-506):
let prefix = &name[..3];
let suffix = &text[start..end];

// ✅ Safe alternatives:
let prefix = name.get(..3).unwrap_or(name);           // Returns None on boundary
let prefix = &name.chars().take(3).collect::<String>(); // Character-aware
let suffix = text.get(start..end).unwrap_or_default();  // Safe fallback
```

Uses regex `&\w+\[\d*\.\.\d*\]` to detect the pattern. Skips test code and comments.

### CB-507: Panic Macros

Detects `todo!()` and `unimplemented!()` in production code. These are useful during development but should be replaced before release:

```rust
// ❌ Panics at runtime (CB-507):
fn handle_edge_case(&self) -> Result<()> {
    todo!()
}

fn serialize_v2(&self) -> Vec<u8> {
    unimplemented!()
}

// ✅ Proper handling:
fn handle_edge_case(&self) -> Result<()> {
    Err(Error::NotSupported("edge case handling"))
}

fn serialize_v2(&self) -> Vec<u8> {
    self.serialize_v1()  // Fallback to v1
}
```

The detector skips macros that appear inside string literals (e.g., `"todo!() is a macro"`).

### CB-508: Lossy Numeric Casts

Detects files with >10 `as` casts to narrower types without bounds checking:

```rust
// ❌ Lossy casts (CB-508):
let byte = large_number as u8;      // Silently truncates
let small = big_float as f32;       // Loses precision
let signed = unsigned_val as i32;   // Can overflow

// ✅ Checked alternatives:
let byte = u8::try_from(large_number)?;
let small: f32 = big_float as f32;  // With #[allow(clippy::cast_possible_truncation)]
let signed = i32::try_from(unsigned_val).unwrap_or(i32::MAX);
```

Lines with `allow(clippy::cast` annotations are excluded from the count.

### CB-509: Feature Gate Coverage

Projects with >3 features in `Cargo.toml` should have CI matrix testing to ensure all feature combinations compile:

```yaml
# ✅ Good: CI tests feature combinations
jobs:
  test:
    strategy:
      matrix:
        features: ["default", "full", "minimal", "no-std"]
    steps:
      - run: cargo test --features ${{ matrix.features }}
```

### CB-510: include!() Macro Hygiene

Flags `include!()` macro usage because included files are not standalone compilable — they cannot be analyzed by tree-sitter, cause false positives in complexity gates, and break IDE tooling:

```rust
// ⚠ CB-510 Info:
include!("helpers/parse_utils.rs");  // Not standalone compilable

// ✅ Better: Use modules
mod parse_utils;  // Standard module system
```

### CB-511: Flaky Timing Tests

Detects tests that use `Instant::now()` with duration assertions, which are inherently flaky under CI load:

```rust
// ❌ Flaky under CI load (CB-511):
#[test]
fn test_cache_performance() {
    let start = Instant::now();
    cache.lookup("key");
    assert!(start.elapsed() < Duration::from_millis(10));  // Fails on slow CI
}

// ✅ Test behavior, not timing:
#[test]
fn test_cache_hit() {
    cache.insert("key", "value");
    assert_eq!(cache.lookup("key"), Some("value"));
}
```

### CB-512: Error Propagation Gap

Detects functions that return `Result<T, E>` but use `.unwrap()` >=3 times internally — a sign that error handling is incomplete:

```rust
// ❌ Returns Result but unwraps internally (CB-512):
fn parse_config(path: &Path) -> Result<Config, Error> {
    let content = fs::read_to_string(path)?;
    let parsed = toml::from_str(&content).unwrap();        // Why not ?
    let name = parsed.get("name").unwrap().as_str().unwrap(); // Two more unwraps
    Ok(Config { name: name.to_string() })
}

// ✅ Consistent error propagation:
fn parse_config(path: &Path) -> Result<Config, Error> {
    let content = fs::read_to_string(path)?;
    let parsed: toml::Value = toml::from_str(&content)?;
    let name = parsed.get("name")
        .and_then(|v| v.as_str())
        .ok_or(Error::MissingField("name"))?;
    Ok(Config { name: name.to_string() })
}
```

### CB-513: Silent Error Swallowing

Detects patterns where errors are intentionally discarded, hiding failure context. Motivated by GH-215 where silent error swallowing in quantization hid data corruption:

```rust
// ❌ Discards error context (CB-513):
let config = load_config().unwrap_or_else(|_| Config::default());
let data = parse(input).map_err(|_| MyError::ParseFailed)?;

// ✅ Preserve error context:
let config = load_config().unwrap_or_else(|e| {
    tracing::warn!("config load failed: {e}, using defaults");
    Config::default()
});
let data = parse(input).map_err(|e| MyError::ParseFailed { source: e })?;
```

The `|_|` closure parameter is the signal — it means the original error is being intentionally thrown away.

### CB-514: Debug Eprintln Leaks

Detects debug print statements left in production code. These leak internal state to stderr and indicate incomplete cleanup after debugging sessions:

```rust
// ❌ Debug output in production (CB-514):
eprintln!("[DEBUG] parsing token: {:?}", token);
eprintln!("[TRACE] entering function with state={}", state);
eprintln!("[DBG] cache size: {}", cache.len());

// ✅ Use structured logging:
tracing::debug!(?token, "parsing token");
tracing::trace!(state, "entering function");
log::debug!("cache size: {}", cache.len());
```

### CB-515: Catch-All Match Default

Detects `_ =>` match arms that return a concrete value instead of an error, `None`, or `unreachable!()`. Motivated by GH-236 where `_ => Architecture::Qwen2` caused all unknown model architectures to silently receive wrong configuration:

```rust
// ❌ Silent default (CB-515):
fn get_architecture(name: &str) -> Architecture {
    match name {
        "gpt" => Architecture::Gpt,
        "llama" => Architecture::Llama,
        _ => Architecture::Qwen2,  // All unknowns become Qwen2!
    }
}

// ✅ Explicit error on unknown:
fn get_architecture(name: &str) -> Result<Architecture, Error> {
    match name {
        "gpt" => Ok(Architecture::Gpt),
        "llama" => Ok(Architecture::Llama),
        _ => Err(Error::UnknownArchitecture(name.to_string())),
    }
}
```

Safe patterns that are **not** flagged: `Err(...)`, `None`, `unreachable!()`, `panic!()`, `return Err(...)`, `Default::default()`, `bail!()`, `todo!()`.

### CB-516: Hardcoded Magic Numbers

Detects large numeric literals (>100) in `Some()` or struct field contexts that likely represent configuration defaults. Motivated by GH-231 where a hardcoded `rope_theta: Some(10000.0)` default produced garbage output for models requiring different values:

```rust
// ❌ Hardcoded config defaults (CB-516 Info):
Config {
    rope_theta: Some(10000.0),  // Wrong for Qwen2 (uses 1000000.0)
    max_seq_len: Some(4096),
}

// ✅ Named constants with documentation:
const DEFAULT_ROPE_THETA: f64 = 10000.0;
const DEFAULT_MAX_SEQ_LEN: usize = 4096;

Config {
    rope_theta: Some(DEFAULT_ROPE_THETA),
    max_seq_len: Some(DEFAULT_MAX_SEQ_LEN),
}
```

This is **Info** severity — advisory only with expected false positives. Common values (128, 256, 512, 1024, etc.) are excluded.

### CB-517: Stale Debug Artifacts

Detects leftover debug instrumentation in production code — static atomic counters and `#[allow(unused)]` annotations on static variables that were used during debugging and not cleaned up:

```rust
// ❌ Leftover debug counter (CB-517):
static DEBUG_COUNTER: AtomicUsize = AtomicUsize::new(0);
fn process() {
    DEBUG_COUNTER.fetch_add(1, Ordering::Relaxed);
}

// ❌ Suppressed unused static (CB-517):
#[allow(unused)]
static TRACE_ENABLED: bool = false;

// ✅ Remove debug artifacts before committing, or use proper instrumentation:
fn process() {
    metrics::counter!("process_calls").increment(1);
}
```

### CB-518: Expensive Clone in Loop

Detects loop bodies with >3 `.clone()` calls, which often indicate that data should be borrowed or restructured to avoid repeated allocation:

```rust
// ❌ Excessive cloning in loop (CB-518):
for item in &items {
    let name = config.name.clone();
    let path = config.path.clone();
    let data = config.data.clone();
    let meta = config.meta.clone();
    process(item, &name, &path, &data, &meta);
}

// ✅ Clone once before the loop, or borrow:
let name = &config.name;
let path = &config.path;
for item in &items {
    process(item, name, path, &config.data, &config.meta);
}
```

This is **Info** severity — advisory, as some clones are necessary (e.g., sending data across threads).

## Test Code Exclusion

All file-scanning checks (CB-501, CB-502, CB-506–CB-508, CB-512–CB-518) exclude test code using two mechanisms:

1. **Test file exclusion**: Files matching `*_test.rs`, `*_tests.rs`, or under a `tests/` directory
2. **Test region exclusion**: Code inside `#[cfg(test)]` module blocks within production files

This prevents false positives from test code where `.unwrap()` and `todo!()` are acceptable.

## Self-Detection Avoidance

The detection code itself uses `concat!()` to avoid self-detection:

```rust
// The scanner uses split strings to avoid matching itself:
const DOT_UNWRAP: &str = concat!(".unwr", "ap()");
const DOT_EXPECT_QUOTE: &str = concat!(".expe", "ct(\"");
```

## Remediation Priority

When `pmat comply check` reports CB-500 violations, fix them in this priority order:

1. **CB-501 Errors** (>10 unwrap/file) — highest crash risk
2. **CB-515** — catch-all match arms silently returning wrong defaults (GH-236)
3. **CB-513** — silent error swallowing hiding data corruption (GH-215)
4. **CB-512** — functions claiming error handling but not doing it
5. **CB-506** — string indexing panics on internationalized input
6. **CB-507** — todo!/unimplemented! left in production
7. **CB-514, CB-517** — debug artifacts leaked to production
8. **CB-502** — lazy expect messages hide root cause during debugging
9. **CB-508** — lossy casts cause silent data corruption
10. **CB-500, CB-505** — project configuration hygiene
11. **CB-503, CB-504, CB-509, CB-510, CB-511, CB-516, CB-518** — informational, fix at leisure

## CI/CD Integration

```yaml
# .github/workflows/rust-best-practices.yml
name: Rust Best Practices
on: [push, pull_request]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install PMAT
        run: cargo install pmat
      - name: Check Rust Best Practices
        run: |
          OUTPUT=$(pmat comply check 2>&1)
          echo "$OUTPUT"
          # Fail on Error-severity violations
          if echo "$OUTPUT" | grep -q "CB-500.*errors: [1-9]"; then
            echo "::error::CB-500 series has Error-severity violations"
            exit 1
          fi
```

## Academic Foundations

The CB-500 checks are grounded in empirical research on Rust defect patterns:

| Paper | Finding | Applied To |
|-------|---------|-----------|
| Xu et al. (2021). "Memory-Safety Challenge Considered Solved?" | 30% of Rust CVEs involve unwrap/expect panics | CB-501, CB-502, CB-512 |
| Qin et al. (2020). "Understanding Memory and Thread Safety Practices" | Unsafe patterns cluster in specific files | CB-507, CB-508 |
| Evans et al. (2020). "Is Rust Used Safely?" | String boundary panics in 18% of crates | CB-506 |
| Zhu et al. (2022). "Learning and Programming Challenges of Rust" | Feature flag complexity is top-5 pain point | CB-509 |

## Specification Reference

Full detection logic: `src/cli/handlers/comply_cb_detect/rust_best_practices.rs`
Aggregate check: `src/cli/handlers/comply_handlers/check_handlers.rs` (`check_rust_best_practices`)
