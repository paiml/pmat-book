#!/usr/bin/env bash
# Every page in src/ must be listed in src/SUMMARY.md, and every SUMMARY.md
# target must exist. mdBook renders only listed pages (create-missing = false),
# so an unlisted file produces no HTML and 404s on the published book (#3).
#
# KNOWN_ORPHANS is a debt ledger, not an allowlist to grow: each entry names the
# issue that removes it. The test also fails when a ledgered file is gone or has
# been registered, so a fixed entry cannot linger.
set -euo pipefail

cd "$(dirname "$0")/../.."

KNOWN_ORPHANS=(
    "ch01-02-first-analysis.md"  # #8: superseded by ch01-02-first-analysis-tdd.md, to be removed
)

WORK_DIR=$(mktemp -d)
trap 'rm -rf "${WORK_DIR:?}"' EXIT

find src -maxdepth 1 -name '*.md' ! -name SUMMARY.md -printf '%f\n' | sort > "$WORK_DIR/files"
grep -oE '\]\([^)]+\.md\)' src/SUMMARY.md | sed 's/^](//; s/)$//' | sort -u > "$WORK_DIR/summary"
printf '%s\n' "${KNOWN_ORPHANS[@]}" | sort > "$WORK_DIR/known"

fail=0
pages=$(wc -l < "$WORK_DIR/files")
listed=$(wc -l < "$WORK_DIR/summary")
echo "checked $pages page(s) in src/ against $listed SUMMARY.md target(s)"
if [ "$pages" -eq 0 ] || [ "$listed" -eq 0 ]; then
    echo "FAIL: nothing to compare (pages=$pages, targets=$listed)"
    exit 1
fi

while read -r f; do
    echo "FAIL: src/$f is not listed in src/SUMMARY.md, so it renders no HTML"
    fail=1
done < <(comm -23 "$WORK_DIR/files" "$WORK_DIR/summary" | comm -23 - "$WORK_DIR/known")

while read -r f; do
    echo "FAIL: src/SUMMARY.md lists $f, which does not exist"
    fail=1
done < <(comm -13 "$WORK_DIR/files" "$WORK_DIR/summary")

while read -r f; do
    if [ ! -f "src/$f" ]; then
        echo "FAIL: KNOWN_ORPHANS lists $f, which no longer exists: delete its ledger line"
        fail=1
    elif grep -qxF "$f" "$WORK_DIR/summary"; then
        echo "FAIL: KNOWN_ORPHANS lists $f, which SUMMARY.md now registers: delete its ledger line"
        fail=1
    fi
done < "$WORK_DIR/known"

[ "$fail" -eq 0 ] && echo "PASS: no unlisted pages, no missing targets"
exit "$fail"
