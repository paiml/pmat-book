# Chapter 15: Complete MCP Tools Reference

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ Rebuilt from `tools/list` on pmat 3.32.0

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 19 | Every tool the server actually exposes, read from `tools/list` |
| ⚠️ Not Implemented | 3 | WebSocket, HTTP-SSE and "background daemon" transports |
| ❌ Broken | 0 | — |
| 📋 Planned | 0 | — |

*Last updated: 2026-08-25*
*PMAT version: pmat 3.32.0*
*MCP protocol: 2024-11-05*
<!-- DOC_STATUS_END -->

> **⚠️ Historical warning, as of pmat 3.32.0 (2026-08-25). The previous edition of
> this chapter documented 36 MCP tools. Thirty-one of them do not exist.**
>
> That edition described `pmat 2.213.1`, was marked `✅ 100% Working (8/8 examples)`,
> and claimed "All tools tested and verified". Asking the running server what it
> serves — `tools/list`, the one authoritative question — returns **19 tools**, of
> which only five (`analyze_complexity`, `analyze_dead_code`, `analyze_satd`,
> `generate_context`, `scaffold_project`) appeared in that list. Calling any of the
> other thirty-one gets you:
>
> ```json
> {"code":-32602,"message":"Resource not found: Tool 'analyze_duplicates' not found"}
> ```
>
> Two more claims in that edition were the opposite of the truth:
>
> - **The transport matrix was false.** It advertised HTTP, WebSocket and SSE modes
>   with `✅ Claude Desktop: Supported` on every row. `--transport web-socket` and
>   `--transport http-sse` exit **2** with "not yet implemented", and there is no
>   Claude Desktop support for either because neither binds a socket.
> - **There is no "background daemon" mode.** `pmat agent` is not in the build you
>   get from `cargo install pmat`.
>
> The real transports — stdio and streamable HTTP — are documented in
> [Chapter 3.4: MCP Transports](ch03-04-mcp-transports.md), which is current and
> verified. This chapter no longer duplicates it; it is the **tool** reference, and
> the tool list below is read out of the server rather than written down.

## The Problem

An MCP tool reference has one job: tell you what you can call and what to pass it. It
is also the single easiest kind of documentation to get wrong, because a tool list is
invisible — nothing fails to compile when a tool is renamed, and a chapter that
invents `analyze_maintainability_index` reads exactly like one that does not.

The fix is not to write the list more carefully. It is to **ask the server**. Every
tool name, argument name, type and requirement in this chapter came out of a live
`tools/list` response from `pmat 3.32.0`, and you can reproduce the whole list in one
command.

## Asking the server yourself

The tool list is one JSON-RPC call. Over stdio:

```bash
{ echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"book","version":"1"}}}';
  echo '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'; } \
  | pmat --mode mcp
```

The `initialize` response, executed:

```json
{"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2024-11-05","capabilities":{"tools":{"listChanged":true}},"serverInfo":{"name":"paiml-mcp-agent-toolkit","version":"3.32.0"}}}
```

To see just the names:

```bash
{ echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"b","version":"1"}}}';
  echo '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'; } \
  | pmat --mode mcp | tail -1 | jq -r '.result.tools[].name'
```

If that list differs from the table below, believe the server: your `pmat` is a
different version, and this chapter is stale.

For how to *connect* — stdio versus streamable HTTP, registration with Claude Code,
tokens, headers — see [Chapter 3.4](ch03-04-mcp-transports.md), or run:

```bash
pmat mcp connect
```

## The 19 tools

| Tool | Required | Optional | What it does |
|------|----------|----------|--------------|
| `analyze_big_o` | `paths` | `top_files` | Classify the Big-O time complexity of functions in the given paths. |
| `analyze_complexity` | `paths` | `top_files`, `threshold` | Analyze cyclomatic and cognitive complexity for source files. |
| `analyze_dag` | `paths` | `dag_type` | Generate a project dependency graph (call graph, import graph, inheritance, or full dependency DAG). |
| `analyze_dead_code` | `paths` | `include_tests` | Find unreachable or unused code (functions, types, or modules). |
| `analyze_deep_context` | `paths` | — | Run the full deep-context analysis pipeline (AST, complexity, churn, dead code) over the given paths. |
| `analyze_hardcoded_paths` | `project_path` | — | Find machine-specific absolute paths baked into source (a user's home, a nix store hash, a build root) — correct where they were written, inert everywhere else. |
| `analyze_reachability` | `project_path` | — | Report tracked .rs files that no compilation unit reaches — orphaned modules that compile to nothing and whose tests never run. |
| `analyze_satd` | `paths` | `include_resolved`, `include_tests` | Detect self-admitted technical debt (TODO, FIXME, HACK markers) in source code. |
| `analyze_vacuous_tests` | `project_path` | — | Find #[test] functions that cannot fail — no assertion, an assertion over constants, or a body that silently returns when a fixture is missing. |
| `generate_context` | `paths` | `format`, `max_depth`, `include_dependencies` | Generate project context (file tree + optional dependency graph) for LLM/agent consumption. |
| `git_operation` | `path` | — | Query git working-tree status for the given repository path. |
| `pdmt_deterministic_todos` | `requirements` | `project_name`, `granularity`, `quality_config` | Generate deterministic, quality-enforced todo lists from a list of requirements. |
| `pmat_find_similar` | `function_id` | `limit`, `min_similarity` | Find functions similar to a reference function. Useful for finding related code, potential duplicates, or implementations of similar patterns. |
| `pmat_get_function` | `function_id` | `include_source` | Get detailed information about a specific function by its ID. Returns full function metadata including source code, quality metrics, and SATD markers. |
| `pmat_index_stats` | — | `rebuild` | Get statistics about the code index including function counts, quality distribution, and index health. |
| `pmat_query_code` | `query` | `limit`, `min_grade`, `max_complexity`, `language`, `path_pattern`, `include_source`, `rebuild_index` | Search code functions by natural language query with TDG quality filtering. Returns semantically ranked results with complexity, fault patterns, and call graph context. |
| `quality_gate` | `paths` | `strict`, `file` | Run the `pmat quality-gate --checks all` suite (complexity, dead code, SATD, entropy, security, duplicates, coverage, documentation sections, provability) plus a TDG score against the given paths. Any check a path could not answer is named in `not_measured` and, with its reason, in `checks.not_run`. |
| `quality_proxy` | `operation`, `file_path` | `content`, `old_content`, `new_content`, `mode`, `quality_config` | Proxy a file operation (write/edit/append) through the quality gate, optionally auto-fixing violations. |
| `scaffold_project` | `paths` | `level` | Produce a high-level project summary scaffold for the given paths. |

Three things to notice, because they are the common trip-ups:

- **`paths` is an array, and it is required** on most tools. A bare string is a
  validation error, and so is omitting it — see [Error shapes](#error-shapes) below.
- **Three tools take `project_path` (a single string) instead** —
  `analyze_hardcoded_paths`, `analyze_reachability` and `analyze_vacuous_tests`. They
  want a project root, not a file list.
- **The `pmat_*` four are the index/search surface**: `pmat_query_code`,
  `pmat_get_function`, `pmat_find_similar` and `pmat_index_stats`. They are the MCP
  equivalent of `pmat query`, and they are the tools an agent should reach for first
  when exploring an unfamiliar codebase.

## Argument reference

#### `analyze_big_o`

Classify the Big-O time complexity of functions in the given paths.

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `paths` | array | yes | Filesystem paths (files or directories) to analyze |
| `top_files` | integer | no | Return only the top N files by algorithmic complexity |

#### `analyze_complexity`

Analyze cyclomatic and cognitive complexity for source files.

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `paths` | array | yes | Filesystem paths (files or directories) to analyze |
| `top_files` | integer | no | Return only the top N most-complex files |
| `threshold` | integer | no | Minimum cyclomatic complexity to report |

#### `analyze_dag`

Generate a project dependency graph (call graph, import graph, inheritance, or full dependency DAG).

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `paths` | array | yes | Filesystem paths (files or directories) to analyze |
| `dag_type` | string | no | Dependency graph type to generate (default: full-dependency) |

#### `analyze_dead_code`

Find unreachable or unused code (functions, types, or modules).

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `paths` | array | yes | Filesystem paths (files or directories) to analyze |
| `include_tests` | boolean | no | Include test files when searching for dead code |

#### `analyze_deep_context`

Run the full deep-context analysis pipeline (AST, complexity, churn, dead code) over the given paths.

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `paths` | array | yes | Filesystem paths (files or directories) to analyze |

#### `analyze_hardcoded_paths`

Find machine-specific absolute paths baked into source (a user's home, a nix store hash, a build root) — correct where they were written, inert everywhere else.

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `project_path` | string | yes | Project root to analyze (the directory holding Cargo.toml / the git worktree) |

#### `analyze_reachability`

Report tracked .rs files that no compilation unit reaches — orphaned modules that compile to nothing and whose tests never run.

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `project_path` | string | yes | Project root to analyze (the directory holding Cargo.toml / the git worktree) |

#### `analyze_satd`

Detect self-admitted technical debt (TODO, FIXME, HACK markers) in source code.

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `paths` | array | yes | Filesystem paths (files or directories) to analyze |
| `include_resolved` | boolean | no | Include items already marked resolved |
| `include_tests` | boolean | no | Include test files and #[cfg(test)] blocks (default: false, matching `pmat analyze satd`) |

#### `analyze_vacuous_tests`

Find #[test] functions that cannot fail — no assertion, an assertion over constants, or a body that silently returns when a fixture is missing.

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `project_path` | string | yes | Project root to analyze (the directory holding Cargo.toml / the git worktree) |

#### `generate_context`

Generate project context (file tree + optional dependency graph) for LLM/agent consumption.

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `paths` | array | yes | Filesystem paths (files or directories) to analyze |
| `format` | string | no | Output format |
| `max_depth` | integer | no | Max directory-tree depth to include |
| `include_dependencies` | boolean | no | Include dependency graph |

#### `git_operation`

Query git working-tree status for the given repository path.

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `path` | string | yes | Path to the git repository to query |

#### `pdmt_deterministic_todos`

Generate deterministic, quality-enforced todo lists from a list of requirements.

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `requirements` | array | yes | Requirements to convert into deterministic actionable todos |
| `project_name` | string | no | Project or component name |
| `granularity` | string | no | Task detail level (default: high) |
| `quality_config` | object | no | Quality enforcement config |

#### `pmat_find_similar`

Find functions similar to a reference function. Useful for finding related code, potential duplicates, or implementations of similar patterns.

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `function_id` | string | yes | Function ID to find similar functions for |
| `limit` | integer | no | Maximum number of similar functions (default: 5, max: 20) |
| `min_similarity` | number | no | Minimum similarity score (0.0-1.0, default: 0.3) |

#### `pmat_get_function`

Get detailed information about a specific function by its ID. Returns full function metadata including source code, quality metrics, and SATD markers.

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `function_id` | string | yes | Function ID from pmat_query_code results (e.g., 'src/handlers/auth.rs::handle_login') |
| `include_source` | boolean | no | Include full source code (default: true) |

#### `pmat_index_stats`

Get statistics about the code index including function counts, quality distribution, and index health.

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `rebuild` | boolean | no | Rebuild the index before returning stats (default: false) |

#### `pmat_query_code`

Search code functions by natural language query with TDG quality filtering. Returns semantically ranked results with complexity, fault patterns, and call graph context.

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `query` | string | yes | Natural language search query describing the code intent. |
| `limit` | integer | no | Maximum number of results to return. |
| `min_grade` | string | no | Minimum TDG grade filter (A+ is best). Case-insensitive. |
| `max_complexity` | integer | no | Maximum cyclomatic complexity filter. |
| `language` | string | no | Language filter. |
| `path_pattern` | string | no | Path glob pattern filter. |
| `include_source` | boolean | no | Include source code in results. |
| `rebuild_index` | boolean | no | Force index rebuild before query. |

#### `quality_gate`

Run the `pmat quality-gate --checks all` suite (complexity, dead code, SATD, entropy, security, duplicates, coverage, documentation sections, provability) plus a TDG score against the given paths. Any check a path could not answer is named in `not_measured` and, with its reason, in `checks.not_run`.

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `paths` | array | yes | Filesystem paths (files or directories) to analyze |
| `strict` | boolean | no | Fail the gate on any violation (no tolerance) |
| `file` | string | no | Check only this single file instead of the paths list |

#### `quality_proxy`

Proxy a file operation (write/edit/append) through the quality gate, optionally auto-fixing violations.

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `operation` | string | yes | File operation to proxy |
| `file_path` | string | yes | Target file path |
| `content` | string | no | New content for `write`/`append` |
| `old_content` | string | no | Old string for `edit` operations |
| `new_content` | string | no | New string for `edit` operations |
| `mode` | string | no | Proxy enforcement mode |
| `quality_config` | object | no | — |

#### `scaffold_project`

Produce a high-level project summary scaffold for the given paths.

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `paths` | array | yes | Filesystem paths (files or directories) to analyze |
| `level` | string | no | Summary detail level |

## Verified calls

Every response below was produced by piping the request into `pmat --mode mcp` against
a two-file Rust fixture. Responses are truncated where noted; nothing is edited.

### `analyze_complexity`

```json
{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"analyze_complexity","arguments":{"paths":["/path/to/fixture"]}}}
```

Response — note that the payload arrives as a **JSON string inside `content[0].text`**,
not as a JSON object; a client has to parse it twice:

```json
{"content":[{"type":"text","text":"{\"status\":\"completed\",\"message\":\"Complexity analysis completed\",\"results\":{\"total_files\":1,\"files_analyzed\":1,\"total_complexity\":7,\"average_complexity\":7,\"violations\":[],\"top_files\":[{\"file\":\"…/src/main.rs\",\"function\":\"classify\",\"cyclomatic_complexity\":5,\"cognitive_complexity\":5,\"line_start\":2,\"line_end\":12}]}}"}],"isError":false}
```

### `analyze_satd`

```json
{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"analyze_satd","arguments":{"paths":["/path/to/fixture"]}}}
```

Decoded `content[0].text`:

```json
{"status":"completed","message":"SATD analysis completed","results":{"total_satd":1,"files":[{"file":"…/src/main.rs","satd_count":1,"debts":[{"line":1,"category":"Requirement","severity":"Low","text":"TODO: this is a self-admitted technical debt marker"}]}],"files_discovered":1,"files_analyzed":1,"census_balances":true,"files_unaccounted":0}}
```

`census_balances` and `files_unaccounted` are worth wiring into any agent that uses
this tool: they say whether every file the walker discovered was actually read. A
count of debts is only meaningful next to a count of files that were looked at.

### `quality_gate`

```json
{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"quality_gate","arguments":{"paths":["/path/to/fixture"]}}}
```

Decoded `content[0].text`, truncated:

```json
{"status":"completed","message":"Quality gate check completed (standard mode)","passed":false,"score":90.0,"grade":"A","not_measured":["coverage","sections"],"checks":{"ran":["complexity","dead-code","satd","entropy","security","duplicates","provability"],"not_run":[{"check":"coverage","path":"…","reason":"no coverage report at .pmat/coverage-cache.json or .pmat-metrics/coverage.json, so this gate does not cover coverage"},{"check":"sections","path":"…","reason":"no README.md, so there is nothing for the documentation-sections check to read"}]}}
```

This is the most useful response shape on the server, and the one to model an agent
around: `not_measured` names every check that could not run, and `checks.not_run`
gives the reason for each. A gate that "passed" while silently skipping coverage is
the failure mode this structure exists to prevent — read `not_measured` before you
believe `passed`.

## Error shapes

Two errors account for nearly everything, and both come back as JSON-RPC errors
(no `result`), not as `isError` results.

**Unknown tool** — including all thirty-one tools the previous edition documented:

```json
{"jsonrpc":"2.0","id":4,"error":{"code":-32602,"message":"Resource not found: Tool 'analyze_duplicates' not found"}}
```

**Missing required argument:**

```json
{"jsonrpc":"2.0","id":6,"error":{"code":-32602,"message":"Validation error: Invalid arguments: missing field `paths`"}}
```

**Wrong type** — `paths` given as a string rather than an array:

```json
{"jsonrpc":"2.0","id":2,"error":{"code":-32602,"message":"Validation error: Invalid arguments: invalid type: string \"/tmp\", expected a sequence"}}
```

All three are `-32602` (invalid params), so a client cannot distinguish "no such tool"
from "bad arguments" by code alone — it has to read the message.

## Tools earlier editions documented that do not exist

All thirty-one return `-32602 ... not found`. Where the right column names a CLI
command, that command is real and was verified to resolve; where it says *nothing*,
the capability does not exist in pmat 3.32.0 in any form.

| Documented tool (fiction) | Nearest real thing |
|---------------------------|--------------------|
| `analyze_duplicates` | `pmat analyze duplicates` on the CLI |
| `analyze_churn` | `pmat analyze churn` on the CLI |
| `analyze_dependencies` | `analyze_dag` |
| `analyze_security` | `quality_gate` (its `security` check) |
| `analyze_performance` | `analyze_big_o` |
| `analyze_lint_hotspots` | `pmat analyze lint-hotspot` on the CLI |
| `analyze_coupling` | `analyze_dag`, or `pmat analyze graph-metrics` on the CLI |
| `analyze_context` | `generate_context` |
| `analyze_provability` | `quality_gate` (its `provability` check) |
| `analyze_entropy` | `quality_gate` (its `entropy` check) |
| `analyze_graph_metrics` | `pmat analyze graph-metrics` on the CLI |
| `analyze_big_o_complexity` | `analyze_big_o` — the name is shorter |
| `analyze_cognitive_load` | `analyze_complexity` reports cognitive complexity |
| `analyze_maintainability_index` | nothing — no such metric is exposed |
| `generate_deep_context` | `analyze_deep_context` |
| `generate_comprehensive_report` | `pmat report` on the CLI |
| `tdg_analyze_with_storage` | `quality_gate` returns a TDG score and grade |
| `check_quality_gates` | `quality_gate` |
| `check_quality_gate_file` | `quality_gate` with its `file` argument |
| `quality_gate_summary` | `quality_gate` |
| `quality_gate_baseline` | `pmat tdg baseline` on the CLI |
| `quality_gate_compare` | `pmat tdg compare` on the CLI |
| `git_status` | `git_operation` |
| `list_templates` | `pmat list` on the CLI |
| `create_agent_template` | `pmat scaffold agent` on the CLI |
| `manage_templates` | nothing — templates are CLI-only |
| `system_diagnostics` | `pmat diagnose` on the CLI |
| `cache_management` | `pmat cache stats` on the CLI |
| `configuration_manager` | `pmat config --show` on the CLI |
| `health_monitor` | nothing — there is no health tool and no health endpoint |
| `background_daemon` | nothing — `pmat agent` is not in the shipped build |

## Transports: what is real

The previous edition's capability matrix advertised four server modes. Measured
against 3.32.0:

| Mode | Real? | Evidence |
|------|-------|----------|
| **stdio** | ✅ Yes | `pmat --mode mcp` or `MCP_VERSION=1 pmat`. 19 tools. No port, no token |
| **Streamable HTTP** | ✅ Yes | `pmat serve --transport http`. Same 19 tools, served at the **root** path with mandatory bearer auth |
| WebSocket | ❌ No | `--transport web-socket` exits 2: "not yet implemented" |
| HTTP-SSE | ❌ No | `--transport http-sse` exits 2: "not yet implemented" |
| Background daemon | ❌ No | `pmat agent` is `[NOT AVAILABLE in the default build]` |

Both real transports are built by the same `build_server`, so the tool surface cannot
drift between them. The details — ports, tokens, the `Accept` header the streamable
transport requires, and the exact `claude mcp add` line — are in
[Chapter 3.4](ch03-04-mcp-transports.md) and, for the HTTP endpoint's measured
behaviour, [Chapter 18](ch18-00-api.md).

## Registering with a client

One command prints every registration form, for the port it actually bound:

```bash
pmat mcp connect
```

For Claude Code with the stdio transport, that is:

```bash
claude mcp add --scope user pmat -- pmat --mode mcp
```

There is no `pmat mcp-server` subcommand and no `"args": []` registration — a bare
`pmat` with no subcommand prints help and exits 2 rather than starting a server. See
[Chapter 64](ch64-00-mcp-mode.md) for the history of that change.

## Summary

`pmat` exposes **19 MCP tools** over two real transports, and the authoritative list is
`tools/list` — not this chapter, and not any chapter. The tools divide into analysis
(`analyze_*`), context generation, the quality gate and its write-time proxy, the
four-tool code index (`pmat_*`), and a small scaffolding/git surface.

The previous edition of this chapter is the best argument in the book for asking the
server: it documented 36 tools, in confident detail, with request and response schemas
for each — and 31 of them had never existed. Every response shape shown above was
produced by running the call.
