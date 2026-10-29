# Chapter 5: The Analyze Command Suite

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (8/8 examples)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 8 | All analyze commands tested |
| ⚠️ Not Implemented | 0 | Planned for future versions |
| ❌ Broken | 0 | Known issues, needs fixing |
| 📋 Planned | 0 | Future roadmap features |

*Last updated: 2026-03-08*
*PMAT version: pmat 3.6.1*
*Test-Driven: All examples validated in `tests/ch05/test_analyze.sh`*
<!-- DOC_STATUS_END -->

## Comprehensive Code Analysis

The `pmat analyze` command suite provides deep insights into your codebase through multiple specialized analyzers. Each analyzer focuses on a specific aspect of code quality, helping you maintain high standards and identify improvement opportunities.

## Basic Analysis

`pmat analyze` is a **parent command**: on its own it has nothing to run, and
`pmat analyze .` fails with `error: unrecognized subcommand`. The subcommand that
runs every analyser at once is `comprehensive`, and it takes the project path
through `-p`/`--path`, never as a positional argument:

```bash
# Analyze current directory (--path defaults to `.`, so this is the short form)
pmat analyze comprehensive

# Analyze specific directory
pmat analyze comprehensive -p src/

# Analyze with detailed output
pmat analyze comprehensive -p . --format detailed

# Save analysis to file
pmat analyze comprehensive -p . --output analysis-report.txt
```

`pmat analyze --help` lists the other thirty-odd subcommands; the rest of this
chapter walks the ones you will reach for most.

### Example Output

Run against a four-file Python/JavaScript project with one deliberately gnarly
function and three TODO/FIXME/HACK comments, `pmat analyze comprehensive -p .`
prints this (progress lines on stderr, report on stdout):

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
  Critical:      4

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

  SATD Violations

    1. ./src/payment_processor.py:1 - Requirement (Low)
    2. ./src/payment_processor.py:14 - Defect (High)
    3. ./web/app.js:1 - Design (Medium)
```

Two things in that transcript are worth reading carefully rather than skipping:

- **Dead-code analysis is Rust-only.** On a non-Cargo project it does not
  silently report zero — it says why it could not run. A metric that reads `0`
  because it never executed is worse than no metric at all.
- **Duplicate detection is not included.** `comprehensive` says so on stderr and
  points you at `pmat analyze duplicates`, which is a separate pass.

## Complexity Analysis

Measure and track code complexity to maintain readability:

```bash
# Basic complexity analysis
pmat analyze complexity

# Set thresholds (there is no --threshold; there are two, one per metric)
pmat analyze complexity --max-cyclomatic 10
pmat analyze complexity --max-cognitive 15

# Analyze a specific directory (path goes through -p/--path, never positionally)
pmat analyze complexity -p src/

# Analyze one file
pmat analyze complexity --file src/parser.rs

# Output formats: summary (default), full, json, sarif. There is no csv.
pmat analyze complexity --format json

# CI/CD mode
pmat analyze complexity --max-cyclomatic 5 --fail-on-violation
```

The full option list is `-p/--path`, `--file`, `--files`, `--toolchain`,
`--format <summary|full|json|sarif>`, `-o/--output`, `--max-cyclomatic`,
`--max-cognitive`, `--include`, `--watch`, `--top-files`, `--fail-on-violation`,
`--timeout` and `--ml`. Note the three that earlier editions of this chapter
used and that do not exist: `--threshold`, `--detailed` and `--cognitive`.
Cognitive complexity is always computed; it is a column, not a mode.

### `--ml` is not implemented

The flag parses, and refuses to pretend:

```bash
pmat analyze complexity --ml
```

```
Error: --ml is not implemented: complexity scores are still computed by the heuristic formulas, so this flag would relabel them without changing them. Re-run `analyze complexity` without --ml (see GH-97).
```

Exit code 1. Its `--help` entry reads `NOT IMPLEMENTED: ML-based scoring
(aprender LinearRegression)`. There is no ML scoring in pmat 3.32.0, and the
"Benefits" list an earlier edition of this chapter attached to it described a
model that never ran.

### Understanding Complexity Metrics

Run against a four-file Rust crate whose `src/parser.rs` holds one deliberately
branchy function:

```bash
pmat analyze complexity
```

```
⏰ Analysis timeout set to 300 seconds
🔍 Analyzing rust project complexity (all languages)...
✅ Successfully analyzed 4 file(s)
   1 of 5 file(s) were not analyzed
   no complexity analyzer for: .toml (1)
Complexity Analysis Summary

  Files analyzed: 4
  Total functions: 8

Complexity Metrics

  Median Cyclomatic: 1.5
  Median Cognitive: 0.5
  Max Cyclomatic: 9
  Max Cognitive: 13
  90th Percentile Cyclomatic: 9
  90th Percentile Cognitive: 13

Top Files by Complexity

  1. src/parser.rs - Cyclomatic: 16, Cognitive: 19, Functions: 4
  2. src/lib.rs - Cyclomatic: 2, Cognitive: 1, Functions: 1
  3. src/util.rs - Cyclomatic: 2, Cognitive: 0, Functions: 2
  4. src/main.rs - Cyclomatic: 1, Cognitive: 0, Functions: 1
```

Two things the header lines earn their place by saying: **4 of 5 files were
analysed**, and the fifth was `Cargo.toml`, for which there is no analyser. A
tool that printed "4 files analyzed" alone would leave you unable to tell a
skipped file from an absent one.

Note also that a file's Cyclomatic (16 for `parser.rs`) is the **sum** over its
functions, while `Max Cyclomatic: 9` is the largest single function. Do not
compare the two columns.

### Per-function detail

`--file` expands one file into its functions:

```bash
pmat analyze complexity --file src/parser.rs
```

```
  1. src/parser.rs - Cyclomatic: 16, Cognitive: 19, Functions: 4

Functions in File

  1. depth (line 2-14) - Cyclomatic: 9, Cognitive: 13
  2. copy_a (line 16-16) - Cyclomatic: 3, Cognitive: 3
  3. copy_b (line 17-17) - Cyclomatic: 3, Cognitive: 3
  4. never_called (line 19-19) - Cyclomatic: 1, Cognitive: 0
```

Setting a threshold below the maximum turns the run into a gate:

```bash
pmat analyze complexity --max-cyclomatic 5 --fail-on-violation
```

```
Top Complexity Hotspots

  1. depth src/parser.rs:2 - cyclomatic complexity: 9


❌ Complexity violations found
```

Exit code 1.

> **Note**: In the terminal, headers appear bold+underlined, labels are bold,
> numbers are bold white, and file paths are cyan. Use `--format json` for
> machine-readable output without colors.

## Dead Code Detection

Identify and remove unused code to reduce maintenance burden:

```bash
# Find all dead code
pmat analyze dead-code

# Check a specific directory
pmat analyze dead-code -p src/

# Write the report to a file (there is no --export)
pmat analyze dead-code -o dead-code-list.txt

# Machine-readable
pmat analyze dead-code -f json
```

The option list is `-p/--path`, `-f/--format <summary|json|sarif|markdown>`,
`-t/--top-files`, `-u/--include-unreachable`, `--min-dead-lines`,
`--include-tests`, `-o/--output`, `--fail-on-violation` and `--max-percentage`
(default 15.0). `--export` and `--safe-only` never existed; there is no
safe-to-remove classification.

### Dead Code Report

```bash
pmat analyze dead-code
```

```
☠️ Analyzing dead code in project...
⏰ Analysis timeout set to 900 seconds
📊 Analysis complete: 4 files analyzed, 1 with dead code
Dead Code Analysis Summary

  Files analyzed: 4
  Files with dead code: 1
  Total dead lines: 5
  Dead code percentage: 14.7%

  Library target: library — cargo: .../Cargo.toml declares package `analyzedemo`, which has a library target, and rustc's dead-code pass treats its public API as reachable

  Compiler scan: full (compiler-lint-ran) — cargo check ran against the existing lockfile; rustc's dead-code lint contributed to these findings

Dead Code by Type

  Dead functions: 1
  Dead classes: 0
  Dead modules: 0
  Other (fields, constants, statics): 0
```

The two prose lines in the middle are the ones to read before acting on this
report. **`Library target: library`** means every `pub` item is treated as
reachable, so a crate that exposes a large public API will show almost no dead
code — `pub fn unused_util` in the fixture above is not counted, while the
private `fn never_called` is. **`Compiler scan: full (compiler-lint-ran)`**
means rustc's own lint contributed; if it reads otherwise, the findings are
heuristic only and weaker.

Gate on a percentage with `--max-percentage`:

```bash
pmat analyze dead-code --max-percentage 10 --fail-on-violation
```

## SATD Analysis

Self-Admitted Technical Debt (SATD) tracks developer-annotated issues:

```bash
# Find all SATD markers
pmat analyze satd

# Extended mode - detect euphemisms (NEW in v2.217.0)
pmat analyze satd --extended

# Filter by severity (there is no --priority)
pmat analyze satd --severity high

# Only the critical items
pmat analyze satd --critical-only

# Add the metrics summary (there is no --report)
pmat analyze satd --metrics

# Write a report to a file
pmat analyze satd -f markdown -o satd.md
```

`--categorize`, `--priority` and `--report` never existed. Categorisation is
unconditional — every violation is already labelled by type (`Defect`,
`Requirement`, …) and severity in the default output.

Run against the same four-file crate:

```bash
pmat analyze satd
```

```
🔍 Analyzing Self-Admitted Technical Debt (SATD)...
SATD Analysis Summary

Found 2 SATD violations in 2 files (analysed 4 of 4 file(s) walked)

Total violations:  2
Scope:  analysed 4 of 4 file(s) walked

Severity Distribution
  Critical: 0
  High: 1
  Medium: 0
  Low: 1

Top Violations
  1. ./src/parser.rs:1 - Defect High
  2. ./src/lib.rs:4 - Requirement Low
```

`analysed 4 of 4 file(s) walked` is the line that makes the count trustworthy:
it distinguishes "no debt" from "nothing was read". Filtering narrows it:

```bash
pmat analyze satd --severity high
```

```
Found 1 SATD violations in 1 files (analysed 4 of 4 file(s) walked)
```

And `--metrics` appends a breakdown:

```bash
pmat analyze satd --metrics
```

```
📊 SATD Metrics:
  Total files analyzed: 2
  Total violations: 2
  Critical violations: 0
  High violations: 1

  Top violation types:
    - Requirement: 1
    - Defect: 1
```

Note that `Total files analyzed: 2` in the metrics block counts files **with**
violations, while the summary above it says 4 files were walked. The two numbers
mean different things.

### Extended Mode (Issue #149)

**NEW in PMAT v2.217.0**: The `--extended` flag detects euphemisms commonly used by AI coding assistants to bypass traditional SATD detection:

| Pattern | Description | Example |
|---------|-------------|---------|
| `placeholder` | Incomplete implementation | "placeholder for real logic" |
| `stub` | Missing implementation | "stub method" |
| `simplified` | Corners cut | "simplified for now" |
| `for demo` | Non-production code | "for demonstration only" |
| `mock/dummy/fake` | Fake implementations | "mock implementation" |
| `hardcoded` | Missing configuration | "hardcoded value" |
| `for now` | Temporary solutions | "works for now" |
| `WIP` | Work in progress | "WIP: not complete" |
| `skip/bypass` | Missing validation | "skip validation for now" |

```bash
# Standard detection only (89 violations in the `pmat` source tree)
pmat analyze satd --path src/

# Extended detection (441 violations - catches 352 more hidden debt)
pmat analyze satd --extended --path src/

# CI/CD zero-tolerance with extended detection
pmat analyze satd --extended --strict --fail-on-violation
```

### `--evolution` is not implemented

`--evolution` and `--days` parse and then refuse, rather than printing an empty
trend:

```
Error: --evolution is not implemented for `analyze satd`: no debt history is computed, and --days selects nothing. Re-run without it.
```

Exit code 1. For debt over time, diff two `pmat analyze satd -f json` runs
yourself.

The `--extended --strict --fail-on-violation` form above exits 1 when it finds
anything, which is what you want in CI and is not an error in the command.

## Defects Analysis (Known Defects v2.1)

**NEW in PMAT v2.200.0**: Detect production-breaking defect patterns with zero-tolerance enforcement.

Identify critical defects that cause production failures:

```bash
# Scan all Rust files for critical defects
pmat analyze defects

# Scan specific directory
pmat analyze defects -p src/

# Scan single file
pmat analyze defects --file src/main.rs

# Filter by severity
pmat analyze defects --severity Critical
pmat analyze defects --severity High

# Output formats
pmat analyze defects --format text      # Colored terminal (default)
pmat analyze defects --format json      # CI/CD integration
pmat analyze defects --format junit     # Test framework integration
```

### Exit Codes

- **0**: No critical defects found
- **1**: Critical defects detected (triggers CI/CD failures)

### Defect Report Example

```
🛡️ Known Defects Report - v2.1
══════════════════════════════

📊 Summary:
Total Defects: 249
Critical: 8
High: 42
Medium: 123
Low: 76

Affected Files: 37/152 (24.3%)

🔴 CRITICAL DEFECTS (8)

Pattern: .unwrap() calls
Severity: Critical
Evidence: Cloudflare outage 2025-11-18 (3+ hour global disruption)
Fix: Use .expect() with descriptive messages or ? operator

Instances:
  1. src/services/api.rs:142:18
     Code: let result = operation().unwrap();

  2. src/handlers/auth.rs:89:25
     Code: let token = parse_jwt(raw).unwrap();

  3. src/utils/config.rs:56:32
     Code: let config = load_config().unwrap();

Fix Recommendation:
Replace .unwrap() with explicit error handling:

  // ❌ BEFORE - Causes panic
  let result = operation().unwrap();

  // ✅ AFTER - Descriptive error
  let result = operation()
      .expect("Bot feature file must be valid");

  // ✅ AFTER - Propagate error
  let result = operation()?;
```

### JSON Output (CI/CD Integration)

```json
{
  "summary": {
    "total_defects": 249,
    "critical": 8,
    "high": 42,
    "medium": 123,
    "low": 76,
    "affected_files": 37,
    "total_files": 152
  },
  "patterns": [
    {
      "id": "RUST-UNWRAP-001",
      "name": ".unwrap() calls",
      "severity": "Critical",
      "fix_recommendation": "Use .expect() or ? operator",
      "evidence": {
        "description": "Cloudflare outage 2025-11-18",
        "url": "https://blog.cloudflare.com/2025-01-18-outage"
      },
      "instances": [
        {
          "file": "src/services/api.rs",
          "line": 142,
          "column": 18,
          "snippet": "let result = operation().unwrap();"
        }
      ]
    }
  ]
}
```

### JUnit XML Output (Test Integration)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="Known Defects Report" tests="1" failures="8">
  <testsuite name="RUST-UNWRAP-001" tests="8" failures="8">
    <testcase name="src/services/api.rs:142" classname="defects.critical">
      <failure message=".unwrap() call detected (Critical severity)">
File: src/services/api.rs
Line: 142
Column: 18
Code: let result = operation().unwrap();

Fix: Use .expect() with descriptive messages or ? operator
Evidence: Cloudflare outage 2025-11-18
      </failure>
    </testcase>
  </testsuite>
</testsuites>
```

### Test Code Exclusion

Defect detection **automatically excludes** test code:
- `tests/` directory
- `benches/` directory
- `#[cfg(test)]` modules

Production code standards apply only to production code.

### Integration with TDG

Critical defects trigger **TDG auto-fail**:
- Score: 0.0/100
- Grade: F
- Exit code: 1

See Chapter 4.1: Known Defects v2.1 for TDG integration details.

### Integration with rust-project-score

Defects contribute to the "Known Defects" category scoring in `pmat rust-project-score`.

## Code Similarity Detection

There is no `pmat analyze similarity`. The subcommand is **`duplicates`**, and
it does clone detection by MinHash plus AST embeddings:

```bash
# Basic duplicate detection
pmat analyze duplicates

# Similarity threshold for semantic clones (0.0-1.0, default 0.85)
pmat analyze duplicates --threshold 0.8

# Detect one clone class (there is no --types 1,2,3)
pmat analyze duplicates --detection-type exact

# Ignore test files
pmat analyze duplicates --exclude "tests/**"
```

`--detection-type` takes `exact`, `renamed`, `gapped`, `semantic`, `fuzzy` or
`all` (default) — the named equivalents of the Type-1/2/3/4 taxonomy. The other
options are `-p/--path`, `--min-lines` (default 5), `--max-tokens` (default
128), `-f/--format <summary|detailed|human|json|csv|sarif>`, `--perf`,
`--include` and `--exclude`.

### The default `--min-lines` will hide short clones

This matters more than any flag on the command. The fixture used throughout this
chapter contains `copy_a` and `copy_b`, which are character-for-character
identical — and the default run finds nothing:

```bash
pmat analyze duplicates
```

```
Analyzing code similarity...
✓  Found 0 duplicate blocks
  Duplication: 0.0% (0 / 34 lines)

✓ Analysis Complete
Duplicate Code Analysis

Summary
  Total duplicate blocks: 0
  Duplicate lines: 0 / 34
  Duplication percentage: 0.0%
```

They are one-liners, and `--min-lines` defaults to 5. Lower it and they appear:

```bash
pmat analyze duplicates --min-lines 1
```

```
Analyzing code similarity...
✓  Found 2 duplicate blocks
  Duplication: 17.6% (6 / 34 lines)

✓ Analysis Complete
Duplicate Code Analysis

Summary
  Total duplicate blocks: 2
  Duplicate lines: 6 / 34
  Duplication percentage: 17.6%

Top Files by Duplication

  1. src/parser.rs - 21.1% duplication (4 / 19 lines)
  2. src/lib.rs - 16.7% duplication (2 / 12 lines)
```

0.0% and 17.6% on the same code, from one flag. A zero from this command means
"no clone at or above `--min-lines`", never "no duplication".

### Finding similarly-named functions

A different question — "what else is called something like this?" — is
`analyze name-similarity`, which takes the name as a positional:

```bash
pmat analyze name-similarity depth
```

```
🔍 Searching for names similar to 'depth'...
✅ Found 8 names to analyze
Name Similarity Analysis

  Query: depth

  Found: 2 matches out of 8 names searched

1. depth (score: 1.00)
   File: ./src/parser.rs:2
   Type: function
   Edit distance: 0

2. dispatch (score: 0.50)
```

## Dependency Analysis

There is no `pmat analyze dependencies`. The subcommand is **`dag`**, and it
renders a Mermaid graph:

```bash
# Full dependency graph (the default)
pmat analyze dag

# Pick the graph type
pmat analyze dag --dag-type call-graph
pmat analyze dag --dag-type import-graph
pmat analyze dag --dag-type inheritance

# Write it out
pmat analyze dag -o deps.mmd
```

```bash
pmat analyze dag
```

```
🔄 Generating dependency analysis graph...
📁 Analyzed 4 files
📊 full-dependency: rendered 14 nodes and 2 edges
graph TD
    src_lib[lib]
    src_lib_dispatch[dispatch]
    src_lib_parser[parser]
    src_lib_util[util]
    src_main[main]
    src_main_main[main]
    src_parser[parser]
    src_parser_copy_a[copy_a]
    src_parser_copy_b[copy_b]
    src_parser_depth[depth]
    src_parser_never_called[never_called]
    src_util[util]
    src_util_scale[scale]
    src_util_unused_util[unused_util]
```

The output is Mermaid text on stdout, not an image — there is no `--graph` flag
and no SVG renderer. Pipe it into a Mermaid renderer, or paste it into any
Markdown viewer that supports Mermaid.

`--dag-type` accepts `call-graph`, `import-graph`, `inheritance` and
`full-dependency` (default). Other options: `-p/--path`, `-o/--output`,
`--max-depth`, `--target-nodes` (applies graph reduction above that count),
`--filter-external`, `--show-complexity`, `--include-duplicates`,
`--include-dead-code`, `--enhanced`.

**There is no circular-dependency detector** and no dependency-vulnerability
check in `pmat analyze`. For cycle and centrality analysis over the same graph,
see `pmat analyze graph-metrics` and
[Chapter 26](ch26-00-graph-statistics.md). For dependency CVEs, use
`cargo audit` / `cargo deny`, or `pmat deps-audit` for the Sovereign-AI-stack
migration report.

## Architecture Analysis

**`pmat analyze architecture` does not exist and never has.** It is not in
`pmat analyze --help`, and every invocation exits 2 with "unrecognized
subcommand". There is no pattern detector for MVC/repository/service, and no
`--rules architecture.yaml` rules engine anywhere in pmat 3.32.0.

The closest real capability is structural, not pattern-based:

| You wanted | Use |
|------------|-----|
| Module structure and coupling | `pmat analyze dag`, `pmat analyze graph-metrics` |
| Which files are architecturally central | `pmat analyze graph-metrics --metrics page-rank` |
| Where a file should be split | `pmat split <FILE>` |
| Whole-project quality posture | `pmat analyze comprehensive`, `pmat tdg` |

## Security Analysis

**`pmat analyze security` does not exist either.** The real security check lives
on the quality gate:

```bash
pmat quality-gate --checks security
```

```
🔍 Running quality gate checks...

📋 Checks to run:
  ✓ Security vulnerabilities

  ⚠️  No .pmat/context.db found — violations not persisted to SQL
Quality Gate: PASSED
Total violations: 1
Blocking violations: 0

## scope (1 violations)
  - . - the security scan read 0 source file(s) directly under . and did NOT descend into subdirectories, so anything under src/ was not examined — a zero here is the scope's, not the tree's


✅ Quality gate PASSED (1 advisory finding(s), not blocking)
```

Read that scope violation before trusting the result: **the scan did not descend
into `src/`**, and `pmat` reports that as a finding rather than letting a
zero-findings result look like a clean bill of health. Point `--path` at the
directory you mean.

There is no secrets scanner (`--secrets`) and no CVE database
(`--vulnerabilities`) in pmat. Use `gitleaks`/`trufflehog` and
`cargo audit`/`cargo deny` respectively.

## Combined Analysis

Run multiple analyzers together:

```bash
# Run all analyzers
pmat analyze comprehensive -p .

# Run a specific combination — each analyser is opted in by name
pmat analyze comprehensive -p . --include-complexity --include-dead-code --include-tdg

# Executive summary only, for a build log
pmat analyze comprehensive -p . --executive-summary
```

> **Not available in pmat 3.32.0.** There is no `pmat analyze all`, no
> comma-separated `pmat analyze complexity,dead-code,satd`, and no
> `--profile`. `comprehensive` is the subcommand that runs the suite, and its
> `--include-*` flags are how you pick a subset. Note that duplicate detection
> is *not* one of them: run `pmat analyze duplicates` separately.

## Output Formats

`pmat analyze comprehensive` accepts five: `summary` (the default),
`detailed`, `json`, `markdown` and `sarif`. There is no `csv` and no `html`
— `--format html` exits 2 with a clap error listing the five that exist.

### JSON Format

```bash
pmat analyze comprehensive -p . --format json > analysis.json
```

Real output from the same four-file project as above, trimmed only where noted:

```json
{
  "complexity": {
    "total_files": 4,
    "violations": [
      {
        "file_path": "./src/payment_processor.py",
        "function_name": "process",
        "line_number": 4,
        "complexity": 39,
        "complexity_type": "cognitive-complexity"
      }
    ],
    "average_complexity": 4.333333333333333,
    "max_complexity": 39,
    "summary": "Analyzed 4 file(s) in . with 1 violation(s)"
  },
  "dead_code": null,
  "satd": {
    "total_files": 2,
    "violations": [
      {
        "file_path": "./src/payment_processor.py",
        "line_number": 1,
        "violation_type": "Requirement",
        "message": "TODO: extract the fee table into config",
        "severity": "Low"
      },
      {
        "file_path": "./src/payment_processor.py",
        "line_number": 14,
        "violation_type": "Defect",
        "message": "FIXME: unsupported currency silently falls through",
        "severity": "High"
      },
      {
        "file_path": "./web/app.js",
        "line_number": 1,
        "violation_type": "Design",
        "message": "HACK: hardcoded until the config service lands",
        "severity": "Medium"
      }
    ],
    "summary": "Found 3 SATD violations in 2 files (analysed 4 of 4 file(s) walked)",
    "census": {
      "discovered": 4,
      "analyzed": 4,
      "not_read": {
        "tests": 0,
        "out_of_scope": 0,
        "minified_or_vendor": 0,
        "too_large": 0,
        "unreadable": 0
      },
      "oversized": []
    }
  },
  "summary": {
    "total_files": 4,
    "total_issues": 4,
    "critical_issues": 4,
    "quality_score": 90.0,
    "recommendations": [
      "Consider refactoring high-complexity functions",
      "Address technical debt items (TODO/FIXME comments)"
    ]
  },
  "duration_ms": 55
}
```

`"dead_code": null` is the JSON spelling of "this analyser did not run" —
distinct from a zero. The `satd.census` block reports what the walk saw versus
what it read, so a shrinking violation count cannot be mistaken for progress
when it was really a shrinking denominator.

### SARIF (for IDEs and code scanning)

```bash
pmat analyze comprehensive -p . --format sarif > analysis.sarif
```

### Markdown Report

```bash
pmat analyze comprehensive -p . --format markdown > ANALYSIS.md
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Code Quality Analysis

on: [push, pull_request]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install PMAT
        run: cargo install pmat
        
      - name: Run Analysis
        run: |
          pmat analyze comprehensive -p . --format json > analysis.json
          pmat analyze complexity -p . --max-cyclomatic 10
          pmat analyze dead-code -p .
          pmat analyze satd -p . --severity high
          
      - name: Check Quality Gates
        run: |
          complexity=$(jq '.complexity.max_complexity' analysis.json)
          if [ "$complexity" -gt 20 ]; then
            echo "❌ Complexity too high: $complexity"
            exit 1
          fi
          
      - name: Upload Reports
        uses: actions/upload-artifact@v3
        with:
          name: analysis-reports
          path: analysis.json
```

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Run analysis on staged files
staged=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(py|js|ts)$')

if [ -n "$staged" ]; then
    echo "Running PMAT analysis..."
    
    # Check complexity. --files takes a comma-separated list, so turn the
    # newline-separated staged list into one.
    if ! pmat analyze complexity --files "$(echo "$staged" | paste -sd,)" \
            --max-cyclomatic 10 --fail-on-violation; then
        echo "❌ Complexity check failed"
        exit 1
    fi

    # Count SATD. There is no --count flag; read the JSON.
    satd=$(pmat analyze satd -f json | jq '.total_violations')
    echo "SATD items: $satd"
fi
```

## Configuration

### Analysis Configuration

```toml
# .pmat/analyze.toml

[complexity]
threshold = 10
cognitive = true
by_function = true

[dead_code]
safe_only = false
exclude = ["tests/", "*_test.py"]

[satd]
patterns = ["TODO", "FIXME", "HACK", "XXX", "BUG", "REFACTOR"]
priority_keywords = {
    high = ["SECURITY", "CRITICAL", "URGENT"],
    medium = ["IMPORTANT", "SOON"],
    low = ["LATER", "MAYBE"]
}

[similarity]
threshold = 0.8
min_lines = 5
types = [1, 2, 3]

[dependencies]
check_circular = true
check_vulnerabilities = true
max_depth = 5

[output]
format = "detailed"
include_recommendations = true
```

## Best Practices

1. **Regular Analysis**: Run analysis daily or on every commit
2. **Set Thresholds**: Define acceptable complexity and duplication levels
3. **Track Trends**: Monitor metrics over time, not just snapshots
4. **Prioritize Fixes**: Address high-complexity and security issues first
5. **Automate Gates**: Fail builds when quality drops below standards
6. **Document Debt**: When adding SATD, include priority and estimated fix time
7. **Refactor Incrementally**: Address duplication and complexity gradually

## Troubleshooting

### Analysis Takes Too Long

```bash
# Raise the walk budget (default 300s, reported on stderr)
pmat analyze complexity -p . --timeout 900

# Narrow the walk to the code you care about
pmat analyze comprehensive -p . --include "src/**"

# Exclude large directories
pmat analyze comprehensive -p . --exclude "node_modules/**"
```

Longer term, put the directories you never want walked into `.pmatignore` — see
[Chapter 30](ch30-00-file-exclusions.md). That applies to every analyser at once
rather than to a single invocation.

### Missing Language Support

```bash
# List the analyzers, and the languages each one names
pmat analyze --help

# Restrict a pass to one detected toolchain
pmat analyze complexity -p . --toolchain rust
```

`pmat analyze complexity` reports what it *could not* read as well as what it
did — `no complexity analyzer for: .yaml (1)` — so an unsupported language shows
up as an explicit skip line rather than as a quietly smaller file count. If a
whole run produces no metrics, it exits non-zero and says so.

### Memory Issues

There is no memory cap or chunking flag. The lever that actually exists is
scoping the walk: analyse one subtree at a time.

```bash
pmat analyze complexity -p src/
pmat analyze complexity --files src/parser.rs,src/util.rs
```

`--files` takes a comma-separated list and analyses exactly those files.

> **Not available in pmat 3.32.0.** Earlier printings of this section showed
> `--parallel`, `--incremental`, `--generic`, `--max-memory` and `--chunk-size`
> on `pmat analyze`, plus a bare `pmat analyze --languages`. None of those flags
> exist, and `pmat analyze` needs a subcommand before any flag is even parsed.

## Summary

The `pmat analyze` suite provides comprehensive insights into:
- **Code Complexity**: Identify hard-to-maintain code
- **Dead Code**: Find and remove unused code
- **Technical Debt**: Track and manage SATD
- **Duplication**: Detect and refactor similar code
- **Dependencies**: Understand coupling and vulnerabilities
- **Architecture**: Validate patterns and structure

Master these tools to maintain high code quality and reduce technical debt systematically.

## Next Steps

- [Chapter 6: Pre-commit Hooks](ch09-00-precommit-hooks.md) - Automate quality checks
- [Chapter 4: Technical Debt Grading](ch04-01-tdg.md) - Advanced debt metrics
- [Chapter 9: Quality-Driven Development](ch14-00-qdd.md) - Quality-first coding