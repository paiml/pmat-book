# Multi-Language Detection

PMAT provides intelligent multi-language detection with confidence scoring, enabling accurate analysis of polyglot projects.

## Overview

The enhanced language detection system (introduced in v2.184.0) solves critical issues with language misidentification and provides:

- **Confidence scoring** - Know how certain PMAT is about the detected language
- **Primary indicators** - Recognizes build files (Cargo.toml, CMakeLists.txt, etc.)
- **Multi-language projects** - Detects and analyzes all languages in polyglot codebases
- **Manual overrides** - Control language detection when needed

## Quick Start

### Automatic Detection

PMAT automatically detects your project's primary language:

```bash
# Analyze with auto-detection
pmat context

# Example output:
# 🔍 Detecting project language...
# ✅ Detected: cpp (confidence: 95.0%)
```

### Confidence Scoring

The confidence score indicates how certain PMAT is:

- **90-100%**: Very confident (has primary indicator file)
- **70-89%**: Confident (high percentage of files)
- **50-69%**: Moderate confidence
- **<50%**: Low confidence (may need manual override)

## Primary Indicators

PMAT recognizes these build/config files to boost confidence:

| File | Language | Confidence Boost |
|------|----------|------------------|
| `Cargo.toml` | Rust | +90% |
| `CMakeLists.txt` | C++ | +85% |
| `go.mod` | Go | +90% |
| `pyproject.toml` | Python | +50% |
| `package.json` | JS/TS | +30% |

### Example: C++ Project

```bash
# Project structure:
# myproject/
# ├── CMakeLists.txt  ← Primary indicator
# ├── src/
# │   ├── main.cpp
# │   └── utils.cpp
# └── tests/
#     └── test.py     ← Some Python scripts

pmat context

# Output:
# ✅ Detected: cpp (confidence: 95.0%)
# - 70% C++ files
# - CMakeLists.txt found (+85% boost)
# - 30% Python files (helper scripts)
```

## Polyglot Projects

### Detecting All Languages

PMAT can detect all languages in your project (those with >5% of files):

```rust
use pmat::services::enhanced_language_detection::detect_all_languages;
use std::path::Path;

let detection = detect_all_languages(Path::new("."));

println!("Primary: {}", detection.primary);
for lang in detection.languages {
    println!("{}: {:.1}% ({} files, confidence: {:.1}%)",
        lang.language,
        lang.percentage,
        lang.file_count,
        lang.confidence
    );
}

// Example output:
// Primary: rust
// rust: 45.0% (450 files, confidence: 95.0%)
// python: 30.0% (300 files, confidence: 35.0%)
// typescript: 25.0% (250 files, confidence: 28.0%)
```

### Multi-Language Analysis

For polyglot projects, PMAT analyzes all significant languages:

```bash
# Future feature (planned for v2.185.0):
pmat context --languages rust,python,typescript

# This will analyze all three languages and generate:
# - Combined complexity metrics
# - Language-specific insights
# - Cross-language dependency analysis
```

## Manual Override

### Override Primary Language

When auto-detection fails or you want to force a specific language:

```rust
use pmat::services::enhanced_language_detection::override_language_detection;
use std::path::Path;

let detection = override_language_detection(Path::new("."), "cpp");

assert_eq!(detection.language, "cpp");
assert_eq!(detection.confidence, 100.0); // Manual = 100% confidence
```

### Override Multiple Languages

Specify exactly which languages to analyze:

```rust
use pmat::services::enhanced_language_detection::override_multiple_languages;
use std::path::Path;

let languages = vec!["rust".to_string(), "python".to_string()];
let detection = override_multiple_languages(Path::new("."), languages);

// Only Rust and Python will be analyzed
// TypeScript (if present) will be ignored
```

## Supported Languages

PMAT detects 14+ programming languages:

| Language | Extensions |
|----------|-----------|
| Rust | `.rs` |
| C++ | `.cpp`, `.cc`, `.cxx`, `.hpp`, `.hxx`, `.h++`, `.c++` |
| C | `.c`, `.h` |
| Python | `.py` |
| JavaScript | `.js`, `.jsx` |
| TypeScript | `.ts`, `.tsx` |
| Go | `.go` |
| Java | `.java` |
| Kotlin | `.kt`, `.kts` |
| Ruby | `.rb` |
| PHP | `.php` |
| Swift | `.swift` |
| C# | `.cs` |
| Bash | `.sh`, `.bash` |

## Real-World Examples

### Example 1: Ceph (C++ Project)

Before fix (BUG-011):
```bash
pmat context
# ❌ Detected: python-uv (confidence: 57.2%)  # WRONG!
# [hangs indefinitely on discovery...]
```

After fix:
```bash
pmat context
# ✅ Detected: cpp (confidence: 95.0%)  # CORRECT!
# - CMakeLists.txt found
# - 70% C++ files (.cc, .h)
# - 20% Python files (helper scripts)
# - 10% Shell scripts (build tools)
```

### Example 2: Monorepo (Rust + TypeScript)

```bash
# Project: my-monorepo/
# ├── Cargo.toml
# ├── backend/  (Rust - 60%)
# ├── frontend/ (TypeScript - 35%)
# └── scripts/  (Python - 5%)

pmat context

# ✅ Detected primary: rust (confidence: 95.0%)
# Also detected: typescript (35.0%, confidence: 38.0%)
# Also detected: python (5.0%, confidence: 5.0%)
```

### Example 3: Low Confidence Warning

```bash
# Project with equal Rust and Python (no Cargo.toml)

pmat context

# ⚠️ Detected: rust (confidence: 52.0%)
# Low confidence (<70%). Consider using --language flag.
# Detected languages:
#   - Rust: 50.0%
#   - Python: 50.0%

# Manual override recommended:
pmat context --language python  # Force Python analysis
```

## Testing Language Detection

PMAT includes comprehensive tests for language detection:

```bash
# Run language detection tests
cargo test --test bug_011_language_detection_tests -- --ignored

# Run example
cargo run --example bug_011_language_detection
```

### Test Coverage

The test suite includes:

- ✅ C++ project detection with CMakeLists.txt
- ✅ Confidence calculation (C++ vs Python)
- ✅ Multi-language detection (Rust + Python + TypeScript)
- ✅ Languages below 5% threshold filtered out
- ✅ Primary indicator confidence boost
- ✅ Manual language override
- ✅ Multi-language manual override
- ✅ Timeout handling (30s)
- ✅ Discovery completion within bounds

## Implementation Details

### Confidence Calculation

```
Confidence = File Percentage + Primary Indicator Boost

Example:
- 70% C++ files = 70 points
- CMakeLists.txt found = +85 points
- Total confidence = min(155, 100) = 100%
```

### 5% Threshold

Languages with <5% of files are filtered out to reduce noise:

```
Project:
- Rust: 90% ✅ Included
- Python: 8% ✅ Included
- Shell: 2% ❌ Filtered (below threshold)
```

### File Counting

PMAT recursively counts files by extension:

```
src/
  ├── main.rs (1)
  ├── lib.rs (1)
  └── utils.rs (1)
scripts/
  └── build.sh (1)

Total: 4 files
Rust: 75% (3/4)
Shell: 25% (1/4)
```

## Troubleshooting

### Wrong Language Detected

**Problem**: PMAT detects Python but your project is C++

**Solution**:
```bash
# Check what PMAT sees
pmat context --dry-run

# Manual override
pmat context --language cpp
```

### No Primary Indicator

**Problem**: Equal Rust/Python files, no Cargo.toml or pyproject.toml

**Solution**: Add a primary indicator file:
```bash
# For Rust project:
cargo init

# For Python project:
touch pyproject.toml
echo "[project]" >> pyproject.toml
echo "name = \"myproject\"" >> pyproject.toml
```

### Polyglot Analysis Not Working

**Problem**: Want to analyze both Rust and Python but only Rust is analyzed

**Status**: Multi-language analysis coming in v2.185.0 (BUG-012)

**Workaround**: Run analysis twice:
```bash
pmat context --language rust -o rust_context.md
pmat context --language python -o python_context.md
```

## Next Steps

- [Chapter 13.2: Multi-Language Context Generation](ch13-02-multi-language-context.md) (Coming in v2.185.0)
- [Chapter 13.3: Language-Specific Analysis](ch13-03-language-specific.md)
- [Chapter 5: Analysis Suite](ch05-00-analyze-suite.md)

## Related Issues

- **BUG-011**: Language Detection Hang - ✅ FIXED in v2.184.0
- **BUG-012**: Multi-Language Support Missing - 🚧 Planned for v2.185.0
- **TICKET-3001-3006**: Unified language analyzers

## Further Reading

- [Language Analyzer Source](https://github.com/paiml/paiml-mcp-agent-toolkit/blob/master/server/src/services/enhanced_language_detection.rs)
- [Test Suite](https://github.com/paiml/paiml-mcp-agent-toolkit/blob/master/server/tests/bug_011_language_detection_tests.rs)
- [Example Usage](https://github.com/paiml/paiml-mcp-agent-toolkit/blob/master/server/examples/bug_011_language_detection.rs)
