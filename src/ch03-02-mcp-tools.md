# MCP Tools

**Chapter Status**: Working (20/20 tools on the `tools/list` surface documented)

*Last updated: 2026-10-05*
*PMAT version: pmat 3.42.0*

## Overview

`pmat --mode mcp` serves **20 tools** over JSON-RPC 2.0 on stdio. This chapter
lists every one of them, and only them. The list below is the server's own
`tools/list` answer, and `tests/ch03/test_03_mcp_tool_inventory.sh` compares the
`####` headings in this file against that answer in both directions. A tool the
binary drops, or a heading for a tool it does not serve, fails the test.

Earlier revisions of this chapter (pinned to pmat 2.215.0) documented 25 tools,
20 of which the server does not have: `validate_documentation`, `check_claim`,
`semantic_search`, the `deep_wasm_*` family and others. Calling any of them
returns a hard error; see [Error Handling](#error-handling).

### Ask the binary

The inventory is a question the server answers, so ask it rather than trusting
any copy, including this one:

```bash
printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"probe","version":"1"}}}' \
  '{"jsonrpc":"2.0","method":"notifications/initialized"}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' \
  | pmat --mode mcp 2>/dev/null \
  | jq -r 'select(.id==2) | .result.tools[].name'
```

## Tool Categories

### Code Search (4 tools)

Semantic search over pmat's function index, with TDG grades and complexity on
every result. `pmat_query_code` returns function IDs; the other three take one.

#### `pmat_query_code`

Search code functions by natural language query with TDG quality filtering. Returns semantically ranked results with complexity, fault patterns, and call graph context.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `query` | string | yes | Natural language search query describing the code intent. |
| `limit` | integer | no | Maximum number of results to return. |
| `min_grade` | string | no | Minimum TDG grade filter (A+ is best). Case-insensitive. One of: `A+`, `A`, `A-`, `B+`, `B`, `B-`, `C+`, `C`, `C-`, `D`, `F`. |
| `max_complexity` | integer | no | Maximum cyclomatic complexity filter. |
| `language` | string | no | Language filter. One of: `rust`, `typescript`, `python`, `go`, `java`, `c`, `cpp`. |
| `path_pattern` | string | no | Path glob pattern filter. |
| `include_source` | boolean | no | Include source code in results. |
| `rebuild_index` | boolean | no | Force index rebuild before query. |

#### `pmat_get_function`

Get detailed information about a specific function by its ID. Returns full function metadata including source code, quality metrics, and SATD markers.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `function_id` | string | yes | Function ID from pmat_query_code results (e.g., 'src/handlers/auth.rs::handle_login') |
| `include_source` | boolean | no | Include full source code (default: true) |

#### `pmat_find_similar`

Find functions similar to a reference function. Useful for finding related code, potential duplicates, or implementations of similar patterns.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `function_id` | string | yes | Function ID to find similar functions for |
| `limit` | integer | no | Maximum number of similar functions (default: 5, max: 20) |
| `min_similarity` | number | no | Minimum similarity score (0.0-1.0, default: 0.3) |

#### `pmat_index_stats`

Get statistics about the code index including function counts, quality distribution, and index health.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `rebuild` | boolean | no | Rebuild the index before returning stats (default: false) |

### Analysis (9 tools)

Each runs one analyzer over the given paths or project root and returns its report as JSON text.

#### `analyze_complexity`

Analyze cyclomatic and cognitive complexity for source files.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `paths` | array | yes | Filesystem paths (files or directories) to analyze |
| `top_files` | integer | no | Return only the top N most-complex files |
| `threshold` | integer | no | Minimum cyclomatic complexity to report |

#### `analyze_big_o`

Classify the Big-O time complexity of functions in the given paths.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `paths` | array | yes | Filesystem paths (files or directories) to analyze |
| `top_files` | integer | no | Return only the top N files by algorithmic complexity |

#### `analyze_dag`

Generate a project dependency graph (call graph, import graph, inheritance, or full dependency DAG).

| Parameter | Type | Required | Description |
|---|---|---|---|
| `paths` | array | yes | Filesystem paths (files or directories) to analyze |
| `dag_type` | string | no | Dependency graph type to generate (default: full-dependency) One of: `call-graph`, `import-graph`, `inheritance`, `full-dependency`. |

#### `analyze_dead_code`

Find unreachable or unused code (functions, types, or modules).

| Parameter | Type | Required | Description |
|---|---|---|---|
| `paths` | array | yes | Filesystem paths (files or directories) to analyze |
| `include_tests` | boolean | no | Include test files when searching for dead code |

#### `analyze_deep_context`

Run the full deep-context analysis pipeline (AST, complexity, churn, dead code) over the given paths.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `paths` | array | yes | Filesystem paths (files or directories) to analyze |

#### `analyze_satd`

Detect self-admitted technical debt (TODO, FIXME, HACK markers) in source code.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `paths` | array | yes | Filesystem paths (files or directories) to analyze |
| `include_resolved` | boolean | no | Include items already marked resolved |
| `include_tests` | boolean | no | Include test files and #[cfg(test)] blocks (default: false, matching `pmat analyze satd`) |

#### `analyze_hardcoded_paths`

Find machine-specific absolute paths baked into source (a user's home, a nix store hash, a build root) — correct where they were written, inert everywhere else.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `project_path` | string | yes | Project root to analyze (the directory holding Cargo.toml / the git worktree) |

#### `analyze_reachability`

Report tracked .rs files that no compilation unit reaches — orphaned modules that compile to nothing and whose tests never run.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `project_path` | string | yes | Project root to analyze (the directory holding Cargo.toml / the git worktree) |

#### `analyze_vacuous_tests`

Find #[test] functions that cannot fail — no assertion, an assertion over constants, or a body that silently returns when a fixture is missing.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `project_path` | string | yes | Project root to analyze (the directory holding Cargo.toml / the git worktree) |

### Quality Gating (3 tools)

`quality_gate` grades files already on disk. `quality_check_content` and `quality_proxy` grade *proposed* content before it is written; they share one description and one schema.

#### `quality_gate`

Run the `pmat quality-gate --checks all` suite (complexity, dead code, SATD, entropy, security, duplicates, coverage, documentation sections, provability) plus a TDG score against the given paths. Any check a path could not answer is named in `not_measured` and, with its reason, in `checks.not_run`.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `paths` | array | yes | Filesystem paths (files or directories) to analyze |
| `strict` | boolean | no | Fail the gate on any violation (no tolerance) |
| `file` | string | no | Check only this single file instead of the paths list |

#### `quality_check_content`

Grade proposed file content against the project's quality gate (complexity, SATD, docs, lint) and return it with a verdict. Never touches the filesystem: hand the returned content to your own file tool, or let the harness PreToolUse hook gate the change.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `file_path` | string | yes | Path the content is destined for (decides the language and the project's pmat.toml) |
| `content` | string | yes | The proposed file content to grade |
| `mode` | string | no | Proxy enforcement mode One of: `strict`, `advisory`, `auto_fix`, `auto-fix`. |
| `quality_config` | object | no |  |

#### `quality_proxy`

Grade proposed file content against the project's quality gate (complexity, SATD, docs, lint) and return it with a verdict. Never touches the filesystem: hand the returned content to your own file tool, or let the harness PreToolUse hook gate the change.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `file_path` | string | yes | Path the content is destined for (decides the language and the project's pmat.toml) |
| `content` | string | yes | The proposed file content to grade |
| `mode` | string | no | Proxy enforcement mode One of: `strict`, `advisory`, `auto_fix`, `auto-fix`. |
| `quality_config` | object | no |  |

### Project Context (3 tools)

#### `generate_context`

Generate project context (file tree + optional dependency graph) for LLM/agent consumption.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `paths` | array | yes | Filesystem paths (files or directories) to analyze |
| `format` | string | no | Output format One of: `json`. |
| `max_depth` | integer | no | Max directory-tree depth to include |
| `include_dependencies` | boolean | no | Include dependency graph |

#### `scaffold_project`

Produce a high-level project summary scaffold for the given paths.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `paths` | array | yes | Filesystem paths (files or directories) to analyze |
| `level` | string | no | Summary detail level One of: `brief`, `normal`, `detailed`. |

#### `git_operation`

Query git working-tree status for the given repository path.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Path to the git repository to query |

### Planning (1 tool)

#### `pdmt_deterministic_todos`

Generate deterministic, quality-enforced todo lists from a list of requirements.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `requirements` | array | yes | Requirements to convert into deterministic actionable todos |
| `project_name` | string | no | Project or component name |
| `granularity` | string | no | Task detail level (default: high) One of: `low`, `medium`, `high`. |
| `quality_config` | object | no | Quality enforcement config |

## Calling a Tool

A `tools/call` request names the tool and passes `arguments` that match its
schema. The result is one `text` content item holding the tool's JSON report:

```bash
printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"probe","version":"1"}}}' \
  '{"jsonrpc":"2.0","method":"notifications/initialized"}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"analyze_satd","arguments":{"paths":["./src"]}}}' \
  | pmat --mode mcp 2>/dev/null | jq -c 'select(.id==2)'
```

Against a `src/lib.rs` holding one `// TODO: tidy` (output abbreviated):

```json
{"jsonrpc":"2.0","id":2,"result":{"content":[{"type":"text","text":"{\"status\":\"completed\",\"message\":\"SATD analysis completed\",\"results\":{\"total_satd\":1,\"files\":[{\"file\":\"src/lib.rs\",\"satd_count\":1,\"debts\":[{\"line\":2,\"category\":\"Requirement\",\"severity\":\"Low\",\"text\":\"TODO: tidy\"}]}], ...}}"}]}}
```

## Error Handling

Errors are JSON-RPC 2.0 error objects. Calling a tool the server does not have
is a `-32602`, not a silent empty result:

```json
{"jsonrpc":"2.0","id":3,"error":{"code":-32602,"message":"Resource not found: Tool 'semantic_search' not found"}}
```

**Error Codes:**
- `-32700`: Parse error
- `-32600`: Invalid request
- `-32601`: Method not found
- `-32602`: Invalid parameters, including an unknown tool name
- `-32603`: Internal error

## Next Steps

- [**Claude Integration**](ch03-03-claude-integration.md) - Connect with Claude Desktop
- [**Chapter 15: Complete MCP Tools Reference**](ch15-00-mcp-tools.md) - Longer workflows. Its tool list has not been reconciled with this one yet (#8); where they disagree, `tools/list` above is the authority.
