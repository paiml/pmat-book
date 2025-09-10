#!/bin/bash
# Minimal test for Chapter 17 WASM Analysis

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

echo "=== Testing Chapter 17: WASM Analysis (Minimal) ==="

# Test 1: Chapter file exists
if [ -f "src/ch17-00-wasm-analysis.md" ]; then
    test_pass "Chapter 17 file exists"
else
    test_fail "Chapter 17 file missing"
fi

# Test 2: Contains WASM analysis documentation
if grep -q "WebAssembly Analysis and Security" src/ch17-00-wasm-analysis.md; then
    test_pass "WASM analysis content present"
else
    test_fail "WASM analysis content missing"
fi

# Test 3: Contains WASM commands
if grep -q "pmat analyze wasm" src/ch17-00-wasm-analysis.md; then
    test_pass "WASM commands documented"
else
    test_fail "WASM commands missing"
fi

# Test 4: Contains security analysis
if grep -q "Security Analysis" src/ch17-00-wasm-analysis.md; then
    test_pass "Security analysis documented"
else
    test_fail "Security analysis missing"
fi

# Test 5: Contains performance profiling
if grep -q "Performance Profiling" src/ch17-00-wasm-analysis.md; then
    test_pass "Performance profiling documented"
else
    test_fail "Performance profiling missing"
fi

# Test 6: Contains formal verification
if grep -q "Formal Verification" src/ch17-00-wasm-analysis.md; then
    test_pass "Formal verification documented"
else
    test_fail "Formal verification missing"
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