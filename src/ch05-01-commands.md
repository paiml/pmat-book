# Chapter 5.1: Complete Command Reference

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (All commands documented)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 50+ | All CLI commands documented |
| ⚠️ Not Implemented | 0 | Planned for future versions |
| ❌ Broken | 0 | Known issues, needs fixing |
| 📋 Planned | 0 | Future roadmap features |

*Last updated: 2025-09-08*  
*PMAT version: pmat 2.64.0*
<!-- DOC_STATUS_END -->

## Core CLI Commands

### Getting Started

```bash
# Display version information
pmat --version
pmat -V

# Show help for any command
pmat --help
pmat help
pmat help <command>
pmat <command> --help

# Initialize a new PMAT project
pmat init
pmat init --template=enterprise
pmat init --interactive

# Check PMAT status and project info
pmat status
pmat status --detailed
pmat info --system
```

### Basic Analysis Commands

```bash
# Standard analysis
pmat analyze .
pmat analyze src/
pmat analyze --format=json
pmat analyze --output=report.json

# Quick scan (faster, less detailed)
pmat scan .
pmat scan --quick
pmat scan --focus=security

# Watch mode for continuous analysis
pmat watch .
pmat watch --on-change
pmat watch --interval=5s
```

### Configuration Management

```bash
# View configuration
pmat config
pmat config list
pmat config show
pmat config get <key>

# Set configuration values
pmat config set <key> <value>
pmat config set analysis.parallel true
pmat config set quality.min_grade "B+"

# Reset configuration
pmat config reset <key>
pmat config reset --all
pmat config reset --to-defaults

# Configuration profiles
pmat config profiles list
pmat config profiles create <name>
pmat config profiles switch <name>
pmat config profiles delete <name>

# Import/Export configuration
pmat config export > config.toml
pmat config import config.toml
pmat config validate
```

### Cache Management

```bash
# Cache status and info
pmat cache status
pmat cache info
pmat cache size

# Clear cache
pmat cache clear
pmat cache clear --all
pmat cache clear --older-than=7d

# Optimize cache
pmat cache optimize
pmat cache rebuild
pmat cache compact
```

### Quality Analysis

```bash
# Technical Debt Grading
pmat analyze tdg
pmat analyze tdg --detailed
pmat tdg --format=html

# Complexity analysis
pmat analyze complexity
pmat complexity --max-threshold=10
pmat complexity --by-function

# Code similarity detection
pmat similarity
pmat similarity --threshold=0.8
pmat similarity --type=1,2,3

# Dead code detection
pmat analyze dead-code
pmat dead-code --remove-safe
pmat dead-code --export-list

# SATD (Self-Admitted Technical Debt)
pmat analyze satd
pmat satd --categorize
pmat satd --priority=high
```

### Security Commands

```bash
# Security scanning
pmat security scan
pmat security scan --severity=critical
pmat security scan --cve-check

# Dependency analysis
pmat dependencies
pmat dependencies --check-vulnerabilities
pmat dependencies --outdated
pmat dependencies --tree

# Secret detection
pmat security secrets
pmat secrets scan --all-history
pmat secrets scan --pre-commit

# Compliance checking
pmat compliance check
pmat compliance --standard=SOC2
pmat compliance --generate-report

# Security audit
pmat audit
pmat audit --comprehensive
pmat audit --fix-suggestions
```

### Reporting and Export

```bash
# Generate reports
pmat report
pmat report --format=html
pmat report --format=pdf
pmat report --format=markdown

# Executive reports
pmat report executive
pmat report executive --period=monthly
pmat report executive --audience=technical

# Component reports
pmat report component <name>
pmat report team <team-name>

# Export data
pmat export --format=json
pmat export --format=csv
pmat export --format=sarif

# Import data
pmat import results.json
pmat import --merge

# Compare and diff
pmat compare <baseline> <current>
pmat diff --from=main --to=feature
pmat diff --commits=HEAD~10..HEAD

# Merge reports
pmat merge report1.json report2.json
pmat merge *.json --output=combined.json
```

### Performance Commands

```bash
# Performance analysis
pmat performance analyze
pmat performance benchmark
pmat performance profile

# Hotspot detection
pmat performance hotspots
pmat performance hotspots --top=10

# Memory analysis
pmat performance memory
pmat performance memory --leak-detection

# Performance comparison
pmat performance compare --baseline=main
pmat performance regression-check
```

### Architecture Commands

```bash
# Architecture analysis
pmat architecture analyze
pmat architecture validate
pmat architecture graph

# Dependency analysis
pmat architecture deps
pmat architecture deps --circular
pmat architecture deps --matrix

# Pattern detection
pmat architecture patterns
pmat architecture patterns --detect=all

# Layer validation
pmat architecture validate-layers
pmat architecture check-boundaries

# Microservices analysis
pmat architecture microservices
pmat architecture microservices --validate
```

### Team Collaboration

```bash
# Team management
pmat team setup
pmat team list
pmat team add-member <email>
pmat team remove-member <email>

# Code review
pmat review prepare
pmat review checklist
pmat review report

# Dashboard
pmat dashboard generate
pmat dashboard serve
pmat dashboard export

# Knowledge extraction
pmat knowledge extract
pmat retrospective generate

# Workspace management
pmat workspace create <name>
pmat workspace switch <name>
pmat workspace sync
```

### Integration Commands

```bash
# API server
pmat api serve
pmat api serve --port=8080
pmat api serve --auth-token=<token>

# Webhook management
pmat webhook create
pmat webhook list
pmat webhook test <webhook-id>
pmat webhook delete <webhook-id>

# Notifications
pmat notify email
pmat notify slack
pmat notify teams

# Pipeline integration
pmat pipeline validate
pmat pipeline run
pmat pipeline status
```

### Plugin Management

```bash
# Plugin commands
pmat plugin list
pmat plugin search <term>
pmat plugin install <name>
pmat plugin uninstall <name>
pmat plugin update <name>
pmat plugin update --all

# Plugin development
pmat plugin create <name>
pmat plugin build
pmat plugin test
pmat plugin publish
```

### AI-Powered Commands

```bash
# AI analysis
pmat ai analyze
pmat ai suggest
pmat ai explain <violation-id>

# AI refactoring
pmat ai refactor <file>
pmat ai refactor --preview
pmat ai refactor --apply

# AI code review
pmat ai review
pmat ai review-pr --number=<pr>

# Natural language
pmat ai explain-report
pmat ai executive-summary
```

### Utility Commands

```bash
# Diagnostics
pmat doctor
pmat doctor --fix
pmat doctor --verbose

# Debugging
pmat debug
pmat debug --trace
pmat debug --profile

# Benchmarking
pmat benchmark
pmat benchmark --iterations=100
pmat benchmark --compare

# System info
pmat info
pmat info --dependencies
pmat info --environment

# Validation
pmat validate
pmat validate --strict
pmat check --all

# Testing
pmat test
pmat test --coverage
pmat lint
```

### Advanced Options

```bash
# Incremental analysis
pmat analyze --incremental
pmat analyze --since=main
pmat analyze --changed-only

# Parallel processing
pmat analyze --parallel
pmat analyze --threads=8
pmat analyze --distributed

# Memory management
pmat analyze --streaming
pmat analyze --low-memory
pmat analyze --max-memory=4g

# Output control
pmat analyze --quiet
pmat analyze --verbose
pmat analyze --debug
pmat analyze --no-color

# Filtering
pmat analyze --include="src/**"
pmat analyze --exclude="tests/**"
pmat analyze --language=python,javascript

# Dry run mode
pmat <command> --dry-run
pmat <command> --preview
pmat <command> --simulate
```

### Global Options

These options work with all commands:

```bash
# Configuration
--config <path>         # Use specific config file
--profile <name>        # Use configuration profile
--no-config            # Ignore config files

# Output
--format <type>        # Output format (json, xml, html, etc.)
--output <path>        # Output file path
--quiet               # Suppress output
--verbose             # Verbose output
--debug              # Debug output
--no-color           # Disable colored output

# Execution
--dry-run            # Preview without making changes
--force              # Force operation (skip confirmations)
--yes                # Auto-confirm prompts
--parallel           # Enable parallel processing
--timeout <seconds>  # Command timeout

# Help
--help               # Show help
--version            # Show version
```

### Environment Variables

```bash
# Configuration
export PMAT_CONFIG_PATH=/path/to/config.toml
export PMAT_PROFILE=production

# Performance
export PMAT_MAX_THREADS=16
export PMAT_MEMORY_LIMIT=8G
export PMAT_CACHE_DIR=/tmp/pmat-cache

# API and Integration
export PMAT_API_TOKEN=your-token-here
export ANTHROPIC_API_KEY=your-key
export PMAT_WEBHOOK_SECRET=secret

# Debugging
export PMAT_DEBUG=1
export PMAT_LOG_LEVEL=debug
export PMAT_TRACE=1
```

## Command Pipelines

### Common Workflows

```bash
# Full project analysis with report
pmat analyze . --comprehensive | \
  pmat report --format=html > report.html

# Incremental analysis in CI/CD
pmat analyze --incremental --since=main | \
  pmat quality-gate --min-grade=B+ || exit 1

# Security scan with notifications
pmat security scan --severity=critical | \
  pmat notify slack --channel=#security

# Performance regression check
pmat performance benchmark | \
  pmat performance compare --baseline=main | \
  pmat notify email --if-regression

# Architecture validation pipeline
pmat architecture analyze | \
  pmat architecture validate-layers | \
  pmat report --format=pdf
```

### Batch Operations

```bash
# Analyze multiple components
for component in frontend backend mobile; do
  pmat analyze $component/ --component-mode
done

# Generate reports for all teams
pmat team list | while read team; do
  pmat report team $team --output=$team-report.pdf
done

# Check all configuration profiles
for profile in dev staging prod; do
  pmat config profiles switch $profile
  pmat validate --strict
done
```

## Command Aliases

Create useful aliases in your shell:

```bash
# ~/.bashrc or ~/.zshrc
alias pa='pmat analyze'
alias pq='pmat quality-gate'
alias ps='pmat status'
alias pc='pmat config'
alias pr='pmat report'

# Quick quality check
alias pcheck='pmat analyze . --quick && pmat quality-gate'

# Full analysis with report
alias pfull='pmat analyze . --comprehensive && pmat report --format=html'

# Security scan
alias psec='pmat security scan --severity=high'
```

## Next Steps

- [Chapter 5.2: Configuration in Depth](ch05-02-config.md)
- [Chapter 5.3: Advanced Workflows](ch05-03-workflows.md)
- [Appendix B: Quick Command Reference](appendix-b-commands.md)