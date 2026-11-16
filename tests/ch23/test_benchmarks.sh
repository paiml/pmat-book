#!/bin/bash
# TDD Test: Chapter 23 - Benchmark and Performance Metrics
set -e

# Source test utilities
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

# Create test workspace
TEST_DIR=$(mktemp -d)
echo "Test directory: $TEST_DIR"

# Cleanup on exit
cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

cd "$TEST_DIR"

# Create benchmark project
mkdir -p benches
cat > benches/bench_main.rs << 'EOF'
use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn fibonacci(n: u64) -> u64 {
    match n {
        0 => 1,
        1 => 1,
        n => fibonacci(n-1) + fibonacci(n-2),
    }
}

fn criterion_benchmark(c: &mut Criterion) {
    c.bench_function("fib 20", |b| b.iter(|| fibonacci(black_box(20))));
}

criterion_group!(benches, criterion_benchmark);
criterion_main!(benches);
EOF

mkdir -p src
cat > src/lib.rs << 'EOF'
pub fn process_data(data: &[u8]) -> Vec<u8> {
    data.iter().map(|x| x.wrapping_add(1)).collect()
}

pub fn sort_data(mut data: Vec<i32>) -> Vec<i32> {
    data.sort_unstable();
    data
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_process() {
        let input = vec![1, 2, 3];
        let output = process_data(&input);
        assert_eq!(output, vec![2, 3, 4]);
    }
}
EOF

cat > Cargo.toml << 'EOF'
[package]
name = "bench-test"
version = "0.1.0"
edition = "2021"

[dev-dependencies]
criterion = "0.5"

[[bench]]
name = "bench_main"
harness = false
EOF

# Every check asserts on real `pmat test` output. The performance suite's exit
# code depends on host throughput (it fails below its LOC/s target on slow or
# loaded hosts), so exit codes are not asserted; the output is.
# Flags the book documents as non-existent (src/ch23-00-testing.md) are asserted
# to be rejected, never reported as "available".
run_pmat() { timeout 120 pmat "$@" 2>&1 || true; }

# expect_match <label> <output> <egrep pattern>
expect_match() {
    if echo "$2" | grep -qE "$3"
    then
        test_pass "$1"
    else
        test_fail "$1 (no match for: $3)"
    fi
}

echo "=== Test 1: Performance Suite Runs ==="
OUT=$(run_pmat test performance --iterations 1)
expect_match "Performance suite runs and reports its suite" "$OUT" "Suite: Performance"

echo "=== Test 2: --compare-baseline Is Not A Real Flag ==="
OUT=$(run_pmat test performance --compare-baseline)
expect_match "--compare-baseline rejected as documented" "$OUT" "unexpected argument '--compare-baseline'"

echo "=== Test 3: Custom Iterations ==="
OUT=$(run_pmat test performance --iterations 5)
expect_match "Custom iteration count is applied" "$OUT" "Iterations: 5"

echo "=== Test 4: Verbose Performance Metrics ==="
OUT=$(run_pmat test performance --iterations 1 --verbose)
expect_match "Verbose output reports measured throughput" "$OUT" "Single-threaded throughput: [0-9]+ LOC/s"

echo "=== Test 5: Performance with Timeout ==="
OUT=$(run_pmat test performance --iterations 1 --timeout 10)
expect_match "Timeout configuration is applied" "$OUT" "Timeout: 10s"

echo "=== Test 6: Output File ==="
OUT=$(run_pmat test performance --iterations 1 -o perf-report.json)
expect_match "-o reports where results were written" "$OUT" "Results written to: perf-report.json"
if [ -s perf-report.json ]
then
    expect_match "-o file holds the performance results" "$(cat perf-report.json)" "Suite: Performance"
else
    test_fail "-o did not write a non-empty perf-report.json"
fi

echo "=== Test 7: Performance Profiling ==="
OUT=$(run_pmat test performance --iterations 1 --perf)
expect_match "--perf run reports measured throughput" "$OUT" "Single-threaded throughput: [0-9]+ LOC/s"

echo "=== Test 8: Regression Mode ==="
OUT=$(run_pmat test performance --threshold 5)
expect_match "--threshold rejected as documented" "$OUT" "unexpected argument '--threshold'"
OUT=$(run_pmat test --regression --iterations 2)
expect_match "--regression applies the iteration count" "$OUT" "Iterations: 2"

# Summary
echo ""
echo "=== Test Summary ==="
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"

if [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ All benchmark tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi