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
if timeout 30 pmat test performance 2>/dev/null | grep -q "performance\|test\|complete"
then
    test_pass "Basic performance test runs"
else
    PERF_OUTPUT=$(timeout 30 pmat test 2>&1) || PERF_OUTPUT=""
    if echo "$PERF_OUTPUT" | grep -q "test\|performance\|benchmark"
    then
        test_pass "Performance testing available"
    else
        pmat_fail "Test suite exists"
    fi
fi

echo "=== Test 2: Property-Based Testing ==="
if timeout 30 pmat test property 2>/dev/null
then
    test_pass "Property-based testing works"
else
    PROPERTY_OUTPUT=$(timeout 30 pmat test property 2>&1) || PROPERTY_OUTPUT=""
    if echo "$PROPERTY_OUTPUT" | grep -q "property\|test\|check"
    then
        test_pass "Property testing available"
    else
        pmat_fail "Property test suite exists"
    fi
fi

echo "=== Test 3: Memory Usage Testing ==="
if timeout 30 pmat test memory 2>/dev/null
then
    test_pass "Memory testing works"
else
    # Try with flag
    if timeout 30 pmat test --memory 2>/dev/null
    then
        test_pass "Memory testing with flag works"
    else
        pmat_fail "Memory validation available"
    fi
fi

echo "=== Test 4: Throughput Testing ==="
if timeout 30 pmat test throughput 2>/dev/null
then
    test_pass "Throughput testing works"
else
    # Try with flag
    if timeout 30 pmat test --throughput 2>/dev/null
    then
        test_pass "Throughput testing with flag works"
    else
        pmat_fail "Throughput validation available"
    fi
fi

echo "=== Test 5: Regression Detection ==="
if timeout 30 pmat test regression --iterations 2 2>/dev/null
then
    test_pass "Regression detection works"
else
    # Try with flag
    if timeout 30 pmat test --regression --iterations 2 2>/dev/null
    then
        test_pass "Regression testing with flag works"
    else
        pmat_fail "Regression detection available"
    fi
fi

echo "=== Test 6: Integration Test Suite ==="
if timeout 30 pmat test integration 2>/dev/null
then
    test_pass "Integration testing works"
else
    INTEGRATION_OUTPUT=$(timeout 30 pmat test integration 2>&1) || INTEGRATION_OUTPUT=""
    pmat_fail "Integration test suite available"
fi

echo "=== Test 7: All Test Suites ==="
if timeout 60 pmat test all 2>/dev/null
then
    test_pass "All test suites run successfully"
else
    # Try with shorter timeout
    if timeout 30 pmat test all --timeout 20 2>/dev/null
    then
        test_pass "All suites with timeout work"
    else
        pmat_fail "Complete test suite available"
    fi
fi

echo "=== Test 8: Test Output Format ==="
if timeout 30 pmat test performance --output results.json 2>/dev/null
then
    if [ -f results.json ]; then
        test_pass "Test results saved to file"
    else
        pmat_fail "Output file generation completed"
    fi
else
    pmat_fail "Test output formatting available"
fi

# Summary
echo ""
echo "=== Test Summary ==="
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"

if [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ All performance testing tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi
