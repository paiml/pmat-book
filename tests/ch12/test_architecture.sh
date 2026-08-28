#!/bin/bash
# TDD Test: Chapter 12 - Architecture Analysis
#
# WHAT THIS REPLACES
#
# The previous version of this file wrote five YAML files (.pmat/architecture.yaml,
# .pmat/microservices.yaml, .pmat/patterns/custom-patterns.yaml, pmat.toml,
# .pmat/architecture-exceptions.yaml) and then asserted that the files it had
# just written existed. It never invoked pmat. It passed for a year while all 39
# `pmat architecture ...` examples in the chapter exited with
# `error: unrecognized subcommand`, and the chapter carried a "✅ 100% Working"
# badge on the strength of it.
#
# Every assertion below runs the real binary against a real fixture. If a claim
# in src/ch12-00-architecture.md stops being true, this test goes red.
#
# No cargo toolchain is required — every command exercised here is pmat's own
# AST/git analysis.

set -u

echo "=== Testing Chapter 12: Architecture Analysis ==="

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
# Fixture: the three-module crate printed in the chapter.
#   api -> domain, api -> store, store -> domain, handler() -> load()
# ---------------------------------------------------------------------------
mkdir -p "$TEST_DIR/arch/src/api" "$TEST_DIR/arch/src/domain" "$TEST_DIR/arch/src/store"
cd "$TEST_DIR/arch" || exit 1

cat > Cargo.toml << 'EOF'
[package]
name = "arch"
version = "0.1.0"
edition = "2021"
EOF
cat > src/lib.rs << 'EOF'
pub mod api;
pub mod domain;
pub mod store;
EOF
cat > src/api/mod.rs << 'EOF'
use crate::domain::User;
use crate::store::load;

pub fn handler(id: u32) -> Option<User> {
    load(id)
}
EOF
cat > src/domain/mod.rs << 'EOF'
pub struct User {
    pub id: u32,
    pub name: String,
}

impl User {
    pub fn label(&self) -> String {
        format!("{}#{}", self.name, self.id)
    }
}
EOF
cat > src/store/mod.rs << 'EOF'
use crate::domain::User;

pub fn load(id: u32) -> Option<User> {
    if id == 0 {
        return None;
    }
    Some(User { id, name: "demo".into() })
}
EOF

git init -q .
git -c user.email=book@example.com -c user.name=book add -A
git -c user.email=book@example.com -c user.name=book commit -qm "init" --no-verify
echo "// touched" >> src/store/mod.rs
git -c user.email=book@example.com -c user.name=book add -A
git -c user.email=book@example.com -c user.name=book commit -qm "touch store" --no-verify

# ---------------------------------------------------------------------------
# Test 1: the default full-dependency graph, and its node/edge counts
# ---------------------------------------------------------------------------
echo ""
echo "Test 1: analyze dag (full-dependency)"
DAG_OUT=$("$PMAT_BIN" analyze dag -p . 2>&1)
if echo "$DAG_OUT" | grep -qE "full-dependency: rendered [0-9]+ nodes and [0-9]+ edges"; then
    test_pass "dag reports a node and edge count before the graph"
else
    test_fail "dag no longer reports node/edge counts: $DAG_OUT"
fi

EDGES=$(echo "$DAG_OUT" | sed -nE 's/.*rendered [0-9]+ nodes and ([0-9]+) edges.*/\1/p')
if [ "${EDGES:-0}" -gt 0 ]; then
    test_pass "dag resolved $EDGES edges (a zero-edge graph would mean nothing resolved)"
else
    test_fail "dag resolved 0 edges on a fixture with three real imports"
fi

# The chapter prints these four edges verbatim.
for edge in "src_api_mod -.-> src_domain_mod" \
            "src_api_mod -.-> src_store_mod" \
            "src_store_mod -.-> src_domain_mod" \
            "src_api_mod_handler --> src_store_mod_load"; do
    if echo "$DAG_OUT" | grep -qF "$edge"; then
        test_pass "edge present: $edge"
    else
        test_fail "edge missing from the graph: $edge"
    fi
done

# ---------------------------------------------------------------------------
# Test 2: the four --dag-type values
# ---------------------------------------------------------------------------
echo ""
echo "Test 2: --dag-type"
CALL_OUT=$("$PMAT_BIN" analyze dag -p . --dag-type call-graph 2>&1)
if echo "$CALL_OUT" | grep -qF "src_api_mod_handler --> src_store_mod_load"; then
    test_pass "call-graph contains handler -> load"
else
    test_fail "call-graph lost the only call edge: $CALL_OUT"
fi

IMP_OUT=$("$PMAT_BIN" analyze dag -p . --dag-type import-graph --filter-external 2>&1)
if echo "$IMP_OUT" | grep -qE "filter-external: dropped [0-9]+ external node\(s\) of [0-9]+"; then
    test_pass "--filter-external reports what it dropped"
else
    test_fail "--filter-external no longer reports its effect: $IMP_OUT"
fi

INH_OUT=$("$PMAT_BIN" analyze dag -p . --dag-type inheritance 2>&1)
if echo "$INH_OUT" | grep -q "empty:"; then
    test_pass "an empty inheritance graph explains itself instead of printing a bare graph"
else
    test_fail "empty inheritance graph no longer explains itself: $INH_OUT"
fi

# ---------------------------------------------------------------------------
# Test 3: -o writes Mermaid to a file
# ---------------------------------------------------------------------------
echo ""
echo "Test 3: dag -o"
"$PMAT_BIN" analyze dag -p . --show-complexity -o dag.mmd >/dev/null 2>&1
if [ -f dag.mmd ] && head -1 dag.mmd | grep -q "graph TD"; then
    test_pass "-o wrote a Mermaid document"
else
    test_fail "-o did not write a Mermaid document"
fi

# ---------------------------------------------------------------------------
# Test 4: a dependency cycle is DRAWN but never flagged (chapter's claim)
# ---------------------------------------------------------------------------
echo ""
echo "Test 4: cycles are visible, not detected"
mkdir -p "$TEST_DIR/cyc/src"
(
  cd "$TEST_DIR/cyc" || exit 1
  cat > Cargo.toml << 'EOF'
[package]
name = "cyc"
version = "0.1.0"
edition = "2021"
EOF
  printf 'pub mod a;\npub mod b;\n' > src/lib.rs
  cat > src/a.rs << 'EOF'
use crate::b::from_b;
pub fn from_a() -> i32 { from_b() + 1 }
pub fn seed() -> i32 { 1 }
EOF
  cat > src/b.rs << 'EOF'
use crate::a::seed;
pub fn from_b() -> i32 { seed() + 1 }
EOF
)
CYC_OUT=$(cd "$TEST_DIR/cyc" && "$PMAT_BIN" analyze dag -p . --dag-type import-graph 2>&1)
CYC_RC=$?
if echo "$CYC_OUT" | grep -qF "src_a -.-> src_b" && echo "$CYC_OUT" | grep -qF "src_b -.-> src_a"; then
    test_pass "both directions of the cycle appear in the graph"
else
    test_fail "the cycle is no longer drawn: $CYC_OUT"
fi
if [ "$CYC_RC" -eq 0 ]; then
    test_pass "a cycle does not change the exit code (chapter: cycles are never flagged)"
else
    test_fail "dag now exits $CYC_RC on a cycle — the chapter's claim is stale"
fi

# ---------------------------------------------------------------------------
# Test 5: duplicates, with a denominator
# ---------------------------------------------------------------------------
echo ""
echo "Test 5: analyze duplicates"
DUP_OUT=$("$PMAT_BIN" analyze duplicates -p . 2>&1)
if echo "$DUP_OUT" | grep -qE "Duplication: [0-9.]+% \([0-9]+ / [0-9]+ lines\)"; then
    DUP_TOTAL=$(echo "$DUP_OUT" | sed -nE 's|.*Duplication: [0-9.]+% \([0-9]+ / ([0-9]+) lines\).*|\1|p' | head -1)
    if [ "${DUP_TOTAL:-0}" -gt 0 ]; then
        test_pass "duplicates reports a non-zero denominator ($DUP_TOTAL lines examined)"
    else
        test_fail "duplicates examined 0 lines — a 0% result would be meaningless"
    fi
else
    test_fail "duplicates no longer reports lines examined: $DUP_OUT"
fi

# ---------------------------------------------------------------------------
# Test 6: split reports modularity and reverse dependencies
# ---------------------------------------------------------------------------
echo ""
echo "Test 6: pmat split"
SPLIT_OUT=$("$PMAT_BIN" split src/store/mod.rs 2>&1)
if echo "$SPLIT_OUT" | grep -q "Modularity:"; then
    test_pass "split reports a Louvain modularity score"
else
    test_fail "split no longer reports Modularity: $SPLIT_OUT"
fi
if echo "$SPLIT_OUT" | grep -q "src/api/mod.rs"; then
    test_pass "split's Impact section names the importing file"
else
    test_fail "split no longer reports reverse dependencies: $SPLIT_OUT"
fi

AUTO_OUT=$("$PMAT_BIN" split --auto 2>&1)
if echo "$AUTO_OUT" | grep -qE "Threshold: [0-9]+ lines"; then
    test_pass "split --auto reports the size threshold it used"
else
    test_fail "split --auto changed shape: $AUTO_OUT"
fi

# ---------------------------------------------------------------------------
# Test 7: bottleneck reads git history and reports its denominator
# ---------------------------------------------------------------------------
echo ""
echo "Test 7: analyze bottleneck"
BOT_OUT=$("$PMAT_BIN" analyze bottleneck -p . --period 365 --threshold 1 2>&1)
if echo "$BOT_OUT" | grep -qE "Total commits: [0-9]+"; then
    BOT_COMMITS=$(echo "$BOT_OUT" | sed -nE 's/.*Total commits: ([0-9]+).*/\1/p' | head -1)
    if [ "${BOT_COMMITS:-0}" -gt 0 ]; then
        test_pass "bottleneck read $BOT_COMMITS commit(s) of history"
    else
        test_fail "bottleneck read 0 commits from a repo with 2 — a silent zero"
    fi
else
    test_fail "bottleneck no longer reports its commit denominator: $BOT_OUT"
fi

# ---------------------------------------------------------------------------
# Test 8: graph-metrics — the chapter warns it reports zero edges. Keep that
# warning honest: if this ever starts resolving edges, the chapter is stale.
# ---------------------------------------------------------------------------
echo ""
echo "Test 8: analyze graph-metrics (chapter documents a zero-edge defect)"
GM_OUT=$("$PMAT_BIN" analyze graph-metrics -p . 2>&1)
GM_EDGES=$(echo "$GM_OUT" | sed -nE 's/.*Total edges: ([0-9]+).*/\1/p' | head -1)
if [ "${GM_EDGES:-x}" = "0" ]; then
    test_pass "graph-metrics still reports 0 edges (chapter's warning is current)"
else
    test_fail "graph-metrics now reports $GM_EDGES edges — remove the warning from the chapter"
fi

# ---------------------------------------------------------------------------
# Test 9: the command the OLD chapter documented must stay gone
# ---------------------------------------------------------------------------
echo ""
echo "Test 9: the architecture subcommand remains nonexistent"
if "$PMAT_BIN" architecture --help >/dev/null 2>&1; then
    test_fail "an 'architecture' subcommand now exists — the chapter's banner is stale"
else
    test_pass "no 'architecture' subcommand (banner is still correct)"
fi

echo ""
echo "=== Chapter 12: $PASS_COUNT passed, $FAIL_COUNT failed ==="
[ "$FAIL_COUNT" -eq 0 ] || exit 1
