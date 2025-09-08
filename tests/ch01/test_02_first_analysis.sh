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
    ((PASS_COUNT++))
}

test_fail() {
    echo "❌ FAIL: $1"
    ((FAIL_COUNT++))
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
echo "Test 1: Analyze current directory"
setup_test_project
if pmat analyze . &> /dev/null; then
    test_pass "Current directory analysis"
else
    test_fail "Current directory analysis"
fi

# Test 2: Analyze with JSON output
echo "Test 2: JSON output format"
OUTPUT=$(pmat analyze . --format json 2>/dev/null)
if echo "$OUTPUT" | jq -e '.repository.total_files' &> /dev/null; then
    test_pass "JSON output contains repository info"
    
    # Verify we detected Python files
    PYTHON_FILES=$(echo "$OUTPUT" | jq -r '.languages.Python.files // 0')
    if [ "$PYTHON_FILES" -gt 0 ]; then
        test_pass "Python files detected: $PYTHON_FILES"
    else
        test_fail "No Python files detected"
    fi
else
    test_fail "JSON output invalid"
fi

# Test 3: Test TDG analysis
echo "Test 3: Technical Debt Grading"
TDG_OUTPUT=$(pmat analyze tdg . --format json 2>/dev/null)
if echo "$TDG_OUTPUT" | jq -e '.grade' &> /dev/null; then
    GRADE=$(echo "$TDG_OUTPUT" | jq -r '.grade')
    test_pass "TDG analysis complete, Grade: $GRADE"
    
    # Check if grade is reasonable
    if echo "$TDG_OUTPUT" | jq -e '.overall_score' &> /dev/null; then
        SCORE=$(echo "$TDG_OUTPUT" | jq -r '.overall_score')
        test_pass "Overall score: $SCORE"
    else
        test_fail "No overall score in TDG"
    fi
else
    test_fail "TDG analysis failed"
fi

# Test 4: Test summary format
echo "Test 4: Summary format"
if pmat analyze . --summary 2>&1 | grep -q "Files:"; then
    test_pass "Summary format contains file count"
else
    test_fail "Summary format missing file count"
fi

# Test 5: Test specific file analysis
echo "Test 5: Single file analysis"
if pmat analyze src/main.py &> /dev/null; then
    test_pass "Single file analysis works"
else
    test_fail "Single file analysis failed"
fi

# Test 6: Test language detection
echo "Test 6: Language detection"
LANG_OUTPUT=$(pmat analyze . --format json 2>/dev/null)
if echo "$LANG_OUTPUT" | jq -e '.languages | has("Python")' &> /dev/null; then
    test_pass "Python language detected"
    
    # Check Markdown detection
    if echo "$LANG_OUTPUT" | jq -e '.languages | has("Markdown")' &> /dev/null; then
        test_pass "Markdown language detected"
    else
        test_fail "Markdown not detected"
    fi
else
    test_fail "Python not detected"
fi

# Test 7: Test complexity metrics
echo "Test 7: Complexity metrics"
METRICS=$(pmat analyze . --format json 2>/dev/null)
if echo "$METRICS" | jq -e '.metrics.complexity' &> /dev/null; then
    test_pass "Complexity metrics present"
else
    test_fail "Complexity metrics missing"
fi

# Test 8: Test recommendations
echo "Test 8: Recommendations"
TDG_WITH_RECS=$(pmat analyze tdg . --format json 2>/dev/null)
if echo "$TDG_WITH_RECS" | jq -e '.recommendations' &> /dev/null; then
    REC_COUNT=$(echo "$TDG_WITH_RECS" | jq '.recommendations | length')
    test_pass "Recommendations provided: $REC_COUNT"
else
    test_fail "No recommendations provided"
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