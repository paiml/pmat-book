# Chapter 7: Quality Gates - Automated Quality Enforcement

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (10/10 examples)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 10 | All quality gate features tested |
| ⚠️ Not Implemented | 0 | Planned for future versions |
| ❌ Broken | 0 | Known issues, needs fixing |
| 📋 Planned | 0 | Future roadmap features |

*Last updated: 2026-02-17*
*PMAT version: pmat 3.3.0*
*Test-Driven: All examples validated in `tests/ch07/test_quality_gate.sh`*
<!-- DOC_STATUS_END -->

## Automated Quality Enforcement

Quality gates are automated checkpoints that enforce code quality standards across your project. PMAT's quality gate system provides comprehensive analysis and configurable thresholds to maintain high-quality codebases consistently.

## Basic Quality Gate Analysis

### Run All Quality Checks

Start with a comprehensive quality assessment:

```bash
# Analyze current project (default)
pmat quality-gate

# Analyze specific directory
pmat quality-gate --project-path src/

# Analyze specific file
pmat quality-gate --file src/main.rs

# Run with verbose output
pmat quality-gate --verbose
```

### Example Output (Summary Format)

```
Quality Gate: FAILED
Total violations: 348

## complexity (266 violations)
  - ./src/parser.rs:135 - parse_expression: cognitive-complexity -
    Cognitive complexity of 21 exceeds recommended complexity of 20
    (complexity: 21, threshold: 20)
  - ./src/handler.rs:262 - handle_request: cyclomatic-complexity -
    Cyclomatic complexity of 33 exceeds maximum allowed complexity of 30
    (complexity: 33, threshold: 30)

## satd (58 violations)
  - ./src/agents/mod.rs:106 - Requirement: TODO: Properly implement
    agent system initialization (at column 5)

## entropy (21 violations)
  - ./src/services/github_client.rs - ApiCall pattern repeated 10 times
    (saves 302 lines) - Fix: Create API client abstraction

## sections (3 violations)
  - README.md - Missing required section: Installation
```

## Available Quality Checks

PMAT's quality gate includes 9 check types, selectable via `--checks`:

```bash
# Run specific checks
pmat quality-gate --checks complexity,satd,entropy

# All checks (default)
pmat quality-gate --checks all
```

**Available checks:** `complexity`, `satd`, `dead-code`, `coverage`, `sections`, `provability`, `entropy`, `security`, `duplicates`

### Complexity Analysis

Monitor both cyclomatic and cognitive complexity:

```bash
# Focus on complexity only
pmat quality-gate --checks complexity
```

**Complexity Thresholds (built-in):**
- **Cyclomatic**: Recommended ≤ 25, Maximum ≤ 30
- **Cognitive**: Recommended ≤ 20, Maximum ≤ 25

### Technical Debt Detection (SATD)

Track Self-Admitted Technical Debt markers:

```bash
# Check technical debt
pmat quality-gate --checks satd
```

**Detected Markers:**
- `TODO` - Future improvements
- `FIXME` - Known bugs or issues
- `HACK` - Temporary solutions
- `XXX` - Critical concerns
- `BUG` - Confirmed defects

### Dead Code Detection

Identify unused code that increases maintenance burden:

```bash
pmat quality-gate --checks dead-code
```

### Entropy Analysis

Detect repetitive code patterns that could be abstracted:

```bash
pmat quality-gate --checks entropy
```

Entropy analysis finds **structurally identical** code patterns and estimates how many lines could be saved by refactoring. Patterns are grouped by structural hash — code is normalized (identifiers replaced with placeholders, literals removed) so that only truly duplicated logic is flagged. This eliminates false positives where different validation checks happen to use the same API (e.g., `.is_empty()`).

> **Note:** The `calculate_pattern_variations()` function was removed because it was overriding structural hash results with its own variation scoring, which diluted the accuracy of structural deduplication. Structural hashing alone provides more precise duplicate detection.

The following paths are **excluded** from entropy analysis by default:
- `tests/` directory and `*.test.rs` files
- Test files matching `*_tests.rs` and `*tests_part*.rs` patterns
- `examples/` and `benches/` directories

Each violation includes:
- **Pattern type** (ApiCall, ErrorHandling, ResourceManagement, etc.)
- **Repetition count** (≥3 structurally identical matches required) and estimated LOC reduction
- **Affected files** and example code
- **Fix suggestion** (e.g., "Create API client abstraction")

Configure via `.pmat-gates.toml`:
```toml
[entropy]
enabled = true
min_pattern_diversity = 0.30
exclude = ["examples/**", "benches/**"]
```

### Provability Analysis

Score how amenable your code is to formal verification:

```bash
pmat quality-gate --checks provability
```

Provability analysis reads actual function source code and scores each function on:
- **Bounds checking** - Array/index safety (no unchecked indexing or `.unwrap()`); the `?` operator is recognized as proper error propagation and does not penalize the score
- **Memory safety** - Ownership and lifetime correctness (no `unsafe`, no raw pointers)
- **No aliasing** - Absence of mutable aliasing; `&mut` is correctly treated as an **exclusive borrow** (Rust's ownership model guarantees NoAlias for `&mut` references, so their presence does not reduce the score)
- **Null safety** - Rust type system guarantees (non-`unsafe` code is null-safe)
- **Pure functions** - Side-effect-free logic (no I/O, no mutation, no loops)

Scores are **differentiated per function** (0.2 to 1.0), not a single fallback value. The provability gate passes when the project-wide average score meets the minimum threshold (>= 0.60). When it fails, violations include the worst-scoring functions and verified property counts:
```
Provability score 0.55 is below minimum 0.60
  Functions: main (20%), handle_request (33%)
  Verified: bounds_check 25/50, memory_safety 30/50, null_safety 40/50,
            no_aliasing 35/50, pure_function 15/50
```

### Test Coverage

Monitor test coverage levels (reads from `.pmat/coverage-cache.json`):

```bash
pmat quality-gate --checks coverage
```

### Section Validation

Check that README.md contains required sections:

```bash
pmat quality-gate --checks sections
```

## Output Formats

PMAT supports 6 output formats: `summary` (default), `human`, `json`, `detailed`, `junit`, `markdown`.

### Summary Format (Default)

Concise list grouped by check type:

```bash
pmat quality-gate --format=summary
```

```
Quality Gate: FAILED
Total violations: 348

## complexity (266 violations)
  - ./src/parser.rs:135 - parse_expression: cognitive-complexity -
    Cognitive complexity of 21 exceeds recommended complexity of 20

## satd (58 violations)
  - ./src/agents/mod.rs:106 - Requirement: TODO: Properly implement
    agent system initialization

## entropy (21 violations)
  - ./src/services/github_client.rs - ApiCall pattern repeated 10 times
    (saves 302 lines) - Fix: Create API client abstraction

## sections (3 violations)
  - README.md - Missing required section: Installation
```

### Human-Readable Format

Same content as summary with additional detail per violation:

```bash
pmat quality-gate --format=human
```

### JSON Format

Machine-readable output for CI/CD integration. Progress messages go to stderr; clean JSON goes to stdout.

```bash
# Pipe-friendly: only JSON on stdout
pmat quality-gate --format=json > report.json

# Suppress progress entirely
pmat quality-gate --format=json --quiet
```

**JSON Structure:**
```json
{
  "results": {
    "passed": false,
    "total_violations": 348,
    "complexity_violations": 266,
    "dead_code_violations": 0,
    "satd_violations": 58,
    "entropy_violations": 21,
    "security_violations": 0,
    "duplicate_violations": 0,
    "coverage_violations": 0,
    "section_violations": 3,
    "provability_violations": 0,
    "provability_score": null,
    "violations": []
  },
  "violations": [
    {
      "check_type": "complexity",
      "severity": "warning",
      "file": "./src/parser.rs",
      "line": 135,
      "message": "parse_expression: cognitive-complexity - Cognitive complexity of 21 exceeds recommended complexity of 20 (complexity: 21, threshold: 20)"
    },
    {
      "check_type": "satd",
      "severity": "info",
      "file": "./src/agents/mod.rs",
      "line": 106,
      "message": "Requirement: TODO: Properly implement agent system initialization (at column 5)"
    },
    {
      "check_type": "entropy",
      "severity": "warning",
      "file": "./src/services/github_client.rs",
      "line": null,
      "message": "ApiCall pattern repeated 10 times (saves 302 lines) - Fix: Create API client abstraction",
      "details": {
        "affected_files": ["./src/services/github_client.rs"],
        "example_code": "let resp = client.post(\"/endpoint\", body).await",
        "fix_suggestion": "Create API client abstraction",
        "score_factors": [
          "pattern_type: ApiCall",
          "repetitions: 10",
          "variation_score: 0.00 (structurally identical)"
        ]
      }
    }
  ]
}
```

**Key fields:**
- `results.passed` - Overall pass/fail boolean
- `results.*_violations` - Count per check type
- `violations[]` - Flat array of all violations
- `violations[].details` - Present for entropy and provability violations with explainability data (affected files, fix suggestions, score breakdown)
- `violations[].line` - Line number (null for file-level or project-level violations)

### JUnit Format

For CI systems that consume JUnit XML:

```bash
pmat quality-gate --format=junit
```

### Markdown Format

For embedding in pull request comments:

```bash
pmat quality-gate --format=markdown
```

## Configurable Thresholds

Thresholds are configured in `.pmat-gates.toml` (project root). CLI flags override config values.

### Complexity Thresholds

Built-in complexity thresholds (not currently CLI-configurable):
- **Cyclomatic**: Recommended ≤ 25, Maximum ≤ 30
- **Cognitive**: Recommended ≤ 20, Maximum ≤ 25

### Dead Code Threshold

```toml
# .pmat-gates.toml
[dead_code]
# Library crates need higher threshold for public APIs
max_dead_code_pct = 30.0
```

### Entropy Configuration

```toml
# .pmat-gates.toml
[entropy]
enabled = true
# Files below this pattern diversity score are flagged (0.0-1.0)
min_pattern_diversity = 0.30
# Paths excluded from entropy analysis
exclude = ["examples/**", "benches/**"]
```

### Selective Check Execution

```bash
# Run only complexity and entropy
pmat quality-gate --checks complexity,entropy

# Run everything except duplicates
pmat quality-gate --checks complexity,satd,dead-code,entropy,coverage,sections,provability,security

# Fail CI if quality gate fails
pmat quality-gate --fail-on-violation --format json
```

## Single File Analysis

Analyze individual files for focused quality assessment:

```bash
# Analyze specific file
pmat quality-gate --file src/payment.rs

# With JSON output
pmat quality-gate --file src/payment.rs --format json
```

Single file analysis runs the same checks but scoped to one file. The output format is identical to project-wide analysis, with violations filtered to the target file.

## CI/CD Integration

### Fail on Quality Gate Violations

Use quality gates as build gates in CI/CD pipelines:

```bash
# Fail build if quality gate fails (exit code 1)
pmat quality-gate --fail-on-violation

# Specific checks only
pmat quality-gate --fail-on-violation --checks complexity,satd,entropy
```

### Exit Codes

Quality gates return meaningful exit codes:

- **0**: All checks passed (or `--fail-on-violation` not set)
- **1**: Quality gate violations found
- **2**: Analysis failed (tool error)

### GitHub Actions Integration

```yaml
name: Quality Gate

on: [push, pull_request]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install PMAT
        run: cargo install pmat

      - name: Run Quality Gate
        run: |
          pmat quality-gate \
            --format json \
            --fail-on-violation \
            --checks complexity,satd,entropy,provability \
            > quality-report.json

      - name: Upload Quality Report
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: quality-report
          path: quality-report.json
```

### GitLab CI Integration

```yaml
quality_gate:
  stage: test
  script:
    - pmat quality-gate --format junit --fail-on-violation > quality-report.xml
  artifacts:
    reports:
      junit: quality-report.xml
    expire_in: 1 week
  allow_failure: false
```

## Advanced Features

### SQL Querying of Quality Data

Quality gate data is stored in SQLite tables alongside the function index. Use `pmat sql` to query violations directly:

```bash
# Query entropy violations sorted by repetition count
pmat sql entropy-violations

# Query low-provability functions
pmat sql low-provability
```

**Entropy violations table schema:**
```sql
CREATE TABLE entropy_violations (
    id INTEGER PRIMARY KEY,
    file_path TEXT NOT NULL,
    pattern_type TEXT NOT NULL,
    pattern_hash TEXT NOT NULL,
    repetitions INTEGER NOT NULL,
    variation_score REAL NOT NULL,
    estimated_loc_reduction INTEGER NOT NULL,
    severity TEXT NOT NULL,
    example_code TEXT,
    UNIQUE(file_path, pattern_hash)
);
```

**Provability scores table schema:**
```sql
CREATE TABLE provability_scores (
    id INTEGER PRIMARY KEY,
    function_id INTEGER,
    file_path TEXT NOT NULL,
    function_name TEXT NOT NULL,
    provability_score REAL NOT NULL,
    verified_properties INTEGER DEFAULT 0,
    FOREIGN KEY (function_id) REFERENCES functions(id)
);
```

### Violation Explainability (Details)

Entropy and provability violations include a `details` field in JSON output with:
- **`affected_files`** - Which files contain the violation
- **`example_code`** - Code snippet demonstrating the pattern
- **`fix_suggestion`** - Actionable recommendation
- **`score_factors`** - Breakdown of how the score was computed

This enables automated triaging: parse the JSON, sort by impact, and generate fix suggestions programmatically.

### Custom Check Selection

Run only specific quality checks:

```bash
# Code structure checks only
pmat quality-gate --checks complexity,dead-code

# Code quality checks only
pmat quality-gate --checks satd,entropy,provability

# Security-focused
pmat quality-gate --checks security,provability
```

## Configuration Reference

### `.pmat-gates.toml` (Project Configuration)

The primary configuration file lives in the project root:

```toml
# .pmat-gates.toml - Quality Gate Configuration

[gates]
run_clippy = true
clippy_strict = true
run_tests = true
test_timeout = 300
check_coverage = true
min_coverage = 80.0
check_complexity = true
max_complexity = 10

[exclude]
# Paths excluded from quality gate checks
paths = [
    "tests/**",
    "examples/**",
    "benches/**",
    "**/target/**",
]

[entropy]
enabled = true
# Minimum pattern diversity score (0.0-1.0)
min_pattern_diversity = 0.30
exclude = ["examples/**", "benches/**"]

[dead_code]
# Library crates: public APIs count as "dead" since they aren't called internally
max_dead_code_pct = 30.0

[tdg]
# Exclude non-production code from TDG grade gate
exclude = [
    "examples/**",
    "scripts/**",
    "benches/**",
]

[comply]
# Secret detector false positive exclusions
yaml_secret_exclude_paths = [
    "contracts/**/*.yaml",
]
```

## Troubleshooting

### Common Issues

#### Analysis Takes Too Long
```bash
# Run only fast checks (skip entropy/provability)
pmat quality-gate --checks complexity,satd,dead-code

# Analyze single file
pmat quality-gate --file src/main.rs
```

#### False Positives in Entropy

Entropy analysis uses **structural code hashing** — code is normalized (identifiers and literals replaced with placeholders) before comparison, so only ≥3 structurally identical code blocks are flagged. This eliminates false positives where different logic happens to use the same API (e.g., multiple unrelated `.is_empty()` checks). Test files (`*_tests.rs`, `*tests_part*.rs`, `*.test.rs`, and the `tests/` directory) as well as `examples/` and `benches/` directories are excluded by default.

If you still see false positives, exclude additional paths:
```bash
# Exclude paths in .pmat-gates.toml
# [entropy]
# exclude = ["examples/**", "benches/**", "generated/**"]
```

#### Coverage Shows 0%
Coverage reads from `.pmat/coverage-cache.json`. Run `make coverage` first to populate the cache.

## Best Practices

### Development Workflow

1. **Pre-commit Checks**: Run quick quality gates before committing
2. **Feature Branch Gates**: Full analysis on feature branches  
3. **Integration Gates**: Strict quality gates on main branch
4. **Release Gates**: Comprehensive quality assessment before release

### Quality Standards

1. **Set Realistic Thresholds**: Start with current baseline, improve gradually
2. **Focus on Trends**: Monitor quality trends over time
3. **Prioritize Violations**: Address high-impact issues first
4. **Regular Reviews**: Review and adjust thresholds periodically

### Team Adoption

1. **Start Gradually**: Begin with warnings, move to enforcement
2. **Educate Team**: Ensure everyone understands quality standards
3. **Automate Everything**: Integrate quality gates into all workflows
4. **Provide Tools**: Give developers tools to meet quality standards

## Integration Examples

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "Running quality gate checks..."

if ! pmat quality-gate --fail-on-violation --checks complexity,satd,entropy; then
    echo "Quality gate failed. Commit rejected."
    echo "Fix quality issues before committing."
    exit 1
fi

echo "Quality gate passed. Proceeding with commit."
```

### Makefile Integration

```makefile
.PHONY: quality-gate quality-report

quality-gate:
	@echo "Running quality gate..."
	@pmat quality-gate --fail-on-violation

quality-report:
	@echo "Generating quality report..."
	@pmat quality-gate --format json > quality-report.json
	@pmat quality-gate --format markdown > quality-report.md
	@echo "Reports generated: quality-report.json, quality-report.md"

ci-quality: quality-gate
	@echo "CI quality checks passed"
```

## Summary

PMAT's quality gates provide comprehensive automated quality enforcement:

- **9 Check Types**: Complexity, SATD, dead code, coverage, entropy, provability, security, duplicates, sections
- **Explainable Violations**: Entropy and provability violations include `details` with affected files, fix suggestions, and score breakdowns
- **6 Output Formats**: Summary, human, JSON, detailed, JUnit, Markdown
- **SQL Queryable**: Quality data stored in SQLite tables for ad-hoc analysis
- **Configurable**: `.pmat-gates.toml` for project-specific thresholds
- **CI/CD Ready**: `--fail-on-violation` flag with meaningful exit codes

Use quality gates to:
1. **Enforce Standards**: Maintain consistent code quality across teams
2. **Prevent Regression**: Catch quality degradation early in CI/CD
3. **Guide Refactoring**: Entropy analysis identifies DRY violations with LOC savings estimates
4. **Prove Safety**: Provability scores track formal verification amenability
5. **Query History**: SQL tables enable trend analysis across builds

## Next Steps

- [Chapter 4: Technical Debt Grading](ch04-01-tdg.md) - Advanced quality metrics
- [Chapter 5: Analyze Suite](ch05-00-analyze-suite.md) - Detailed code analysis
- [Chapter 6: Scaffold Command](ch06-00-scaffold.md) - Generate quality-focused projects