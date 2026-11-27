#!/bin/bash
# TDD Test: Chapter 18 - API Server and WebSocket Support
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

echo "=== Test 1: Start API Server ==="
# Without pmat there is no server to test: the whole suite is SKIPPED, not failed.
if ! type -P pmat >/dev/null 2>&1; then
    test_skip "API server tests not run: pmat not on PATH (this run verified NOTHING about the API)"
    echo "⚠️  SKIPPED: this run verified NOTHING"
    exit 0
fi

# The server never exits on its own: bound its lifetime with timeout(1) so a
# lost cleanup cannot hold the job, and wait only on pids we name.
setsid timeout -k 5 120 pmat serve --port 9090 > server.log 2>&1 &
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

echo "=== Test 2: Health Check Endpoint ==="
if curl -s -m 10 http://localhost:9090/health | grep -q "healthy"
then
    test_pass "Health check endpoint responds"
else
    # Try alternative response format
    HEALTH_RESPONSE=$(curl -s -m 10 http://localhost:9090/health)
    if curl -sf -m 10 http://localhost:9090/health >/dev/null; then
        test_pass "Health endpoint returns 2xx: $HEALTH_RESPONSE"
    else
        test_fail "Health check endpoint not responding"
    fi
fi

echo "=== Test 3: Analyze Endpoint ==="
ANALYZE_RESPONSE=$(curl -sf -m 10 -X POST http://localhost:9090/analyze \
    -H "Content-Type: application/json" \
    -d "{\"path\": \"$TEST_DIR\"}" 2>/dev/null || echo "")

if [ ! -z "$ANALYZE_RESPONSE" ]; then
    if echo "$ANALYZE_RESPONSE" | grep -q "files\|lines"
    then
        test_pass "Analyze endpoint responds with data"
    else
        test_fail "Analyze endpoint did not respond with data"
    fi
else
    test_fail "Analyze endpoint not responding"
fi

echo "=== Test 4: Context Generation Endpoint ==="
CONTEXT_RESPONSE=$(curl -sf -m 10 -X POST http://localhost:9090/context \
    -H "Content-Type: application/json" \
    -d "{\"path\": \"$TEST_DIR\"}" 2>/dev/null || echo "")

if [ ! -z "$CONTEXT_RESPONSE" ]; then
    test_pass "Context endpoint responds"
else
    test_fail "Context endpoint not responding"
fi

echo "=== Test 5: WebSocket Support Check ==="
# Check if server log mentions WebSocket
if grep -q -i "websocket\|ws://" server.log 2>/dev/null
then
    test_pass "WebSocket support detected in server logs"
else
    # Alternative: Check for upgrade headers support
    WS_CHECK=$(curl -s -m 10 -I -H "Upgrade: websocket" \
        -H "Connection: Upgrade" \
        http://localhost:9090/ws 2>/dev/null || echo "")
    
    if echo "$WS_CHECK" | grep -q "101\|Upgrade\|websocket"
    then
        test_pass "WebSocket upgrade headers supported"
    else
        test_fail "WebSocket upgrade headers not supported"
    fi
fi

echo "=== Test 6: API Version Endpoint ==="
VERSION_RESPONSE=$(curl -sf -m 10 http://localhost:9090/version 2>/dev/null || \
    curl -sf -m 10 http://localhost:9090/api/version 2>/dev/null || echo "")

if [ ! -z "$VERSION_RESPONSE" ]; then
    test_pass "Version endpoint responds"
else
    # Version might be in health or status
    test_fail "Version info not available through API"
fi

echo "=== Test 7: Concurrent Request Handling ==="
# Send multiple requests in parallel
CURL_PIDS=()
for i in {1..5}; do
    curl -s -m 10 http://localhost:9090/health > /dev/null 2>&1 &
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
        test_skip "Server shut down"
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