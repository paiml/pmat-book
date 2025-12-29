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
pmat analyze .
```

**Output:**
```json
{
  "repository": {
    "path": "/home/user/my-project",
    "total_files": 42,
    "total_lines": 3847,
    "languages": {
      "Python": {
        "files": 15,
        "lines": 2103,
        "percentage": 54.7
      },
      "JavaScript": {
        "files": 10,
        "lines": 892,
        "percentage": 23.2
      },
      "Markdown": {
        "files": 8,
        "lines": 652,
        "percentage": 16.9
      },
      "JSON": {
        "files": 9,
        "lines": 200,
        "percentage": 5.2
      }
    },
    "complexity": {
      "average": 3.2,
      "max": 15,
      "high_complexity_functions": 2
    }
  }
}
```

### Example 2: Analyzing a Specific Directory

Target a specific directory:

```bash
pmat analyze /path/to/project
```

### Example 3: Analyzing with Technical Debt Grading

Get comprehensive quality metrics:

```bash
pmat analyze tdg .
```

**Output:**
```json
{
  "grade": "B+",
  "overall_score": 82.5,
  "components": {
    "structural_complexity": {
      "score": 85.0,
      "grade": "B+",
      "details": {
        "cyclomatic_complexity_avg": 3.2,
        "cognitive_complexity_avg": 4.1,
        "nesting_depth_max": 3
      }
    },
    "code_duplication": {
      "score": 90.0,
      "grade": "A-",
      "details": {
        "duplication_ratio": 0.02,
        "duplicate_blocks": 3
      }
    },
    "documentation_coverage": {
      "score": 75.0,
      "grade": "C+",
      "details": {
        "documented_functions": 45,
        "total_functions": 60,
        "coverage_percentage": 75.0
      }
    }
  },
  "recommendations": [
    "Add documentation to 15 undocumented functions",
    "Refactor high-complexity function at src/analyzer.py:142",
    "Consider extracting duplicate code block found in 3 locations"
  ]
}
```

### Example 4: Quick Analysis with Summary

For a quick overview without details:

```bash
pmat analyze . --summary
```

**Output:**
```
Repository: /home/user/project
Files: 42 | Lines: 3,847 | Languages: 4
Grade: B+ (82.5/100)
Top Issues: Missing docs (15), High complexity (2), Duplicates (3)
```

### Example 5: Analyzing a GitHub Repository

Analyze any public GitHub repository:

```bash
# Clone and analyze
git clone https://github.com/user/repo.git /tmp/repo
pmat analyze /tmp/repo

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
pmat analyze . --threshold B
if [ $? -ne 0 ]; then
  echo "Code quality below threshold. Please improve before committing."
  exit 1
fi
```

### Scenario 2: CI/CD Integration

Add to your GitHub Actions:

```yaml
- name: Run PMAT Analysis
  run: |
    cargo install pmat
    pmat analyze . --format json > pmat-report.json
    
- name: Upload PMAT Report
  uses: actions/upload-artifact@v2
  with:
    name: pmat-report
    path: pmat-report.json
```

### Scenario 3: Team Dashboard

Generate HTML reports:

```bash
pmat analyze . --format html > report.html
open report.html  # Opens in browser
```

## Tips for Effective Analysis

1. **Start Small**: Begin with a single module or directory
2. **Regular Scans**: Run daily to track quality trends
3. **Set Thresholds**: Define minimum acceptable grades
4. **Act on Recommendations**: Fix issues as they're found
5. **Track Progress**: Save reports to monitor improvement

## Troubleshooting

### Large Repository Taking Too Long

Use sampling for quick overview:
```bash
pmat analyze . --sample 1000  # Analyze first 1000 files
```

### Binary Files Causing Issues

Exclude binary files:
```bash
pmat analyze . --exclude "*.bin,*.exe,*.jpg"
```

### Need More Detail

Increase verbosity:
```bash
pmat analyze . --verbose
```

## Next Steps

Now that you've run your first analysis, let's dive deeper into [understanding the output](ch01-03-output.md) and what all the metrics mean.