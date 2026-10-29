# First Analysis - Test-Driven Documentation

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (8/8 examples)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 8 | All examples tested via `make test-ch01` |
| ⚠️ Not Implemented | 0 | Planned for future versions |
| ❌ Broken | 0 | Known issues, needs fixing |
| 📋 Planned | 0 | Future roadmap features |

*Last updated: 2025-10-26*  
*PMAT version: pmat 2.213.1*  
*Test-Driven: All examples validated in `tests/ch01/test_02_first_analysis.sh`*
<!-- DOC_STATUS_END -->

## Test-First Approach

Every example in this chapter follows TDD principles:
1. **Test Written First**: Each example has corresponding test validation
2. **Red-Green-Refactor**: Tests fail until implementation works
3. **Automated Validation**: Run `make test-ch01` to verify all examples

```bash
# Run all Chapter 1 tests
make test-ch01

# Output shows each test passing
✅ PASS: Current directory analysis  
✅ PASS: JSON output contains repository info
✅ PASS: Python files detected
✅ PASS: TDG analysis complete
✅ PASS: Summary format contains file count
```

## Example 1: Basic Analysis (TDD Verified)

**Test Location**: `tests/ch01/test_02_first_analysis.sh` line 83

This test creates a controlled environment with known files:

```python
# Test creates: src/main.py
def calculate_sum(a, b):
    """Calculate sum of two numbers."""
    return a + b

def calculate_product(a, b):
    """Calculate product of two numbers."""
    return a * b
```

```python  
# Test creates: src/utils.py
def validate_input(value):
    """Validate input value."""
    if not isinstance(value, (int, float)):
        raise ValueError("Input must be a number")
    return True
```

**Command Tested**:
```bash
pmat analyze comprehensive
```

`analyze` is a parent command. `pmat analyze .`, which earlier printings of
this chapter presented as the first command a reader runs, exits 2 with
`error: unrecognized subcommand`.
`comprehensive` is the subcommand that runs the suite, and `--path` defaults to
`.`. The test now asserts *both* directions: that `pmat analyze comprehensive`
succeeds, and that `pmat analyze .` fails, so the old form cannot creep back in
unnoticed.

**Test Validation**:
- ✅ Command executes successfully (exit code 0)
- ✅ `pmat analyze .` is rejected (exit code 2)
- ✅ JSON output carries a `summary` section
- ✅ At least one file is analyzed

**Verified Output Structure** (`--format json`, trimmed):
```json
{
  "summary": {
    "total_files": 3,
    "total_issues": 0,
    "critical_issues": 0,
    "quality_score": 100,
    "recommendations": [
      "Code quality looks good! Continue following best practices."
    ]
  },
  "dead_code": null,
  "satd": {
    "census": {
      "discovered": 3,
      "analyzed": 2,
      "not_read": { "tests": 1, "out_of_scope": 0, "minified_or_vendor": 0, "too_large": 0, "unreadable": 0 }
    }
  }
}
```

`"dead_code": null` is load-bearing. Dead-code analysis is Rust-only, and on a
Python project PMAT reports that it did not run rather than reporting `0`. The
test asserts `null` specifically — a `0` there would be a metric that measures
nothing while looking clean.

## Example 2: Technical Debt Grading (TDD Verified)

**Test Location**: `tests/ch01/test_02_first_analysis.sh` line 130

**Command Tested**:
```bash
pmat analyze tdg --path .
```

`analyze tdg` takes its path through `-p`/`--path`. `pmat analyze tdg .` fails
with `error: unexpected argument found` — the test asserts that too. (The
*top-level* `pmat tdg` command does accept a positional path: `pmat tdg .`.)

**Test Validation**:
- ✅ TDG analysis completes
- ✅ `average_grade` exists in output
- ✅ `average_score` is present
- ✅ `pmat analyze tdg .` is rejected

**Verified Output Structure** (project summary; `.files[]` omitted here):
```json
{
  "average_score": 96.45316,
  "average_grade": "A+",
  "not_measured": [],
  "total_files": 3,
  "language_distribution": { "Python": 2, "Markdown": 1 },
  "grade_distribution": { "A+": 2, "A": 1 },
  "f_grade_count": 0,
  "grade_capped": false,
  "files_reported": 3,
  "files_truncated": false,
  "ungraded_files": [],
  "cross_file_duplication_ratio": 0,
  "cross_file_duplication_coverage": { "measured": 2, "total": 3 }
}
```

The keys are `average_grade`/`average_score`, not `grade`/`overall_score`, and
the per-file component breakdown lives under `.files[]` (or in the table printed
by `--include-components`), not under a top-level `components` object.

## Example 3: JSON Output Format (TDD Verified)

**Test Location**: `tests/ch01/test_02_first_analysis.sh` line 105

**Command Tested**:
```bash
pmat analyze comprehensive --path . --format json
```

**Test Validation**:
- ✅ Output is valid JSON (parsed by `jq`)
- ✅ `summary` section exists
- ✅ `complexity` section exists
- ✅ `satd.census` reports the population that was read

**JSON Schema Validation**:
```bash
# Test verifies these fields exist
echo "$OUTPUT" | jq -e '.summary.total_files'
echo "$OUTPUT" | jq -e '.complexity.summary'
echo "$OUTPUT" | jq -e '.satd.census.analyzed'
```

Progress lines go to stderr and the JSON document to stdout, so no `grep '^{'`
filtering is needed before piping into `jq`.

## Example 4: Language Detection (TDD Verified)

**Test Location**: `tests/ch01/test_02_first_analysis.sh` line 171

**Test Setup**: Creates multi-language project:
- Python files (`.py`)
- Markdown files (`.md`)
- Test files (`test_*.py`)

**Test Validation**:
- ✅ Python language detected
- ✅ Markdown language detected
- ✅ File counts accurate
- ✅ Percentages calculated correctly

**Verified Language Detection** — from `pmat analyze tdg --path . --format json`:
```json
{
  "language_distribution": {
    "Python": 2,
    "Markdown": 1
  },
  "total_files": 3
}
```

The distribution is a plain file count per language. There is no per-language
line count and no percentage field; percentages appear only in the human-readable
table that `pmat analyze tdg` prints without `--format json`.

## Example 5: Complexity Metrics (TDD Verified)

**Test Location**: `tests/ch01/test_02_first_analysis.sh` line 180

**Test Creates Functions With Known Complexity**:
```python
# Simple function (complexity = 1)
def simple_function():
    return "hello"

# Complex function (complexity = 4)
def complex_function(x):
    if x > 0:
        if x < 10:
            return "small positive"
        else:
            return "large positive"
    else:
        return "negative or zero"
```

**Test Validation**:
- ✅ Complexity metrics calculated
- ✅ Average complexity reasonable
- ✅ Max complexity detected
- ✅ No division by zero errors

## Example 6: Recommendations Engine (TDD Verified)

**Test Location**: `tests/ch01/test_02_first_analysis.sh` line 189

**Test Creates Code With Known Issues**:
```python
# Missing docstring (documentation issue)
def undocumented_function():
    pass

# High complexity (refactoring recommendation)
def very_complex_function(a, b, c, d):
    if a:
        if b:
            if c:
                if d:
                    return "nested"
    return "default"
```

**Test Validation**:
- ✅ Recommendations array exists
- ✅ At least one recommendation provided
- ✅ Recommendations have priority levels
- ✅ Effort estimates included

**Verified Recommendations** — `recommendations` lives under `summary` in the
`analyze comprehensive` document, and is a list of plain strings:
```json
{
  "summary": {
    "total_issues": 4,
    "critical_issues": 4,
    "quality_score": 90.0,
    "recommendations": [
      "Consider refactoring high-complexity functions",
      "Address technical debt items (TODO/FIXME comments)"
    ]
  }
}
```

There are no per-recommendation `priority`, `location` or `effort` fields.
Locations come from the violation lists — `complexity.violations[]` and
`satd.violations[]` — each of which carries `file_path`, `line_number` and a
severity.

## Example 7: Single File Analysis (TDD Verified)

**Test Location**: `tests/ch01/test_02_first_analysis.sh` line 163

**Command Tested**:
```bash
pmat analyze complexity --file src/main.py
```

A single file goes through `--file`, not as a positional argument. The banner
confirms the scope: `🔍 Analyzing complexity of file: src/main.py`.

**Test Validation**:
- ✅ Single file analysis works
- ✅ Output focuses on specified file
- ✅ Analysis completes successfully

## Example 8: Summary Format (TDD Verified)

**Test Location**: `tests/ch01/test_02_first_analysis.sh` line 155

**Command Tested**:
```bash
pmat analyze comprehensive --path . --executive-summary
```

There is no `--summary` flag. `--executive-summary` is the real one, and
`--format summary` is the default anyway.

**Test Validation**:
- ✅ Summary contains "Total Files:" keyword
- ✅ Human-readable format
- ✅ Concise output for quick overview

**Verified Summary Output**:
```
Comprehensive Code Analysis Report

Executive Summary

  Project analysis completed with 3 total files analyzed.

  Quality Score: 100.0%
  Total Files:   3
  Total Issues:  0
  Critical:      0

  Key Recommendations

    - Code quality looks good! Continue following best practices.
```

## Running the Tests Yourself

Verify all examples work on your system:

```bash
# Run specific test
./tests/ch01/test_02_first_analysis.sh

# Run all Chapter 1 tests
make test-ch01

# View test results
cat test-results/ch01/test_02_first_analysis.log
```

## Test Infrastructure

The test creates a temporary directory with:
- Python source files with known characteristics
- Markdown documentation
- Test files
- Known complexity patterns
- Deliberate documentation gaps

This ensures predictable, reproducible test results across all environments.

## Next Steps

Now that you've seen TDD-verified analysis examples, explore:
- [Understanding Output](ch01-03-output.md) - Interpret the results
- [Core Concepts](ch02-00-core-concepts.md) - Deeper analysis capabilities
- [Test Results](ch02-00-core-concepts.md) - View actual test output