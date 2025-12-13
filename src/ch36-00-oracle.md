# Chapter 36: PMAT Oracle - Automated Quality Improvement

The PMAT Oracle provides automated, iterative quality improvement using the Toyota Way PDCA (Plan-Do-Check-Act) cycle with Compiler-In-The-Loop (CITL) verification. It combines ALL native Rust signals with PMAT's analysis capabilities to achieve convergent quality improvement.

## Overview

The Oracle system implements five Toyota Way principles:

1. **Jidoka** (Built-in Quality): Stop-the-line on critical defects
2. **Kaizen** (Continuous Improvement): Iterative PDCA cycles
3. **Genchi Genbutsu** (Go and See): Evidence-based from actual compiler output
4. **Andon** (Signal System): Visual status indicators
5. **Muda Elimination** (Waste Reduction): Prioritized fix ordering

## Quick Start

```bash
# Run automated quality improvement loop
pmat oracle fix --path ./my-project

# Check current quality status
pmat oracle status --path ./my-project

# Analyze single iteration without applying fixes
pmat oracle single --path ./my-project --format markdown
```

## Command Reference

### `pmat oracle fix`

Runs the full PDCA improvement loop until convergence or maximum iterations.

```bash
pmat oracle fix [OPTIONS]

Options:
  -p, --path <PATH>              Project path [default: .]
  -m, --max-iterations <N>       Maximum PDCA iterations [default: 10]
  -a, --auto-apply <THRESHOLD>   Auto-apply fixes above confidence [default: 0.95]
  -r, --review <THRESHOLD>       Human review threshold [default: 0.70]
  -n, --dry-run                  Show fixes without applying
  -f, --format <FORMAT>          Output format: text, json, markdown
  -o, --output <FILE>            Write output to file
```

**Example Output:**

```
PMAT Oracle - Automated Quality Improvement
============================================

Iteration 1/10
--------------
Defects Found: 15
  Critical: 2
  High: 5
  Medium: 6
  Low: 2

Auto-Applied: 8 fixes (confidence >= 0.95)
Human Review: 4 fixes (confidence 0.70-0.95)
Skipped: 3 fixes (confidence < 0.70)

Quality Score: 72.5% -> 85.3% (+12.8%)

Iteration 2/10
--------------
Defects Found: 7
...

Convergence achieved after 4 iterations
Final Quality Score: 94.2%
```

### `pmat oracle status`

Shows current project quality status without making changes.

```bash
pmat oracle status [OPTIONS]

Options:
  -p, --path <PATH>      Project path [default: .]
  -f, --format <FORMAT>  Output format: text, json, markdown
```

**Example Output:**

```
PMAT Oracle Status
==================

Quality Score: 94.2%
Andon Status: GREEN

Signal Sources:
  rustc:     0 errors, 2 warnings
  clippy:    5 lints (3 pedantic, 2 style)
  tests:     156 passed, 0 failed
  coverage:  87.3%
  complexity: avg 8.2 (max 15)
  satd:      3 TODOs, 1 FIXME

Defect Summary:
  Unresolved: 8 (all Low severity)
  Last Fix: 2 hours ago
```

### `pmat oracle single`

Runs a single PDCA iteration for analysis without looping.

```bash
pmat oracle single [OPTIONS]

Options:
  -p, --path <PATH>      Project path [default: .]
  -f, --format <FORMAT>  Output format: text, json, markdown
  -o, --output <FILE>    Write output to file
```

## PDCA Cycle Details

### Plan Phase

The Oracle collects signals from multiple sources:

| Signal Source | Weight | Description |
|--------------|--------|-------------|
| rustc errors | 1.0 | Compiler errors (must fix) |
| rustc warnings | 0.8 | Compiler warnings |
| clippy lints | 0.7 | Static analysis findings |
| test failures | 0.9 | Failing test cases |
| coverage gaps | 0.5 | Uncovered code paths |
| complexity | 0.6 | High cyclomatic complexity |
| SATD markers | 0.4 | Self-admitted technical debt |
| dead code | 0.3 | Unused functions/modules |

### Do Phase

Fixes are categorized by decision:

- **AutoApply** (confidence >= 0.95): Applied automatically
- **HumanReview** (confidence 0.70-0.95): Presented for review
- **Skip** (confidence < 0.70): Logged but not applied

### Check Phase

After applying fixes, the Oracle verifies:

1. `cargo check` passes (no new errors)
2. `cargo clippy` runs clean
3. `cargo test` passes
4. Quality score improved

### Act Phase

Based on results:

- **Improved**: Continue to next iteration
- **Regressed**: Revert and try alternative fix
- **Converged**: Stop loop (quality target met)
- **Stalled**: Stop loop (no progress after N iterations)

## Unified Defect Schema (UDS)

The Oracle uses 18 defect categories:

| Category | rustc Confidence | Description |
|----------|-----------------|-------------|
| TypeMismatch | 0.95 | Type system violations |
| BorrowCheck | 0.92 | Ownership/borrowing errors |
| LifetimeBound | 0.90 | Lifetime constraint violations |
| UnusedCode | 0.70 | Dead code detection |
| StyleViolation | 0.60 | Formatting/style issues |
| Complexity | 0.55 | High cyclomatic complexity |
| TestFailure | 0.85 | Failing test cases |
| CoverageGap | 0.50 | Uncovered code paths |
| SecurityFlaw | 0.88 | Security vulnerabilities |
| PerformanceAnti | 0.65 | Performance anti-patterns |
| DocumentationGap | 0.40 | Missing documentation |
| DependencyIssue | 0.75 | Dependency problems |
| UnsafeUsage | 0.80 | Unsafe code blocks |
| ConcurrencyBug | 0.85 | Race conditions, deadlocks |
| MemoryLeak | 0.82 | Memory management issues |
| ApiMisuse | 0.78 | Incorrect API usage |
| ConfigError | 0.70 | Configuration problems |
| BuildError | 0.95 | Build system errors |

## Rich Report Format

The Oracle supports rich terminal output with:

### ASCII Progress Visualization

```
Quality Improvement Progress
============================
Iteration [################....] 80% (4/5)
Quality   [##################..] 94.2%
Coverage  [#################...] 87.3%

Defects by Severity:
Critical [                    ] 0
High     [##                  ] 2
Medium   [####                ] 4
Low      [########            ] 8
```

### K-Means Clustering

Defects are clustered by similarity for batch fixing:

```
Defect Clusters (K-Means, k=4):
-------------------------------
Cluster 1: Type Errors (5 defects)
  - src/parser.rs:42 - TypeMismatch
  - src/parser.rs:87 - TypeMismatch
  - src/lexer.rs:23 - TypeMismatch
  ...

Cluster 2: Borrow Issues (3 defects)
  - src/vm.rs:156 - BorrowCheck
  - src/vm.rs:201 - BorrowCheck
  ...
```

### PageRank Centrality

Critical defects ranked by code impact:

```
Defect Centrality (PageRank):
-----------------------------
1. src/core.rs:89 (0.342) - affects 12 dependents
2. src/api.rs:45 (0.287) - affects 8 dependents
3. src/util.rs:12 (0.156) - affects 5 dependents
```

### Louvain Community Detection

Related defects grouped by code community:

```
Code Communities (Louvain):
---------------------------
Community "parser" (modularity: 0.82)
  - 8 defects across 3 files
  - Primary issue: error handling

Community "runtime" (modularity: 0.76)
  - 5 defects across 2 files
  - Primary issue: memory management
```

## Configuration

Create `.pmat-oracle.toml` for project-specific settings:

```toml
[oracle]
max_iterations = 10
auto_apply_threshold = 0.95
review_threshold = 0.70
convergence_threshold = 0.02  # Stop when improvement < 2%

[weights]
rustc_error = 1.0
rustc_warning = 0.8
clippy = 0.7
test = 0.9
coverage = 0.5
complexity = 0.6
satd = 0.4

[thresholds]
quality_target = 90.0  # Target quality score
max_complexity = 20    # Maximum cyclomatic complexity
min_coverage = 85.0    # Minimum test coverage
```

## Integration with CI/CD

```yaml
# .github/workflows/quality.yml
name: Quality Gate

on: [push, pull_request]

jobs:
  oracle:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install PMAT
        run: cargo install pmat

      - name: Run Oracle Status
        run: pmat oracle status --format json > oracle-status.json

      - name: Check Quality Gate
        run: |
          SCORE=$(jq '.quality_score' oracle-status.json)
          if (( $(echo "$SCORE < 85" | bc -l) )); then
            echo "Quality score $SCORE below threshold 85"
            exit 1
          fi
```

## Best Practices

1. **Start with dry-run**: Use `--dry-run` to preview changes before applying
2. **Review thresholds**: Adjust `--auto-apply` and `--review` based on project maturity
3. **Iterate gradually**: Don't try to fix everything at once
4. **Monitor convergence**: Watch for stalls indicating deeper issues
5. **Integrate early**: Add Oracle to CI/CD from project start

## Troubleshooting

### Oracle stalls at low quality score

The Oracle may stall if defects require architectural changes. Check:

```bash
pmat oracle single --format markdown
```

Review the "Skipped" fixes - they often indicate complex issues needing manual intervention.

### Auto-applied fix causes regression

The Oracle automatically reverts regressing fixes, but if issues persist:

```bash
git diff HEAD~1  # Review last changes
git revert HEAD  # Revert if needed
```

### Slow iteration times

For large projects, consider:

1. Using `--max-iterations 5` for quicker feedback
2. Running on specific paths: `--path ./src/core`
3. Adjusting thresholds to reduce fix attempts

## See Also

- [Chapter 4: Technical Debt Grading (TDG)](ch04-01-tdg.md)
- [Chapter 7: Quality Gates](ch07-00-quality-gate.md)
- [Chapter 27: Quality-Driven Development (QDD)](ch14-00-qdd.md)
- [Chapter 33: Rust Project Score](ch33-00-rust-project-score.md)
