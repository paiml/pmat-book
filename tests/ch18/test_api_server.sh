#!/bin/bash
# TDD Test: Chapter 18 - MCP HTTP Server (`pmat serve`)
# pmat 3.44.0 serves ONE MCP endpoint at the ROOT path (POST /), with bearer auth.
# There is no REST API, no /health, no /ws and no /version (src/ch18-00-api.md, Part 1).
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

# Stop the server: SERVER_PID leads its own process group (setsid), so signal the
# whole group. TERM first (timeout forwards it), then KILL the group if any member lives.
stop_server() {
    [ -n "$SERVER_PID" ] || return 0
    kill -TERM -- "-$SERVER_PID" 2>/dev/null || true
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        ps -o stat= -g "$SERVER_PID" 2>/dev/null | grep -qv "^Z" || break
        sleep 0.5
    done
    kill -KILL -- "-$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
    SERVER_PID=""
}

# Cleanup on exit
cleanup() {
    stop_server
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

cd "$TEST_DIR"

# Create a simple test project
cat > main.rs << 'EOF'
fn main() {
    println!("Hello, PMAT API!");
}

fn calculate_sum(a: i32, b: i32) -> i32 {
    a + b
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sum() {
        assert_eq!(calculate_sum(2, 3), 5);
    }
}
EOF

cat > Cargo.toml << 'EOF'
[package]
name = "test-api"
version = "0.1.0"
edition = "2021"

[dependencies]
EOF

# JSON-RPC over the one endpoint. Every RPC needs the bearer token and the
# streamable-HTTP Accept header; without Accept the server answers 406.
rpc() {
    curl -s -m 20 -X POST http://127.0.0.1:9090/ \
        -H "Authorization: Bearer $PMAT_MCP_HTTP_TOKEN" \
        -H 'Content-Type: application/json' \
        -H 'Accept: application/json, text/event-stream' \
        -d "$1" 2>/dev/null || echo ""
}

echo "=== Test 1: Start API Server ==="
# Without pmat there is no server to test: the whole suite is SKIPPED, not failed.
if ! type -P pmat >/dev/null 2>&1; then
    test_skip "API server tests not run: pmat not on PATH (this run verified NOTHING about the API)"
    echo "⚠️  SKIPPED: this run verified NOTHING"
    exit 0
fi

# Auth is mandatory: the token must be >= 16 characters. pmat mints a conforming one.
PMAT_MCP_HTTP_TOKEN=$(pmat mcp token)
export PMAT_MCP_HTTP_TOKEN

# The server never exits on its own: bound its lifetime with timeout(1) so a
# lost cleanup cannot hold the job, and wait only on pids we name.
setsid timeout -k 5 120 pmat serve --transport http --port 9090 > server.log 2>&1 &
SERVER_PID=$!
LISTENING=0
for _ in $(seq 1 40); do
    if (exec 3<>/dev/tcp/127.0.0.1/9090) 2>/dev/null; then LISTENING=1; break; fi
    kill -0 "$SERVER_PID" 2>/dev/null || break
    sleep 0.25
done
if [ "$LISTENING" = 1 ]; then
    test_pass "API server listening on port 9090"
else
    test_fail "API server did not listen on port 9090 within 10 s (or exited)"
fi

echo "=== Test 2: Readiness via MCP root (no /health endpoint exists) ==="
TOOLS_RESPONSE=$(rpc '{"jsonrpc":"2.0","id":1,"method":"tools/list"}')
if echo "$TOOLS_RESPONSE" | grep -qF '"result":{"tools":'
then
    test_pass "MCP root answers tools/list"
else
    test_fail "MCP root did not answer tools/list"
fi

echo "=== Test 3: Analyze Tool (no REST /analyze; MCP tools/call analyze_complexity) ==="
ANALYZE_RESPONSE=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"analyze_complexity\",\"arguments\":{\"paths\":[\"$TEST_DIR\"]}}}")

if echo "$ANALYZE_RESPONSE" | grep -qF '\"status\":\"completed\"' \
    && echo "$ANALYZE_RESPONSE" | grep -qF '\"files_analyzed\":1,'
then
    test_pass "Analyze tool responds with data"
else
    test_fail "Analyze tool did not respond with data"
fi

echo "=== Test 4: Context Tool (no REST /context; MCP tools/call generate_context) ==="
CONTEXT_RESPONSE=$(rpc "{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"tools/call\",\"params\":{\"name\":\"generate_context\",\"arguments\":{\"paths\":[\"$TEST_DIR\"]}}}")

if echo "$CONTEXT_RESPONSE" | grep -qF '\"status\":\"completed\"' \
    && echo "$CONTEXT_RESPONSE" | grep -qF '\"name\":\"main\"'
then
    test_pass "Context tool returns the function index for main.rs"
else
    test_fail "Context tool not responding with context"
fi

echo "=== Test 5: WebSocket Is Not Implemented (asserted as documented) ==="
# --transport web-socket exits 2 with "not yet implemented"; /ws is 404 on the live server.
WS_OUT=$(pmat serve --transport web-socket --port 9091 2>&1) && WS_RC=0 || WS_RC=$?
WS_CODE=$(curl -s -o /dev/null -w '%{http_code}' -m 10 http://127.0.0.1:9090/ws)
if [ "$WS_RC" = 2 ] && echo "$WS_OUT" | grep -q "not yet implemented" && [ "$WS_CODE" = 404 ]
then
    test_pass "WebSocket transport refused (exit 2) and /ws is 404, as documented"
else
    test_fail "WebSocket behaviour differs from documented non-support (rc=$WS_RC, /ws=$WS_CODE)"
fi

echo "=== Test 6: Server Version Over MCP initialize ==="
INIT_RESPONSE=$(rpc '{"jsonrpc":"2.0","id":4,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"ch18-test","version":"0"}}}')
PMAT_VER=$(pmat --version | awk '{print $2}')
if echo "$INIT_RESPONSE" | grep -qF "\"serverInfo\""  \
    && echo "$INIT_RESPONSE" | grep -qF "\"version\":\"$PMAT_VER\""
then
    test_pass "Version info served in initialize serverInfo: $PMAT_VER"
else
    test_fail "Version info not available through MCP initialize"
fi

echo "=== Test 7: Concurrent Request Handling ==="
# Send multiple requests in parallel
CURL_PIDS=()
for i in {1..5}; do
    rpc '{"jsonrpc":"2.0","id":5,"method":"tools/list"}' > /dev/null 2>&1 &
    CURL_PIDS+=($!)
done
for p in "${CURL_PIDS[@]}"; do
    wait "$p" 2>/dev/null || true
done

# Check if server is still running
if ps -p $SERVER_PID > /dev/null 2>&1; then
    test_pass "Server handles concurrent requests"
else
    test_fail "Server crashed during concurrent requests"
fi

echo "=== Test 8: Graceful Shutdown ==="
if [ -n "$SERVER_PID" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
    GPID=$SERVER_PID
    stop_server
    if ps -o stat= -g "$GPID" 2>/dev/null | grep -qv "^Z"; then
        test_fail "Server survived shutdown"
    else
        test_pass "Server shut down"
    fi
else
    test_fail "Server was not running at shutdown"
fi

# Summary
echo ""
echo "=== Test Summary ==="
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"

if [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ All API server tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi
