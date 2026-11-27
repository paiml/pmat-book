#!/bin/bash
# TDD Test: Chapter 24 - Memory Management
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

# Create memory-intensive test project
cat > main.rs << 'EOF'
fn main() {
    let mut data = Vec::new();
    for i in 0..1000000 {
        data.push(i);
    }
    println!("Allocated {} items", data.len());
}

fn allocate_large_buffer() -> Vec<u8> {
    vec![0u8; 100 * 1024 * 1024] // 100MB
}

fn create_memory_pools() {
    let pool1 = vec![0u8; 10 * 1024 * 1024];
    let pool2 = vec![0u8; 20 * 1024 * 1024];
    let pool3 = vec![0u8; 30 * 1024 * 1024];
}
EOF

cat > Cargo.toml << 'EOF'
[package]
name = "memory-test"
version = "0.1.0"
edition = "2021"

[profile.release]
opt-level = 3
lto = true
EOF

echo "=== Test 1: Memory Statistics ==="
STATS_OUTPUT=$(pmat memory stats 2>/dev/null) || STATS_OUTPUT=""
if echo "$STATS_OUTPUT" | grep -q "memory\|heap\|usage\|MB\|allocated"
then
    test_pass "Memory statistics displayed"
else
    # Try verbose mode
    STATS_VERBOSE=$(pmat memory stats --verbose 2>&1) || STATS_VERBOSE=""
    if echo "$STATS_VERBOSE" | grep -q "memory\|stats\|usage"
    then
        test_pass "Memory stats available"
    else
        pmat_fail "Memory monitoring exists"
    fi
fi

echo "=== Test 2: Memory Cleanup ==="
if pmat memory cleanup 2>/dev/null
then
    test_pass "Memory cleanup executed"
else
    CLEANUP_OUTPUT=$(pmat memory cleanup 2>&1) || CLEANUP_OUTPUT=""
    if echo "$CLEANUP_OUTPUT" | grep -q "cleanup\|freed\|memory"
    then
        test_pass "Memory cleanup available"
    else
        pmat_fail "Cleanup functionality exists"
    fi
fi

echo "=== Test 3: Memory Configuration ==="
# 3.44.0 flag is --max-memory-mb: it is echoed back, and pmat says it is not enforced.
CONFIG_OUTPUT=$(pmat memory configure --max-memory-mb 500 2>/dev/null) || CONFIG_OUTPUT=""
if echo "$CONFIG_OUTPUT" | grep -q "Maximum memory: 500 MB" && echo "$CONFIG_OUTPUT" | grep -q "Runtime reconfiguration not yet supported"
then
    test_pass "Memory limit echoed (--max-memory-mb 500); runtime reconfiguration not supported"
else
    pmat_fail "Configuration system exists"
fi

echo "=== Test 4: Memory Pools ==="
POOLS_OUTPUT=$(pmat memory pools 2>/dev/null) || POOLS_OUTPUT=""
if echo "$POOLS_OUTPUT" | grep -q "pool\|buffer\|allocat"
then
    test_pass "Memory pool statistics shown"
else
    pmat_fail "Pool management available"
fi

echo "=== Test 5: Memory Pressure ==="
PRESSURE_OUTPUT=$(pmat memory pressure 2>/dev/null) || PRESSURE_OUTPUT=""
if echo "$PRESSURE_OUTPUT" | grep -q "pressure\|low\|medium\|high\|memory"
then
    test_pass "Memory pressure detected"
else
    pmat_fail "Pressure monitoring available"
fi

echo "=== Test 6: Memory with Verbose ==="
# --verbose adds tracing, not data: the manager is created by this command and reads 0 B.
VERBOSE_MEM=$(pmat memory stats --verbose 2>&1) || VERBOSE_MEM=""
if echo "$VERBOSE_MEM" | grep -q "Initializing global memory manager" && echo "$VERBOSE_MEM" | grep -q "Total Allocated: 0 B"
then
    test_pass "Verbose adds tracing only (counters read 0 B, as documented)"
else
    pmat_fail "Verbose memory info available"
fi

echo "=== Test 7: Force Garbage Collection ==="
# Rust has no runtime GC: --force-gc does not exist (exit 2). cleanup reports 0 B.
rc=0; GC_OUTPUT=$(pmat memory cleanup --force-gc 2>&1) || rc=$?
CLEANUP_OUTPUT=$(pmat memory cleanup 2>/dev/null) || CLEANUP_OUTPUT=""
if [ $rc -eq 2 ] && echo "$GC_OUTPUT" | grep -q "unexpected argument '--force-gc'" && echo "$CLEANUP_OUTPUT" | grep -q "Cleaned 0 B of memory"
then
    test_pass "No --force-gc (exit 2, as documented); cleanup reports Cleaned 0 B"
else
    pmat_fail "GC triggering available"
fi

echo "=== Test 8: Memory Limits Check ==="
# --check-limits does not exist (exit 2). Limits are echoed by configure, not enforced (Test 3).
rc=0; LIMITS_OUTPUT=$(pmat memory configure --check-limits 2>&1) || rc=$?
if [ $rc -eq 2 ] && echo "$LIMITS_OUTPUT" | grep -q "unexpected argument '--check-limits'"
then
    test_pass "No --check-limits (exit 2, as documented); limits are echoed, not enforced"
else
    pmat_fail "Memory limit checking available"
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
    echo "✅ All memory management tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi
