# Understanding Output

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | All | All output formats documented |
| ⚠️ Not Implemented | 0 | Planned for future versions |
| ❌ Broken | 0 | Known issues, needs fixing |
| 📋 Planned | 0 | Future roadmap features |

*Last updated: 2026-03-08*
*PMAT version: pmat 3.6.1*
<!-- DOC_STATUS_END -->

## Colorized Terminal Output

Starting with v3.6.1, all PMAT CLI commands use a standardized colorized output system for terminal display. The shared `cli::colors` module provides consistent styling across every command:

| Element | Style | Example |
|---------|-------|---------|
| Headers | Bold + Underline | `Complexity Analysis Summary` |
| Labels | Bold | `Files analyzed:` |
| Numbers | Bold White | `15` |
| File paths | Cyan | `src/cli/colors.rs` |
| Pass/Success | Green with checkmark | `✓ analysis.complexity` |
| Fail/Error | Red with cross | `✗ Dead code detected` |
| Warnings | Yellow | `⚠ 5 files over threshold` |
| Dimmed text | Gray | `(142μs)` |
| Grades | Color-coded | A+=Green, B=Yellow, F=Red |
| Percentages | Threshold-based | Green ≥ good, Yellow ≥ warn, Red below |

### Example: Diagnostics Output

```
PMAT Self-Diagnostic Report
  Version: 3.6.1    Duration: 0ms

✓ analysis.complexity (0μs)
✓ analysis.deep_context (6μs)
✓ ast.python (0μs)
✓ ast.rust (137μs)
✓ ast.typescript (0μs)
✓ cache.subsystem (50μs)
✓ integration.git (4μs)
✓ output.mermaid (0μs)

Summary:
  Total: 8
  Passed: 8
  Failed: 0
  Success Rate: 100.0%
```

### Example: Complexity Analysis

```
Complexity Analysis Summary

  Files analyzed: 1
  Total functions: 15

Complexity Metrics

  Median Cyclomatic: 1.0
  Median Cognitive: 0.0
  Max Cyclomatic: 7
  Max Cognitive: 10

Top Files by Complexity

  1. src/cli/colors.rs - Cyclomatic: 26, Cognitive: 19, Functions: 15
```

### Disabling Colors

Colors are automatically disabled when piping output or when the terminal does not support ANSI codes. You can also control color output with environment variables:

```bash
# Disable colors
NO_COLOR=1 pmat analyze complexity --file src/main.rs

# Force colors (even when piping)
CLICOLOR_FORCE=1 pmat diagnose | less -R
```

### Machine-Readable Output

When using `--format json` or `--format sarif`, PMAT outputs clean machine-readable data with no ANSI codes. (There is no `yaml` format.) Use these formats for CI/CD pipelines, scripting, and tool integration.

## Output Formats

PMAT supports multiple output formats to integrate with your workflow:

`pmat analyze` is a parent command — every example below names a subcommand.
`comprehensive` is the one that runs the whole suite; `--path` defaults to `.`,
so it is written out only where the path matters. Progress lines go to stderr
and the document to stdout, so `| jq` needs no pre-filtering.

`analyze comprehensive` accepts five formats: `summary` (the default),
`detailed`, `json`, `markdown` and `sarif`.

### JSON Format

Structured data for programmatic use:

```bash
pmat analyze comprehensive --path . --format json
```

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
    "summary": "Found 3 SATD violations in 2 files (analysed 4 of 4 file(s) walked)",
    "census": {
      "discovered": 4,
      "analyzed": 4,
      "not_read": { "tests": 0, "out_of_scope": 0, "minified_or_vendor": 0, "too_large": 0, "unreadable": 0 }
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

Two fields repay attention. `"dead_code": null` means that analyser did not run
(it is Rust-only) — distinct from a measured zero. `satd.census` reports the
population the walk actually read, so a falling violation count cannot be
mistaken for progress when the denominator moved instead.

### Markdown Format

Human-readable reports:

```bash
pmat analyze comprehensive --path . --format markdown
```

```markdown
# Comprehensive Code Analysis Report

## Complexity Analysis

- **Files Analyzed**: 4
- **Average Complexity**: 4.3
- **Max Complexity**: 39
- **Violations**: 1

### Top Complexity Violations

1. ./src/payment_processor.py - process (complexity: 39)

## Technical Debt (SATD) Analysis

- **Files Analyzed**: 2
- **Violations**: 3

### SATD Violations

1. ./src/payment_processor.py:1 - Requirement (Low)
2. ./src/payment_processor.py:14 - Defect (High)
3. ./web/app.js:1 - Design (Medium)
```

For a letter grade rather than raw counts, use `pmat analyze tdg --path .`
(or `pmat tdg .`), which is where A+–F grading lives.

### Detailed Format

The default `summary` format with every section expanded:

```bash
pmat analyze comprehensive --path . --format detailed
```

### SARIF Format

For IDE and CI/CD integration:

```bash
pmat analyze comprehensive --path . --format sarif > analysis.sarif
```

```json
{
  "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
  "version": "2.1.0",
  "runs": [
    {
      "tool": {
        "driver": {
          "name": "pmat-comprehensive",
          "version": "3.32.0",
          "informationUri": "https://github.com/paiml/paiml-mcp-agent-toolkit"
        }
      },
      "results": [
        {
          "ruleId": "high-complexity",
          "level": "error",
          "message": { "text": "Function process has complexity 39" },
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": { "uri": "./src/payment_processor.py" },
                "region": { "startLine": 4 }
              }
            }
          ]
        }
      ]
    }
  ]
}
```

Compatible with:
- GitHub Code Scanning
- Visual Studio Code
- Azure DevOps
- GitLab

> **Not available in pmat 3.32.0.** Earlier printings of this chapter documented
> `--format html` and `--format csv` here, with sample reports. Neither exists:
> `--format html` exits 2 with a clap error naming the five formats that do.
> `pmat quality-gate` additionally offers `human` and `junit`, and
> `pmat context` offers `llm-optimized` — but no command emits HTML or CSV.

## Key Metrics Explained

### Complexity Metrics

**Cyclomatic Complexity**: Number of independent paths through code
- **1-4**: Simple, low risk
- **5-7**: Moderate complexity
- **8-10**: Complex, needs attention
- **11+**: Very complex, refactor recommended

**Cognitive Complexity**: How hard code is to understand
- Penalizes nested structures
- Rewards linear flow
- Better predictor of maintainability

### Duplication Metrics

**Type-1 (Exact)**: Identical code blocks
```python
# Found in file1.py and file2.py
def calculate_tax(amount):
    return amount * 0.08
```

**Type-2 (Renamed)**: Same structure, different names
```python
# file1.py
def calc_tax(amt):
    return amt * 0.08

# file2.py  
def compute_tax(value):
    return value * 0.08
```

**Type-3 (Modified)**: Similar with changes
```python
# file1.py
def calc_tax(amt):
    return amt * 0.08

# file2.py
def calc_tax(amt, rate=0.08):
    return amt * rate
```

**Type-4 (Semantic)**: Different code, same behavior
```python
# file1.py
sum([1, 2, 3])

# file2.py
result = 0
for n in [1, 2, 3]:
    result += n
```

### Quality Grades

PMAT uses academic-style grading:

| Grade | Score | Description |
|-------|-------|-------------|
| A+ | 97-100 | Exceptional quality |
| A | 93-96 | Excellent |
| A- | 90-92 | Very good |
| B+ | 87-89 | Good |
| B | 83-86 | Above average |
| B- | 80-82 | Satisfactory |
| C+ | 77-79 | Acceptable |
| C | 73-76 | Needs improvement |
| C- | 70-72 | Below average |
| D | 60-69 | Poor |
| F | <60 | Failing |

## Understanding Recommendations

PMAT provides actionable recommendations:

### Priority Levels

```json
{
  "recommendations": [
    {
      "priority": "HIGH",
      "type": "complexity",
      "message": "Refactor function 'process_data' (complexity: 28)",
      "location": "src/processor.py:142",
      "effort": "2 hours"
    },
    {
      "priority": "MEDIUM",
      "type": "duplication",
      "message": "Extract common code into shared function",
      "locations": ["src/a.py:20", "src/b.py:45"],
      "effort": "30 minutes"
    },
    {
      "priority": "LOW",
      "type": "documentation",
      "message": "Add docstring to 'helper_function'",
      "location": "src/utils.py:88",
      "effort": "5 minutes"
    }
  ]
}
```

### Acting on Recommendations

**High Priority**: Address immediately
- Security vulnerabilities
- Critical complexity
- Major duplication

**Medium Priority**: Plan for next sprint
- Moderate complexity
- Documentation gaps
- Minor duplication

**Low Priority**: Continuous improvement
- Style issues
- Nice-to-have documentation
- Micro-optimizations

## Filtering and Focusing Output

### Focus on Specific Metrics

Each analyser is its own subcommand, so "only complexity" means running only
that subcommand. `analyze comprehensive` opts analysers in by name:

```bash
# Only complexity
pmat analyze complexity --path .

# Only duplication (comprehensive deliberately excludes it — it says so on stderr)
pmat analyze duplicates --path .

# Two analysers in one comprehensive pass
pmat analyze comprehensive --path . --include-complexity --include-tdg
```

### Filter by Severity

```bash
# Only high-severity self-admitted debt
pmat analyze satd --path . --severity high

# Critical only
pmat analyze satd --path . --critical-only
```

`--severity` takes exactly one of `low`, `medium`, `high`, `critical` — not a
comma-separated list.

### Language-Specific Analysis

```bash
# Only the Python files
pmat analyze complexity --path . --toolchain python-uv

# Only the Rust files
pmat analyze complexity --path . --toolchain rust
```

`--toolchain` takes one value (`rust`, `deno` or `python-uv`), not a list. To
scope by file instead, use `--include "**/*.py"`.

## Integration Examples

### VS Code Integration

```json
// .vscode/tasks.json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "PMAT Analysis",
      "type": "shell",
      "command": "pmat analyze comprehensive --path . --format sarif > pmat.sarif",
      "problemMatcher": "$pmat"
    }
  ]
}
```

### Git Pre-Push Hook

```bash
#!/bin/bash
# .git/hooks/pre-push
GRADE=$(pmat analyze tdg --path . --format json | jq -r '.average_grade')
if [[ "$GRADE" < "B" ]]; then
  echo "Warning: Code quality grade $GRADE is below B"
  read -p "Continue push? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi
```

## Next Steps

Now that you understand PMAT's output, explore:
- [Chapter 2: Core Concepts](ch02-00-core-concepts.md) - Deep dive into analysis
- [Chapter 3: MCP Protocol](ch03-00-mcp-protocol.md) - AI agent integration
- [Chapter 4: Advanced Features](ch04-00-advanced.md) - TDG and similarity detection