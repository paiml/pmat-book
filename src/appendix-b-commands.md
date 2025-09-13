# Appendix B: Quick Command Reference

## Essential Commands

| Command | Description | Example |
|---------|-------------|---------|
| `pmat --version` | Display version | `pmat --version` |
| `pmat help` | Show help | `pmat help analyze` |
| `pmat init` | Initialize project | `pmat init --template=enterprise` |
| `pmat status` | Check project status | `pmat status --detailed` |

## Analysis Commands

| Command | Description | Example |
|---------|-------------|---------|
| `pmat analyze` | Run standard analysis | `pmat analyze .` |
| `pmat scan` | Quick scan | `pmat scan --focus=security` |
| `pmat watch` | Continuous monitoring | `pmat watch --on-change` |
| `pmat analyze tdg` | Technical debt grading | `pmat analyze tdg --detailed` |
| `pmat complexity` | Complexity analysis | `pmat complexity --by-function` |
| `pmat similarity` | Code similarity | `pmat similarity --threshold=0.8` |
| `pmat dead-code` | Dead code detection | `pmat dead-code --export-list` |
| `pmat satd` | SATD detection | `pmat satd --priority=high` |

## Configuration

| Command | Description | Example |
|---------|-------------|---------|
| `pmat config list` | List configuration | `pmat config list` |
| `pmat config get` | Get config value | `pmat config get quality.min_grade` |
| `pmat config set` | Set config value | `pmat config set analysis.parallel true` |
| `pmat config reset` | Reset to defaults | `pmat config reset --all` |
| `pmat config profiles` | Manage profiles | `pmat config profiles switch prod` |
| `pmat config export` | Export config | `pmat config export > config.toml` |
| `pmat config import` | Import config | `pmat config import config.toml` |

## Cache Management

| Command | Description | Example |
|---------|-------------|---------|
| `pmat cache status` | Cache status | `pmat cache status` |
| `pmat cache clear` | Clear cache | `pmat cache clear --all` |
| `pmat cache optimize` | Optimize cache | `pmat cache optimize` |

## Security

| Command | Description | Example |
|---------|-------------|---------|
| `pmat security scan` | Security scan | `pmat security scan --severity=critical` |
| `pmat dependencies` | Dependency check | `pmat dependencies --check-vulnerabilities` |

## API Server & Roadmap

| Command | Description | Example |
|---------|-------------|---------|
| `pmat serve` | Start API server | `pmat serve --port 8080` |
| `pmat serve --metrics` | Server with metrics | `pmat serve --metrics --verbose` |
| `pmat roadmap init` | Initialize sprint | `pmat roadmap init --sprint v1.0` |
| `pmat roadmap todos` | Generate todos | `pmat roadmap todos --format markdown` |
| `pmat roadmap start` | Start task | `pmat roadmap start PMAT-001` |
| `pmat roadmap complete` | Complete task | `pmat roadmap complete PMAT-001 --quality-check` |
| `pmat roadmap status` | Sprint status | `pmat roadmap status --format json` |
| `pmat roadmap validate` | Validate release | `pmat roadmap validate` |
| `pmat roadmap quality-check` | Quality validation | `pmat roadmap quality-check PMAT-001` |

## Agent Management

| Command | Description | Example |
|---------|-------------|---------|
| `pmat agent start` | Start background agent | `pmat agent start --project-path .` |
| `pmat agent stop` | Stop agent daemon | `pmat agent stop` |
| `pmat agent status` | Show agent status | `pmat agent status --verbose` |
| `pmat agent health` | Health check | `pmat agent health` |
| `pmat agent monitor` | Monitor project | `pmat agent monitor --project-id main` |
| `pmat agent unmonitor` | Stop monitoring | `pmat agent unmonitor --project-id main` |
| `pmat agent reload` | Reload configuration | `pmat agent reload` |
| `pmat agent quality-gate` | Quality gate via agent | `pmat agent quality-gate --strict` |
| `pmat agent mcp-server` | Start MCP server | `pmat agent mcp-server --debug` |

## AI-Powered Refactoring

| Command | Description | Example |
|---------|-------------|---------|
| `pmat refactor auto` | Automated refactoring | `pmat refactor auto --quality-profile extreme` |
| `pmat refactor interactive` | Interactive refactoring | `pmat refactor interactive --target-complexity 8` |
| `pmat refactor serve` | Batch processing server | `pmat refactor serve --port 8080` |
| `pmat refactor status` | Refactoring status | `pmat refactor status` |
| `pmat refactor resume` | Resume from checkpoint | `pmat refactor resume --checkpoint state.json` |
| `pmat refactor docs` | Documentation cleanup | `pmat refactor docs --dry-run` |
| `pmat secrets` | Secret detection | `pmat secrets scan --all-history` |
| `pmat compliance` | Compliance check | `pmat compliance --standard=SOC2` |
| `pmat audit` | Security audit | `pmat audit --comprehensive` |

## Reporting

| Command | Description | Example |
|---------|-------------|---------|
| `pmat report` | Generate report | `pmat report --format=html` |
| `pmat report executive` | Executive summary | `pmat report executive --period=monthly` |
| `pmat export` | Export data | `pmat export --format=json` |
| `pmat import` | Import data | `pmat import results.json` |
| `pmat compare` | Compare analyses | `pmat compare baseline.json current.json` |
| `pmat diff` | Show differences | `pmat diff --from=main --to=feature` |
| `pmat merge` | Merge reports | `pmat merge *.json --output=combined.json` |

## Performance

| Command | Description | Example |
|---------|-------------|---------|
| `pmat performance analyze` | Performance analysis | `pmat performance analyze` |
| `pmat performance hotspots` | Find hotspots | `pmat performance hotspots --top=10` |
| `pmat performance memory` | Memory analysis | `pmat performance memory --leak-detection` |
| `pmat performance compare` | Compare performance | `pmat performance compare --baseline=main` |

## Architecture

| Command | Description | Example |
|---------|-------------|---------|
| `pmat architecture analyze` | Architecture analysis | `pmat architecture analyze` |
| `pmat architecture deps` | Dependency analysis | `pmat architecture deps --circular` |
| `pmat architecture patterns` | Pattern detection | `pmat architecture patterns --detect=all` |
| `pmat architecture validate-layers` | Layer validation | `pmat architecture validate-layers` |
| `pmat architecture graph` | Generate graph | `pmat architecture graph --output=deps.svg` |

## Quality Gates

| Command | Description | Example |
|---------|-------------|---------|
| `pmat quality-gate` | Check quality gates | `pmat quality-gate --min-grade=B+` |
| `pmat validate` | Validate project | `pmat validate --strict` |
| `pmat check` | Run all checks | `pmat check --all` |

## Team Collaboration

| Command | Description | Example |
|---------|-------------|---------|
| `pmat team setup` | Setup team | `pmat team setup` |
| `pmat review prepare` | Prepare review | `pmat review prepare --pr-number=123` |
| `pmat dashboard serve` | Start dashboard | `pmat dashboard serve --port=8080` |
| `pmat retrospective` | Generate retrospective | `pmat retrospective generate` |

## Integration

| Command | Description | Example |
|---------|-------------|---------|
| `pmat serve` | Start HTTP API server | `pmat serve --port=8080 --cors` |
| `pmat webhook` | Manage webhooks | `pmat webhook create` |
| `pmat notify` | Send notifications | `pmat notify slack --channel=#alerts` |
| `pmat pipeline` | Pipeline integration | `pmat pipeline validate` |

## Plugins

| Command | Description | Example |
|---------|-------------|---------|
| `pmat plugin list` | List plugins | `pmat plugin list` |
| `pmat plugin install` | Install plugin | `pmat plugin install swift-analyzer` |
| `pmat plugin update` | Update plugins | `pmat plugin update --all` |

## AI Features

| Command | Description | Example |
|---------|-------------|---------|
| `pmat ai analyze` | AI analysis | `pmat ai analyze --explain-violations` |
| `pmat ai suggest` | Get suggestions | `pmat ai suggest-improvements` |
| `pmat ai refactor` | AI refactoring | `pmat ai refactor --preview` |
| `pmat ai review` | AI code review | `pmat ai review-pr --number=123` |

## Utilities

| Command | Description | Example |
|---------|-------------|---------|
| `pmat doctor` | Diagnostics | `pmat doctor --fix` |
| `pmat debug` | Debug mode | `pmat debug --trace` |
| `pmat benchmark` | Benchmarking | `pmat benchmark --iterations=100` |
| `pmat info` | System info | `pmat info --environment` |

## Custom Rules

| Command | Description | Example |
|---------|-------------|---------|
| `pmat rules init` | Initialize rules | `pmat rules init` |
| `pmat rules create` | Create rule | `pmat rules create --name=no-console-log` |
| `pmat rules test` | Test rules | `pmat rules test --all` |
| `pmat rules validate` | Validate rules | `pmat rules validate` |

## Auto-clippy

| Command | Description | Example |
|---------|-------------|---------|
| `pmat clippy enable` | Enable clippy | `pmat clippy enable` |
| `pmat clippy run` | Run clippy | `pmat clippy run --format=json` |
| `pmat clippy fix` | Auto-fix issues | `pmat clippy fix --safe` |

## Hooks

| Command | Description | Example |
|---------|-------------|---------|
| `pmat hooks install` | Install hooks | `pmat hooks install --pre-commit` |
| `pmat hooks run` | Run hooks | `pmat hooks run pre-commit` |
| `pmat hooks configure` | Configure hooks | `pmat hooks configure` |

## Global Options

| Option | Description | Example |
|--------|-------------|---------|
| `--config <path>` | Use specific config | `--config custom.toml` |
| `--profile <name>` | Use profile | `--profile production` |
| `--format <type>` | Output format | `--format json` |
| `--output <path>` | Output file | `--output report.html` |
| `--quiet` | Suppress output | `--quiet` |
| `--verbose` | Verbose output | `--verbose` |
| `--debug` | Debug output | `--debug` |
| `--dry-run` | Preview only | `--dry-run` |
| `--parallel` | Parallel processing | `--parallel` |
| `--help` | Show help | `--help` |

## Common Workflows

### Quick Quality Check
```bash
pmat analyze . --quick && pmat quality-gate --min-grade=B+
```

### Full Analysis with Report
```bash
pmat analyze . --comprehensive && pmat report --format=html
```

### Security Scan
```bash
pmat security scan --severity=high && pmat notify slack
```

### Incremental CI/CD Analysis
```bash
pmat analyze --incremental --since=main | pmat quality-gate
```

### Team Dashboard
```bash
pmat dashboard generate --team=backend && pmat dashboard serve
```

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `PMAT_CONFIG_PATH` | Config file path | `/opt/pmat/config.toml` |
| `PMAT_PROFILE` | Active profile | `production` |
| `PMAT_MAX_THREADS` | Thread limit | `16` |
| `PMAT_MEMORY_LIMIT` | Memory limit | `8G` |
| `PMAT_CACHE_DIR` | Cache directory | `/tmp/pmat-cache` |
| `PMAT_API_TOKEN` | API token | `your-token` |
| `PMAT_DEBUG` | Debug mode | `1` |
| `PMAT_LOG_LEVEL` | Log level | `debug` |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Configuration error |
| 3 | Analysis failure |
| 4 | Quality gate failure |
| 5 | Security violation |
| 10 | Invalid arguments |
| 11 | Missing dependencies |
| 12 | Network error |
| 20 | License error |

## Tips and Tricks

### Create Aliases
```bash
alias pa='pmat analyze'
alias pq='pmat quality-gate'
alias ps='pmat status'
```

### Batch Analysis
```bash
find . -type d -name "src" | xargs -I {} pmat analyze {}
```

### JSON Processing
```bash
pmat analyze . --format=json | jq '.violations[] | select(.severity=="error")'
```

### Continuous Monitoring
```bash
watch -n 60 'pmat status --detailed'
```

### Pipeline Integration
```bash
pmat analyze . || exit $?
```

## Getting Help

- `pmat help` - General help
- `pmat help <command>` - Command-specific help
- `pmat <command> --help` - Alternative help syntax
- `pmat doctor` - Diagnose issues
- `pmat info` - System information

## See Also

- [Chapter 5.1: Complete Command Reference](ch05-01-commands.md)
- [Chapter 5.2: Configuration](ch05-02-config.md)
- [Chapter 5.3: Workflows](ch05-03-workflows.md)