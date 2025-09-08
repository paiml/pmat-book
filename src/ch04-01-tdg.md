# Chapter 4.1: Technical Debt Grading (TDG)

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (8/8 examples)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 8 | All TDG features tested |
| ⚠️ Not Implemented | 0 | Planned for future versions |
| ❌ Broken | 0 | Known issues, needs fixing |
| 📋 Planned | 0 | Future roadmap features |

*Last updated: 2025-09-08*  
*PMAT version: pmat 2.68.0*  
*Test-Driven: All examples validated in `tests/ch04/test_tdg.sh`*
<!-- DOC_STATUS_END -->

## Understanding Technical Debt Grading

Technical Debt Grading (TDG) is PMAT's flagship feature for comprehensive code quality assessment. Introduced in version 2.68.0, TDG provides a multi-dimensional analysis that goes beyond simple metrics to deliver actionable insights about code maintainability.

## What is TDG?

TDG is a composite score ranging from 0.0 to 5.0 that quantifies technical debt by analyzing five orthogonal components:

1. **Complexity Factor** (30% weight) - Cyclomatic and cognitive complexity
2. **Churn Factor** (35% weight) - Code change frequency and magnitude
3. **Coupling Factor** (15% weight) - Dependencies and architectural entanglement
4. **Duplication Factor** (10% weight) - Code clones and similarity
5. **Domain Risk Factor** (10% weight) - Business criticality and security considerations

These components combine to produce both a numerical score and a letter grade (A+ through F), making it easy to communicate code quality to both technical and non-technical stakeholders.

## TDG Scoring System

### Score Ranges and Severity

| TDG Score | Severity | Grade | Action Required |
|-----------|----------|-------|-----------------|
| 0.0 - 0.5 | Excellent | A+ | Maintain quality |
| 0.5 - 1.0 | Very Good | A | Minor improvements |
| 1.0 - 1.5 | Good | B+ | Monitor closely |
| 1.5 - 2.0 | Acceptable | B | Plan refactoring |
| 2.0 - 2.5 | Warning | C | Refactor soon |
| 2.5 - 3.0 | Critical | D | Immediate attention |
| 3.0 - 5.0 | Severe | F | Emergency refactoring |

### The Five Components Explained

#### 1. Complexity Factor (30%)
Measures both cyclomatic and cognitive complexity:
- **Cyclomatic Complexity**: Number of linearly independent paths
- **Cognitive Complexity**: Mental effort required to understand code
- **Nested Depth**: Levels of control flow nesting

#### 2. Churn Factor (35%)
Analyzes code volatility over time:
- **Change Frequency**: How often the code changes
- **Change Magnitude**: Size of changes
- **Author Count**: Number of different contributors
- **Hot Spot Detection**: Frequently modified complex code

#### 3. Coupling Factor (15%)
Evaluates dependencies and architectural health:
- **Afferent Coupling**: Incoming dependencies
- **Efferent Coupling**: Outgoing dependencies
- **Instability Index**: Ratio of efferent to total coupling
- **Circular Dependencies**: Cyclic relationships

#### 4. Duplication Factor (10%)
Identifies code clones and repetition:
- **Type 1**: Exact duplicates
- **Type 2**: Renamed/parameterized duplicates
- **Type 3**: Modified duplicates
- **Type 4**: Semantic duplicates

#### 5. Domain Risk Factor (10%)
Assesses business and security criticality:
- **Security Patterns**: Authentication, encryption, validation
- **Business Critical Paths**: Payment, user data, compliance
- **External Integrations**: Third-party API dependencies
- **Error Handling**: Exception management quality

## Basic TDG Analysis

### Command Line Usage

```bash
# Basic TDG analysis of current directory
pmat analyze tdg .

# Analyze specific path
pmat analyze tdg src/

# Show only critical files (TDG > 2.5)
pmat analyze tdg . --critical-only

# Custom threshold filtering
pmat analyze tdg . --threshold 2.0

# Include component breakdown
pmat analyze tdg . --include-components

# Limit to top 10 files
pmat analyze tdg . --top-files 10
```

### Example Output

```
📊 Technical Debt Grading Analysis
═══════════════════════════════════════════════════════════════════

Project: my-application
Files Analyzed: 247
Average TDG: 1.42 (Grade: B+)

Top Files by TDG Score:
┌──────────────────────────────────┬──────┬───────┬──────────────┐
│ File                             │ TDG  │ Grade │ Severity     │
├──────────────────────────────────┼──────┼───────┼──────────────┤
│ src/legacy/payment_processor.py │ 3.8  │ F     │ Critical     │
│ src/utils/data_transformer.py   │ 2.9  │ D     │ Critical     │
│ src/api/complex_handler.py      │ 2.4  │ C     │ Warning      │
│ src/models/user_validator.py    │ 1.8  │ B     │ Normal       │
│ src/services/email_service.py   │ 1.2  │ B+    │ Normal       │
└──────────────────────────────────┴──────┴───────┴──────────────┘

Distribution:
  A+ (0.0-0.5):  45 files (18.2%)  ████████
  A  (0.5-1.0):  82 files (33.2%)  ██████████████
  B+ (1.0-1.5):  67 files (27.1%)  ███████████
  B  (1.5-2.0):  35 files (14.2%)  ██████
  C  (2.0-2.5):  12 files (4.9%)   ██
  D  (2.5-3.0):  4 files (1.6%)    █
  F  (3.0+):     2 files (0.8%)    ▌
```

## Component Breakdown Analysis

Understanding individual components helps target specific improvements:

```bash
# Show detailed component breakdown
pmat analyze tdg . --include-components --format json
```

### Example Component Output

```json
{
  "file": "src/legacy/payment_processor.py",
  "tdg_score": 3.8,
  "grade": "F",
  "severity": "critical",
  "components": {
    "complexity": {
      "value": 2.4,
      "cyclomatic": 45,
      "cognitive": 62,
      "max_depth": 8,
      "contribution": "63.2%"
    },
    "churn": {
      "value": 0.8,
      "changes_last_30d": 15,
      "unique_authors": 6,
      "contribution": "21.1%"
    },
    "coupling": {
      "value": 0.3,
      "afferent": 12,
      "efferent": 28,
      "instability": 0.7,
      "contribution": "7.9%"
    },
    "duplication": {
      "value": 0.2,
      "clone_percentage": 18.5,
      "similar_blocks": 4,
      "contribution": "5.3%"
    },
    "domain_risk": {
      "value": 0.1,
      "risk_patterns": ["payment", "pii_data"],
      "contribution": "2.6%"
    }
  },
  "recommendations": [
    "Extract complex nested logic into separate functions",
    "Implement proper error handling patterns",
    "Reduce coupling by introducing interfaces",
    "Consolidate duplicate payment validation logic"
  ]
}
```

## Configuration

### Project Configuration

```toml
# pmat.toml
[tdg]
enabled = true
critical_threshold = 2.5
warning_threshold = 1.5

[tdg.weights]
complexity = 0.30
churn = 0.35
coupling = 0.15
duplication = 0.10
domain_risk = 0.10

[tdg.output]
include_components = true
show_percentiles = true
top_files = 10
grade_system = true

[tdg.analysis]
parallel = true
cache_enabled = true
incremental = true

[tdg.thresholds]
max_cyclomatic_complexity = 10
max_cognitive_complexity = 15
max_nesting_depth = 4
max_coupling = 20
duplication_threshold = 0.15
```

### Custom Domain Risk Patterns

```yaml
# .pmat/domain-risk.yaml
high_risk_patterns:
  - pattern: "payment|billing|charge"
    risk_score: 1.0
    category: "financial"
    
  - pattern: "password|auth|token|secret"
    risk_score: 0.9
    category: "security"
    
  - pattern: "user_data|personal_info|pii"
    risk_score: 0.8
    category: "privacy"
    
  - pattern: "export|report|analytics"
    risk_score: 0.5
    category: "business"

critical_paths:
  - "src/payments/**"
  - "src/auth/**"
  - "src/user/personal/**"
```

## Advanced Features

### Transactional Hashed TDG System

PMAT 2.68+ includes enterprise-grade features for large-scale analysis:

```bash
# Use persistent storage backend
pmat analyze tdg . --storage-backend sled

# Priority-based analysis
pmat analyze tdg src/critical --priority high

# Incremental analysis with caching
pmat analyze tdg . --incremental --cache-enabled
```

### MCP Integration

TDG is fully integrated with the Model Context Protocol:

```json
{
  "name": "tdg_analyze_with_storage",
  "arguments": {
    "paths": ["src/", "lib/"],
    "storage_backend": "rocksdb",
    "priority": "critical",
    "include_components": true
  }
}
```

### Performance Profiling

```bash
# Profile TDG analysis performance
pmat tdg performance-profile . --duration 30

# Generate flame graphs
pmat tdg flame-graph . --output tdg-flame.svg
```

## CI/CD Integration

### GitHub Actions

```yaml
name: TDG Analysis

on:
  pull_request:
  push:
    branches: [main]

jobs:
  tdg-analysis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install PMAT
        run: cargo install pmat
        
      - name: Run TDG Analysis
        run: |
          pmat analyze tdg . \
            --format json \
            --output tdg-report.json
            
      - name: Check TDG Thresholds
        run: |
          # Fail if any file has TDG > 3.0
          pmat analyze tdg . --threshold 3.0 || exit 1
          
      - name: Generate TDG Report
        run: |
          pmat analyze tdg . \
            --include-components \
            --format markdown > tdg-report.md
            
      - name: Comment PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const report = fs.readFileSync('tdg-report.md', 'utf8');
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## 📊 TDG Analysis Results\n\n${report}`
            });
```

### Quality Gates

```bash
# Enforce quality gates in CI/CD
pmat quality-gate \
  --tdg-threshold 2.0 \
  --min-grade B \
  --fail-on-regression
```

## Real-World Examples

### Example 1: Legacy Code Assessment

```bash
# Analyze legacy module
pmat analyze tdg src/legacy/ --include-components

# Output
File: src/legacy/order_processor.py
  TDG Score: 3.2 (Grade: F)
  Components:
    Complexity: 1.8 (56%) - Cyclomatic: 42, Cognitive: 58
    Churn: 0.9 (28%) - 23 changes in 30 days
    Coupling: 0.3 (9%) - 35 dependencies
    Duplication: 0.15 (5%) - 22% duplicate code
    Domain Risk: 0.05 (2%) - Contains payment logic
    
  Critical Issues:
    - Deeply nested conditional logic (max depth: 7)
    - Multiple responsibilities in single class
    - Hardcoded business rules
    
  Recommendations:
    1. Extract payment validation to separate service
    2. Implement strategy pattern for order types
    3. Add comprehensive error handling
    4. Increase test coverage (current: 12%)
```

### Example 2: Microservice Analysis

```bash
# Analyze microservices with custom config
cat > tdg-micro.toml << EOF
[tdg.weights]
complexity = 0.25
churn = 0.30
coupling = 0.25  # Higher weight for microservices
duplication = 0.10
domain_risk = 0.10
EOF

pmat analyze tdg services/ --config tdg-micro.toml
```

### Example 3: Hotspot Detection

```bash
# Find high-churn, high-complexity files
pmat analyze tdg . \
  --include-components \
  --format json | \
  jq '.files[] | 
    select(.components.churn.value > 0.5 and 
           .components.complexity.value > 1.5) | 
    {file: .path, tdg: .tdg_score, grade: .grade}'
```

## Interpreting TDG Results

### Action Priority Matrix

| TDG Score | Complexity | Churn | Action |
|-----------|------------|-------|--------|
| High (>2.5) | High | High | 🔴 Immediate refactoring |
| High (>2.5) | High | Low | 🟠 Plan refactoring |
| High (>2.5) | Low | High | 🟡 Add tests first |
| Low (<1.5) | Any | Any | 🟢 Monitor only |

### Improvement Strategies

#### For High Complexity:
- Extract methods to reduce cyclomatic complexity
- Simplify conditional logic
- Apply design patterns (Strategy, Chain of Responsibility)
- Reduce nesting depth

#### For High Churn:
- Stabilize requirements
- Improve test coverage
- Add documentation
- Consider architectural changes

#### For High Coupling:
- Introduce interfaces/protocols
- Apply Dependency Inversion Principle
- Use dependency injection
- Implement facade pattern

#### For High Duplication:
- Extract common functionality
- Create shared libraries
- Use template patterns
- Implement DRY principle

## Best Practices

### 1. Baseline Establishment

```bash
# Create baseline for tracking
pmat analyze tdg . --format json > tdg-baseline.json

# Compare against baseline
pmat analyze tdg . --compare-baseline tdg-baseline.json
```

### 2. Incremental Improvement

```bash
# Focus on worst files first
pmat analyze tdg . --top-files 5 --critical-only

# Track improvement over time
pmat analyze tdg . --trend --period 30d
```

### 3. Team Standards

```toml
# team-standards.toml
[tdg.quality_gates]
new_code_max_tdg = 1.5
legacy_code_max_tdg = 3.0
pr_regression_tolerance = 0.1

[tdg.requirements]
min_grade_for_production = "B"
min_grade_for_release = "B+"
```

## Troubleshooting

### Common Issues

#### High TDG Despite Simple Code
- Check for high churn (frequent changes)
- Review domain risk patterns
- Verify weight configuration

#### Inconsistent Scores
- Enable caching: `--cache-enabled`
- Use storage backend for persistence
- Check for concurrent modifications

#### Performance Issues
- Use incremental analysis: `--incremental`
- Enable parallel processing: `--parallel`
- Limit scope: `--top-files 20`

## Summary

Technical Debt Grading provides:
- **Comprehensive Assessment**: Five orthogonal metrics for complete picture
- **Actionable Insights**: Specific recommendations for improvement
- **Grade System**: Easy communication with stakeholders
- **Enterprise Features**: Scalable to large codebases
- **CI/CD Integration**: Automated quality gates
- **Trend Analysis**: Track improvement over time

TDG transforms code quality from abstract concept to measurable, manageable metric.

## Next Steps

- [Chapter 4.2: Code Similarity Detection](ch04-02-similarity.md)
- [Chapter 4.3: Multi-Language Support](ch04-03-languages.md)
- [Chapter 5: CLI Mastery](ch05-00-cli.md)