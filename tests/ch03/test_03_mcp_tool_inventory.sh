#!/bin/bash
# Chapter 3.2 documents the MCP tool inventory. This test asks the server for it.
#
# The chapter once listed 25 tools, 20 of which `pmat --mode mcp` never served
# (#11), and stayed "Working (25/25)" because nothing compared it to the server.
# Here both directions fail:
#   - a tool `tools/list` returns that has no `#### \`name\`` heading;
#   - a heading for a tool `tools/list` does not return;
#   - a tool whose "Required: yes" rows differ from its schema's `required`.
# Exit 0 = the chapter matches the server, 1 = it does not, 2 = cannot measure
# (no pmat, no jq, or an empty tools/list), which is never a pass.
set -u

CHAPTER="${CHAPTER:-src/ch03-02-mcp-tools.md}"
PMAT_BIN="${PMAT_BIN:-pmat}"

command -v jq >/dev/null 2>&1 || { echo "CANNOT MEASURE: jq not found"; exit 2; }
command -v "$PMAT_BIN" >/dev/null 2>&1 || { echo "CANNOT MEASURE: $PMAT_BIN not found"; exit 2; }
[ -f "$CHAPTER" ] || { echo "CANNOT MEASURE: $CHAPTER missing"; exit 2; }

tools=$(printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"pmat-book-test","version":"1"}}}' \
  '{"jsonrpc":"2.0","method":"notifications/initialized"}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' \
  | timeout 120 "$PMAT_BIN" --mode mcp 2>/dev/null | jq -c 'select(.id==2) | .result.tools' 2>/dev/null)

live=$(printf '%s' "$tools" | jq -r '.[]?.name' 2>/dev/null | sort)
[ -n "$live" ] || { echo "CANNOT MEASURE: $PMAT_BIN --mode mcp returned no tools/list"; exit 2; }

documented=$(sed -n 's/^#### `\([a-z0-9_]*\)`.*/\1/p' "$CHAPTER" | sort)
fail=0

while read -r t; do
  echo "❌ FAIL: served by $($PMAT_BIN --version | head -1) but not documented: $t"
  fail=$((fail + 1))
done < <(comm -23 <(printf '%s\n' "$live") <(printf '%s\n' "$documented") | grep -v '^$')

while read -r t; do
  echo "❌ FAIL: documented but not served (calling it is a -32602): $t"
  fail=$((fail + 1))
done < <(comm -13 <(printf '%s\n' "$live") <(printf '%s\n' "$documented") | grep -v '^$')

# Required parameters: the "| `p` | type | yes |" rows under each heading.
for t in $(comm -12 <(printf '%s\n' "$live") <(printf '%s\n' "$documented")); do
  want=$(printf '%s' "$tools" | jq -r --arg t "$t" '.[] | select(.name==$t) | (.inputSchema.required // [])[]' | sort | tr '\n' ' ')
  got=$(awk -v h="#### \`$t\`" '$0==h {p=1; next} /^#{2,4} / {p=0} p' "$CHAPTER" \
    | sed -n 's/^| `\([a-z_]*\)` | [a-z]* | yes |.*/\1/p' | sort | tr '\n' ' ')
  if [ "$want" != "$got" ]; then
    echo "❌ FAIL: $t required parameters: server [${want% }], chapter [${got% }]"
    fail=$((fail + 1))
  fi
done

n=$(printf '%s\n' "$live" | wc -l)
echo "checked $n served tool(s) against $(printf '%s\n' "$documented" | grep -c .) heading(s) in $CHAPTER: $fail mismatch(es)"
[ "$fail" = 0 ]
