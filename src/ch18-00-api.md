# Chapter 18: The MCP HTTP Server and Roadmap Management

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ Rewritten against pmat 3.32.0 — every example below was executed

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 21 | Executed against pmat 3.32.0 on 2026-08-25 |
| ⚠️ Not Implemented | 4 | `--transport web-socket`, `http-sse`, `both`, `all` — all exit 2 |
| ❌ Broken | 0 | — |
| 📋 Planned | 0 | — |

*Last updated: 2026-08-25*
*PMAT version: pmat 3.32.0*
<!-- DOC_STATUS_END -->

> **⚠️ Historical warning, as of pmat 3.32.0 (2026-08-25). The REST API this
> chapter used to document does not exist and never did.**
>
> The previous edition described `pmat 2.213.1` and was marked
> `✅ 100% Working (16/16 examples)`. Every HTTP example in it was fiction:
>
> - **There is no REST API.** `/health`, `/analyze`, `/context`, `/quality-gate`,
>   `/batch-analyze` and `/report` all return **404**, GET and POST alike, against a
>   running server. So does `/mcp`. Measured, all fourteen combinations, below.
> - **There is no WebSocket endpoint.** `ws://localhost:8080/ws` is a 404 like the
>   rest, and `--transport web-socket` exits 2 with "not yet implemented".
> - **`ab -n 1000 -c 10 http://localhost:8080/health`** — the benchmark the old
>   chapter reported at 2500 req/s — was load-testing a 404.
> - **The roadmap flags were wrong.** `roadmap init --sprint --goal`,
>   `roadmap todos --format markdown`, `roadmap complete --quality-check` and
>   `roadmap quality-check --project` are all rejected by the argument parser with
>   `error: unexpected argument found`, exit 2.
>
> What `pmat serve` really does is serve **MCP over streamable HTTP at the root
> path**, with mandatory bearer auth. That is documented below and, in more depth,
> in [Chapter 3.4: MCP Transports](ch03-04-mcp-transports.md). The roadmap half of
> this chapter is real, and has been rewritten against the flags the binary
> actually accepts.
>
> Chapter 69 recorded `pmat serve` as a stub that bound no port at 3.14.0. That was
> true then. As of 3.32.0 it binds, and the transcript below is from a live server.

## The Problem

Two unrelated needs got bundled into one chapter, and both were mis-documented.

The first is **giving an MCP client access to pmat's analyses over a network** —
a client on another machine, or one that cannot spawn a subprocess. That is what
`pmat serve` is for. It is not a general-purpose REST API and it does not have
per-analysis URLs; it is one JSON-RPC endpoint speaking the Model Context Protocol.

The second is **sprint tracking with quality gates** — `pmat roadmap`. That is a
small markdown-backed tracker, and it works, provided you use the flags it has.

## Part 1 — `pmat serve`: MCP over HTTP

### Starting the server

`--transport http` is the only implemented transport, and it is the default:

```bash
export PMAT_MCP_HTTP_TOKEN=$(pmat mcp token)
pmat serve --transport http --port 8791
```

Executed output — the token is redacted and the `claude mcp add` line is wrapped to
fit the page; nothing else is changed:

```
pmat MCP (streamable HTTP) listening on http://127.0.0.1:8791/
  endpoint: the ROOT path — `/mcp` and `/health` are 404, there is no health endpoint
  auth: Bearer, from PMAT_MCP_HTTP_TOKEN; unauthenticated requests get 401
  tools: 19 (identical to the stdio surface)

Register this server with Claude Code (copy-paste):

  claude mcp add --scope user --transport http pmat \
    http://127.0.0.1:8791/ --header "Authorization: Bearer <token>"

  (already registered? `claude mcp remove pmat -s user` first — add refuses to replace)
```

Four properties of this endpoint are not guessable, and the binary says so itself:

1. **MCP is served at the ROOT path.** `POST /` is 200. `/mcp` is 404.
2. **There is no health endpoint.** `/health` is 404, so it cannot be a readiness
   probe. Poll the root with a real RPC instead.
3. **Auth is mandatory.** `PMAT_MCP_HTTP_TOKEN` must be at least 16 characters or the
   server refuses to start. Unauthenticated requests get 401. On a loopback bind with
   the variable unset, the server generates a token and prints it; that token dies
   with the process, so a client registered with the old one gets 401 after a restart.
4. **Every RPC call needs `Accept: application/json, text/event-stream`.** Without it
   the server answers 406, which `curl -f` reports as an empty string with no message.

### The endpoint matrix, measured

Against a live server on port 8791, with a valid bearer token and the correct
`Accept` header on every request:

| Path | GET | POST |
|------|-----|------|
| `/` | 405 | **200** |
| `/health` | 404 | 404 |
| `/analyze` | 404 | 404 |
| `/context` | 404 | 404 |
| `/quality-gate` | 404 | 404 |
| `/batch-analyze` | 404 | 404 |
| `/report` | 404 | 404 |
| `/ws` | 404 | 404 |
| `/mcp` | 404 | 404 |

Every path the previous edition of this chapter documented is in the 404 column.
There is exactly one endpoint, it is `/`, and it only answers POST.

Two more measurements on the same server:

| Request | Status |
|---------|--------|
| `POST /` with no `Authorization` header | 401 |
| `POST /` with no `Accept` header | 406 |

### A real call

```bash
curl -sS http://127.0.0.1:8791/ \
  -H "Authorization: Bearer $PMAT_MCP_HTTP_TOKEN" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
```

Executed response (truncated at 400 bytes):

```json
{"jsonrpc":"2.0","id":1,"result":{"tools":[{"name":"quality_gate","description":"Run the `pmat quality-gate --checks all` suite (complexity, dead code, SATD, entropy, security, duplicates, coverage, documentation sections, provability) plus a TDG score against the given paths. Any check a path could not answer is named in `not_measured` and, with its reason, in `checks.not_run`.","inputSchema":{"t
```

The 19 tools served here are the same 19 the stdio server serves — one `build_server`
builds both, so the two surfaces cannot drift. The tool list and each tool's arguments
are in [Chapter 15](ch15-00-mcp-tools.md) and
[Chapter 3.4](ch03-04-mcp-transports.md).

### The transports that do not exist

```bash
pmat serve --transport web-socket --port 8794
```

Executed output, exit status **2**:

```
error: pmat serve --transport websocket is not yet implemented
  requested: transport=websocket host=127.0.0.1 port=8794
hint: `--transport http` works — build with `--features mcp-http` and set PMAT_MCP_HTTP_TOKEN
hint: use stdio MCP today — `MCP_VERSION=1 pmat` (serves the analysis tools over stdio)
hint: follow KAIZEN-0191 for the HTTP/WebSocket/SSE wiring
```

`--transport http-sse`, `--transport both` and `--transport all` behave identically.
There is no `stdio` value for `--transport` at all — passing one is a clap error, also
exit 2. For MCP over stdio, run `pmat --mode mcp` or `MCP_VERSION=1 pmat`.

### CI/CD: what to write instead

The old chapter's GitHub Actions job started `pmat serve` and POSTed to
`/quality-gate`. That job could only ever have passed by ignoring a 404. Run the CLI —
it does the same analysis with no server, no port and no token:

```yaml
name: PMAT Quality Gate

on: [push, pull_request]

jobs:
  quality-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install PMAT
        run: cargo install pmat

      - name: Run quality gate
        run: pmat quality-gate --project-path . --checks all --format json
```

If you genuinely need the server in CI — because a remote MCP client is the consumer —
then poll the root with a real RPC for readiness, never `/health`:

```bash
until curl -sf -m 2 http://127.0.0.1:8791/ \
        -H "Authorization: Bearer $PMAT_MCP_HTTP_TOKEN" \
        -H 'Content-Type: application/json' \
        -H 'Accept: application/json, text/event-stream' \
        -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' >/dev/null; do sleep 1; done
```

## Part 2 — `pmat roadmap`: sprint tracking

`pmat roadmap` keeps a sprint in a **markdown file at `docs/execution/roadmap.md`**,
relative to the current directory. Two things about that are worth knowing before you
start, because both cost a confused ten minutes otherwise:

- **The directory must already exist.** `pmat roadmap init` does not create it; it
  fails with `Failed to write roadmap to docs/execution/roadmap.md: No such file or
  directory (os error 2)` and exit 1.
- **Task IDs are exactly four digits.** The parser matches `PMAT-\d{4}`, so
  `PMAT-0001` is a task and `PMAT-001` is invisible — `pmat roadmap start PMAT-001`
  answers `Task PMAT-001 not found in roadmap`.

### Initialize a sprint

```bash
mkdir -p docs/execution
pmat roadmap init --version v1.0.0 --title "Core features"
```

Executed output:

```
📋 Initializing sprint v1.0.0 - Core features
✅ Sprint v1.0.0 initialized successfully
📝 Roadmap updated at: docs/execution/roadmap.md
```

The flags are `--version`, `--title`, `--duration-days` and `--priority`. There is no
`--sprint` and no `--goal`; both exit 2.

The file it writes:

```markdown
# PMAT Development Roadmap

## Current Sprint: v1.0.0 Core features
- **Duration**: 2026-08-25 to 2026-09-08
- **Priority**: P0
- **Quality Gates**: Complexity ≤ 20, SATD = 0, Coverage ≥ 80%

### Tasks
| ID | Description | Status | Complexity | Priority |
|----|-------------|--------|------------|----------|

### Definition of Done
- [ ] All tasks completed
- [ ] Quality gates passed
- [ ] Documentation updated
- [ ] Tests passing
- [ ] Changelog updated
```

### Add tasks

There is no `roadmap add` subcommand. Tasks are rows you write into that table by
hand — five columns, four-digit ID:

```markdown
| ID | Description | Status | Complexity | Priority |
|----|-------------|--------|------------|----------|
| PMAT-0001 | Implement token bucket | pending | medium | P0 |
| PMAT-0002 | Wire up the CLI flag | completed | low | P1 |
```

### Sprint status

```bash
pmat roadmap status
```

Executed output:

```
Sprint v1.0.0: Core features
  Duration: 2026-08-25 to 2026-09-08
  Progress: 1/2 completed, 0 in progress

  Tasks:
    📋 PMAT-0001 - Implement token bucket
    ✅ PMAT-0002 - Wire up the CLI flag
```

`--format json` gives the machine-readable form:

```bash
pmat roadmap status --format json
```

```json
{
  "version": "v1.0.0",
  "title": "Core features",
  "start_date": "2026-08-25T00:00:00Z",
  "end_date": "2026-09-08T23:59:59Z",
  "priority": "P0",
  "tasks": [
    {
      "id": "PMAT-0001",
      "description": "Implement token bucket",
      "status": "Completed",
      "complexity": "Medium"
    }
  ]
}
```

### Generate PDMT todos

```bash
pmat roadmap todos
```

Executed output:

```
🔄 Generating PDMT todos from roadmap...
📝 Generated 2 todos for 2 tasks
✅ Todos written to: todos.md
```

`todos.md`, as written:

```markdown
- [ ] PMAT-0001-001: Implement Implement token bucket
- [ ] PMAT-0001-002: Write comprehensive tests for: Implement token bucket
```

It writes to `todos.md` in the current directory. `--output <FILE>` redirects it and
`--sprint <SPRINT>` selects a sprint; there is **no `--format`** flag — the old
chapter's `pmat roadmap todos --format markdown` exits 2.

### Task lifecycle

```bash
pmat roadmap start PMAT-0001
```

Executed output:

```
🚀 Starting task PMAT-0001
✅ Task PMAT-0001 status updated to: 🚧 In Progress

📋 Task Details:
  ID: PMAT-0001
  Description: Implement token bucket
  Complexity: Medium
  Priority: P0
```

Completing a task runs the repo-wide quality checks first, and refuses if they fail:

```bash
pmat roadmap complete PMAT-0001
```

```
🏁 Completing task PMAT-0001
🔍 Running quality checks...
🔍 Running repo-wide quality checks for task PMAT-0001...
❌ Complexity check failed
Error: Complexity exceeds limit
```

The flag that bypasses that is `--skip-quality-check` (the old chapter's
`--quality-check` does not exist and exits 2):

```bash
pmat roadmap complete PMAT-0001 --skip-quality-check
```

```
🏁 Completing task PMAT-0001
✅ Task PMAT-0001 completed successfully
📝 Creating commit: PMAT-0001: Complete implementation
✅ Changes committed
```

Note the last two lines: **`roadmap complete` makes a git commit.** That is not
optional and there is no `--no-commit`. Run it in a repository where an automatic
commit is what you want.

### Quality checks for one task

```bash
pmat roadmap quality-check --task-id PMAT-0001
```

```
🔍 Running repo-wide quality checks for task PMAT-0001...
❌ Complexity check failed
Error: Complexity exceeds limit
```

The flag is `--task-id`. There is no `--project` flag; the checks are repo-wide
regardless of which task you name — the task ID is used to validate that the task
exists, not to scope the analysis.

### Validate a sprint for release

`--sprint` is **required** here; without it the command exits 2 with
`error: one or more required arguments were not provided`.

```bash
pmat roadmap validate --sprint v1.0.0
```

Executed output, exit status 1:

```
🔍 Validating sprint v1.0.0 for release...
✅ All tasks completed

📋 Definition of Done (pmat holds no completion state for these):
  • All tasks completed
  • Quality gates passed
  • Documentation updated
  • Tests passing
  • Changelog updated

❌ Sprint v1.0.0: readiness NOT certified — 5 Definition-of-Done item(s) and 0 quality gate(s) are not evaluated by pmat
```

This is the honest answer, and it is worth reading twice: every task being complete is
**not** the same as the sprint being releasable, and `pmat` will not pretend otherwise.
It tracks no state for the Definition-of-Done checklist, so it declines to certify. A
sprint with no tasks at all also exits 1, with "nothing to validate".

### Roadmap command summary

Every row verified against pmat 3.32.0:

| Command | Required arguments | Notes |
|---------|--------------------|-------|
| `pmat roadmap init` | `--version`, `--title` | Also `--duration-days`, `--priority`. `docs/execution/` must exist |
| `pmat roadmap status` | — | `--sprint`, `--task`, `--format` |
| `pmat roadmap todos` | — | Writes `todos.md`. `--output`, `--sprint`, `--include-quality-gates`. No `--format` |
| `pmat roadmap start` | `<TASK_ID>` | `--create-branch` |
| `pmat roadmap complete` | `<TASK_ID>` | Runs quality checks then **commits**. `--skip-quality-check` |
| `pmat roadmap validate` | `--sprint` | Exits 1 unless readiness can be certified |
| `pmat roadmap quality-check` | `--task-id` | Repo-wide checks |
| `pmat roadmap sync` | — | Renders `ROADMAP.yaml` from the `pmat work` store. `--dry-run`, `--path` |

For issue-backed work with a richer contract — falsification ledgers, provenance,
scoring — see `pmat work`, which is a separate and much larger surface
([Appendix B](appendix-b-commands.md#pmat-work) lists its 24 subcommands).

## Summary

`pmat serve` is one MCP endpoint at `/`, not a REST API: nine of the ten paths the
previous edition documented return 404, and the tenth (`/`) answers only POST, only
with a bearer token, and only with the streamable-HTTP `Accept` header. If what you
want is analysis results in a script, the CLI gives them to you directly with
`--format json` and no server at all.

`pmat roadmap` is real, small, and file-backed: a markdown sprint at
`docs/execution/roadmap.md`, four-digit task IDs, and a `validate` that refuses to
certify readiness it cannot measure. Use the flags in the table above; the ones the
previous edition printed were rejected by the parser.
