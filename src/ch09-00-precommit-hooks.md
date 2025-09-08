# Chapter 9: Pre-commit Hooks Management

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (8/8 examples)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 8 | All hook configurations tested |
| ⚠️ Not Implemented | 0 | Planned for future versions |
| ❌ Broken | 0 | Known issues, needs fixing |
| 📋 Planned | 0 | Future roadmap features |

*Last updated: 2025-09-08*  
*PMAT version: pmat 2.64.0*  
*Test-Driven: All examples validated in `tests/ch09/test_precommit_hooks.sh`*
<!-- DOC_STATUS_END -->

## The Power of Automated Quality Gates

Pre-commit hooks are your first line of defense against technical debt. PMAT's latest feature provides comprehensive pre-commit hook management that ensures code quality before it enters your repository.

## Why PMAT Pre-commit Hooks?

Traditional pre-commit hooks run simple checks. PMAT hooks provide:
- **Deep Analysis**: Complexity, duplication, technical debt detection
- **Quality Gates**: Enforce minimum code quality standards
- **Smart Caching**: Only analyze changed files for speed
- **Team Consistency**: Same quality standards for everyone
- **Zero Configuration**: Works out of the box with sensible defaults

## Quick Start

Install PMAT pre-commit hooks in 30 seconds:

```bash
# Install PMAT
cargo install pmat

# Initialize hooks in your repository
pmat hooks init

# That's it! Hooks are now active
```

## Comprehensive Setup Guide

### Method 1: Automatic Installation (Recommended)

```bash
# Initialize PMAT hooks with interactive setup
pmat hooks init --interactive

# This will:
# 1. Detect your project type (Python, Rust, JavaScript, etc.)
# 2. Create appropriate hook configurations
# 3. Install git hooks
# 4. Configure quality thresholds
```

### Method 2: Manual Git Hooks

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# PMAT Pre-commit Hook

echo "🔍 Running PMAT quality checks..."

# Run quality gate with strict mode
pmat quality-gate --strict || {
    echo "❌ Quality gate failed!"
    echo "Run 'pmat analyze . --detailed' for more information"
    exit 1
}

# Check for complexity issues
pmat analyze complexity --project-path . --max-complexity 10 || {
    echo "❌ Complexity threshold exceeded!"
    exit 1
}

# Check for technical debt
SATD_COUNT=$(pmat analyze satd --path . --format json | jq '.total_violations')
if [ "$SATD_COUNT" -gt 5 ]; then
    echo "❌ Too many technical debt items: $SATD_COUNT"
    exit 1
fi

echo "✅ All quality checks passed!"
```

Make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

### Method 3: Python pre-commit Framework

For Python projects, integrate with the popular pre-commit framework:

```yaml
# .pre-commit-config.yaml
repos:
  # Standard hooks
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      
  # PMAT quality hooks
  - repo: local
    hooks:
      - id: pmat-quality-gate
        name: PMAT Quality Gate
        entry: pmat quality-gate --strict
        language: system
        pass_filenames: false
        always_run: true
        
      - id: pmat-complexity
        name: PMAT Complexity Analysis
        entry: pmat analyze complexity --project-path .
        language: system
        types: [python]
        files: \.py$
        
      - id: pmat-dead-code
        name: PMAT Dead Code Detection
        entry: pmat analyze dead-code --path .
        language: system
        pass_filenames: false
        
      - id: pmat-satd
        name: PMAT Technical Debt Check
        entry: pmat analyze satd --path . --max-items 5
        language: system
        pass_filenames: false
```

Install pre-commit:
```bash
pip install pre-commit
pre-commit install
```

## Configuration Options

### PMAT Hooks Configuration File

Create `.pmat-hooks.yaml` for advanced configuration:

```yaml
version: "1.0"
hooks:
  pre-commit:
    - name: quality-gate
      enabled: true
      config:
        min_grade: "B+"
        fail_on_decrease: true
        cache_results: true
        
    - name: complexity-check
      enabled: true
      config:
        max_complexity: 10
        max_cognitive_complexity: 15
        exclude_patterns:
          - "tests/**"
          - "migrations/**"
          - "*.generated.*"
          
    - name: duplication-check
      enabled: true
      config:
        max_duplication_ratio: 0.05
        min_lines_to_consider: 6
        
    - name: dead-code-check
      enabled: true
      config:
        fail_on_dead_code: false
        exclude_test_files: true
        
    - name: satd-check
      enabled: true
      config:
        max_satd_items: 10
        severity_threshold: "medium"
        forbidden_patterns:
          - "FIXME"
          - "HACK"
          - "KLUDGE"
          
  pre-push:
    - name: full-analysis
      enabled: true
      config:
        generate_report: true
        report_format: "markdown"
        upload_to_ci: true
        
    - name: test-coverage
      enabled: true
      config:
        min_coverage: 80
        check_branch_coverage: true
```

### Quality Gate Thresholds

Configure in `pmat.toml`:

```toml
[quality-gate]
min_grade = "B+"
fail_fast = true
parallel = true
cache_duration = 300  # seconds

[quality-gate.thresholds]
complexity = 10
cognitive_complexity = 15
duplication_ratio = 0.05
documentation_coverage = 0.80
test_coverage = 0.75
max_file_length = 500
max_function_length = 50

[quality-gate.weights]
complexity = 0.25
duplication = 0.20
documentation = 0.20
consistency = 0.15
maintainability = 0.20

[hooks]
enabled = true
fail_on_warning = false
show_diff = true
auto_fix = false  # Experimental

[hooks.performance]
timeout = 30  # seconds
max_files = 1000
incremental = true  # Only check changed files
```

## Real-World Examples

### Example 1: Enforcing Team Standards

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Team-specific quality standards
TEAM_MIN_GRADE="A-"
MAX_COMPLEXITY=8
MAX_FILE_SIZE=100000  # 100KB

echo "🏢 Enforcing team quality standards..."

# Check grade
GRADE=$(pmat quality-gate --format json | jq -r '.grade')
if [[ "$GRADE" < "$TEAM_MIN_GRADE" ]]; then
    echo "❌ Code quality ($GRADE) below team standard ($TEAM_MIN_GRADE)"
    exit 1
fi

# Check file sizes
for file in $(git diff --cached --name-only); do
    if [ -f "$file" ]; then
        SIZE=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
        if [ "$SIZE" -gt "$MAX_FILE_SIZE" ]; then
            echo "❌ File $file exceeds size limit: $SIZE bytes"
            exit 1
        fi
    fi
done

echo "✅ Team standards met!"
```

### Example 2: Progressive Quality Improvement

Track and enforce gradual quality improvements:

```python
#!/usr/bin/env python3
# .git/hooks/pre-commit

import json
import subprocess
import sys
from pathlib import Path

def get_current_grade():
    """Get current code quality grade from PMAT."""
    result = subprocess.run(
        ["pmat", "quality-gate", "--format", "json"],
        capture_output=True,
        text=True
    )
    if result.returncode == 0:
        data = json.loads(result.stdout)
        return data.get("grade", "F"), data.get("score", 0)
    return "F", 0

def get_baseline_grade():
    """Get baseline grade from last commit."""
    baseline_file = Path(".pmat-baseline.json")
    if baseline_file.exists():
        with open(baseline_file) as f:
            data = json.load(f)
            return data.get("grade", "F"), data.get("score", 0)
    return "F", 0

def save_baseline(grade, score):
    """Save current grade as baseline."""
    with open(".pmat-baseline.json", "w") as f:
        json.dump({"grade": grade, "score": score}, f)

# Check quality
current_grade, current_score = get_current_grade()
baseline_grade, baseline_score = get_baseline_grade()

print(f"📊 Current grade: {current_grade} ({current_score:.1f})")
print(f"📊 Baseline grade: {baseline_grade} ({baseline_score:.1f})")

# Enforce no regression
if current_score < baseline_score - 2:  # Allow 2-point variance
    print(f"❌ Quality decreased by {baseline_score - current_score:.1f} points")
    sys.exit(1)

# Update baseline if improved
if current_score > baseline_score:
    save_baseline(current_grade, current_score)
    print(f"⬆️ Quality improved! New baseline: {current_grade}")

print("✅ Quality check passed!")
```

### Example 3: Multi-Language Project

Handle different languages with specific rules:

```yaml
# .pmat-hooks.yaml
version: "1.0"
hooks:
  pre-commit:
    - name: python-quality
      enabled: true
      file_patterns: ["*.py"]
      config:
        linter: "ruff"
        formatter: "black"
        max_complexity: 10
        
    - name: rust-quality
      enabled: true
      file_patterns: ["*.rs"]
      config:
        linter: "clippy"
        formatter: "rustfmt"
        max_complexity: 15
        
    - name: javascript-quality
      enabled: true
      file_patterns: ["*.js", "*.jsx", "*.ts", "*.tsx"]
      config:
        linter: "eslint"
        formatter: "prettier"
        max_complexity: 8
        
    - name: universal-checks
      enabled: true
      config:
        check_todos: true
        check_secrets: true
        check_large_files: true
        max_file_size_mb: 10
```

## Integration with CI/CD

### GitHub Actions

```yaml
# .github/workflows/quality-gates.yml
name: PMAT Quality Gates

on:
  pull_request:
    types: [opened, synchronize, reopened]
  push:
    branches: [main, develop]

jobs:
  quality-check:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for comparison
          
      - name: Install PMAT
        run: |
          cargo install pmat
          pmat --version
          
      - name: Run pre-commit checks
        run: |
          # Simulate pre-commit environment
          pmat hooks run --all-files
          
      - name: Quality gate enforcement
        run: |
          pmat quality-gate --strict --min-grade B+
          
      - name: Generate quality report
        if: always()
        run: |
          pmat analyze . --format markdown > quality-report.md
          pmat analyze . --format json > quality-report.json
          
      - name: Comment PR with report
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const report = fs.readFileSync('quality-report.md', 'utf8');
            const data = JSON.parse(fs.readFileSync('quality-report.json', 'utf8'));
            
            const comment = `## 📊 PMAT Quality Report
            
            **Grade**: ${data.grade} (${data.score}/100)
            
            ${report}
            
            <details>
            <summary>Detailed Metrics</summary>
            
            \`\`\`json
            ${JSON.stringify(data.metrics, null, 2)}
            \`\`\`
            </details>`;
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: comment
            });
```

### GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - quality

pmat-quality:
  stage: quality
  image: rust:latest
  
  before_script:
    - cargo install pmat
    
  script:
    - pmat hooks run --all-files
    - pmat quality-gate --strict --min-grade B+
    
  artifacts:
    reports:
      junit: pmat-report.xml
    paths:
      - pmat-report.*
    when: always
    
  only:
    - merge_requests
    - main
```

## Troubleshooting

### Common Issues and Solutions

#### Hook Not Running

```bash
# Check if hook is executable
ls -la .git/hooks/pre-commit

# Fix permissions
chmod +x .git/hooks/pre-commit

# Test hook manually
.git/hooks/pre-commit
```

#### Hook Running Too Slowly

```toml
# pmat.toml - Performance optimizations
[hooks.performance]
incremental = true  # Only analyze changed files
parallel = true     # Use multiple cores
cache = true        # Cache analysis results
timeout = 15        # Fail fast after 15 seconds

[hooks.optimization]
skip_unchanged = true
skip_generated = true
skip_vendor = true
```

#### Bypassing Hooks (Emergency)

```bash
# Skip hooks for emergency fix
git commit --no-verify -m "Emergency fix: bypass hooks"

# But immediately follow up with:
pmat analyze . --detailed
pmat quality-gate --fix  # Auto-fix what's possible
```

## Best Practices

### 1. Start Gradual
Begin with warnings, then enforce:
```yaml
# Week 1-2: Warning only
hooks:
  pre-commit:
    enforce: false
    warn_only: true
    
# Week 3+: Enforce standards
hooks:
  pre-commit:
    enforce: true
    min_grade: "C+"
    
# Month 2+: Raise standards
hooks:
  pre-commit:
    enforce: true
    min_grade: "B+"
```

### 2. Team Onboarding

Create `scripts/setup-dev.sh`:
```bash
#!/bin/bash
echo "🚀 Setting up development environment..."

# Install PMAT
cargo install pmat

# Initialize hooks
pmat hooks init

# Run initial analysis
pmat analyze . --detailed

# Show team standards
cat .pmat-hooks.yaml

echo "✅ Development environment ready!"
echo "📚 See docs/quality-standards.md for team guidelines"
```

### 3. Continuous Improvement

Track metrics over time:
```python
# scripts/track-quality.py
import json
import subprocess
from datetime import datetime

result = subprocess.run(
    ["pmat", "analyze", ".", "--format", "json"],
    capture_output=True,
    text=True
)

data = json.loads(result.stdout)
data["timestamp"] = datetime.now().isoformat()

# Append to metrics file
with open(".metrics/quality-history.jsonl", "a") as f:
    f.write(json.dumps(data) + "\n")

print(f"📈 Quality tracked: Grade {data['grade']}")
```

## Advanced Features

### Custom Hook Plugins

Create custom PMAT plugins:

```rust
// pmat-plugin-security/src/lib.rs
use pmat_plugin_api::*;

#[derive(Default)]
pub struct SecurityPlugin;

impl Plugin for SecurityPlugin {
    fn name(&self) -> &str {
        "security-scanner"
    }
    
    fn run(&self, context: &Context) -> Result<Report> {
        // Check for hardcoded secrets
        let violations = scan_for_secrets(&context.files);
        
        Ok(Report {
            passed: violations.is_empty(),
            violations,
            suggestions: vec![
                "Use environment variables for secrets",
                "Enable git-secrets scanning",
            ],
        })
    }
}

// Register plugin
plugin_export!(SecurityPlugin);
```

### AI-Powered Suggestions

Enable AI suggestions in hooks:

```yaml
# .pmat-hooks.yaml
version: "1.0"
ai:
  enabled: true
  provider: "openai"  # or "anthropic", "local"
  
hooks:
  pre-commit:
    - name: ai-review
      enabled: true
      config:
        suggest_improvements: true
        auto_fix_simple_issues: false
        explain_violations: true
        learning_mode: true  # Learn from accepted/rejected suggestions
```

## Summary

PMAT's pre-commit hooks provide:
- **Automatic Quality Enforcement**: Never commit bad code again
- **Team Consistency**: Everyone follows the same standards
- **Progressive Improvement**: Gradually raise quality bar
- **Fast Feedback**: Know issues before commit
- **Flexible Configuration**: Adapt to any workflow

With PMAT hooks, technical debt is caught at the source, making your codebase healthier with every commit.

## Next Steps

- [Chapter 10: PMAT in CI/CD Pipelines](ch10-00-cicd-integration.md)
- [Chapter 11: Custom Quality Rules](ch11-00-custom-rules.md)
- [Appendix F: Hook Configuration Reference](appendix-f-hooks-reference.md)