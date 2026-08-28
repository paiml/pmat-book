# First Analysis

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (5/5 examples)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 5 | All examples tested |
| ⚠️ Not Implemented | 0 | Planned for future versions |
| ❌ Broken | 0 | Known issues, needs fixing |
| 📋 Planned | 0 | Future roadmap features |

*Last updated: 2025-10-26*  
*PMAT version: pmat 2.213.1*
<!-- DOC_STATUS_END -->

## Your First Repository Analysis

Let's start by analyzing a simple project to understand what PMAT can do.

### Example 1: Analyzing Current Directory

The simplest way to use PMAT:

```bash
pmat analyze comprehensive
```

`analyze` is a parent command — `pmat analyze .` exits 2 with
`error: unrecognized subcommand`. `comprehensive` is the subcommand that runs
every analyser in one pass, and its `--path` defaults to `.`, so the bare form
above analyses the current directory.

**Output** (from a four-file Python/JavaScript project; progress lines go to
stderr, the report to stdout):

```
🔍 Running comprehensive analysis...
Warning: dead_code analysis failed: Cargo check failed: error: could not find `Cargo.toml` in /path/to/project

ℹ️  Duplicate detection is not part of comprehensive analysis; run `pmat analyze duplicates` for clone results.
🐛 Predicting defects...
✓ Comprehensive analysis completed
Comprehensive Code Analysis Report

Executive Summary

  Project analysis completed with 4 total files analyzed.

  Quality Score: 90.0%
  Total Files:   4
  Total Issues:  4
  Critical:      0

  Key Recommendations

    - Consider refactoring high-complexity functions
    - Address technical debt items (TODO/FIXME comments)

Complexity Analysis

  Files Analyzed:     4
  Average Complexity: 4.3
  Max Complexity:     39
  Violations:         1

  Top Complexity Violations

    1. ./src/payment_processor.py - process (complexity: 39)

Technical Debt (SATD) Analysis

  Files Analyzed: 2
  Violations:     3
```

Note the second line. Dead-code analysis is Rust-only, and on a Python project
it does not quietly report zero — it tells you it could not run. A `0` that
means "never measured" is the one number a quality tool must never print.

### Example 2: Analyzing a Specific Directory

Target a specific directory:

```bash
pmat analyze comprehensive --path /path/to/project
```

The path goes through `--path` (short `-p`). A positional path is rejected:
`pmat analyze comprehensive /path/to/project` fails with
`error: unexpected argument found`.

### Example 3: Analyzing with Technical Debt Grading

Get comprehensive quality metrics:

```bash
pmat analyze tdg -p . --include-components
```

**Output:**
```
🔍 Starting TDG (Technical Debt Grading) analysis...
╭─────────────────────────────────────────────────╮
│  Project TDG Score Report                       │
├─────────────────────────────────────────────────┤
│  Average Score: 97.2/100 (A+)                   │
│  Total Files: 4                                 │
│                                                 │
│  Language Distribution:                         │
│  ├─ Python      :   3 files (75.0%)             │
│  ├─ JavaScript  :   1 files (25.0%)             │
│                                                 │
│  Grade Distribution:                            │
│  ├─ A+:   3 files (75.0%)                       │
│  ├─ A:   1 files (25.0%)                        │
╰─────────────────────────────────────────────────╯

Component Breakdown (--include-components; points earned per metric):
  ./src/validate.py            structural  25.0  semantic  20.0  duplication  12.5  coupling  15.0  documentation   0.0  consistency  10.0
  ./src/payment_processor.py   structural  23.8  semantic  17.0  duplication  20.0  coupling  15.0  documentation   3.6  consistency  10.0
  ./lib/util.py                structural  25.0  semantic  19.0  duplication  20.0  coupling  15.0  documentation   0.0  consistency  10.0
  ./web/app.js                 structural  25.0  semantic  20.0  duplication  20.0  coupling  15.0  documentation  10.0  consistency  10.0

🔍 Checking for critical defects...
✅ No critical defects found
✅ TDG analysis complete
```

`analyze tdg` takes its path through `-p`/`--path` — `pmat analyze tdg .` fails
with `error: unexpected argument found`. For the whole-project one-line grade
without the per-file breakdown, the top-level `pmat tdg` command *does* take a
positional path: `pmat tdg .`.

### Example 4: Quick Analysis with Summary

For a quick overview without details:

```bash
pmat analyze comprehensive --executive-summary
```

**Output:**
```
Comprehensive Code Analysis Report

Executive Summary

  Project analysis completed with 4 total files analyzed.

  Quality Score: 90.0%
  Total Files:   4
  Total Issues:  4
  Critical:      0

  Key Recommendations

    - Consider refactoring high-complexity functions
    - Address technical debt items (TODO/FIXME comments)
```

(`--summary` is not a flag. `--executive-summary` is, and `--format summary` is
the default anyway.)

### Example 5: Analyzing a GitHub Repository

Analyze any public GitHub repository:

```bash
# Clone and analyze
git clone https://github.com/user/repo.git /tmp/repo
pmat analyze comprehensive --path /tmp/repo

# Or use the web demo
curl -X POST https://pmat-demo.paiml.com/api/analyze \
  -H "Content-Type: application/json" \
  -d '{"url": "https://github.com/user/repo"}'
```

## Understanding the Analysis Process

When you run `pmat analyze`, here's what happens:

1. **Discovery Phase** (< 1 second)
   - Scans directory structure
   - Identifies programming languages
   - Builds file index

2. **Analysis Phase** (1-5 seconds)
   - Parses source files
   - Calculates complexity metrics
   - Detects patterns and anti-patterns

3. **Grading Phase** (< 1 second)
   - Applies scoring algorithms
   - Generates recommendations
   - Produces final report

## Common Analysis Scenarios

### Scenario 1: Pre-Commit Check

Add to your git hooks:

```bash
#!/bin/bash
# .git/hooks/pre-commit
# quality-gate is the command that has a verdict. Since 3.32.0 it exits 1 on
# blocking violations by default, so the `if` below is belt-and-braces.
pmat quality-gate -p . --checks complexity --checks satd
if [ $? -ne 0 ]; then
  echo "Code quality below threshold. Please improve before committing."
  exit 1
fi
```

`pmat analyze ...` reports; `pmat quality-gate` judges. There is no
`--threshold B` on either — `quality-gate` reads its thresholds from
`.pmat-metrics.toml` when one exists and from built-in defaults otherwise, and
it says which it used (`⚙️  Complexity thresholds: cyclomatic 30, cognitive 25
(from built-in defaults)`).

### Scenario 2: CI/CD Integration

Add to your GitHub Actions:

```yaml
- name: Run PMAT Analysis
  run: |
    cargo install pmat
    pmat analyze comprehensive -p . --format json > pmat-report.json
    
- name: Upload PMAT Report
  uses: actions/upload-artifact@v2
  with:
    name: pmat-report
    path: pmat-report.json
```

### Scenario 3: Team Dashboard

Generate HTML reports:

```bash
pmat analyze comprehensive -p . --format markdown > report.md
```

There is no HTML output format. `analyze comprehensive` accepts `summary`,
`detailed`, `json`, `markdown` and `sarif`; `--format html` exits 2 with a clap
error listing those five.

## Tips for Effective Analysis

1. **Start Small**: Begin with a single module or directory
2. **Regular Scans**: Run daily to track quality trends
3. **Set Thresholds**: Define minimum acceptable grades
4. **Act on Recommendations**: Fix issues as they're found
5. **Track Progress**: Save reports to monitor improvement

## Troubleshooting

### Large Repository Taking Too Long

Narrow the walk, or raise the budget. There is no sampling flag.
```bash
# Only the directories you care about
pmat analyze comprehensive -p . --include "src/**"

# Or raise the 300-second default walk budget
pmat analyze complexity -p . --timeout 900
```

### Binary Files Causing Issues

Exclude them by glob:
```bash
pmat analyze comprehensive -p . --exclude "**/*.bin"
```

For exclusions you want to apply to *every* analyser rather than one command,
put them in `.pmatignore` — see [Chapter 30](ch30-00-file-exclusions.md).

### Need More Detail

Increase verbosity:
```bash
pmat analyze comprehensive -p . --verbose
```

## Next Steps

Now that you've run your first analysis, let's dive deeper into [understanding the output](ch01-03-output.md) and what all the metrics mean.