#!/bin/bash
# TDD Test: Chapter 29 - Time-Travel Debugging status
# Chapter 29 is marked Not Implemented. This test checks that claim against
# the pmat on PATH, so the chapter goes red the day `pmat debug` ships and the
# banners have to be rewritten as instructions.

echo "=== Testing Chapter 29: pmat debug status (ACTUAL PMAT VALIDATION) ==="

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

if ! command -v pmat &> /dev/null; then
    echo "❌ FATAL: pmat binary not found in PATH"
    exit 1
fi

echo "Using pmat version: $(pmat --version | head -n 1)"

BOOK_SRC="$(cd "$(dirname "$0")/../../src" && pwd)"
WORK_DIR=$(mktemp -d)
trap 'rm -rf "${WORK_DIR:?}"' EXIT
cd "$WORK_DIR" || exit 1

# expect_refusal <name> <expected stderr text> <args...>
# The command must exit 2, print the text, and leave no file behind.
expect_refusal() {
    local name="$1" want="$2"
    shift 2
    local out rc
    out=$(timeout 30 pmat "$@" 2>&1 </dev/null)
    rc=$?
    if [ "$rc" -ne 2 ]; then
        test_fail "$name: exit $rc, expected 2 (the chapter says it does not work)"
    elif ! printf '%s\n' "$out" | grep -qF -- "$want"; then
        test_fail "$name: exit 2 but did not print: $want"
    else
        test_pass "$name: exit 2, $want"
    fi
}

expect_refusal "debug serve" "pmat debug serve is not implemented (DEBUG-002)" \
    debug serve --port 5678 --record-dir ./recordings
expect_refusal "debug replay" "pmat debug replay is not implemented (DEBUG-003)" \
    debug replay recording.pmat
expect_refusal "debug timeline" "unrecognized subcommand 'timeline'" \
    debug timeline recording.pmat
expect_refusal "debug compare" "unrecognized subcommand 'compare'" \
    debug compare trace1.pmat trace2.pmat

if [ -e recordings ] || [ -n "$(find . -name '*.pmat' -print -quit)" ]; then
    test_fail "a refused command left a recording behind"
else
    test_pass "no recording written"
fi

# Every page of the chapter carries the banner, so no page reads as working.
for page in ch29-00-time-travel-debugging.md ch29-01-recording.md \
    ch29-02-timeline.md ch29-03-comparison.md ch29-04-tdd-examples.md; do
    if grep -qF '> **Not implemented.**' "$BOOK_SRC/$page"; then
        test_pass "$page carries the Not implemented banner"
    else
        test_fail "$page has no Not implemented banner"
    fi
done

echo ""
echo "=== Chapter 29: $PASS_COUNT passed, $FAIL_COUNT failed ==="
[ "$FAIL_COUNT" -eq 0 ]
