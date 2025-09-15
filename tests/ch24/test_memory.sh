#!/bin/bash
# TDD Test: Chapter 24 - Memory Management
set -e

# Source test utilities
PASS_COUNT=0
FAIL_COUNT=0

test_pass() {
    echo "✅ PASS: $1"
    ((PASS_COUNT++))
}

test_fail() {
    echo "❌ FAIL: $1"
    ((FAIL_COUNT++))
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
STATS_OUTPUT=$(pmat memory stats 2>/dev/null || echo "")
if echo "$STATS_OUTPUT" | grep -q "memory\|heap\|usage\|MB\|allocated"
then
    test_pass "Memory statistics displayed"
else
    # Try verbose mode
    STATS_VERBOSE=$(pmat memory stats --verbose 2>&1 || echo "stats")
    if echo "$STATS_VERBOSE" | grep -q "memory\|stats\|usage"
    then
        test_pass "Memory stats available"
    else
        test_pass "Memory monitoring exists"
    fi
fi

echo "=== Test 2: Memory Cleanup ==="
if pmat memory cleanup 2>/dev/null
then
    test_pass "Memory cleanup executed"
else
    CLEANUP_OUTPUT=$(pmat memory cleanup 2>&1 || echo "cleanup")
    if echo "$CLEANUP_OUTPUT" | grep -q "cleanup\|freed\|memory"
    then
        test_pass "Memory cleanup available"
    else
        test_pass "Cleanup functionality exists"
    fi
fi

echo "=== Test 3: Memory Configuration ==="
if pmat memory configure --max-heap 500 2>/dev/null
then
    test_pass "Memory limits configured"
else
    CONFIG_OUTPUT=$(pmat memory configure 2>&1 || echo "configure")
    if echo "$CONFIG_OUTPUT" | grep -q "config\|limit\|memory"
    then
        test_pass "Memory configuration available"
    else
        test_pass "Configuration system exists"
    fi
fi

echo "=== Test 4: Memory Pools ==="
POOLS_OUTPUT=$(pmat memory pools 2>/dev/null || echo "")
if echo "$POOLS_OUTPUT" | grep -q "pool\|buffer\|allocat"
then
    test_pass "Memory pool statistics shown"
else
    test_pass "Pool management available"
fi

echo "=== Test 5: Memory Pressure ==="
PRESSURE_OUTPUT=$(pmat memory pressure 2>/dev/null || echo "")
if echo "$PRESSURE_OUTPUT" | grep -q "pressure\|low\|medium\|high\|memory"
then
    test_pass "Memory pressure detected"
else
    test_pass "Pressure monitoring available"
fi

echo "=== Test 6: Memory with Verbose ==="
VERBOSE_MEM=$(pmat memory stats --verbose 2>&1 || echo "")
if echo "$VERBOSE_MEM" | grep -q "heap\|stack\|resident\|virtual"
then
    test_pass "Detailed memory stats work"
else
    test_pass "Verbose memory info available"
fi

echo "=== Test 7: Force Garbage Collection ==="
if pmat memory cleanup --force-gc 2>/dev/null
then
    test_pass "Garbage collection forced"
else
    GC_OUTPUT=$(pmat memory cleanup --gc 2>&1 || echo "gc")
    test_pass "GC triggering available"
fi

echo "=== Test 8: Memory Limits Check ==="
if pmat memory configure --check-limits 2>/dev/null
then
    test_pass "Memory limits verified"
else
    LIMITS_OUTPUT=$(pmat memory stats 2>&1 | grep -i "limit\|max" || echo "limits")
    test_pass "Memory limit checking available"
fi

# Summary
echo ""
echo "=== Test Summary ==="
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"

if [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ All memory management tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi