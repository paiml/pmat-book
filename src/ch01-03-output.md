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

When using `--format json`, `--format yaml`, or `--format sarif`, PMAT outputs clean machine-readable data with no ANSI codes. Use these formats for CI/CD pipelines, scripting, and tool integration.

## Output Formats

PMAT supports multiple output formats to integrate with your workflow:

### JSON Format (Default)

Structured data for programmatic use:

```bash
pmat analyze . --format json
```

```json
{
  "timestamp": "2025-10-26T10:30:00Z",
  "version": "2.173.0",
  "repository": {
    "path": "/workspace/project",
    "vcs": "git",
    "branch": "main"
  },
  "summary": {
    "total_files": 156,
    "total_lines": 12847,
    "total_functions": 342,
    "total_classes": 48
  },
  "languages": {
    "Python": {
      "files": 89,
      "lines": 8234,
      "percentage": 64.1
    }
  },
  "metrics": {
    "complexity": {
      "cyclomatic": {
        "average": 3.4,
        "median": 2.0,
        "p95": 12.0,
        "max": 28.0
      }
    }
  }
}
```

### Markdown Format

Human-readable reports:

```bash
pmat analyze . --format markdown
```

```markdown
# Repository Analysis Report

**Date**: 2025-10-26
**Repository**: /workspace/project
**PMAT Version**: 2.173.0

## Summary
- **Total Files**: 156
- **Total Lines**: 12,847
- **Primary Language**: Python (64.1%)

## Quality Grade: B+
Overall Score: 82.5/100

### Breakdown
| Metric | Score | Grade |
|--------|-------|-------|
| Complexity | 85 | B+ |
| Duplication | 90 | A- |
| Documentation | 75 | C+ |
```

### HTML Format

Interactive web reports:

```bash
pmat analyze . --format html > report.html
```

Features:
- Interactive charts
- Drill-down capabilities
- Exportable visualizations
- Team sharing ready

### CSV Format

For spreadsheet analysis:

```bash
pmat analyze . --format csv
```

```csv
file_path,language,lines,complexity,duplication,documentation
src/main.py,Python,234,3.2,0.02,0.85
src/utils.py,Python,156,2.1,0.00,0.92
```

### SARIF Format

For IDE and CI/CD integration:

```bash
pmat analyze . --format sarif
```

Compatible with:
- GitHub Code Scanning
- Visual Studio Code
- Azure DevOps
- GitLab

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

```bash
# Only show complexity issues
pmat analyze . --metrics complexity

# Only show duplication
pmat analyze . --metrics duplication

# Multiple metrics
pmat analyze . --metrics "complexity,documentation"
```

### Filter by Severity

```bash
# Only high-priority issues
pmat analyze . --severity high

# High and medium
pmat analyze . --severity "high,medium"
```

### Language-Specific Analysis

```bash
# Only analyze Python files
pmat analyze . --languages python

# Multiple languages
pmat analyze . --languages "python,javascript"
```

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
      "command": "pmat analyze . --format sarif > pmat.sarif",
      "problemMatcher": "$pmat"
    }
  ]
}
```

### Git Pre-Push Hook

```bash
#!/bin/bash
# .git/hooks/pre-push
GRADE=$(pmat analyze . --format json | jq -r '.grade')
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