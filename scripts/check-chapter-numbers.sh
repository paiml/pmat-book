#!/bin/sh
# Every "Chapter N" a reader sees for a page must be the number SUMMARY.md gives it:
# the H1 of each "Chapter N" entry, and the label of every [Chapter N: ...](page.md)
# link in src/ (an indented sub-entry carries its parent chapter's number).
# A label whose target file does not exist is a dead link: listed, counted, not
# compared. Exit 1 on a mismatch, 2 if nothing was compared.
set -eu
src=${1:-src}
map=$(mktemp)
trap 'rm -f "$map"' EXIT
# file<TAB>number<TAB>own (own=1 for a "Chapter N" entry, 0 for a sub-entry)
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
bad=0
checked=0
dead=0
tab=$(printf '\t')
while IFS="$tab" read -r file num own; do
  [ "$own" = 1 ] && [ -f "$src/$file" ] || continue
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
links=$(grep -rnoE '\[Chapter [0-9]+:[^]]*\]\((\./)?[A-Za-z0-9._-]+\.md(#[^)]*)?\)' "$src" --include='*.md' | grep -v "^$src/SUMMARY.md:" || true)
if [ -n "$links" ]; then
  while IFS= read -r l; do
    target=$(printf '%s\n' "$l" | sed 's/.*](\(\.\/\)\{0,1\}\([^)#]*\).*/\2/')
    n=$(printf '%s\n' "$l" | sed 's/.*\[Chapter \([0-9][0-9]*\):.*/\1/')
    where=${l%%\[Chapter*}
    if [ ! -f "$src/$target" ]; then
      echo "DEAD ${where}label Chapter $n -> $target (no such page; not compared)"
      dead=$((dead + 1))
      continue
    fi
    if ! awk -F'\t' -v t="$target" '$1 == t { found = 1 } END { exit !found }' "$map"; then
      echo "LINK ${where}label Chapter $n -> $target: page exists but SUMMARY.md does not list it"
      checked=$((checked + 1))
      bad=$((bad + 1))
      continue
    fi
    num=$(awk -F'\t' -v t="$target" '$1 == t { print $2; exit }' "$map")
    checked=$((checked + 1))
    if [ "$n" != "$num" ]; then
      echo "LINK ${where}label Chapter $n -> $target: SUMMARY.md says Chapter ${num:-(none)}"
      bad=$((bad + 1))
    fi
  done <<LINKS
$links
LINKS
fi
echo "check-chapter-numbers: $entries SUMMARY.md chapter entries, $checked comparisons, $bad mismatch(es), $dead dead-link label(s) not compared"
[ "$checked" -gt 0 ] || exit 2
[ "$bad" -eq 0 ]
