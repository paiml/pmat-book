#!/bin/sh
# Every "Chapter N:" entry in SUMMARY.md must land on a page whose first H1
# says "Chapter N:" too (paiml/pmat-book#5). Six once disagreed: a reader
# clicked "Chapter 27: QDD" and arrived at "Chapter 14: QDD".
#
# A section page ("Chapter 4.1:") belongs to its chapter, 4. An entry whose
# page is missing or whose H1 carries no number is printed and counted as
# not comparable, never passed silently.
#
# Usage: scripts/check-chapter-numbers.sh [src-dir]   (default: src)
# Exit 0: all agree. 1: a mismatch. 2: nothing was compared, which is a
# broken check, not a pass.
set -eu

src="${1:-src}"
summary="$src/SUMMARY.md"
[ -f "$summary" ] || { echo "check-chapter-numbers: no $summary" >&2; exit 2; }

compared=0
bad=0
skipped=0
entries=$(sed -n 's/^[[:space:]]*- \[Chapter \([0-9][0-9]*\):[^]]*\](\([^)]*\)).*/\1 \2/p' "$summary")

# The here-document keeps the loop in this shell, so the counters survive it.
while read -r want path; do
    [ -n "$path" ] || continue
    page="$src/$path"
    if [ ! -f "$page" ]; then
        skipped=$((skipped + 1))
        printf '%s: not compared, the file does not exist\n' "$path"
        continue
    fi
    # The first H1 outside a fenced code block.
    h1=$(awk '/^[[:space:]]*```/ { f = !f; next } !f && /^# / { print; exit }' "$page")
    got=$(printf '%s\n' "$h1" | sed -n 's/^# Chapter \([0-9][0-9]*\)[.0-9]*:.*/\1/p')
    if [ -z "$got" ]; then
        skipped=$((skipped + 1))
        printf '%s: not compared, its H1 has no chapter number: "%s"\n' "$path" "$h1"
        continue
    fi
    compared=$((compared + 1))
    if [ "$got" != "$want" ]; then
        bad=$((bad + 1))
        printf '%s: SUMMARY says Chapter %s, the page says "%s"\n' "$path" "$want" "$h1"
    fi
done <<EOF
$entries
EOF

echo "check-chapter-numbers: $compared compared, $bad disagree, $skipped not comparable"
[ "$compared" -gt 0 ] || exit 2
[ "$bad" -eq 0 ]
