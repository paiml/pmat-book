# Chapter 56: Compliance Governance (pmat comply)

The `pmat comply` command is a comprehensive compliance governance system that validates projects against PMAT quality standards. It runs 30+ checks across infrastructure, code quality, language-specific best practices, and governance domains -- producing a pass/warn/fail report for every check.

## Overview

`pmat comply check` is the entry point. It loads project configuration from `.pmat/project.toml` and `.pmat.yaml`, runs all applicable compliance checks, and outputs a structured report. Checks that do not apply to your project (for example, Lua checks in a Rust-only project) are automatically skipped.

Each check produces one of four statuses:

| Status | Meaning |
|--------|---------|
| Pass | Meets or exceeds the standard |
| Warn | Advisory issue, does not block compliance |
| Fail | Violation that must be fixed |
| Skip | Check not applicable to this project |

A project is **compliant** if it has zero Fail results. In `--strict` mode, warnings also cause a non-zero exit code.

## Basic Usage

```bash
# Run all compliance checks against the current directory
pmat comply check

# Run against a specific project path
pmat comply check --path /path/to/project

# Strict mode: exit code 1 on failures, exit code 2 on warnings
pmat comply check --strict

# Show only failures (hide passing and warning checks)
pmat comply check --failures-only

# Output as JSON for CI/CD consumption
pmat comply check --format json

# Output as Markdown for documentation
pmat comply check --format markdown
```

### Exit Codes (Strict Mode)

| Exit Code | Meaning |
|-----------|---------|
| 0 | Fully compliant, no warnings |
| 1 | One or more failures |
| 2 | No failures, but warnings present |

## Compliance Check Catalog

All checks are organized into four categories: Infrastructure, Code Quality, Best Practices (language-specific), and Governance.

### Infrastructure Checks

These checks validate that the project's tooling and configuration are properly set up.

#### Version Currency

Compares the version recorded in `.pmat/project.toml` against the running pmat binary version. Projects more than 5 minor versions behind receive a Fail.

```bash
# If your project is behind, migrate:
pmat comply migrate
```

#### Config Files

Verifies that required configuration files exist:

- `.pmat/project.toml` -- project version and compliance metadata
- `.pmat-metrics.toml` -- quality threshold definitions

#### Git Hooks

Checks that a PMAT-aware pre-commit hook is installed at `.git/hooks/pre-commit`. The hook file must contain "pmat" or "PMAT" to pass.

```bash
# Install hooks
pmat hooks init
```

#### CB-030: O(1) Hooks Cache

Validates that the hooks cache directory (`.pmat/hooks-cache/`) is initialized with either `tree-hash.json` or a `gates/` directory, enabling O(1) pre-commit checks instead of full re-analysis.

```bash
# Initialize the cache
pmat hooks cache init
```

#### CB-031: Cache Health

Reads `.pmat/hooks-cache/metrics.json` and checks the cache hit rate. Requires at least 5 runs of data. A hit rate below 60% triggers a warning.

#### Cargo.lock Present

For Rust projects: verifies that `Cargo.lock` is committed for reproducible builds.

#### MSRV Defined

Checks for a `rust-version` field in `Cargo.toml` to ensure minimum supported Rust version is declared.

#### CI Configured

Looks for CI configuration in any of:
- `.github/workflows/` (GitHub Actions)
- `.gitlab-ci.yml` (GitLab CI)
- `Jenkinsfile` (Jenkins)

#### Quality Thresholds

Verifies that `.pmat-metrics.toml` exists with quality gate thresholds.

#### Deprecated Features

Scans for usage of deprecated PMAT features. Currently always passes.

### Code Quality Checks

#### CB-200: TDG Grade Gate

The TDG (Technical Debt Grade) gate is one of the most important checks. It queries the SQLite index at `.pmat/context.db` and fails if any non-test function falls below the configured minimum grade.

**Default minimum grade: A**

Key behaviors:
- **Auto-reindex**: If `context.db` is missing or stale (source files newer than the DB), pmat automatically rebuilds the index before checking.
- **Test exclusion**: Functions in paths containing `/tests/`, `/test/`, or files ending with `_test.rs` / `_tests.rs` are excluded.
- **Path exclusion**: Configure paths to exclude via `.pmat.yaml` or `.pmat-gates.toml`.

```yaml
# .pmat.yaml configuration
comply:
  thresholds:
    min_tdg_grade: "B"       # A, B, C, D, F
    tdg_exclude_paths:
      - "vendor/"
      - "generated/"
```

```toml
# .pmat-gates.toml (overrides .pmat.yaml if both exist)
[tdg]
min_grade = "C"
exclude = ["**/*_generated.rs", "vendor/*"]
```

When violations are found, the output shows up to 10 offending functions:

```
CB-200: TDG Grade Gate: 3 function(s) below minimum grade A
    src/legacy.rs:20 bad_fn [D] (complexity: 42)
    src/awful.rs:30 terrible_fn [F] (complexity: 60)
    src/old.rs:15 needs_refactor [C] (complexity: 28)
```

#### CB-304: Dead Code Percentage

Scans `src/` for dead code indicators:

- `#[allow(dead_code)]` and `#[allow(unused` annotations
- Commented-out code blocks (3+ consecutive lines of `//`-prefixed code-like content)
- Block comments (`/* ... */`) containing code patterns

The default threshold is 15%. Projects between 15-30% receive a warning; above 30% triggers a failure.

Intelligent exclusions:
- Test modules (`#[cfg(test)]`) are stripped before analysis
- Heavily cfg-gated files (SIMD/arch-specific) are skipped entirely
- `macro_rules!` blocks are excluded from item counting

#### CB-040: File Health

Scans Rust source files for oversized files and other health metrics using the `file_health` module. Checks file line counts against configured maximums.

#### CB-081: Dependency Health

A 5-point scoring system for Cargo dependency hygiene:

| Sub-check | What it measures |
|-----------|-----------------|
| CB-081-A | Direct and transitive dependency counts |
| CB-081-B | Duplicate crate detection (multiple versions) |
| CB-081-C | Feature flag hygiene (`default-features = false` usage) |
| CB-081-D | Sovereign stack bonus (batuta ecosystem crates) |
| CB-081-E | Trend tracking (delta since last check) |

Scores 4-5 pass, 2-3 warn, 0-1 fail.

#### CB-060: ComputeBrick Compliance

For projects using the ComputeBrick ecosystem (trueno, probar, realizar). Validates:

- CB-001/CB-002: WGSL shader safety (bounds checks, barrier divergence)
- CB-020: `unsafe` blocks without `// SAFETY:` comments
- CB-021: SIMD intrinsics without `#[target_feature]`
- CB-BUDGET: Bricks without assertion/validation
- BrickProfiler anomaly detection (CV > 15%, efficiency < 25%)

Skipped automatically for non-ComputeBrick projects.

#### OIP Tarantula Patterns (CB-120 to CB-124)

Advisory (non-blocking) checks for common defect patterns:

| ID | Pattern | Severity |
|----|---------|----------|
| CB-120 | NaN-unsafe comparison (`partial_cmp().unwrap()`) | Error |
| CB-121 | Lock poisoning (`mutex.lock().unwrap()`) | Warning |
| CB-122 | Serde deserialization safety (`from_str().unwrap()`) | Error |
| CB-123 | Undocumented `#[ignore]` tests | Warning |
| CB-124 | Low coverage thresholds (< 80%) | Varies |

These are tracked as advisory technical debt and reported as warnings even when critical patterns are found.

#### Coverage Quality Patterns (CB-125 to CB-127)

Unlike the OIP Tarantula patterns, these are **blocking** checks:

| ID | Pattern | What it detects |
|----|---------|-----------------|
| CB-125 | Coverage exclusion gaming | `coverage(off)` on production code |
| CB-126 | Slow tests | Tests with hardcoded sleeps or excessive durations |
| CB-127 | Slow coverage config | Suboptimal coverage tooling configuration |

### Language-Specific Best Practices

Each language series is automatically skipped if no matching source files are found.

#### CB-500: Rust Best Practices (CB-500 to CB-530)

31 pattern detectors for Rust projects:

| ID | Pattern |
|----|---------|
| CB-500 | Publish hygiene (missing license, description, repository) |
| CB-501 | Unwrap density (excessive `.unwrap()` in production code) |
| CB-502 | Expect quality (`.expect()` without descriptive messages) |
| CB-503 | Clippy config (missing clippy.toml or configuration) |
| CB-504 | Deny config (missing `#![deny(warnings)]` or similar) |
| CB-505 | Workspace lint hygiene |
| CB-506 | String byte indexing (potential panics on multi-byte chars) |
| CB-507 | Panic macros in library code |
| CB-508 | Lossy numeric casts (`as` without bounds checking) |
| CB-509 | Feature gate coverage |
| CB-510 | `include!()` macro hygiene |
| CB-511 | Flaky timing tests (tests depending on wall-clock time) |
| CB-512 | Error propagation gaps (missing `?` operator usage) |
| CB-513 | Silent error swallowing (`let _ = result`) |
| CB-514 | Debug eprintln leaks in production |
| CB-515 | Catch-all match/default arms |
| CB-516 | Hardcoded magic numbers |
| CB-517 | Stale debug artifacts |
| CB-518 | Expensive clone in loop |
| CB-519 | Lossy data pipeline conversions |
| CB-520 | Expensive initialization in loop |
| CB-521 | Format detection without magic bytes |
| CB-522 | Untested path normalization |
| CB-523 | External config over embedded |
| CB-524 | Incomplete enum match |
| CB-525 | Hardcoded field names |
| CB-526 | Single path resolution |
| CB-527 | Incomplete pattern list |
| CB-528 | Division by length (potential division by zero) |
| CB-530 | Log without clamp (numerical stability) |

#### CB-600: Lua Best Practices (CB-600 to CB-619)

20 detectors for Lua projects, based on LuaTaint, FLuaScan, and luacheck research:

| ID | Pattern |
|----|---------|
| CB-600 | Implicit globals |
| CB-601 | Nil-unsafe access |
| CB-602 | pcall error handling |
| CB-603 | Deprecated/dangerous API usage |
| CB-604 | Unused variables |
| CB-605 | String concatenation in loop |
| CB-606 | Missing module return |
| CB-607 | Colon/dot method confusion |
| CB-608 | Unchecked nil/err |
| CB-609 | assert() in library code |
| CB-610 | String accumulator in loop |
| CB-611 | Weak table misuse |
| CB-612 | Test framework |
| CB-613 | Require cycles |
| CB-614 | Global protection |
| CB-615 | Coroutine checks |
| CB-616 | Type annotations |
| CB-617 | OpenResty checks |
| CB-618 | FFI safety |
| CB-619 | OOP patterns |

#### CB-700: SQL Best Practices (CB-700 to CB-705)

6 detectors for SQL files:

| ID | Pattern |
|----|---------|
| CB-700 | SELECT * usage |
| CB-701 | Missing WHERE clause on UPDATE/DELETE |
| CB-702 | Implicit JOIN syntax |
| CB-703 | SQL injection patterns |
| CB-704 | Missing index hints |
| CB-705 | N+1 query patterns |

#### CB-800: Scala Best Practices (CB-800 to CB-805)

6 detectors for Scala projects:

| ID | Pattern |
|----|---------|
| CB-800 | Mutable collection usage |
| CB-801 | null usage (prefer Option) |
| CB-802 | Wildcard imports |
| CB-803 | Explicit return statements |
| CB-804 | var declarations |
| CB-805 | Blocking calls in Future context |

#### CB-900: Markdown Best Practices (CB-900 to CB-904)

5 detectors for Markdown files:

| ID | Pattern |
|----|---------|
| CB-900 | Broken internal links |
| CB-901 | Heading hierarchy skips (e.g., # to ###) |
| CB-902 | Missing alt text on images |
| CB-903 | Bare URLs (not wrapped in markdown links) |
| CB-904 | Long lines (exceeding configured maximum) |

#### CB-950: YAML Best Practices (CB-950 to CB-954)

5 detectors for YAML files:

| ID | Pattern |
|----|---------|
| CB-950 | Truthy ambiguity (bare yes/no/on/off values) |
| CB-951 | Excessive nesting depth |
| CB-952 | Missing required fields |
| CB-953 | Unpinned GitHub Action versions |
| CB-954 | Plaintext secrets in YAML |

#### CB-1000: MLOps Model Quality (CB-1000 to CB-1008)

8 detectors for ML model files (`.gguf`, `.apr`, `.safetensors`):

| ID | Pattern |
|----|---------|
| CB-1000 | Missing model card |
| CB-1001 | Oversized tensor count |
| CB-1002 | Missing tokenizer |
| CB-1004 | Missing architecture metadata |
| CB-1005 | Quantization mismatch |
| CB-1006 | Sharded model without index file |
| CB-1007 | Excessive file size |
| CB-1008 | APR format missing CRC |

### Governance Checks

#### CB-130: Agent Context Adoption

Validates that the project is set up for RAG-powered agent code search:

1. **Index exists**: `.pmat/context.idx` or `.pmat/context.db` must be present
2. **Index is fresh**: Less than 24 hours old
3. **CLAUDE.md configured**: References `pmat_query_code` or `pmat query`
4. **Required patterns**: CLAUDE.md contains `NEVER use grep` and `--faults`
5. **No forbidden patterns**: No grep/find examples that bypass pmat query

```bash
# Build or refresh the index
pmat query "test" --rebuild-index
```

#### CB-300: Muda Waste Score

Aggregates the Seven Wastes (Toyota Production System) into a single quality health metric scored 0-100:

- **Overproduction**: Dead code, unused dependencies
- **Waiting**: Slow builds, slow tests
- **Inventory**: Stale branches, unused configs
- **Over-processing**: Excessive complexity
- **Defects**: Bug density, SATD markers

Grades: Lean (90+), Efficient (70-89), Moderate (50-69), High (30-49), Critical (0-29).

#### CB-301: Reproducibility Level

Classifies project reproducibility following NeurIPS/ICLR standards:

| Level | Requirements |
|-------|-------------|
| Gold | Cargo.lock + CI + pinned deps + deterministic builds |
| Silver | Cargo.lock + CI |
| Bronze | Cargo.lock only |
| None | No reproducibility measures |

#### CB-302: Golden Trace Drift

For projects using Renacer golden tracing: validates that `renacer.toml` exists and traces are still valid. Skipped if no `renacer.toml` is found.

```bash
# Validate traces manually
renacer validate --all
```

#### CB-303: EDD Compliance

For simulation projects (using `simular` or `trueno-sim`): validates that public functions document their mathematical models in doc comments. Requires 80% compliance to pass.

#### Sovereign Stack Patterns

For projects in the batuta ecosystem: checks for Five Whys debugging patterns, falsification tests, APR model usage, ticket references, and ML commit classification.

#### PAIML Dependencies Workspace

Validates that batuta ecosystem dependencies (trueno, aprender, renacer, etc.) are properly declared with workspace inheritance.

#### CB-1100: Custom Project Scores

Dynamic checks defined in `.pmat.yaml` under `scoring.custom_scores`. Each entry specifies a shell command that must output JSON with a `score` field. Fails if the score is below the configured `min_score`.

```yaml
# .pmat.yaml
scoring:
  custom_scores:
    - id: "lighthouse"
      name: "Lighthouse Performance"
      command: "lighthouse --output json | jq '.categories.performance.score * 100'"
      min_score: 90.0
      severity: error
```

## Configuration

### .pmat.yaml

The primary configuration file for compliance. Place it in your project root.

```yaml
comply:
  # Disable or configure individual checks
  checks:
    cb-060: { enabled: true, severity: critical }
    cb-500: { enabled: true, severity: warning }
    cb-130: { enabled: false }  # Disable agent context check

  # Global thresholds
  thresholds:
    coverage: 85.0
    complexity: 20
    dead_code_pct: 5.0
    min_tdg_grade: "B"
    tdg_exclude_paths:
      - "vendor/"
      - "generated/"

  # Suppression rules for false positives
  suppressions:
    - rules: ["CB-954"]
      reason: "max_tokens is an LLM parameter, not a secret"
    - rules: ["CB-501"]
      files: ["examples/**"]
      reason: "Examples use unwrap for brevity"
      expires: "2026-12-31"

quality:
  tdg_enabled: true
  min_tdg_score: 70.0
```

When a check is disabled via `enabled: false`, it appears in the report with `Skip` status and a note that it was disabled in `.pmat.yaml`.

Suppressions let you silence specific violation IDs for specific file patterns without disabling the entire check category. Suppressions can have an expiration date.

### .pmat-gates.toml

Additional gate configuration, primarily used for the TDG grade gate and ComputeBrick settings:

```toml
[tdg]
min_grade = "B"
exclude = ["**/*_generated.rs", "vendor/*"]

[compute-brick]
gui_coverage_threshold = 80
max_cv = 15.0
```

Values in `.pmat-gates.toml` override corresponding values in `.pmat.yaml` when both are present.

### .pmat/project.toml

Created by `pmat comply init`. Tracks the project's PMAT version and last compliance check timestamp:

```toml
[pmat]
version = "3.3.0"
last_compliance_check = "2026-02-17T10:30:00Z"
auto_update = false
```

## CI/CD Integration

### GitHub Actions

```yaml
name: PMAT Compliance
on: [push, pull_request]

jobs:
  comply:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install pmat
        run: cargo install pmat

      - name: Run compliance check
        run: pmat comply check --strict --format json > compliance.json

      - name: Upload compliance report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: compliance-report
          path: compliance.json
```

### GitLab CI

```yaml
comply:
  stage: quality
  script:
    - pmat comply check --strict --format json > compliance.json
  artifacts:
    when: always
    paths:
      - compliance.json
```

### Using JSON Output Programmatically

The `--format json` output follows this schema:

```json
{
  "project_version": "3.3.0",
  "current_version": "3.3.0",
  "is_compliant": true,
  "versions_behind": 0,
  "checks": [
    {
      "name": "Version Currency",
      "status": "Pass",
      "message": "Project is on latest version (v3.3.0)",
      "severity": "Info"
    }
  ],
  "breaking_changes": [],
  "recommendations": [],
  "timestamp": "2026-02-17T10:30:00Z"
}
```

## Other Subcommands

Beyond `check`, `pmat comply` provides several supporting subcommands:

### pmat comply init

Scaffolds a new project with PMAT compliance configuration:

```bash
pmat comply init
# Creates:
#   .pmat/project.toml   - version tracking
#   .pmat.yaml            - compliance configuration
#   CLAUDE.md             - agent context instructions
```

Use `--force` to overwrite existing files.

### pmat comply migrate

Migrates project configuration to the latest PMAT version:

```bash
pmat comply migrate                     # Migrate to latest
pmat comply migrate --version 3.2.0     # Migrate to specific version
pmat comply migrate --dry-run           # Preview changes
pmat comply migrate --force             # Proceed past breaking changes
```

### pmat comply diff

Shows the changelog between your project's version and the current binary:

```bash
pmat comply diff                        # Show all changes
pmat comply diff --breaking-only        # Show only breaking changes
pmat comply diff --from 3.0.0 --to 3.3.0
```

### pmat comply upgrade

Upgrades a project to a specific quality enforcement style:

```bash
pmat comply upgrade --target popperian --dry-run
pmat comply upgrade --target popperian
```

The Popperian upgrade installs strict enforcement: 95% minimum coverage, zero TDG regression, complexity limits, and Popper falsification contracts.

### pmat comply enforce

Installs or removes mandatory git hooks for work tracking:

```bash
pmat comply enforce                     # Install hooks (with confirmation)
pmat comply enforce --yes               # Skip confirmation
pmat comply enforce --disable           # Remove hooks
```

### pmat comply report

Generates a compliance report with optional ticket history:

```bash
pmat comply report --format markdown --output report.md
pmat comply report --include-history
```

### pmat comply review

Layer 2 (Genchi Genbutsu): generates an evidence-based reviewer checklist with reproducibility, hypothesis, and trace evidence:

```bash
pmat comply review --format markdown --output review.md
```

### pmat comply audit

Layer 3 (Governance): generates an audit artifact with sovereign trail. Requires clean git state:

```bash
pmat comply audit --format json --output audit.json
```

## What Changed in v3.3.0

Version 3.3.0 introduced several compliance improvements:

- **CB-200 TDG Grade Gate** with auto-reindex: The check now automatically rebuilds the SQLite index when `context.db` is missing or stale, removing the need to manually run `pmat query` before compliance checks. Staleness is determined by comparing source file modification times against the DB file.

- **`.pmat-gates.toml` overrides for CB-200**: The `[tdg]` section in `.pmat-gates.toml` can now override the minimum grade and exclude patterns set in `.pmat.yaml`, giving teams a separate configuration surface for gate enforcement.

- **CB-500 series expanded to CB-530**: New numerical stability checks (CB-528: division by length, CB-530: log without clamp) join the Rust best practices family, bringing the total to 31 detectors.

- **Suppression system for CB patterns**: All language-specific best practice checks (CB-500, CB-600, CB-700, CB-800, CB-900, CB-950, CB-1000) now support the `.pmat.yaml` suppression mechanism, allowing teams to silence false positives with documented reasons and expiration dates.

- **CB-1100 Custom Project Scores**: A new extensibility point allowing projects to define custom score commands in `.pmat.yaml` that are evaluated alongside built-in checks.
