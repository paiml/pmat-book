#!/bin/bash
# TDD Test: Chapter 22 - Health Monitoring and System Verification
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

# Create test workspace
TEST_DIR=$(mktemp -d)
echo "Test directory: $TEST_DIR"

# Cleanup on exit
cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

cd "$TEST_DIR"

echo "=== Test 1: System Health Check ==="
# Run a comprehensive health check
HEALTH_OUTPUT=$(pmat diagnose 2>&1) || HEALTH_OUTPUT=""
if echo "$HEALTH_OUTPUT" | grep -q "health\|system\|status\|ok"
then
    test_pass "System health check runs"
else
    pmat_fail "Health monitoring system available"
fi

echo "=== Test 2: Component Status Verification ==="
# Check individual components
# 3.44.0 feature-test names (exact; anything else exits 1)
COMPONENTS="ast.rust analysis.complexity cache.subsystem"
for component in $COMPONENTS; do
    if out=$(pmat diagnose --only "$component" --format compact 2>/dev/null) && grep -q '"ok":true' <<<"$out"
    then
        test_pass "Component '$component' verified"
    else
        pmat_fail "Component '$component' verified"
    fi
done

echo "=== Test 3: Performance Metrics Collection ==="
if out=$(pmat diagnose --verbose 2>&1) && grep -q "time\|ms\|performance\|latency" <<<"$out"
then
    test_pass "Performance metrics collected"
else
    pmat_fail "Performance monitoring available"
fi

echo "=== Test 4: Dependency Verification ==="
# Check system dependencies
if out=$(pmat diagnose 2>&1) && grep -q "depend\|version\|require\|cargo\|rust" <<<"$out"
then
    test_pass "Dependency verification works"
else
    pmat_fail "Dependency checking available"
fi

echo "=== Test 5: Configuration Validation ==="
# Create a test configuration
cat > pmat-config.toml << 'EOF'
[analysis]
max_complexity = 10
timeout = 60

[cache]
enabled = true
size_mb = 100

[quality]
min_grade = "B+"
EOF

if PMAT_CONFIG=pmat-config.toml pmat diagnose 2>/dev/null
then
    test_pass "Configuration validation works"
else
    pmat_fail "Config validation capability exists"
fi

echo "=== Test 6: Error Detection and Reporting ==="
# Intentionally create an issue
mkdir -p broken-project
cd broken-project
cat > invalid.rs << 'EOF'
fn broken_syntax {
    this is not valid rust
}
EOF

# diagnose self-tests the pmat binary, not the project in the cwd: the broken
# file must not change its verdict (the chapter documents this).
rc=0; ERROR_OUTPUT=$(pmat diagnose 2>&1) || rc=$?
if [ $rc -eq 0 ] && echo "$ERROR_OUTPUT" | grep -q "Failed: 0"
then
    test_pass "diagnose ignores the broken project and reports pmat's own self-tests (Failed: 0)"
else
    pmat_fail "diagnose self-test verdict (exit $rc)"
fi
cd ..

echo "=== Test 7: Resource Usage Monitoring ==="
# The only resource field diagnose reports is cache.subsystem.memory_pressure in
# the JSON report. It is in-process (same as pmat memory), not a project measurement.
if out=$(pmat diagnose --format json 2>/dev/null) && grep -q '"memory_pressure"' <<<"$out"
then
    test_pass "Resource field reported in JSON (cache.subsystem.memory_pressure, in-process)"
else
    pmat_fail "Resource tracking available"
fi

echo "=== Test 8: Diagnostic Report Generation ==="
if pmat diagnose --format json > diagnostic-report.json 2>/dev/null
then
    if [ -s diagnostic-report.json ]; then
        test_pass "Diagnostic report generated"
    else
        pmat_fail "Report generation completed"
    fi
else
    pmat_fail "Diagnostic reporting available"
fi

# Summary
echo ""
echo "=== Test Summary ==="
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"

if [ $FAIL_COUNT -eq 0 ] && [ $PASS_COUNT -eq 0 ]; then
    echo "⚠️  SKIPPED: this run verified NOTHING"
    exit 0
fi
if [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ All health monitoring tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi
