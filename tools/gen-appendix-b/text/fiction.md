
## Commands earlier editions listed that do not exist

Every row here was printed as a working command by this appendix before
{date}. None of them resolve against `{version}`. The middle column is what the
binary actually does when you type it; the right column is the nearest real command,
verified to resolve.

Where the right column says **nothing** — there is no equivalent. `pmat` has no plugin
system, no webhook manager, no notification sender, no team/retrospective features and
no secret scanner. That capability was never built; it was only ever written down.

| Documented command (fiction) | What really happens | Real command in {version} |
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
