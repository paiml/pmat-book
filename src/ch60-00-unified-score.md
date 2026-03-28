# Chapter 60: Unified Quality Score (pmat score)

The `pmat score` command is the single canonical quality gate for PMAT projects. It computes a geometric composite of 7 sub-scores (0-100), persists results to `.pmat-metrics/`, and exits with appropriate codes for CI integration.

## Why One Score?

Before `pmat score`, four separate commands measured quality independently:

| Command | Scale | Problem |
|---------|-------|---------|
| `pmat comply check` | pass/fail | No numeric trend, no persistence |
| `pmat rust-project-score` | 0-289 pts | Doesn't share data with comply |
| `pmat repo-score` | 0-110 | Third overlapping formula |
| `pmat work score` | 0-1 per contract | Only for work items |

None shared analysis, none persisted results, none gated each other. `pmat score` runs comply and RPS internally, reads coverage and DBC from cache, and produces ONE number.

## Basic Usage

```bash
# Compute composite score
pmat score

# Output:
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PMAT Unified Score
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
#   Composite: 66.9/100  Grade: D
#
# Sub-Scores
#   RPS:         69.4
#   Comply:      66.0  (1 errors, 8 warnings)
#   Coverage:    81.0
#   Muda (inv):  63.7
#   EvoScore:    50.0
#   DBC:         71.8
#   File Health: 71.0
```

## Sub-Scores

| Sub-Score | Source | Normalization |
|-----------|--------|---------------|
| RPS | `RustProjectScoreOrchestrator` (11 categories) | Category-average % |
| Comply | `build_compliance_report()` | `100 - (errors*10 + warnings*3)` |
| Coverage | `.pmat-metrics/coverage.result` | Line coverage % |
| Muda | `calculate_muda_score()` CB-300 | `100 - waste_score` |
| EvoScore | CB-142 test trajectory | `clamp(0,1) * 100` |
| DBC | `compute_codebase_score()` | 4-factor composite * 100 |
| File Health | CB-040 file line counts | avg health % |

## Formula: Geometric Mean

```
composite = (rps * comply * coverage * muda * evo * dbc * health) ^ (1/7)
```

The geometric mean has a critical property: **one zero kills the composite**. You cannot ace testing while ignoring code quality. A single sub-score of 0 makes the composite 0.

Compared to arithmetic mean, geometric mean penalizes outliers more heavily — a project scoring 90 on 6 sub-scores but 10 on one gets 47.3 (geometric) vs 78.6 (arithmetic).

## CI Integration

### Gate Flag

```bash
# Exit 1 if composite < 70
pmat score --gate 70

# JSON for CI artifacts
pmat score --gate 70 --format json -o score.json
```

### GitHub Actions Workflow

```yaml
# .github/workflows/quality-gate.yml
name: Quality Gate
on: [push, pull_request]
jobs:
  score:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: dtolnay/rust-toolchain@stable
      - name: Quality Gate
        run: pmat score --gate 70 --format json > score.json
      - uses: actions/upload-artifact@v4
        with:
          name: pmat-score
          path: score.json
        if: always()
```

### Pre-Push Hook

`pmat hooks install` adds a score gate to the pre-push hook:

```bash
# Step 5 in pre-push hook (advisory, doesn't block)
pmat score --gate 60
```

## Score Trend

Track composite over time:

```bash
pmat score --trend

# Output:
# Score Trend (5 commits):
#
#   ▃▅▆▇█
#   Range: 62.1 - 71.3  Current: 71.3 (C)
```

## Regression Detection (CB-145)

Block pushes if quality drops:

```bash
pmat score --regression-check
# Exit 1 if composite dropped >5 pts from previous commit
```

## Cross-Validation (CB-146)

Six invariant rules detect contradictions between sub-scores:

| Rule | Invariant |
|------|-----------|
| XV-001 | Comply 0 errors => RPS Code Quality >= 40% |
| XV-003 | Coverage >= 90% => RPS Testing >= 60% |
| XV-007 | RPS Grade A => composite >= 75 |
| XV-008 | Comply 0 errors => RPS >= 60% |
| XV-009 | File health A => Muda Over-processing < 15 |
| XV-010 | Coverage < 50% => composite < 80 |

If 3+ invariants fail, a systemic inconsistency warning is printed.

## Stack Quality (CB-150)

Show sovereign stack dependency scores:

```bash
pmat score --stack

# Stack Quality (CB-150):
#   aprender             no composite
#   trueno               local (no score)
#   trueno-graph         local (no score)
```

## Score Diagnosis

Map composite breakdown to concrete code locations:

```bash
pmat query --score-diagnosis --limit 5

# COMPOSITE: 66.9/100  Grade: D
#
# Dragging RPS (69.4):
#   Code Quality: 27%
#   Formal Verification: 37%
#
# Dragging Muda (inv) (63.7):
#   Over-processing files: c_visitor.rs (cc=81)
#   Defects files: falsification_cb050.rs (190 pts)
#
# Dragging File Health (71.0):
#   46 files >1000 lines
#   definition.rs: 1534 lines
```

## Metric Persistence

Every `pmat score` run writes to `.pmat-metrics/commit-<sha>-meta.json`:

```json
{
  "sha": "25dcd2e8",
  "composite": 66.9,
  "grade": "D",
  "sub_scores": {
    "rps": 69.4,
    "comply": 66.0,
    "coverage": 81.0,
    "muda_inv": 63.7,
    "evoscore": 50.0,
    "dbc": 71.8,
    "file_health": 71.0
  },
  "rps_categories": { "Code Quality": 27, ... },
  "comply_errors": 1,
  "comply_warnings": 9
}
```

## Work Integration (CB-1250)

`pmat work complete` runs `pmat score --gate 60` as an advisory check after the existing quality gates (tests, clippy, golden traces).

## Grading Scale

| Grade | Composite | Meaning |
|-------|-----------|---------|
| A | 90-100 | Excellent — all sub-scores strong |
| B | 80-89 | Good — minor gaps |
| C | 70-79 | Acceptable — some sub-scores need work |
| D | 60-69 | Below standard — multiple weak areas |
| F | <60 | Failing — significant quality issues |

## See Also

- [Chapter 56: Compliance Governance](ch56-00-comply.md) — comply checks feed the Comply sub-score
- [Chapter 33: Rust Project Score](ch33-00-rust-project-score.md) — RPS feeds the RPS sub-score
- [Chapter 59: Design by Contract](ch59-00-design-by-contract.md) — DBC feeds the DBC sub-score
- Spec: `docs/specifications/components/scoring-convergence.md`
