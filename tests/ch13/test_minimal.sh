#!/bin/bash
# Minimal test to verify Chapter 13 content

set -e

PASS_COUNT=0
FAIL_COUNT=0

test_pass() {
    echo "✅ PASS: $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

test_fail() {
    echo "❌ FAIL: $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

echo "=== Testing Chapter 13: Language Examples (Minimal) ==="

# Test 1: Chapter file exists
if [ -f "src/ch13-00-language-examples.md" ]; then
    test_pass "Chapter 13 file exists"
else
    test_fail "Chapter 13 file missing"
fi

# Test 2: Contains language examples
if grep -q "Python Project Analysis" src/ch13-00-language-examples.md; then
    test_pass "Python examples present"
else
    test_fail "Python examples missing"
fi

# Test 3: Contains JavaScript examples
if grep -q "JavaScript/Node.js Project Analysis" src/ch13-00-language-examples.md; then
    test_pass "JavaScript examples present"
else
    test_fail "JavaScript examples missing"
fi

# Test 4: Contains Rust examples
if grep -q "Rust Project Analysis" src/ch13-00-language-examples.md; then
    test_pass "Rust examples present"
else
    test_fail "Rust examples missing"
fi

# Test 5: Contains polyglot analysis
if grep -q "Polyglot Project Analysis" src/ch13-00-language-examples.md; then
    test_pass "Polyglot examples present"
else
    test_fail "Polyglot examples missing"
fi

# Test 6: Contains C++/CUDA query features (v3.6+)
if grep -q "CUDA Kernel Indexing\|CUDA kernel detection\|\.cu.*\.cuh" src/ch13-00-language-examples.md; then
    test_pass "C++/CUDA query features documented"
else
    test_fail "C++/CUDA query features missing"
fi

# Test 7: Contains header classification
if grep -q "Header Classification\|classify.*header\|\.h files" src/ch13-00-language-examples.md; then
    test_pass "Header classification documented"
else
    test_fail "Header classification missing"
fi

# Test 8: Contains PTX instruction tags
if grep -q "PTX Instruction Tags\|PTX:mma.sync\|PTX:<opcode>" src/ch13-00-language-examples.md; then
    test_pass "PTX instruction tags documented"
else
    test_fail "PTX instruction tags missing"
fi

# Test 9: Contains C++/CUDA complexity penalties
if grep -q "Complexity Penalties\|__shared__.*+2\|__syncthreads.*+3" src/ch13-00-language-examples.md; then
    test_pass "C++/CUDA complexity penalties documented"
else
    test_fail "C++/CUDA complexity penalties missing"
fi

# Test 10: Contains C++ macro classification
if grep -q "Macro Classification\|MACRO:ASSERT\|MACRO:DISPATCH\|MACRO:LOG" src/ch13-00-language-examples.md; then
    test_pass "C++ macro classification documented"
else
    test_fail "C++ macro classification missing"
fi

# Test 11: Contains inline PTX defect detection
if grep -q "PTX Defect Detection\|PTX_MISSING_BARRIER\|PTX_BARRIER_DIV\|PTX_HIGH_REGS" src/ch13-00-language-examples.md; then
    test_pass "Inline PTX defect detection documented"
else
    test_fail "Inline PTX defect detection missing"
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