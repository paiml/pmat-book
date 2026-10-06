#!/usr/bin/env bash
# Issue #4: in-prose relative links must resolve to a file in the book.
#
# mdbook validates only SUMMARY.md. A relative link in a chapter is rewritten
# from foo.md to foo.html without any check, so a link to a chapter that was
# never written renders as a live <a href> to a 404, and `mdbook build` still
# exits 0. This walks every Markdown file under src/, skips fenced code blocks
# and inline code spans (an example link in backticks is not a link), and
# requires every relative link and image target to exist on disk.
#
# It counts the links it checked and refuses to pass below a floor: a broken
# extractor would otherwise report "0 dead links" over 0 links.
set -euo pipefail

cd "$(dirname "$0")/../.."
SRC=${1:-src}
MIN_CHECKED=${MIN_CHECKED:-50}

# One line per relative target: <file>:<line><TAB><target>
extract() {
    find "$SRC" -name '*.md' -type f | LC_ALL=C sort | while IFS= read -r f; do
        awk -v file="$f" '
            /^[[:space:]]*(```|~~~)/ { fence = !fence; next }
            fence { next }
            {
                line = $0
                gsub(/`[^`]*`/, "", line)
                while (match(line, /\]\([^) \t]+/)) {
                    t = substr(line, RSTART + 2, RLENGTH - 2)
                    line = substr(line, RSTART + RLENGTH)
                    if (t ~ /^(https?:|mailto:|#|\/)/) continue
                    print file ":" FNR "\t" t
                }
            }
        ' "$f"
    done
}

checked=0
dead=0
while IFS=$'\t' read -r where target; do
    checked=$((checked + 1))
    path=${target%%#*}
    [ -n "$path" ] || continue
    dir=$(dirname "${where%%:*}")
    if [ ! -e "$dir/$path" ]; then
        echo "DEAD: $where -> $target"
        dead=$((dead + 1))
    fi
done < <(extract)

echo "checked $checked relative link(s) under $SRC, $dead dead"
if [ "$checked" -lt "$MIN_CHECKED" ]; then
    echo "UNMEASURED: fewer than $MIN_CHECKED links checked; the extractor is broken"
    exit 1
fi
[ "$dead" -eq 0 ]
