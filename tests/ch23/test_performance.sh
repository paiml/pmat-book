#!/bin/bash
# TDD Test: Chapter 23 - Performance Testing Suite
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

# Create test project with performance issues
cat > main.rs << 'EOF'
fn main() {
    println!("Performance test project");
    let result = expensive_computation(1000);
    println!("Result: {}", result);
}

fn expensive_computation(n: u32) -> u64 {
    // Intentionally inefficient for testing
    if n <= 1 {
        return 1;
    }
    expensive_computation(n - 1) + expensive_computation(n - 2)
}

fn memory_intensive_function() -> Vec<Vec<u8>> {
    let mut data = Vec::new();
    for _ in 0..1000 {
        data.push(vec![0u8; 1024 * 1024]); // 1MB chunks
    }
    data
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_computation() {
        assert!(expensive_computation(10) > 0);
    }
    
    #[test]
    fn test_memory() {
        let data = memory_intensive_function();
        assert_eq!(data.len(), 1000);
    }
}
EOF

cat > Cargo.toml << 'EOF'
[package]
name = "perf-test"
version = "0.1.0"
edition = "2021"

[profile.release]
opt-level = 3
EOF

echo "=== Test 1: Basic Performance Test ==="
# pmat's own throughput budget (389,600 LOC/s, SPECIFICATION.md Sec. 30). ch23: exit 1 on ordinary hardware.
rc=0; PERF_OUTPUT=$(timeout 300 pmat test performance 2>&1) || rc=$?
if [ $rc -eq 0 ] && echo "$PERF_OUTPUT" | grep -q "Single-threaded throughput: [0-9]* LOC/s"
then
    test_pass "Performance suite passes its throughput budget"
else
    pmat_fail "Performance suite passes its throughput budget (pmat test performance exit $rc)"
fi

echo "=== Test 2: Property-Based Testing ==="
rc=0; PROP_OUTPUT=$(timeout 300 pmat test property 2>&1) || rc=$?
if [ $rc -eq 0 ] && echo "$PROP_OUTPUT" | grep -q "Running property-based test suite"
then
    test_pass "Property-based suite passes"
else
    pmat_fail "Property-based suite passes (pmat test property exit $rc)"
fi

echo "=== Test 3: Memory Usage Testing ==="
# Budget: peak RSS <= 10240 KB for 20K LOC (ch23: exit 1 on ordinary hardware).
rc=0; MEM_OUTPUT=$(timeout 300 pmat test memory 2>&1) || rc=$?
if [ $rc -eq 0 ]; then
    test_pass "Memory suite passes its memory budget"
else
    # Try with flag (documented: --memory enables memory usage testing)
    rc=0; MEM_FLAG_OUTPUT=$(timeout 300 pmat test --memory 2>&1) || rc=$?
    if [ $rc -eq 0 ]; then
        test_pass "Memory testing with flag passes its memory budget"
    else
        pmat_fail "Memory suite passes its memory budget (pmat test memory exit $rc)"
    fi
fi

echo "=== Test 4: Throughput Testing ==="
rc=0; THR_OUTPUT=$(timeout 300 pmat test throughput 2>&1) || rc=$?
if [ $rc -eq 0 ]; then
    test_pass "Throughput suite passes its throughput budget"
else
    # Try with flag (documented: --throughput enables throughput testing)
    rc=0; THR_FLAG_OUTPUT=$(timeout 300 pmat test --throughput 2>&1) || rc=$?
    if [ $rc -eq 0 ]; then
        test_pass "Throughput testing with flag passes its throughput budget"
    else
        pmat_fail "Throughput suite passes its throughput budget (pmat test throughput exit $rc)"
    fi
fi

echo "=== Test 5: Regression Detection ==="
# Portable check: variance across --iterations runs, no absolute target (ch23 "Using It in CI").
rc=0; REG_OUTPUT=$(timeout 120 pmat test regression --iterations 2 2>&1) || rc=$?
if [ $rc -eq 0 ] && echo "$REG_OUTPUT" | grep -q "Regression tests passed!"
then
    test_pass "Regression detection passes (run-to-run variance)"
else
    pmat_fail "Regression detection passes (pmat test regression exit $rc)"
fi

echo "=== Test 6: Integration Test Suite ==="
# ch23: integration exits 0 by reporting that it found nothing to run. Only that message counts.
rc=0; INT_OUTPUT=$(timeout 120 pmat test integration 2>&1) || rc=$?
if [ $rc -eq 0 ] && echo "$INT_OUTPUT" | grep -q "No separate integration test file found"
then
    test_pass "Integration suite runs; it reports no integration test file (nothing executed)"
else
    pmat_fail "Integration test suite runs (pmat test integration exit $rc)"
fi

echo "=== Test 7: All Test Suites ==="
# Runs the performance gate first; on ordinary hardware it exits 1 at the throughput budget (ch23).
rc=0; ALL_OUTPUT=$(timeout 300 pmat test all 2>&1) || rc=$?
if [ $rc -eq 0 ]; then
    test_pass "All test suites pass"
else
    pmat_fail "All test suites pass (pmat test all exit $rc)"
fi

echo "=== Test 8: Test Output Format ==="
# -o/--output writes plain text, not JSON (ch23 "The Real Options").
rm -f results.json
rc=0; timeout 120 pmat test integration -o results.json >/dev/null 2>&1 || rc=$?
if [ $rc -eq 0 ] && [ -s results.json ] && grep -q "Performance Test Results" results.json
then
    test_pass "Results written to file as plain text (-o)"
else
    pmat_fail "Test output formatting available (pmat test integration -o exit $rc)"
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
    echo "✅ All performance testing tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi
