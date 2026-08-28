# Chapter 22: System Diagnostics and Health Monitoring

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ Rewritten against pmat 3.32.0 — every example below was executed

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 17 | Executed against pmat 3.32.0 on 2026-08-25 |
| ⚠️ Not Implemented | 0 | — |
| ❌ Broken | 0 | — |
| 📋 Planned | 0 | — |

*Last updated: 2026-08-25*
*PMAT version: pmat 3.32.0*
<!-- DOC_STATUS_END -->

> **⚠️ Historical warning, as of pmat 3.32.0 (2026-08-25). The diagnostic server,
> the profilers and most of the flags this chapter used to document do not exist.**
>
> The previous edition described `pmat 3.6.1` and was marked
> `✅ 100% Working (16/16 examples)`. `pmat diagnose` has exactly four options of its
> own — `--format`, `--only`, `--skip`, `--timeout` — plus the global flags. Every
> other flag that edition printed exits **2** with `error: unexpected argument found`:
>
> `--troubleshoot`, `--repair-cache`, `--serve`, `--port`, `--fix-config`,
> `--config-file`, `--profile-latency`, `--profile-memory`, `--reset`,
> `--reinit-config`, `--alert-on-failure`, `--email`.
>
> Three consequences worth stating plainly:
>
> - **There is no diagnostic dashboard.** `pmat diagnose --serve --port 8090` exits 2,
>   so the six endpoints that edition listed (`/health`, `/metrics`, `/diagnostics`,
>   `/features`, `/performance`, `WebSocket /live`) have never been served by
>   anything. `pmat serve` is an MCP endpoint, not a dashboard, and it has no
>   `/health` either — see [Chapter 18](ch18-00-api.md).
> - **The JSON structure was invented.** The real report has six top-level keys:
>   `version`, `build_info`, `timestamp`, `duration_ms`, `features`, `summary`. There
>   is no `health_score`, no `platform`, no `dependencies`, no `performance` and no
>   `issues`. The CI job that edition recommended ran
>   `HEALTH_SCORE=$(jq '.health_score' diagnostics.json)`, which yields the string
>   `null`, and then `[ "$HEALTH_SCORE" -lt 90 ]`, which fails with
>   `[: null: integer expression expected` — a health check that could never pass or
>   fail on health. A corrected version is [below](#cicd-a-health-check-that-works).
> - **`--only analysis` is not a category.** `--only` and `--skip` take the exact
>   feature-test names, and an unknown one exits 1 and prints the eight valid names.
>
> `pmat self-update`, `pmat cache clear`, `pmat cache optimize` and `pmat config set`
> were also recommended here as remedies. None of them exist; the real commands are
> at the [end of this chapter](#cache-config-and-updates).

## The Problem

When a tool that measures other software misbehaves, you need to know whether the
tool itself is healthy before you trust a single number it prints. That is a real
need, and `pmat diagnose` is a real answer to it — a self-test that exercises the
parsers, the analysis pipeline, the cache and the git integration, and reports which
of them work.

What it is *not* is a monitoring platform. It has no server, no metrics endpoint, no
profiler and no alerting. Documentation that gave it those things did not add
capability; it added an hour of confusion for every reader who tried them.

## What `pmat diagnose` actually runs

Eight self-tests, in-process, taking milliseconds:

```bash
pmat diagnose
```

Executed output:

```
PMAT Self-Diagnostic Report
  Version: 3.32.0    Duration: 11ms

✓ analysis.complexity (194μs)
✓ analysis.deep_context (8387μs)
✓ ast.python (303μs)
✓ ast.rust (153μs)
✓ ast.typescript (2815μs)
✓ cache.subsystem (12μs)
✓ integration.git (2μs)
✓ output.mermaid (0μs)

Summary:
  Total: 8
  Passed: 8
  Failed: 0
  Success Rate: 100.0%
```

Those eight names are the whole vocabulary of `--only` and `--skip`:

| Feature test | What it proves |
|--------------|----------------|
| `ast.rust` | The Rust parser parses |
| `ast.typescript` | The TypeScript parser parses |
| `ast.python` | The Python parser parses |
| `analysis.complexity` | The complexity analyser runs and returns metrics |
| `analysis.deep_context` | The deep-context pipeline runs end to end |
| `cache.subsystem` | The cache initialises and reports pressure/hit-rate |
| `integration.git` | `git` is available and answerable |
| `output.mermaid` | Mermaid rendering produces valid syntax |

### Selecting and skipping tests

```bash
pmat diagnose --only ast.rust
```

```
PMAT Self-Diagnostic Report
  Version: 3.32.0    Duration: 0ms

✓ ast.rust (213μs)

Summary:
  Total: 1
  Passed: 1
  Failed: 0
  Success Rate: 100.0%
```

Both flags repeat (`--only ast.rust --only ast.python`) and both take exact names.
A category name is not a name:

```bash
pmat diagnose --only analysis
```

Exit status 1:

```
Error: unknown --only feature test 'analysis'. Available: ast.rust, ast.typescript,
ast.python, analysis.complexity, analysis.deep_context, cache.subsystem,
integration.git, output.mermaid
```

That error is a good one — it lists the valid values rather than leaving you to guess
— but it means the old chapter's `pmat diagnose --only cache --only quality --only templates`
fails on the first argument.

### Output formats

`--format` takes `pretty` (the default, shown above), `compact` and `json`.

```bash
pmat diagnose --format compact
```

```json
{"v":"3.32.0","ok":true,"failed":null,"fixes":null}
```

One line, four keys: version, whether everything passed, which tests failed, and
suggested fixes. This is the format for a shell prompt or a pre-flight check.

```bash
pmat diagnose --format json
```

The real structure, executed and abridged in the middle:

```json
{
  "version": "3.32.0",
  "build_info": {
    "rust_version": "unknown",
    "build_date": "unknown",
    "git_commit": null,
    "features": ["cli"]
  },
  "timestamp": "2026-08-25T20:52:24.354549330Z",
  "duration_ms": 35,
  "features": {
    "analysis.complexity": {
      "status": "ok",
      "duration_us": 1143,
      "metrics": {
        "status": "measured",
        "functions_analyzed": 1,
        "max_cyclomatic": 4,
        "analysis_time_ms": 0
      }
    },
    "cache.subsystem": {
      "status": "ok",
      "duration_us": 12,
      "metrics": {
        "cache_initialized": true,
        "memory_pressure": 0.0,
        "total_cache_size": 0,
        "overall_hit_rate": 0.0,
        "memory_efficiency": 1.0
      }
    }
  },
  "summary": {
    "total": 8,
    "passed": 8,
    "failed": 0,
    "degraded": 0,
    "skipped": 0,
    "all_passed": true,
    "success_rate": 100.0
  }
}
```

`build_info.features` is worth a look: it lists the cargo features the binary was
built with. `["cli"]` is the default `cargo install pmat` build, and it is why
`pmat demo`, `pmat org` and `pmat agent` refuse to run — they need features that are
not in it.

Every format prints three progress lines — `⏳ Analyzing project...`,
`Analyses complete`, `Analysis complete!` — but they go to **stderr**, so stdout is
clean JSON and no filtering is needed. `--quiet` silences them entirely:

```bash
pmat diagnose --format json > diagnostics.json
pmat diagnose --quiet --format json | jq -e '.summary.all_passed'
```

Verified: the first line of the redirected file is `{`, and with `--quiet` the command
writes nothing to stderr at all. Merge stderr into stdout (`2>&1`) and you will break
the pipe — that is the one way to get the progress lines into your JSON.

### The complete option list

| Option | Values | Default |
|--------|--------|---------|
| `--format` | `pretty`, `json`, `compact` | `pretty` |
| `--only` | one of the eight feature-test names; repeatable | all |
| `--skip` | one of the eight feature-test names; repeatable | none |
| `--timeout` | seconds | 60 |

Plus the global flags every `pmat` command takes: `-v/--verbose`, `-q/--quiet`,
`--debug`, `--trace`, `--trace-filter`, `--color`, `--mode`.

`pmat doctor` and `pmat diag` are aliases of `pmat diagnose`; all three are the same
command.

## CI/CD: a health check that works

The key is `summary`, not `health_score`. This job fails when a self-test fails, and
uploads the report either way:

```yaml
# .github/workflows/pmat-health.yml
name: PMAT Health Check

on:
  schedule:
    - cron: '0 */6 * * *'
  workflow_dispatch:

jobs:
  health-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install PMAT
        run: cargo install pmat

      - name: Run diagnostics
        run: |
          pmat diagnose --format json > diagnostics.json
          jq -e '.summary.failed == 0 and .summary.all_passed' diagnostics.json \
            || { echo "::error::pmat self-diagnostics failed"; \
                 jq '.features | map_values(.status)' diagnostics.json; exit 1; }

      - name: Upload diagnostic report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: diagnostic-report
          path: diagnostics.json
```

`jq -e` exits non-zero when the filter is false or null, which is what makes this a
gate rather than a printout. The old job's `jq '.health_score'` returned `null` and
the shell comparison errored — that step could not fail *for the reason it claimed*,
which is worse than not having the step at all.

For a shell loop or a prompt, `--format compact` is cheaper:

```bash
pmat diagnose --quiet --format compact | jq -e '.ok' >/dev/null && echo healthy
```

## Beyond self-diagnostics

`pmat diagnose` answers "is `pmat` working?". Three other commands answer "is the
*project* healthy?", and they are what the old chapter's dashboard was reaching for.
All three were executed against the same fixture.

### `pmat project-diag` — 20 Rust project checks

```bash
pmat project-diag --path .
```

```
  Project Diagnostics: .
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Overall: RED 31.0/100.0 (31.0%)

  Cargo Config [3/6]
  Dependencies [2/3]
  Build Performance [1/4]
  Code Quality [0/4]
  Advanced [0/3]

  Checks:
  ───────────────────────────────────────────────────
  ✓ Edition 2021+ - Edition 2021 configured
  ✓ Resolver v2 - Resolver v2 via edition 2021+
  ✓ Dependencies <= 50 - 0 dependencies (excellent)
  ⚠ LTO Enabled - LTO not configured - add lto = true to [profile.release]
  ⚠ Workspace Lints - No workspace lints - add [workspace.lints.rust] section
  ⏭ Workspace Deps - Single-crate project (N/A)
  ✓ Cargo.lock Present - Cargo.lock present (reproducible builds)
  ⚠ Audit Config - No audit config - add deny.toml for security scanning
```

Every check names the fix. Note `⏭` — a check that does not apply is skipped, not
silently passed.

### `pmat maintain health` — does it build?

```bash
pmat maintain health
```

```
✅ Project Health Report

✅ Build: Project builds successfully

📊 Summary:
   Total:   1
   Passed:  1
   Warned:  0
   Failed:  0
   Skipped: 0

✨ Project is healthy!
```

By default this checks the build only. `--all` adds tests, coverage and compliance,
which is much slower — read `pmat maintain health --help` before putting it in a
tight loop.

### `pmat repo-score` — repository hygiene

```bash
pmat repo-score --path .
```

```
Repository Health Score
  Score: 31.5/100.0
  Grade: F

Categories
  ✗ Documentation             0.0/15.0 (0.0%)
  ⚠ Pre-commit Hooks          14.0/20.0 (70.0%)
  ✓ Repository Hygiene        15.0/15.0 (100.0%)
```

For a single composite number across every dimension `pmat` measures, `pmat score`
combines them and says how many dimensions it could actually measure:

```bash
pmat score --path .
```

```
PMAT Unified Score

  Composite: 66.1/100  Grade: D  Dimensions: 4/8

Sub-Scores
  RPS:         34.6
  Comply:      57.0  (1 errors, 11 warnings)
  Coverage:    not measured
```

`Dimensions: 4/8` and `Coverage: not measured` are the load-bearing parts of that
output. A composite built from half the dimensions is not the same claim as one built
from all eight, and the command says which you are looking at rather than averaging
the gap away.

## Cache, config and updates

The old chapter's remediation steps used four commands that do not exist. What is
real:

| Old advice | Status | What to do instead |
|------------|--------|--------------------|
| `pmat cache clear` | `error: unrecognized subcommand`, exit 2 | `pmat cache stats` is the only cache subcommand. To clear, delete the `.pmat/` directory in the project |
| `pmat cache optimize` | `error: unrecognized subcommand`, exit 2 | Nothing to run — there is no optimiser |
| `pmat config set cache.size_mb 200` | `error: unexpected argument found`, exit 2 | `pmat config` takes flags, not subcommands: `--show`, `--edit`, `--validate`, `--reset` |
| `pmat self-update` | `error: unrecognized subcommand`, exit 2 | `cargo install pmat --force` |

The cache statistics that do exist:

```bash
pmat cache stats
```

```
PMAT Cache Statistics
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Orchestrator (this process):
   Strategy Switches: 0
   Evaluations: 0
   Overall Effectiveness: not measured (no cache evaluations in this process)

On-disk caches under /path/to/project:
   /path/to/project/.pmat: 3 file(s), 0.0 MB
```

Read the "this process" heading carefully: the orchestrator counters start empty in
every new process, so they measure the run you just started, not the project's cache
history. The on-disk section is the part that persists. `pmat memory stats` is the
same shape and says so explicitly — "no allocations were recorded in this process".
Neither is a system monitor, and neither claims to be.

## Summary

`pmat diagnose` is a fast, honest self-test: eight checks, four options, three output
formats, and a `summary` block that a CI job can gate on. It is not a server, has no
dashboard, and exposes no metrics endpoint — and a chapter that said otherwise cost
its readers more than it gave them.

For project health rather than tool health, reach for `pmat project-diag` (Rust
project configuration), `pmat maintain health` (does it build), `pmat repo-score`
(repository hygiene) or `pmat score` (a composite that tells you how much of itself it
could measure). Every one of those exists, and every output above came from running
them.
