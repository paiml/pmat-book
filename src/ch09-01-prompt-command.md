# AI Prompt Generation Command

The `pmat prompt` command provides intelligent AI prompt generation with organizational intelligence integration. It supports multiple workflows including defect-aware prompts, ticket-based TDD workflows, specification-based implementation, and new repository scaffolding.

## Overview

```bash
pmat prompt show --list                      # List all workflow prompts (legacy)
pmat prompt generate --task "Fix auth bug"   # Generate defect-aware prompt
pmat prompt ticket ticket-123.md             # EXTREME TDD ticket workflow
pmat prompt implement docs/spec.md           # Spec-based implementation
pmat prompt scaffold-new-repo docs/spec.md   # New repo with PMAT/bashrs
pmat p show --list                           # Short alias
```

## Subcommands

### `pmat prompt show` - Workflow Prompts (Legacy)

View pre-configured workflow prompts that enforce EXTREME TDD and Toyota Way quality principles.

**Usage:**
```bash
pmat prompt show code-coverage               # Show coverage workflow
pmat prompt show debug --format json         # Get debugging workflow as JSON
pmat prompt show --list                      # List all available prompts
```

**Quick Start:**

```bash
# List all prompts
$ pmat prompt show --list
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

# View a prompt
$ pmat prompt show code-coverage
name: code-coverage
description: Ensure code coverage >85% using EXTREME TDD
category: quality
priority: critical
prompt: |
  All code coverage must be greater than 85%. Continue next best
  recommended step using EXTREME TDD...
```

**Output Formats:**

- `yaml` (default): Full metadata and prompt text
- `json`: Programmatic integration
- `text`: Just the prompt text (ideal for piping to AI)

**Variable Substitution:**

Override default Rust commands for other languages:

```bash
# Python
pmat prompt show code-coverage \
  --set TEST_CMD="pytest" \
  --set COVERAGE_CMD="pytest --cov"

# JavaScript
pmat prompt show code-coverage \
  --set TEST_CMD="npm test" \
  --set COVERAGE_CMD="jest --coverage"

# Go
pmat prompt show code-coverage \
  --set TEST_CMD="go test ./..." \
  --set COVERAGE_CMD="go test -coverprofile=coverage.out"
```

**Options:**
- `--list`: List all available prompts
- `--format <FORMAT>`: Output format (yaml, json, text)
- `--show-variables`: Show available variables
- `--set VAR=value`: Override prompt variables
- `-o, --output <FILE>`: Write output to file

### `pmat prompt generate` - Defect-Aware Prompts

Generate AI prompts enriched with organizational defect patterns from GitHub organization analysis.

**Usage:**
```bash
pmat prompt generate \
  --task "Implement authentication system" \
  --context "Express.js REST API with JWT tokens" \
  --summary org_summary.yaml \
  --output auth_prompt.md
```

**Example:**

```bash
# Step 1: Analyze GitHub organization (see Chapter 32)
pmat org analyze --org mycompany \
  --output org_report.yaml \
  --summarize --strip-pii

# Step 2: Generate defect-aware prompt
pmat prompt generate \
  --task "Add user registration endpoint" \
  --context "Node.js Express API with MongoDB" \
  --summary org_report.summary.yaml

# Output: AI prompt enriched with organizational defect patterns
```

**Generated Prompt Structure:**

```markdown
# Task
Add user registration endpoint

# Context
Node.js Express API with MongoDB

# Organizational Intelligence (3 repositories, 450 commits analyzed)

## Critical Defect Patterns to Avoid

### Integration (35% of defects)
- Missing API endpoint error handling
- Uncaught promise rejections
- Database connection failures

### Testing (28% of defects)
- Missing integration tests
- No error case coverage
- Async test timeouts

## Implementation Checklist
- [ ] Add comprehensive error handling
- [ ] Write integration tests FIRST (EXTREME TDD)
- [ ] Handle all async errors
- [ ] Validate database connection
```

**Why This Matters:**

Traditional AI prompts are generic. Defect-aware prompts are informed by YOUR organization's actual failure patterns from hundreds of commits, dramatically reducing the likelihood of repeating past mistakes.

**Options:**
- `--task <STRING>`: Implementation task description (required)
- `--context <STRING>`: Additional context (tech stack, constraints)
- `--summary <FILE>`: Organizational intelligence summary (from `pmat org analyze`)
- `-o, --output <FILE>`: Write prompt to file

### `pmat prompt ticket` - EXTREME TDD Ticket Workflow

Generate structured workflow prompt for fixing a ticket using EXTREME TDD methodology.

**Usage:**
```bash
pmat prompt ticket ticket-123.md \
  --summary org_summary.yaml \
  --output workflow.md
```

**Example Ticket File (ticket-123.md):**

```markdown
# Bug: Authentication fails on password reset

## Description
Users cannot reset passwords - getting 500 error

## Reproduction Steps
1. Click "Forgot Password"
2. Enter email
3. Submit form
4. Error: "Internal Server Error"

## Expected
Password reset email sent successfully

## Logs
```
Error: SMTP connection timeout
  at sendEmail (mail.js:45)
```

**Generated Workflow:**

```markdown
# EXTREME TDD: Fix Ticket

## Ticket
[Full ticket content]

## Workflow

### 1. RED - Write Failing Test
Write a test that reproduces the issue:
- Test password reset flow
- Assert email is sent
- Assert no 500 error

### 2. GREEN - Minimal Fix
Implement minimal fix to make test pass:
- Add SMTP timeout handling
- Add connection retry logic
- Add proper error responses

### 3. REFACTOR - Clean Up
Improve code while keeping tests green:
- Extract email service
- Add configuration
- Improve error messages

### 4. VERIFY - Quality Gates
Run all quality gates:
- ✅ make test-fast (all tests pass)
- ✅ make coverage (>85%)
- ✅ cargo clippy (no warnings)
- ✅ pmat tdg (score improved)

### 5. COMMIT - Only if Green
Only commit if ALL gates pass.

## Organizational Intelligence (if --summary provided)

### Similar Past Issues
- Email service timeouts (12 occurrences)
- Missing async error handling (8 occurrences)
- No retry logic (5 occurrences)

### Prevention Checklist
- [ ] Add timeout configuration
- [ ] Add retry with exponential backoff
- [ ] Add error handling tests
- [ ] Add integration tests
```

**Options:**
- `--summary <FILE>`: Optional organizational intelligence summary
- `-o, --output <FILE>`: Write workflow to file

### `pmat prompt implement` - Specification-Based Implementation

Generate implementation prompt from a technical specification document.

**Usage:**
```bash
pmat prompt implement docs/specifications/api-versioning.md \
  --summary org_summary.yaml \
  --output implementation_plan.md
```

**Example Specification (api-versioning.md):**

```markdown
# API Versioning Specification

## Overview
Implement API versioning using URL path versioning (e.g., /v1/users, /v2/users)

## Requirements
1. Support multiple API versions simultaneously
2. Route requests to correct version handler
3. Deprecation warnings for old versions
4. Version header in responses

## Acceptance Criteria
- [ ] /v1/* routes to v1 handlers
- [ ] /v2/* routes to v2 handlers
- [ ] X-API-Version header in all responses
- [ ] 85%+ test coverage
```

**Generated Implementation Prompt:**

```markdown
# Implementation: API Versioning Specification

## Specification
[Full spec content from api-versioning.md]

## EXTREME TDD Implementation Steps

### Phase 1: RED (Write Tests)
```typescript
// tests/api-versioning.test.ts
describe('API Versioning', () => {
  test('v1 endpoint returns X-API-Version: 1.0', async () => {
    const response = await request(app).get('/v1/users');
    expect(response.headers['x-api-version']).toBe('1.0');
  });

  test('v2 endpoint returns X-API-Version: 2.0', async () => {
    const response = await request(app).get('/v2/users');
    expect(response.headers['x-api-version']).toBe('2.0');
  });
});
```

### Phase 2: GREEN (Implement)
1. Add version routing middleware
2. Add version header middleware
3. Create v1 and v2 route handlers
4. Add deprecation warnings

### Phase 3: REFACTOR
1. Extract version logic to module
2. Add configuration for versions
3. Improve error handling

## Organizational Intelligence

### Common Pitfalls (from your organization's history)
- Missing backward compatibility tests (15 occurrences)
- Breaking changes without deprecation warnings (12 occurrences)
- Version routing bugs (8 occurrences)

### Quality Checklist
- [ ] Write tests for ALL version combinations
- [ ] Test backward compatibility
- [ ] Document breaking changes
- [ ] Add deprecation timeline
- [ ] Verify >85% coverage
```

**Options:**
- `--summary <FILE>`: Optional organizational intelligence summary
- `-o, --output <FILE>`: Write implementation plan to file

### `pmat prompt scaffold-new-repo` - New Repository Setup

Generate comprehensive setup prompt for a new repository with PMAT tools, bashrs, roadmapping, and quality infrastructure.

**Usage:**
```bash
pmat prompt scaffold-new-repo docs/specifications/new-service.md \
  --include-pmat \
  --include-bashrs \
  --include-roadmap \
  --output setup_plan.md
```

**Example Specification (new-service.md):**

```markdown
# New Microservice: User Notification Service

## Tech Stack
- Language: Rust
- Framework: Actix-web
- Database: PostgreSQL
- Message Queue: RabbitMQ

## Purpose
Send notifications (email, SMS, push) to users
```

**Generated Setup Prompt:**

```markdown
# New Repository Setup: User Notification Service

## Specification
[Full spec from new-service.md]

## Repository Setup Checklist

### 1. Initialize Repository
```bash
cargo init user-notification-service --bin
cd user-notification-service
git init
```

### 2. PMAT Tools Integration
```bash
# Add PMAT as dev dependency
cargo add --dev pmat

# Install TDG enforcement hooks
pmat hooks install --tdg-enforcement

# Create .pmatignore
cat > .pmatignore <<EOF
target/
.git/
*.log
EOF

# Configure quality gates in CI/CD
cat > .github/workflows/quality.yml <<EOF
name: Quality Gates
on: [push, pull_request]
jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: cargo build --all-features
      - run: cargo clippy -- -D warnings
      - run: cargo test
      - run: pmat quality-gate --fail-on-violation
EOF
```

### 3. bashrs Integration
```bash
# Install bashrs for shell safety
cargo install bashrs

# Lint all shell scripts
bashrs lint Makefile
bashrs lint scripts/*.sh

# Add bashrs to pre-commit hook (already included in pmat hooks)
```

### 4. Roadmap Management
```bash
# Create roadmap
mkdir -p docs/roadmap
pmat maintain roadmap --create

# Initial roadmap structure:
docs/roadmap/
├── 2025-Q1-notifications.md
├── 2025-Q2-scaling.md
└── backlog.md
```

### 5. Quality Infrastructure
```bash
# Makefile with quality targets
cat > Makefile <<EOF
.PHONY: test coverage lint quality-gate

test:
	cargo test

test-fast:
	cargo test --lib

coverage:
	cargo llvm-cov --all-features --lcov --output-path lcov.info

lint:
	cargo clippy --all-targets --all-features -- -D warnings
	cargo fmt -- --check
	bashrs lint Makefile scripts/*.sh

quality-gate:
	pmat quality-gate --fail-on-violation
	pmat tdg --threshold 60
	make coverage
	make lint
EOF

# Run initial quality check
make quality-gate
```

### 6. Documentation
```bash
# README.md
cat > README.md <<EOF
# User Notification Service

[Spec description]

## Quick Start
\`\`\`bash
cargo build
cargo test
make quality-gate
\`\`\`

## Quality Standards
- 85%+ test coverage (enforced by PMAT)
- TDG score >60 (enforced by hooks)
- Zero clippy warnings
- All bash scripts pass bashrs linting
EOF

# Create docs structure
mkdir -p docs/{specifications,architecture,roadmap}
```

### 7. Testing Infrastructure
```bash
# Add test dependencies
cargo add --dev proptest tokio-test

# Create tests structure
mkdir -p tests/{integration,property}

# Property-based testing example
cat > tests/property/notification_tests.rs <<EOF
use proptest::prelude::*;

proptest! {
    #[test]
    fn email_validation_never_panics(email in ".*") {
        let _ = validate_email(&email);
    }
}
EOF
```

## Organizational Intelligence

### Repository Setup Pitfalls (from your organization)
- Missing CI/CD quality gates (20 occurrences)
- No test coverage tracking (18 occurrences)
- Shell scripts without linting (15 occurrances)
- No roadmap planning (12 occurrences)

### Quality Checklist
- [ ] PMAT hooks installed and tested
- [ ] bashrs linting all shell scripts
- [ ] CI/CD quality gates configured
- [ ] Initial test coverage >85%
- [ ] Roadmap created and documented
- [ ] README with quality standards
- [ ] Property-based tests for core logic

## Next Steps
1. Run `make quality-gate` to verify setup
2. Create first feature branch
3. Implement MVP using EXTREME TDD
4. Verify all quality gates pass
5. Deploy to staging
```

**Options:**
- `--include-pmat`: Include PMAT tools integration (default: true)
- `--include-bashrs`: Include bashrs shell linting (default: true)
- `--include-roadmap`: Include roadmap management setup (default: true)
- `-o, --output <FILE>`: Write setup plan to file

## Practical Use Cases

### 1. Pipe Defect-Aware Prompts to AI

```bash
# Generate defect-aware prompt and copy to clipboard
pmat prompt generate \
  --task "Add user authentication" \
  --context "Express.js REST API" \
  --summary org_summary.yaml \
  --format text | pbcopy

# Paste into Claude Code, ChatGPT, or Cursor
```

### 2. Ticket Workflow for Team

```bash
# Generate workflow for team member
pmat prompt ticket jira-1234.md \
  --summary org_summary.yaml \
  --output workflow.md

# Share workflow.md with team member
```

### 3. Implementation Planning

```bash
# Generate implementation plan from spec
pmat prompt implement docs/specifications/caching.md \
  --summary org_summary.yaml \
  --output implementation_plan.md

# Use plan for sprint planning
```

### 4. New Microservice Setup

```bash
# Generate comprehensive setup guide
pmat prompt scaffold-new-repo docs/specifications/analytics-service.md \
  --include-pmat \
  --include-bashrs \
  --include-roadmap \
  --output setup_guide.md

# Follow setup_guide.md step-by-step
```

### 5. Legacy Workflow Prompts

```bash
# Still available for backward compatibility
pmat prompt show code-coverage --format text | pbcopy
pmat prompt show debug --format text > docs/DEBUGGING.md
```

## MCP Integration

All prompt generation is available as MCP tools for AI assistants:

```json
// Claude Desktop config.json
{
  "mcpServers": {
    "pmat": {
      "command": "pmat",
      "args": ["serve", "--mcp"]
    }
  }
}
```

**Available MCP Tools:**
- `generate_defect_aware_prompt`: Generate defect-aware AI prompts
- `analyze_organization`: Analyze GitHub organization for defect patterns
- (See Chapter 15 for complete MCP tools reference)

## Toyota Way Principles

All prompt subcommands enforce these principles:

### Jidoka (Built-in Quality)
- Every prompt includes quality gates and verification steps
- Organizational intelligence prevents past defects

### Andon Cord (Stop the Line)
- All prompts include "STOP THE LINE" language for quality issues
- RED-GREEN-REFACTOR enforces stopping on test failures

### Five Whys (Root Cause Analysis)
- `ticket` workflow encourages root cause analysis
- Organizational intelligence reveals systemic patterns

### Genchi Genbutsu (Go and See)
- Prompts based on ACTUAL organizational defect patterns
- Data-driven from real commit history

### Kaizen (Continuous Improvement)
- Organizational intelligence improves over time
- More commits analyzed = better defect prevention

## Best Practices

### 1. Always Use Organizational Intelligence

Run `pmat org analyze` periodically (monthly recommended) to keep defect patterns current:

```bash
pmat org analyze --org mycompany \
  --output org_report.yaml \
  --summarize --strip-pii
```

### 2. Use Text Format for AI Assistants

Always use `--format text` when piping to AI:

```bash
pmat prompt generate --task "..." --context "..." --format text | pbcopy
```

### 3. Save Generated Prompts

Save prompts for team documentation and repeatability:

```bash
pmat prompt ticket ticket-123.md --output workflow.md
pmat prompt implement spec.md --output implementation_plan.md
```

### 4. PII Stripping for Public Repos

Always use `--strip-pii` when analyzing organizations:

```bash
pmat org analyze --org mycompany --summarize --strip-pii
```

### 5. Combine with Deep Context

For maximum effectiveness, combine with `pmat context`:

```bash
# Generate deep context
pmat context --output deep_context.md

# Generate defect-aware prompt with context
pmat prompt generate \
  --task "Add caching layer" \
  --context "$(cat deep_context.md)" \
  --summary org_summary.yaml
```

## Command Options Reference

### Global Options
- `-o, --output <FILE>`: Write output to file instead of stdout

### `show` Subcommand
- `--list`: List all available prompts
- `--format <FORMAT>`: Output format (yaml, json, text)
- `--show-variables`: Show available variables
- `--set VAR=value`: Override prompt variables (can be repeated)

### `generate` Subcommand
- `--task <STRING>`: Implementation task description (required)
- `--context <STRING>`: Additional context (tech stack, constraints)
- `--summary <FILE>`: Organizational intelligence summary

### `ticket` Subcommand
- `--summary <FILE>`: Optional organizational intelligence summary

### `implement` Subcommand
- `--summary <FILE>`: Optional organizational intelligence summary

### `scaffold-new-repo` Subcommand
- `--include-pmat`: Include PMAT tools integration (default: true)
- `--include-bashrs`: Include bashrs shell linting (default: true)
- `--include-roadmap`: Include roadmap management setup (default: true)

## Short Alias

Use `pmat p` as a shorthand:

```bash
pmat p show --list                          # Same as pmat prompt show --list
pmat p generate --task "..." --context "..." # Same as pmat prompt generate...
pmat p ticket ticket-123.md                  # Same as pmat prompt ticket...
```

## Summary

The `pmat prompt` command provides intelligent AI prompt generation with organizational intelligence integration:

- **`show`**: Legacy workflow prompts with variable substitution
- **`generate`**: Defect-aware prompts informed by organizational patterns
- **`ticket`**: EXTREME TDD ticket workflow generation
- **`implement`**: Specification-based implementation planning
- **`scaffold-new-repo`**: New repository setup with PMAT/bashrs/roadmapping

All subcommands can optionally accept `--summary` to enrich prompts with your organization's actual defect patterns, dramatically reducing the likelihood of repeating past mistakes.

**Next Steps:**
- See [Chapter 32: Organizational Intelligence](ch32-00-organizational-intelligence.md) for `pmat org analyze`
- See [Chapter 15: MCP Tools Reference](ch15-00-mcp-tools.md) for AI assistant integration
- See [Chapter 4: TDG Enforcement](ch04-02-tdg-enforcement.md) for quality gates
