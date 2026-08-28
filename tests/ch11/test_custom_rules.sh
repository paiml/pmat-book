#!/bin/bash
# TDD Test: Chapter 11 - Custom Quality Rules
#
# WHAT THIS REPLACES
#
# The previous version of this file wrote seven YAML "rule" files under
# .pmat/rules/ and then asserted, seven times, that the files it had just
# written existed. It never invoked pmat once. It passed for a year while every
# command the chapter documented (`pmat rules init`, `create`, `test`, ...)
# exited with `error: unrecognized subcommand`, and the chapter carried a
# "✅ 100% Working" badge on the strength of it.
#
# Every assertion below runs the real binary and checks its real output. If a
# claim in src/ch11-00-custom-rules.md stops being true, this test goes red.
#
# No cargo toolchain is required: the fixture disables the clippy, test and
# coverage gates and exercises the complexity gate, which is pmat's own AST
# analysis.

set -u

echo "=== Testing Chapter 11: Custom Quality Rules ==="

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
    echo "   Install it with: cargo install pmat"
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
# Fixture: the crate printed in the chapter. `classify` has cyclomatic 6.
# ---------------------------------------------------------------------------
mkdir -p "$TEST_DIR/rules-demo/src"
cd "$TEST_DIR/rules-demo" || exit 1

cat > Cargo.toml << 'EOF'
[package]
name = "rules-demo"
version = "0.1.0"
edition = "2021"
EOF

cat > src/lib.rs << 'EOF'
pub fn classify(n: i32) -> &'static str {
    if n < 0 {
        "negative"
    } else if n == 0 {
        "zero"
    } else if n < 10 {
        "small"
    } else if n < 100 {
        "medium"
    } else if n < 1000 {
        "large"
    } else {
        "huge"
    }
}
EOF

# ---------------------------------------------------------------------------
# Test 1: `pmat quality-gates init` writes .pmat-gates.toml
# ---------------------------------------------------------------------------
echo ""
echo "Test 1: quality-gates init"
INIT_OUT=$("$PMAT_BIN" quality-gates init 2>&1)
if [ -f .pmat-gates.toml ] && echo "$INIT_OUT" | grep -q "Created .pmat-gates.toml"; then
    test_pass "quality-gates init created .pmat-gates.toml"
else
    test_fail "quality-gates init did not create the config (output: $INIT_OUT)"
fi

# The chapter states the schema is exactly these eight keys. If pmat grows a
# key, the chapter is stale and this must go red.
for key in run_clippy clippy_strict run_tests test_timeout \
           check_coverage min_coverage check_complexity max_complexity; do
    grep -q "^${key} = " .pmat-gates.toml || test_fail "generated config is missing key: $key"
done
GEN_KEYS=$(grep -cE '^[a-z_]+ = ' .pmat-gates.toml)
if [ "$GEN_KEYS" = "8" ]; then
    test_pass "generated config has exactly the 8 keys the chapter documents"
else
    test_fail "generated config has $GEN_KEYS keys, chapter documents 8"
fi

# ---------------------------------------------------------------------------
# Test 2: `pmat quality-gates validate` accepts a good file, rejects a bad one
# ---------------------------------------------------------------------------
echo ""
echo "Test 2: quality-gates validate"
if "$PMAT_BIN" quality-gates validate 2>&1 | grep -q "Configuration is valid"; then
    test_pass "validate accepts the generated config"
else
    test_fail "validate rejected a freshly generated config"
fi

cp .pmat-gates.toml .pmat-gates.toml.bak
printf '[gates]\nmax_complexity = "ten"\n' > .pmat-gates.toml
BAD_OUT=$("$PMAT_BIN" quality-gates validate 2>&1)
BAD_RC=$?
if [ "$BAD_RC" -ne 0 ] && echo "$BAD_OUT" | grep -q "expected u32"; then
    test_pass "validate rejects a wrongly-typed value and exits non-zero"
else
    test_fail "validate accepted max_complexity = \"ten\" (rc=$BAD_RC): $BAD_OUT"
fi
mv .pmat-gates.toml.bak .pmat-gates.toml

# ---------------------------------------------------------------------------
# Test 3: `pmat quality-gates show` prints the MERGED configuration
# ---------------------------------------------------------------------------
echo ""
echo "Test 3: quality-gates show reflects edits"
cat > .pmat-gates.toml << 'EOF'
[gates]
run_clippy = false
run_tests = false
check_coverage = false
check_complexity = true
max_complexity = 10
EOF
SHOW_OUT=$("$PMAT_BIN" quality-gates show 2>&1)
if echo "$SHOW_OUT" | grep -q "run_clippy = false" && \
   echo "$SHOW_OUT" | grep -q "max_complexity = 10"; then
    test_pass "show reports the edited values"
else
    test_fail "show did not reflect the edited config: $SHOW_OUT"
fi
# The chapter warns that an unknown KEY is silently ignored. Prove it.
cp .pmat-gates.toml .pmat-gates.toml.bak
printf 'max_complexty = 3\n' >> .pmat-gates.toml
if "$PMAT_BIN" quality-gates show 2>&1 | grep -q "max_complexty"; then
    test_fail "a misspelled key now surfaces — the chapter's warning is stale"
else
    test_pass "a misspelled key is silently ignored (as the chapter warns)"
fi
mv .pmat-gates.toml.bak .pmat-gates.toml

# ---------------------------------------------------------------------------
# Test 4: the complexity gate PASSES at 10 and FAILS at 5, with exit 1
# ---------------------------------------------------------------------------
echo ""
echo "Test 4: the gate actually enforces"
PASS_OUT=$("$PMAT_BIN" quality-gates 2>&1)
PASS_RC=$?
if [ "$PASS_RC" -eq 0 ] && echo "$PASS_OUT" | grep -q "✓ complexity"; then
    test_pass "gate passes at max_complexity = 10 (exit 0)"
else
    test_fail "gate did not pass at max_complexity = 10 (rc=$PASS_RC): $PASS_OUT"
fi

sed -i.bak 's/max_complexity = 10/max_complexity = 5/' .pmat-gates.toml
FAIL_OUT=$("$PMAT_BIN" quality-gates 2>&1)
FAIL_RC=$?
if [ "$FAIL_RC" -eq 1 ]; then
    test_pass "gate exits 1 when the threshold is breached"
else
    test_fail "gate exited $FAIL_RC instead of 1 on a breach"
fi
# The chapter quotes this message verbatim, including the denominator.
if echo "$FAIL_OUT" | grep -q "classify in ./src/lib.rs has cyclomatic 6 (> 5)"; then
    test_pass "failure names the function and the measured value"
else
    test_fail "failure message changed shape: $FAIL_OUT"
fi
if echo "$FAIL_OUT" | grep -q "measured 1 function(s) in 1 of 1 file(s)"; then
    test_pass "failure reports the denominator (files parsed)"
else
    test_fail "failure no longer reports a denominator: $FAIL_OUT"
fi

# ---------------------------------------------------------------------------
# Test 5: --json and --config
# ---------------------------------------------------------------------------
echo ""
echo "Test 5: machine-readable output and an alternate config path"
JSON_OUT=$("$PMAT_BIN" quality-gates --json 2>&1 | sed -n '/^{/,$p')
if echo "$JSON_OUT" | grep -q '"passed": false' && echo "$JSON_OUT" | grep -q '"name": "complexity"'; then
    test_pass "--json emits a gates array with a passed flag"
else
    test_fail "--json output changed shape: $JSON_OUT"
fi

mkdir -p ci
sed 's/max_complexity = 5/max_complexity = 99/' .pmat-gates.toml > ci/lenient-gates.toml
if "$PMAT_BIN" quality-gates --config ci/lenient-gates.toml >/dev/null 2>&1; then
    test_pass "--config reads an alternate gate file"
else
    test_fail "--config ci/lenient-gates.toml did not pass at max_complexity = 99"
fi

# ---------------------------------------------------------------------------
# Test 6: `pmat quality-gate` (singular) — check selection and --report-only
# ---------------------------------------------------------------------------
echo ""
echo "Test 6: quality-gate (singular)"
SEL_OUT=$("$PMAT_BIN" quality-gate -p . --checks complexity,satd 2>&1)
if echo "$SEL_OUT" | grep -q "Complexity analysis" && echo "$SEL_OUT" | grep -q "SATD"; then
    test_pass "--checks accepts a comma-separated list and runs both"
else
    test_fail "--checks complexity,satd did not run both checks: $SEL_OUT"
fi

if "$PMAT_BIN" quality-gate -p . --checks bogus >/dev/null 2>&1; then
    test_fail "an unknown --checks value was accepted"
else
    test_pass "an unknown --checks value is rejected, not silently skipped"
fi

if "$PMAT_BIN" quality-gate -p . --report-only >/dev/null 2>&1; then
    test_pass "--report-only exits 0 even with blocking violations"
else
    test_fail "--report-only exited non-zero"
fi

# ---------------------------------------------------------------------------
# Test 7: the commands the OLD chapter documented must stay gone
# ---------------------------------------------------------------------------
echo ""
echo 'Test 7: the rules subcommand remains nonexistent'
if "$PMAT_BIN" rules --help >/dev/null 2>&1; then
    test_fail "a 'rules' subcommand now exists — the chapter's banner is stale"
else
    test_pass "no 'rules' subcommand (banner is still correct)"
fi

echo ""
echo "=== Chapter 11: $PASS_COUNT passed, $FAIL_COUNT failed ==="
[ "$FAIL_COUNT" -eq 0 ] || exit 1
