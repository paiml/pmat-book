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
*PMAT version: pmat 2.173.0*  
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

**Test Location**: `tests/ch01/test_02_first_analysis.sh` line 45

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
pmat analyze .
```

**Test Validation**:
- ✅ Command executes successfully (exit code 0)
- ✅ Output is valid JSON
- ✅ Contains repository metadata
- ✅ Detects Python files correctly

**Verified Output Structure**:
```json
{
  "repository": {
    "path": "/tmp/test_project_xyz",
    "total_files": 4,
    "total_lines": 35
  },
  "languages": {
    "Python": {
      "files": 2,
      "percentage": 50.0
    },
    "Markdown": {
      "files": 1,
      "percentage": 25.0  
    }
  }
}
```

## Example 2: Technical Debt Grading (TDD Verified)

**Test Location**: `tests/ch01/test_02_first_analysis.sh` line 78

**Command Tested**:
```bash
pmat analyze tdg .
```

**Test Validation**:
- ✅ TDG analysis completes
- ✅ Grade field exists in output
- ✅ Overall score is present
- ✅ Grade is in valid range (A+ through F)

**Verified Output Structure**:
```json
{
  "grade": "B+",
  "overall_score": 87.5,
  "components": {
    "structural_complexity": {
      "score": 92.0,
      "grade": "A-"
    },
    "code_duplication": {
      "score": 95.0,
      "grade": "A"
    },
    "documentation_coverage": {
      "score": 75.0,
      "grade": "C+"
    }
  }
}
```

## Example 3: JSON Output Format (TDD Verified)

**Test Location**: `tests/ch01/test_02_first_analysis.sh` line 55

**Command Tested**:
```bash
pmat analyze . --format json
```

**Test Validation**:
- ✅ Output is valid JSON (parsed by `jq`)
- ✅ Repository section exists
- ✅ Languages section exists
- ✅ Metrics section exists

**JSON Schema Validation**:
```bash
# Test verifies these fields exist
echo "$OUTPUT" | jq -e '.repository.total_files'
echo "$OUTPUT" | jq -e '.languages.Python.files' 
echo "$OUTPUT" | jq -e '.metrics.complexity'
```

## Example 4: Language Detection (TDD Verified)

**Test Location**: `tests/ch01/test_02_first_analysis.sh` line 95

**Test Setup**: Creates multi-language project:
- Python files (`.py`)
- Markdown files (`.md`)
- Test files (`test_*.py`)

**Test Validation**:
- ✅ Python language detected
- ✅ Markdown language detected
- ✅ File counts accurate
- ✅ Percentages calculated correctly

**Verified Language Detection**:
```json
{
  "languages": {
    "Python": {
      "files": 2,
      "lines": 25,
      "percentage": 71.4
    },
    "Markdown": {
      "files": 1, 
      "lines": 10,
      "percentage": 28.6
    }
  }
}
```

## Example 5: Complexity Metrics (TDD Verified)

**Test Location**: `tests/ch01/test_02_first_analysis.sh` line 112

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

**Test Location**: `tests/ch01/test_02_first_analysis.sh` line 125

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

**Verified Recommendations**:
```json
{
  "recommendations": [
    {
      "priority": "MEDIUM",
      "type": "documentation",
      "message": "Add docstring to 'undocumented_function'",
      "location": "src/main.py:15",
      "effort": "5 minutes"
    },
    {
      "priority": "HIGH", 
      "type": "complexity",
      "message": "Refactor high-complexity function",
      "location": "src/main.py:20",
      "effort": "30 minutes"
    }
  ]
}
```

## Example 7: Single File Analysis (TDD Verified)

**Test Location**: `tests/ch01/test_02_first_analysis.sh` line 140

**Command Tested**:
```bash
pmat analyze src/main.py
```

**Test Validation**:
- ✅ Single file analysis works
- ✅ Output focuses on specified file
- ✅ Analysis completes successfully

## Example 8: Summary Format (TDD Verified)

**Test Location**: `tests/ch01/test_02_first_analysis.sh` line 90

**Command Tested**:
```bash
pmat analyze . --summary
```

**Test Validation**:
- ✅ Summary contains "Files:" keyword
- ✅ Human-readable format
- ✅ Concise output for quick overview

**Verified Summary Output**:
```
Repository: /tmp/test_project_xyz
Files: 4 | Lines: 35 | Languages: 2
Grade: B+ (87.5/100)
Top Issues: Missing docs (1), Complexity (1)
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