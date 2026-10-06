#!/bin/bash
# Chapter 3: the MCP commands the chapters tell readers to run must exist (#14).
#
# `pmat mcp-server` is not a subcommand (exit 2), and two Claude Desktop
# configs in ch03-03 used `"args": ["mcp-server"]`, a server that never starts.
# This test (1) refuses those spellings in the chapters that carried them, and
# (2) executes the forms the chapters now document, so a test that only greps
# cannot pass on a CLI that no longer answers.
set -u

PASS=0
FAIL=0
test_pass() { echo "✅ PASS: $1"; PASS=$((PASS + 1)); }
test_fail() { echo "❌ FAIL: $1"; FAIL=$((FAIL + 1)); }

CHAPTERS="src/ch01-04-using-pmat.md src/ch03-00-mcp-protocol.md src/ch03-01-mcp-setup.md src/ch03-03-claude-integration.md"

# 1. No chapter documents the non-existent subcommand or its flags.
# `pmat agent mcp-server` and `--template mcp-server` are real and are not matched.
BAD=$(grep -nE 'pmat mcp-server|"mcp-server"[],]|--unix-socket|mcp-server --bind' $CHAPTERS)
if [ -z "$BAD" ]; then
    test_pass "no chapter runs \`pmat mcp-server\` or its invented flags"
else
    test_fail "chapters still run a subcommand that does not exist:"
    printf '%s\n' "$BAD"
fi

# 2. The documented forms execute. Without pmat there is no verdict: fail.
if ! command -v pmat >/dev/null 2>&1; then
    test_fail "pmat is not on PATH: the documented commands cannot be executed"
else
    if pmat mcp-server >/dev/null 2>&1; then
        test_fail "\`pmat mcp-server\` now exits 0: re-check #14 before keeping this test"
    else
        test_pass "\`pmat mcp-server\` is still rejected, as the chapters now say"
    fi

    REQ='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"book","version":"1"}}}
{"jsonrpc":"2.0","method":"notifications/initialized"}
{"jsonrpc":"2.0","id":2,"method":"tools/list"}'
    OUT=$(printf '%s\n' "$REQ" | timeout 30 pmat --mode mcp 2>/dev/null)
    TOOLS=$(printf '%s\n' "$OUT" | jq -r 'select(.id == 2) | .result.tools | length' 2>/dev/null)
    if [ "${TOOLS:-0}" -gt 0 ] 2>/dev/null; then
        test_pass "\`pmat --mode mcp\` answers initialize and lists $TOOLS tools"
    else
        test_fail "\`pmat --mode mcp\` did not list tools over stdio"
    fi

    HELP=$(pmat serve --help 2>&1)
    for flag in --transport --host --port; do
        if printf '%s\n' "$HELP" | grep -q -- "$flag"; then
            test_pass "\`pmat serve\` takes $flag"
        else
            test_fail "\`pmat serve\` has no $flag flag"
        fi
    done

    if pmat mcp connect >/dev/null 2>&1; then
        test_pass "\`pmat mcp connect\` runs"
    else
        test_fail "\`pmat mcp connect\` failed"
    fi
fi

echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ] && [ "$PASS" -gt 0 ]
