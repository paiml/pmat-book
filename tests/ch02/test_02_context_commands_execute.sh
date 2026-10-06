#!/bin/bash
# Chapter 2: every `pmat context` command the chapter prints must run (#28).
#
# The chapter used a flag vocabulary `pmat context` does not have
# (`--include`, `--max-tokens`, `--cache`, `--template`, ...), and clap
# rejects each with exit 2. A test that greps for a spelling only finds the
# spellings someone thought of, so this one EXECUTES every command in the
# chapter's code blocks, as printed, against a small project, and fails on any
# non-zero exit.
set -u

PASS=0
FAIL=0
test_pass() { echo "✅ PASS: $1"; PASS=$((PASS + 1)); }
test_fail() { echo "❌ FAIL: $1"; FAIL=$((FAIL + 1)); }

CHAPTER="$(cd "$(dirname "$0")/../.." && pwd)/src/ch02-00-getting-started.md"

if ! command -v pmat >/dev/null 2>&1; then
    echo "❌ FAIL: pmat is not on PATH: the chapter's commands cannot be executed"
    exit 1
fi

# Every command as printed, from fenced code blocks only (not prose): a line
# continued with `\` is joined to the next first, so a wrapped command is run
# whole rather than cut at the break. The command runs from `pmat context` to
# a pipe, a redirect, a `;` or a comment.
code_blocks() { awk '/^[[:space:]]*```/ { inside = !inside; next } inside' "$1"; }
join_continuations() { sed -e ':a' -e '/\\$/ { N; s/\\\n[[:space:]]*/ /; ba' -e '}'; }
CMDS=$(code_blocks "$CHAPTER" | join_continuations | grep -oE 'pmat context[^#|>;]*' | sed -E 's/[[:space:]]+$//' | sort -u)
COUNT=$(printf '%s\n' "$CMDS" | grep -c .)
if [ "$COUNT" -lt 10 ]; then
    echo "❌ FAIL: found only $COUNT \`pmat context\` commands in $CHAPTER: the extractor is broken"
    exit 1
fi

# A small project the chapter's paths exist in: source in two languages, a
# sibling project for `-p ../...`, and the directories its examples write to.
FIXTURE=$(mktemp -d)
trap 'rm -rf "$FIXTURE"' EXIT
PROJECT="$FIXTURE/project"
for dir in src tests repo1 repo2 .vscode ../my-other-project; do
    mkdir -p "$PROJECT/$dir"
done
printf 'def add(a, b):\n    if a > b:\n        return a + b\n    return a - b\n' > "$PROJECT/src/app.py"
printf 'export function f(x) { return x > 1 ? x : 0 }\n' > "$PROJECT/src/web.js"
for dir in tests repo1 repo2 ../my-other-project; do
    cp "$PROJECT/src/app.py" "$PROJECT/$dir/"
done

while IFS= read -r cmd; do
    if (cd "$PROJECT" && timeout 120 bash -c "$cmd" >/dev/null 2>"$FIXTURE/.err"); then
        test_pass "$cmd"
    else
        test_fail "$cmd => $(grep -m1 -iE 'error' "$FIXTURE/.err" | cut -c1-100)"
    fi
done <<< "$CMDS"

echo "commands=$COUNT passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ] && [ "$PASS" -eq "$COUNT" ]
