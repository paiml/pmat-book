#!/bin/bash
# TDD Test: Chapter 24 - Cache Management
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

# Create project with cacheable operations
cat > main.rs << 'EOF'
use std::collections::HashMap;

struct Cache<K, V> {
    data: HashMap<K, V>,
    max_size: usize,
}

impl<K: Eq + std::hash::Hash, V> Cache<K, V> {
    fn new(max_size: usize) -> Self {
        Cache {
            data: HashMap::new(),
            max_size,
        }
    }
    
    fn get(&self, key: &K) -> Option<&V> {
        self.data.get(key)
    }
    
    fn insert(&mut self, key: K, value: V) {
        if self.data.len() >= self.max_size {
            // Simple eviction - remove first item
            if let Some(first_key) = self.data.keys().next().cloned() {
                self.data.remove(&first_key);
            }
        }
        self.data.insert(key, value);
    }
}

fn expensive_computation(n: u32) -> u64 {
    // Simulate expensive operation
    std::thread::sleep(std::time::Duration::from_millis(10));
    n as u64 * n as u64
}

fn main() {
    let mut cache = Cache::new(100);
    
    for i in 0..200 {
        let result = expensive_computation(i);
        cache.insert(i, result);
    }
    
    println!("Cache populated with {} items", cache.data.len());
}
EOF

cat > Cargo.toml << 'EOF'
[package]
name = "cache-test"
version = "0.1.0"
edition = "2021"

[dependencies]
lru = "0.12"
EOF

echo "=== Test 1: Cache Statistics ==="
# pmat 3.44.0: `pmat cache stats` is the only cache subcommand (see ch24 "Cache Statistics").
CACHE_STATS=$(pmat cache stats 2>/dev/null) || CACHE_STATS=""
if echo "$CACHE_STATS" | grep -q "PMAT Cache Statistics" && echo "$CACHE_STATS" | grep -q "On-disk caches under"
then
    test_pass "Cache statistics displayed"
else
    pmat_fail "Cache statistics displayed"
fi

echo "=== Test 2: Cache Hit Rate ==="
# A CLI process has no live cache session: the default report says "not measured",
# and --detailed says why. No hit rate is invented.
CACHE_OUTPUT=$(pmat cache stats 2>/dev/null) || CACHE_OUTPUT=""
DETAIL_OUTPUT=$(pmat cache stats --detailed 2>/dev/null) || DETAIL_OUTPUT=""
if echo "$CACHE_OUTPUT" | grep -q "Overall Effectiveness: not measured" && echo "$DETAIL_OUTPUT" | grep -q "Per-tier hit rates require a live cache session"
then
    test_pass "Hit rate reported as not measured (no live cache session)"
else
    pmat_fail "Hit rate reporting"
fi

echo "=== Test 3: Cache Size Information ==="
# On-disk size is real: place a 1 MB .pmat directory and check pmat measures it.
mkdir -p .pmat && head -c 1048576 /dev/zero > .pmat/blob.bin
SIZE_OUTPUT=$(pmat cache stats 2>/dev/null) || SIZE_OUTPUT=""
rm -rf .pmat
if echo "$SIZE_OUTPUT" | grep -q "\.pmat: 1 file(s), 1\.0 MB"
then
    test_pass "Cache size measured on disk (1.0 MB)"
else
    pmat_fail "Size tracking available"
fi

echo "=== Test 4: Cache Clear Operation ==="
# There is no `pmat cache clear` (exit 2). The documented remedy is deleting
# .pmat and .pmat-cache by hand; afterwards stats must report "none found".
rc=0; CLEAR_OUTPUT=$(pmat cache clear 2>&1) || rc=$?
mkdir -p .pmat-cache && echo cached > .pmat-cache/entry
rm -rf .pmat .pmat-cache
AFTER_OUTPUT=$(pmat cache stats 2>/dev/null) || AFTER_OUTPUT=""
if [ $rc -eq 2 ] && echo "$CLEAR_OUTPUT" | grep -q "unrecognized subcommand" && echo "$AFTER_OUTPUT" | grep -q "none found"
then
    test_pass "No cache clear subcommand (exit 2); deleting .pmat/.pmat-cache leaves 'none found'"
else
    pmat_fail "Cache management exists"
fi

echo "=== Test 5: Cache Optimization ==="
# There is no optimiser: `pmat cache optimize` exits 2 (unrecognized subcommand).
rc=0; OPTIMIZE_OUTPUT=$(pmat cache optimize 2>&1) || rc=$?
if [ $rc -eq 2 ] && echo "$OPTIMIZE_OUTPUT" | grep -q "unrecognized subcommand"
then
    test_pass "No optimize subcommand (exit 2, as documented)"
else
    pmat_fail "Optimization capability exists"
fi

echo "=== Test 6: Cache Performance Metrics ==="
# --perf does not exist (exit 2). Per-tier rates come from --detailed (Test 2).
rc=0; PERF_OUTPUT=$(pmat cache stats --perf 2>&1) || rc=$?
if [ $rc -eq 2 ] && echo "$PERF_OUTPUT" | grep -q "unexpected argument '--perf'"
then
    test_pass "No --perf flag (exit 2, as documented); per-tier metrics come from --detailed"
else
    pmat_fail "Performance tracking available"
fi

echo "=== Test 7: Cache Eviction Policy ==="
# No `configure` subcommand (exit 2): eviction cannot be set.
rc=0; EVICTION_OUTPUT=$(pmat cache configure --eviction lru 2>&1) || rc=$?
if [ $rc -eq 2 ] && echo "$EVICTION_OUTPUT" | grep -q "unrecognized subcommand"
then
    test_pass "No configure subcommand (exit 2, as documented); eviction is not configurable"
else
    pmat_fail "Eviction management available"
fi

echo "=== Test 8: Cache Warmup ==="
# No `warmup` subcommand (exit 2).
rc=0; WARMUP_OUTPUT=$(pmat cache warmup 2>&1) || rc=$?
if [ $rc -eq 2 ] && echo "$WARMUP_OUTPUT" | grep -q "unrecognized subcommand"
then
    test_pass "No warmup subcommand (exit 2, as documented)"
else
    pmat_fail "Warmup capability exists"
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
    echo "✅ All cache management tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi
