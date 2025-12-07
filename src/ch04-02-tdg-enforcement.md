# Chapter 4.2: TDG Enforcement System

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (v2.180.1)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | All features | Baseline, hooks, regression checks, CI/CD integration |
| ⚠️ Not Implemented | 0 | N/A |
| ❌ Broken | 0 | All systems operational |
| 📋 Planned | Module-specific thresholds | Future enhancement |

*Last updated: 2025-10-29*
*PMAT version: pmat 2.180.1*
*Test-Driven: Validated through Sprint 67 dogfooding on PMAT codebase*
*New in v2.180.0: Zero-regression quality enforcement system*
<!-- DOC_STATUS_END -->

## Introduction

The **TDG Enforcement System** provides automated zero-regression quality guarantees for your codebase. Introduced in v2.180.0 and validated through Sprint 67 dogfooding, this system ensures that code quality never degrades through baseline tracking, quality gates, git hooks, and CI/CD integration.

**Key Capabilities**:
- **Baseline Tracking**: Snapshot your codebase quality at any point in time
- **Regression Detection**: Automatically detect quality degradations
- **Quality Gates**: Enforce minimum quality standards for new code
- **Git Hooks**: Pre-commit and post-commit quality checks
- **CI/CD Integration**: Automated enforcement in GitHub Actions, GitLab CI, Jenkins
- **Zero-Regression Enforcement**: Block commits/PRs that degrade quality

**Sprint 67 Results** (PMAT Dogfooding):
- **851 files analyzed** across PMAT codebase
- **93.0 average score** (A grade)
- **83.9% of files** score A- or higher
- **< 10 minutes** to create baseline
- **< 5 seconds** per pre-commit check

---

## Core Concepts

### 1. Quality Baselines

A **baseline** is a snapshot of your codebase's quality at a specific point in time. Baselines use **Blake3 content-hash deduplication** for efficient storage and fast comparisons.

**Baseline Structure**:
```json
{
  "metadata": {
    "created_at": "2025-10-29T12:00:00Z",
    "pmat_version": "2.180.1",
    "total_files": 851,
    "avg_score": 93.0
  },
  "summary": {
    "grade_distribution": {
      "APLus": 409,
      "A": 305,
      "AMinus": 37,
      "BPlus": 41,
      "B": 38,
      "BMinus": 16,
      "CPlus": 4,
      "C": 1
    },
    "languages": {
      "Rust": 848,
      "JavaScript": 1,
      "TypeScript": 1,
      "Python": 1
    }
  },
  "files": [
    {
      "path": "server/src/lib.rs",
      "content_hash": "blake3:a1b2c3d4...",
      "score": 95.5,
      "grade": "A+",
      "language": "Rust"
    }
    // ... 850 more files
  ]
}
```

### 2. Quality Gates

**Quality Gates** enforce minimum standards:

1. **RegressionGate**: Prevents quality score drops
   - Configurable threshold (e.g., max 5-point drop)
   - Detects degradation via baseline comparison

2. **MinimumGradeGate**: Enforces minimum quality for new code
   - Language-specific thresholds (e.g., Rust: B+, Python: A)
   - Blocks commits below threshold

3. **NewFileGate**: Special handling for new files
   - Stricter standards for greenfield code
   - Encourages quality from day one

### 3. Enforcement Modes

**Strict Mode** (Production):
- Blocks commits/PRs that violate gates
- Exit code 1 on violation
- Used in CI/CD and git hooks

**Warning Mode** (Learning):
- Shows violations but allows commits
- Exit code 0 (success)
- Used during team adjustment period

**Disabled Mode**:
- No enforcement
- Analysis only

---

## Quick Start

### Step 1: Create Initial Baseline

```bash
cd /path/to/your/project
pmat tdg baseline create --output .pmat/tdg-baseline.json --path src/
```

**Expected Output**:
```
✅ Baseline created successfully!
   Files analyzed: 247
   Average score: 91.5
   Grade distribution:
     A+ : 45 files (18.2%)
     A  : 82 files (33.2%)
     B+ : 67 files (27.1%)
     B  : 35 files (14.2%)
     C  : 12 files (4.9%)
     D  :  4 files (1.6%)
     F  :  2 files (0.8%)

   Baseline saved to: .pmat/tdg-baseline.json
```

**Performance**:
- **Small projects** (< 100 files): < 1 minute
- **Medium projects** (100-500 files): 1-5 minutes
- **Large projects** (500-2000 files): 5-15 minutes
- **PMAT-scale** (851 files): ~10 minutes

### Step 2: Install Git Hooks

```bash
pmat hooks install --tdg-enforcement
```

**What this installs**:
- `.git/hooks/pre-commit` - Quality checks before commit
- `.git/hooks/post-commit` - Baseline auto-update (optional)
- `.pmat/tdg-rules.toml` - Configuration file

**Pre-commit Hook Behavior**:
1. Runs regression check (current vs baseline)
2. Runs quality check on staged files
3. Blocks commit if violations found (strict mode)
4. Shows warnings but allows commit (warning mode)

### Step 3: Configure Quality Thresholds

Edit `.pmat/tdg-rules.toml`:

```toml
[quality_gates]
# Minimum grade for new code (A+, A, A-, B+, B, B-, C+, C, D, F)
rust_min_grade = "B+"
python_min_grade = "A"
javascript_min_grade = "B+"
typescript_min_grade = "A-"

# Maximum allowed score drop (0.0 = no regressions allowed)
max_score_drop = 5.0

# Enforcement mode: "strict", "warning", "disabled"
mode = "warning"  # Start in warning mode

[baseline]
# Path to baseline file
baseline_path = ".pmat/tdg-baseline.json"

# Auto-update baseline on main branch commits
auto_update_on_main = true

# Retention policy
retention_days = 90
```

**Recommended Thresholds**:
- **Strict Projects**: `min_grade = "A"`, `max_score_drop = 3.0`
- **Balanced Projects**: `min_grade = "B+"`, `max_score_drop = 5.0`
- **Legacy Projects**: `min_grade = "B"`, `max_score_drop = 7.0`

### Step 4: Test the System

```bash
# Check for regressions against baseline
pmat tdg check-regression --baseline .pmat/tdg-baseline.json --path .

# Expected output (no regressions):
✅ No quality regressions detected
   Files analyzed: 247
   Unchanged: 247
   Improved: 0
   Regressed: 0

# Analyze specific files
pmat tdg src/new_feature.rs --baseline .pmat/tdg-baseline.json

# Expected output (new file):
📊 TDG Analysis
   File: src/new_feature.rs
   Score: 92.0
   Grade: A
   Status: NEW FILE ✨

   Quality Gate: ✅ PASS (exceeds B+ minimum)
```

---

## Git Hook Integration

### Pre-commit Hook

The pre-commit hook runs two checks:

**1. Regression Check**:
```bash
# Compares current state vs baseline
pmat tdg check-regression --baseline .pmat/tdg-baseline.json --path .
```

**2. Quality Check**:
```bash
# Checks staged files meet minimum grade
pmat tdg check-quality --files $(git diff --cached --name-only)
```

**Example Output** (Warning Mode):
```
⚠️  Quality Gate Warnings:

   File: src/utils/helper.rs
   Current Grade: B (Score: 82.0)
   Required Grade: B+ (Score: 85.0+)
   Gap: -3.0 points

   File: src/api/handler.rs
   Regression Detected: -6.2 points
   Previous: A (92.5) → Current: B+ (86.3)
   Max Allowed Drop: 5.0 points

   Mode: WARNING (commit allowed)
   To enforce: Set mode = "strict" in .pmat/tdg-rules.toml
```

**Example Output** (Strict Mode):
```
❌ Quality Gate Failed!

   src/utils/helper.rs: B (82.0) < B+ (85.0) required
   src/api/handler.rs: Regression -6.2 > -5.0 threshold

   Commit blocked. Fix quality issues or use:
   git commit --no-verify (NOT RECOMMENDED)
```

### Post-commit Hook

The post-commit hook optionally updates the baseline:

```bash
# Update baseline after successful commit (main branch only)
if [[ $(git branch --show-current) == "main" ]]; then
  pmat tdg baseline update --baseline .pmat/tdg-baseline.json --path .
fi
```

**Behavior**:
- Only runs on main/master branch (configurable)
- Incremental update (only changed files re-analyzed)
- Keeps baseline synchronized with codebase

### Hook Bypass (Emergency Only)

```bash
# Bypass pre-commit hook (NOT RECOMMENDED)
git commit --no-verify -m "Emergency hotfix"

# Then fix quality issues immediately:
pmat tdg src/emergency_fix.rs
# Refactor to meet standards
git add src/emergency_fix.rs
git commit -m "refactor: Fix quality issues in emergency hotfix"
```

---

## CI/CD Integration

### GitHub Actions

Create `.github/workflows/tdg-quality.yml`:

```yaml
name: TDG Quality Enforcement

on:
  pull_request:
    branches: [main, master]
  push:
    branches: [main, master]

jobs:
  tdg-enforcement:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for baseline comparison

      - name: Install PMAT
        run: |
          cargo install pmat --version 2.180.1
          pmat --version

      - name: Load baseline
        run: |
          # Baseline should be committed to repo
          if [[ ! -f .pmat/tdg-baseline.json ]]; then
            echo "❌ No baseline found. Run: pmat tdg baseline create"
            exit 1
          fi

      - name: Check for regressions
        run: |
          pmat tdg check-regression \
            --baseline .pmat/tdg-baseline.json \
            --path . \
            --fail-on-regression

      - name: Check new file quality
        run: |
          # Get changed files
          CHANGED_FILES=$(git diff --name-only origin/main...HEAD)

          if [[ -n "$CHANGED_FILES" ]]; then
            pmat tdg check-quality \
              --files $CHANGED_FILES \
              --min-grade B+ \
              --fail-on-violation
          fi

      - name: Generate quality report
        if: github.event_name == 'pull_request'
        run: |
          pmat tdg . \
            --include-components \
            --format markdown > tdg-report.md

      - name: Comment PR with results
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
              body: `## 📊 TDG Quality Report\n\n${report}`
            });

      - name: Update baseline (main branch only)
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        run: |
          pmat tdg baseline update \
            --baseline .pmat/tdg-baseline.json \
            --path .

          # Commit updated baseline
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add .pmat/tdg-baseline.json
          git commit -m "chore: Update TDG baseline [skip ci]" || true
          git push
```

**Example PR Comment**:
```markdown
## 📊 TDG Quality Report

✅ No regressions detected
✅ All new files meet B+ minimum

### Files Analyzed: 5

| File | Score | Grade | Status |
|------|-------|-------|--------|
| src/parser/new_feature.rs | 94.0 | A | NEW ✨ |
| src/lib.rs | 95.5 | A+ | UNCHANGED |
| src/utils/helper.rs | 87.0 | B+ | IMPROVED (+2.5) |
| tests/integration_test.rs | 98.0 | A+ | NEW ✨ |
| README.md | - | - | SKIPPED (doc) |

### Summary
- **Average Score**: 93.6 (A grade)
- **Grade Distribution**: 3× A+, 1× A, 1× B+
- **Quality Gate**: ✅ PASS
```

### GitLab CI

Create `.gitlab-ci.yml`:

```yaml
stages:
  - quality

tdg-enforcement:
  stage: quality
  image: rust:latest

  before_script:
    - cargo install pmat --version 2.180.1

  script:
    # Regression check
    - pmat tdg check-regression --baseline .pmat/tdg-baseline.json --path . --fail-on-regression

    # Quality check on changed files
    - |
      CHANGED_FILES=$(git diff --name-only $CI_MERGE_REQUEST_DIFF_BASE_SHA...HEAD)
      if [[ -n "$CHANGED_FILES" ]]; then
        pmat tdg check-quality --files $CHANGED_FILES --min-grade B+ --fail-on-violation
      fi

  artifacts:
    reports:
      junit: tdg-report.xml

  only:
    - merge_requests
    - main
```

### Jenkins Pipeline

Create `Jenkinsfile`:

```groovy
pipeline {
  agent any

  stages {
    stage('TDG Enforcement') {
      steps {
        sh 'cargo install pmat --version 2.180.1'

        sh '''
          pmat tdg check-regression \
            --baseline .pmat/tdg-baseline.json \
            --path . \
            --fail-on-regression
        '''

        script {
          def changedFiles = sh(
            script: 'git diff --name-only origin/main...HEAD',
            returnStdout: true
          ).trim()

          if (changedFiles) {
            sh """
              pmat tdg check-quality \
                --files ${changedFiles} \
                --min-grade B+ \
                --fail-on-violation
            """
          }
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'tdg-report.json', allowEmptyArchive: true
    }
  }
}
```

---

## Baseline Management

### Creating Baselines

```bash
# Create initial baseline
pmat tdg baseline create --output .pmat/tdg-baseline.json --path src/

# Create baseline for specific languages
pmat tdg baseline create --output .pmat/tdg-baseline.json --path src/ --languages rust,python

# Create baseline with custom config
pmat tdg baseline create \
  --output .pmat/tdg-baseline.json \
  --path src/ \
  --config .pmat/tdg-rules.toml

# Create baseline and commit to git
pmat tdg baseline create --output .pmat/tdg-baseline.json --path src/
git add .pmat/tdg-baseline.json
git commit -m "chore: Create TDG quality baseline"
git push
```

### Updating Baselines

```bash
# Incremental update (only changed files)
pmat tdg baseline update --baseline .pmat/tdg-baseline.json --path .

# Full re-analysis (all files)
pmat tdg baseline update --baseline .pmat/tdg-baseline.json --path . --full

# Update specific files
pmat tdg baseline update \
  --baseline .pmat/tdg-baseline.json \
  --files src/lib.rs src/parser.rs
```

### Comparing Baselines

```bash
# Compare current state vs baseline
pmat tdg baseline compare \
  --baseline .pmat/tdg-baseline.json \
  --path . \
  --format table

# Output:
╭──────────────────────────────────────────────────────────────╮
│  Baseline Comparison                                         │
├──────────────────────────────────────────────────────────────┤
│  Files analyzed: 247                                         │
│  Unchanged: 240 (97.2%)                                      │
│  Improved: 5 (2.0%)                                          │
│  Regressed: 2 (0.8%)                                         │
│                                                              │
│  Regressed Files:                                            │
│    src/api/handler.rs: A (92.5) → B+ (86.3) [-6.2]          │
│    src/utils/helper.rs: B+ (85.5) → B (82.0) [-3.5]         │
│                                                              │
│  Improved Files:                                             │
│    src/parser/lexer.rs: B (80.0) → B+ (88.0) [+8.0]         │
│    src/ast/visitor.rs: B+ (87.0) → A (91.5) [+4.5]          │
│    src/lib.rs: A (93.0) → A+ (96.0) [+3.0]                  │
╰──────────────────────────────────────────────────────────────╯

# Compare two baselines
pmat tdg baseline compare \
  --baseline1 .pmat/tdg-baseline-v1.json \
  --baseline2 .pmat/tdg-baseline-v2.json

# JSON output for automation
pmat tdg baseline compare \
  --baseline .pmat/tdg-baseline.json \
  --path . \
  --format json > comparison.json
```

### Baseline Archaeology

```bash
# Track quality over time via git history
git log --all --oneline --format="%H %s" -- .pmat/tdg-baseline.json

# Checkout baseline from specific release
git show v2.0.0:.pmat/tdg-baseline.json > baseline-v2.0.0.json

# Compare releases
pmat tdg baseline compare \
  --baseline1 baseline-v1.0.0.json \
  --baseline2 baseline-v2.0.0.json
```

---

## Regression Detection

### Automatic Regression Detection

```bash
# Check for any regressions
pmat tdg check-regression --baseline .pmat/tdg-baseline.json --path .

# Strict mode (fail on any regression)
pmat tdg check-regression \
  --baseline .pmat/tdg-baseline.json \
  --path . \
  --fail-on-regression

# Custom threshold
pmat tdg check-regression \
  --baseline .pmat/tdg-baseline.json \
  --path . \
  --max-drop 3.0  # Fail if > 3 point drop
```

### Regression Analysis

```bash
# Detailed regression report
pmat tdg check-regression \
  --baseline .pmat/tdg-baseline.json \
  --path . \
  --verbose \
  --format json

# Output:
{
  "summary": {
    "total_files": 247,
    "unchanged": 240,
    "improved": 5,
    "regressed": 2,
    "regression_rate": 0.8
  },
  "regressions": [
    {
      "file": "src/api/handler.rs",
      "baseline_score": 92.5,
      "current_score": 86.3,
      "delta": -6.2,
      "baseline_grade": "A",
      "current_grade": "B+",
      "severity": "critical"
    }
  ],
  "improvements": [
    {
      "file": "src/parser/lexer.rs",
      "baseline_score": 80.0,
      "current_score": 88.0,
      "delta": 8.0,
      "baseline_grade": "B",
      "current_grade": "B+"
    }
  ]
}
```

### Regression Root Cause Analysis

```bash
# Analyze why a file regressed
pmat tdg src/api/handler.rs --include-components --verbose

# Output shows component breakdown:
File: src/api/handler.rs
  TDG Score: 86.3 (B+) [was 92.5 A]

  Component Breakdown:
    Complexity: 25.0 [was 18.5] ⚠️ +6.5 points
      - Cyclomatic: 42 [was 28] ⚠️
      - Cognitive: 58 [was 35] ⚠️
      - Nesting: 6 [was 4] ⚠️

    Churn: 12.0 [was 15.0] ✅ -3.0 points
      - Changes (30d): 8 [was 12] ✅

    Coupling: 8.0 [was 8.0] → No change
    Duplication: 5.3 [was 5.0] → Minimal change
    Domain Risk: 2.0 [was 2.0] → No change

  Root Cause: Increased complexity (+6.5 points)

  Recommendations:
    1. Refactor nested conditional logic (reduce nesting 6 → 4)
    2. Extract complex validation to separate functions
    3. Simplify error handling paths
```

---

## Quality Gate Configuration

### Language-Specific Thresholds

```toml
# .pmat/tdg-rules.toml
[quality_gates]
# Different standards for different languages
rust_min_grade = "A"      # Rust is strict
python_min_grade = "B+"   # Python moderate
javascript_min_grade = "B+"
typescript_min_grade = "A-"
c_min_grade = "B"
cpp_min_grade = "B"

# Global fallback
default_min_grade = "B+"
```

### Module-Specific Thresholds (Planned)

```toml
# Future feature (not yet implemented)
[quality_gates.modules]
"src/core/**" = { min_grade = "A+", max_drop = 2.0 }
"src/api/**" = { min_grade = "A", max_drop = 5.0 }
"src/utils/**" = { min_grade = "B+", max_drop = 7.0 }
"tests/**" = { min_grade = "B", max_drop = 10.0 }
```

### Grace Periods

```toml
[quality_gates]
# Allow temporary violations during refactoring
grace_period_days = 7

# Grace period tracking
[grace_periods]
"src/legacy/old_module.rs" = { expires = "2025-11-05", reason = "Refactoring in progress" }
```

---

## Real-World Examples

### Example 1: Sprint 67 - PMAT Dogfooding

**Scenario**: Apply TDG enforcement to PMAT itself

```bash
# Step 1: Create baseline
cd ~/src/paiml-mcp-agent-toolkit
pmat tdg baseline create --output .pmat/tdg-baseline.json --path server/src

# Result: 851 files, avg 93.0 (A grade)

# Step 2: Install hooks
pmat hooks install --tdg-enforcement

# Step 3: Configure (warning mode initially)
cat > .pmat/tdg-rules.toml << EOF
[quality_gates]
rust_min_grade = "B+"
max_score_drop = 5.0
mode = "warning"

[baseline]
baseline_path = ".pmat/tdg-baseline.json"
auto_update_on_main = true
EOF

# Step 4: Test regression check
pmat tdg check-regression --baseline .pmat/tdg-baseline.json --path .

# Result: ✅ No regressions (851 files unchanged)
```

**Outcome**:
- Found critical v2.180.0 bug during dogfooding
- Fixed and released v2.180.1 within 4 hours
- Validated system works on real-world codebase
- Created reference implementation for users

### Example 2: Open Source Project Integration

**Scenario**: Add TDG enforcement to open source Rust project

```bash
# 1. Create baseline at release tag
git checkout v1.0.0
pmat tdg baseline create --output .pmat/tdg-baseline-v1.0.0.json --path src/
git checkout main

# 2. Install hooks (warning mode for contributors)
pmat hooks install --tdg-enforcement

# 3. Configure for open source (permissive)
cat > .pmat/tdg-rules.toml << EOF
[quality_gates]
rust_min_grade = "B"      # Permissive for contributors
max_score_drop = 10.0     # Allow some flexibility
mode = "warning"          # Don't block contributors

[baseline]
baseline_path = ".pmat/tdg-baseline-v1.0.0.json"
auto_update_on_main = false  # Manual baseline updates
EOF

# 4. Add GitHub Actions (strict for maintainers)
# .github/workflows/tdg-quality.yml
# (see CI/CD Integration section above)

# 5. Document in CONTRIBUTING.md
cat >> CONTRIBUTING.md << EOF

## Code Quality Standards

This project uses PMAT TDG enforcement to maintain code quality:

- Minimum grade for new code: B
- Please run 'pmat tdg <file>' before submitting PR
- CI will check for quality regressions
- See .pmat/tdg-rules.toml for configuration
EOF

# 6. Commit configuration
git add .pmat/ .github/workflows/tdg-quality.yml CONTRIBUTING.md
git commit -m "chore: Add TDG quality enforcement"
git push
```

### Example 3: Enterprise Microservices

**Scenario**: Enforce quality across 20 microservices

```bash
# 1. Create shared quality standard
# shared-quality-standard.toml (in shared repo)
cat > shared-quality-standard.toml << EOF
[quality_gates]
rust_min_grade = "A"
python_min_grade = "A-"
max_score_drop = 3.0
mode = "strict"

[quality_gates.modules]
# Critical services get stricter standards
"services/auth/**" = { min_grade = "A+", max_drop = 2.0 }
"services/payment/**" = { min_grade = "A+", max_drop = 2.0 }
"services/user-data/**" = { min_grade = "A", max_drop = 3.0 }

# Supporting services more flexible
"services/notification/**" = { min_grade = "B+", max_drop = 5.0 }
"services/analytics/**" = { min_grade = "B", max_drop = 7.0 }
EOF

# 2. Deploy to each microservice
for service in services/*; do
  cd $service

  # Copy shared standard
  cp ../../shared-quality-standard.toml .pmat/tdg-rules.toml

  # Create baseline
  pmat tdg baseline create --output .pmat/tdg-baseline.json --path src/

  # Install hooks
  pmat hooks install --tdg-enforcement

  # Commit
  git add .pmat/
  git commit -m "chore: Add TDG enforcement"
  git push

  cd ../..
done

# 3. Monitor quality across all services
# quality-dashboard.sh
for service in services/*; do
  echo "=== $service ==="
  cd $service
  pmat tdg baseline compare --baseline .pmat/tdg-baseline.json --path . --format table
  cd ../..
done
```

---

## Best Practices

### 1. Establish Baseline at Stable Points

```bash
# Create baseline at releases
git tag v1.0.0
pmat tdg baseline create --output .pmat/tdg-baseline-v1.0.0.json --path src/
git add .pmat/tdg-baseline-v1.0.0.json
git commit -m "chore: TDG baseline for v1.0.0"

# Update baseline periodically (e.g., monthly)
pmat tdg baseline update --baseline .pmat/tdg-baseline.json --path . --full
git add .pmat/tdg-baseline.json
git commit -m "chore: Monthly TDG baseline update"
```

### 2. Start with Warning Mode

```toml
[quality_gates]
mode = "warning"  # Week 1-2: Learning phase
```

After 2-4 weeks:
```toml
[quality_gates]
mode = "strict"  # Production enforcement
```

### 3. Gradual Threshold Tightening

**Phase 1** (Weeks 1-4):
```toml
rust_min_grade = "C+"  # Very permissive
max_score_drop = 15.0
```

**Phase 2** (Weeks 5-8):
```toml
rust_min_grade = "B"   # Moderate
max_score_drop = 10.0
```

**Phase 3** (Week 9+):
```toml
rust_min_grade = "B+"  # Production standard
max_score_drop = 5.0
```

### 4. Commit Baselines to Git

```bash
# Baselines should be version controlled
git add .pmat/tdg-baseline.json
git commit -m "chore: Update TDG baseline"

# Tag baselines at releases
git tag -a v1.0.0-baseline -m "Quality baseline for v1.0.0"
git push --tags
```

### 5. Document Quality Standards

```markdown
# QUALITY.md

## Code Quality Standards

This project maintains quality via PMAT TDG enforcement:

- **Minimum Grade**: B+ for all new code
- **Regression Tolerance**: Maximum 5-point drop
- **Enforcement**: Strict mode in CI/CD, warning mode locally
- **Baseline**: Updated monthly or at major releases

### Running Quality Checks

```bash
# Check your changes
pmat tdg <file> --baseline .pmat/tdg-baseline.json

# Check for regressions
pmat tdg check-regression --baseline .pmat/tdg-baseline.json --path .
```

### Quality Gate Failures

If CI fails due to quality gate:

1. Run `pmat tdg <file> --verbose` to see what's wrong
2. Refactor to improve quality (extract functions, reduce complexity)
3. Re-run checks until passing
4. If needed, discuss with team (grace period possible)
```

---

## Troubleshooting

### Issue: Baseline Creation Fails

**Symptom**: `pmat tdg baseline create` fails with error

**Diagnosis**:
```bash
# Check path exists
ls -la src/

# Run with verbose logging
pmat tdg baseline create --output .pmat/tdg-baseline.json --path src/ --verbose

# Check for permissions
ls -la .pmat/
```

**Solution**:
```bash
# Create .pmat directory if missing
mkdir -p .pmat

# Ensure write permissions
chmod 755 .pmat
```

### Issue: Pre-commit Hook Blocks Legitimate Commits

**Symptom**: Hook blocks commit even though quality is acceptable

**Diagnosis**:
```bash
# Check what's failing
pmat tdg check-regression --baseline .pmat/tdg-baseline.json --path . --verbose

# Check configuration
cat .pmat/tdg-rules.toml
```

**Solution**:
```bash
# Option 1: Adjust thresholds in .pmat/tdg-rules.toml
max_score_drop = 7.0  # Increase from 5.0

# Option 2: Switch to warning mode temporarily
mode = "warning"

# Option 3: Emergency bypass (NOT RECOMMENDED)
git commit --no-verify
```

### Issue: False Positive Regressions

**Symptom**: Files marked as regressed but no functional changes

**Diagnosis**:
```bash
# Check file hash
pmat tdg src/file.rs --include-hash

# Compare with baseline
jq '.files[] | select(.path == "src/file.rs")' .pmat/tdg-baseline.json
```

**Solution**:
```bash
# Update baseline to include recent improvements
pmat tdg baseline update --baseline .pmat/tdg-baseline.json --path .

# Or increase sensitivity threshold
max_score_drop = 7.0
```

### Issue: CI/CD Performance Slow

**Symptom**: TDG analysis takes too long in CI/CD

**Diagnosis**:
```bash
# Time the analysis
time pmat tdg baseline create --output test.json --path src/
```

**Solution**:
```bash
# 1. Use incremental analysis
pmat tdg check-regression --baseline .pmat/tdg-baseline.json --path . --incremental

# 2. Analyze only changed files in CI
CHANGED_FILES=$(git diff --name-only origin/main...HEAD)
pmat tdg check-quality --files $CHANGED_FILES

# 3. Cache PMAT installation in CI
# (see CI/CD Integration section for caching examples)

# 4. Use parallel analysis (automatic in v2.180.1)
```

---

## Performance Characteristics

### Baseline Creation

| Project Size | Files | Time | Memory |
|--------------|-------|------|--------|
| Small | < 100 | < 1 min | < 100MB |
| Medium | 100-500 | 1-5 min | < 200MB |
| Large | 500-2000 | 5-15 min | < 500MB |
| PMAT-scale | 851 | ~10 min | ~300MB |

### Regression Checks

| Files Checked | Time | Memory |
|---------------|------|--------|
| 1-10 | < 1 sec | < 50MB |
| 10-50 | 1-3 sec | < 100MB |
| 50-100 | 3-5 sec | < 150MB |
| 100+ | 5-10 sec | < 200MB |

### Storage Requirements

| Metric | Size |
|--------|------|
| Baseline (100 files) | ~500KB |
| Baseline (500 files) | ~2MB |
| Baseline (1000 files) | ~4MB |
| PMAT baseline (851 files) | ~66MB (includes full details) |

**Optimization**: Baselines use Blake3 content-hash deduplication, so identical files are stored once.

---

## Migration Guide

### Migrating from No Enforcement

**Week 1**: Establish Baseline
```bash
pmat tdg baseline create --output .pmat/tdg-baseline.json --path src/
git add .pmat/tdg-baseline.json
git commit -m "chore: Establish TDG quality baseline"
```

**Week 2**: Install Hooks (Warning Mode)
```bash
pmat hooks install --tdg-enforcement
# Edit .pmat/tdg-rules.toml: mode = "warning"
git add .pmat/ .git/hooks/
git commit -m "chore: Add TDG hooks in warning mode"
```

**Week 3**: Add CI/CD (Warning Mode)
```bash
# Copy GitHub Actions template
# Set mode = "warning" in workflow
git add .github/workflows/tdg-quality.yml
git commit -m "chore: Add TDG CI/CD in warning mode"
```

**Week 4**: Review Results, Adjust Thresholds
```bash
# Analyze violations
pmat tdg check-regression --baseline .pmat/tdg-baseline.json --path . --verbose

# Adjust thresholds if needed
# Update .pmat/tdg-rules.toml
```

**Week 5+**: Enable Strict Mode
```bash
# Edit .pmat/tdg-rules.toml: mode = "strict"
git add .pmat/tdg-rules.toml
git commit -m "chore: Enable strict TDG enforcement"
```

### Migrating Between PMAT Versions

```bash
# Backup old baseline
cp .pmat/tdg-baseline.json .pmat/tdg-baseline-backup.json

# Re-create baseline with new version
pmat tdg baseline create --output .pmat/tdg-baseline-new.json --path src/

# Compare results
pmat tdg baseline compare \
  --baseline1 .pmat/tdg-baseline-backup.json \
  --baseline2 .pmat/tdg-baseline-new.json

# If acceptable, replace baseline
mv .pmat/tdg-baseline-new.json .pmat/tdg-baseline.json
git add .pmat/tdg-baseline.json
git commit -m "chore: Update baseline for PMAT v2.180.1"
```

---

## Summary

The TDG Enforcement System provides:

✅ **Zero-Regression Guarantees**: Prevent quality degradation automatically
✅ **Baseline Tracking**: Quality archaeology via git-versioned baselines
✅ **Git Hook Integration**: Catch quality issues before they enter the repo
✅ **CI/CD Enforcement**: Automated quality gates in GitHub Actions, GitLab CI, Jenkins
✅ **Configurable Thresholds**: Language-specific and module-specific standards
✅ **Performance**: Sub-second regression checks, minute-scale baseline creation
✅ **Battle-Tested**: Validated through Sprint 67 dogfooding on PMAT itself (851 files, 93.0 avg score)

**Recommendation**: Start with warning mode for 2-4 weeks, then enable strict enforcement. Your future self will thank you.

---

## Next Steps

- [Chapter 5: The Analyze Command Suite](ch05-00-analyze-suite.md)
- [Chapter 7: Quality Gates](ch07-00-quality-gate.md)
- [Chapter 9: Pre-commit Hooks Management](ch09-00-precommit-hooks.md)

---

**Chapter Status**: ✅ Ready for Production (v2.180.1)
**Last Updated**: 2025-10-29
**Validated**: Sprint 67 Dogfooding (851 files, 93.0 avg score)
