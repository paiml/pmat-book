#!/usr/bin/env bash
# Appendix B (#33): every `pmat ...` example on the quick reference must be a
# command pmat has. Earlier editions listed about 30 top-level commands that
# never existed and 163 of 283 examples failed argument parsing (exit 2).
#
# An example is checked by appending `--help`: the argument parser then judges
# the subcommand path and every flag before `--help`, and exits 0 only if all
# of them exist, without running the command. Examples are the lines in code
# fences and the backticked cells of table rows; prose may name a removed
# command to say it is gone.
set -euo pipefail

cd "$(dirname "$0")/../.."
APPENDIX=${1:-src/appendix-b-commands.md}

WORK_DIR=$(mktemp -d)
trap 'rm -rf "${WORK_DIR:?}"' EXIT

pass=0
fail=0
ok() { echo "PASS: $1"; pass=$((pass + 1)); }
bad() { echo "FAIL: $1"; fail=$((fail + 1)); }

echo "pmat: $(pmat --version | head -n 1)"

{
    awk '
        /^```/ { code = !code; next }
        code && cont { line = line " " $0; sub(/\\$/, "", line); if ($0 !~ /\\$/) { print line; cont = 0 }; next }
        code && /^[[:space:]]*pmat / {
            line = $0; sub(/^[[:space:]]+/, "", line)
            if (line ~ /\\$/) { sub(/\\$/, "", line); cont = 1 } else print line
        }
    ' "$APPENDIX"
    grep -E '^\|' "$APPENDIX" | grep -oE '`pmat [^`]*`' | tr -d '`'
} | sed -E 's/[[:space:]]*(\||&&|;|2?>|#).*$//; s/[[:space:]]+/ /g; s/ $//' |
    grep -v '<' | sort -u > "$WORK_DIR/examples"
count=$(wc -l < "$WORK_DIR/examples")
echo "found $count distinct pmat example(s)"
if [ "$count" -lt 100 ]; then
    bad "expected at least 100 pmat examples, found $count: the extractor is broken"
fi

# 1. Every example parses. `pmat help <cmd>` takes no flags; it only prints help.
while IFS= read -r ex; do
    case "$ex" in
        "pmat help"*|*--help*) cmd=$ex ;;
        *) cmd="$ex --help" ;;
    esac
    rc=0
    (cd "$WORK_DIR" && eval "timeout 20 $cmd") >"$WORK_DIR/out" 2>&1 </dev/null || rc=$?
    if [ "$rc" -eq 0 ]; then
        ok "parses: $ex"
    else
        bad "$ex: rc=$rc: $(grep -m1 -i error "$WORK_DIR/out" || head -n 1 "$WORK_DIR/out")"
    fi
done < "$WORK_DIR/examples"

# 2. None of the invented top-level commands is offered as an example.
for gone in status scan check compliance doctor info dashboard team plugin \
    webhook pipeline retrospective ai rules clippy architecture performance \
    security templates validate-template; do
    if grep -qxE "pmat $gone( .*)?" "$WORK_DIR/examples"; then
        bad "still offers pmat $gone, which pmat does not have"
    fi
done

# 3. Only environment variables pmat reads.
for var in PMAT_CONFIG_PATH PMAT_PROFILE PMAT_MAX_THREADS PMAT_MEMORY_LIMIT \
    PMAT_CACHE_DIR PMAT_API_TOKEN PMAT_DEBUG PMAT_LOG_LEVEL; do
    if grep -E '^\|' "$APPENDIX" | grep -qF "\`$var\`"; then
        bad "the environment table lists $var, which pmat does not read"
    fi
done

echo "$pass passed, $fail failed"
[ "$pass" -gt 0 ] && [ "$fail" -eq 0 ]
