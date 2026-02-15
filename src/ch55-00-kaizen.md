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

## CI/CD Integration

```bash
# CI pipeline: scan and fail on issues
pmat kaizen --dry-run --format json -o report.json
jq -e '.issues | length == 0' report.json || exit 1
```

## What Changed in v3.1.1

- Added batuta defect scanner integration (`--skip-defects` to disable)
- Improved comply check accuracy: fixed 10+ false positive categories (#200-#211, #214)
- New CB-528 (division-by-length guard) and CB-530 (log clamp guard) checks
- CB-508: Respect `#[allow(clippy::cast_*)]` annotations on preceding lines
