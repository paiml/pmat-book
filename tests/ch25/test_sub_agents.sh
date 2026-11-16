#!/bin/bash
# TDD Test: Chapter 25 - Sub-Agents (`pmat agent`)
# Every check asserts on real `pmat agent` output from the installed pmat.
# No path to a pmat source checkout is used.

PASS_COUNT=0
FAIL_COUNT=0
TEST_DIR=$(mktemp -d)
trap 'rm -rf "${TEST_DIR:?}"' EXIT

test_pass() { echo "✅ PASS: $1"; PASS_COUNT=$((PASS_COUNT + 1)); }
test_fail() { echo "❌ FAIL: $1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

# expect_match <label> <output> <egrep pattern>
expect_match() {
    if echo "$2" | grep -qE -e "$3"; then
        test_pass "$1"
    else
        test_fail "$1 (no match for: $3)"
    fi
}

# Run pmat agent; print output, then a final "rc=N" line.
agent() {
    local out rc
    out=$(timeout 30 pmat agent "$@" 2>&1)
    rc=$?
    printf '%s\nrc=%s\n' "$out" "$rc"
}

echo "Running Chapter 25 Sub-Agents Tests (pmat $(pmat --version 2>&1 | head -n 1))"

echo "Testing pmat agent --help..."
HELP=$(agent --help)
for sub in start stop status monitor unmonitor health reload quality-gate mcp-server; do
    expect_match "help lists subcommand: $sub" "$HELP" "^  $sub  "
done
expect_match "help states the daemon needs the agent-daemon feature" "$HELP" "agent-daemon"
expect_match "help documents the default-build limitation" "$HELP" "not in the default feature set"

echo "Testing the default-build behaviour the help documents..."
for args in "start" "stop" "status" "health" "reload" "mcp-server" \
            "monitor --project-path $TEST_DIR" "unmonitor --project-id test" \
            "quality-gate --project $TEST_DIR"; do
    # shellcheck disable=SC2086
    OUT=$(agent $args)
    expect_match "agent ${args%% *} reports the feature is not enabled" \
        "$OUT" "Agent daemon feature not enabled"
    expect_match "agent ${args%% *} exits rc=1" "$OUT" "^rc=1\$"
done

echo "Testing argument validation..."
OUT=$(agent monitor)
expect_match "monitor requires --project-path" "$OUT" "--project-path <PROJECT_PATH>"
OUT=$(agent quality-gate)
expect_match "quality-gate requires --project" "$OUT" "--project <PROJECT>"

echo ""
echo "=== Test Summary ==="
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"
if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "✅ All sub-agent tests passed!"
    exit 0
fi
echo "❌ Some tests failed"
exit 1
