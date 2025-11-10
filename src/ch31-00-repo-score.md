# Chapter 31: Repository Health Scoring

The `pmat repo-score` command provides comprehensive health assessment for software repositories, scoring them on a 0-110 scale (100 base points + 10 bonus points) across six quality categories.

## Overview

Repository health scoring helps teams:
- **Quantify code quality** with objective metrics
- **Identify improvement areas** with prioritized recommendations
- **Track progress** over time with consistent grading
- **Enforce standards** with automated quality gates

## Score Categories (100 Base Points)

### Category A: Documentation Quality (20 points)

**A1: README Accuracy (10 points)**
- README.md exists and is not empty
- No broken links (future enhancement)
- Proper markdown formatting

**A2: README Comprehensiveness (10 points)**
- Project description/overview section
- Installation instructions
- Usage examples
- License information
- Contributing guidelines

**Example:**
```bash
$ pmat repo-score /path/to/repo

Documentation: 18/20 (90%) ✅ Pass
├─ A1: README Accuracy: 10/10 ✅
└─ A2: README Comprehensiveness: 8/10 ⚠️
   Missing: Contributing guidelines
```

### Category B: Pre-commit Hooks (20 points)

**B1: Hook Present (10 points)**
- `.git/hooks/pre-commit` exists
- Hook file is executable (Unix systems)
- Partial credit (5 points) if exists but not executable

**B2: Hook Performance (10 points)**
- Fast execution (heuristic: references to `test-fast`, `--quick`)
- Quality checks (linting, formatting)
- Non-blocking for local development

**Example:**
```bash
Pre-commit Hooks: 20/20 (100%) ✅ Pass
├─ B1: Hook Present: 10/10 ✅
└─ B2: Hook Performance: 10/10 ✅
   Fast execution pattern detected
```

### Category C: Repository Hygiene (10 points)

**C1: No Cruft Files (5 points)**
- No temporary files (`.tmp*`, `*.bak`, `*.swp`)
- No build artifacts in version control
- No OS-specific files (`.DS_Store`, `Thumbs.db`)

**C2: No Team-Specific Files (5 points)**
- No IDE configuration (`.idea/`, `.vscode/`)
- Use `.gitignore` for local exclusions
- Keep repository clean for all contributors

**Example:**
```bash
Repository Hygiene: 8/10 (80%) ⚠️ Warning
├─ C1: No Cruft Files: 4/5 ⚠️
│  Found: src/.tmp_cache/data.db (-0.5)
└─ C2: No Team-Specific Files: 4/5 ⚠️
   Found: .idea/workspace.xml (-0.5)
```

### Category D: Build & Test Automation (25 points)

**D1: Makefile Present (5 points)**
- Valid Makefile exists at repository root
- Contains actual build targets

**D2: Required Targets (15 points)**
- `test-fast` (5 points) - Quick unit tests
- `test` (4 points) - Full test suite
- `lint` (3 points) - Code quality checks
- `coverage` (3 points) - Test coverage reporting

**D3: Performance (5 points)**
- Fast targets optimized for speed
- Heuristic analysis of target commands

**Example:**
```bash
Build & Test Automation: 25/25 (100%) ✅ Pass
├─ D1: Makefile Present: 5/5 ✅
├─ D2: Required Targets: 15/15 ✅
│  ✓ test-fast, test, lint, coverage
└─ D3: Performance: 5/5 ✅
   Fast execution patterns detected
```

### Category E: Continuous Integration (20 points)

**E1: CI Workflows Present (10 points)**
- `.github/workflows/` directory exists
- Valid YAML workflow files found
- Score increases with number of workflows (up to 10 points)

**E2: Workflows Configured Properly (10 points)**
- Valid YAML structure (`name:`, `on:`, `jobs:`)
- Testing automation detected
- Linting automation detected

**Example:**
```bash
Continuous Integration: 19/20 (95%) ✅ Pass
├─ E1: CI Workflows Present: 9/10 ✅
│  Found: ci.yml, release.yml, lint.yml
└─ E2: Workflows Configured: 10/10 ✅
   All workflows properly configured with tests and linting
```

### Category F: PMAT Compliance (5 points)

**F1: Configuration Present (2.5 points)**
- `.pmat-gates.toml` exists
- Valid TOML format
- Not empty

**F2: No Violations (2.5 points)**
- Quality gates are defined
- Configuration is meaningful

**Example:**
```bash
PMAT Compliance: 5/5 (100%) ✅ Pass
├─ F1: Configuration Present: 2.5/2.5 ✅
└─ F2: No Violations: 2.5/2.5 ✅
   Quality gates properly configured
```

## Bonus Features (10 points)

Detect advanced quality practices for bonus points:

### Property-Based Testing (+3 points)
- **Detects:** `proptest` dependency in Cargo.toml
- **Detects:** `proptest!` macro usage in source files
- **Why:** Property tests catch edge cases regular tests miss

### Fuzzing (+2 points)
- **Detects:** `fuzz/` directory with targets
- **Detects:** `cargo-fuzz` or `libfuzzer-sys` dependencies
- **Why:** Fuzzing finds security vulnerabilities

### Mutation Testing (+2 points)
- **Detects:** `mutants.toml` configuration
- **Detects:** `cargo-mutants` in CI workflows
- **Detects:** Mutation testing in Makefile
- **Why:** Ensures tests actually catch bugs

### Living Documentation (+3 points)
- **Detects:** `book.toml` (mdBook configuration)
- **Detects:** `src/SUMMARY.md` (book structure)
- **Detects:** `book/` or `docs/` directories with mdBook
- **Why:** Documentation stays synchronized with code

**Example:**
```bash
Bonus Features: 5/10 (50%)
├─ Property Tests: 3/3 ✅
│  Evidence: Cargo.toml, src/tests/properties.rs
├─ Fuzzing: 2/2 ✅
│  Evidence: fuzz/fuzz_targets/
├─ Mutation Testing: 0/2 ❌
└─ Living Docs: 0/3 ❌
```

## Grading System

Repositories receive letter grades based on final score:

| Grade | Score Range | Description |
|-------|-------------|-------------|
| **A+** | 95-110 | Exceptional (includes bonus) |
| **A** | 90-94 | Excellent |
| **A-** | 85-89 | PMAT standard (minimum for production) |
| **B+** | 80-84 | Good |
| **B** | 70-79 | Acceptable |
| **C** | 60-69 | Needs improvement |
| **D** | 50-59 | Poor |
| **F** | 0-49 | Failing |

### Score Status Thresholds

Each category also receives a status:
- **✅ Pass:** ≥90% of category max score
- **⚠️ Warning:** 70-89% of category max score
- **❌ Fail:** <70% of category max score

## Complete Example

```bash
$ pmat repo-score .

Repository Health Score
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Final Score: 97/110 (88.2%)
Grade: A+

Base Score: 92/100
Bonus Points: 5/10

Categories:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Documentation (A): 18/20 (90%) Pass
   ✅ A1: README Accuracy: 10/10
   ⚠️  A2: Comprehensiveness: 8/10
      Missing: Contributing guidelines (2 points)

✅ Pre-commit Hooks (B): 20/20 (100%) Pass
   ✅ B1: Hook Present: 10/10
   ✅ B2: Performance: 10/10

⚠️  Repository Hygiene (C): 8/10 (80%) Warning
   ⚠️  C1: No Cruft: 4/5
      Found: .tmp_cache/ (-0.5)
   ⚠️  C2: No Team Files: 4/5
      Found: .idea/ (-0.5)

✅ Build & Test (D): 23/25 (92%) Pass
   ✅ D1: Makefile Present: 5/5
   ✅ D2: Required Targets: 13/15
      Missing: coverage target (3 points)
   ✅ D3: Performance: 5/5

✅ Continuous Integration (E): 18/20 (90%) Pass
   ✅ E1: Workflows Present: 9/10
   ✅ E2: Configured: 9/10

✅ PMAT Compliance (F): 5/5 (100%) Pass
   ✅ F1: Config Present: 2.5/2.5
   ✅ F2: No Violations: 2.5/2.5

Bonus Features:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Property Tests: 3/3
   Evidence: Cargo.toml, src/lib.rs
✅ Fuzzing: 2/2
   Evidence: fuzz/fuzz_targets/
❌ Mutation Testing: 0/2
❌ Living Docs: 0/3

Recommendations:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔴 CRITICAL (2 points)
   Add Contributing Guidelines
   → Create CONTRIBUTING.md with PR guidelines
   → Impact: +2 points (Documentation)

🟠 HIGH (3 points)
   Add Coverage Target
   → Add 'coverage' target to Makefile
   → Command: Add "coverage:\n\tcargo llvm-cov"
   → Impact: +3 points (Build & Test)

🟡 MEDIUM (1 point)
   Clean Repository Hygiene
   → Remove .tmp_cache/ and .idea/
   → Update .gitignore
   → Impact: +1 point (Hygiene)

🟢 LOW (5 points)
   Add Advanced Testing
   → Consider mutation testing (cargo-mutants)
   → Consider living documentation (mdBook)
   → Impact: +5 bonus points

Metadata:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Repository: /home/noah/src/my-project
Branch: main
Commit: a1b2c3d
Scored: 2025-11-10 19:30:45 UTC
Execution Time: 42ms
Spec Version: 1.0.0
```

## Usage

### Basic Usage

```bash
# Score current directory
pmat repo-score .

# Score specific repository
pmat repo-score /path/to/repo

# Output formats
pmat repo-score . --format json
pmat repo-score . --format text
pmat repo-score . --format junit
```

### CI/CD Integration

```yaml
# .github/workflows/repo-health.yml
name: Repository Health Check

on:
  push:
    branches: [ main ]
  pull_request:

jobs:
  score:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install PMAT
        run: cargo install pmat

      - name: Score Repository
        run: pmat repo-score . --format junit > repo-score.xml

      - name: Upload Results
        uses: actions/upload-artifact@v3
        with:
          name: repo-score
          path: repo-score.xml

      - name: Enforce Minimum Grade
        run: |
          GRADE=$(pmat repo-score . --format json | jq -r '.grade')
          if [[ "$GRADE" != "A+" && "$GRADE" != "A" && "$GRADE" != "A-" ]]; then
            echo "❌ Repository score below A- threshold"
            exit 1
          fi
```

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "🔍 Checking repository health..."
pmat repo-score . --quiet

SCORE=$(pmat repo-score . --format json | jq '.final_score')
if (( $(echo "$SCORE < 85" | bc -l) )); then
    echo "⚠️  Repository score below 85 (A- threshold)"
    echo "Run 'pmat repo-score .' for details"
    exit 1
fi
```

## Design Decisions

### Graceful Degradation
Missing components score 0 points rather than failing the entire assessment. This allows partial repositories to receive meaningful scores.

### Partial Credit
Some components award partial points:
- Non-executable pre-commit hook: 5/10 points (exists but not functional)
- Empty TOML files: 0 points (invalid configuration)
- Minimal README: Proportional points based on sections present

### Heuristic Analysis
Performance scoring uses content analysis instead of execution to avoid:
- Security risks (running untrusted code)
- Time overhead (slow tests)
- Environment dependencies (missing tools)

### Evidence-Based Findings
Every score adjustment is documented with:
- Severity level (Success, Warning, Error, Info)
- Category context
- Impact in points
- Location reference
- Evidence description

## Future Enhancements

### Planned Features
- **Broken Link Detection** - Validate all URLs in README
- **Security Scanning** - Detect common vulnerabilities
- **Dependency Health** - Check for outdated/vulnerable dependencies
- **Code Coverage** - Integrate with llvm-cov for actual coverage metrics
- **Historical Tracking** - Track score changes over time
- **Team Dashboards** - Aggregate scores across multiple repositories
- **Custom Rules** - User-defined scoring criteria

### API Integration

The scoring system is designed to be integrated with:
- **GitHub Status Checks** - Block PRs below threshold
- **Badges** - Display score in README (shields.io)
- **Analytics** - Track organization-wide quality trends
- **Notifications** - Alert on score degradation

## Troubleshooting

### Empty Score (0/110)

**Problem:** Repository scores 0 across all categories

**Solutions:**
- Ensure you're in a valid git repository (`git status`)
- Check file permissions (especially `.git/hooks/pre-commit`)
- Verify expected files exist (README.md, Makefile, etc.)

### Low Hygiene Score

**Problem:** Hygiene category scores poorly despite clean-looking repository

**Solutions:**
- Check for hidden temporary files (`ls -la`)
- Look in subdirectories for IDE files
- Review `.gitignore` patterns
- Run `find . -name ".tmp*"` to locate cruft

### Grade Lower Than Expected

**Problem:** Individual categories score well but overall grade is low

**Solutions:**
- Check bonus points (only awarded for advanced features)
- Review recommendations for quick wins
- Focus on categories with "Fail" status first
- Remember: A- (85) is the PMAT standard, not 90

## Related Commands

- `pmat quality-gate` - Enforce quality thresholds
- `pmat analyze` - Deep code analysis
- `pmat context` - Generate comprehensive context
- `pmat validate-readme` - Detailed README validation

## Summary

The `pmat repo-score` command provides objective, actionable repository health assessment. Use it to:
- Establish quality baselines
- Track improvement over time
- Enforce team standards
- Identify optimization opportunities

**Next Steps:**
- Run `pmat repo-score .` on your repository
- Review recommendations
- Target "Critical" and "High" priority items
- Re-score to track improvement
