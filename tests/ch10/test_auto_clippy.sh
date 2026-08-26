#!/bin/bash
# TDD Test: Chapter 10 (src/ch10-00-auto-clippy.md) - Auto-clippy Integration
#
# WHAT THIS REPLACES
#
# The previous version of this file wrote a pmat.toml with a [clippy] section,
# a .pmat/clippy-rules.yaml and a .pmat/clippy-ignore.yaml, and then asserted
# that the files it had just written existed. It never invoked pmat. The
# commands the chapter documented (`pmat clippy enable|run|fix|cache`) do not
# exist; the real command is `pmat analyze clippy`.
#
# NOTE ON WIRING: `make test-ch10` runs tests/ch10/test_precommit.sh, not this
# file — the book's chapter numbering and its Makefile targets disagree. Run
# this one directly:  bash tests/ch10/test_auto_clippy.sh
#
# This test needs a cargo toolchain with clippy, because the command under test
# shells out to `cargo clippy`.

set -u

echo "=== Testing Chapter 10: Auto-clippy Integration ==="

PMAT_BIN=""
if command -v pmat &> /dev/null; then
    PMAT_BIN="pmat"
elif [ -x "../paiml-mcp-agent-toolkit/target/release/pmat" ]; then
    PMAT_BIN="../paiml-mcp-agent-toolkit/target/release/pmat"
elif [ -x "../paiml-mcp-agent-toolkit/target/debug/pmat" ]; then
    PMAT_BIN="../paiml-mcp-agent-toolkit/target/debug/pmat"
fi

if [ -z "$PMAT_BIN" ]; then
    echo "⚠️  SKIPPED: pmat not found on PATH — this run verified NOTHING"
    exit 0
fi
if ! cargo clippy --version >/dev/null 2>&1; then
    echo "⚠️  SKIPPED: cargo clippy is not installed — this run verified NOTHING"
    exit 0
fi

PMAT_BIN=$(command -v "$PMAT_BIN" || echo "$PMAT_BIN")
echo "Using PMAT binary: $PMAT_BIN"
"$PMAT_BIN" --version | head -1

PASS_COUNT=0
FAIL_COUNT=0
test_pass() { echo "✅ PASS: $1"; PASS_COUNT=$((PASS_COUNT + 1)); }
test_fail() { echo "❌ FAIL: $1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

TEST_DIR=$(mktemp -d)
cleanup() { rm -rf "$TEST_DIR"; }
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Fixture: the crate printed in the chapter. Two clippy findings —
# clippy::needless_return (High confidence) and clippy::len_zero (below High).
# ---------------------------------------------------------------------------
mkdir -p "$TEST_DIR/demo2/src"
cd "$TEST_DIR/demo2" || exit 1
cat > Cargo.toml << 'EOF'
[package]
name = "demo2"
version = "0.1.0"
edition = "2021"
EOF
cat > src/main.rs << 'EOF'
fn double(x: i32) -> i32 {
    return x * 2;
}

fn main() {
    let s = "hello".to_string();
    if s.len() > 0 {
        println!("{}", double(3));
    }
}
EOF
cp src/main.rs "$TEST_DIR/main.rs.orig"

json_field() { echo "$1" | sed -nE "s/.*\"$2\": ([0-9]+).*/\1/p" | head -1; }

# ---------------------------------------------------------------------------
# Test 1: the default confidence filters, and says how much it hid
# ---------------------------------------------------------------------------
echo ""
echo "Test 1: analyze clippy --dry-run at the default confidence"
HIGH_OUT=$("$PMAT_BIN" analyze clippy --dry-run 2>&1)
FOUND=$(json_field "$HIGH_OUT" diagnostics_found)
ELIG=$(json_field "$HIGH_OUT" diagnostics_eligible)
FILT=$(json_field "$HIGH_OUT" diagnostics_filtered_out)

if [ "${FOUND:-0}" -ge 2 ]; then
    test_pass "cargo clippy reported $FOUND diagnostics on the fixture"
else
    test_fail "expected at least 2 diagnostics, got '${FOUND:-none}': $HIGH_OUT"
fi
if [ "${FILT:-0}" -ge 1 ]; then
    test_pass "the default confidence hid $FILT diagnostic(s) and reported the count"
else
    test_fail "diagnostics_filtered_out was not reported: $HIGH_OUT"
fi
if echo "$HIGH_OUT" | grep -q '"code": "clippy::needless_return"'; then
    test_pass "needless_return survives the High confidence filter"
else
    test_fail "needless_return is no longer High confidence: $HIGH_OUT"
fi

# ---------------------------------------------------------------------------
# Test 2: --confidence low shows everything
# ---------------------------------------------------------------------------
echo ""
echo "Test 2: --confidence low"
LOW_OUT=$("$PMAT_BIN" analyze clippy --dry-run --confidence low 2>&1)
LOW_ELIG=$(json_field "$LOW_OUT" diagnostics_eligible)
if [ "${LOW_ELIG:-0}" -gt "${ELIG:-0}" ]; then
    test_pass "lowering the threshold surfaces more diagnostics ($ELIG -> $LOW_ELIG)"
else
    test_fail "--confidence low did not surface more than the default: $LOW_OUT"
fi

if "$PMAT_BIN" analyze clippy --dry-run --confidence bogus >/dev/null 2>&1; then
    test_fail "an invalid confidence level was accepted"
else
    test_pass "an invalid confidence level is rejected, not silently defaulted"
fi

# ---------------------------------------------------------------------------
# Test 3: -o writes the same JSON to a file
# ---------------------------------------------------------------------------
echo ""
echo "Test 3: -o"
"$PMAT_BIN" analyze clippy --dry-run --confidence low -o report.json >/dev/null 2>&1
if [ -s report.json ] && grep -q '"diagnostics_found"' report.json; then
    test_pass "-o wrote the JSON report to a file"
else
    test_fail "-o did not write a usable report"
fi

# ---------------------------------------------------------------------------
# Test 4: the chapter's central warning — "applied" writes no bytes.
#
# This assertion is deliberately inverted: it PASSES while the defect exists.
# The day pmat starts writing fixes, this goes red and the chapter's warning
# must be removed. That is the point — a documented defect needs a test too.
# ---------------------------------------------------------------------------
echo ""
echo "Test 4: non-dry-run reports success without modifying the file"
APPLY_OUT=$("$PMAT_BIN" analyze clippy --confidence low 2>&1)
if echo "$APPLY_OUT" | grep -q '"action": "applied"' && \
   echo "$APPLY_OUT" | grep -q '"successful_fixes": [1-9]'; then
    test_pass "the command claims it applied fixes"
else
    test_fail "output shape changed; re-check the chapter: $APPLY_OUT"
fi

if diff -q "$TEST_DIR/main.rs.orig" src/main.rs >/dev/null 2>&1; then
    test_pass "src/main.rs is unchanged — the chapter's warning is still correct"
else
    test_fail "pmat now writes fixes to disk — DELETE the warning from ch10-00-auto-clippy.md"
fi

# ---------------------------------------------------------------------------
# Test 5: cargo's own fixer, by contrast, does modify the file
# ---------------------------------------------------------------------------
echo ""
echo "Test 5: cargo clippy --fix (the chapter's recommended alternative)"
git init -q .
git -c user.email=book@example.com -c user.name=book add -A
git -c user.email=book@example.com -c user.name=book commit -qm init --no-verify
if cargo clippy --fix --allow-dirty --allow-staged >/dev/null 2>&1; then
    if ! diff -q "$TEST_DIR/main.rs.orig" src/main.rs >/dev/null 2>&1; then
        test_pass "cargo clippy --fix really rewrote the source"
    else
        test_fail "cargo clippy --fix left the file unchanged"
    fi
else
    test_fail "cargo clippy --fix failed to run"
fi

# ---------------------------------------------------------------------------
# Test 6: the command the OLD chapter documented must stay gone
# ---------------------------------------------------------------------------
echo ""
echo "Test 6: the top-level clippy subcommand remains nonexistent"
if "$PMAT_BIN" clippy --help >/dev/null 2>&1; then
    test_fail "a top-level 'clippy' subcommand now exists — the chapter is stale"
else
    test_pass "no top-level 'clippy' subcommand; the real one is 'analyze clippy'"
fi

echo ""
echo "=== Chapter 10 (auto-clippy): $PASS_COUNT passed, $FAIL_COUNT failed ==="
[ "$FAIL_COUNT" -eq 0 ] || exit 1
