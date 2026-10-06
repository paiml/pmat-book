#!/usr/bin/env bash
# Chapter 18 status (#16): `pmat serve` is an MCP server, not the REST API the
# chapter was written for. This checks the chapter's status claims against the
# binary: every documented REST endpoint and /ws is 404 on a live server while
# MCP at the root path works, the broken commands exit non-zero, and the
# chapter carries the banners that say so.
set -euo pipefail

cd "$(dirname "$0")/../.."
CHAPTER=src/ch18-00-api.md

WORK_DIR=$(mktemp -d)
trap 'rm -rf "${WORK_DIR:?}"' EXIT

pass=0
fail=0
ok() { echo "PASS: $1"; pass=$((pass + 1)); }
bad() { echo "FAIL: $1"; fail=$((fail + 1)); }

# expect_exit WANT_RC TEXT ARGS...: pmat ARGS exits WANT_RC and prints TEXT.
expect_exit() {
    local want=$1 text=$2 rc=0
    shift 2
    (cd "$WORK_DIR" && timeout 30 pmat "$@") >"$WORK_DIR/out" 2>&1 || rc=$?
    if [ "$rc" -eq "$want" ] && grep -qF -- "$text" "$WORK_DIR/out"; then
        ok "pmat $* exits $want"
    else
        bad "pmat $*: want exit $want and '$text', got rc=$rc: $(head -n 1 "$WORK_DIR/out")"
    fi
}

echo "pmat: $(pmat --version | head -n 1)"

# 1. Commands the status block counts as broken.
expect_exit 2 "unexpected argument '--sprint'" roadmap init --sprint v1.0.0 --goal "Complete core features"
expect_exit 2 "unexpected argument '--from-analysis'" roadmap init --from-analysis book-analysis.json
expect_exit 2 "unexpected argument '--quality-check'" roadmap complete PMAT-001 --quality-check
expect_exit 2 "unexpected argument '--project'" roadmap quality-check --project book
expect_exit 2 "unexpected argument '--format'" roadmap todos --format markdown
expect_exit 2 "--sprint <SPRINT>" roadmap validate
expect_exit 2 "unrecognized subcommand '.'" analyze . --output book-analysis.json
expect_exit 2 "unexpected argument '--path'" report --path . --format json
expect_exit 2 "unexpected argument '--metrics'" serve --metrics
unset PMAT_MCP_HTTP_TOKEN  # the --host refusal only fires with no token set
expect_exit 4 "is not loopback" serve --port 9090 --host 0.0.0.0

# 2. A live server: MCP at the root works, every documented endpoint is 404.
PORT=$((20000 + RANDOM % 20000))
TOKEN=$(pmat mcp token)
PMAT_MCP_HTTP_TOKEN="$TOKEN" timeout 30 pmat serve --port "$PORT" >"$WORK_DIR/serve.log" 2>&1 &
SERVER=$!
call() {
    curl -sS -o "$WORK_DIR/body" -w '%{http_code}' -X "$1" "http://127.0.0.1:$PORT$2" \
        -H "Authorization: Bearer $TOKEN" \
        -H 'Content-Type: application/json' \
        -H 'Accept: application/json, text/event-stream' \
        -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' 2>/dev/null || true
}
code=000
for _ in $(seq 1 40); do
    code=$(call POST /)
    [ "$code" = 200 ] && break
    sleep 0.25
done
if [ "$code" = 200 ] && grep -qF '"tools"' "$WORK_DIR/body"; then
    ok "POST / returns MCP tools/list"
else
    bad "POST / gave HTTP $code; server log: $(head -n 3 "$WORK_DIR/serve.log")"
fi
if grep -qF 'pmat MCP (streamable HTTP) listening' "$WORK_DIR/serve.log"; then
    ok "pmat serve prints the MCP banner the chapter quotes"
else
    bad "pmat serve banner changed: $(head -n 1 "$WORK_DIR/serve.log")"
fi
for ep in /health /analyze /context /quality-gate /batch-analyze /report /ws; do
    get=$(call GET "$ep")
    post=$(call POST "$ep")
    if [ "$get" = 404 ] && [ "$post" = 404 ]; then
        ok "$ep is 404 (GET and POST)"
    else
        bad "$ep: GET=$get POST=$post, want 404 for both"
    fi
done
wait "$SERVER" 2>/dev/null || true

# 3. The chapter says what was measured.
if grep -qF '100% Working' "$CHAPTER"; then
    bad "$CHAPTER still claims 100% Working"
else
    ok "$CHAPTER no longer claims 100% Working"
fi
for want in '> **Not implemented: the REST API and WebSocket.**' \
    '> **Not implemented.** None of the endpoints in this section exists.' \
    '> **Not implemented.** pmat has no WebSocket endpoint.' \
    '> **Broken in pmat 3.42.0.**' \
    'pmat MCP (streamable HTTP) listening on http://127.0.0.1:8080/'; do
    if grep -qF -- "$want" "$CHAPTER"; then ok "$CHAPTER says: $want"; else bad "$CHAPTER lacks: $want"; fi
done
if grep -qF 'WebSocket endpoint: ws://127.0.0.1:8080/ws' "$CHAPTER"; then
    bad "$CHAPTER still quotes a banner pmat does not print"
else
    ok "$CHAPTER no longer quotes the invented banner"
fi

echo "$pass passed, $fail failed"
[ "$pass" -gt 0 ] && [ "$fail" -eq 0 ]
