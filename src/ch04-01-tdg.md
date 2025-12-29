# Chapter 4.1: Technical Debt Grading (TDG)

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (9/9 examples)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 9 | All TDG features tested including git-commit correlation |
| ⚠️ Not Implemented | 0 | Planned for future versions |
| ❌ Broken | 0 | Known issues, needs fixing |
| 📋 Planned | 0 | Future roadmap features |

*Last updated: 2025-10-28*
*PMAT version: pmat 2.213.1*
*Test-Driven: All examples validated in `tests/ch04/test_tdg.sh`*
*New in v2.179.0: Git-commit correlation for quality archaeology*
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

### Known Defects v2.1: Critical Defects Auto-Fail

Starting in PMAT v2.200.0, TDG implements **Critical Defects Auto-Fail** - a zero-tolerance policy for production-breaking defect patterns.

**Auto-Fail Behavior:**
- If a file contains **critical defects**, TDG automatically assigns:
  - **Score**: 0.0/100
  - **Grade**: F
  - **Exit Code**: 1 (for CI/CD integration)

**Critical Defect Patterns:**

1. **`.unwrap()` Calls** (Severity: Critical)
   - **Why Critical**: Causes immediate panic in production
   - **Evidence**: Cloudflare outage 2025-11-18 (3+ hours of global network disruption)
   - **Fix**: Use `.expect()` with descriptive messages or proper error handling with `?`

   ```rust
   // ❌ CRITICAL DEFECT - Auto-fails TDG
   let result = some_operation().unwrap();

   // ✅ CORRECT - Descriptive error handling
   let result = some_operation()
       .expect("Bot feature file must be valid");

   // ✅ CORRECT - Propagate errors
   let result = some_operation()?;
   ```

**Example TDG Output with Critical Defects:**

```
🔴 CRITICAL DEFECTS DETECTED
===========================

Critical Defects: 2
Status: AUTO-FAIL (Score: 0.0, Grade: F)

Run 'pmat analyze defects' for detailed defect report.
```

**Test Code Exclusion:**
- Defects in test code (`tests/`, `benches/`, `#[cfg(test)]`) are **not flagged**
- Production code standards apply only to production code

**See Also:**
- `pmat analyze defects` - Detailed defect report with multiple output formats
- Chapter 5: Analyze Suite - Full documentation of defect detection
- rust-project-score - Known Defects category scoring

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

# ML-based scoring (GH-97) - Uses aprender LinearRegression
pmat analyze tdg . --ml
pmat tdg . --ml  # Short form

# Combined ML mode with other options
pmat analyze tdg . --ml --include-components --format json
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

## Git-Commit Correlation (v2.179.0+)

Track TDG scores at specific git commits for "quality archaeology" workflows. Discover which commits affected code quality and track quality trends over time.

### Basic Usage

#### Analyze with Git Context

```bash
# Analyze file and store git metadata
pmat tdg src/lib.rs --with-git-context

# Analysis output shows TDG score
# Git context stored in ~/.pmat/ for history queries
```

#### Query TDG History

```bash
# Query specific commit (by SHA or tag)
pmat tdg history --commit abc123
pmat tdg history --commit v2.178.0

# History since reference
pmat tdg history --since HEAD~10
pmat tdg history --since v2.177.0

# Commit range
pmat tdg history --range HEAD~10..HEAD
pmat tdg history --range v2.177.0..v2.178.0

# Filter by file path
pmat tdg history --path src/lib.rs --since HEAD~5
```

### Output Formats

#### Table Format (Default)

```bash
pmat tdg history --commit HEAD
```

Output:
```
╭──────────────────────────────────────────────────────────────────────────╮
│  TDG History                                                             │
├──────────────────────────────────────────────────────────────────────────┤
│  📝 f0fb3af - A+ (95.5)                                                  │
│  ├─ Branch:  main                                                        │
│  ├─ Author:  Alice Developer                                             │
│  ├─ Date:    2025-10-28 18:43                                            │
│  └─ File:    src/lib.rs                                                  │
│                                                                          │
╰──────────────────────────────────────────────────────────────────────────╯
```

#### JSON Format (For Automation)

```bash
pmat tdg history --commit HEAD --format json | jq .
```

Output:
```json
{
  "history": [
    {
      "file_path": "src/lib.rs",
      "score": {
        "total": 95.5,
        "grade": "A+",
        "structural_complexity": 12.5,
        "semantic_complexity": 8.3,
        "duplication_ratio": 0.02,
        "coupling_score": 15.0,
        "doc_coverage": 92.0,
        "consistency_score": 98.0,
        "entropy_score": 7.2
      },
      "git_context": {
        "commit_sha": "f0fb3af0469e620368b53cc1c560cc4b46bd4075",
        "commit_sha_short": "f0fb3af",
        "branch": "main",
        "author_name": "Alice Developer",
        "author_email": "alice@example.com",
        "commit_timestamp": "2025-10-28T18:43:27Z",
        "commit_message": "Refactor authentication module",
        "tags": ["v2.1.0"]
      }
    }
  ]
}
```

### Quality Archaeology Workflows

#### Find Quality Regressions

```bash
# Find commits where quality dropped below B+
pmat tdg history --since HEAD~50 --format json | \
  jq '.history[] | select(.score.grade | test("C|D|F"))'
```

#### Compare Quality Between Releases

```bash
# Quality delta between releases
pmat tdg history --range v2.177.0..v2.178.0

# Focus on specific file
pmat tdg history --path src/auth.rs --range v1.0.0..v2.0.0
```

#### Track Per-File Quality Trends

```bash
# See how a file's quality evolved
pmat tdg history --path src/database.rs --since HEAD~20

# Export for visualization
pmat tdg history --path src/api.rs --since HEAD~50 --format json > quality-trend.json
```

#### CI/CD Quality Gates

```bash
#!/bin/bash
# quality-gate.sh - Block commits that degrade quality

# Analyze current commit
pmat tdg src/ --with-git-context

# Get previous commit's quality
PREV_GRADE=$(pmat tdg history --commit HEAD~1 --format json | jq -r '.history[0].score.grade')

# Get current quality
CURR_GRADE=$(pmat tdg history --commit HEAD --format json | jq -r '.history[0].score.grade')

if [[ "$CURR_GRADE" < "$PREV_GRADE" ]]; then
  echo "❌ Quality regression detected: $PREV_GRADE → $CURR_GRADE"
  exit 1
fi

echo "✅ Quality maintained or improved"
```

### Use Cases

#### 1. Quality Attribution
Track which developer commits affected code quality:

```bash
# Find author of quality regression
pmat tdg history --since HEAD~20 --format json | \
  jq '.history[] | select(.score.total < 80) | .git_context.author_name'
```

#### 2. Release Quality Reports
Generate quality reports for releases:

```bash
# Quality summary between releases
pmat tdg history --range v2.0.0..v2.1.0 --format json | \
  jq '{
    files: .history | length,
    avg_score: (.history | map(.score.total) | add / length),
    grades: (.history | group_by(.score.grade) |
      map({grade: .[0].score.grade, count: length}))
  }'
```

#### 3. Hotspot Analysis
Identify files with frequent quality issues:

```bash
# Files with most quality fluctuation
pmat tdg history --since HEAD~100 --format json | \
  jq -r '.history[] | .file_path' | sort | uniq -c | sort -rn | head -10
```

### Best Practices

**1. Regular Analysis**
```bash
# Analyze on every commit (git hook)
cat > .git/hooks/post-commit << 'EOF'
#!/bin/bash
pmat tdg . --with-git-context
EOF
chmod +x .git/hooks/post-commit
```

**2. Baseline Establishment**
```bash
# Create baseline at release
git tag v1.0.0
pmat tdg . --with-git-context

# Compare future changes
pmat tdg history --range v1.0.0..HEAD
```

**3. Storage Location**
- Git context stored in `~/.pmat/tdg-warm/` (recent)
- Archived to `~/.pmat/tdg-cold/` after 30 days
- Use `--storage-path` to customize location

### Limitations

- Git context only stored when using `--with-git-context` flag
- History queries only show files analyzed with git context
- Storage grows with analysis frequency (~100 bytes per file per commit)
- Requires git repository (returns None for non-git directories)

### MCP Integration

Git-commit correlation works seamlessly with MCP:

```json
{
  "tool": "analyze.tdg",
  "arguments": {
    "paths": ["src/lib.rs"],
    "with_git_context": true
  }
}
```

Query history via MCP:
```json
{
  "tool": "tdg.history",
  "arguments": {
    "commit": "HEAD",
    "format": "json"
  }
}
```

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