#!/bin/bash
# TDD Test: Chapter 1 - First Analysis
# Tests all examples from ch01-02-first-analysis.md

set -e

echo "=== Testing Chapter 1: First Analysis Examples ==="

# Test utilities
PASS_COUNT=0
FAIL_COUNT=0
TEST_DIR=$(mktemp -d)

test_pass() {
    echo "✅ PASS: $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

test_fail() {
    echo "❌ FAIL: $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

# Setup test project
setup_test_project() {
    cd "$TEST_DIR"
    
    # Create Python files
    mkdir -p src tests docs
    
    cat > src/main.py << 'EOF'
def calculate_sum(a, b):
    """Calculate sum of two numbers."""
    return a + b

def calculate_product(a, b):
    """Calculate product of two numbers."""
    return a * b

if __name__ == "__main__":
    print(calculate_sum(5, 3))
    print(calculate_product(5, 3))
EOF
    
    cat > src/utils.py << 'EOF'
def validate_input(value):
    """Validate input value."""
    if not isinstance(value, (int, float)):
        raise ValueError("Input must be a number")
    return True

def format_output(value):
    """Format output value."""
    return f"Result: {value:.2f}"
EOF
    
    cat > tests/test_main.py << 'EOF'
import sys
sys.path.append('../src')
from main import calculate_sum, calculate_product

def test_sum():
    assert calculate_sum(2, 3) == 5
    assert calculate_sum(-1, 1) == 0

def test_product():
    assert calculate_product(2, 3) == 6
    assert calculate_product(-2, 3) == -6
EOF
    
    cat > README.md << 'EOF'
# Test Project

A simple test project for PMAT analysis.

## Features
- Basic math operations
- Input validation
- Test coverage
EOF
}

# Test 1: Analyze current directory
#
# `analyze` is a PARENT command. `pmat analyze .` exits 2 with
# "error: unrecognized subcommand" — it never worked. `comprehensive` is the
# subcommand that runs the whole suite, and --path defaults to `.`.
echo "Test 1: Analyze current directory"
setup_test_project
if pmat analyze comprehensive &> /dev/null; then
    test_pass "Current directory analysis"
else
    test_fail "Current directory analysis"
fi

# Test 1b: prove the old form is genuinely rejected, so this test cannot pass
# again by accident if someone reintroduces it.
echo "Test 1b: bare 'pmat analyze .' is rejected"
if pmat analyze . &> /dev/null; then
    test_fail "'pmat analyze .' unexpectedly succeeded"
else
    test_pass "'pmat analyze .' rejected, as documented"
fi

# Test 2: Analyze with JSON output
echo "Test 2: JSON output format"
OUTPUT=$(pmat analyze comprehensive --path . --format json 2>/dev/null)
if echo "$OUTPUT" | jq -e '.summary.total_files' &> /dev/null; then
    test_pass "JSON output contains a summary section"

    FILES=$(echo "$OUTPUT" | jq -r '.summary.total_files')
    if [ "$FILES" -gt 0 ]; then
        test_pass "Files analyzed: $FILES"
    else
        test_fail "No files analyzed"
    fi
else
    test_fail "JSON output invalid"
fi

# Test 2b: dead_code must be null on a non-Cargo project, NOT 0.
# A zero that means "never ran" is the defect this book shipped once.
echo "Test 2b: dead_code reports 'not measured', not zero"
if [ "$(echo "$OUTPUT" | jq -r '.dead_code')" = "null" ]; then
    test_pass "dead_code is null (Rust-only analyser, correctly not measured)"
else
    test_fail "dead_code should be null on a Python project"
fi

# Test 3: Test TDG analysis
echo "Test 3: Technical Debt Grading"
TDG_OUTPUT=$(pmat analyze tdg --path . --format json 2>/dev/null)
if echo "$TDG_OUTPUT" | jq -e '.average_grade' &> /dev/null; then
    GRADE=$(echo "$TDG_OUTPUT" | jq -r '.average_grade')
    test_pass "TDG analysis complete, Grade: $GRADE"

    if echo "$TDG_OUTPUT" | jq -e '.average_score' &> /dev/null; then
        SCORE=$(echo "$TDG_OUTPUT" | jq -r '.average_score')
        test_pass "Average score: $SCORE"
    else
        test_fail "No average score in TDG"
    fi
else
    test_fail "TDG analysis failed"
fi

# Test 3b: the positional form is rejected; -p/--path is required.
echo "Test 3b: 'pmat analyze tdg .' is rejected"
if pmat analyze tdg . &> /dev/null; then
    test_fail "'pmat analyze tdg .' unexpectedly succeeded"
else
    test_pass "'pmat analyze tdg .' rejected, as documented"
fi

# Test 4: Executive summary
echo "Test 4: Executive summary"
if pmat analyze comprehensive --path . --executive-summary 2>/dev/null | grep -q "Total Files:"; then
    test_pass "Executive summary contains file count"
else
    test_fail "Executive summary missing file count"
fi

# Test 5: Test specific file analysis
echo "Test 5: Single file analysis"
if pmat analyze complexity --file src/main.py &> /dev/null; then
    test_pass "Single file analysis works"
else
    test_fail "Single file analysis failed"
fi

# Test 6: Test language detection
echo "Test 6: Language detection"
LANG_OUTPUT=$(pmat analyze tdg --path . --format json 2>/dev/null)
if echo "$LANG_OUTPUT" | jq -e '.language_distribution | has("Python")' &> /dev/null; then
    test_pass "Python language detected"
else
    test_fail "Python not detected"
fi

# Test 7: Test complexity metrics
echo "Test 7: Complexity metrics"
METRICS=$(pmat analyze complexity --path . --format json 2>/dev/null)
if echo "$METRICS" | jq -e '.summary.median_cyclomatic' &> /dev/null; then
    test_pass "Complexity metrics present"
else
    test_fail "Complexity metrics missing"
fi

# Test 8: SATD violations are reported with their scope
echo "Test 8: SATD scope census"
if echo "$OUTPUT" | jq -e '.satd.census.analyzed' &> /dev/null; then
    ANALYZED=$(echo "$OUTPUT" | jq -r '.satd.census.analyzed')
    test_pass "SATD reports its denominator: $ANALYZED file(s) read"
else
    test_fail "SATD census missing"
fi

# Cleanup
cd /
rm -rf "$TEST_DIR"

# Summary
echo ""
echo "=== Test Summary ==="
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"

if [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi