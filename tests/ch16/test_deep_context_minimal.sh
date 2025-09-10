#!/bin/bash
# Minimal test for Chapter 16 Deep Context Analysis

set -e

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

echo "=== Testing Chapter 16: Deep Context Analysis (Minimal) ==="

# Test 1: Chapter file exists
if [ -f "src/ch16-00-deep-context.md" ]; then
    test_pass "Chapter 16 file exists"
else
    test_fail "Chapter 16 file missing"
fi

# Test 2: Contains deep context documentation
if grep -q "Deep Context Analysis" src/ch16-00-deep-context.md; then
    test_pass "Deep context analysis content present"
else
    test_fail "Deep context content missing"
fi

# Test 3: Contains command interface
if grep -q "pmat analyze deep-context" src/ch16-00-deep-context.md; then
    test_pass "Deep context commands documented"
else
    test_fail "Deep context commands missing"
fi

# Test 4: Contains performance information
if grep -q "Performance Optimization" src/ch16-00-deep-context.md; then
    test_pass "Performance optimization documented"
else
    test_fail "Performance optimization missing"
fi

# Test 5: Contains integration examples
if grep -q "Integration Patterns" src/ch16-00-deep-context.md; then
    test_pass "Integration patterns documented"
else
    test_fail "Integration patterns missing"
fi

echo ""
echo "=== Test Summary ==="
if [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ All $PASS_COUNT tests passed!"
    exit 0
else
    echo "❌ $FAIL_COUNT out of $((PASS_COUNT + FAIL_COUNT)) tests failed"
    exit 1
fi