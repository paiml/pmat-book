#!/usr/bin/env bash
# Chapter 19 (#23): `pmat agent` exists only with `--features agent-daemon`,
# which a default `cargo install pmat` lacks. Every `pmat agent` example in
# ch19 and appendix B must (a) parse, so that on a default build it reaches the
# feature gate and exits 1 with its message rather than exiting 2 on a bad
# flag, and (b) sit in a chapter that says the feature is required.
set -euo pipefail

cd "$(dirname "$0")/../.."
CHAPTER=src/ch19-00-agent.md
APPENDIX=src/appendix-b-commands.md
GATE='Agent daemon feature not enabled'

WORK_DIR=$(mktemp -d)
trap 'rm -rf "${WORK_DIR:?}"' EXIT

pass=0
fail=0
ok() { echo "PASS: $1"; pass=$((pass + 1)); }
bad() { echo "FAIL: $1"; fail=$((fail + 1)); }

echo "pmat: $(pmat --version | head -n 1)"

# Every `pmat agent ...` example: whole lines in code (continuations joined),
# plus the Example column of the appendix table.
awk '
    /^```/ { code = !code; next }
    code && cont { line = line " " $0; sub(/\\$/, "", line); if ($0 !~ /\\$/) { print line; cont = 0 }; next }
    code && /^[[:space:]]*pmat agent / {
        line = $0; sub(/^[[:space:]]+/, "", line)
        if (line ~ /\\$/) { sub(/\\$/, "", line); cont = 1 } else print line
    }
' "$CHAPTER" "$APPENDIX" > "$WORK_DIR/examples"
sed -n 's/^| `pmat agent [^`]*` | [^|]* | `\(pmat agent [^`]*\)` |$/\1/p' "$APPENDIX" >> "$WORK_DIR/examples"
sed -i 's/[[:space:]]*&[[:space:]]*$//; s/[[:space:]]*>[^>]*$//; s/[[:space:]]\+/ /g' "$WORK_DIR/examples"
sort -u -o "$WORK_DIR/examples" "$WORK_DIR/examples"
count=$(wc -l < "$WORK_DIR/examples")
echo "found $count distinct pmat agent example(s)"
if [ "$count" -lt 20 ]; then
    bad "expected at least 20 pmat agent examples, found $count: the extractor is broken"
fi

# 1. On a default build every example reaches the feature gate. On a build
#    with the feature these would start a real daemon, so do not run them.
if pmat agent --help 2>&1 | grep -qF 'NOT AVAILABLE in the default build'; then
    while IFS= read -r ex; do
        rc=0
        (cd "$WORK_DIR" && eval "timeout 20 $ex") >"$WORK_DIR/out" 2>&1 </dev/null || rc=$?
        if [ "$rc" -eq 1 ] && grep -qF "$GATE" "$WORK_DIR/out"; then
            ok "reaches the feature gate: $ex"
        else
            bad "$ex: rc=$rc, want 1 and '$GATE': $(grep -m1 -i error "$WORK_DIR/out" || head -n 1 "$WORK_DIR/out")"
        fi
    done < "$WORK_DIR/examples"
else
    echo "SKIP: this pmat was built with agent-daemon; examples not executed"
fi

# 2. The chapter and appendix say the feature is required.
if grep -qF '100% Working' "$CHAPTER"; then
    bad "$CHAPTER still claims 100% Working"
else
    ok "$CHAPTER no longer claims 100% Working"
fi
for want in '> **Not implemented in the default build.**' \
    'cargo install pmat --features agent-daemon' \
    '"args": ["--mode", "mcp"]'; do
    if grep -qF -- "$want" "$CHAPTER"; then ok "$CHAPTER says: $want"; else bad "$CHAPTER lacks: $want"; fi
done
if grep -qF '"args": ["agent", "mcp-server"]' "$CHAPTER"; then
    bad "$CHAPTER still registers pmat agent mcp-server as an MCP server"
else
    ok "$CHAPTER no longer registers pmat agent mcp-server as an MCP server"
fi
if grep -qE 'cargo install pmat$' "$CHAPTER"; then
    bad "$CHAPTER installs pmat without agent-daemon before using the agent"
else
    ok "$CHAPTER installs pmat with agent-daemon"
fi
if grep -qF '> **Needs `--features agent-daemon`.**' "$APPENDIX"; then
    ok "$APPENDIX notes the feature on its agent table"
else
    bad "$APPENDIX lacks the agent-daemon note"
fi

echo "$pass passed, $fail failed"
[ "$pass" -gt 0 ] && [ "$fail" -eq 0 ]
