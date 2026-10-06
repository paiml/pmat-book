#!/usr/bin/env bash
# Chapter 15 transports (#15): pmat serves MCP over stdio and streamable HTTP
# only. WebSocket and SSE exit 2, and the chapter must say so rather than list
# them as supported. Every claim the chapter makes about the transports is
# checked against the binary here.
set -euo pipefail

cd "$(dirname "$0")/../.."
CHAPTER=src/ch15-00-mcp-tools.md

WORK_DIR=$(mktemp -d)
trap 'rm -rf "${WORK_DIR:?}"' EXIT

pass=0
fail=0
ok() { echo "PASS: $1"; pass=$((pass + 1)); }
bad() { echo "FAIL: $1"; fail=$((fail + 1)); }

# expect_refusal NAME EXPECTED_TEXT ARGS...: exit 2 and the fixed message.
expect_refusal() {
    local name=$1 text=$2 rc=0
    shift 2
    timeout 20 pmat "$@" >"$WORK_DIR/out" 2>&1 || rc=$?
    if [ "$rc" -eq 2 ] && grep -qF -- "$text" "$WORK_DIR/out"; then
        ok "$name exits 2: $text"
    else
        bad "$name: want exit 2 and '$text', got rc=$rc: $(head -n 1 "$WORK_DIR/out")"
    fi
}

echo "pmat: $(pmat --version | head -n 1)"

# 1. The transports the chapter says do not exist.
expect_refusal "serve --transport web-socket" "is not yet implemented" \
    serve --transport web-socket --port 18901
expect_refusal "serve --transport http-sse" "is not yet implemented" \
    serve --transport http-sse --port 18902
expect_refusal "the old Claude Desktop argv" "unexpected argument '--port'" \
    mcp --port 8081 --mode websocket

# 2. stdio answers an MCP initialize.
init='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"book","version":"0"}}}'
if printf '%s\n' "$init" | timeout 20 pmat --mode mcp 2>/dev/null | head -n 1 | grep -qF '"result"'; then
    ok "pmat --mode mcp answers initialize over stdio"
else
    bad "pmat --mode mcp did not answer initialize"
fi

# 3. Streamable HTTP: root path, bearer token, Accept header; /mcp and /health 404.
PORT=$((20000 + RANDOM % 20000))
TOKEN=$(pmat mcp token)
PMAT_MCP_HTTP_TOKEN="$TOKEN" timeout 30 pmat serve --transport http --port "$PORT" \
    >"$WORK_DIR/serve.log" 2>&1 &
SERVER=$!
rpc() {
    curl -sS -o "$WORK_DIR/body" -w '%{http_code}' "http://127.0.0.1:$PORT$1" \
        -H "Authorization: Bearer $TOKEN" \
        -H 'Content-Type: application/json' \
        -H 'Accept: application/json, text/event-stream' \
        -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' 2>/dev/null || true
}
code=000
for _ in $(seq 1 40); do
    code=$(rpc /)
    [ "$code" = 200 ] && break
    sleep 0.25
done
if [ "$code" = 200 ] && grep -qF '"tools"' "$WORK_DIR/body"; then
    ok "POST / with token and Accept returns tools/list"
else
    bad "POST / gave HTTP $code; server log: $(head -n 3 "$WORK_DIR/serve.log")"
fi
for path in /mcp /health; do
    code=$(rpc "$path")
    if [ "$code" = 404 ]; then ok "$path is 404"; else bad "$path gave HTTP $code, want 404"; fi
done
wait "$SERVER" 2>/dev/null || true

# 4. The chapter no longer advertises what does not exist.
for stale in '"--mode", "websocket"' '"mcp", "--port"' 'ws://localhost' '/mcp",' \
    '| WebSocket Mode |' 'pmat mcp --port 8080 --mode http'; do
    if grep -qF -- "$stale" "$CHAPTER"; then
        bad "$CHAPTER still contains: $stale"
    else
        ok "$CHAPTER no longer contains: $stale"
    fi
done
for want in '> **Not implemented: WebSocket, SSE and a background daemon.**' \
    '`pmat --mode mcp`' '`pmat serve --transport http --port 8080`' \
    '"args": ["--mode", "mcp"]'; do
    if grep -qF -- "$want" "$CHAPTER"; then ok "$CHAPTER says: $want"; else bad "$CHAPTER lacks: $want"; fi
done

echo "$pass passed, $fail failed"
[ "$pass" -gt 0 ] && [ "$fail" -eq 0 ]
