# Chapter 30: File Exclusions with .pmatignore

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (10/10 examples)
*Test-Driven: All examples validated in `tests/ch30/test_01_pmatignore.sh`*
*EXTREME TDD Quality Gates*: Unit tests (10/10), Real-world validation ✅
*Version*: PMAT v2.163.0+
<!-- DOC_STATUS_END -->

## Introduction

PMAT respects file exclusion patterns to help you focus on the code that matters. This chapter demonstrates how to use `.pmatignore` and `.paimlignore` files to exclude directories and files from analysis.

**Key Features**:
- 🎯 **Dual Format Support**: Both `.pmatignore` (current) and `.paimlignore` (legacy)
- 🔄 **Git Integration**: Automatic `.gitignore` respect
- 🚀 **Performance**: Efficient filtering using ripgrep-style walk
- 📝 **Flexible Syntax**: Comments, wildcards, and glob patterns

## Why File Exclusions Matter

When analyzing large codebases, you often want to exclude:
- Test directories during production quality checks
- Build artifacts and generated code
- Third-party dependencies
- Temporary files and caches
- Legacy code scheduled for removal

File exclusions improve analysis performance and focus quality metrics on code you maintain.

---

## Example 1: Basic .pmatignore File (TDD Verified)

**Test Location**: `tests/ch30/test_01_pmatignore.sh` line 64
**Command Tested**: `pmat analyze complexity --path . --format json`
**Test Validation**:
- ✅ Excludes 3 directories correctly
- ✅ Analyzes only 2 source files (src/main.rs, lib/utils.rs); `docs/README.md`
  is skipped for a different reason — Markdown has no complexity analyzer
- ✅ Verifies excluded files don't appear in output

### Project Structure

```
my-project/
├── .pmatignore
├── src/
│   └── main.rs
├── lib/
│   └── utils.rs
├── docs/
│   └── README.md
├── tests_disabled/
│   └── old_test.rs       # EXCLUDED
├── target/
│   └── debug/            # EXCLUDED
└── tmp/
    └── scratch.rs        # EXCLUDED
```

### .pmatignore File

```gitignore
# Exclude test directories
tests_disabled/
tests_disabled/**

# Exclude build artifacts
target/
target/**

# Exclude temporary files
tmp/
tmp/**
```

### Running Analysis

```bash
pmat analyze complexity --path . --format json
```

### Verified Output

Progress lines go to stderr; the JSON document goes to stdout, so `| jq` works
without any filtering. The stderr banner names the exclusion rule by name:

```
✅ Successfully analyzed 2 file(s)
   4 of 6 file(s) were not analyzed
   no complexity analyzer for: .md (1)
   excluded by ignore rules (.pmatignore/.paimlignore, vendored, generated): .rs (3)
```

And the document on stdout (trimmed here to the fields that matter — the real
one carries per-function metrics as well):

```json
{
  "summary": {
    "total_files": 2,
    "total_functions": 2,
    "median_cyclomatic": 1.5,
    "median_cognitive": 0.5,
    "max_cyclomatic": 2,
    "max_cognitive": 1,
    "p90_cyclomatic": 2,
    "p90_cognitive": 1,
    "technical_debt_hours": 0
  },
  "violations": [],
  "hotspots": [],
  "files": [
    { "path": "./lib/utils.rs", "functions": [ { "name": "helper" } ] },
    { "path": "./src/main.rs",  "functions": [ { "name": "main"   } ] }
  ]
}
```

Note that `docs/README.md` is *not* excluded — it is simply not a complexity
target, which the stderr banner reports separately (`no complexity analyzer
for: .md`). Only the three `.rs` files under `tests_disabled/`, `target/` and
`tmp/` were dropped by `.pmatignore`.

**Result**: Only 3 files analyzed, excluded directories correctly ignored.

---

## Example 2: Legacy .paimlignore Support (TDD Verified)

**Test Location**: `tests/ch30/test_01_pmatignore.sh` line 113
**Command Tested**: `pmat analyze complexity --path . --format json`
**Test Validation**:
- ✅ Recognizes legacy `.paimlignore` filename
- ✅ Applies exclusion patterns correctly
- ✅ Backward compatibility maintained

### .paimlignore File

```gitignore
# Legacy ignore file format (still supported!)
tests_disabled/
target/
```

### Running Analysis

```bash
pmat analyze complexity --path . --format json
```

**Result**: PMAT respects legacy `.paimlignore` files for backward compatibility with older projects that used the "paiml" naming.

---

## Example 3: .pmatignore Precedence (TDD Verified)

**Test Location**: `tests/ch30/test_01_pmatignore.sh` line 132
**Command Tested**: `pmat analyze complexity --path . --format json`
**Test Validation**:
- ✅ `.pmatignore` takes precedence over `.paimlignore`
- ✅ Only `.pmatignore` patterns applied

When both `.pmatignore` and `.paimlignore` exist, **`.pmatignore` takes precedence**.

### Project With Both Files

```
my-project/
├── .pmatignore           # THIS ONE WINS
├── .paimlignore          # IGNORED
└── src/
```

### .pmatignore (Applied)

```gitignore
tests_disabled/
target/
tmp/
```

### .paimlignore (Ignored)

```gitignore
# This file is ignored because .pmatignore exists
```

**Result**: Only `.pmatignore` patterns are applied.

---

## Example 4: Wildcard Patterns (TDD Verified)

**Test Location**: `tests/ch30/test_01_pmatignore.sh` line 151
**Command Tested**: `pmat analyze complexity --path . --format json`
**Test Validation**:
- ✅ `cache/**` excludes all cache subdirectories
- ✅ Wildcard patterns work correctly

### Project Structure

```
my-project/
├── .pmatignore
├── src/
│   └── main.rs
└── cache/
    ├── temp/
    │   └── cache.rs      # EXCLUDED
    └── data/
        └── data.rs       # EXCLUDED
```

### .pmatignore With Wildcards

```gitignore
# Exclude all cache subdirectories
cache/**
```

### Running Analysis

```bash
pmat analyze complexity --path . --format json
```

**Result**: All files under `cache/` are excluded, regardless of nesting depth.

---

## Example 5: Comment Syntax (TDD Verified)

**Test Location**: `tests/ch30/test_01_pmatignore.sh` line 168
**Command Tested**: `pmat analyze complexity --path . --format json`
**Test Validation**:
- ✅ Comments starting with `#` are ignored
- ✅ Inline comments work correctly
- ✅ Exclusion patterns still applied

### .pmatignore With Comments

```gitignore
# This is a full-line comment
tests_disabled/  # This is an inline comment

# Another comment
target/
```

**Result**: Comments are ignored, exclusion patterns work as expected.

---

## Example 6: .gitignore Integration (TDD Verified)

**Test Location**: `tests/ch30/test_01_pmatignore.sh` line 186
**Command Tested**: `pmat analyze complexity --path . --format json`
**Test Validation**:
- ✅ `.gitignore` patterns automatically respected
- ✅ Build artifacts excluded via `.gitignore`

PMAT automatically respects `.gitignore` files in your repository.

### Project Structure

```
my-project/
├── .gitignore            # Git exclusions
├── src/
│   └── main.rs
└── build/
    └── output.rs         # EXCLUDED by .gitignore
```

### .gitignore File

```gitignore
build/
*.log
```

### Running Analysis

```bash
pmat analyze complexity --path . --format json
```

**Result**: Files matching `.gitignore` patterns are automatically excluded.

---

## Example 7: Complex Real-World Scenario (TDD Verified)

**Test Location**: `tests/ch30/test_01_pmatignore.sh` line 202
**Command Tested**: `pmat analyze complexity --path . --format json`
**Test Validation**:
- ✅ Finds exactly 2 source files
- ✅ Excludes all test directories (unit, integration, e2e)
- ✅ Excludes all build artifacts

### Realistic Project Structure

```
web-service/
├── .pmatignore
├── src/
│   ├── core/
│   │   └── main.rs       # ANALYZED
│   ├── utils/
│   │   └── helpers.rs    # ANALYZED
│   └── api/
├── tests/
│   ├── unit/             # EXCLUDED
│   ├── integration/      # EXCLUDED
│   └── e2e/              # EXCLUDED
└── target/
    ├── debug/            # EXCLUDED
    └── release/          # EXCLUDED
```

### .pmatignore for Production Code Only

```gitignore
# Exclude all test directories
tests/
tests/**

# Exclude build artifacts
target/
target/**
```

### Running Analysis

```bash
pmat analyze complexity --path . --format json
```

### Verified Output

On stderr, the count of what was dropped and why:

```
✅ Successfully analyzed 2 file(s)
   5 of 7 file(s) were not analyzed
   excluded by ignore rules (.pmatignore/.paimlignore, vendored, generated): .rs (5)
```

On stdout (trimmed to the fields that matter):

```json
{
  "summary": {
    "total_files": 2,
    "total_functions": 2,
    "median_cyclomatic": 1.5,
    "median_cognitive": 0.5,
    "max_cyclomatic": 2,
    "max_cognitive": 1,
    "technical_debt_hours": 0
  },
  "violations": [],
  "hotspots": [],
  "files": [
    { "path": "./src/utils/helpers.rs", "functions": [ { "name": "helpers" } ] },
    { "path": "./src/core/main.rs",     "functions": [ { "name": "main"    } ] }
  ]
}
```

**Result**: Only production source code analyzed, all tests and build artifacts excluded.

---

## Example 8: Empty .pmatignore File (TDD Verified)

**Test Location**: `tests/ch30/test_01_pmatignore.sh` line 264
**Command Tested**: `pmat analyze complexity --path . --format json`
**Test Validation**:
- ✅ Empty `.pmatignore` doesn't exclude files
- ✅ Only `.gitignore` exclusions apply

### Empty .pmatignore

```gitignore
# Empty file - no exclusions
```

**Result**: An empty `.pmatignore` file doesn't exclude anything. Only `.gitignore` patterns apply.

---

## Example 9: Case Sensitivity (TDD Verified)

**Test Location**: `tests/ch30/test_01_pmatignore.sh` line 281
**Command Tested**: `pmat analyze complexity --path . --format json`
**Test Validation**:
- ✅ Pattern matching is case-sensitive
- ✅ Lowercase `tests/` doesn't match `Tests/` or `TESTS/`

### Project Structure

```
my-project/
├── .pmatignore
├── Tests/
│   └── test1.rs          # NOT EXCLUDED (capital T)
├── TESTS/
│   └── test2.rs          # NOT EXCLUDED (all caps)
└── tests/
    └── test3.rs          # EXCLUDED (lowercase)
```

### .pmatignore (Case-Sensitive)

```gitignore
tests/
```

**Result**: Only lowercase `tests/` is excluded. Case sensitivity follows filesystem conventions.

---

## Example 10: Performance With Large Exclusion List (TDD Verified)

**Test Location**: `tests/ch30/test_01_pmatignore.sh` line 304
**Command Tested**: `pmat analyze complexity --path . --format json`
**Test Validation**:
- ✅ Analysis completes in < 5 seconds
- ✅ Finds all 50 source files correctly
- ✅ Large exclusion list doesn't degrade performance

### Project With 50 Source Files

```
large-project/
├── .pmatignore           # 15+ exclusion patterns
└── src/
    ├── file_1.rs
    ├── file_2.rs
    ...
    └── file_50.rs
```

### Large .pmatignore File

```gitignore
# Large exclusion list
target/
tests/
build/
dist/
node_modules/
vendor/
.git/
.svn/
cache/
tmp/
temp/
logs/
*.log
*.tmp
*.bak
```

### Running Analysis

```bash
time pmat analyze complexity --path . --format json
```

**Result**: Analysis completes in ~2-3 seconds despite large exclusion list. PMAT uses efficient ripgrep-style filtering.

---

## Best Practices

### 1. Use .pmatignore for New Projects

```gitignore
# .pmatignore (recommended for new projects)
tests/
target/
build/
dist/
```

### 2. Keep .paimlignore for Legacy Projects

If you have an existing `.paimlignore` file, it will continue to work. No migration needed.

### 3. Combine with .gitignore

Let `.gitignore` handle version control exclusions, use `.pmatignore` for analysis-specific exclusions:

```gitignore
# .gitignore (version control)
target/
*.log

# .pmatignore (analysis-specific)
legacy_code/
experimental/
```

### 4. Use Comments for Clarity

```gitignore
# Third-party dependencies
vendor/
node_modules/

# Generated code
build/
dist/

# Test fixtures
tests/fixtures/
```

### 5. Test Your Exclusions

Verify your exclusion patterns work:

```bash
# Check file count
pmat analyze complexity --path . --format json | jq '.summary.total_files'

# List analyzed files
pmat analyze complexity --path . --format json | jq -r '.files[].path'
```

---

## Common Patterns

### Rust Projects

```gitignore
target/
Cargo.lock
*.rs.bk
```

### Python Projects

```gitignore
__pycache__/
*.pyc
.pytest_cache/
venv/
.venv/
```

### JavaScript Projects

```gitignore
node_modules/
dist/
build/
coverage/
*.min.js
```

### Multi-Language Projects

```gitignore
# Build artifacts
target/
build/
dist/
out/

# Dependencies
node_modules/
vendor/
venv/

# Tests
tests/
test/
__tests__/

# Generated code
generated/
*.gen.*
```

---

## Troubleshooting

### Problem: Files Still Being Analyzed

**Solution**: Check pattern syntax

```gitignore
# ❌ Wrong - missing trailing slash
tests

# ✅ Correct - directory exclusion
tests/
tests/**
```

### Problem: Wildcard Not Working

**Solution**: Use `**` for recursive matching

```gitignore
# ❌ Wrong - only matches top-level
cache/*

# ✅ Correct - matches all subdirectories
cache/**
```

### Problem: .pmatignore Not Recognized

**Solution**: Verify file location

```bash
# Must be in project root
ls -la .pmatignore

# Check PMAT version (v2.163.0+ required)
pmat --version
```

---

## Technical Details

### Implementation

PMAT uses the `ignore` crate (from ripgrep) for efficient file filtering:

1. **WalkBuilder**: Traverses directory tree
2. **Custom Ignore Files**: `.pmatignore` and `.paimlignore`
3. **Standard Filters**: `.gitignore`, `.ignore`, `.git/info/exclude`
4. **Performance**: Parallel directory walking with efficient pruning

### Precedence Order

1. `.pmatignore` (if exists)
2. `.paimlignore` (if no `.pmatignore`)
3. `.gitignore`
4. `.ignore`
5. `.git/info/exclude`

### Pattern Syntax

Follows standard gitignore syntax:
- `foo/` - Exclude directory
- `*.log` - Exclude by extension
- `foo/**` - Exclude recursively
- `!important.log` - Negate pattern (include despite other exclusions)
- `#` - Comment

---

## Summary

File exclusions in PMAT provide:
- ✅ **Dual format support** (.pmatignore and .paimlignore)
- ✅ **Automatic .gitignore integration**
- ✅ **Flexible pattern syntax** (wildcards, comments, negation)
- ✅ **High performance** (ripgrep-style filtering)
- ✅ **Case-sensitive matching**
- ✅ **EXTREME TDD validation** (10/10 tests passing)

**All examples in this chapter are validated by automated tests** in `tests/ch30/test_01_pmatignore.sh`. Every command, output, and edge case has been verified using EXTREME TDD methodology.

---

## Related Chapters

- [Chapter 1: First Analysis](ch01-02-first-analysis-tdd.md) - Basic PMAT usage
- [Chapter 5: Analyze Command Suite](ch05-00-analyze-suite.md) - Advanced analysis options
- [Chapter 7: Quality Gates](ch07-00-quality-gate.md) - Pre-commit hook integration

---

**Chapter Validation**: ✅ All 10 examples tested and verified in v2.163.0
**Quality Gate**: 🟢 EXTREME TDD validated, NASA-style quality assurance
**Test Script**: `tests/ch30/test_01_pmatignore.sh` (10/10 passing)
