# Chapter 55: Autonomous Continuous Improvement (`pmat kaizen`)

## Overview

The `pmat kaizen` command implements Toyota Way Kaizen (改善) — autonomous, continuous improvement of your codebase. It scans for improvement opportunities across multiple quality dimensions, optionally applies safe fixes, and reports remaining issues that need human attention.

## Basic Usage

```bash
# Scan only — show what can be improved (no changes)
pmat kaizen --dry-run

# Apply safe auto-fixes
pmat kaizen

# Apply fixes and commit
pmat kaizen --commit

# Full pipeline: fix, commit, push
pmat kaizen --commit --push
```

## Quality Dimensions

Kaizen scans across five quality dimensions by default:

| Dimension | What It Checks | Skip Flag |
|-----------|---------------|-----------|
| **Clippy** | Rust lint warnings and auto-fixable issues | `--skip-clippy` |
| **Rustfmt** | Code formatting deviations | `--skip-fmt` |
| **Comply** | PMAT compliance checks (CB-xxx patterns) | `--skip-comply` |
| **GitHub** | Open issues and PRs for the repository | `--skip-github` |
| **Defects** | Batuta defect pattern analysis | `--skip-defects` |

### Selective Scanning

```bash
# Only check clippy and formatting
pmat kaizen --skip-comply --skip-github --skip-defects

# Only check comply patterns
pmat kaizen --skip-clippy --skip-fmt --skip-github --skip-defects
```

## Output Formats

```bash
# Text output (default)
pmat kaizen --format text

# JSON for CI/CD integration
pmat kaizen --format json -o kaizen-report.json
```

## AI Sub-Agent Mode

For complex fixes that require AI reasoning, kaizen can spawn sub-agents:

```bash
# Enable AI sub-agents for complex fixes
pmat kaizen --agent

# Limit concurrent agents
pmat kaizen --agent --max-agents 2
```

## Cross-Stack Mode

The `--cross-stack` flag scans all batuta stack crates in a single invocation, applying fixes per-crate and producing a unified grouped report.

```bash
# Scan entire batuta stack
pmat kaizen --cross-stack --dry-run

# Auto-fix across all crates, no GitHub issues
pmat kaizen --cross-stack --no-issues

# Full pipeline: fix, commit, push per-crate
pmat kaizen --cross-stack --push

# JSON report for CI/CD
pmat kaizen --cross-stack --dry-run -f json -o cross-stack-report.json

# Markdown report
pmat kaizen --cross-stack --dry-run -f markdown -o cross-stack-report.md
```

### Crate Discovery

Cross-stack mode discovers crates using a 5-priority chain:

1. **Cargo workspace members** — `[workspace]` in `Cargo.toml`
2. **Batuta oracle** — `batuta oracle --local` auto-discovers stack crates
3. **Workspace siblings** — `.pmat/workspace.toml` configuration
4. **Single-crate fallback** — the current directory

### Per-Crate Operations

In cross-stack mode, kaizen processes each crate independently:

- **Scanning**: clippy, fmt, comply, defects, GitHub issues per-crate
- **Fixing**: `clippy --fix` and `cargo fmt` with `cargo check` verification
- **Committing**: separate commit per-crate with crate name in message
- **Pushing**: detects each crate's default branch (supports both `main` and `master`)

### Grouped Report Output

```text
=== Kaizen Cross-Stack Report ===

Kaizen Report: 15 findings | 8 auto-fixed | 2 agent-fixed | 5 remaining | 0 issues filed
Crates scanned: pmat, trueno, aprender

--- pmat (12 findings, 8 fixed) ---
  [FIXED] [MED ] clippy::needless_return src/lib.rs
  [TODO ] [LOW ] rustfmt::unformatted src/main.rs

--- trueno (3 findings, 1 fixed) ---
  [FIXED] [LOW ] rustfmt::unformatted src/lib.rs
  [AGENT] [HIGH] defect::RUST-UNWRAP-001 src/tensor.rs
```

## CI/CD Integration

```bash
# CI pipeline: scan and fail on issues
pmat kaizen --dry-run --format json -o report.json
jq -e '.issues | length == 0' report.json || exit 1

# Cross-stack CI pipeline
pmat kaizen --cross-stack --dry-run -f json -o report.json
jq -e '.remaining_count == 0' report.json || exit 1
```

## What Changed in v3.5.1

- **Cross-stack kaizen** (`--cross-stack`): Scan, fix, commit, and push across all batuta stack crates in a single invocation
- **Branch detection**: `push_changes()` now detects the current branch instead of hardcoding `master`, supporting repos that use `main`
- **Fix #234**: `rust-project-score` no longer counts `unwrap()` calls in `examples/` and `book/` directories as production code (MUDA elimination)
- **Tarantula enrichment**: Findings can now carry `crate_name` for cross-stack grouping; reports group by crate in text, markdown, and JSON formats

## What Changed in v3.5.0

- **Document search** (`--docs`, `--docs-only`, `--no-docs`): Search Markdown, PDF, SVG, and plaintext documentation alongside code using FTS5 BM25 ranking
- **batuta-common consolidation**: Shared utilities (math, formatting, compression, traits) extracted to `batuta-common` crate, reducing cross-crate code duplication by 98%

## What Changed in v3.3.0

- **CB-200 TDG Grade Gate auto-rebuild**: Stale `context.db` is now automatically rebuilt during comply checks, eliminating manual `pmat index` invocations before `pmat comply`
- **TDG scoring refinements**: Cyclomatic complexity divisor changed from 20 to 25 (less harsh penalty), SATD penalty softened (first 2 markers free, 0.5 per marker after), LOC threshold raised to 200+, and enums/structs are now exempt from LOC penalties
- **XXX removed from SATD markers**: Eliminates false positives from legitimate patterns like `BUG-XXX` identifiers that were incorrectly flagged as technical debt
- **Dead code cleanup**: Deleted `extensions_old()` (80 lines) and orphaned `spec.rs` (24KB) discovered through kaizen scanning
- **Configurable entropy quality gate**: Entropy thresholds are now configurable via `.pmat-gates.toml` under the `[entropy]` section
- **CB-200 respects gate configuration**: TDG grade gate reads `[tdg] min_grade` and `exclude` patterns from `.pmat-gates.toml`, allowing project-specific tuning
- **Command dispatchers excluded from TDG gate**: Functions matching the command dispatcher architectural pattern (large match blocks routing to handlers) are automatically excluded from TDG grading

## What Changed in v3.1.1

- Added batuta defect scanner integration (`--skip-defects` to disable)
- Improved comply check accuracy: fixed 10+ false positive categories (#200-#211, #214)
- New CB-528 (division-by-length guard) and CB-530 (log clamp guard) checks
- CB-508: Respect `#[allow(clippy::cast_*)]` annotations on preceding lines
