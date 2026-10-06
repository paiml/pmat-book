#!/usr/bin/env bash
# Issue #6: a chapter test script that no make target names can never fail.
#
# Every tests/chNN/*.sh must be EITHER run by a test-chNN recipe OR listed in
# tests/chapter-scripts-not-in-make-test.txt with a reason, never both and
# never neither. A ledger line whose script is gone fails too, so the ledger
# cannot go stale. Every test-chNN target must be a prerequisite of
# test-all-chapters (test-ch19..21 were defined and never run), and every
# prerequisite must be defined.
#
# It prints how many scripts it scanned and refuses to pass below a floor:
# "0 unwired" over 0 scripts would mean the scan is broken, not the repo clean.
set -euo pipefail

ROOT=${1:-$(cd "$(dirname "$0")/../.." && pwd)}
MIN_SCRIPTS=${MIN_SCRIPTS:-50}
MK=$ROOT/Makefile
LEDGER=$ROOT/tests/chapter-scripts-not-in-make-test.txt

fail=0
bad() { echo "FAIL: $*"; fail=$((fail + 1)); }

scripts=$(find "$ROOT/tests" -path "$ROOT/tests/ch*" -name "*.sh" -type f | sed "s|^$ROOT/||" | LC_ALL=C sort)
# Only recipe lines of test-chNN targets count: a path in a comment, an echo
# in help, or a target nothing runs would otherwise pass as "wired".
named=$(awk '
    /^[^\t#][^:=]*:/ { split($0, a, ":"); tgt = a[1] }
    /^\t/ && tgt ~ /^test-ch[0-9]+$/ && $0 !~ /^\t[[:space:]]*#/ {
        line = $0
        while (match(line, /tests\/ch[0-9]+\/[A-Za-z0-9_]+\.sh/)) {
            print substr(line, RSTART, RLENGTH)
            line = substr(line, RSTART + RLENGTH)
        }
    }
' "$MK" | LC_ALL=C sort -u)
listed=$({ [ ! -f "$LEDGER" ] || grep -oE '^tests/ch[0-9]+/[A-Za-z0-9_]+\.sh' "$LEDGER" || true; } | LC_ALL=C sort)

n=0
for s in $scripts; do
    n=$((n + 1))
    in_mk=0; in_ledger=0
    if grep -qxF "$s" <<<"$named"; then in_mk=1; fi
    if grep -qxF "$s" <<<"$listed"; then in_ledger=1; fi
    if [ "$in_mk$in_ledger" = 00 ]; then bad "$s is named by no make target and not in the ledger"; fi
    if [ "$in_mk$in_ledger" = 11 ]; then bad "$s is in the Makefile AND the ledger; delete its ledger line"; fi
done

for s in $listed; do
    [ -f "$ROOT/$s" ] || bad "ledger line for $s, which does not exist"
done
dups=$(uniq -d <<<"$listed")
[ -z "$dups" ] || bad "ledger lists twice: $dups"

for s in $named; do
    [ -f "$ROOT/$s" ] || bad "Makefile names $s, which does not exist"
done

defined=$({ grep -oE '^test-ch[0-9]+:' "$MK" || true; } | tr -d ':' | LC_ALL=C sort)
aggregate=$({ grep -E '^test-all-chapters:' "$MK" || true; } | cut -d: -f2 | tr ' ' '\n' | { grep -E '^test-ch' || true; } | LC_ALL=C sort)
[ -n "$aggregate" ] || bad "no test-all-chapters prerequisites found"
for t in $defined; do
    grep -qxF "$t" <<<"$aggregate" || bad "$t is defined but not run by test-all-chapters"
done
for t in $aggregate; do
    grep -qxF "$t" <<<"$defined" || bad "test-all-chapters needs $t, which is not defined"
done
# make test is what CI and contributors run; the aggregate is only wired if it reaches it.
testdeps=$({ grep -E '^test:' "$MK" || true; } | cut -d: -f2)
for t in test-chapter-wiring test-all-chapters; do
    grep -qw -- "$t" <<<"$testdeps" || bad "make test does not depend on $t"
done

echo "scanned $n chapter script(s): $(wc -w <<<"$named") named by make, $(wc -w <<<"$listed") in the ledger; $(wc -w <<<"$defined") test-chNN target(s); $fail failure(s)"
if [ "$n" -lt "$MIN_SCRIPTS" ]; then
    echo "UNMEASURED: fewer than $MIN_SCRIPTS scripts scanned; the scan is broken"
    exit 1
fi
[ "$fail" -eq 0 ]
