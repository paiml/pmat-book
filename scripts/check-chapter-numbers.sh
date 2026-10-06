#!/bin/sh
# Every "Chapter N" a reader sees for a page must be the number SUMMARY.md gives it:
# the page's own H1, and the label of every [Chapter N: ...](page.md) link in src/.
# Exit 1 on a mismatch, 2 if nothing was compared.
set -eu
src=${1:-src}
map=$(mktemp)
trap 'rm -f "$map"' EXIT
# file<TAB>number for each "[Chapter N: ...](file)" entry in SUMMARY.md
sed -n 's/^[[:space:]]*- \[Chapter \([0-9][0-9]*\):[^]]*\](\([^)]*\)).*/\2\t\1/p' "$src/SUMMARY.md" >"$map"
entries=$(wc -l <"$map")
bad=0
checked=0
while IFS="$(printf '\t')" read -r file num; do
  [ -f "$src/$file" ] || continue
  h1=$(awk '/^```/{f=!f;next} !f && /^# /{print;exit}' "$src/$file")
  case "$h1" in
  "# Chapter "[0-9]*)
    n=$(printf '%s\n' "$h1" | sed 's/^# Chapter \([0-9][0-9]*\).*/\1/')
    checked=$((checked + 1))
    if [ "$n" != "$num" ]; then
      echo "H1   $file: page says Chapter $n, SUMMARY.md says Chapter $num"
      bad=$((bad + 1))
    fi
    ;;
  esac
done <"$map"
# Link labels in chapter pages (SUMMARY.md itself is the reference).
links=$(grep -rnoE '\[Chapter [0-9]+:[^]]*\]\((\./)?[A-Za-z0-9._-]+\.md\)' "$src" --include='*.md' | grep -v "^$src/SUMMARY.md:" || true)
if [ -n "$links" ]; then
  while IFS= read -r l; do
    target=$(printf '%s\n' "$l" | sed 's/.*](\(\.\/\)\{0,1\}\([^)]*\)).*/\2/')
    n=$(printf '%s\n' "$l" | sed 's/.*\[Chapter \([0-9][0-9]*\):.*/\1/')
    num=$(awk -F'\t' -v t="$target" '$1==t{print $2;exit}' "$map")
    [ -n "$num" ] || continue
    checked=$((checked + 1))
    if [ "$n" != "$num" ]; then
      echo "LINK ${l%%\](*}](...$target): label says Chapter $n, SUMMARY.md says Chapter $num"
      bad=$((bad + 1))
    fi
  done <<LINKS
$links
LINKS
fi
echo "check-chapter-numbers: $entries SUMMARY.md chapter entries, $checked comparisons, $bad mismatch(es)"
[ "$checked" -gt 0 ] || exit 2
[ "$bad" -eq 0 ]
