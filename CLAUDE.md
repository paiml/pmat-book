# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the PMAT Book - a comprehensive guide to the PAIML MCP Agent Toolkit (PMAT), an MCP tool for making agentic coding reliable from Pragmatic AI Labs. The book follows the same structure and style as the Ruchy Programming Language book.

## Book Development Commands

### Core Commands
- `make build` - Build the book with mdBook
- `make serve` - Serve the book locally with auto-reload (port 3000)
- `make clean` - Remove all build artifacts
- `make validate` - Run all quality checks before committing

### Testing Commands
- `make test` - Test all code examples in the book
- `make test-ch01` - Test specific chapter examples
- `make lint` - Lint all code examples
- `make lint-markdown` - Validate markdown links

### Setup
- `make install-deps` - Install mdBook and required tools
- `cargo install mdbook` - Install mdBook if not present
- `cargo install mdbook-linkcheck` - Install link checker

## Book Structure

The book follows a test-driven documentation approach:

```
src/
├── SUMMARY.md                  # Table of contents
├── title-page.md               # Book title page
├── foreword.md                 # Foreword
├── introduction.md             # Introduction
├── ch00-00-introduction.md     # Getting started overview
├── ch01-*.md                   # Installation and setup chapters
├── ch02-*.md                   # Core PMAT concepts
├── ch03-*.md                   # MCP protocol integration
├── ch04-*.md                   # Practical examples
├── appendix-*.md               # Reference materials
└── conclusion.md               # Conclusion
```

## Chapter Status Tracking

Each chapter should include a status block at the top:

```markdown
<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (X/X examples)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | X | Ready for production use |
| ⚠️ Not Implemented | 0 | Planned for future versions |
| ❌ Broken | 0 | Known issues, needs fixing |
| 📋 Planned | 0 | Future roadmap features |

*Last updated: YYYY-MM-DD*  
*PMAT version: pmat X.X.X*
<!-- DOC_STATUS_END -->
```

## Code Examples

All code examples should:
1. Be tested and working with the current PMAT version
2. Include clear input/output examples
3. Show both CLI and MCP usage where applicable
4. Use consistent formatting and style

Example structure:
```markdown
### Example: Analyzing a Repository

```bash
# CLI usage
pmat analyze /path/to/repo

# MCP tool usage
{
  "tool": "analyze_repository",
  "params": {
    "path": "/path/to/repo"
  }
}
```

**Output:**
```json
{
  "files": 100,
  "lines": 5000,
  "languages": ["rust", "python"]
}
```
```

## Configuration Files

### book.toml
Main mdBook configuration with:
- Book metadata (title, authors, description)
- Build settings
- HTML output configuration with theme
- Search and playground settings

### Makefile
Automation for:
- Building and serving the book
- Testing code examples
- Quality checks and validation
- Version synchronization

## Quality Standards - STRICT TDD REQUIREMENTS

1. **ZERO CODE WITHOUT TDD**: Every single code example MUST have corresponding automated tests
2. **Test-First Development**: Tests are written before documentation examples
3. **Automated Validation**: All examples verified via `make test` in CI/CD
4. **PMAT Dogfooding**: Use PMAT itself to analyze the book codebase
5. **GitHub Actions Integration**: All tests run automatically on push/PR
6. **Quality Gates**: Minimum Grade B+ required for all commits
7. **No Vaporware**: Only document features that are implemented and tested
8. **Version Consistency**: All examples use the same PMAT version

## Theme and Styling

The book uses custom CSS for enhanced readability:
- `theme/pmat.css` - Main theme styles
- `theme/code-enhancements.css` - Code block improvements
- Syntax highlighting for bash, JSON, YAML, and other formats

## Writing Guidelines

1. **Be Concrete**: Use specific examples from the PMAT codebase
2. **Show Results**: Always include actual output from commands
3. **Progressive Complexity**: Start simple, build up to advanced features
4. **Cross-Reference**: Link between related chapters and concepts
5. **Test Everything**: No untested code in the documentation

## Chapter Template

```markdown
# Chapter Title

<!-- DOC_STATUS_START -->
[Status block]
<!-- DOC_STATUS_END -->

## The Problem
[What problem does this chapter solve?]

## Core Concepts
[Key ideas and terminology]

## Practical Examples
[Working code examples with output]

## Common Patterns
[Best practices and idioms]

## Troubleshooting
[Common issues and solutions]

## Summary
[Key takeaways]
```

## TDD Workflow - MANDATORY PROCESS

1. **Write Tests First**: Create `tests/chXX/test_*.sh` files BEFORE writing chapter content
2. **Red Phase**: Tests fail initially (no implementation yet)
3. **Write Documentation**: Document examples that make tests pass
4. **Green Phase**: Run `make test-chXX` to verify tests pass
5. **Update Status**: Update chapter status blocks with test results
6. **Validate Quality**: Run `make validate` (includes PMAT dogfooding)
7. **Commit**: Only commit when all tests pass and quality gates met

### Test Structure Requirements

Each test file must:
- Use bash with `set -e` for fail-fast
- Include test utilities (test_pass/test_fail functions)
- Create isolated test environments (temp directories)
- Clean up resources (trap cleanup EXIT)
- Validate JSON output with `jq`
- Check expected vs actual results
- Provide clear pass/fail messages
- Return proper exit codes (0 = success, 1 = failure)

### Example Test Template

```bash
#!/bin/bash
# TDD Test: Chapter X - Feature Name
set -e

PASS_COUNT=0
FAIL_COUNT=0

test_pass() {
    echo "✅ PASS: $1"
    ((PASS_COUNT++))
}

test_fail() {
    echo "❌ FAIL: $1"
    ((FAIL_COUNT++))
}

# Test implementation here...

# Summary
if [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ $FAIL_COUNT tests failed"
    exit 1
fi
```

## Version Management

- Track PMAT version in each chapter's status block
- Update all examples when PMAT version changes
- Use `make sync-version` to update version references
- Maintain CHANGELOG.md with version history
- all examples must be TDD driven like other books. there can be no code without TDD, under any circumstances. Also, github actions must test everything and we must use pmat itself and dogfood it in testing via github actions as well as building examples.

## GitHub Actions Requirements

The repository MUST include:
- `.github/workflows/test.yml` that runs all chapter tests
- PMAT dogfooding analysis on every push/PR
- Quality gate enforcement (Grade B+ minimum)
- Automated book building and deployment
- Test result artifacts uploaded for inspection
- PR comments with quality reports

## Commands Reference for Development

```bash
# Run all tests
make test

# Test specific chapter  
make test-ch01

# Run PMAT analysis on book itself
make dogfood-pmat

# Check quality gates
make quality-gate

# Run complete validation
make validate

# Build the book
make build

# Serve locally for development
make serve
```
- all examples must be TDD driven like other books.  there can be no code without TDD, under any circumstances.  Also, github actions must test everything and we must use pmat itself and dogfood it in testing via github actions as well as building examples.