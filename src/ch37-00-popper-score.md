# Chapter 37: Popper Falsifiability Score

The `pmat popper-score` command evaluates a project's scientific rigor against Karl Popper's falsifiability criterion, providing a comprehensive 100-point score that measures whether claims are empirically testable.

## Overview

The Popper Falsifiability Score implements Popper's demarcation criterion from *The Logic of Scientific Discovery* (1959):

> "A theory that is not refutable by any conceivable event is non-scientific. Irrefutability is not a virtue of a theory (as people often think) but a vice."

This score helps teams:
- **Quantify scientific rigor** of software claims
- **Identify unfalsifiable statements** that cannot be verified
- **Enforce reproducibility** standards
- **Improve empirical evidence** in documentation

## The Falsifiability Gateway

**Critical Concept**: If Category A (Falsifiability & Testability) scores below 60%, the total score is **automatically 0**.

This implements Popper's key insight: without falsifiable claims, no amount of other quality metrics matter. A project making unfalsifiable claims (like "fastest API ever" without benchmarks) cannot be scientifically validated.

```
┌─────────────────────────────────────────────────────────┐
│              FALSIFIABILITY GATEWAY                     │
│                                                         │
│   Category A >= 60%?                                    │
│         │                                               │
│    ┌────┴────┐                                          │
│   YES       NO                                          │
│    │         │                                          │
│    ▼         ▼                                          │
│  Score    Score = 0                                     │
│  calculated  "Gateway Failed"                           │
└─────────────────────────────────────────────────────────┘
```

## Score Categories (100 Points Total)

### Category A: Falsifiability & Testability (25 points) - GATEWAY

**This category gates the entire score.**

| Sub-Score | Points | Criteria |
|-----------|--------|----------|
| A1: Explicit Falsifiable Claims | 8 | README contains measurable success/failure criteria |
| A2: Test Coverage as Evidence | 10 | Tests exist, coverage measured, CI runs them |
| A3: Confidence Intervals | 7 | Statistical uncertainty quantified |

**What Makes a Claim Falsifiable?**

```markdown
# UNFALSIFIABLE (❌)
"This library is extremely fast and efficient."
"Our API is robust and reliable."
"Handles all edge cases gracefully."

# FALSIFIABLE (✅)
"Response time < 100ms for 99th percentile (measured via Criterion)"
"Zero memory leaks verified with Valgrind on test suite"
"Handles inputs up to 10GB without OOM (tested in CI)"
```

### Category B: Reproducibility Infrastructure (25 points)

| Sub-Score | Points | Criteria |
|-----------|--------|----------|
| B1: Dependency Pinning | 10 | Cargo.lock/package-lock.json committed |
| B2: Containerization | 8 | Dockerfile or Nix flake present |
| B3: Build Reproducibility | 7 | Makefile, clear build instructions |

### Category C: Transparency & Openness (20 points)

| Sub-Score | Points | Criteria |
|-----------|--------|----------|
| C1: License | 5 | OSI-approved license present |
| C2: Documentation | 8 | Comprehensive README, API docs, CHANGELOG |
| C3: Design Decisions | 7 | ADRs, CONTRIBUTING guide |

### Category D: Statistical Rigor (15 points)

| Sub-Score | Points | Criteria |
|-----------|--------|----------|
| D1: Sample Documentation | 5 | Data sources documented |
| D2: Effect Size Reporting | 5 | Confidence intervals, not just p-values |
| D3: Comparison Baselines | 5 | Benchmarks compare against alternatives |

### Category E: Historical Integrity (10 points)

| Sub-Score | Points | Criteria |
|-----------|--------|----------|
| E1: Version Control | 4 | Git repository with history |
| E2: Pre-registration | 3 | Roadmap/design docs before implementation |
| E3: Change Documentation | 3 | CHANGELOG with semantic versioning |

### Category F: ML/AI Reproducibility (5 points or N/A)

*Only applies to ML/AI projects. For non-ML projects, this category is excluded from scoring.*

| Sub-Score | Points | Criteria |
|-----------|--------|----------|
| F1: Random Seed Management | 2 | Seeds documented and reproducible |
| F2: Model Artifacts | 2 | Weights/checkpoints version-controlled |
| F3: Dataset Documentation | 1 | Training data sources documented |

**N/A Handling**: For non-ML projects, the denominator excludes Category F:
- ML project: Score out of 100 points
- Non-ML project: Score out of 95 points (normalized to 100%)

## Grading System

| Grade | Score Range | Interpretation |
|-------|-------------|----------------|
| **A+** | 95-100% | Exceptional scientific rigor |
| **A** | 85-94% | Meets PMAT standards |
| **B** | 70-84% | Good, minor gaps |
| **C** | 55-69% | Acceptable, improvement needed |
| **D** | 40-54% | Below standard |
| **F** | 1-39% | Failing |
| **GATEWAY FAILED** | 0% | Category A < 60% |

## Usage

### Basic Usage

```bash
# Score current project
pmat popper-score

# Score specific path
pmat popper-score --path /path/to/project
```

### Output Formats

```bash
# Text (default, terminal)
pmat popper-score

# JSON (CI/CD integration)
pmat popper-score --format json

# Markdown (documentation)
pmat popper-score --format markdown --output SCORE.md

# YAML (config files)
pmat popper-score --format yaml
```

### Verbose Mode

```bash
# Show detailed breakdown of all sub-scores
pmat popper-score --verbose
```

### Failures Only

```bash
# Show only failing checks and recommendations
pmat popper-score --failures-only
```

### Command Aliases

```bash
# All equivalent:
pmat popper-score
pmat popper
pmat falsifiability
```

## Complete Example

```bash
$ pmat popper-score --verbose

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔬  Popper Falsifiability Score v1.1.0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅  Gateway: PASSED (Falsifiability >= 60%)

📌  Summary
  Score: 78.5/95
  Normalized: 82.6%
  Grade: B

📂  Categories
  ✅ A. Falsifiability & Testability: 18.0/25 (72.0%) [GATEWAY]
    ✓ A1: 6.0/8 - explicit claims found, measurable thresholds found
    ✓ A2: 8.0/10 - test files exist, coverage config found, CI runs tests
    ~ A3: 4.0/7 - confidence intervals mentioned
  ⚠️ B. Reproducibility Infrastructure: 17.0/25 (68.0%)
    ✓ B1: 8.0/10 - Cargo.lock found
    ~ B2: 4.0/8 - Dockerfile found
    ✓ B3: 5.0/7 - Makefile found, standard build config found
  ✅ C. Transparency & Openness: 18.0/20 (90.0%)
    ✓ C1: 5.0/5 - LICENSE exists, OSI-approved license
    ✓ C2: 8.0/8 - comprehensive README, API documentation
    ✓ C3: 5.0/7 - CONTRIBUTING guide exists
  ⚠️ D. Statistical Rigor: 9.0/15 (60.0%)
    ~ D1: 3.0/5 - sample documentation found
    ~ D2: 3.0/5 - confidence intervals found
    ~ D3: 3.0/5 - comparison baselines found
  ✅ E. Historical Integrity: 8.5/10 (85.0%)
    ✓ E1: 4.0/4 - git repository
    ✓ E2: 2.5/3 - roadmap documented
    ✓ E3: 2.0/3 - CHANGELOG exists, semantic versioning
  ⚪ F. ML/AI Reproducibility: N/A

📋  Verdict
  GOOD: Project demonstrates solid scientific practices with room for improvement
  in statistical rigor and reproducibility documentation.

💡  Recommendations
  🟡 [Statistical Rigor] Add Criterion benchmarks with confidence intervals
     $ cargo add criterion --dev
  🟡 [Reproducibility] Add Nix flake for reproducible builds
     $ nix flake init
  🟢 [Transparency] Add ADR (Architecture Decision Records)
     $ mkdir docs/adr && echo "# ADR-001" > docs/adr/001-initial.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Gateway Failed Example

```bash
$ pmat popper-score

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔬  Popper Falsifiability Score v1.1.0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❌  Gateway: FAILED (Falsifiability < 60%)
    Without falsifiable claims, score is 0.

📌  Summary
  Score: 0.0/100
  Normalized: 0.0%
  Grade: GATEWAY FAILED

📂  Categories
  ❌ A. Falsifiability & Testability: 10.0/25 (40.0%) [GATEWAY]
  ⚠️ B. Reproducibility Infrastructure: 15.0/25 (60.0%)
  ✅ C. Transparency & Openness: 18.0/20 (90.0%)
  ⚠️ D. Statistical Rigor: 8.0/15 (53.3%)
  ✅ E. Historical Integrity: 8.0/10 (80.0%)
  ⚪ F. ML/AI Reproducibility: N/A

📋  Verdict
  GATEWAY FAILED: Project does not meet minimum falsifiability requirements.
  Without testable claims, independent verification is not possible.

💡  Recommendations
  🔴 [Falsifiability (Gateway)] Add explicit falsifiable claims and test coverage.
     This is required for any score above 0.
     $ pmat quality-gate --checks tests,coverage

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Programmatic Usage

```rust
use pmat::services::popper_score::{score_project, PopperScore};
use std::path::Path;

fn main() -> anyhow::Result<()> {
    let score = score_project(Path::new("."))?;

    println!("Gateway Passed: {}", score.gateway_passed);
    println!("Normalized Score: {:.1}%", score.normalized_score);
    println!("Grade: {}", score.grade);

    // Access individual categories
    let falsifiability = &score.categories.falsifiability;
    println!(
        "Falsifiability: {:.1}/{:.0} ({:.1}%)",
        falsifiability.earned,
        falsifiability.max,
        falsifiability.percentage()
    );

    Ok(())
}
```

Run the example:
```bash
cargo run --example popper_score_demo
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Popper Falsifiability Score

on:
  push:
    branches: [ main ]
  pull_request:

jobs:
  popper-score:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install PMAT
        run: cargo install pmat

      - name: Run Popper Score
        run: pmat popper-score --format json > popper-score.json

      - name: Upload Score
        uses: actions/upload-artifact@v3
        with:
          name: popper-score
          path: popper-score.json

      - name: Enforce Gateway
        run: |
          GATEWAY=$(jq '.gateway_passed' popper-score.json)
          if [ "$GATEWAY" != "true" ]; then
            echo "❌ Falsifiability Gateway FAILED"
            echo "Add explicit falsifiable claims to README"
            exit 1
          fi

      - name: Enforce Minimum Score
        run: |
          SCORE=$(jq '.normalized_score' popper-score.json)
          if (( $(echo "$SCORE < 70" | bc -l) )); then
            echo "❌ Score $SCORE below B threshold (70%)"
            exit 1
          fi
```

### Pre-commit Hook

```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: popper-score
        name: Popper Falsifiability Check
        entry: bash -c 'pmat popper-score --format json | jq -e ".gateway_passed"'
        language: system
        pass_filenames: false
        always_run: true
```

## Improving Your Score

### Quick Wins

1. **Add falsifiable claims to README**:
   ```markdown
   ## Performance

   - Response time: < 50ms (99th percentile, measured via Criterion)
   - Memory: < 100MB for 1M records (tested in CI)
   - Throughput: > 10K requests/second (benchmark: wrk)
   ```

2. **Add test coverage reporting**:
   ```bash
   cargo llvm-cov --html
   ```

3. **Commit Cargo.lock**:
   ```bash
   git add Cargo.lock && git commit -m "Add lock file for reproducibility"
   ```

4. **Add Dockerfile**:
   ```dockerfile
   FROM rust:1.75-slim
   WORKDIR /app
   COPY . .
   RUN cargo build --release
   ```

### Medium-Term Improvements

1. **Add Criterion benchmarks with confidence intervals**
2. **Document data sources and sample sizes**
3. **Add ADRs (Architecture Decision Records)**
4. **Create CHANGELOG with semantic versioning**

### For ML Projects

1. **Document random seeds**:
   ```python
   SEED = 42
   torch.manual_seed(SEED)
   np.random.seed(SEED)
   ```

2. **Version control model artifacts**:
   ```bash
   dvc init
   dvc add models/
   ```

3. **Document training data sources**

## Philosophical Foundation

The Popper Falsifiability Score is grounded in:

### Karl Popper's Falsificationism

From *The Logic of Scientific Discovery* (1959):
- Science progresses through bold conjectures and rigorous refutation attempts
- Unfalsifiable claims are not scientific
- Reproducibility is essential for independent verification

### Toyota Way Principles

| Principle | Application |
|-----------|-------------|
| **Genchi Genbutsu** | Evidence-based scoring (go see for yourself) |
| **Jidoka** | Gateway stops the line on unfalsifiable claims |
| **Kaizen** | Continuous improvement through recommendations |
| **Hansei** | Honest reflection on current state |

## Related Commands

- `pmat repo-score` - General repository health (language-agnostic)
- `pmat rust-project-score` - Rust-specific quality metrics
- `pmat quality-gate` - Enforce quality thresholds
- `pmat five-whys` - Root cause analysis

## Summary

The `pmat popper-score` command provides:

- **100-point scoring** across 6 categories
- **Falsifiability Gateway** (Category A < 60% = 0 total score)
- **N/A handling** for ML category in non-ML projects
- **Multiple output formats** (text, JSON, markdown, YAML)
- **Actionable recommendations** with priority ranking

**Key Differentiators:**
- Scientific rigor focus (vs. general code quality)
- Gateway mechanism (Popper's demarcation criterion)
- Evidence-based claims verification
- Reproducibility infrastructure checks

**Run your first score:**
```bash
pmat popper-score --verbose
```
