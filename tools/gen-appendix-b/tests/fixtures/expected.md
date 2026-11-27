# Appendix B: Command Reference

> **This appendix is generated from the binary, not written by hand.**
> Every command path below was read out of `pmat 9.9.9`'s own `--help` output and
> then re-checked by running `pmat <path> --help` and requiring exit status 0.
> Nothing in the tables is transcribed from memory. Regenerate it with:
>
> ```bash
> cargo run -q --release --manifest-path tools/gen-appendix-b/Cargo.toml > src/appendix-b-commands.md
> ```
>
> **If you bookmarked this page before 2000-01-02, what you read here was wrong.**
> Earlier editions listed 31 top-level commands that `pmat` has never had —
> `pmat architecture`, `pmat rules`, `pmat clippy`, `pmat status`, `pmat scan`,
> `pmat dashboard` and more. Of the 150 command paths that edition printed, 73 did
> not resolve. Every one of them is accounted for in
> [Commands earlier editions listed that do not exist](#commands-earlier-editions-listed-that-do-not-exist),
> with the real replacement where there is one.

`pmat 9.9.9` exposes **6 top-level commands** and **5 subcommands**.

## How to read this appendix

- **Aliases are real.** `pmat a cx` is `pmat analyze complexity`. Anything in the
  Aliases column can be substituted for the command name.
- **`--help` works at every level**, and short-circuits before argument validation:
  `pmat <command> --help` and `pmat <command> <subcommand> --help` always print and
  exit 0 if the path exists. That is exactly the check this appendix is built on.
- **A command with subcommands requires one.** `pmat analyze .` is not "analyze the
  current directory" — it exits 2 with `error: unrecognized subcommand`. The path
  goes to the *subcommand*: `pmat analyze complexity --path .`
- **Path arguments are not uniform, and this is the single most common mistake.**
  Some commands take a positional path, some take `--path`, some take
  `--project-path`, and passing a positional to a command that wants a flag exits 2
  with `error: unexpected argument found`. The tables below name the form for every
  command, so check the column rather than guessing:

  ```bash
  pmat tdg .                              # positional
  pmat analyze complexity --path .        # --path
  pmat quality-gate --project-path .      # --project-path
  ```

- **`[NOT AVAILABLE in the default build]`** in a description is pmat's own wording.
  Those commands parse and appear in `--help`, but the shipped `cargo install pmat`
  binary refuses them at runtime; they need a non-default `--features` build. They are
  marked ⚠ below.

## Top-level commands

| Command | Aliases | Subcommands | What it does |
|---------|---------|-------------|--------------|
| `pmat analyze` | — | [3](#pmat-analyze) | Analyze code metrics and patterns |
| `pmat tdg` | `grade`, `t` | [2](#pmat-tdg) | Grade technical debt \| pipes and `pmat` mentions |
| `pmat query` | — | — | Search code with `pmat` and a very long description that keeps going well past the truncation limit so that the cell function has to cut it at a word boundary and add an … |
| `pmat repo-score` | `rs` | — | Score a repo |
| `pmat extract` | — | — | Extract items from a file |
| `pmat hooks` | — | — | ⚠ [NOT AVAILABLE in the default build] Manage hooks |

## Commands that take no subcommand

These run directly. The Path column is the form this command accepts a target path in — using the wrong one exits 2.

| Command | Path | Other positional arguments |
|---------|------|----------------------------|
| `pmat query` | — | `<QUERY>` |
| `pmat repo-score` | `--path` | — |
| `pmat extract` | — | — |
| `pmat hooks` | — | — |

A `—` in the Path column means the command takes no path at all, or takes its
target some other way. Two that catch people out: `pmat extract` takes its file
as the *value* of `--list` (`pmat extract --list src/main.rs`), and `pmat generate`
takes a template category and name (`pmat generate makefile rust/cli -p project_name=demo`).

## Subcommands by parent

<a id="pmat-analyze"></a>

### `pmat analyze`

Analyze code metrics and patterns

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat analyze complexity` | `cx`, `complex` | `--path` | Analyze code complexity |
| `pmat analyze satd` | `debt` | `--project-path` | Analyze SATD |
| `pmat analyze dag` | — | — | ⚠ [REMOVED] Dependency graphs |

<a id="pmat-tdg"></a>

### `pmat tdg` (aliases: `grade` `t`)

Grade technical debt \| pipes and `pmat` mentions

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat tdg compare` | — | `<FILE>` (positional) | Compare two files |
| `pmat tdg history` | — | — | View history |


## Verified examples

Each block below was **executed** against `pmat 9.9.9` on 2000-01-02, in a two-file Rust
fixture, and the exit status recorded. Output is trimmed for length; nothing else is
edited.

```bash
pmat --version
# pmat 3.32.0                                                     exit 0
```

```bash
pmat analyze complexity --path .
# ✅ Successfully analyzed 1 file(s)
#   Files analyzed: 1
#   Total functions: 3                                            exit 0
```

```bash
pmat analyze satd --path .
# Found 1 SATD violations in 1 files (analysed 1 of 1 file(s) walked)   exit 0
```

```bash
pmat analyze dead-code --path .
#   Files with dead code: 1
#   Dead code percentage: 27.8%                                   exit 0
```

```bash
pmat analyze tdg -p . --format table
#   Average Score: 99.5/100 (A+)                                  exit 0
```

```bash
pmat tdg .
#   Overall Score: 99.5/100 (A+)                                  exit 0
```

```bash
pmat quality-gate -p . --checks complexity
# Quality Gate: PASSED
# Total violations: 0                                             exit 0
```

```bash
pmat analyze dag --target-nodes 10
# 📊 full-dependency: rendered 4 nodes and 0 edges
# graph TD                                                        exit 0
```

```bash
pmat extract --list src/main.rs
# { "file": "src/main.rs", "language": "rust", "items": [ ...     exit 0
```

```bash
pmat search rust --limit 2
#  1. template://readme/rust/cli (score: 9.00)                    exit 0
```

```bash
pmat mcp connect
# prints every way to connect this binary to an MCP client, with
# the exact `claude mcp add` line                                 exit 0
```

Two failures worth knowing, also executed. They are shown as a table rather than a
code block on purpose: this is what a *wrong* form looks like, not something to type.

| Command | Result | Why |
|---------|--------|-----|
| `pmat analyze .` | `error: unrecognized subcommand`, exit 2 | `analyze` requires a subcommand, and the path belongs to it: `pmat analyze complexity --path .` |
| `pmat repo-score .` | `error: unexpected argument found`, exit 2 | `repo-score` takes `--path`; a positional path is rejected |

Between them these two shapes account for most broken `pmat` lines in circulation.
Check the Path column in the tables above before typing a path.


## Commands earlier editions listed that do not exist

Every row here was printed as a working command by this appendix before
2000-01-02. None of them resolve against `pmat 9.9.9`. The middle column is what the
binary actually does when you type it; the right column is the nearest real command,
verified to resolve.

Where the right column says **nothing** — there is no equivalent. `pmat` has no plugin
system, no webhook manager, no notification sender, no team/retrospective features and
no secret scanner. That capability was never built; it was only ever written down.

| Documented command (fiction) | What really happens | Real command in pmat 9.9.9 |
|------------------------------|---------------------|---------------------------|
| `pmat status` | `error: unrecognized subcommand` | `pmat diagnose`, or `pmat score --path .` |
| `pmat scan` | `error: unrecognized subcommand` | `pmat analyze comprehensive --path .` |
| `pmat watch` | `error: unrecognized subcommand` | nothing — there is no watch mode |
| `pmat complexity` | `error: unrecognized subcommand` | `pmat analyze complexity --path .` |
| `pmat dead-code` | `error: unrecognized subcommand` | `pmat analyze dead-code --path .` |
| `pmat satd` | `error: unrecognized subcommand` | `pmat analyze satd --path .` |
| `pmat similarity` | `error: unrecognized subcommand` | `pmat analyze name-similarity`, `pmat analyze duplicates`, `pmat semantic similar` |
| `pmat architecture analyze` (and `deps`, `patterns`, `graph`, `validate-layers`) | `error: unrecognized subcommand` | `pmat analyze dag`, `pmat analyze graph-metrics`, `pmat analyze symbol-table` |
| `pmat rules init` (and `create`, `test`, `validate`) | `error: unrecognized subcommand` | `pmat quality-gates init` writes `.pmat-gates.toml`; `pmat comply` enforces project rules |
| `pmat clippy run` (and `enable`, `fix`) | `error: unrecognized subcommand` | `pmat analyze clippy` |
| `pmat security scan` | `error: unrecognized subcommand` | `pmat quality-gate --checks security` |
| `pmat secrets scan` | `error: unrecognized subcommand` | nothing — `pmat` does not scan for secrets |
| `pmat audit` | `error: unrecognized subcommand` | `pmat deps-audit --path .` (dependencies), `pmat comply audit` (governance artifact) |
| `pmat dependencies` | `error: unrecognized subcommand` | `pmat deps-audit --path .` |
| `pmat performance analyze` (and `hotspots`, `memory`, `compare`) | `error: unrecognized subcommand` | `pmat test performance`, `pmat analyze big-o`, `pmat analyze bottleneck` |
| `pmat benchmark` | `error: unrecognized subcommand` | `pmat test throughput` |
| `pmat compare` / `pmat diff` | `error: unrecognized subcommand` | `pmat tdg compare`, `pmat comply diff` |
| `pmat merge` / `pmat export` / `pmat import` | `error: unrecognized subcommand` | nothing — use each command's own `--format` and `--output` |
| `pmat report executive` | `report` takes no subcommand; exits 2 | `pmat report --format json` |
| `pmat dashboard serve` / `pmat dashboard generate` | `error: unrecognized subcommand` | `pmat tdg dashboard` ⚠ (needs `--features http-server`; not in the shipped build) |
| `pmat team setup` / `pmat retrospective` / `pmat review prepare` | `error: unrecognized subcommand` | nothing — no team, retrospective or review-prep features exist |
| `pmat webhook` / `pmat notify slack` | `error: unrecognized subcommand` | nothing — `pmat` sends no notifications |
| `pmat pipeline validate` | `error: unrecognized subcommand` | `pmat ci-local` |
| `pmat plugin list` (and `install`, `update`) | `error: unrecognized subcommand` | nothing — there is no plugin system |
| `pmat ai analyze` (and `suggest`, `refactor`, `review`) | `error: unrecognized subcommand` | `pmat refactor auto`, `pmat prompt generate`, `pmat oracle fix` |
| `pmat info` | `error: unrecognized subcommand` | `pmat diagnose --format json` |
| `pmat doctor` | works — it is an **alias** of `pmat diagnose` | `pmat diagnose` |
| `pmat check` | works — it is an **alias** of `pmat quality-gate` | `pmat quality-gate` |
| `pmat compliance` | works — it is an **alias** of `pmat comply` | `pmat comply check` |
| `pmat config set` (and `get`, `list`, `reset`, `profiles`, `export`, `import`) | `config` takes no subcommand; exits 2 | `pmat config --show`, `--edit`, `--validate`, `--reset` |
| `pmat cache clear` (and `optimize`, `warmup`, `configure`) | `error: unrecognized subcommand` | only `pmat cache stats` exists; delete the `.pmat/` directory to clear |
| `pmat hooks configure` | `error: unrecognized subcommand` | `pmat hooks refresh`, `pmat hooks verify`, `pmat hooks status` |
| `pmat self-update` | `error: unrecognized subcommand` | `cargo install pmat --force` |
| `pmat mutate` | `error: unrecognized subcommand` | nothing in `pmat` — run `cargo mutants` directly |
| `pmat analyze tdg --detailed` | `--detailed` is not a flag; exits 2 | `pmat analyze tdg -p . --include-components` |


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

Only variables that `pmat 9.9.9` itself declares in `--help` (as `[env: NAME=]`) or
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
