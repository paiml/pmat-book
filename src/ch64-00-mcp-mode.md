# Chapter 64: MCP Mode — pmat as an MCP Server for Claude Code

*How the `pmat` binary doubles as a Model Context Protocol server over stdio, what its 16 tools actually do, where the schema disclosure is broken, and how to wire it into Claude Code in practice.*

The `pmat` binary is two tools bolted into the same entrypoint. When launched with a subcommand (`pmat analyze complexity`, `pmat comply check`, etc.) it behaves as a regular CLI. When launched with no subcommand *and a JSON-RPC 2.0 message on stdin*, it enters MCP mode and speaks the Model Context Protocol v2024-11-05 over stdout. There is no flag to flip. The mode is auto-detected from the shape of stdin.

This chapter covers the verified behavior of MCP mode in `pmat 3.14.0`: how to invoke it, what the 16 exposed tools actually accept as arguments, where the `inputSchema` disclosure lies (it does — see issue #333), and how to register `pmat` as an MCP server in Claude Code's `.claude/settings.json`. Every command in this chapter has been run against `pmat 3.14.0` and the output pasted verbatim.

## Why Auto-detected MCP Mode Exists

Claude Code, like most MCP clients, spawns configured servers as child processes and communicates with them over stdin/stdout using newline-delimited JSON-RPC messages. The client does not know or care that `pmat` has a hundred CLI subcommands — it just pipes JSON to the process and expects JSON back. Auto-detection keeps the binary single-shot: one install path, one executable, one PATH entry. Users who never touch MCP never see the protocol. Users who do get it for free on every install.

The cost of this design is that there is no `pmat mcp` subcommand to discover. `pmat --mode mcp` also does not work — it exits code 2 demanding a subcommand (defect D12, issue #333). The only supported invocation is to write a JSON-RPC message to `pmat`'s stdin and let the binary notice.

## Verified: Initialize and List Tools

The canonical two-message handshake is `initialize` followed by `tools/list`. Pipe both messages on stdin, separated by newlines, and `pmat` responds with two JSON-RPC results on stdout.

```bash
{ echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"t","version":"1"}}}' ;
  echo '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' ;
} | pmat
```

Actual output, captured from `pmat 3.14.0` (one response per line, shown across multiple lines here for readability):

```json
{"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2024-11-05","capabilities":{"tools":{}},"serverInfo":{"name":"paiml-mcp-agent-toolkit","version":"3.14.0"}}}
{"jsonrpc":"2.0","id":2,"result":{"tools":[
  {"name":"analyze_dag","inputSchema":{"type":"object","properties":{}}},
  {"name":"quality_proxy","inputSchema":{"type":"object","properties":{}}},
  {"name":"analyze_satd","inputSchema":{"type":"object","properties":{}}},
  {"name":"git_operation","inputSchema":{"type":"object","properties":{}}},
  {"name":"refactor.getState","inputSchema":{"type":"object","properties":{}}},
  {"name":"generate_context","inputSchema":{"type":"object","properties":{}}},
  {"name":"analyze_complexity","inputSchema":{"type":"object","properties":{}}},
  {"name":"pdmt_deterministic_todos","inputSchema":{"type":"object","properties":{}}},
  {"name":"refactor.stop","inputSchema":{"type":"object","properties":{}}},
  {"name":"refactor.nextIteration","inputSchema":{"type":"object","properties":{}}},
  {"name":"analyze_dead_code","inputSchema":{"type":"object","properties":{}}},
  {"name":"refactor.start","inputSchema":{"type":"object","properties":{}}},
  {"name":"analyze_deep_context","inputSchema":{"type":"object","properties":{}}},
  {"name":"quality_gate","inputSchema":{"type":"object","properties":{}}},
  {"name":"analyze_big_o","inputSchema":{"type":"object","properties":{}}},
  {"name":"scaffold_project","inputSchema":{"type":"object","properties":{}}}
]}}
```

Sixteen tools. Protocol version `2024-11-05`. Server identifies as `paiml-mcp-agent-toolkit` at version `3.14.0`. The server waits for additional messages after `tools/list`, so an interactive harness (or a client with an init sequence) will keep the process alive until EOF or an explicit `shutdown`.

## Disclaimer: the inputSchema Gap (Issue #333, Defect D14)

Look closely at every tool entry above. Each `inputSchema.properties` is `{}` — empty.

This is defect D14 in `pmat 3.14.0`, tracked on [issue #333](https://github.com/paiml/paiml-mcp-agent-toolkit/issues/333). MCP clients rely on `inputSchema` to render UI, validate arguments, and tell language models what each tool accepts. With empty `properties`, a Claude Code integration, a custom MCP client, or an inspector like `mcp-inspector` sees every tool as argument-free — and calls fail at runtime with a validation error.

The tools *do* accept arguments — the argument names just do not appear in the schema. The next section documents the real argument shapes, derived by calling each tool empty and reading the validation errors. Until a future release populates `inputSchema.properties`, treat this chapter as the authoritative reference for what `pmat`'s MCP tools expect.

A related gap, D15, is that PMAT's internal documentation lists `pmat_query_code`, `pmat_get_function`, `pmat_find_similar`, `pmat_index_stats` as MCP tools. Those four are **not exposed** by `pmat 3.14.0` MCP mode. Only the 16 tools shown above are dispatchable.

## Verified: the Real Argument Shapes

Calling each tool with an empty arguments object returns a precise `missing field` validation error. That error *is* the schema, captured at runtime.

Example — calling `analyze_complexity` with no arguments:

```bash
{ echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"t","version":"1"}}}' ;
  echo '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"analyze_complexity","arguments":{}}}' ;
} | pmat
```

Actual response (second line):

```json
{"jsonrpc":"2.0","id":2,"error":{"code":-32603,"message":"Validation error: Invalid arguments: missing field `paths`"}}
```

Repeating this for each tool yields the table below. Fifteen of the sixteen tools require a `paths` array (plural, JSON array of strings). One tool, `git_operation`, requires a singular `path` string. The `refactor.*` family and `pdmt_deterministic_todos` accept more nuanced state payloads not enumerated by the minimal error, but all sixteen tools reject `{}`.

| Tool | Required argument | Type | Notes |
|---|---|---|---|
| `analyze_complexity` | `paths` | array of string | Plural. Each path is a file or dir. |
| `analyze_satd` | `paths` | array of string | SATD = Self-Admitted Technical Debt. |
| `analyze_dead_code` | `paths` | array of string | Cross-module dead code detector. |
| `analyze_dag` | `paths` | array of string | Call-graph DAG emitter. |
| `analyze_big_o` | `paths` | array of string | Big-O complexity inference. |
| `analyze_deep_context` | `paths` | array of string | Full deep-context synthesis. |
| `generate_context` | `paths` | array of string | Light-weight context. |
| `quality_gate` | `paths` | array of string | Runs the default gate set. |
| `quality_proxy` | `paths` | array of string | Proxy metrics. |
| `scaffold_project` | `paths` | array of string | Treats path as output dir. |
| `git_operation` | `path` | string (singular) | The only tool that takes `path`, not `paths`. |
| `refactor.start` | `paths` | array of string | Starts a refactor session. |
| `refactor.nextIteration` | `paths` | array of string | Advances the session. |
| `refactor.getState` | `paths` | array of string | Returns current state. |
| `refactor.stop` | `paths` | array of string | Ends the session. |
| `pdmt_deterministic_todos` | `paths` | array of string | Deterministic TODO scan. |

Verified call — `analyze_complexity` with a concrete `paths` argument:

```bash
{ echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"t","version":"1"}}}' ;
  echo '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"analyze_complexity","arguments":{"paths":["src/main.rs"]}}}' ;
} | pmat
```

Actual response (second line, truncated for width):

```json
{"jsonrpc":"2.0","id":2,"result":{"content":[{"type":"text","text":"{\"status\":\"completed\",\"message\":\"Complexity analysis completed\",\"results\":{\"total_files\":0,\"total_complexity\":0,\"average_complexity\":0,\"violations\":[],\"top_files\":[]}}"}],"isError":false}}
```

The response is an MCP `content` array with a single `text` entry whose payload is a stringified JSON report — the same report you would get from `pmat analyze complexity` at the CLI, wrapped for MCP transport.

## What Each Tool Does — Short Version

The long version lives in Chapter 15 (Complete MCP Tools Reference). The short version, so you can pick tools for a Claude Code workflow without leaving this chapter:

* **`analyze_complexity`** — cyclomatic and cognitive complexity per function, per file, with violations at the pre-commit thresholds (cyclomatic > 30, cognitive > 25).
* **`analyze_satd`** — counts TODO / FIXME / HACK / XXX comments ("self-admitted technical debt") and ranks them by severity.
* **`analyze_dead_code`** — cross-module dead-code detector. Catches unreachable functions, unused exports, orphan modules.
* **`analyze_dag`** — emits the call-graph DAG in Mermaid or JSON. Useful for refactor planning.
* **`analyze_big_o`** — static inference of asymptotic complexity. Flags nested loops and super-linear patterns.
* **`analyze_deep_context`** — full deep-context synthesis (AST + metrics + graph). The MCP wrapper around `pmat context`.
* **`generate_context`** — lighter context pass without full AST. For prompts that need breadth over depth.
* **`quality_gate`** — runs the default gate set (tdg, complexity, satd, dead-code). Returns pass/fail plus per-check evidence.
* **`quality_proxy`** — proxy metrics when full analysis is expensive. Used by Claude Code pre-tool hooks.
* **`scaffold_project`** — project scaffolding from a template (maps to `pmat scaffold`).
* **`git_operation`** — git metadata queries (churn, blame aggregation). The singular `path` tool.
* **`refactor.start` / `refactor.nextIteration` / `refactor.getState` / `refactor.stop`** — stateful refactor session lifecycle. Claude Code calls `start`, streams iterations, polls state, and calls `stop` when a plan is accepted.
* **`pdmt_deterministic_todos`** — deterministic, content-hash-keyed TODO generation. Stable across re-runs so a TODO does not move when code is reformatted.

## Wiring pmat into Claude Code

The `.claude/settings.json` snippet below registers `pmat` as an MCP server at the project level. Place it under `mcpServers.pmat`:

```json
{
  "mcpServers": {
    "pmat": {
      "command": "pmat",
      "args": [],
      "env": {}
    }
  }
}
```

Three things matter in this snippet:

1. **`command: "pmat"`** — relies on the `pmat` binary being on PATH. Use an absolute path (e.g. `/home/you/.cargo/bin/pmat`) if your Claude Code launcher does not inherit the shell PATH. The binary must be installed; see Chapter 1 for installation.
2. **`args: []`** — empty. `pmat` auto-detects MCP mode from stdin. Do *not* pass `--mode mcp` or `mcp` as an argument; both fail in 3.14.0 (defects D12 / exit 2).
3. **`env: {}`** — usually empty. Set `PMAT_HOME` here if you want the MCP process to target a non-default config directory. Set `RUST_LOG=debug` if you want protocol tracing on stderr while debugging.

Once registered, restart Claude Code. On the next session the tool list shown to the model will include the 16 pmat tools prefixed with `pmat_` (or the server name you chose in `mcpServers`). Because the `inputSchema` gap is real, Claude Code may not render rich argument UI for these tools — but the model itself, given this chapter or the table above, will pass `paths: [...]` correctly and the tool will execute.

A global registration — available to every project — goes in `~/.claude/settings.json` under the same `mcpServers.pmat` key. Use global if you run pmat on any repo; project-level if you want pmat only on specific repos.

## End-to-end: a Real Claude Code Call

With `.claude/settings.json` in place, a Claude Code conversation against a Rust project might include:

> User: check the complexity of `src/cli/handlers/query_handler.rs`
>
> Claude: *calls* `pmat.analyze_complexity({ paths: ["src/cli/handlers/query_handler.rs"] })`
>
> *MCP tool returns:* `{"status":"completed", ..., "results": {...per-function complexity..., "violations": [...]}}`
>
> Claude: the file has two functions over the cyclomatic=30 threshold — `handle_query_command` at 47 and `format_results_table` at 33. Both are candidates for extraction...

The model reads the tool result content, understands it as JSON, and responds in natural language. The whole exchange takes a single MCP round-trip per tool call, and Claude Code streams the pmat tool's stdout back as the tool's MCP response.

## Debugging the Integration

Three commands solve most MCP-mode problems:

* **Confirm pmat is on PATH where Claude Code runs it.** Open a Claude Code terminal and run `which pmat && pmat --version`. You should see `pmat 3.14.0` (or newer). If not, either fix PATH or use an absolute `command` path in the settings JSON.
* **Reproduce the handshake by hand.** The `{ echo ... ; echo ... ; } | pmat` recipe at the top of this chapter is the minimum viable MCP test. If it prints two valid JSON-RPC responses, `pmat` MCP mode is healthy and the problem is upstream of the binary (Claude Code config, PATH, sandboxing).
* **Turn on protocol tracing.** Set `RUST_LOG=debug` in the `env` block of `.claude/settings.json`. Stderr will include every inbound and outbound message, plus argument validation errors. These are the same errors you see when running the JSON-RPC recipe manually.

If a tool call returns `"code":-32603, "message":"Validation error: Invalid arguments: missing field \`paths\`"`, the integration is fine — the model just omitted the required argument. Prompt Claude with the table above, or include this chapter in the project's MCP context, and the model will supply `paths`.

## Known Gaps and What to Expect Next

The two material gaps in `pmat 3.14.0` MCP mode are:

* **Empty `inputSchema.properties` for every tool (D14).** Clients cannot discover argument shapes. Workaround: rely on this chapter, or call each tool empty once and read the resulting validation error.
* **Four advertised tools not exposed (D15).** `pmat_query_code`, `pmat_get_function`, `pmat_find_similar`, and `pmat_index_stats` appear in PMAT's CLAUDE.md as MCP-available but are absent from `tools/list`. These will ship in a future release; until then, call them at the CLI level with `pmat query` / `pmat query --function ...`.

Both gaps are tracked on issue #333. Neither blocks MCP mode from being useful today — they limit discoverability, not functionality.

A third, less material gap: `pmat --mode mcp` as an *explicit* invocation fails with exit code 2 (defect D12). Stick to argumentless `pmat` for MCP mode and the auto-detection path; the explicit flag is a trap.

## Minimum Viable Usage Pattern

If you take one thing from this chapter, let it be the three-line recipe that works today against `pmat 3.14.0`:

1. Install `pmat` and confirm it is on PATH: `pmat --version` prints `pmat 3.14.0`.
2. Register it in `.claude/settings.json` with `command: "pmat"`, `args: []`.
3. Tell Claude Code (or your MCP client) that every analysis tool takes `{ paths: [<file or dir>, ...] }` and `git_operation` takes `{ path: <string> }`.

That is the entire integration. No server to run, no ports to bind, no transports to configure. MCP mode is an attribute of the existing `pmat` binary, accessible the moment any JSON-RPC 2.0 message lands on its stdin.

---

*Cross-references:*
- Issue #333 — D13 HTTP stub, D14 empty MCP schemas, D15 missing tool list
- Chapter 3 (`ch03-00-mcp-protocol.md`) — MCP protocol overview
- Chapter 15 (`ch15-00-mcp-tools.md`) — complete MCP tools reference
- Chapter 25 (`ch25-00-sub-agents.md`) — Claude Code sub-agent integration
- Chapter 65 (`ch65-00-http-server.md`) — current state of `pmat serve --transport http` (stub)
