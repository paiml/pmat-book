#!/bin/sh
# Every "Chapter N" a reader sees for a page must be the number SUMMARY.md gives it:
# the H1 of every listed page and the label of every [Chapter N...](page.md) link
# in src/. An indented sub-entry carries its parent chapter's number, so its
# "# Chapter N.M" H1 or a "Chapter N.M" label must start with that N.
# A label whose target page does not exist, or exists but is not in SUMMARY.md,
# fails: the reader sees a number SUMMARY.md never gave.
# Exit 1 on any mismatch, 2 if nothing was compared or SUMMARY.md has a
# "[Chapter" entry this parser does not recognise.
set -eu
src=${1:-src}
map=$(mktemp)
trap 'rm -f "$map"' EXIT
# file<TAB>number<TAB>own (own=1 for a "- [Chapter N: ...]" entry, 0 otherwise)
awk '
  match($0, /\]\([^)#]*/) {
    file = substr($0, RSTART + 2, RLENGTH - 2)
    sub(/^\.\//, "", file)
    if ($0 ~ /^- \[Chapter [0-9]+:/) {
      cur = $0; sub(/^- \[Chapter /, "", cur); sub(/:.*/, "", cur)
      print file "\t" cur "\t1"
    } else if ($0 ~ /^- /) {
      cur = ""
      print file "\t\t0"
    } else {
      print file "\t" cur "\t0"
    }
  }' "$src/SUMMARY.md" >"$map"
entries=$(awk -F'\t' '$3 == 1' "$map" | wc -l)
all=$(grep -c '\[Chapter [0-9]' "$src/SUMMARY.md" || true)
if [ "$all" -ne "$entries" ]; then
  echo "SUMMARY.md has $all [Chapter N entries but only $entries are top-level \"- [Chapter N: ...]\" lines"
  exit 2
fi
bad=0
checked=0
tab=$(printf '\t')
# major<TAB>minor of a "Chapter N" or "Chapter N.M" string on stdin
num_of() { sed 's/.*Chapter \([0-9][0-9]*\)\(\.[0-9][0-9]*\)\{0,1\}.*/\1/'; }
while IFS="$tab" read -r file num own; do
  [ -f "$src/$file" ] || continue
  h1=$(awk '/^```/{f=!f;next} !f && /^# /{print;exit}' "$src/$file")
  case "$h1" in
  "# Chapter "[0-9]*)
    n=$(printf '%s\n' "$h1" | num_of)
    checked=$((checked + 1))
    if [ "$n" != "$num" ]; then
      echo "H1   $file: page says Chapter $n, SUMMARY.md says Chapter ${num:-(none)}"
      bad=$((bad + 1))
    fi
    ;;
  esac
done <"$map"
# Link labels in chapter pages (SUMMARY.md itself is the reference).
links=$(grep -rnoE '\[Chapter [0-9]+(\.[0-9]+)?([:]?[^]]*)?\]\((\./)?[A-Za-z0-9._-]+\.md(#[^)]*)?\)' "$src" --include='*.md' | grep -v "^$src/SUMMARY.md:" || true)
if [ -n "$links" ]; then
  while IFS= read -r l; do
    target=$(printf '%s\n' "$l" | sed 's/.*](\(\.\/\)\{0,1\}\([^)#]*\).*/\2/')
    n=$(printf '%s\n' "$l" | num_of)
    where=${l%%\[Chapter*}
    checked=$((checked + 1))
    if [ ! -f "$src/$target" ]; then
      echo "DEAD ${where}label Chapter $n -> $target: no such page"
      bad=$((bad + 1))
      continue
    fi
    if ! awk -F'\t' -v t="$target" '$1 == t { found = 1 } END { exit !found }' "$map"; then
      echo "LINK ${where}label Chapter $n -> $target: page exists but SUMMARY.md does not list it"
      bad=$((bad + 1))
      continue
    fi
    num=$(awk -F'\t' -v t="$target" '$1 == t { print $2; exit }' "$map")
    if [ "$n" != "$num" ]; then
      echo "LINK ${where}label Chapter $n -> $target: SUMMARY.md says Chapter ${num:-(none)}"
      bad=$((bad + 1))
    fi
  done <<LINKS
$links
LINKS
fi
echo "check-chapter-numbers: $entries SUMMARY.md chapter entries, $checked comparisons, $bad mismatch(es)"
[ "$checked" -gt 0 ] || exit 2
[ "$bad" -eq 0 ]
