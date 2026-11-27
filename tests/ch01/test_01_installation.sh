#!/bin/bash
# TDD Test: Chapter 1 - Installation
# Tests all installation methods documented in the book

set -e

# pmat shim: when pmat is absent, fail silently (no "command not found" text
# for greps to match); every caller then takes its SKIPPED arm.
pmat() {
    type -P pmat >/dev/null 2>&1 || return 127
    command pmat "$@"
}


echo "=== Testing Chapter 1: Installation Methods ==="

# Test utilities
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

test_pass() {
    echo "✅ PASS: $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

test_fail() {
    echo "❌ FAIL: $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

# A check that did not run is SKIPPED and counts zero passes.
test_skip() {
    echo "⚠️  SKIPPED: $1"
    SKIP_COUNT=$((SKIP_COUNT + 1))
}

# Test 1: Verify PMAT is installed (or skip)
echo "Test 1: Verify PMAT installation"
PMAT_AVAILABLE=false
if type -P pmat &> /dev/null; then
    if timeout 5s pmat --version > /tmp/pmat_version.txt 2>&1; then
        test_pass "PMAT command found"
        VERSION=$(cat /tmp/pmat_version.txt)
        echo "  Version: $VERSION"
        PMAT_AVAILABLE=true
    else
        test_fail "pmat is on PATH but 'pmat --version' timed out or failed"
        PMAT_AVAILABLE=false
    fi
else
    test_skip "PMAT not installed: this run verified NOTHING about pmat"
fi

# Test 2: Test basic help command
echo "Test 2: Test help command"
if [ "$PMAT_AVAILABLE" = true ]; then
    if pmat --help &> /dev/null; then
        test_pass "Help command works"
    else
        test_fail "Help command failed"
    fi
else
    test_skip "Help command not checked: PMAT not available"
fi

# Test 3: Test version output format
echo "Test 3: Test version format"
if [ "$PMAT_AVAILABLE" = true ]; then
    VERSION_OUTPUT=$(pmat --version)
    if [[ "$VERSION_OUTPUT" =~ ^pmat[[:space:]][0-9]+\.[0-9]+\.[0-9]+ ]]; then
        test_pass "Version format correct: $VERSION_OUTPUT"
    else
        test_fail "Version format incorrect: $VERSION_OUTPUT"
    fi
else
    test_skip "Version format not checked: PMAT not available (no installed version to read)"
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
    if [ "$PMAT_AVAILABLE" = true ]; then
        test_pass "Test file created: $TEST_FILE"
    else
        # Fixture for the PMAT checks below; it is not an assertion.
        echo "  fixture written: $TEST_FILE (not an assertion)"
    fi
else
    test_fail "Failed to create test file"
fi

# Test 5: Test basic analysis command
echo "Test 5: Test basic analysis"
if [ "$PMAT_AVAILABLE" = true ]; then
    if pmat analyze complexity --path "$(dirname "$TEST_FILE")" &> /dev/null; then
        test_pass "Basic analysis command works"
    else
        test_fail "Basic analysis command failed"
    fi
else
    test_skip "Basic analysis not run: PMAT not available"
fi

# Test 6: Test JSON output format
echo "Test 6: Test JSON output"
if [ "$PMAT_AVAILABLE" = true ]; then
    OUTPUT=$(pmat analyze complexity --path "$(dirname "$TEST_FILE")" --format json 2>/dev/null)
    if echo "$OUTPUT" | jq empty 2>/dev/null; then
        test_pass "JSON output is valid"
    else
        test_fail "JSON output is invalid"
    fi
else
    test_skip "JSON output not produced: PMAT not available"
fi

# Test 7: Test analysis contains expected fields
echo "Test 7: Test analysis structure"
if [ "$PMAT_AVAILABLE" = true ]; then
    if echo "$OUTPUT" | jq -e '.summary' &> /dev/null || echo "$OUTPUT" | jq -e '.files' &> /dev/null; then
        test_pass "Analysis contains expected fields"
    else
        test_fail "Analysis missing expected fields"
    fi
else
    test_skip "Analysis structure not checked: PMAT not available"
fi

# Cleanup
rm -f "$TEST_FILE"

# Summary
echo ""
echo "=== Test Summary ==="
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"
echo "Skipped: $SKIP_COUNT"

if [ $FAIL_COUNT -eq 0 ] && [ $PASS_COUNT -eq 0 ]; then
    echo "⚠️  SKIPPED: this run verified NOTHING"
    exit 0
fi
if [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi
