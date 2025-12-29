# Chapter 7: Quality Gates - Automated Quality Enforcement

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (8/8 examples)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 8 | All quality gate features tested |
| ⚠️ Not Implemented | 0 | Planned for future versions |
| ❌ Broken | 0 | Known issues, needs fixing |
| 📋 Planned | 0 | Future roadmap features |

*Last updated: 2025-09-09*  
*PMAT version: pmat 2.213.1*  
*Test-Driven: All examples validated in `tests/ch07/test_quality_gate.sh`*
<!-- DOC_STATUS_END -->

## Automated Quality Enforcement

Quality gates are automated checkpoints that enforce code quality standards across your project. PMAT's quality gate system provides comprehensive analysis and configurable thresholds to maintain high-quality codebases consistently.

## Basic Quality Gate Analysis

### Run All Quality Checks

Start with a comprehensive quality assessment:

```bash
# Analyze entire project
pmat quality-gate .

# Analyze specific directory
pmat quality-gate src/

# Include performance metrics
pmat quality-gate . --performance
```

### Example Output

```
🚦 Quality Gate Report
======================

Project: my-application
Checks Run: 6
Time: 2.3s

## Results Summary

✅ PASSED: 4/6 checks
❌ FAILED: 2/6 checks

## Failed Checks

❌ Complexity Check
   - Function process_payment: Cyclomatic complexity 15 > threshold 10
   - Function validate_user: Cyclomatic complexity 12 > threshold 10
   - Files with high complexity: 2

❌ SATD (Technical Debt) Check
   - TODO items found: 12
   - FIXME items found: 8
   - HACK items found: 3
   - Total technical debt markers: 23

## Passed Checks

✅ Dead Code Check (2.1% dead code < 15% threshold)
✅ Documentation Check (89% documented > 80% threshold)
✅ Lint Check (No violations found)
✅ Coverage Check (82% > 60% threshold)

Overall Status: ❌ FAILED
Quality Score: 67/100

🔧 Recommendations:
1. Refactor high-complexity functions
2. Address technical debt markers
3. Consider adding more unit tests
```

## Available Quality Checks

### Complexity Analysis

Monitor cyclomatic complexity to ensure maintainable code:

```bash
# Focus on complexity only
pmat quality-gate . --checks=complexity

# Custom complexity threshold
pmat quality-gate . --checks=complexity --max-complexity-p99=20
```

**Complexity Thresholds:**
- **Low**: 1-5 (Simple, easy to test)
- **Moderate**: 6-10 (Acceptable complexity)
- **High**: 11-20 (Consider refactoring)
- **Very High**: 21+ (Refactor immediately)

### Technical Debt Detection (SATD)

Track Self-Admitted Technical Debt markers:

```bash
# Check technical debt
pmat quality-gate . --checks=satd

# Multiple check types
pmat quality-gate . --checks=complexity,satd,dead_code
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
# Check for dead code
pmat quality-gate . --checks=dead_code --max-dead-code=10.0
```

**Dead Code Types:**
- Unused functions
- Unreachable code
- Unused variables
- Unused imports
- Deprecated methods

### Documentation Coverage

Ensure adequate code documentation:

```bash
# Check documentation coverage
pmat quality-gate . --checks=documentation --min-doc-coverage=80.0
```

### Lint Compliance

Verify code follows style guidelines:

```bash
# Run lint checks
pmat quality-gate . --checks=lint
```

### Test Coverage

Monitor test coverage levels:

```bash
# Check test coverage
pmat quality-gate . --checks=coverage --min-coverage=75.0
```

## Output Formats

### Summary Format (Default)

Concise overview for quick assessment:

```bash
pmat quality-gate . --format=summary
```

### Human-Readable Format

Detailed, formatted output for manual review:

```bash
pmat quality-gate . --format=human
```

**Output:**
```
🚦 Quality Gate Analysis
========================

Project Path: /path/to/project
Analysis Time: 1.8s

📊 Threshold Configuration:
   Max Complexity (P99): 10
   Max Dead Code: 15.0%
   Min Coverage: 60.0%
   Min Documentation: 80.0%

🔍 Analysis Results:

Complexity Analysis:
   ❌ Max complexity (15) exceeds threshold (10)
   ⚠️  Average complexity (7.2) is acceptable
   ❌ 2 functions exceed recommended complexity

Dead Code Analysis:
   ✅ Dead code percentage (2.1%) is below threshold (15.0%)
   ✅ No unused functions detected

Technical Debt Analysis:
   ❌ 23 technical debt markers found
   - TODO: 12 items (moderate priority)
   - FIXME: 8 items (high priority)  
   - HACK: 3 items (critical priority)

Coverage Analysis:
   ✅ Test coverage (82%) exceeds threshold (60%)
   ✅ All critical paths covered

Overall Result: ❌ FAILED
Quality Score: 67/100

🔧 Action Items:
1. Refactor process_payment function (complexity: 15)
2. Refactor validate_user function (complexity: 12)
3. Address 8 FIXME items (high priority)
4. Address 3 HACK items (critical priority)
```

### JSON Format

Machine-readable output for CI/CD integration:

```bash
pmat quality-gate . --format=json
```

**JSON Structure:**
```json
{
  "status": "failed",
  "timestamp": "2025-09-09T10:30:00Z",
  "project_path": "/path/to/project",
  "analysis_time_ms": 1847,
  "checks_run": ["complexity", "satd", "dead_code", "coverage", "documentation", "lint"],
  "thresholds": {
    "max_complexity_p99": 10,
    "max_dead_code_percentage": 15.0,
    "min_coverage_percentage": 60.0,
    "min_documentation_percentage": 80.0
  },
  "results": {
    "complexity": {
      "passed": false,
      "violations": [
        {
          "file": "src/payment.rs",
          "function": "process_payment",
          "complexity": 15,
          "threshold": 10,
          "line": 45
        },
        {
          "file": "src/auth.rs", 
          "function": "validate_user",
          "complexity": 12,
          "threshold": 10,
          "line": 23
        }
      ],
      "summary": {
        "max_complexity": 15,
        "avg_complexity": 7.2,
        "functions_over_threshold": 2,
        "total_functions": 24
      }
    },
    "satd": {
      "passed": false,
      "violations": [
        {
          "file": "src/payment.rs",
          "line": 67,
          "type": "TODO",
          "message": "Add retry logic for failed payments"
        },
        {
          "file": "src/auth.rs",
          "line": 156,
          "type": "FIXME", 
          "message": "Memory leak in token validation"
        }
      ],
      "summary": {
        "total_markers": 23,
        "todo_count": 12,
        "fixme_count": 8,
        "hack_count": 3,
        "xxx_count": 0
      }
    },
    "dead_code": {
      "passed": true,
      "summary": {
        "dead_functions": 0,
        "dead_code_percentage": 2.1,
        "total_lines": 4567,
        "dead_lines": 96
      }
    },
    "coverage": {
      "passed": true,
      "summary": {
        "line_coverage": 82.4,
        "branch_coverage": 76.8,
        "function_coverage": 89.2
      }
    }
  },
  "summary": {
    "total_checks": 6,
    "passed_checks": 4,
    "failed_checks": 2,
    "quality_score": 67,
    "grade": "C+",
    "recommendation": "Focus on reducing complexity and addressing technical debt"
  }
}
```

## Configurable Thresholds

### Complexity Thresholds

Control complexity tolerance levels:

```bash
# Strict complexity limits
pmat quality-gate . --max-complexity-p99=15

# Very strict for critical code
pmat quality-gate . --max-complexity-p99=8

# Relaxed for legacy code
pmat quality-gate . --max-complexity-p99=25
```

### Dead Code Thresholds

Set acceptable dead code levels:

```bash
# Strict dead code limits
pmat quality-gate . --max-dead-code=5.0

# Standard tolerance
pmat quality-gate . --max-dead-code=15.0

# Legacy codebase tolerance
pmat quality-gate . --max-dead-code=30.0
```

### Custom Threshold Combinations

```bash
# High-quality standards
pmat quality-gate . \
    --max-complexity-p99=10 \
    --max-dead-code=5.0 \
    --min-entropy=3.0

# Production readiness check
pmat quality-gate . \
    --max-complexity-p99=15 \
    --max-dead-code=10.0 \
    --min-entropy=2.5 \
    --fail-on-violation

# Legacy code maintenance
pmat quality-gate . \
    --max-complexity-p99=30 \
    --max-dead-code=25.0 \
    --min-entropy=1.5
```

## Single File Analysis

Analyze individual files for focused quality assessment:

```bash
# Analyze specific file
pmat quality-gate . --file=src/payment.rs

# Multiple files
pmat quality-gate . --file=src/payment.rs --format=json
pmat quality-gate . --file=src/auth.rs --format=json
```

**Single File Output:**
```json
{
  "status": "warning",
  "file": "src/payment.rs",
  "analysis_time_ms": 234,
  "checks_run": ["complexity", "satd", "dead_code", "lint", "documentation"],
  "results": {
    "complexity": {
      "passed": false,
      "functions": [
        {"name": "process_payment", "complexity": 15, "line": 45},
        {"name": "validate_card", "complexity": 6, "line": 123},
        {"name": "calculate_fee", "complexity": 4, "line": 234}
      ],
      "max_complexity": 15,
      "violations": 1
    },
    "satd": {
      "passed": false,
      "markers": [
        {"type": "TODO", "line": 67, "message": "Add retry logic"},
        {"type": "FIXME", "line": 89, "message": "Handle edge case"}
      ]
    }
  },
  "summary": {
    "passed_checks": 3,
    "failed_checks": 2,
    "quality_score": 60,
    "grade": "C"
  }
}
```

## CI/CD Integration

### Fail on Quality Gate Violations

Use quality gates as build gates in CI/CD pipelines:

```bash
# Fail build if quality gate fails
pmat quality-gate . --fail-on-violation

# Strict quality enforcement
pmat quality-gate . \
    --fail-on-violation \
    --max-complexity-p99=10 \
    --max-dead-code=5.0 \
    --checks=complexity,dead_code,satd
```

### Exit Codes

Quality gates return meaningful exit codes:

- **0**: All checks passed
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
          pmat quality-gate . \
            --format=json \
            --output=quality-report.json \
            --fail-on-violation \
            --max-complexity-p99=15 \
            --max-dead-code=10.0
            
      - name: Upload Quality Report
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: quality-report
          path: quality-report.json
          
      - name: Comment PR with Quality Results
        if: github.event_name == 'pull_request'
        run: |
          if [ -f quality-report.json ]; then
            echo "## Quality Gate Results" >> pr-comment.md
            echo "\`\`\`json" >> pr-comment.md
            cat quality-report.json >> pr-comment.md
            echo "\`\`\`" >> pr-comment.md
          fi
```

### GitLab CI Integration

```yaml
quality_gate:
  stage: test
  script:
    - pmat quality-gate . --format=json --output=quality-report.json --fail-on-violation
  artifacts:
    reports:
      junit: quality-report.json
    expire_in: 1 week
  allow_failure: false
```

## Advanced Features

### Performance Monitoring

Track analysis performance and resource usage:

```bash
pmat quality-gate . --performance --format=human
```

**Performance Output:**
```
⏱️  Performance Metrics:
   Initialization: 45ms
   File Discovery: 23ms (156 files)
   Complexity Analysis: 456ms
   SATD Detection: 234ms
   Dead Code Analysis: 345ms
   Report Generation: 67ms
   
   Total Runtime: 1,170ms
   Files Analyzed: 156
   Lines Processed: 12,450
   Average Speed: 10,641 lines/sec

📊 Resource Usage:
   Peak Memory: 34.7 MB
   CPU Utilization: 67%
   I/O Operations: 312 reads, 8 writes
   Cache Hit Rate: 89%
```

### Batch File Analysis

Process multiple files efficiently:

```bash
# Analyze all Rust files
find . -name "*.rs" -exec pmat quality-gate . --file={} \;

# Parallel analysis
find . -name "*.rs" | xargs -P 4 -I {} pmat quality-gate . --file={}
```

### Custom Check Selection

Run only specific quality checks:

```bash
# Code structure checks only
pmat quality-gate . --checks=complexity,dead_code

# Code quality checks only
pmat quality-gate . --checks=satd,lint,documentation

# All checks except performance-intensive ones
pmat quality-gate . --checks=complexity,satd,lint
```

## Quality Gate Profiles

### Predefined Profiles

Use predefined quality profiles for different scenarios:

```bash
# Development profile (relaxed)
pmat quality-gate . --profile=dev

# Staging profile (balanced)
pmat quality-gate . --profile=staging

# Production profile (strict)
pmat quality-gate . --profile=production

# Security-focused profile
pmat quality-gate . --profile=security
```

### Profile Configurations

**Development Profile:**
- Max Complexity: 20
- Max Dead Code: 25%
- SATD Tolerance: High
- Documentation: 60%

**Production Profile:**
- Max Complexity: 10
- Max Dead Code: 5%
- SATD Tolerance: Low
- Documentation: 90%

**Security Profile:**
- Max Complexity: 8
- Max Dead Code: 2%
- SATD Tolerance: None
- Documentation: 95%
- Additional security checks enabled

## Configuration Files

### Project Configuration

Create `.pmat/quality-gate.toml` for project-specific settings:

```toml
# Quality gate configuration

[thresholds]
max_complexity_p99 = 15
max_dead_code_percentage = 10.0
min_entropy = 2.5
min_coverage = 80.0
min_documentation = 85.0

[checks]
enabled = ["complexity", "satd", "dead_code", "coverage", "documentation", "lint"]
disabled = []

[complexity]
per_function_threshold = 10
aggregate_threshold = 15
exclude_patterns = ["**/test/**", "**/*_test.rs"]

[satd]
patterns = ["TODO", "FIXME", "HACK", "XXX", "BUG"]
severity_weights = { "TODO" = 1, "FIXME" = 3, "HACK" = 5, "XXX" = 8, "BUG" = 10 }
max_weighted_score = 50

[dead_code]
include_test_code = false
include_example_code = false
aggressive_detection = true

[output]
default_format = "human"
include_recommendations = true
include_performance_metrics = false
```

### Global Configuration

Set system-wide defaults in `~/.pmat/config.toml`:

```toml
[quality_gate]
default_profile = "production"
fail_on_violation = true
output_format = "human"
include_performance = true

[thresholds]
complexity_p99 = 12
dead_code_max = 8.0
entropy_min = 2.8
```

## Troubleshooting

### Common Issues

#### Analysis Takes Too Long
```bash
# Use performance mode to identify bottlenecks
pmat quality-gate . --performance

# Exclude large directories
pmat quality-gate . --exclude="target/,node_modules/,build/"

# Analyze smaller subset
pmat quality-gate src/ --checks=complexity,satd
```

#### High Memory Usage
```bash
# Process files in smaller batches
pmat quality-gate . --batch-size=50

# Reduce analysis depth
pmat quality-gate . --shallow-analysis

# Use streaming mode
pmat quality-gate . --stream
```

#### False Positives
```bash
# Adjust thresholds
pmat quality-gate . --max-complexity-p99=20

# Exclude problematic patterns
pmat quality-gate . --exclude="**/generated/**,**/vendor/**"

# Use file-specific analysis
pmat quality-gate . --file=specific/file.rs
```

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

if ! pmat quality-gate . --fail-on-violation --checks=complexity,satd,lint; then
    echo "❌ Quality gate failed. Commit rejected."
    echo "Fix quality issues before committing:"
    echo "  - Reduce function complexity"
    echo "  - Address technical debt markers"
    echo "  - Fix lint violations"
    exit 1
fi

echo "✅ Quality gate passed. Proceeding with commit."
```

### Makefile Integration

```makefile
.PHONY: quality-gate quality-report

quality-gate:
	@echo "Running quality gate..."
	@pmat quality-gate . --fail-on-violation

quality-report:
	@echo "Generating quality report..."
	@pmat quality-gate . --format=json --output=quality-report.json
	@pmat quality-gate . --format=human --output=quality-report.txt
	@echo "Reports generated: quality-report.json, quality-report.txt"

ci-quality: quality-gate
	@echo "CI quality checks passed"
```

## Summary

PMAT's quality gates provide comprehensive automated quality enforcement:

- **Multi-dimensional Analysis**: Complexity, technical debt, dead code, coverage
- **Configurable Thresholds**: Adapt to your project's quality standards  
- **Multiple Output Formats**: Human-readable and machine-readable results
- **CI/CD Integration**: Seamless integration with build pipelines
- **Performance Monitoring**: Track analysis performance and resource usage
- **Flexible Configuration**: Project and global configuration options

Use quality gates to:
1. **Enforce Standards**: Maintain consistent code quality
2. **Prevent Regression**: Catch quality degradation early
3. **Guide Development**: Provide actionable quality feedback
4. **Enable CI/CD**: Automate quality enforcement in pipelines
5. **Track Progress**: Monitor quality improvements over time

## Next Steps

- [Chapter 4: Technical Debt Grading](ch04-01-tdg.md) - Advanced quality metrics
- [Chapter 5: Analyze Suite](ch05-00-analyze-suite.md) - Detailed code analysis
- [Chapter 6: Scaffold Command](ch06-00-scaffold.md) - Generate quality-focused projects