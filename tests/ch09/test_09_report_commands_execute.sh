#!/bin/bash
# Chapter 9: every `pmat report` command the chapter prints must run (#25).
#
# The chapter passed the project as a positional (`pmat report .`), which clap
# rejects with exit 2, and used flags `pmat report` does not have. A test that
# greps for a spelling only finds the spellings someone thought of, so this one
# EXECUTES every command line in the chapter, as printed, against a small
# project, and fails on any non-zero exit.
set -u

PASS=0
FAIL=0
test_pass() { echo "✅ PASS: $1"; PASS=$((PASS + 1)); }
test_fail() { echo "❌ FAIL: $1"; FAIL=$((FAIL + 1)); }

CHAPTER="$(cd "$(dirname "$0")/../.." && pwd)/src/ch09-00-report.md"

if ! command -v pmat >/dev/null 2>&1; then
    echo "❌ FAIL: pmat is not on PATH: the chapter's commands cannot be executed"
    exit 1
fi

# Every command as printed, from fenced code blocks only (not prose): a line
# continued with `\` is joined to the next first, so a wrapped command is run
# whole rather than cut at the break. The command runs from `pmat report` to a
# pipe or a comment.
code_blocks() { awk '/^[[:space:]]*```/ { inside = !inside; next } inside' "$1"; }
join_continuations() { sed -e ':a' -e '/\\$/ { N; s/\\\n[[:space:]]*/ /; ba' -e '}'; }
CMDS=$(code_blocks "$CHAPTER" | join_continuations | grep -oE 'pmat report[^#|]*' | sed -E 's/[[:space:]]+$//' | sort -u)
COUNT=$(printf '%s\n' "$CMDS" | grep -c .)
if [ "$COUNT" -lt 10 ]; then
    echo "❌ FAIL: found only $COUNT \`pmat report\` commands in $CHAPTER: the extractor is broken"
    exit 1
fi

# A small project with source and tests, so a report has something to measure.
FIXTURE=$(mktemp -d)
trap 'rm -rf "$FIXTURE"' EXIT
mkdir -p "$FIXTURE/src" "$FIXTURE/tests"
printf '[package]\nname = "fx"\nversion = "0.1.0"\nedition = "2021"\n' > "$FIXTURE/Cargo.toml"
cat > "$FIXTURE/src/lib.rs" <<'EOF'
pub fn classify(a: i32, b: i32) -> i32 {
    if a > b { a + b } else if a < 0 { b - a } else { a * b }
}

pub fn pair_sum(v: &[i32]) -> i32 {
    let mut s = 0;
    for x in v { for y in v { s += x * y; } }
    s
}
EOF
cp "$FIXTURE/src/lib.rs" "$FIXTURE/tests/dup.rs"

while IFS= read -r cmd; do
    if (cd "$FIXTURE" && timeout 120 bash -c "$cmd" >/dev/null 2>"$FIXTURE/.err"); then
        test_pass "$cmd"
    else
        test_fail "$cmd => $(grep -m1 -iE 'error' "$FIXTURE/.err" | cut -c1-100)"
    fi
done <<< "$CMDS"

echo "commands=$COUNT passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ] && [ "$PASS" -eq "$COUNT" ]
