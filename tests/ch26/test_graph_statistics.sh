#!/bin/bash

# pmat shim: when pmat is absent, fail silently (no "command not found" text
# for greps to match); every caller then takes its SKIPPED arm.
pmat() {
    type -P pmat >/dev/null 2>&1 || return 127
    command pmat "$@"
}

# TDD Test: Chapter 26 - Graph Statistics (`pmat analyze graph-metrics`)
# Every check asserts on real output of the installed pmat and can fail.
#
# Two kinds of check:
#   * behaviour checks on pmat output (exit codes, rejected flags, row counts);
#   * book checks: a line pmat really printed must appear, character for
#     character, in the chapter source. A wrong number in the book is red.
# Every value captured from pmat output and used in a comparison is first
# asserted non-empty and numeric (need_number), so a rejected flag or an empty
# capture can never make a row pass by accident.
#
# Each command runs with the crate root as the working directory (like the
# chapter), so node names are the same as in the book.
# Not asserted: --perf timing values (host-flaky; only the line shape), the
# order of the two functions in `pmat split` output, and --pagerank-seeds
# (pmat accepts it but ignores which node is named; chapter says so).

PASS_COUNT=0
FAIL_COUNT=0
TEST_DIR=$(mktemp -d)
trap 'rm -rf "${TEST_DIR:?}"' EXIT

BOOK="$(dirname "$0")/../../src/ch26-00-graph-statistics.md"

test_skip() {
    echo "⚠️  SKIPPED: $1"
}

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
# need_number <label> <value>: the value must be non-empty and numeric.
need_number() {
    if echo "$2" | grep -qE '^[0-9]+(\.[0-9]+)?$'; then test_pass "$1 is a number ($2)"; else test_fail "$1 is not a number (got: '$2')"; fi
}
# book_row <label> <pmat output> <egrep pattern>: the first output line matching
# the pattern must exist and appear verbatim as a whole line in the chapter.
book_row() {
    local line
    line=$(echo "$2" | grep -E -e "$3" | head -1)
    if [ -z "$line" ]; then test_fail "$1 (pmat printed no line matching: $3)"; return; fi
    if grep -qxF -e "$line" "$BOOKSEC"; then test_pass "$1 [book has: $line]"; else test_fail "$1 (book lacks pmat's line: $line)"; fi
}
# book_text <label> <text>: the chapter must contain this text.
book_text() {
    if [ -z "$2" ]; then test_fail "$1 (empty text)"; return; fi
    if grep -qF -e "$2" "$BOOKSEC"; then test_pass "$1 [book has: $2]"; else test_fail "$1 (book lacks: $2)"; fi
}
# csv_field <csv row> <field number>
csv_field() { echo "$1" | cut -d, -f"$2"; }
# use_section <n>: from now on, book checks look only inside "### Example <n>:"
# of the chapter, so a number changed in one example is not hidden by the same
# line appearing in another example. An empty section is a failure.
BOOKSEC="$BOOK"
use_section() {
    awk -v n="$1" '
        $0 ~ "^### Example " n ":" { on = 1; print; next }
        on && (/^### Example / || /^## Integration with CI/) { exit }
        on { print }' "$BOOK" > "$TEST_DIR/section.md"
    BOOKSEC="$TEST_DIR/section.md"
    if [ -s "$BOOKSEC" ]; then test_pass "chapter section Example $1 found"; else test_fail "chapter section Example $1 is empty or missing"; fi
}

# The five-file crate from the chapter.
mkdir "$TEST_DIR/src"
printf 'pub mod core;\npub mod api;\npub mod utils;\n' > "$TEST_DIR/src/lib.rs"
printf 'use crate::utils;\n' > "$TEST_DIR/src/core.rs"
printf 'use crate::core;\nuse crate::utils;\npub fn handle() {}\npub fn health() {}\n' > "$TEST_DIR/src/api.rs"
: > "$TEST_DIR/src/utils.rs"
printf 'fn main() {}\n' > "$TEST_DIR/src/main.rs"

if [ -f "$BOOK" ]; then test_pass "chapter source found"; else test_fail "chapter source not found at $BOOK"; fi

# Without pmat every check below reads empty output, and empty output passes the
# "no match" and "is a number (0)" checks vacuously. Report one SKIPPED and stop.
if [ -z "$(type -P pmat)" ]; then
    test_skip "pmat not on PATH: graph-metrics, context and split checks not run"
    echo ""
    echo "=== Test Summary ==="
    echo "Passed: $PASS_COUNT"
    echo "Failed: $FAIL_COUNT"
    [ "$FAIL_COUNT" -eq 0 ] && exit 0
    exit 1
fi

# gm <args>: run graph-metrics in the crate root; print output then a final "rc=N" line.
gm() {
    local out rc
    out=$(cd "$TEST_DIR" && timeout 60 pmat analyze graph-metrics "$@" 2>&1)
    rc=$?
    printf '%s\nrc=%s\n' "$out" "$rc"
}

echo "Testing the default summary (Example 2)..."
use_section 2
OUT=$(gm)
expect_match "default run exits 0" "$OUT" '^rc=0$'
expect_nomatch "summary has no per-node table" "$OUT" 'degree_centrality'
DEFAULT_NODES=$(echo "$OUT" | sed -n 's/.*Built graph with \([0-9]*\) nodes.*/\1/p' | head -1)
need_number "default node count" "$DEFAULT_NODES"
for stat in 'Built graph with [0-9]+ nodes and [0-9]+ edges' '  Total nodes: [0-9]+' '  Total edges: [0-9]+' \
            '  Density: [0-9.]+' '  Average degree: [0-9.]+' '  Max degree: [0-9]+' '  Connected components: [0-9]+'; do
    book_row "summary line '$stat'" "$OUT" "^[✅ ]*$stat\$"
done
book_text "book says the graph has 3 edges" "Built graph with $DEFAULT_NODES nodes and 3 edges"

echo "Testing page-rank only (Examples 3, 5)..."
use_section 7
OUT=$(gm --metrics page-rank --format csv)
expect_match "csv header" "$OUT" '^name,degree_centrality,betweenness,closeness,pagerank,clustering,component_id,in_degree,out_degree$'
expect_match "page-rank csv leaves betweenness/closeness empty" "$OUT" '^src_utils,[0-9.]+,,,[0-9.]+,,,[0-9]+,[0-9]+$'
FIRST=$(echo "$OUT" | grep -E '^src_[a-z]+,' | head -1)
expect_match "highest PageRank node is utils" "$FIRST" '^src_utils,'
for node in src_utils src_core src_api; do
    book_row "page-rank csv row $node is in the book (Example 7 table values)" "$OUT" "^$node,"
done
use_section 3
OUT=$(gm --metrics page-rank --format detailed)
expect_match "detailed run exits 0" "$OUT" '^rc=0$'
expect_match "detailed: unrequested metric is n/a" "$OUT" 'Betweenness: n/a'
for field in '     Degree: [0-9.]+ \(in: [0-9]+, out: [0-9]+\)' '     PageRank: [0-9.]+'; do
    book_row "detailed block line '$field'" "$OUT" "^$field\$"
done
for node in src_utils src_core src_api; do
    book_row "detailed ranking line for $node" "$OUT" "^  [0-9]+\. $node [0-9.]+\$"
done
use_section 5
OUT=$(gm --metrics page-rank --format json)
expect_match "json: unrequested metric is null" "$OUT" '"betweenness_centrality": null'
for node in src_utils src_core src_api; do
    PR=$(echo "$OUT" | grep -A5 "\"name\": \"$node\"" | sed -n 's/.*"pagerank": \([0-9.]*\),.*/\1/p' | head -1)
    need_number "json pagerank of $node" "$PR"
    book_text "book has the json pagerank of $node (first 6 chars)" "\"pagerank\": $(echo "$PR" | cut -c1-6)"
done
for key in total_nodes total_edges max_degree connected_components; do
    book_row "json $key" "$OUT" "^  \"$key\": [0-9]+,?\$"
done
for key in density average_degree; do
    V=$(echo "$OUT" | sed -n "s/^  \"$key\": \([0-9.]*\),\$/\1/p")
    need_number "json $key" "$V"
    book_text "book has json $key (first 6 chars)" "\"$key\": $(echo "$V" | cut -c1-6)"
done

echo "Testing all metrics (Example 4, 5)..."
use_section 5
OUT=$(gm --metrics all --format csv)
expect_match "all metrics fills every column" "$OUT" '^src_api,[0-9.]+,[0-9.]+,[0-9.]+,[0-9.]+,[0-9.]+,[0-9]+,[0-9]+,[0-9]+$'
for node in src_api src_core src_utils; do
    book_row "all-metrics csv row $node" "$OUT" "^$node,"
done
use_section 4
OUT=$(gm --metrics all --format detailed)
expect_match "all-metrics detailed run exits 0" "$OUT" '^rc=0$'
for field in '     Closeness: [0-9.]+' '     Clustering: [0-9.]+' '     Component: [0-9]+' '     Betweenness: [0-9.]+'; do
    book_row "all-metrics detailed line '$field'" "$OUT" "^$field\$"
done
use_section 5
OUT=$(gm --format markdown)
expect_match "markdown report heading" "$OUT" '^# Graph Metrics Report$'
for node in src_api src_core src_utils; do
    book_row "markdown row $node" "$OUT" "^\| $node \|"
done
for metric in 'Total Nodes' 'Total Edges' 'Density' 'Average Degree' 'Max Degree' 'Connected Components'; do
    book_row "markdown summary '$metric'" "$OUT" "^\| $metric \| [0-9.]+ \|\$"
done
NROWS=$(echo "$OUT" | grep -cE '^\| src_')
if [ "$NROWS" -eq 3 ]; then test_pass "per-node table has 3 rows for $DEFAULT_NODES nodes"; else test_fail "per-node table has 3 rows (got $NROWS)"; fi

echo "Testing PageRank tuning (Example 7)..."
use_section 7
BASE=$(gm --metrics page-rank --format csv | grep '^src_utils,')
LOW=$(gm --metrics page-rank --damping-factor 0.5 --format csv | grep '^src_utils,')
BASE_PR=$(csv_field "$BASE" 5)
LOW_PR=$(csv_field "$LOW" 5)
need_number "default pagerank of src_utils" "$BASE_PR"
need_number "damping 0.5 pagerank of src_utils" "$LOW_PR"
if [ "$BASE_PR" != "$LOW_PR" ]; then test_pass "damping 0.5 changes the scores ($BASE_PR -> $LOW_PR)"; else test_fail "damping 0.5 changes the scores"; fi
OUT=$(gm --metrics page-rank --damping-factor 0.5 --format csv)
for node in src_utils src_core src_api; do
    ROW=$(echo "$OUT" | grep "^$node,")
    PR=$(csv_field "$ROW" 5)
    need_number "damping 0.5 pagerank of $node" "$PR"
    book_text "book table has damping 0.5 value of $node" "| $node | $(gm --metrics page-rank --format csv | grep "^$node," | cut -d, -f5) | $PR |"
done
OUT=$(gm --metrics page-rank --max-iterations 200 --convergence-threshold 0.00000001 --format csv)
expect_match "max-iterations/convergence-threshold run" "$OUT" '^rc=0$'
for node in src_utils src_core src_api; do
    book_row "max-iterations csv row $node" "$OUT" "^$node,"
done

echo "Testing scoping (Example 8)..."
use_section 8
OUT=$(gm --top-k 2 --format csv)
ROWS=$(echo "$OUT" | grep -cE '^src_[a-z]+,')
need_number "--top-k row count" "$ROWS"
if [ "$ROWS" -eq 2 ]; then test_pass "--top-k 2 prints two rows"; else test_fail "--top-k 2 prints two rows (got $ROWS)"; fi
OUT=$(gm --min-centrality 0.5 --format csv)
expect_match "--min-centrality 0.5 run exits 0" "$OUT" '^rc=0$'
ROWS=$(echo "$OUT" | grep -cE '^src_[a-z]+,')
need_number "--min-centrality 0.5 row count" "$ROWS"
if [ "$ROWS" -eq 0 ]; then test_pass "--min-centrality 0.5 prints no rows"; else test_fail "--min-centrality 0.5 prints no rows (got $ROWS)"; fi
OUT=$(gm --min-centrality 0.2 --format csv)
ROWS=$(echo "$OUT" | grep -cE '^src_[a-z]+,')
need_number "--min-centrality 0.2 row count" "$ROWS"
if [ "$ROWS" -eq 3 ]; then test_pass "--min-centrality 0.2 prints three rows"; else test_fail "--min-centrality 0.2 prints three rows (got $ROWS)"; fi
OUT=$(gm --include src --exclude main)
EXC_NODES=$(echo "$OUT" | sed -n 's/.*Built graph with \([0-9]*\) nodes.*/\1/p' | head -1)
need_number "--exclude main node count" "$EXC_NODES"
if [ "$EXC_NODES" -lt "$DEFAULT_NODES" ]; then
    test_pass "--exclude main removes nodes ($DEFAULT_NODES -> $EXC_NODES)"
else
    test_fail "--exclude main removes nodes (default=$DEFAULT_NODES exclude=$EXC_NODES)"
fi
book_row "--exclude main node line" "$OUT" '^✅ Built graph with [0-9]+ nodes and [0-9]+ edges$'
OUT=$(gm --include 'src/**/*.rs')
expect_match "glob --include finds nothing" "$OUT" 'Built graph with 0 nodes and 0 edges'
expect_match "glob --include fails loudly (exit 5)" "$OUT" '^rc=5$'
book_row "glob --include error line" "$OUT" '^Error: no source files were found'
OUT=$(gm --metrics page-rank --perf)
expect_match "--perf prints a timing line" "$OUT" 'perf: analyze graph-metrics completed in [0-9.]+ ms'
book_text "book shows the --perf line" "perf: analyze graph-metrics completed in"

echo "Testing GraphML export (Example 6)..."
use_section 6
OUT=$(gm --export-graphml -o g.graphml)
expect_match "export reports the file" "$OUT" 'Results written to: .*g\.graphml'
GML=$(cat "$TEST_DIR/g.graphml" 2>/dev/null)
expect_match "graphml has a label key" "$GML" 'attr.name="label"'
expect_nomatch "graphml carries no scores" "$GML" 'pagerank|community|complexity'
EDGES=$(echo "$GML" | grep -c '<edge ')
GML_NODES=$(echo "$GML" | grep -c '<node ')
BOOK_NODES=$(grep -c '<node id=' "$BOOKSEC")
need_number "graphml edge count" "$EDGES"
need_number "graphml node count" "$GML_NODES"
if [ "$EDGES" -eq 3 ]; then test_pass "graphml has 3 edges"; else test_fail "graphml has 3 edges (got $EDGES)"; fi
if [ "$GML_NODES" -eq "$BOOK_NODES" ]; then test_pass "graphml node count matches the book ($GML_NODES)"; else test_fail "graphml has $GML_NODES nodes, book shows $BOOK_NODES"; fi
while IFS= read -r line; do
    book_text "graphml line is in the book" "$line"
done < <(echo "$GML" | grep -E '<node |<edge ')
gm -o "$TEST_DIR/graph_export" > /dev/null
if [ -f "$TEST_DIR/graph_export" ] && [ ! -f "$TEST_DIR/graph_export.graphml" ]; then
    test_pass "-o without extension writes that exact filename"
else
    test_fail "-o without extension writes that exact filename"
fi

echo "Testing pmat context (Example 1)..."
use_section 1
CTX_OUT=$(cd "$TEST_DIR" && timeout 120 pmat context --output deep_analysis.md 2>&1; echo "rc=$?")
expect_match "pmat context exits 0" "$CTX_OUT" 'rc=0$'
CTX=$(cat "$TEST_DIR/deep_analysis.md" 2>/dev/null)
book_row "context total files" "$CTX" '^- \*\*Total Files\*\*: [0-9]+$'
book_row "context total functions" "$CTX" '^- \*\*Total Functions\*\*: [0-9]+$'
book_row "context api.rs function count" "$CTX" '^\*\*File Complexity\*\*: [0-9]+ \| \*\*Functions\*\*: 2$'
expect_nomatch "context has no PageRank" "$CTX" '[Pp]age[Rr]ank'

echo "Testing pmat split (Example 9)..."
use_section 9
SPLIT=$(cd "$TEST_DIR" && timeout 60 pmat split src/api.rs 2>&1; echo "rc=$?")
expect_match "pmat split exits 0" "$SPLIT" 'rc=0$'
for field in 'Computing annotations for [0-9]+ functions\.\.\.' 'Total lines: ~[0-9]+' 'Modularity: [0-9.]+' 'Clusters: [0-9]+' \
             'Unclustered items: [0-9]+' '  Function handle \(L[0-9]+-L[0-9]+\)' '  Function health \(L[0-9]+-L[0-9]+\)'; do
    book_row "split line '$field'" "$SPLIT" "^$field\$"
done

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
    expect_match "$flag is rejected with exit 2" "$OUT" '^rc=2$'
done
OUT=$(cd "$TEST_DIR" && timeout 30 pmat analyze graph-trends 2>&1)
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
