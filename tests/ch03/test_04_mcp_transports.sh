#!/bin/bash
# TDD Test: Chapter 3.4 - MCP Transports (CLI, MCP stdio, MCP over HTTP)
# Every assertion here corresponds to a transcript printed in
# src/ch03-04-mcp-transports.md. If a claim in that chapter stops being true,
# this test must go red.

set -e

echo "=== Testing Chapter 3.4: MCP Transports ==="

# ---------------------------------------------------------------------------
# Preconditions. A missing tool is reported as SKIPPED, never as a pass: a
# suite that cannot fail proves nothing.
# ---------------------------------------------------------------------------
PMAT_BIN=""
if command -v pmat &> /dev/null; then
    PMAT_BIN="pmat"
elif [ -x "../paiml-mcp-agent-toolkit/target/release/pmat" ]; then
    PMAT_BIN="../paiml-mcp-agent-toolkit/target/release/pmat"
elif [ -x "../paiml-mcp-agent-toolkit/target/debug/pmat" ]; then
    PMAT_BIN="../paiml-mcp-agent-toolkit/target/debug/pmat"
fi

for tool in curl jq; do
    command -v "$tool" &> /dev/null || {
        echo "⚠️  SKIPPED: $tool is not installed — this run verified NOTHING"
        exit 0
    }
done

if [ -z "$PMAT_BIN" ]; then
    echo "⚠️  SKIPPED: pmat not found on PATH — this run verified NOTHING"
    echo "   Install it with: cargo install pmat"
    exit 0
fi

PMAT_BIN=$(command -v "$PMAT_BIN" || echo "$PMAT_BIN")
echo "Using PMAT binary: $PMAT_BIN"
"$PMAT_BIN" --version | head -1

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

TEST_DIR=$(mktemp -d)
SERVER_PID=""

cleanup() {
    if [ -n "$SERVER_PID" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
        kill "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
    fi
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

TOKEN="pmat-book-test-token-0123456789"
INIT='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"book-test","version":"1"}}}'
LIST='{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'

# A fixture with exactly one piece of self-admitted technical debt.
mkdir -p "$TEST_DIR/src"
cat > "$TEST_DIR/src/main.rs" << 'EOF'
// TODO: replace this hand-rolled grader with the real one
fn grade(score: u32, strict: bool) -> &'static str {
    if strict {
        if score > 90 { "A" } else if score > 80 { "B" } else { "C" }
    } else if score > 70 {
        "pass"
    } else {
        "fail"
    }
}

fn main() {
    println!("{}", grade(85, true));
}
EOF
FIXTURE="$TEST_DIR/src/main.rs"
CALL_SATD="{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"tools/call\",\"params\":{\"name\":\"analyze_satd\",\"arguments\":{\"paths\":[\"$FIXTURE\"]}}}"

# ---------------------------------------------------------------------------
# Surface 1: the CLI
# ---------------------------------------------------------------------------
echo ""
echo "--- Surface 1: CLI ---"

if "$PMAT_BIN" analyze satd --path "$FIXTURE" > "$TEST_DIR/cli-satd.txt" 2>&1 &&
   grep -q "Found 1 SATD violations" "$TEST_DIR/cli-satd.txt"; then
    test_pass "CLI: pmat analyze satd finds the fixture's single TODO"
else
    test_fail "CLI: pmat analyze satd did not report 1 violation"
    cat "$TEST_DIR/cli-satd.txt"
fi

# ---------------------------------------------------------------------------
# Surface 2: MCP over stdio
# ---------------------------------------------------------------------------
echo ""
echo "--- Surface 2: MCP over stdio ---"

printf '%s\n%s\n' "$INIT" "$LIST" | "$PMAT_BIN" --mode mcp 2>/dev/null > "$TEST_DIR/stdio.jsonl" || true

if [ "$(sed -n 1p "$TEST_DIR/stdio.jsonl" | jq -r '.result.serverInfo.name')" = "paiml-mcp-agent-toolkit" ]; then
    test_pass "stdio: pmat --mode mcp answers initialize as paiml-mcp-agent-toolkit"
else
    test_fail "stdio: pmat --mode mcp did not answer initialize"
fi

sed -n 2p "$TEST_DIR/stdio.jsonl" | jq -S '.result.tools | sort_by(.name)' > "$TEST_DIR/tools-stdio.json"
STDIO_TOOL_COUNT=$(jq length "$TEST_DIR/tools-stdio.json")

if [ "$STDIO_TOOL_COUNT" -gt 0 ]; then
    test_pass "stdio: tools/list returns $STDIO_TOOL_COUNT tools"
else
    test_fail "stdio: tools/list returned no tools"
fi

# The env-var entry point must start the same server as --mode mcp.
printf '%s\n%s\n' "$INIT" "$LIST" | MCP_VERSION=1 "$PMAT_BIN" 2>/dev/null \
    | sed -n 2p | jq -S '.result.tools | sort_by(.name)' > "$TEST_DIR/tools-envvar.json" || true

ENVVAR_TOOL_COUNT=$(jq length "$TEST_DIR/tools-envvar.json" 2>/dev/null || echo 0)
if [ "$ENVVAR_TOOL_COUNT" -gt 0 ] &&
   diff -q "$TEST_DIR/tools-stdio.json" "$TEST_DIR/tools-envvar.json" > /dev/null 2>&1; then
    test_pass "stdio: MCP_VERSION=1 pmat serves the same surface as pmat --mode mcp"
else
    test_fail "stdio: MCP_VERSION=1 pmat differs from pmat --mode mcp (or served nothing)"
fi

printf '%s\n%s\n' "$INIT" "$CALL_SATD" | "$PMAT_BIN" --mode mcp 2>/dev/null \
    | sed -n 2p | jq -r '.result.content[0].text' > "$TEST_DIR/satd-stdio.json" || true

if [ "$(jq -r '.results.total_satd' "$TEST_DIR/satd-stdio.json")" = "1" ]; then
    test_pass "stdio: analyze_satd finds 1 debt item in the fixture"
else
    test_fail "stdio: analyze_satd did not report total_satd=1"
fi

# ---------------------------------------------------------------------------
# Surface 3: MCP over HTTP — refusals before the socket
# ---------------------------------------------------------------------------
echo ""
echo "--- Surface 3: MCP over HTTP (startup refusals) ---"

RC=0
env -u PMAT_MCP_HTTP_TOKEN "$PMAT_BIN" serve --transport http --port 18899 \
    > "$TEST_DIR/no-token.txt" 2>&1 || RC=$?
if [ "$RC" -eq 4 ] && grep -q "PMAT_MCP_HTTP_TOKEN is not set" "$TEST_DIR/no-token.txt"; then
    test_pass "HTTP: no token refuses to start (exit 4)"
else
    test_fail "HTTP: no token did not refuse with exit 4 (got $RC)"
    cat "$TEST_DIR/no-token.txt"
fi

RC=0
PMAT_MCP_HTTP_TOKEN='too-short-123' "$PMAT_BIN" serve --transport http --port 18899 \
    > "$TEST_DIR/short-token.txt" 2>&1 || RC=$?
if [ "$RC" -eq 1 ] && grep -q "must be at least 16 characters; got 13" "$TEST_DIR/short-token.txt"; then
    test_pass "HTTP: a 13-character token refuses to start (exit 1)"
else
    test_fail "HTTP: short token did not refuse with exit 1 (got $RC)"
    cat "$TEST_DIR/short-token.txt"
fi

for t in web-socket http-sse both all stdio; do
    RC=0
    PMAT_MCP_HTTP_TOKEN="$TOKEN" "$PMAT_BIN" serve --transport "$t" --port 18899 \
        > "$TEST_DIR/transport-$t.txt" 2>&1 || RC=$?
    if [ "$RC" -eq 2 ]; then
        test_pass "HTTP: --transport $t exits 2 (not implemented / not a value)"
    else
        test_fail "HTTP: --transport $t exited $RC, expected 2"
    fi
done

# ---------------------------------------------------------------------------
# Surface 3: MCP over HTTP — a live server
# ---------------------------------------------------------------------------
echo ""
echo "--- Surface 3: MCP over HTTP (live server) ---"

PORT=""
for candidate in $(seq 18810 18840); do
    if command -v ss > /dev/null 2>&1 && ss -tln 2>/dev/null | grep -q ":$candidate "; then
        continue
    fi
    PMAT_MCP_HTTP_TOKEN="$TOKEN" "$PMAT_BIN" serve --transport http --port "$candidate" \
        > "$TEST_DIR/server.log" 2>&1 &
    SERVER_PID=$!
    for _ in $(seq 1 30); do
        sleep 0.5
        if grep -q "listening on http://127.0.0.1:$candidate/" "$TEST_DIR/server.log" 2>/dev/null; then
            PORT="$candidate"
            break
        fi
        kill -0 "$SERVER_PID" 2>/dev/null || break
    done
    [ -n "$PORT" ] && break
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
    SERVER_PID=""
done

if [ -z "$PORT" ]; then
    test_fail "HTTP: could not bind a port in 18810-18840"
    cat "$TEST_DIR/server.log" 2>/dev/null || true
else
    test_pass "HTTP: server bound 127.0.0.1:$PORT and announced itself"
    URL="http://127.0.0.1:$PORT/"

    AUTH=(-H "Authorization: Bearer $TOKEN")
    HDRS=(-H "Content-Type: application/json" -H "Accept: application/json, text/event-stream")

    # No handshake is required: the FIRST request this server ever sees is a
    # tools/call, with no initialize and no session id.
    curl -s -X POST "$URL" "${AUTH[@]}" "${HDRS[@]}" -d "$CALL_SATD" \
        | jq -r '.result.content[0].text' > "$TEST_DIR/satd-nohandshake.json"
    if [ "$(jq -r '.results.total_satd' "$TEST_DIR/satd-nohandshake.json")" = "1" ]; then
        test_pass "HTTP: tools/call works as the first request, with no initialize"
    else
        test_fail "HTTP: tools/call without a prior initialize did not work"
        cat "$TEST_DIR/satd-nohandshake.json"
    fi

    # initialize at the ROOT path
    curl -s -X POST "$URL" "${AUTH[@]}" "${HDRS[@]}" -d "$INIT" > "$TEST_DIR/http-init.json"
    if [ "$(jq -r '.result.protocolVersion' "$TEST_DIR/http-init.json")" = "2024-11-05" ]; then
        test_pass "HTTP: initialize at / returns protocolVersion 2024-11-05"
    else
        test_fail "HTTP: initialize at / did not return a protocol version"
        cat "$TEST_DIR/http-init.json"
    fi

    # initialize issues no session id — clients do not need to carry one
    curl -s -D "$TEST_DIR/init-headers.txt" -o /dev/null -X POST "$URL" \
        "${AUTH[@]}" "${HDRS[@]}" -d "$INIT"
    if grep -qi '^HTTP/1.1 200' "$TEST_DIR/init-headers.txt" &&
       ! grep -qi '^mcp-session-id:' "$TEST_DIR/init-headers.txt"; then
        test_pass "HTTP: initialize returns 200 and issues no Mcp-Session-Id"
    else
        test_fail "HTTP: initialize response headers were not as documented"
        cat "$TEST_DIR/init-headers.txt"
    fi

    # tools/call works without a session id and without a prior initialize
    curl -s -X POST "$URL" "${AUTH[@]}" "${HDRS[@]}" -d "$CALL_SATD" \
        | jq -r '.result.content[0].text' > "$TEST_DIR/satd-http.json"
    if [ "$(jq -r '.results.total_satd' "$TEST_DIR/satd-http.json")" = "1" ]; then
        test_pass "HTTP: tools/call analyze_satd finds 1 debt item"
    else
        test_fail "HTTP: tools/call analyze_satd did not report total_satd=1"
        cat "$TEST_DIR/satd-http.json"
    fi

    # ...and returns byte-identical output to the stdio surface
    if diff -q "$TEST_DIR/satd-stdio.json" "$TEST_DIR/satd-http.json" > /dev/null 2>&1; then
        test_pass "HTTP == stdio: the same tools/call returns byte-identical JSON"
    else
        test_fail "HTTP != stdio: the same tools/call returned different JSON"
        diff "$TEST_DIR/satd-stdio.json" "$TEST_DIR/satd-http.json" || true
    fi

    # The tool surfaces are the same set, schemas included.
    curl -s -X POST "$URL" "${AUTH[@]}" "${HDRS[@]}" -d "$LIST" \
        | jq -S '.result.tools | sort_by(.name)' > "$TEST_DIR/tools-http.json"
    if diff -q "$TEST_DIR/tools-stdio.json" "$TEST_DIR/tools-http.json" > /dev/null 2>&1; then
        test_pass "HTTP == stdio: tools/list is identical ($STDIO_TOOL_COUNT tools, schemas included)"
    else
        test_fail "HTTP != stdio: tools/list differs"
        diff "$TEST_DIR/tools-stdio.json" "$TEST_DIR/tools-http.json" || true
    fi

    # The banner's tool count agrees with tools/list.
    BANNER_COUNT=$(grep -oE 'tools: [0-9]+' "$TEST_DIR/server.log" | grep -oE '[0-9]+' | head -1)
    if [ "$BANNER_COUNT" = "$STDIO_TOOL_COUNT" ]; then
        test_pass "HTTP: the startup banner's tool count ($BANNER_COUNT) matches tools/list"
    else
        test_fail "HTTP: banner says $BANNER_COUNT tools, tools/list says $STDIO_TOOL_COUNT"
    fi

    # Failure mode: no Accept header -> 406
    CODE=$(curl -s -o "$TEST_DIR/no-accept.json" -w '%{http_code}' -X POST "$URL" \
        "${AUTH[@]}" -H "Content-Type: application/json" -d "$INIT")
    if [ "$CODE" = "406" ] && grep -q "Accept header must include application/json or text/event-stream" "$TEST_DIR/no-accept.json"; then
        test_pass "HTTP: a request without Accept is rejected 406 with a named reason"
    else
        test_fail "HTTP: request without Accept returned $CODE"
        cat "$TEST_DIR/no-accept.json"
    fi

    # Failure mode: no Authorization header -> 401
    CODE=$(curl -s -o "$TEST_DIR/no-auth.json" -w '%{http_code}' -X POST "$URL" "${HDRS[@]}" -d "$INIT")
    if [ "$CODE" = "401" ] && grep -q "missing Authorization header" "$TEST_DIR/no-auth.json"; then
        test_pass "HTTP: an unauthenticated request gets 401"
    else
        test_fail "HTTP: unauthenticated request returned $CODE"
        cat "$TEST_DIR/no-auth.json"
    fi

    # Failure mode: wrong token -> 401
    CODE=$(curl -s -o "$TEST_DIR/bad-auth.json" -w '%{http_code}' -X POST "$URL" \
        -H "Authorization: Bearer wrong-token-but-long-enough-xxxx" "${HDRS[@]}" -d "$INIT")
    if [ "$CODE" = "401" ] && grep -q "invalid bearer token" "$TEST_DIR/bad-auth.json"; then
        test_pass "HTTP: a wrong bearer token gets 401"
    else
        test_fail "HTTP: wrong bearer token returned $CODE"
        cat "$TEST_DIR/bad-auth.json"
    fi

    # Failure mode: MCP is at the ROOT, so the habitual paths are 404
    for path in mcp health api/v1; do
        CODE=$(curl -s -o /dev/null -w '%{http_code}' -X POST "http://127.0.0.1:$PORT/$path" \
            "${AUTH[@]}" "${HDRS[@]}" -d "$INIT")
        if [ "$CODE" = "404" ]; then
            test_pass "HTTP: POST /$path is 404 (MCP lives at the root path)"
        else
            test_fail "HTTP: POST /$path returned $CODE, expected 404"
        fi
    done

    # Failure mode: the port is already taken
    RC=0
    PMAT_MCP_HTTP_TOKEN="$TOKEN" "$PMAT_BIN" serve --transport http --port "$PORT" \
        > "$TEST_DIR/in-use.txt" 2>&1 || RC=$?
    if [ "$RC" -eq 1 ] && grep -q "Address already in use" "$TEST_DIR/in-use.txt"; then
        test_pass "HTTP: a second server on the same port fails with 'Address already in use'"
    else
        test_fail "HTTP: second server on a busy port exited $RC"
        cat "$TEST_DIR/in-use.txt"
    fi
fi

# ---------------------------------------------------------------------------
# Registration: pmat init writes the stdio registration the chapter documents
# ---------------------------------------------------------------------------
echo ""
echo "--- Registration ---"

mkdir -p "$TEST_DIR/workspace"
"$PMAT_BIN" init --target claude --path "$TEST_DIR/workspace" > "$TEST_DIR/init.log" 2>&1 || true
if [ -f "$TEST_DIR/workspace/.mcp.json" ] &&
   [ "$(jq -r '.mcpServers.pmat.args | join(" ")' "$TEST_DIR/workspace/.mcp.json")" = "--mode mcp" ]; then
    test_pass "pmat init --target claude registers 'pmat --mode mcp' in .mcp.json"
else
    test_fail "pmat init --target claude did not write the documented .mcp.json"
    cat "$TEST_DIR/workspace/.mcp.json" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== Test Summary ==="
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"
if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "✅ All $PASS_COUNT Chapter 3.4 transport tests passed!"
    exit 0
else
    echo "❌ $FAIL_COUNT of $((PASS_COUNT + FAIL_COUNT)) Chapter 3.4 transport tests failed"
    exit 1
fi
