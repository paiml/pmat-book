#!/bin/bash
# Minimal test for Chapter 17 WASM Analysis

set -e

# pmat shim: when pmat is absent, fail silently (no "command not found" text
# for greps to match); every caller then takes its SKIPPED arm.
pmat() {
    type -P pmat >/dev/null 2>&1 || return 127
    command pmat "$@"
}


PASS_COUNT=0
FAIL_COUNT=0

test_skip() {
    echo "⚠️  SKIPPED: $1"
}

test_pass() {
    echo "✅ PASS: $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

test_fail() {
    echo "❌ FAIL: $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
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

# Tests 3 to 6 used to ask for `pmat analyze wasm`, "Security Analysis",
# "Performance Profiling" and "Formal Verification". The chapter was rewritten
# around the two commands a default pmat build ships, and it removed the
# invented profiling and verification sections, so three of those checks failed
# and the fourth passed only on the banner that says the command is unavailable.

# Test 3: Documents the commands a default build ships, as commands
if grep -qxF "pmat analyze web-assembly --security" src/ch17-00-wasm-analysis.md \
    && grep -qF "pmat analyze assembly-script -p ./as" src/ch17-00-wasm-analysis.md; then
    test_pass "web-assembly and assembly-script commands documented"
else
    test_fail "web-assembly or assembly-script command missing"
fi

# Test 4: Contains the security section
if grep -qxF "## Security Validation" src/ch17-00-wasm-analysis.md; then
    test_pass "Security validation documented"
else
    test_fail "Security validation section missing"
fi

# Test 5: Contains the memory and complexity section
if grep -qxF "## Memory and Complexity" src/ch17-00-wasm-analysis.md; then
    test_pass "Memory and complexity documented"
else
    test_fail "Memory and complexity section missing"
fi

# Test 6: The removed sections stay removed (no heading for either)
if grep -qE "^#+ .*(Performance Profiling|Formal Verification)" src/ch17-00-wasm-analysis.md; then
    test_fail "A 'Performance Profiling' or 'Formal Verification' heading is back; pmat has neither"
else
    test_pass "No profiling or formal-verification section"
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