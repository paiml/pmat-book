# Chapter 3.4: Three Surfaces — CLI, MCP stdio, and MCP over HTTP

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (28/28 automated assertions)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 28 | `tests/ch03/test_04_mcp_transports.sh` |
| ⚠️ Not Implemented | 0 | `--transport web-socket / http-sse / both / all` are documented here as the exit-2 refusals they are |
| ❌ Broken | 0 | — |
| 📋 Planned | 0 | — |

*Last updated: 2026-08-25*
*PMAT version: pmat 3.32.0*
<!-- DOC_STATUS_END -->

## The Problem

One `pmat` binary answers to three different callers, and the three do not
look alike from the outside:

- a human at a shell,
- an agent that spawns a child process and speaks JSON-RPC down its pipes,
- an agent on another machine (or in another container) that can only reach
  you over a socket.

Older editions of this book treated the first as "pmat" and the second as "MCP
mode", and described the third as a stub that printed a banner and bound
nothing. As of **pmat 3.32.0** all three are real, they are served from the same
binary, and — the part worth internalising — the two MCP surfaces expose a tool
set that is *identical down to the JSON schema*. This chapter is the map: how to
start each surface, how to talk to it with nothing but `curl`, exactly which
error you get when you hold it wrong, and how to choose.

## The Three Surfaces at a Glance

| Surface | How you start it | Who talks to it | Reach for it when |
|---|---|---|---|
| **CLI** | `pmat analyze satd --path src/` | a human, a Makefile, a CI job | you want a human-readable report, an exit code, or a shell pipeline |
| **MCP over stdio** | `pmat --mode mcp` (or `MCP_VERSION=1 pmat`, or `pmat serve --mode mcp`) | an agent that can spawn a child process: Claude Code, Claude Desktop, any MCP client with a `command` field | the agent runs on the same machine as the code, which is the common case |
| **MCP over HTTP** | `pmat serve --transport http --port 8823` | an agent that can only reach you over a socket: a remote or containerised client, several clients at once, a browser-side tool | pmat and the agent are on different sides of a process, container, or host boundary |

Two things are true of every row and are worth stating before the details:

1. **The two MCP rows serve the same tools.** Not "similar" — the same, proved
   by diff later in this chapter.
2. **The `--transport` flag has exactly one implemented value.** `http` works.
   `web-socket`, `http-sse`, `both` and `all` exit 2 with a message saying so.
   There is no `stdio` value; stdio is not a transport of `serve`, it is what
   `--mode mcp` gives you.

The examples below all use one tiny fixture. Create it once:

```bash
mkdir -p /tmp/pmat-mcp-demo/src && cd /tmp/pmat-mcp-demo
cat > src/main.rs << 'EOF'
// TODO: replace this hand-rolled grader with the real one
fn grade(score: u32, strict: bool) -> &'static str {
    if strict {
        if score > 90 { "A" } else if score > 80 { "B" } else { "C" }
    } else if score > 70 {
        "pass"
    } else {
        "fail"
    }
}

fn main() {
    println!("{}", grade(85, true));
}
EOF
```

One file, one `TODO`. Every surface below is asked the same question about it,
so you can see the answers line up.

## Surface 1: The CLI

```bash
pmat analyze satd --path src/main.rs
```

```
🔍 Analyzing Self-Admitted Technical Debt (SATD)...
SATD Analysis Summary

Found 1 SATD violations in 1 files

Total violations:  1

Severity Distribution
  Critical: 0
  High: 0
  Medium: 0
  Low: 1

Top Violations
  1. src/main.rs:1 - Requirement Low
```

Formatted for a person, exit code for a script. Nothing about MCP is involved.
This is the surface the rest of the book documents command by command; it is in
this chapter only so the other two have something to be compared against.

## Surface 2: MCP over stdio

An MCP client that can spawn a process wants a command, not a URL. `pmat` gives
it one:

```bash
printf '%s\n%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"c","version":"1"}}}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' \
  | pmat --mode mcp 2>/dev/null | head -1
```

```json
{"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2024-11-05","capabilities":{"tools":{"listChanged":true}},"serverInfo":{"name":"paiml-mcp-agent-toolkit","version":"3.32.0"}}}
```

There are three spellings of this one server, and they are interchangeable:

| Invocation | Notes |
|---|---|
| `pmat --mode mcp` | the explicit form; what `pmat init` writes into a client config |
| `MCP_VERSION=1 pmat` | the environment-variable form, for clients that set env but not args |
| `pmat serve --mode mcp` | `serve`'s own `--mode`; same stdio server, no socket is bound |

`pmat --mode mcp` and `MCP_VERSION=1 pmat` are verified in this book's test
suite to return a byte-identical `tools/list`.

> **A correction to older editions.** Earlier printings said MCP mode was
> auto-detected from the shape of stdin and that `pmat --mode mcp` did not work.
> Both halves are now false. Piping JSON-RPC into a bare `pmat` prints the help
> text and exits 2 — it does *not* enter MCP mode. Use `--mode mcp` or
> `MCP_VERSION=1`.

### Registering the stdio server

`pmat init` writes the registration for you rather than making you copy JSON out
of a book:

```bash
pmat init --target claude --path /tmp/pmat-mcp-demo
```

```
pmat init — target: claude
root: /tmp/pmat-mcp-demo

  created  .agents/hooks/pmat-quality-feedback.sh       shared pre-write quality hook (FEEDBACK, not a gate — see AGENTS.md)
  created  AGENTS.md                                    root rules file, read by Claude Code and Antigravity alike
  created  .claude/settings.json                        PreToolUse hook via $CLAUDE_PROJECT_DIR (no cwd hazard)
  created  .mcp.json                                    MCP server registration — `pmat --mode mcp`, spawn-tested
  created  .claude/skills/pmat-quality/SKILL.md         skill with pinned `effort` frontmatter (the path CB-1650 reads)

5 written, 0 already current, 0 kept, 0 refused

next: install pmat on PATH (`cargo install pmat`), then verify the MCP
registration with:  pmat --mode mcp <<< '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}'
```

The `.mcp.json` it writes is the canonical shape:

```json
{
  "mcpServers": {
    "pmat": {
      "command": "pmat",
      "args": ["--mode", "mcp"],
      "env": {}
    }
  }
}
```

Note `args`. A registration with `"args": []` — which older editions of this
book printed — no longer starts an MCP server.

## Surface 3: MCP over Streamable HTTP

New in 3.32.0: `--transport http` is implemented, it binds a real socket, and
it is in the **default feature set**. Before this release you had to build with
`--features mcp-http`; a stock `cargo install pmat` now has it.

### Quickstart

```bash
PMAT_MCP_HTTP_TOKEN='pmat-mcp-demo-token-0123456789' \
  pmat serve --transport http --port 8823
```

```
pmat MCP (streamable HTTP) listening on http://127.0.0.1:8823/
  auth: Bearer, from PMAT_MCP_HTTP_TOKEN; unauthenticated requests get 401
  tools: 16
```

Three facts are packed into that banner, and each is load-bearing:

1. **The URL ends in `/`.** MCP is served at the **root path**. There is no
   `/mcp`, no `/health`, no `/api/v1`; those are 404s (see *Failure Modes*).
2. **A bearer token is mandatory.** `pmat serve` refuses to start without
   `PMAT_MCP_HTTP_TOKEN`, and refuses tokens shorter than 16 characters. The
   underlying `pmcp` transport serves every request when no auth provider is
   wired, so "no token" has to mean "no server" — there is no unauthenticated
   mode to fall into by accident.
3. **The tool count is a property of your build**, not of this book. Read it
   from the banner, or count it yourself (below).

It binds `127.0.0.1` unless you pass `--host`. If you widen that, the bearer
token is the only thing between the port and the full tool surface — pick a real
secret, not the demo string above.

### Wiring it into Claude Code

```bash
claude mcp add --scope user --transport http pmat-http http://127.0.0.1:8823/ \
  --header "Authorization: Bearer pmat-mcp-demo-token-0123456789"
```

```
Added HTTP MCP server pmat-http with URL: http://127.0.0.1:8823 to user config
Headers: {
  "Authorization": "[REDACTED]"
}
File modified: /home/noah/.claude.json
```

```bash
claude mcp list
```

```
Checking MCP server health…

pmat-http: http://127.0.0.1:8823/ (HTTP) - ✔ Connected
```

(Any other servers you have registered are listed alongside it; only the `pmat-http`
line is shown here.)

`✔ Connected` is the whole acceptance test. If you get `✘ Failed to connect`,
jump to *Failure Modes* — the message is specific enough to name the cause.

To remove it again:

```bash
claude mcp remove --scope user pmat-http
```

```
Removed MCP server pmat-http from user config
File modified: /home/noah/.claude.json
```

## Talking to It With `curl`

You do not need an MCP client to exercise the HTTP surface, and doing it by hand
once is the fastest way to understand what your client is doing. Two headers are
non-negotiable:

- `Authorization: Bearer <PMAT_MCP_HTTP_TOKEN>`
- `Accept: application/json, text/event-stream` — the streamable transport
  rejects a request that does not accept both.

### `initialize`

```bash
curl -s -D - -X POST http://127.0.0.1:8823/ \
  -H "Authorization: Bearer pmat-mcp-demo-token-0123456789" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"curl","version":"1"}}}'
```

```
HTTP/1.1 200 OK
content-type: application/json
mcp-protocol-version: 2024-11-05
x-content-type-options: nosniff
x-frame-options: DENY
cache-control: no-store
vary: origin
access-control-expose-headers: mcp-session-id,mcp-protocol-version
content-length: 179

{"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2024-11-05","capabilities":{"tools":{"listChanged":true}},"serverInfo":{"name":"paiml-mcp-agent-toolkit","version":"3.32.0"}}}
```

Look at what is *not* in those headers: there is no `Mcp-Session-Id`. This
server does not issue one and does not require one. `tools/call` works
immediately, and works even if you never sent `initialize` at all.

### `tools/call`

```bash
curl -s -X POST http://127.0.0.1:8823/ \
  -H "Authorization: Bearer pmat-mcp-demo-token-0123456789" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"analyze_satd","arguments":{"paths":["/tmp/pmat-mcp-demo/src/main.rs"]}}}' \
  | jq -r '.result.content[0].text' | jq .
```

```json
{
  "status": "completed",
  "message": "SATD analysis completed",
  "results": {
    "total_satd": 1,
    "files": [
      {
        "file": "/tmp/pmat-mcp-demo/src/main.rs",
        "satd_count": 1,
        "debts": [
          {
            "line": 1,
            "category": "Requirement",
            "severity": "Low",
            "text": "TODO: replace this hand-rolled grader with the real one"
          }
        ]
      }
    ],
    "files_read": 1,
    "files_not_read": {
      "total": 0,
      "tests": 0,
      "examples_demo_fuzz_generated": 0,
      "minified_or_vendor": 0,
      "too_large": 0,
      "unreadable": 0
    },
    "violations_truncated": false
  }
}
```

The MCP envelope is a `content` array whose single `text` entry is a stringified
JSON report — hence the double `jq`. Same one `TODO` the CLI found, same line
number, now machine-readable.

### The paths belong to the server, not to you

The tool arguments are filesystem paths, and they are resolved by the **server**
process. Run the server in `/tmp/pmat-mcp-demo` and `curl` from anywhere else:

```bash
cd /home/noah/src/pmat-book   # a completely different directory
curl -s -X POST http://127.0.0.1:8823/ \
  -H "Authorization: Bearer pmat-mcp-demo-token-0123456789" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"analyze_satd","arguments":{"paths":["src/main.rs"]}}}' \
  | jq -r '.result.content[0].text' | jq -c '.results.files[0].file'
```

```
"src/main.rs"
```

That resolved against the *server's* working directory. A path relative to the
client's directory is simply not there:

```bash
curl -s -X POST http://127.0.0.1:8823/ \
  -H "Authorization: Bearer pmat-mcp-demo-token-0123456789" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"analyze_satd","arguments":{"paths":["src/ch03-00-mcp-protocol.md"]}}}' \
  | jq -c .error
```

```json
{"code":-32603,"message":"Validation error: path(s) not found: src/ch03-00-mcp-protocol.md. Analysing a nonexistent path would report zero findings, which is indistinguishable from a clean result."}
```

Note that pmat refuses rather than returning a clean-looking zero. Over HTTP,
**send absolute paths** unless you are certain where the server was started.

## The Two MCP Surfaces Are One Surface

This is the claim that makes the HTTP transport safe to adopt: nothing about
your tool usage changes when you move a client from stdio to HTTP. Prove it
locally — ask both surfaces for their tool list, sort, and diff:

```bash
TOKEN='pmat-mcp-demo-token-0123456789'
INIT='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"c","version":"1"}}}'
LIST='{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'

printf '%s\n%s\n' "$INIT" "$LIST" | pmat --mode mcp 2>/dev/null \
  | sed -n 2p | jq -S '.result.tools | sort_by(.name)' > /tmp/tools-stdio.json

curl -s -X POST http://127.0.0.1:8823/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d "$LIST" | jq -S '.result.tools | sort_by(.name)' > /tmp/tools-http.json

diff /tmp/tools-stdio.json /tmp/tools-http.json && echo "identical: $(jq length /tmp/tools-http.json) tools"
```

```
identical: 16 tools
```

`diff` is silent: same names, same descriptions, same `inputSchema` for every
tool. The `sort_by(.name)` matters — the two surfaces build the same set but do
not promise the same array order, so compare them as sets.

The names, on the build used for this chapter:

```bash
jq -r '.[].name' /tmp/tools-http.json
```

```
analyze_big_o
analyze_complexity
analyze_dag
analyze_dead_code
analyze_deep_context
analyze_satd
generate_context
git_operation
pdmt_deterministic_todos
pmat_find_similar
pmat_get_function
pmat_index_stats
pmat_query_code
quality_gate
quality_proxy
scaffold_project
```

### Count the tools; do not quote them

The number above is 16, and it is *not* a fact about "pmat 3.32.0". Tools are
added within a release line, so a binary reporting the same version string can
serve more of them: the 3.32.0 build this chapter was written against
(`commit 583ea9ac`) serves 16, while a 3.32.0 build from `commit 90767deb`
serves 19 — it adds `analyze_hardcoded_paths`, `analyze_reachability` and
`analyze_vacuous_tests`. Both builds pass the identity check above unchanged.

So read the count from your own binary rather than from a book:

```bash
pmat --version | head -1
printf '%s\n%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"c","version":"1"}}}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' \
  | pmat --mode mcp 2>/dev/null | sed -n 2p | jq '.result.tools | length'
```

```
pmat 3.32.0
16
```

The HTTP banner's `tools: N` line reports the same number, and this book's test
suite asserts that the banner and `tools/list` agree.

## Failure Modes

These are ordered by how often you will hit them. Each message below is the
verbatim output of the command above it.

### The token is too short — the server refuses to start

```bash
PMAT_MCP_HTTP_TOKEN='too-short-123' pmat serve --transport http --port 8823
```

```
Error: PMAT_MCP_HTTP_TOKEN must be at least 16 characters; got 13
```

Exit code **1**. No socket is bound. The minimum is 16 characters.

### No token at all — also refuses to start

```bash
env -u PMAT_MCP_HTTP_TOKEN pmat serve --transport http --port 8823
```

```
Error: PMAT_MCP_HTTP_TOKEN is not set. `pmat serve` will not start an unauthenticated MCP endpoint: pmcp serves every request when no auth provider is configured, so starting without a token would publish the full tool surface to anyone who can reach the port.
```

Exit code **4**. This is deliberate: an unauthenticated MCP endpoint would hand
anyone who can reach the port the ability to read your source tree, so the
failure is loud and at startup rather than silent and at request time.

### Missing `Accept` header — 406

```bash
curl -s -X POST http://127.0.0.1:8823/ \
  -H "Authorization: Bearer pmat-mcp-demo-token-0123456789" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"c","version":"1"}}}'
```

```json
{"jsonrpc":"2.0","error":{"code":-32700,"message":"Accept header must include application/json or text/event-stream"},"id":null}
```

HTTP **406**. Beware of hiding this from yourself: `curl -f` turns it into an
empty body and exit status 22, with no message at all —

```bash
curl -sf -X POST http://127.0.0.1:8823/ \
  -H "Authorization: Bearer pmat-mcp-demo-token-0123456789" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"c","version":"1"}}}'
echo "curl -f exit=$?"
```

```
curl -f exit=22
```

— which is why the header requirement is worth committing to memory. Health
checks written with `curl -f` are the classic way to make this bug invisible.

### No credentials — 401

```bash
curl -s -X POST http://127.0.0.1:8823/ \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"c","version":"1"}}}'
```

```json
{"jsonrpc":"2.0","error":{"code":-32003,"message":"Authentication failed: Internal error: missing Authorization header"},"id":null}
```

### Wrong token — 401

```bash
curl -s -X POST http://127.0.0.1:8823/ \
  -H "Authorization: Bearer wrong-token-but-long-enough-xxxx" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"c","version":"1"}}}'
```

```json
{"jsonrpc":"2.0","error":{"code":-32003,"message":"Authentication failed: Internal error: invalid bearer token"},"id":null}
```

Both are HTTP **401** with JSON-RPC code `-32003`, and the two messages tell you
which mistake you made.

### Right server, wrong path — 404

MCP lives at `/`. Every path a REST habit reaches for is a 404:

```bash
for p in /mcp /health /api/v1; do
  printf '%-8s ' "$p"
  curl -s -o /dev/null -w 'HTTP %{http_code}\n' -X POST "http://127.0.0.1:8823$p" \
    -H "Authorization: Bearer pmat-mcp-demo-token-0123456789" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json, text/event-stream" \
    -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"c","version":"1"}}}'
done
```

```
/mcp     HTTP 404
/health  HTTP 404
/api/v1  HTTP 404
```

There is **no health endpoint**. To check liveness, POST a real `initialize` to
`/` and look for a 200 — or watch for the listening banner on startup.

### A 400 is never an authentication problem

The request body is parsed before credentials are checked, so a malformed body
returns **400** even with no `Authorization` header at all:

```bash
curl -s -o /dev/null -w 'HTTP %{http_code}\n' -X POST http://127.0.0.1:8823/ \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d 'not json at all'
curl -s -X POST http://127.0.0.1:8823/ \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d 'not json at all'
```

```
HTTP 400
{"jsonrpc":"2.0","error":{"code":-32700,"message":"Invalid JSON: Transport error: Invalid message format: Invalid JSON: expected ident at line 1 column 2"},"id":null}
```

If you see 400, fix your JSON; if you see 401, fix your token. They are never
the same problem.

### The port is taken

```bash
PMAT_MCP_HTTP_TOKEN='pmat-mcp-demo-token-0123456789' pmat serve --transport http --port 8823
```

```
Error: starting the streamable-HTTP MCP server failed: Transport error: IO error: Address already in use (os error 98)
```

Exit code **1** — including when the thing already holding the port is your own
earlier `pmat serve`.

### `claude mcp add` without `--header`

Registering the HTTP server and forgetting the bearer header does not produce a
401 in the client UI. It produces this:

```
pmat-http-noauth: http://127.0.0.1:8823/ (HTTP) - ✘ Failed to connect — Dynamic Client Registration rejected (HTTP 404):
```

The client tried to negotiate OAuth, found no registration endpoint (correctly —
there is none), and reported that instead of the underlying auth failure. If you
see "Dynamic Client Registration", you forgot `--header`.

### The other transports

```bash
PMAT_MCP_HTTP_TOKEN='pmat-mcp-demo-token-0123456789' pmat serve --transport web-socket --port 8899
```

```
error: pmat serve --transport websocket is not yet implemented
  requested: transport=websocket host=127.0.0.1 port=8899
hint: `--transport http` works — build with `--features mcp-http` and set PMAT_MCP_HTTP_TOKEN
hint: use stdio MCP today — `MCP_VERSION=1 pmat` (serves the analysis tools over stdio)
hint: follow KAIZEN-0191 for the HTTP/WebSocket/SSE wiring
```

Exit code **2**, and the same for `http-sse`, `both` and `all`. The refusal
names the transport, the host and the port it was asked for — it fails at
startup instead of printing a success banner and binding nothing, which is what
these flags used to do. (The first hint is vestigial: `mcp-http` has been a
default feature since 3.32.0, so there is nothing to rebuild.)

`stdio` is not a value of `--transport` at all:

```bash
pmat serve --transport stdio
```

```
error: invalid value 'stdio' for '--transport <TRANSPORT>'
  [possible values: http, web-socket, http-sse, both, all]

For more information, try '--help'.
```

Exit code **2**, from the argument parser. For stdio, use `--mode mcp`.

One more piece of `--help` text to read sceptically: `--transport http` is
described there as "HTTP transport (REST API)". It is not a REST API. It is MCP
JSON-RPC over streamable HTTP, at the root path, and nothing on the server
answers a `GET`.

## Choosing a Surface

| If… | Use |
|---|---|
| you are a person, or a Makefile, or a CI step | the CLI |
| your agent runs on the same machine as the code | MCP over stdio — no port, no token, no lifecycle to manage |
| your agent is in a different container, or on another host | MCP over HTTP |
| several clients need one warm pmat | MCP over HTTP — a stdio server serves exactly one client, its parent |
| you need a REST API | none of them; call the CLI and parse its output |
| you need WebSocket or SSE | none of them yet; `--transport web-socket` / `http-sse` exit 2 |

The default answer for a coding agent is **stdio**. It has no port to secure, no
token to leak, and the client owns the process lifetime. Reach for HTTP when a
process boundary makes stdio impossible — and then remember that the token is
the entire security model.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Server exits immediately, `must be at least 16 characters` | token too short | use ≥16 characters |
| Server exits immediately, `PMAT_MCP_HTTP_TOKEN is not set` | no token | set one; there is no unauthenticated mode |
| `Address already in use (os error 98)` | port taken, often by your own earlier run | `--port` something else, or stop the other server |
| HTTP 406 | missing `Accept: application/json, text/event-stream` | add the header |
| HTTP 401, `missing Authorization header` | no credentials | add `Authorization: Bearer $PMAT_MCP_HTTP_TOKEN` |
| HTTP 401, `invalid bearer token` | wrong token | make the header match the server's env var |
| HTTP 404 | you posted to `/mcp`, `/health` or `/api/v1` | post to `/` |
| HTTP 400 | malformed JSON-RPC body | fix the body — this is not an auth error |
| Empty response, `curl` exits 22 | `curl -f` swallowed a 4xx | drop `-f`, or add `-w '%{http_code}'` |
| `✘ Failed to connect — Dynamic Client Registration rejected` | `claude mcp add` without `--header` | re-add with `--header "Authorization: Bearer …"` |
| `path(s) not found` on a path that exists | relative path resolved against the *server's* cwd | send absolute paths |
| Bare `pmat` prints help instead of speaking MCP | MCP mode is not auto-detected | use `pmat --mode mcp` or `MCP_VERSION=1 pmat` |

## Testing This Chapter

Every command above is executed by
`tests/ch03/test_04_mcp_transports.sh`, which is wired into `make test-ch03`:

```bash
make test-ch03
```

The script covers all three surfaces: it runs the CLI against the fixture,
drives both stdio entry points, starts a real HTTP server on a free port in
18810–18840, and asserts every status code, exit code and error string quoted in
this chapter — including the byte-identical `tools/list` diff and the agreement
between the startup banner's tool count and `tools/list`. It is deliberately
count-agnostic, so it passes unchanged on the 16-tool and 19-tool builds
described above.

Missing `pmat`, `curl` or `jq` makes the script print `SKIPPED: … this run
verified NOTHING` and exit 0. That wording is chosen on purpose: a skipped test
is not a passing test.

## Summary

- One binary, three surfaces: **CLI**, **MCP over stdio**, **MCP over HTTP**.
- stdio: `pmat --mode mcp`, `MCP_VERSION=1 pmat`, or `pmat serve --mode mcp`.
  A bare `pmat` with JSON-RPC on stdin does **not** enter MCP mode.
- HTTP: `pmat serve --transport http`, implemented and in the default feature
  set as of 3.32.0. It serves MCP at the **root path** — `/mcp`, `/health` and
  `/api/v1` are 404s.
- `PMAT_MCP_HTTP_TOKEN` is mandatory and must be ≥16 characters; the server
  refuses to start otherwise, because the transport underneath it would
  otherwise serve everyone.
- Every RPC needs both `Authorization: Bearer …` and
  `Accept: application/json, text/event-stream`. No session id is required.
- The stdio and HTTP tool surfaces are **identical**, schemas included — verify
  it with the `diff` recipe rather than trusting this sentence.
- The tool count belongs to your build, not to the version string. Count it.
- `--transport web-socket`, `http-sse`, `both` and `all` exit 2; `stdio` is not
  a `--transport` value at all.

---

*Cross-references:*
- Chapter 3 (`ch03-00-mcp-protocol.md`) — MCP protocol overview
- Chapter 3.1 (`ch03-01-mcp-setup.md`) — MCP server setup
- Chapter 3.3 (`ch03-03-claude-integration.md`) — Claude Code integration
- Chapter 15 (`ch15-00-mcp-tools.md`) — per-tool reference
- Chapter 64 (`ch64-00-mcp-mode.md`) — historical: MCP mode as of 3.14.0
- Chapter 65 (`ch65-00-http-server.md`) — historical: the HTTP stub, now closed
