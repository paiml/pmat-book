# Using PMAT Effectively

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working

| Status | Count | Description |
|--------|-------|-------------|
| ✅ Working | 3 | All sections verified with v2.212.0 |
| ⚠️ Not Implemented | 0 | None |
| ❌ Broken | 0 | None |
| 📋 Planned | 0 | None |

*Last updated: 2025-12-13*
*PMAT version: pmat 2.212.0*
<!-- DOC_STATUS_END -->

This section answers common questions about PMAT usage patterns, including CLI vs MCP mode, workflow tracking, and finding documentation.

## CLI vs MCP: Understanding the Modes

### What is MCP?

MCP (Model Context Protocol) is an open protocol that allows AI assistants (like Claude) to interact with external tools. PMAT supports both:

1. **CLI Mode**: Direct command-line usage by humans
2. **MCP Mode**: Protocol-based communication with AI assistants

### Are All Services Available via MCP?

**Yes, with some nuances:**

| Feature | CLI | MCP | Notes |
|---------|-----|-----|-------|
| Code Analysis | ✅ | ✅ | `analyze complexity`, `analyze satd`, `analyze dead-code` |
| TDG Scoring | ✅ | ✅ | `tdg`, `tdg-file` |
| Context Generation | ✅ | ✅ | `context`, `context-file` |
| Quality Gates | ✅ | ✅ | `quality-gate` |
| Perfection Score | ✅ | ✅ | `perfection-score` |
| Work Tracking | ✅ | ✅ | `work start`, `work status`, `work complete` |
| Roadmap Management | ✅ | ✅ | `roadmap validate`, `roadmap migrate` |
| Interactive Commands | ✅ | ⚠️ | Some interactive features require TTY |

**Key Differences:**

```bash
# CLI Mode - Human-friendly output with colors and formatting
pmat analyze complexity --project-path .

# MCP Mode - JSON output for AI consumption
# (automatically detected when running via MCP server)
pmat --mode mcp analyze complexity --project-path .
```

**MCP Server Setup** (for Claude Desktop/Code):

```json
{
  "mcpServers": {
    "pmat": {
      "command": "pmat",
      "args": ["--mode", "mcp", "mcp-server"]
    }
  }
}
```

### When to Use Each Mode

| Use Case | Recommended Mode |
|----------|-----------------|
| Daily development workflow | CLI |
| AI-assisted code review | MCP |
| CI/CD pipelines | CLI with `--format json` |
| Interactive debugging | CLI |
| Automated analysis via Claude | MCP |

## Workflow Tracking: pmat work and pmat roadmap

PMAT includes a unified workflow system for tracking development work. This integrates with both GitHub Issues and local YAML-based roadmaps.

### Quick Start with pmat work

```bash
# Initialize workflow in your project
pmat work init

# Start working on a task (GitHub issue or roadmap ticket)
pmat work start 42           # GitHub issue #42
pmat work start PERF-001     # Roadmap ticket PERF-001

# Check current work status
pmat work status

# Complete the work
pmat work complete
```

### Understanding roadmap.yaml

The `roadmap.yaml` file is your project's source of truth for planned work:

```yaml
# roadmap.yaml
meta:
  project: My Project
  approach: Extreme TDD
  quality_gates:
    min_coverage: 0.85
    max_complexity: 10

active_sprints:
  - id: sprint-1
    name: "Initial Setup"
    tickets:
      - id: SETUP-001
        title: "Configure CI/CD"
        status: in_progress
        priority: high

      - id: SETUP-002
        title: "Add test infrastructure"
        status: planned
        priority: medium
```

### Best Practices for pmat work

#### 1. Always Initialize First

```bash
# In your project root
pmat work init

# This creates:
# - roadmap.yaml (if not exists)
# - .pmat/ directory for state
# - Git hooks for workflow tracking
```

#### 2. Use Consistent Ticket IDs

```yaml
# Good - Clear category prefixes
tickets:
  - id: PERF-001    # Performance work
  - id: BUG-042     # Bug fixes
  - id: FEAT-007    # New features
  - id: DOC-003     # Documentation

# Bad - Unclear IDs
tickets:
  - id: 1
  - id: task
  - id: todo
```

#### 3. Track Work State Transitions

```bash
# Start work (moves to in_progress)
pmat work start PERF-001

# Check what you're working on
pmat work status

# Complete work (moves to done)
pmat work complete

# The workflow enforces:
# planned → in_progress → done
```

#### 4. Sync with GitHub

```bash
# Create GitHub issue from roadmap ticket
pmat work start PERF-001 --create-github

# Sync status between GitHub and roadmap
pmat work sync
```

#### 5. Validate Before Commits

```bash
# Check roadmap.yaml syntax
pmat work validate

# Auto-fix common issues
pmat work migrate
```

### Integration with Quality Gates

```yaml
# roadmap.yaml quality gates are enforced
meta:
  quality_gates:
    max_complexity: 10
    min_coverage: 0.85

# When you run pmat work complete, it checks:
# 1. All tests pass
# 2. Coverage meets threshold
# 3. No new complexity violations
```

## Finding Command Documentation

PMAT has extensive CLI documentation. Here's how to navigate it:

### Built-in Help

```bash
# Top-level help
pmat --help

# Command-specific help
pmat analyze --help
pmat work --help
pmat tdg --help

# Subcommand help
pmat analyze complexity --help
pmat work start --help
```

### Command Discovery

```bash
# List all available commands
pmat --help

# Common command groups:
# - analyze    Code analysis (complexity, satd, dead-code)
# - tdg        Technical Debt Gradient scoring
# - context    Generate project context for AI
# - work       Workflow tracking
# - roadmap    Roadmap management (alias for work)
# - quality-gate  CI/CD quality enforcement
```

### MCP Tool Discovery

When using PMAT via MCP, tools are auto-discovered:

```bash
# List MCP tools (for debugging)
pmat mcp-server --list-tools

# Available MCP tools match CLI commands:
# - analyze_complexity
# - analyze_satd
# - analyze_dead_code
# - tdg_analyze
# - context_generate
# - quality_gate_check
# - work_start
# - work_status
# - work_complete
```

### Documentation Resources

| Resource | Location | Best For |
|----------|----------|----------|
| CLI Help | `pmat --help` | Quick reference |
| This Book | https://paiml.github.io/pmat-book | Comprehensive guides |
| Appendix B | [Command Reference](appendix-b-commands.md) | Full command listing |
| GitHub | https://github.com/paiml/paiml-mcp-agent-toolkit | Source, issues, discussions |
| Chapter 3 | [MCP Protocol](ch03-00-mcp-protocol.md) | MCP-specific setup |

### Quick Reference Card

```bash
# Analysis Commands
pmat analyze complexity .          # Cyclomatic complexity
pmat analyze satd .                # Self-Admitted Technical Debt
pmat analyze dead-code .           # Unused code detection
pmat analyze churn .               # Git churn analysis

# Scoring Commands
pmat tdg .                         # Technical Debt Gradient
pmat perfection-score              # 200-point quality score
pmat repo-score                    # Repository health score
pmat rust-project-score            # Rust-specific scoring

# Context Commands
pmat context                       # Full project context
pmat context --format markdown     # AI-optimized format

# Workflow Commands
pmat work init                     # Initialize workflow
pmat work start <ID>               # Start working on ticket
pmat work status                   # Show current work
pmat work complete                 # Complete current work
pmat work validate                 # Validate roadmap.yaml

# Quality Commands
pmat quality-gate                  # Run quality checks
pmat quality-gate --strict         # Fail on any issue
```

## Next Steps

- [First Analysis](ch01-02-first-analysis-tdd.md) - Run your first code analysis
- [MCP Protocol](ch03-00-mcp-protocol.md) - Deep dive into MCP integration
- [TDG Scoring](ch04-01-tdg.md) - Understanding Technical Debt Gradient
- [Command Reference](appendix-b-commands.md) - Complete command listing
