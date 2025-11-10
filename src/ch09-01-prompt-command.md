# Workflow Prompts Command

The `pmat prompt` command provides pre-configured workflow prompts that enforce EXTREME TDD and Toyota Way quality principles. These prompts are designed to be used with AI assistants like Claude Code, or as reference documentation for development teams.

## Overview

```bash
pmat prompt --list                    # List all available prompts
pmat prompt code-coverage             # Show coverage workflow
pmat prompt debug --format json       # Get debugging workflow as JSON
pmat p --list                         # Short alias
```

## Quick Start

### List All Prompts

```bash
$ pmat prompt --list
Available Prompts:

  code-coverage - Enforce 85%+ coverage using EXTREME TDD [critical]
  debug - Five Whys root cause analysis [critical]
  quality-enforcement - Run all quality gates [critical]
  security-audit - Security analysis and fixes [critical]

  continue - Continue next best step [high]
  assert-cmd-testing - Verify CLI test coverage [high]
  mutation-testing - Run mutation testing [high]
  performance-optimization - Speed optimization [high]
  refactor-hotspots - Refactor high-TDG code [high]

  clean-repo-cruft - Remove temporary files [medium]
  documentation - Update and validate docs [medium]
```

### View a Prompt

```bash
$ pmat prompt code-coverage
name: code-coverage
description: Ensure code coverage >85% using EXTREME TDD
category: quality
priority: critical
prompt: |
  All code coverage must be greater than 85%. Continue next best
  recommended step using EXTREME TDD...
```

## Output Formats

### YAML Format (Default)

```bash
pmat prompt code-coverage
```

Returns the full prompt with all metadata in YAML format.

### JSON Format

```bash
pmat prompt code-coverage --format json
```

Perfect for programmatic use or CI/CD integration:

```json
{
  "name": "code-coverage",
  "description": "Ensure code coverage >85% using EXTREME TDD",
  "category": "quality",
  "priority": "critical",
  "coverage_target": 85,
  "methodology": "EXTREME TDD"
}
```

### Text Format

```bash
pmat prompt code-coverage --format text
```

Returns just the prompt text, ideal for piping to AI assistants:

```
All code coverage must be greater than 85%. Continue next best
recommended step using EXTREME TDD...
```

## Available Prompts

### CRITICAL Priority Prompts

#### code-coverage

Ensures all code coverage is greater than 85% using EXTREME TDD methodology.

**Usage:**
```bash
pmat prompt code-coverage --format text | pbcopy
# Paste into Claude Code or your AI assistant
```

**Key Features:**
- Enforces 85%+ coverage target
- Time constraints: `make coverage <10min`, `make test-fast <5min`
- Heuristics: uncovered code first, low coverage with low TDG
- Testing approaches: mutation, property-based, cargo examples

#### debug

Five Whys root cause analysis for debugging issues.

**Usage:**
```bash
pmat prompt debug --format text
```

**Process:**
1. Why did this problem occur? [Surface symptom]
2. Why did that happen? [Immediate cause]
3. Why did that happen? [Underlying cause]
4. Why did that happen? [Systemic issue]
5. Why did that happen? [ROOT CAUSE]

#### quality-enforcement

Runs all quality gates and enforces extreme quality standards.

**Quality Gates:**
1. Compilation: `cargo build --all-features`
2. Linting: `cargo clippy -- -D warnings`
3. Formatting: `cargo fmt -- --check`
4. Tests: `make test-fast` (100% passing)
5. Coverage: `make coverage` (>85%)
6. Mutation: `pmat mutate` (score >80%)
7. Complexity: `pmat analyze` (max <15)
8. TDG: `pmat tdg` (average >60)
9. Documentation: `pmat validate-docs`
10. README: `pmat validate-readme`
11. Book: `make validate-book`
12. Bash: `bashrs lint`

#### security-audit

Security analysis and vulnerability fixes using EXTREME TDD.

**Checks:**
- `cargo audit` for known vulnerabilities
- `bashrs lint` for shell injection
- SQL injection points
- Command injection
- Path traversal
- Unvalidated input

### HIGH Priority Prompts

#### continue

Continue next best recommended step using EXTREME TDD.

**Workflow:**
1. Run `pmat analyze` to identify issues
2. Run `pmat tdg` to find highest debt
3. Prioritize using heuristics
4. Implement fix using RED-GREEN-REFACTOR
5. Verify all quality gates pass
6. Commit with descriptive message

#### mutation-testing

Run mutation testing on high-complexity or low-coverage code.

**Target Files:**
- Complexity >10
- Coverage <85%
- TDG score <50

**Mutation Score Target:** 80%

#### performance-optimization

Speed up compilation and test execution using Five Whys.

**Targets:**
- `make coverage`: <10 minutes
- `make test-fast`: <5 minutes (ideally <3)
- Pre-commit test: <30 seconds

**Common Optimizations:**
- Exclude slow tests from test-fast
- Enable mold linker
- Use cargo-nextest
- Feature flags for heavy dependencies

#### refactor-hotspots

Refactor high-TDG/low-coverage code using EXTREME TDD.

**Hotspot Criteria:**
- TDG score >80
- Complexity >15
- Coverage <85%

**Improvement Goals:**
- TDG improvement: +20 points
- Complexity reduction: -30%
- Coverage target: >85%

### MEDIUM Priority Prompts

#### clean-repo-cruft

Remove all temporary files from repository root.

**Patterns to Clean:**
- `defect-report-*.txt`
- `defect-report-*.json`
- `*.tmp`
- `.DS_Store`

#### documentation

Update all documentation and verify accuracy.

**Steps:**
1. Update README.md
2. Update CHANGELOG.md
3. Update docs/ specifications
4. Update pmat-book if CLI changed
5. Run `pmat validate-docs`
6. Run `pmat validate-readme`
7. Push pmat-book changes FIRST

## Variable Substitution

Prompts support variable substitution for non-Rust projects.

### Rust Projects (Default)

```bash
pmat prompt code-coverage
# Uses: cargo test, cargo clippy, cargo llvm-cov
```

### Python Projects

```bash
pmat prompt code-coverage \
  --set TEST_CMD="pytest" \
  --set COVERAGE_CMD="pytest --cov" \
  --set LINT_CMD="pylint"
```

### JavaScript Projects

```bash
pmat prompt code-coverage \
  --set TEST_CMD="npm test" \
  --set COVERAGE_CMD="jest --coverage" \
  --set LINT_CMD="eslint"
```

### Go Projects

```bash
pmat prompt code-coverage \
  --set TEST_CMD="go test ./..." \
  --set COVERAGE_CMD="go test -coverprofile=coverage.out" \
  --set LINT_CMD="golint"
```

### View Available Variables

```bash
pmat prompt code-coverage --show-variables
Variables:
  ${TEST_CMD}
  ${COVERAGE_CMD}
  ${LINT_CMD}
```

## Toyota Way Principles

All prompts enforce these principles:

### Jidoka (Built-in Quality)

Every prompt includes quality gates and verification steps.

### Andon Cord (Stop the Line)

All prompts include "STOP THE LINE" language for quality issues:

> If you spot a defect due to unimplemented or partially implemented functionality, STOP THE LINE and implement using EXTREME TDD. The concept of "pre-existing failure" is irrelevant, fix.

### Five Whys (Root Cause Analysis)

The `debug` and `performance-optimization` prompts explicitly use Five Whys methodology.

### Genchi Genbutsu (Go and See)

Prompts encourage verification of actual state:
- Run actual commands
- Check actual metrics
- Verify actual quality gates

### Kaizen (Continuous Improvement)

The `continue` prompt enables iterative improvement workflow.

### PDCA Cycle (Plan-Do-Check-Act)

All prompts follow:
1. **Plan**: Identify issues via analysis
2. **Do**: Implement fixes using TDD
3. **Check**: Run quality gates
4. **Act**: Commit and iterate

## Practical Use Cases

### 1. Pipe to AI Assistant

```bash
# Copy to clipboard
pmat prompt debug --format text | pbcopy

# Paste into Claude Code, ChatGPT, or Cursor
```

### 2. Generate Team Workflow Documentation

```bash
pmat prompt quality-enforcement --format text > docs/QUALITY_GATES.md
```

### 3. CI/CD Integration

```bash
# Generate JSON for programmatic use
pmat prompt continue --format json > .pmat/workflow.json
```

### 4. Project-Specific Workflow

```bash
# Customize for Python project
pmat prompt code-coverage \
  --set TEST_CMD="pytest" \
  -o .github/COVERAGE_WORKFLOW.md
```

### 5. Quick Reference

```bash
# List all prompts for team reference
pmat prompt --list > docs/WORKFLOWS.md
```

## Command Options

### `--list`

List all available prompts with descriptions and priorities.

```bash
pmat prompt --list
```

### `--format <FORMAT>`

Output format: `yaml` (default), `json`, or `text`.

```bash
pmat prompt code-coverage --format json
```

### `--show-variables`

Show available variables that can be customized.

```bash
pmat prompt code-coverage --show-variables
```

### `--set VAR=value`

Override prompt variables (can be repeated).

```bash
pmat prompt code-coverage \
  --set TEST_CMD="pytest" \
  --set COVERAGE_CMD="pytest --cov"
```

### `-o, --output <FILE>`

Write output to file instead of stdout.

```bash
pmat prompt quality-enforcement -o workflow.yaml
```

## Short Alias

Use `pmat p` as a shorthand:

```bash
pmat p --list                    # Same as pmat prompt --list
pmat p code-coverage             # Same as pmat prompt code-coverage
pmat p debug --format text       # Same as pmat prompt debug --format text
```

## Examples

### Example 1: Coverage Workflow

```bash
$ pmat prompt code-coverage --format text
All code coverage must be greater than 85%. Continue next best
recommended step or roadmap using EXTREME TDD (mutation/property/
cargo run --example, pmat tdg enhanced testing) that respects
(make coverage <10min, make test-fast under <5 min, and
pre-commit test < 30 seconds).

Use Heuristic:
1. Uncovered code
2. Low coverage with low TDG score

If you spot a defect due to unimplemented or partially implemented
functionality, STOP THE LINE and implement using EXTREME TDD. The
concept of "pre-existing failure" is irrelevant, fix.
```

### Example 2: Debug with Five Whys

```bash
$ pmat prompt debug --format text | head -20
Debug this issue using Five Whys root cause analysis and a
permanent fix that solves root cause using EXTREME TDD...

Five Whys Process:
1. Why did this problem occur? [Surface symptom]
2. Why did that happen? [Immediate cause]
3. Why did that happen? [Underlying cause]
4. Why did that happen? [Systemic issue]
5. Why did that happen? [ROOT CAUSE]
```

### Example 3: All Quality Gates

```bash
$ pmat prompt quality-enforcement --format text | grep "Quality Gates:" -A 12
Quality Gates:
1. Compilation: cargo build --all-features
2. Linting: cargo clippy --all-targets --all-features -- -D warnings
3. Formatting: cargo fmt -- --check
4. Tests: make test-fast (must pass 100%)
5. Coverage: make coverage (must be >85%)
6. Mutation: pmat mutate (score >80%)
7. Complexity: pmat analyze (max complexity <15)
8. TDG: pmat tdg (average score >60%)
9. Documentation: pmat validate-docs (no broken links)
10. README: pmat validate-readme (no hallucinations)
11. Book: make validate-book (all tests pass)
12. Bash: bashrs lint Makefile scripts/*.sh
```

## Best Practices

### 1. Use Text Format for AI Assistants

Always use `--format text` when piping to AI assistants:

```bash
pmat prompt continue --format text | pbcopy
```

### 2. Save Team Workflows

Generate workflow documentation for your team:

```bash
pmat prompt quality-enforcement --format text > docs/QUALITY.md
pmat prompt code-coverage --format text > docs/COVERAGE.md
pmat prompt debug --format text > docs/DEBUGGING.md
```

### 3. Customize for Your Stack

Override variables for non-Rust projects:

```bash
# Python
pmat prompt code-coverage --set TEST_CMD="pytest"

# JavaScript
pmat prompt code-coverage --set TEST_CMD="npm test"

# Go
pmat prompt code-coverage --set TEST_CMD="go test ./..."
```

### 4. Use JSON for Automation

Use JSON format for CI/CD or programmatic use:

```bash
pmat prompt continue --format json > .pmat/workflow.json
```

### 5. List Before Using

Always check available prompts first:

```bash
pmat prompt --list
```

## Summary

The `pmat prompt` command provides 11 pre-configured workflow prompts that enforce EXTREME TDD and Toyota Way principles. These prompts can be:

- Viewed in multiple formats (YAML, JSON, text)
- Customized with variable substitution
- Piped to AI assistants
- Saved as team documentation
- Integrated into CI/CD workflows

All prompts enforce quality gates, time constraints, and zero-tolerance policies, making them ideal for maintaining high-quality codebases.
