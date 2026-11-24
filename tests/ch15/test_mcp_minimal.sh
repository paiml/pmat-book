#!/bin/bash
# Minimal test for Chapter 15 MCP Tools Reference

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

echo "=== Testing Chapter 15: MCP Tools Reference (Minimal) ==="

# Test 1: Chapter file exists
if [ -f "src/ch15-00-mcp-tools.md" ]; then
    test_pass "Chapter 15 file exists"
else
    test_fail "Chapter 15 file missing"
fi

# Test 2: Contains MCP tools documentation
if grep -q "Complete MCP Tools Reference" src/ch15-00-mcp-tools.md; then
    test_pass "MCP tools reference present"
else
    test_fail "MCP tools reference missing"
fi

# Test 3: Contains analysis tools
if grep -q "analyze_complexity" src/ch15-00-mcp-tools.md; then
    test_pass "Analysis tools documented"
else
    test_fail "Analysis tools missing"
fi

# Test 4: Contains context generation
if grep -q "generate_context" src/ch15-00-mcp-tools.md; then
    test_pass "Context generation documented"
else
    test_fail "Context generation missing"
fi

# Test 5: Client registration. The chapter was rebuilt from `tools/list`; its
# "Claude Desktop Integration" section went with the invented tools, and this
# check kept asking for that heading. It asks for the section and the command
# the chapter prints now.
if grep -qxF "## Registering with a client" src/ch15-00-mcp-tools.md \
    && grep -qxF "claude mcp add --scope user pmat -- pmat --mode mcp" src/ch15-00-mcp-tools.md; then
    test_pass "Client registration documented"
else
    test_fail "Client registration section or its 'claude mcp add' line missing"
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