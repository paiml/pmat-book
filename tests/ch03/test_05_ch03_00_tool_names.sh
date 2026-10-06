#!/bin/bash
# Chapter 3 names MCP tools in its overview and its callTool examples. This
# test asks the server which tools exist.
#
# The chapter once said "19 tools" and named 19, of which only quality_gate was
# served (#13): the count happened to match the server, so the claim passed a
# glance while 18 of the names returned -32602 "Tool not found". Here:
#   - a name in a `- **`name`**` overview item or a callTool('name') call that
#     tools/list does not return fails;
#   - a tool tools/list returns that the overview does not list fails;
#   - a hard-coded total ("Total Tools: N", "(N Total)", "N MCP tools") fails,
#     because the count moves between builds of one release line.
# Exit 0 = the chapter matches the server, 1 = it does not, 2 = cannot measure
# (no pmat, no jq, or an empty tools/list), which is never a pass.
set -u

CHAPTER="${CHAPTER:-src/ch03-00-mcp-protocol.md}"
PMAT_BIN="${PMAT_BIN:-pmat}"

command -v jq >/dev/null 2>&1 || { echo "CANNOT MEASURE: jq not found"; exit 2; }
command -v "$PMAT_BIN" >/dev/null 2>&1 || { echo "CANNOT MEASURE: $PMAT_BIN not found"; exit 2; }
[ -f "$CHAPTER" ] || { echo "CANNOT MEASURE: $CHAPTER missing"; exit 2; }

live=$(printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"pmat-book-test","version":"1"}}}' \
  '{"jsonrpc":"2.0","method":"notifications/initialized"}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' \
  | timeout 120 "$PMAT_BIN" --mode mcp 2>/dev/null \
  | jq -r 'select(.id==2) | .result.tools[]?.name' 2>/dev/null | sort -u)
[ -n "$live" ] || { echo "CANNOT MEASURE: $PMAT_BIN --mode mcp returned no tools/list"; exit 2; }

listed=$(sed -n 's/^- \*\*`\([a-z0-9_]*\)`\*\*.*/\1/p' "$CHAPTER" | sort -u)
called=$(grep -o "callTool('[a-z0-9_]*'" "$CHAPTER" | sed "s/callTool('\(.*\)'/\1/" | sort -u)
[ -n "$listed" ] || { echo "CANNOT MEASURE: no '- **\`name\`**' items in $CHAPTER"; exit 2; }
fail=0

while read -r t; do
  echo "❌ FAIL: named in the chapter but not served (calling it is a -32602): $t"
  fail=$((fail + 1))
done < <(comm -13 <(printf '%s\n' "$live") <(printf '%s\n%s\n' "$listed" "$called" | sort -u) | grep -v '^$')

while read -r t; do
  echo "❌ FAIL: served by $("$PMAT_BIN" --version | head -1) but missing from the overview: $t"
  fail=$((fail + 1))
done < <(comm -23 <(printf '%s\n' "$live") <(printf '%s\n' "$listed") | grep -v '^$')

while read -r l; do
  echo "❌ FAIL: hard-coded tool total (ask tools/list instead): $l"
  fail=$((fail + 1))
done < <(grep -nE 'Total Tools\*\*: [0-9]|\([0-9]+ Total\)|[0-9]+ MCP tools|Tools \([0-9]+ tools\)' "$CHAPTER")

echo "checked $(printf '%s\n' "$live" | grep -c .) served tool(s) against $(printf '%s\n' "$listed" | grep -c .) listed and $(printf '%s\n' "$called" | grep -c .) called name(s) in $CHAPTER: $fail mismatch(es)"
[ "$fail" = 0 ]
