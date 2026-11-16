#!/bin/bash
# TDD Test: Chapter 26 - Graph Statistics (`pmat analyze graph-metrics`)
# Every check asserts on real output of the installed pmat and can fail.
# No path to a pmat source checkout is used. Node names carry the temp path
# and node/density counts differ between pmat versions, so those are not asserted.
# Not asserted (host-flaky): `pmat context` (slow, scans the whole tree) and
# timings from --perf. Not asserted (book/pmat mismatch, ticketed): node count
# 5, --pagerank-seeds changing scores, --min-centrality 0.5 keeping one row.

PASS_COUNT=0
FAIL_COUNT=0
TEST_DIR=$(mktemp -d)
trap 'rm -rf "${TEST_DIR:?}"' EXIT

test_pass() { echo "✅ PASS: $1"; PASS_COUNT=$((PASS_COUNT + 1)); }
test_fail() { echo "❌ FAIL: $1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

# expect_match <label> <text> <egrep pattern>
expect_match() {
    if echo "$2" | grep -qE -e "$3"; then test_pass "$1"; else test_fail "$1 (no match for: $3)"; fi
}
# expect_nomatch <label> <text> <egrep pattern>
expect_nomatch() {
    if echo "$2" | grep -qE -e "$3"; then test_fail "$1 (unexpected match: $3)"; else test_pass "$1"; fi
}

# The five-file crate from the chapter.
mkdir "$TEST_DIR/src"
printf 'pub mod core;\npub mod api;\npub mod utils;\n' > "$TEST_DIR/src/lib.rs"
printf 'use crate::utils;\n' > "$TEST_DIR/src/core.rs"
printf 'use crate::core;\nuse crate::utils;\n' > "$TEST_DIR/src/api.rs"
: > "$TEST_DIR/src/utils.rs"
printf 'fn main() {}\n' > "$TEST_DIR/src/main.rs"

# gm <args>: run graph-metrics; print output then a final "rc=N" line.
gm() {
    local out rc
    out=$(timeout 60 pmat analyze graph-metrics -p "$TEST_DIR" "$@" 2>&1)
    rc=$?
    printf '%s\nrc=%s\n' "$out" "$rc"
}

echo "Testing the default summary..."
OUT=$(gm)
expect_match "default run exits 0" "$OUT" '^rc=0$'
expect_match "summary reports 3 edges" "$OUT" 'Built graph with [0-9]+ nodes and 3 edges'
expect_match "summary has Total edges: 3" "$OUT" 'Total edges: 3'
expect_nomatch "summary has no per-node table" "$OUT" 'degree_centrality'
DEFAULT_NODES=$(echo "$OUT" | sed -n 's/.*Built graph with \([0-9]*\) nodes.*/\1/p' | head -1)

echo "Testing page-rank only (unrequested metrics are not computed)..."
OUT=$(gm --metrics page-rank --format csv)
expect_match "csv header" "$OUT" '^name,degree_centrality,betweenness,closeness,pagerank,clustering,component_id,in_degree,out_degree$'
expect_match "page-rank csv leaves betweenness/closeness empty" "$OUT" '_src_utils,[0-9.]+,,,[0-9.]+,,,[0-9]+,[0-9]+$'
FIRST=$(echo "$OUT" | grep -E '^[^,]+_src_[a-z]+,' | head -1)
expect_match "highest PageRank node is utils" "$FIRST" '_src_utils,'
OUT=$(gm --metrics page-rank --format json)
expect_match "json: unrequested metric is null" "$OUT" '"betweenness_centrality": null'
expect_match "json: requested metric is a number" "$OUT" '"pagerank": [0-9.]+'

echo "Testing all metrics..."
OUT=$(gm --metrics all --format csv)
expect_match "all metrics fills every column" "$OUT" '_src_api,[0-9.]+,[0-9.]+,[0-9.]+,[0-9.]+,[0-9.]+,[0-9]+,[0-9]+,[0-9]+$'
OUT=$(gm --format markdown)
expect_match "markdown report heading" "$OUT" '^# Graph Metrics Report$'

echo "Testing PageRank tuning..."
BASE=$(gm --metrics page-rank --format csv | grep '_src_utils,')
LOW=$(gm --metrics page-rank ${DAMPING_FLAG:---damping-factor} 0.5 --format csv | grep '_src_utils,')
if [ -n "$BASE" ] && [ -n "$LOW" ] && [ "$BASE" != "$LOW" ]; then test_pass "damping 0.5 changes the scores"; else test_fail "damping 0.5 changes the scores"; fi
OUT=$(gm --metrics page-rank --max-iterations 200 --convergence-threshold 0.00000001 --format csv)
expect_match "max-iterations/convergence-threshold run" "$OUT" '^rc=0$'

echo "Testing scoping..."
OUT=$(gm --top-k 2 --format csv)
ROWS=$(echo "$OUT" | grep -cE '^[^,]+_src_[a-z]+,')
if [ "$ROWS" -eq 2 ]; then test_pass "--top-k 2 prints two rows"; else test_fail "--top-k 2 prints two rows (got $ROWS)"; fi
OUT=$(gm --include src --exclude main)
EXC_NODES=$(echo "$OUT" | sed -n 's/.*Built graph with \([0-9]*\) nodes.*/\1/p' | head -1)
if [ -n "$EXC_NODES" ] && [ -n "$DEFAULT_NODES" ] && [ "$EXC_NODES" -lt "$DEFAULT_NODES" ]; then
    test_pass "--exclude main removes nodes ($DEFAULT_NODES -> $EXC_NODES)"
else
    test_fail "--exclude main removes nodes (default=$DEFAULT_NODES exclude=$EXC_NODES)"
fi
OUT=$(gm --include 'src/**/*.rs')
expect_match "glob --include finds nothing" "$OUT" 'Built graph with 0 nodes and 0 edges'
expect_match "glob --include fails loudly (exit 5)" "$OUT" '^rc=5$'

echo "Testing GraphML export..."
OUT=$(gm --export-graphml -o "$TEST_DIR/g.graphml")
expect_match "export reports the file" "$OUT" 'Results written to: .*g\.graphml'
GML=$(cat "$TEST_DIR/g.graphml" 2>/dev/null)
expect_match "graphml has a label key" "$GML" 'attr.name="label"'
expect_nomatch "graphml carries no scores" "$GML" 'pagerank|community|complexity'
EDGES=$(echo "$GML" | grep -c '<edge ')
if [ "$EDGES" -eq 3 ]; then test_pass "graphml has 3 edges"; else test_fail "graphml has 3 edges (got $EDGES)"; fi
gm -o "$TEST_DIR/graph_export" > /dev/null
if [ -f "$TEST_DIR/graph_export" ] && [ ! -f "$TEST_DIR/graph_export.graphml" ]; then
    test_pass "-o without extension writes that exact filename"
else
    test_fail "-o without extension writes that exact filename"
fi

echo "Testing things the chapter says do not exist (must be rejected)..."
OUT=$(gm --metrics pagerank)
expect_match "--metrics pagerank is rejected (exit 2)" "$OUT" '^rc=2$'
expect_match "rejection suggests page-rank" "$OUT" "similar value exists: 'page-rank'"
OUT=$(gm --metrics community)
expect_match "--metrics community is rejected" "$OUT" "invalid value 'community'"
for flag in --pagerank-damping --community-resolution --quality-assessment --hotspot-detection \
            --parallel --cache-enabled --incremental --sample-ratio --memory-limit; do
    OUT=$(gm "$flag")
    expect_match "$flag is rejected" "$OUT" "unexpected argument '$flag'"
done
OUT=$(timeout 30 pmat analyze graph-trends -p "$TEST_DIR" 2>&1)
expect_match "pmat analyze graph-trends does not exist" "$OUT" "unrecognized subcommand 'graph-trends'"

echo ""
echo "=== Test Summary ==="
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"
if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "✅ All graph statistics tests passed!"
    exit 0
fi
echo "❌ Some tests failed"
exit 1
