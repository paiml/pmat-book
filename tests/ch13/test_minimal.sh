#!/bin/bash
# Minimal test to verify Chapter 13 content

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

echo ""
echo "=== Test Summary ==="
if [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ All $PASS_COUNT tests passed!"
    exit 0
else
    echo "❌ $FAIL_COUNT out of $((PASS_COUNT + FAIL_COUNT)) tests failed"
    exit 1
fi