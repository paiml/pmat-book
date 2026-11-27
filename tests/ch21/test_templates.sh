#!/bin/bash
# TDD Test: Chapter 21 - Template Generation and Scaffolding
set -e

# pmat shim: when pmat is absent, fail silently (no "command not found" text
# for greps to match); every caller then takes its SKIPPED arm.
pmat() {
    type -P pmat >/dev/null 2>&1 || return 127
    command pmat "$@"
}


# Source test utilities
PASS_COUNT=0
FAIL_COUNT=0

test_skip() {
    echo "⚠️  SKIPPED: $1"
}

# A failed pmat command fails the run; with pmat absent the check is SKIPPED.
pmat_fail() {
    if type -P pmat >/dev/null 2>&1; then test_fail "$1"; else test_skip "$1 (pmat not on PATH)"; fi
}

test_pass() {
    echo "✅ PASS: $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

test_fail() {
    echo "❌ FAIL: $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

# Create test workspace
TEST_DIR=$(mktemp -d)
echo "Test directory: $TEST_DIR"

# Cleanup on exit
cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

cd "$TEST_DIR"

echo "=== Test 1: List Available Templates ==="
TEMPLATES=$(pmat list 2>/dev/null) || TEMPLATES=""
if echo "$TEMPLATES" | grep -q "template\|project\|agent\|rust\|python"
then
    test_pass "Template listing works"
else
    # Try with format flag
    TEMPLATES=$(pmat list --format json 2>/dev/null) || TEMPLATES=""
    if echo "$TEMPLATES" | grep -q "{" || echo "$TEMPLATES" | grep -q "template"
    then
        test_pass "Template listing available"
    else
        pmat_fail "Template system exists"
    fi
fi

echo "=== Test 2: Search Templates ==="
if pmat search "rust" 2>/dev/null | grep -q "rust\|cli\|web\|api"
then
    test_pass "Template search works for 'rust'"
else
    SEARCH_OUTPUT=$(pmat search "web" 2>/dev/null) || SEARCH_OUTPUT=""
    if echo "$SEARCH_OUTPUT" | grep -q "web\|api\|server\|search"
    then
        test_pass "Template search functionality available"
    else
        pmat_fail "Search capability exists"
    fi
fi

echo "=== Test 3: Generate Single Template ==="
# Try to generate a basic template (CATEGORY TEMPLATE, e.g. makefile rust/cli)
if pmat generate makefile rust/cli -p project_name=test-cli --output Makefile 2>/dev/null
then
    if [ -f Makefile ]; then
        test_pass "Single template generated successfully"
    else
        pmat_fail "Template generation completed"
    fi
else
    # Try alternative syntax
    if pmat gen makefile rust/cli -p project_name=test-cli -o Makefile 2>/dev/null
    then
        test_pass "Template generation with short flags works"
    else
        pmat_fail "Template generation system available"
    fi
fi

echo "=== Test 4: Template Parameter Validation ==="
if pmat validate template://makefile/rust/cli -p project_name=test-project 2>/dev/null
then
    test_pass "Template parameter validation works"
else
    VALIDATE_OUTPUT=$(pmat validate template://makefile/rust/cli 2>&1) || VALIDATE_OUTPUT=""
    if echo "$VALIDATE_OUTPUT" | grep -q "valid\|param\|require"
    then
        test_pass "Parameter validation available"
    else
        pmat_fail "Validation system exists"
    fi
fi

echo "=== Test 5: Filter Templates by Category ==="
if pmat list --category rust 2>/dev/null | grep -q "rust"
then
    test_pass "Category filtering works"
else
    # Try toolchain filter
    if pmat list --toolchain rust 2>/dev/null
    then
        test_pass "Toolchain filtering available"
    else
        pmat_fail "Template filtering capability exists"
    fi
fi

echo "=== Test 6: Generate with Directory Creation ==="
if pmat generate readme rust/cli -p project_name=nested-app -p description="Nested app" -o deep/nested/app.md --create-dirs 2>/dev/null
then
    if [ -f deep/nested/app.md ]; then
        test_pass "Directory creation with template works"
    else
        pmat_fail "Directory structure created"
    fi
else
    pmat_fail "Directory creation option available"
fi

echo "=== Test 7: JSON Format Output ==="
JSON_TEMPLATES=$(pmat list --format json 2>/dev/null) || JSON_TEMPLATES=""
if echo "$JSON_TEMPLATES" | grep -q '\[' || echo "$JSON_TEMPLATES" | grep -q '{'
then
    test_pass "JSON format output works"
else
    pmat_fail "Structured output formats available"
fi

echo "=== Test 8: Template Search with Limit ==="
if pmat search "project" --limit 5 2>/dev/null
then
    test_pass "Search with result limit works"
else
    LIMIT_OUTPUT=$(pmat search "test" --limit 3 2>&1) || LIMIT_OUTPUT=""
    pmat_fail "Search limiting capability available"
fi

# Summary
echo ""
echo "=== Test Summary ==="
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"

if [ $FAIL_COUNT -eq 0 ] && [ $PASS_COUNT -gt 0 ]; then
    echo "✅ All template generation tests passed!"
    exit 0
elif [ $FAIL_COUNT -eq 0 ]; then
    echo "⚠️  No checks ran (pmat not on PATH): nothing was verified"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi
