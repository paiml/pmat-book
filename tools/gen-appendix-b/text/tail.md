
## Global options

These are accepted by every command (from `pmat --help`):

| Option | Description |
|--------|-------------|
| `--mode <cli\|mcp>` | Force CLI or MCP mode instead of auto-detecting. `--mode mcp` starts the MCP stdio server |
| `-v`, `--verbose` | Info-level output |
| `-q`, `--quiet` | Errors only |
| `--debug` | Debug-level output |
| `--trace` | Trace-level output |
| `--trace-filter <FILTER>` | Custom trace filter, e.g. `--trace-filter="paiml=debug,cache=trace"` (env: `RUST_LOG`) |
| `--color <auto\|always\|never>` | Colour control (default `auto`) |
| `-h`, `--help` | Print help |
| `-V`, `--version` | Print version |

`--format` and `--output` are **per-command**, not global: most analysis commands take
`-f, --format` and `-o, --output`, but the accepted values differ per command. Check
`pmat <command> --help`.

## Environment variables

Only variables that `{version}` itself declares in `--help` (as `[env: NAME=]`) or
prints from `pmat mcp connect` are listed. Earlier editions of this appendix listed
eight variables — `PMAT_CONFIG_PATH`, `PMAT_PROFILE`, `PMAT_MAX_THREADS`,
`PMAT_MEMORY_LIMIT`, `PMAT_API_TOKEN`, `PMAT_DEBUG`, `PMAT_LOG_LEVEL` and
`PMAT_CACHE_DIR` — of which seven appear nowhere in the `pmat` source at all.
`PMAT_CACHE_DIR` is the one that is real, but no `--help` declares it, so it is listed
here as a source-level detail rather than a supported interface.

| Variable | Where it applies |
|----------|------------------|
| `MCP_VERSION=1` | Setting it makes a bare `pmat` start the MCP stdio server (equivalent to `pmat --mode mcp`) |
| `PMAT_MCP_HTTP_TOKEN` | Bearer token for `pmat serve --transport http`. Must be ≥16 characters or the server refuses to start |
| `RUST_LOG` | Backs `--trace-filter` on every command |
| `PMAT_COVERAGE_FILE` | `pmat query` — path to the coverage file to enrich results with |
| `PMAT_AGENT_MODEL`, `PMAT_AGENT_HARNESS`, `PMAT_AGENT_EFFORT`, `PMAT_AGENT_PARENT`, `PMAT_AGENT_WORKFLOW_ID` | Agent provenance recorded by `pmat work start`, `work checkpoint`, `work complete`, `work falsify` |

## Exit codes

Measured, not documented by the tool. Earlier editions of this appendix listed ten
codes (3 = analysis failure, 4 = quality gate failure, 5 = security violation, 20 =
license error, …); `pmat` emits none of them.

| Code | Meaning | Example that produces it |
|------|---------|--------------------------|
| 0 | Success — including an analysis that *found* problems but was not asked to fail on them | `pmat analyze satd --path .` |
| 1 | The command ran and failed: a gate tripped, a target could not be analysed, a subprocess died | `pmat analyze satd --path . --fail-on-violation`, `pmat analyze complexity --path /nonexistent` |
| 2 | Usage error from the argument parser — unknown subcommand, unknown flag, unexpected positional | `pmat analyze .`, `pmat repo-score .` |

A `--fail-on-*` style flag is what turns a finding into exit 1; without one, most
analysis commands report and exit 0. Do not build CI on "pmat exited 0 therefore the
code is clean" — check the flag list for the command you are running.

## See also

- [Chapter 5: The Analyze Command Suite](ch05-00-analyze-suite.md) — `pmat analyze` with worked examples
- [Chapter 3.4: MCP Transports](ch03-04-mcp-transports.md) — the verified MCP surface
- [Chapter 15: Complete MCP Tools Reference](ch15-00-mcp-tools.md) — the 19 MCP tools, read out of the server
- `pmat <command> --help` — always the authority; this appendix is generated from it
