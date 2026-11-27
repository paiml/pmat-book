#!/bin/bash
# TDD Test: Chapter 18 - documented `pmat serve` tool count matches the binary (#118)
# (a) the chapter states the same tool count in every place that names one;
# (b) if pmat is on PATH, the live HTTP server's tools/list returns that many tools.
# CH18_DOC overrides the chapter path (used to run the check against an older commit).
set -e

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

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
CHAPTER="${CH18_DOC:-$REPO_ROOT/src/ch18-00-api.md}"

if [ ! -f "$CHAPTER" ]; then
    test_fail "chapter not found: $CHAPTER"
    echo "Results: $PASS_COUNT passed, $FAIL_COUNT failed"
    exit 1
fi

# --- (a) the chapter's own statements -------------------------------------
# Three places name the count: the status line "(N)", the serve banner
# "tools: N", and the prose "The N tools served here".
STATUS_N=$(grep -oE 'tool count re-measured on pmat [0-9.]+ \([0-9]+\)' "$CHAPTER" | grep -oE '[0-9]+\)$' | tr -d ')' | head -1 || true)
BANNER_N=$(grep -oE '^  tools: [0-9]+' "$CHAPTER" | grep -oE '[0-9]+$' | head -1 || true)
PROSE_N=$(grep -oE 'The [0-9]+ tools served here' "$CHAPTER" | grep -oE '[0-9]+' | head -1 || true)

if [ -n "$STATUS_N" ] && [ -n "$BANNER_N" ] && [ -n "$PROSE_N" ] \
    && [ "$STATUS_N" = "$BANNER_N" ] && [ "$BANNER_N" = "$PROSE_N" ]
then
    test_pass "chapter states one tool count in all three places ($BANNER_N)"
else
    test_fail "chapter tool-count statements missing or disagree (status='$STATUS_N' banner='$BANNER_N' prose='$PROSE_N')"
fi

DOC_N="$BANNER_N"

# --- (b) the binary ---------------------------------------------------------
if ! type -P pmat >/dev/null 2>&1; then
    test_skip "live tools/list not run: pmat not on PATH (binary count NOT verified)"
    echo "Results: $PASS_COUNT passed, $FAIL_COUNT failed, 1 skipped"
    [ "$FAIL_COUNT" -eq 0 ] && exit 0 || exit 1
fi

TEST_DIR=$(mktemp -d)
SERVER_PID=""

cleanup() {
    if [ -n "$SERVER_PID" ]; then
        kill "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
    fi
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# First TCP port at or above 18100 with nothing listening on it.
PORT=18100
while (exec 3<>"/dev/tcp/127.0.0.1/$PORT") 2>/dev/null; do
    PORT=$((PORT + 1))
done

TOKEN="ch18-tool-count-test-token-$$"
cd "$TEST_DIR"
PMAT_MCP_HTTP_TOKEN="$TOKEN" pmat serve --transport http --port "$PORT" > server.log 2>&1 &
SERVER_PID=$!

# Wait up to 15 s for the listener; the server never exits on its own.
UP=0
for _ in $(seq 1 30); do
    if ! kill -0 "$SERVER_PID" 2>/dev/null; then
        break
    fi
    if (exec 3<>"/dev/tcp/127.0.0.1/$PORT") 2>/dev/null; then
        UP=1
        break
    fi
    sleep 0.5
done

if [ "$UP" -ne 1 ]; then
    test_fail "pmat serve did not listen on port $PORT (see $TEST_DIR/server.log)"
    echo "Results: $PASS_COUNT passed, $FAIL_COUNT failed"
    exit 1
fi

# tools/list needs the bearer token and the streamable-HTTP Accept header (else 406).
RESPONSE=$(curl -s -m 20 -X POST "http://127.0.0.1:$PORT/" \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json, text/event-stream' \
    -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' || true)

# The reply may be plain JSON or an SSE frame ("data: {...}"); keep the JSON line.
JSON=$(printf '%s\n' "$RESPONSE" | sed -n 's/^data: //p; /^{/p' | head -1)
LIVE_N=$(printf '%s' "$JSON" | jq -r '.result.tools | length' 2>/dev/null || true)

if [ -n "$LIVE_N" ] && [ "$LIVE_N" != "null" ] && [ "$LIVE_N" -gt 0 ] 2>/dev/null; then
    test_pass "pmat serve tools/list returned $LIVE_N tools"
else
    test_fail "pmat serve tools/list gave no tool list (response: ${RESPONSE:0:200})"
    LIVE_N=""
fi

if [ -n "$LIVE_N" ] && [ -n "$DOC_N" ]
then
    if [ "$LIVE_N" = "$DOC_N" ]; then
        test_pass "chapter tool count ($DOC_N) equals binary tool count ($LIVE_N)"
    else
        test_fail "chapter says $DOC_N tools, binary serves $LIVE_N"
    fi
fi

echo "Results: $PASS_COUNT passed, $FAIL_COUNT failed"
[ "$FAIL_COUNT" -eq 0 ] && exit 0 || exit 1
