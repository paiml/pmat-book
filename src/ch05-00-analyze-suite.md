# Chapter 5: The Analyze Command Suite

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (8/8 examples)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 8 | All analyze commands tested |
| ⚠️ Not Implemented | 0 | Planned for future versions |
| ❌ Broken | 0 | Known issues, needs fixing |
| 📋 Planned | 0 | Future roadmap features |

*Last updated: 2025-09-09*  
*PMAT version: pmat 2.69.0*  
*Test-Driven: All examples validated in `tests/ch05/test_analyze.sh`*
<!-- DOC_STATUS_END -->

## Comprehensive Code Analysis

The `pmat analyze` command suite provides deep insights into your codebase through multiple specialized analyzers. Each analyzer focuses on a specific aspect of code quality, helping you maintain high standards and identify improvement opportunities.

## Basic Analysis

Start with a comprehensive analysis of your entire repository:

```bash
# Analyze current directory
pmat analyze .

# Analyze specific directory
pmat analyze src/

# Analyze with detailed output
pmat analyze . --detailed

# Save analysis to file
pmat analyze . --output analysis-report.txt
```

### Example Output

```
📊 Repository Analysis
======================

Files Analyzed: 156
Total Lines: 12,450
Languages: Python (75%), JavaScript (20%), YAML (5%)

## Metrics Summary
- Cyclomatic Complexity: 6.8 (average), 42 (max)
- Technical Debt Grade: B+ (1.8/5.0)
- Code Duplication: 8.5%
- Test Coverage: 82%
- Dead Code: 3 functions, 127 lines

## Quality Assessment
✅ Strengths:
- Good test coverage (>80%)
- Low average complexity
- Consistent code style

⚠️ Areas for Improvement:
- High complexity in payment_processor.py (42)
- Duplication in validation logic (8.5%)
- 3 unused functions detected

## Recommendations
1. Refactor payment_processor.py to reduce complexity
2. Extract common validation into shared utilities
3. Remove or document dead code
```

## Complexity Analysis

Measure and track code complexity to maintain readability:

```bash
# Basic complexity analysis
pmat analyze complexity

# Set complexity threshold
pmat analyze complexity --threshold 10

# Analyze specific files
pmat analyze complexity src/services/

# Output in different formats
pmat analyze complexity --format json
pmat analyze complexity --format csv
```

### Understanding Complexity Metrics

```bash
pmat analyze complexity --detailed
```

Output:
```
🔧 Complexity Analysis
=======================

## File-by-File Breakdown

src/services/payment.py:
  process_payment(): 42 (⚠️ Very High)
    - 15 decision points
    - 8 levels of nesting
    - 27 logical operators
  
  validate_card(): 8 (Moderate)
  refund_transaction(): 6 (Low)
  
src/models/user.py:
  authenticate(): 12 (High)
  update_profile(): 4 (Low)
  get_permissions(): 3 (Low)

## Summary Statistics
- Average Complexity: 6.8
- Median Complexity: 4
- Maximum: 42 (process_payment)
- Files Over Threshold (10): 5

## Complexity Distribution
Low (1-5):      ████████████ 65%
Moderate (6-10): ████ 20%
High (11-20):    ██ 10%
Very High (>20): █ 5%

## Risk Assessment
⚠️ 5 functions exceed recommended complexity (10)
🔴 1 function in critical range (>30)
```

### Cognitive Complexity

Beyond cyclomatic complexity, analyze cognitive load:

```bash
pmat analyze complexity --cognitive
```

## Dead Code Detection

Identify and remove unused code to reduce maintenance burden:

```bash
# Find all dead code
pmat analyze dead-code

# Check specific directories
pmat analyze dead-code src/legacy/

# Export dead code list
pmat analyze dead-code --export dead-code-list.txt

# Show safe-to-remove items only
pmat analyze dead-code --safe-only
```

### Dead Code Report

```
💀 Dead Code Detection
=======================

## Unused Functions (3)
1. src/utils/helpers.py:45 `old_formatter()` 
   - Last modified: 6 months ago
   - Safe to remove: ✅ Yes

2. src/legacy/converter.py:120 `legacy_transform()`
   - Last modified: 1 year ago
   - Safe to remove: ⚠️ Check for dynamic calls

3. src/services/email.py:89 `send_test_email()`
   - Last modified: 2 weeks ago
   - Safe to remove: ❌ No (might be test utility)

## Unused Variables (12)
- src/config.py: OLD_API_KEY, DEPRECATED_URL
- src/models/product.py: legacy_price, old_sku

## Unused Imports (8)
- datetime (src/utils/calc.py:3)
- json (src/services/api.py:5)

## Impact Analysis
- Total dead code: 412 lines
- Percentage of codebase: 3.3%
- Estimated cleanup time: 2-3 hours
```

## SATD Analysis

Self-Admitted Technical Debt (SATD) tracks developer-annotated issues:

```bash
# Find all SATD markers
pmat analyze satd

# Categorize by type
pmat analyze satd --categorize

# Filter by priority
pmat analyze satd --priority high

# Generate SATD report
pmat analyze satd --report
```

### SATD Categories and Patterns

```
🏗️ Self-Admitted Technical Debt Report
========================================

## Summary
Total SATD Items: 47
Affected Files: 23
Estimated Debt: 18-24 hours

## By Category
TODO (23):
  - Feature additions: 12
  - Refactoring needs: 8
  - Documentation: 3

FIXME (15):
  - Bug workarounds: 10
  - Performance issues: 5

HACK (6):
  - Temporary solutions: 4
  - Quick fixes: 2

XXX (3):
  - Major concerns: 3

## By Priority
🔴 High (Blocking): 5
  - src/auth/validator.py:45 "FIXME: Security vulnerability"
  - src/payment/processor.py:120 "XXX: Race condition"

🟡 Medium (Important): 18
  - src/api/routes.py:78 "TODO: Add rate limiting"
  - src/models/user.py:234 "HACK: Optimize this query"

🟢 Low (Nice to have): 24
  - src/utils/helpers.py:12 "TODO: Add type hints"

## Trends
- SATD increased by 15% in last month
- Most debt in: payment module (8 items)
- Oldest SATD: 8 months (src/legacy/adapter.py:45)
```

## Defects Analysis (Known Defects v2.1)

**NEW in PMAT v2.200.0**: Detect production-breaking defect patterns with zero-tolerance enforcement.

Identify critical defects that cause production failures:

```bash
# Scan all Rust files for critical defects
pmat analyze defects

# Scan specific directory
pmat analyze defects src/

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

Find duplicate and similar code blocks:

```bash
# Basic similarity detection
pmat analyze similarity

# Set similarity threshold (0.0-1.0)
pmat analyze similarity --threshold 0.8

# Detect specific clone types
pmat analyze similarity --types 1,2,3

# Ignore test files
pmat analyze similarity --exclude tests/
```

### Clone Types Explained

```
🔄 Code Duplication Analysis
==============================

## Type-1 Clones (Exact Duplicates)
Location A: src/validators/user.py:45-67
Location B: src/validators/admin.py:23-45
Similarity: 100%
Lines: 23
```python
def validate_email(email):
    if not email:
        raise ValueError("Email required")
    if "@" not in email:
        raise ValueError("Invalid email")
    # ... 18 more lines ...
```

## Type-2 Clones (Renamed Variables)
Location A: src/utils/calc.py:12-25
Location B: src/helpers/math.py:34-47
Similarity: 95%
Difference: Variable names (total→sum, items→elements)

## Type-3 Clones (Modified Statements)
Location A: src/services/notification.py:67-89
Location B: src/services/email.py:45-70
Similarity: 78%
Difference: Added error handling in B

## Type-4 Clones (Semantic)
Location A: Bubble sort in sort_utils.py
Location B: Selection sort in legacy_sort.py
Note: Different algorithms, same purpose

## Impact Analysis
- Total duplication: 12.5% (1,556 lines)
- Potential reduction: 8.2% (1,020 lines)
- Estimated refactoring: 6-8 hours
- Maintenance cost reduction: 35%
```

## Dependency Analysis

Understand coupling and dependencies:

```bash
# Analyze all dependencies
pmat analyze dependencies

# Show dependency tree
pmat analyze dependencies --tree

# Check for circular dependencies
pmat analyze dependencies --circular

# Export dependency graph
pmat analyze dependencies --graph --output deps.svg
```

### Dependency Report

```
📦 Dependency Analysis
========================

## Module Dependencies

src/services/
├── payment.py
│   ├── models.user (import User)
│   ├── models.transaction (import Transaction)
│   ├── utils.validator (import validate_card)
│   └── external: stripe, requests
│
├── notification.py
│   ├── models.user (import User)
│   ├── utils.email (import send_email)
│   └── external: sendgrid
│
└── auth.py
    ├── models.user (import User, Permission)
    ├── utils.crypto (import hash_password)
    └── external: jwt, bcrypt

## Metrics
- Afferent Coupling (Ca): 12
- Efferent Coupling (Ce): 18
- Instability (I): 0.6
- Abstractness (A): 0.3

## Circular Dependencies
⚠️ Found 2 circular dependencies:
1. models.user → services.auth → models.user
2. services.payment → utils.validator → services.payment

## External Dependencies
Production (15):
- fastapi==0.68.0
- sqlalchemy==1.4.23
- pydantic==1.8.2
- stripe==2.60.0
- ... 11 more

Development (8):
- pytest==6.2.4
- black==21.7b0
- mypy==0.910
- ... 5 more

## Vulnerability Check
🔴 2 dependencies with known vulnerabilities:
- requests==2.25.1 (CVE-2021-12345: High)
- pyyaml==5.3.1 (CVE-2020-14343: Medium)
```

## Architecture Analysis

Analyze architectural patterns and structure:

```bash
# Full architecture analysis
pmat analyze architecture

# Check specific patterns
pmat analyze architecture --patterns mvc,repository,service

# Validate against rules
pmat analyze architecture --rules architecture.yaml
```

## Security Analysis

Basic security scanning (detailed security requires specialized tools):

```bash
# Security scan
pmat analyze security

# Check for secrets
pmat analyze security --secrets

# Common vulnerabilities
pmat analyze security --vulnerabilities
```

## Combined Analysis

Run multiple analyzers together:

```bash
# Run all analyzers
pmat analyze all

# Run specific combination
pmat analyze complexity,dead-code,satd

# Custom analysis profile
pmat analyze --profile quality-check
```

## Output Formats

### JSON Format

```bash
pmat analyze . --format json > analysis.json
```

```json
{
  "timestamp": "2025-09-09T10:30:00Z",
  "repository": "/path/to/repo",
  "summary": {
    "files": 156,
    "lines": 12450,
    "languages": {
      "Python": 9337,
      "JavaScript": 2490,
      "YAML": 623
    }
  },
  "metrics": {
    "complexity": {
      "average": 6.8,
      "median": 4,
      "max": 42,
      "over_threshold": 5
    },
    "duplication": {
      "percentage": 12.5,
      "lines": 1556,
      "blocks": 23
    },
    "satd": {
      "total": 47,
      "by_type": {
        "TODO": 23,
        "FIXME": 15,
        "HACK": 6,
        "XXX": 3
      }
    },
    "dead_code": {
      "functions": 3,
      "lines": 127
    }
  },
  "grade": "B+",
  "recommendations": [
    "Refactor high complexity functions",
    "Remove code duplication",
    "Address high-priority SATD items"
  ]
}
```

### CSV Format

```bash
pmat analyze . --format csv > analysis.csv
```

### HTML Report

```bash
pmat analyze . --format html --output report.html
```

### Markdown Report

```bash
pmat analyze . --format markdown > ANALYSIS.md
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
          pmat analyze . --format json > analysis.json
          pmat analyze complexity --threshold 10
          pmat analyze dead-code
          pmat analyze satd --priority high
          
      - name: Check Quality Gates
        run: |
          complexity=$(jq '.metrics.complexity.max' analysis.json)
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
    
    # Check complexity
    pmat analyze complexity $staged --threshold 10
    if [ $? -ne 0 ]; then
        echo "❌ Complexity check failed"
        exit 1
    fi
    
    # Check for new SATD
    satd_before=$(pmat analyze satd --count)
    git stash -q --keep-index
    satd_after=$(pmat analyze satd --count)
    git stash pop -q
    
    if [ "$satd_after" -gt "$satd_before" ]; then
        echo "⚠️ Warning: New technical debt added"
    fi
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
# Use parallel processing
pmat analyze . --parallel

# Analyze incrementally
pmat analyze . --incremental

# Exclude large directories
pmat analyze . --exclude "node_modules/,venv/,build/"
```

### Missing Language Support

```bash
# Check supported languages
pmat analyze --languages

# Use generic analysis for unsupported languages
pmat analyze . --generic
```

### Memory Issues

```bash
# Limit memory usage
pmat analyze . --max-memory 2G

# Process in chunks
pmat analyze . --chunk-size 100
```

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