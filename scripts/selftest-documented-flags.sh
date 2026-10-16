#!/usr/bin/env bash
# Does the flag gate actually fail?
#
# A gate nobody has watched fail is a gate nobody has tested. This project has
# already shipped one: eight chapter tests that ran in MOCK_MODE whenever pmat
# was on PATH — 88 assertions, green, measuring nothing. The gate was not
# broken in some subtle way. It simply could not go red, and no one had checked.
#
# So this asserts the property directly, by NAMED MUTATION. It copies the whole
# book into a throwaway directory, measures the pristine count, then plants one
# defect at a time and demands that verify-documented-flags.sh:
#
#   1. exits non-zero, and
#   2. prints the planted command, so a human is told WHAT broke, not just that
#      the number moved.
#
# THE CONTROL IS THE POINT
#
# Mutations alone would be satisfied by a gate that fails on everything, which
# is just as useless as one that fails on nothing. The last case plants a
# command that is CORRECT and demands the gate stay GREEN. Without that, this
# script would certify a `exit 1` one-liner.
#
# Every case restores the chapter and re-measures, so a mutation that failed to
# clean up cannot be mistaken for the next one's signal.

set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || { echo "FAIL: cannot cd to the book root" >&2; exit 2; }

GATE="scripts/verify-documented-flags.sh"
PMAT="${PMAT:-pmat}"
command -v "$PMAT" >/dev/null 2>&1 || {
    echo "FAIL: '$PMAT' is not on PATH. This self-test cannot run without the" >&2
    echo "  tool the gate probes, and a skip here would certify nothing." >&2
    exit 2
}

WORK=$(mktemp -d "${TMPDIR:-/tmp}/pmat-book-selftest.XXXXXXXX") || exit 2
trap 'rm -rf "$WORK"' EXIT INT TERM

SRC="$WORK/src"
BASE="$WORK/baseline"
LOG="$WORK/gate.log"
cp -R src "$SRC"

# The chapter the mutations are planted in. A copy, never the checkout.
VICTIM="$SRC/ch05-00-analyze-suite.md"
[ -f "$VICTIM" ] || { echo "FAIL: no $VICTIM to mutate." >&2; exit 2; }
cp "$VICTIM" "$WORK/victim.pristine"

# --compare-to points at the pristine copy, so the gate reports only what the
# mutation ADDED — the same path CI takes, where the comparison tree is derived
# from git HEAD. Exercising the real naming path is the point; a self-test that
# only ever hits the fallback would not test what CI runs.
PRISTINE_TREE="$WORK/pristine-src"
cp -R src "$PRISTINE_TREE"
run_gate() {
    bash "$GATE" --src "$SRC" --baseline "$BASE" --compare-to "$PRISTINE_TREE" \
                 --jobs "${JOBS:-8}" > "$LOG" 2>&1
}

# A planted command that the book ALREADY prints proves nothing: the gate
# deduplicates by command text, so the count does not move and the case passes
# green whatever the gate does. The first draft of this script had two such
# cases and reported 4/5 — one of the survivors was the CONTROL, which would
# have certified a gate that could not fail at all. Assert uniqueness instead of
# hoping for it.
assert_absent() {
    local cmd="$1" hits
    # Counted with awk, not `grep -c`: grep -c PRINTS 0 and EXITS 1 when there
    # are no matches, and under `set -o pipefail` that turns "the command is
    # absent" — the case we WANT — into a failed pipeline.
    hits=$(bash "$GATE" --src "$SRC" --list 2>/dev/null | awk -v c="$cmd" '$0 == c { n++ } END { print n + 0 }')
    if [ "${hits:-0}" -ne 0 ]; then
        echo "FAIL: '$cmd' already appears in the book, so planting it is a no-op" >&2
        echo "  after deduplication. This case would pass vacuously. Pick a" >&2
        echo "  command the book does not already contain." >&2
        exit 1
    fi
}

plant() {
    cp "$WORK/victim.pristine" "$VICTIM"
    # shellcheck disable=SC2016  # the backticks are a markdown fence, not a
    # command substitution; the format string must stay literal.
    printf '\n## Planted by selftest-documented-flags.sh\n\n```bash\n%s\n```\n' "$1" >> "$VICTIM"
}
restore() { cp "$WORK/victim.pristine" "$VICTIM"; }

# ------------------------------------------------------- pristine measurement
restore
run_gate; status=$?
if [ "$status" -ne 2 ]; then
    echo "FAIL: expected exit 2 (no baseline yet), got $status." >&2; cat "$LOG" >&2; exit 1
fi
PRISTINE=$(awk -F'PARSE_FAILURES=' '/^PARSE_FAILURES=/ { split($2, a, " "); print a[1] }' "$LOG")
[ -n "$PRISTINE" ] || { echo "FAIL: could not read the pristine count." >&2; cat "$LOG" >&2; exit 1; }
echo "$PRISTINE" > "$BASE"
echo "pristine copy of the book: $PRISTINE parse failure(s) — that is the scratch baseline"

run_gate; status=$?
if [ "$status" -ne 0 ]; then
    echo "FAIL: the pristine copy is not green at its own baseline (exit $status)." >&2
    cat "$LOG" >&2; exit 1
fi
echo "  control A: unmutated copy is GREEN"

# --------------------------------------------------------------- the mutations
fails=0

expect_red() {
    local label="$1" cmd="$2"
    assert_absent "$cmd"
    plant "$cmd"
    run_gate; local st=$?
    restore
    if [ "$st" -eq 0 ]; then
        echo "  MUTATION SURVIVED [$label]: gate stayed green after planting: $cmd" >&2
        fails=$((fails + 1)); return
    fi
    if ! grep -qF -- "$cmd" "$LOG"; then
        echo "  MUTATION UNNAMED [$label]: gate went red (exit $st) but never printed: $cmd" >&2
        echo "    A count that moves without naming the cause makes the reader" >&2
        echo "    re-do the whole audit by hand." >&2
        fails=$((fails + 1)); return
    fi
    echo "  killed [$label]: exit $st, and the gate named it"
}

expect_green() {
    local label="$1" cmd="$2"
    assert_absent "$cmd"
    plant "$cmd"
    run_gate; local st=$?
    restore
    if [ "$st" -ne 0 ]; then
        echo "  FALSE POSITIVE [$label]: a VALID command turned the gate red (exit $st): $cmd" >&2
        sed -n '1,20p' "$LOG" >&2
        fails=$((fails + 1)); return
    fi
    echo "  control B [$label]: a valid command keeps the gate GREEN"
}

# One per class the classifier distinguishes, so a regression in any single
# branch of it is caught rather than masked by the others.
expect_red  "unknown-flag"          "pmat analyze complexity --path . --bogus-flag"
expect_red  "renamed-enum-value"    "pmat analyze graph-metrics --metrics pagerank"
expect_red  "positional-not-flag"   "pmat analyze tdg ./selftest-planted-path"
expect_red  "nonexistent-subcmd"    "pmat architecture --detect-patterns"

# The control. If this one goes red, every result above is meaningless.
expect_green "valid-command"        "pmat analyze complexity --path . --top-files 7 --format json"

echo
if [ "$fails" -ne 0 ]; then
    echo "FAIL: $fails of 5 mutation case(s) did not behave as required." >&2
    echo "  The flag gate cannot be trusted until every one of them does." >&2
    exit 1
fi
echo "PASS: 4 planted defects killed, 1 valid command left alone."
