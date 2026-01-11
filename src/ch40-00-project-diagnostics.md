# Chapter 40: Project Diagnostics

The `pmat project-diag` command provides a comprehensive health check for Rust projects, running 20 diagnostic checks across 5 categories. This feature aligns with lltop Tab 8 functionality and integrates with the broader rust-project-score system.

## Overview

Project diagnostics help teams:
- **Quick health assessment** with 20 focused checks
- **Category-based filtering** for targeted analysis
- **Toyota Way Andon board** visualization
- **CI/CD integration** with JSON output
- **Complement rust-project-score** for full quality analysis

## Quick Start

```bash
# Run diagnostics on current directory
pmat project-diag

# Short aliases
pmat diag
pmat diagnose

# Specify a path
pmat project-diag --path /path/to/rust/project

# Filter by category
pmat project-diag --category build

# Output formats
pmat project-diag --format summary   # Human-readable (default)
pmat project-diag --format json      # For CI/CD
pmat project-diag --format markdown  # For documentation
pmat project-diag --format andon     # Toyota Way Andon board
```

## The 20 Diagnostic Checks

### Cargo Config (6 checks, 30 points max)

| Check | Points | Description |
|-------|--------|-------------|
| Edition 2021+ | 5 | Validates Rust edition is 2021 or 2024 |
| Resolver v2 | 5 | Checks for resolver = "2" or edition 2021+ |
| Dependencies <= 50 | 5 | Counts dependencies, warns if >50 |
| LTO Enabled | 5 | Checks for lto = true/thin/fat in [profile.release] |
| Workspace Lints | 5 | Validates [workspace.lints] configuration |
| Workspace Deps | 5 | Checks for [workspace.dependencies] |

**Why these checks matter:**
- **Edition 2021+**: Access to latest Rust features and improvements
- **Resolver v2**: Proper feature resolution for complex dependency trees
- **Dependencies <= 50**: Manageable dependency footprint for security and maintainability
- **LTO**: Smaller binaries and better runtime performance
- **Workspace**: Consistent configuration across multi-crate projects

### Dependencies (3 checks, 15 points max)

| Check | Points | Description |
|-------|--------|-------------|
| Target Dir <= 10GB | 5 | Measures target/ directory size |
| Cargo.lock Present | 5 | Ensures reproducible builds |
| Audit Config | 5 | Checks for deny.toml or audit.toml |

**Why these checks matter:**
- **Target Dir**: Large caches indicate potential build configuration issues
- **Cargo.lock**: Critical for reproducible builds in applications
- **Audit Config**: Security vulnerability scanning configuration

### Build Performance (4 checks, 20 points max)

| Check | Points | Description |
|-------|--------|-------------|
| Cargo Config | 5 | Validates .cargo/config.toml exists |
| Incremental Builds | 5 | Checks incremental compilation settings |
| Codegen Units | 5 | Validates codegen-units = 1 for release |
| Build System | 5 | Checks for Makefile/justfile/build.rs |

**Why these checks matter:**
- **Cargo Config**: Project-specific build settings
- **Incremental**: Faster development iteration
- **Codegen Units**: Maximum optimization for releases
- **Build System**: Automation and reproducible builds

### Code Quality (4 checks, 20 points max)

| Check | Points | Description |
|-------|--------|-------------|
| Clippy Config | 5 | Checks for .clippy.toml or [lints.clippy] |
| Rustfmt Config | 5 | Validates rustfmt.toml exists |
| Tests Present | 5 | Checks for tests/ directory and #[test] |
| README | 5 | Validates README.md exists and has content |

**Why these checks matter:**
- **Clippy Config**: Consistent linting rules
- **Rustfmt Config**: Consistent code formatting
- **Tests Present**: Test infrastructure exists
- **README**: Project documentation for users

### Advanced (3 checks, 15 points max)

| Check | Points | Description |
|-------|--------|-------------|
| MSRV Defined | 5 | Checks for rust-version in Cargo.toml |
| Benchmarks | 5 | Validates benches/ directory and Criterion |
| CI Configured | 5 | Checks for .github/workflows/ or .gitlab-ci.yml |

**Why these checks matter:**
- **MSRV**: Explicit compatibility guarantees
- **Benchmarks**: Performance regression testing
- **CI**: Automated quality validation

## Health Status Interpretation

| Status | Score Range | Meaning |
|--------|-------------|---------|
| GREEN | >= 85% | Production ready, all critical checks pass |
| YELLOW | 60-84% | Some issues need attention before release |
| RED | < 60% | Critical issues must be resolved |

## Example Output

### Summary Format (Default)

```
Project Diagnostics: /path/to/project
==================================================

Overall: [YELLOW] 78.0/100.0 (78.0%)

Cargo Config [5/6]
Dependencies [2/3]
Build Performance [4/4]
Code Quality [2/4]
Advanced [1/3]

Checks:
--------------------------------------------------
[OK]   Edition 2021+ - Edition: 2024
[OK]   Resolver v2 - Using resolver v2
[WARN] Dependencies <= 50 - 52 dependencies (2 over limit)
[OK]   LTO Enabled - lto = "thin"
[SKIP] Workspace Lints - Single-crate project
[SKIP] Workspace Deps - Single-crate project
[OK]   Target Dir <= 10GB - 2.3 GB
[OK]   Cargo.lock Present - Present
[FAIL] Audit Config - No deny.toml or audit.toml found
[OK]   Cargo Config - .cargo/config.toml present
[OK]   Incremental Builds - Incremental builds enabled
[OK]   Codegen Units - codegen-units = 1
[OK]   Build System - Build automation: Makefile, build.rs
[FAIL] Clippy Config - No clippy configuration found
[OK]   Rustfmt Config - rustfmt.toml present
[OK]   Tests Present - tests/ directory and #[test] found
[WARN] README - README.md exists but is short (< 200 chars)
[FAIL] MSRV Defined - No rust-version in Cargo.toml
[SKIP] Benchmarks - No benches/ directory
[OK]   CI Configured - 31 GitHub Actions workflows
```

### Andon Board Format

The `--format andon` option displays a Toyota Way Andon-style status board:

```
+=================================================================+
|                    PROJECT DIAGNOSTICS                          |
|                      (Andon Board)                              |
+=================================================================+
|  Score: [##############################----------] 75.0%        |
+=================================================================+
|  [YELLOW] Cargo Config         5/6 checks passed               |
|  [GREEN]  Dependencies         3/3 checks passed               |
|  [GREEN]  Build Performance    4/4 checks passed               |
|  [YELLOW] Code Quality         2/4 checks passed               |
|  [RED]    Advanced             0/3 checks passed               |
+=================================================================+
|  ANDON CORD TRIGGERED - Issues require attention:               |
|    - MSRV Defined                                               |
|    - Benchmarks                                                 |
|    - CI Configured                                              |
+=================================================================+
```

**Toyota Way Principles:**
- **GREEN**: Line running smoothly (production ready)
- **YELLOW**: Minor issues, continue with caution
- **RED**: Stop the line, address issues immediately
- **Andon Cord**: List of issues requiring attention

### JSON Format (for CI/CD)

```json
{
  "project_path": "/path/to/project",
  "percentage": 78.0,
  "earned": 78.0,
  "max": 100.0,
  "health_status": "Yellow",
  "categories": {
    "cargo_config": {"passed": 5, "total": 6, "status": "Yellow"},
    "dependencies": {"passed": 2, "total": 3, "status": "Yellow"},
    "build_performance": {"passed": 4, "total": 4, "status": "Green"},
    "code_quality": {"passed": 2, "total": 4, "status": "Yellow"},
    "advanced": {"passed": 1, "total": 3, "status": "Red"}
  },
  "checks": [
    {
      "name": "Edition 2021+",
      "category": "cargo_config",
      "status": "Ok",
      "message": "Edition: 2024",
      "points": 5.0
    }
    // ... more checks
  ]
}
```

## Category Filtering

Focus diagnostics on specific areas:

```bash
# Cargo configuration only
pmat project-diag --category cargo

# Dependency checks only
pmat project-diag --category deps

# Build performance only
pmat project-diag --category build

# Code quality only
pmat project-diag --category quality

# Advanced checks only
pmat project-diag --category advanced
```

## Failures Only Mode

Show only failing and warning checks:

```bash
pmat project-diag --failures-only
```

## Save to File

```bash
# Save JSON report
pmat project-diag --format json --output diag.json

# Save Markdown report
pmat project-diag --format markdown --output DIAGNOSTICS.md
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Project Diagnostics
on: [push, pull_request]

jobs:
  diagnostics:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Project Diagnostics
        run: |
          pmat project-diag --format json --output diag.json

          # Parse and check score
          SCORE=$(jq '.percentage' diag.json)
          if (( $(echo "$SCORE < 80" | bc -l) )); then
            echo "Diagnostics score $SCORE is below 80%"
            exit 1
          fi

      - name: Upload Report
        uses: actions/upload-artifact@v4
        with:
          name: diagnostics-report
          path: diag.json
```

### GitLab CI

```yaml
project-diagnostics:
  stage: quality
  script:
    - pmat project-diag --format json --output diag.json
    - 'SCORE=$(jq ".percentage" diag.json) && test $SCORE -ge 80'
  artifacts:
    paths:
      - diag.json
```

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit
pmat project-diag --failures-only --quiet
if [ $? -ne 0 ]; then
    echo "Project diagnostics found critical issues"
    exit 1
fi
```

## Relationship to rust-project-score

The `project-diag` command provides a quick, focused assessment while `rust-project-score` offers comprehensive quality scoring:

| Feature | project-diag | rust-project-score |
|---------|--------------|-------------------|
| Checks | 20 | 50+ across 10 scorers |
| Points | 100 | 159 |
| Speed | Fast (<1s) | Fast/Full modes (2-15 min) |
| Purpose | Quick health check | Comprehensive audit |
| Andon Board | Yes | No |

**Use together:**
```bash
# Quick daily check
pmat project-diag

# Comprehensive release audit
pmat rust-project-score --full
```

## Integration with Comply

The `pmat comply check` command includes 3 checks from project-diag:

1. **Cargo.lock Present** - Reproducible builds (Error severity)
2. **MSRV Defined** - Compatibility guarantee (Warning severity)
3. **CI Configured** - Automation present (Warning severity)

```bash
# Run compliance check (includes project-diag subset)
pmat comply check
```

## Running the Example

```bash
# Run the example demo
cargo run --example project_diag_demo

# Run diagnostics on PMAT itself
pmat project-diag
```

## Summary

The `pmat project-diag` command provides:
- **20 diagnostic checks** across 5 categories
- **Quick assessment** (<1 second execution)
- **Toyota Way Andon board** visualization
- **CI/CD integration** with JSON/Markdown output
- **Category filtering** for focused analysis
- **Alignment with rust-project-score** BuildPerfScorer

**When to use project-diag:**
- Quick daily health checks
- Pre-commit validation
- CI pipeline gates
- New project assessment

**When to use rust-project-score:**
- Release preparation
- Comprehensive audits
- Quality trending
- Formal verification needs

**Related Commands:**
- `pmat rust-project-score` - Full quality assessment (see Chapter 33)
- `pmat comply check` - Compliance validation
- `pmat five-whys` - Root cause analysis for issues found
