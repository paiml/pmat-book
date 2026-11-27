
## Verified examples

Each block below was **executed** against `{version}` on {date}, in a two-file Rust
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
