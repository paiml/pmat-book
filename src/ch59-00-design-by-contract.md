# Chapter 59: Design by Contract for Work Items

The `pmat work` system implements Meyer's Design by Contract (DbC) to enforce quality during development. Every work item carries a **contract** — a set of falsifiable claims organized into preconditions, invariants, and postconditions that must hold throughout the work lifecycle.

## Overview

Traditional ticket systems track *what* to do. Design by Contract tracks *what must remain true* while you do it:

```
┌─────────────────────────────────────────────────────────┐
│                    Work Contract                        │
├────────────┬─────────────────┬──────────────────────────┤
│  REQUIRE   │   INVARIANT     │         ENSURE           │
│ (before)   │  (throughout)   │        (after)           │
├────────────┼─────────────────┼──────────────────────────┤
│ Compiles   │ No new warnings │ Coverage ≥ 85%           │
│ Tests pass │ No SATD added   │ TDG grade ≥ baseline     │
│ Clean git  │ Files < 500 LOC │ All tests pass           │
│            │                 │ Complexity ≤ threshold   │
└────────────┴─────────────────┴──────────────────────────┘
```

## Quick Start

```bash
# Start work with a contract (auto-detects profile)
pmat work start PMAT-123

# Start with a specific profile
pmat work start PMAT-123 --profile rust

# Start with the strict PMAT profile
pmat work start PMAT-123 --profile pmat

# Exclude specific claims
pmat work start PMAT-123 --without coverage --without complexity

# Run a checkpoint (tests invariants)
pmat work checkpoint PMAT-123

# Complete work (tests all postconditions)
pmat work done PMAT-123
```

## Contract Profiles

Profiles determine which claims are included in a contract.

### Universal Profile (6 claims)

The minimal profile that works for any language:

| Kind | Claim | Threshold |
|------|-------|-----------|
| Require | Clean working directory | - |
| Require | Tests pass | - |
| Invariant | No new SATD comments | - |
| Invariant | File count stable | ±10% |
| Ensure | Tests still pass | - |
| Ensure | No regression in test count | - |

### Rust Profile (14 claims)

Extends Universal with Rust-specific checks:

| Kind | Claim | Threshold |
|------|-------|-----------|
| Invariant | No new clippy warnings | - |
| Invariant | No unsafe added | - |
| Invariant | File line limit | ≤ 500 LOC |
| Invariant | Dependency count stable | ±5% |
| Ensure | Coverage ≥ threshold | configurable |
| Ensure | TDG grade ≥ baseline | per-function |
| Ensure | Complexity ≤ threshold | configurable |
| Ensure | No new dead code | - |

### PMAT Profile (25 claims)

The strictest profile, used for PMAT's own development:

| Kind | Claim | Threshold |
|------|-------|-----------|
| Require | Index freshness | < 24h |
| Require | CLAUDE.md configured | - |
| Invariant | Mutation score stable | ≥ 80% |
| Invariant | Property test coverage | ≥ baseline |
| Ensure | Coverage ≥ 95% | strict |
| Ensure | Spec score ≥ 95 | all specs |
| Ensure | Zero falsified claims | all specs |

## The Meyer Triad

### Require (Preconditions)

Checked once when `pmat work start` is called. If any precondition fails, work cannot begin:

```bash
$ pmat work start PMAT-456
❌ Precondition failed: REQ-002 — Tests must pass before starting work
   Run `cargo test` to fix, then retry.
```

### Invariant (Maintained Throughout)

Checked at every checkpoint (`pmat work checkpoint`). Invariants must hold continuously:

```bash
$ pmat work checkpoint PMAT-456
  ✅ INV-001: No new compiler warnings
  ✅ INV-002: No new SATD comments
  ❌ INV-003: File line limit exceeded
     → src/handlers/big_handler.rs: 523 lines (limit: 500)
```

### Ensure (Postconditions)

Checked when work is completed (`pmat work done`). All postconditions must pass:

```bash
$ pmat work done PMAT-456
  ✅ ENS-001: Tests pass
  ✅ ENS-002: Coverage 96.2% (≥ 95%)
  ✅ ENS-003: TDG grade A (≥ baseline A)
  ❌ ENS-004: Complexity regression
     → parse_config(): cyclomatic 32 (limit: 30)
```

## Subcontracting

When reworking a ticket across iterations, postconditions can only **strengthen** (Liskov Substitution Principle):

```bash
# First iteration: coverage target 85%
pmat work start PMAT-789 --iteration 1
pmat work done PMAT-789

# Second iteration: coverage must be ≥ 85% (inherited)
# Can strengthen to 90%, cannot weaken to 80%
pmat work start PMAT-789 --iteration 2

# This would fail:
# ❌ Subcontracting violation: postcondition weakened
#    ENS-001 coverage: 85% → 80% (must be monotonically non-decreasing)
```

## Stack Manifests

Third-party tool stacks can define their own claims via `.dbc-stack.toml`:

```toml
[stack]
name = "nextjs-stack"
version = "1.0.0"
extends = "universal"  # Inherit universal claims

[[require]]
id = "npm-audit"
description = "No critical vulnerabilities"
check = "npm audit --audit-level=critical"
timeout = 60

[[ensure]]
id = "lighthouse-perf"
description = "Lighthouse performance score ≥90"
check = "npx lighthouse --output=json http://localhost:3000"
metric_pattern = "performance.*?([\\d.]+)"
threshold = { metric = "perf_score", op = "Gte", value = 0.9 }

[[rescue]]
for_clause = "lighthouse-perf"
strategy = "diagnose"
command = "npx lighthouse http://localhost:3000 --view"
guidance = "Check render-blocking resources and image optimization"
```

### Security Restrictions

Stack manifest commands are validated against security restrictions:

- No pipe to shell (`| sh`, `| bash`)
- No backtick substitution (`` `cmd` ``)
- No `$()` command substitution
- No network fetch + execute (`curl | bash`)
- No redirect to executable with chmod

### TOFU Trust Model

Stack manifests use Trust On First Use (TOFU):

```bash
# First use: prompted to review and trust
$ pmat work start TASK-001 --stack ./nextjs-stack.toml
⚠️  New stack manifest: nextjs-stack v1.0.0
   Commands: npm audit, npx lighthouse
   Trust this manifest? [y/N]

# Subsequent uses: trusted if hash matches
$ pmat work start TASK-002 --stack ./nextjs-stack.toml
✅ Stack nextjs-stack v1.0.0 (trusted)
```

## Rescue Protocol

When postconditions fail, the rescue protocol attempts automated recovery:

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  Claim Fails │────▶│  Strategy    │────▶│  Execute     │
│              │     │  Selection   │     │  Rescue      │
└──────────────┘     └──────────────┘     └──────┬───────┘
                                                  │
                                           ┌──────▼───────┐
                                           │  Re-test     │
                                           │  (max 3)     │
                                           └──────────────┘
```

Rescue strategies by claim type:

| Claim Type | Strategy | Action |
|------------|----------|--------|
| Coverage | `auto-fix` | Run `pmat oracle` to generate tests |
| Complexity | `diagnose` | Run `pmat analyze complexity` |
| TDG | `diagnose` | Run `pmat analyze tdg` |
| SATD | `guidance` | Show SATD locations |
| Stack | `command` | Run manifest rescue command |

## Contract Quality

The `--without` flag excludes claims from a contract. Contract quality tracks what percentage of applicable claims are active:

```bash
$ pmat work start PMAT-123 --without coverage --without complexity
⚠️  Contract quality: 75% (Strong) — 15/20 claims active
   Excluded: ENS-001 (coverage), ENS-004 (complexity)
```

Quality ratings:
- **Excellent**: ≥ 90% claims active
- **Strong**: ≥ 75%
- **Adequate**: ≥ 50%
- **Weak**: < 50%

## Contract Scoring (v1.2.0)

Every contract receives a **5-dimension quality score** adapted from provable-contracts:

```bash
# Score a work contract
pmat work score PMAT-123

# Score with minimum threshold (CI/CD mode)
pmat work score PMAT-123 --min-score 0.60

# JSON output for automation
pmat work score PMAT-123 --format json
```

### Scoring Dimensions

| Dimension | Weight | What it measures |
|-----------|--------|------------------|
| spec_depth | 0.20 | How comprehensive are the contract clauses? |
| falsification | 0.25 | What fraction of claims have been verified? |
| invariant_health | 0.25 | Invariant pass rate across checkpoints |
| subcontracting | 0.10 | Monotonic postcondition strengthening |
| traceability | 0.20 | Coverage of require/ensure/invariant triad |

### Grade Scale

| Grade | Score Range |
|-------|------------|
| A | >= 0.90 |
| B | >= 0.75 |
| C | >= 0.60 |
| D | >= 0.40 |
| F | < 0.40 |

## DBC Lint Rules (v1.2.0)

10 lint rules validate contract health, modeled after provable-contracts PV-* rules:

| Rule ID | Severity | Description |
|---------|----------|-------------|
| DBC-VAL-001 | Warning | Missing preconditions (require empty) |
| DBC-VAL-002 | Error | Missing postconditions (ensure empty) |
| DBC-VAL-003 | Warning | Missing invariants (invariant empty) |
| DBC-VAL-004 | Error | Empty claim hypothesis |
| DBC-AUD-001 | Warning | Postcondition without falsification test |
| DBC-AUD-002 | Info | Invariant without checkpoint evaluation |
| DBC-AUD-003 | Info | Claim defined but never verified |
| DBC-SCR-001 | Error | Contract score below threshold |
| DBC-PRV-001 | Error | Subcontracting violation detected |
| DBC-DRF-001 | Warning | Contract drift exceeds bound |

Rules run in 5 sequential gates: validation, audit, score, provability, drift.

## Drift Detection (v1.2.0)

Based on the ABC drift bounds theorem (arXiv:2602.22302):

- **alpha** (drift rate): Increases with time since last checkpoint
- **gamma** (recovery rate): Increases with checkpoint frequency
- **D\*** = alpha / gamma: Bounded drift (lower is better)
- **Staleness**: Contracts without a checkpoint for >24h are flagged

Drift metrics are computed at every checkpoint and stored with the checkpoint record.

## Trend Tracking (v1.2.0)

Quality trend tracking uses a 7-snapshot rolling window:

- Each `pmat work checkpoint` records a trend snapshot
- Rolling average score is computed over the last 7 snapshots
- **Drift detection**: >5% drop from rolling average triggers a warning (DBC-DRF-001)
- Trend direction: improving, stable, or declining

```bash
# View trend data in the score report
pmat work score PMAT-123
```

## Configuration

DbC settings in `.pmat-work/dbc-config.toml`:

```toml
# Override default thresholds
[thresholds]
coverage_pct = 95.0
max_complexity = 25
max_file_lines = 500
tdg_grade_minimum = "A"

# Profile defaults
[profile]
default = "rust"
```

## Running the Example

```bash
cargo run --example dbc_contract_demo
```

This demonstrates all DbC concepts programmatically: Meyer's triad, subcontracting validation, stack manifest parsing, contract quality scoring, command security restrictions, 5-dimension scoring, ABC drift bounds, lint rules, and trend tracking.

## Specification

Full specification: [`docs/specifications/dbc.md`](https://github.com/paiml/paiml-mcp-agent-toolkit/blob/master/docs/specifications/dbc.md)

Based on:
- Meyer, B. (1997). *Object-Oriented Software Construction*, 2nd ed. Prentice Hall.
- Popper, K. (1959). *The Logic of Scientific Discovery*. Routledge.
- Liskov, B. (1987). "Data Abstraction and Hierarchy." *OOPSLA*.
- ABC Drift Bounds (arXiv:2602.22302). Contracts with recovery rate gamma > alpha bound drift to D* = alpha/gamma.
