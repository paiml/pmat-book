#!/bin/bash
# TDD Test: Chapter 1 - Installation
# Tests all installation methods documented in the book

set -e

echo "=== Testing Chapter 1: Installation Methods ==="

# Test utilities
PASS_COUNT=0
FAIL_COUNT=0

test_pass() {
    echo "✅ PASS: $1"
    ((PASS_COUNT++))
}

test_fail() {
    echo "❌ FAIL: $1"
    ((FAIL_COUNT++))
}

# Test 1: Verify PMAT is installed
echo "Test 1: Verify PMAT installation"
if command -v pmat &> /dev/null; then
    test_pass "PMAT command found"
    VERSION=$(pmat --version)
    echo "  Version: $VERSION"
else
    test_fail "PMAT command not found"
    exit 1
fi

# Test 2: Test basic help command
echo "Test 2: Test help command"
if pmat --help &> /dev/null; then
    test_pass "Help command works"
else
    test_fail "Help command failed"
fi

# Test 3: Test version output format
echo "Test 3: Test version format"
VERSION_OUTPUT=$(pmat --version)
if [[ "$VERSION_OUTPUT" =~ ^pmat[[:space:]][0-9]+\.[0-9]+\.[0-9]+ ]]; then
    test_pass "Version format correct: $VERSION_OUTPUT"
else
    test_fail "Version format incorrect: $VERSION_OUTPUT"
fi

# Test 4: Create test file for analysis
echo "Test 4: Test file creation for analysis"
TEST_FILE="test_hello.py"
cat > "$TEST_FILE" << 'EOF'
def hello_world():
    """Simple hello world function for testing."""
    print("Hello, PMAT!")

if __name__ == "__main__":
    hello_world()
EOF

if [ -f "$TEST_FILE" ]; then
    test_pass "Test file created: $TEST_FILE"
else
    test_fail "Failed to create test file"
fi

# Test 5: Test basic analysis command
echo "Test 5: Test basic analysis"
if pmat analyze "$TEST_FILE" &> /dev/null; then
    test_pass "Basic analysis command works"
else
    test_fail "Basic analysis command failed"
fi

# Test 6: Test JSON output format
echo "Test 6: Test JSON output"
OUTPUT=$(pmat analyze "$TEST_FILE" --format json 2>/dev/null)
if echo "$OUTPUT" | jq empty 2>/dev/null; then
    test_pass "JSON output is valid"
else
    test_fail "JSON output is invalid"
fi

# Test 7: Test analysis contains expected fields
echo "Test 7: Test analysis structure"
if echo "$OUTPUT" | jq -e '.repository.total_files' &> /dev/null; then
    test_pass "Analysis contains expected fields"
else
    test_fail "Analysis missing expected fields"
fi

# Cleanup
rm -f "$TEST_FILE"

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