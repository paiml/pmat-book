#!/bin/bash
# TDD Test: Chapter 18 - Roadmap Management Commands
# Checks the flags pmat 3.44.0 accepts (see src/ch18-00-api.md, Part 2).
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

# A failed pmat command fails the run; with pmat absent the check is SKIPPED.
pmat_fail() {
    if type -P pmat >/dev/null 2>&1; then test_fail "$1"; else test_skip "$1 (pmat not on PATH)"; fi
}

test_pass() {
    echo "✅ PASS: $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

test_fail() {
    echo "❌ FAIL: $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

# Without pmat there is no roadmap to test: the whole suite is SKIPPED, not passed.
if ! type -P pmat >/dev/null 2>&1; then
    test_skip "roadmap tests not run: pmat not on PATH (this run verified NOTHING about roadmap)"
    echo "⚠️  SKIPPED: this run verified NOTHING"
    exit 0
fi

# Create test workspace
TEST_DIR=$(mktemp -d)
echo "Test directory: $TEST_DIR"

# Cleanup on exit
cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

cd "$TEST_DIR"

# Create a sample project
cat > main.rs << 'EOF'
fn main() {
    println!("Sprint Management System");
}

fn calculate_velocity(completed: u32, total: u32) -> f32 {
    (completed as f32 / total as f32) * 100.0
}
EOF

cat > Cargo.toml << 'EOF'
[package]
name = "sprint-tracker"
version = "0.1.0"
edition = "2021"
EOF

echo "=== Test 1: Initialize Roadmap Sprint ==="
# The directory must already exist: pmat roadmap init does not create docs/execution/.
mkdir -p docs/execution
if pmat roadmap init --version "v1.0.0" --title "Core features" 2>/dev/null \
    && [ -s docs/execution/roadmap.md ]
then
    test_pass "Sprint initialized successfully"
else
    pmat_fail "Roadmap init command available"
fi

# Tasks are rows written into the roadmap table by hand (there is no `roadmap add`).
# Task IDs are exactly four digits: PMAT-0001, not PMAT-001.
sed -i '/^|----|/a | PMAT-0001 | Implement token bucket | pending | medium | P0 |' docs/execution/roadmap.md

echo "=== Test 2: Generate PDMT Todos ==="
OUTPUT=$(pmat roadmap todos 2>/dev/null) || OUTPUT=""
if echo "$OUTPUT" | grep -q "todo\|task\|generated" && [ -s todos.md ]
then
    test_pass "PDMT todos generated from roadmap"
else
    pmat_fail "Todos generation command available"
fi

echo "=== Test 3: Start a Task ==="
if pmat roadmap start "PMAT-0001" 2>/dev/null
then
    test_pass "Task PMAT-0001 started"
else
    pmat_fail "Task management available"
fi

echo "=== Test 4: Complete Task with Quality Check ==="
# `complete` runs the repo-wide quality checks first (the default; no flag needed).
if pmat roadmap complete "PMAT-0001" 2>/dev/null
then
    test_pass "Task completed with quality validation"
else
    pmat_fail "Quality validation on completion"
fi

echo "=== Test 5: Check Sprint Status ==="
STATUS=$(pmat roadmap status 2>/dev/null) || STATUS=""
if echo "$STATUS" | grep -q "Sprint v1.0.0\|Progress:"
then
    test_pass "Sprint status retrieved"
else
    pmat_fail "Status command available"
fi

echo "=== Test 6: Run Quality Checks ==="
# The flag is --task-id; the checks are repo-wide regardless of the task named.
if pmat roadmap quality-check --task-id "PMAT-0001" 2>/dev/null
then
    test_pass "Quality check passed for task"
else
    pmat_fail "Quality validation integrated"
fi

echo "=== Test 7: Validate Sprint for Release ==="
# validate must refuse to certify release readiness it cannot measure: exit 1 and say so.
# (pmat holds no state for the Definition-of-Done checklist, so it never certifies.)
VALIDATE_OUTPUT=$(pmat roadmap validate --sprint v1.0.0 2>&1) && VALIDATE_RC=0 || VALIDATE_RC=$?
if [ "$VALIDATE_RC" = 1 ] && echo "$VALIDATE_OUTPUT" | grep -q "NOT ready for release\|readiness NOT certified"
then
    test_pass "Sprint release readiness check runs and refuses to certify (exit 1)"
else
    pmat_fail "Release readiness check available"
fi

echo "=== Test 8: Generate Roadmap Report ==="
if pmat roadmap status --sprint v1.0.0 --format json > roadmap.json 2>/dev/null
then
    if [ -s roadmap.json ] && grep -q '"tasks"' roadmap.json; then
        test_pass "Roadmap report generated in JSON"
    else
        pmat_fail "Roadmap export capability available"
    fi
else
    pmat_fail "Roadmap generation feature available"
fi

# Summary
echo ""
echo "=== Test Summary ==="
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"

if [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ All roadmap tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi
