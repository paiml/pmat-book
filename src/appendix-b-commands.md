# Appendix B: Quick Command Reference

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ Every example on this page parses with pmat 3.42.0

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 133 | Every pmat example below is accepted by pmat 3.42.0's argument parser (`<example> --help` exits 0); `tests/appendix-b/test_commands_parse.sh` checks every one |
| ⚠️ Not Implemented | 0 | `pmat agent` and `pmat org` exist but need a feature build; they are marked where they appear |
| ❌ Broken | 0 | |
| 📋 Planned | 0 | |

*Not measured: what each command prints on your project. The check above proves the command and its flags exist, not the output.*

*Last updated: 2026-10-06*
*PMAT version: pmat 3.42.0*
<!-- DOC_STATUS_END -->

This page lists commands pmat 3.42.0 actually has. Earlier editions listed
about 30 top-level commands that never existed (`pmat status`, `pmat scan`,
`pmat dashboard`, `pmat team`, `pmat webhook`, `pmat plugin`, and others) and
dropped the `analyze` prefix from real analyses. If a command you remember is
not here, `pmat --help` is the authority: it lists every top-level command,
and `pmat <command> --help` lists its subcommands and flags.

## Essential Commands

| Command | Description | Example |
|---------|-------------|---------|
| `pmat --version` | Display version | `pmat --version` |
| `pmat help` | Show help | `pmat help analyze` |
| `pmat init` | Bootstrap an agent-ready workspace (quality hook, MCP registration) | `pmat init --path .` |
| `pmat diagnose` | Self-diagnostics: check that pmat's features work here | `pmat diagnose --format json` |
| `pmat explain` | Explain what a check, metric or grade means | `pmat explain tdg` |

## Analysis

Every analysis is a subcommand of `pmat analyze`. `pmat analyze --help`
lists all of them.

| Command | Description | Example |
|---------|-------------|---------|
| `pmat analyze complexity` | Cyclomatic and cognitive complexity | `pmat analyze complexity --path .` |
| `pmat analyze satd` | Self-admitted technical debt markers | `pmat analyze satd --path .` |
| `pmat analyze dead-code` | Dead code detection | `pmat analyze dead-code --path .` |
| `pmat analyze churn` | Git churn | `pmat analyze churn --path .` |
| `pmat analyze duplicates` | Code clones | `pmat analyze duplicates --path .` |
| `pmat analyze dag` | Dependency graph | `pmat analyze dag --path .` |
| `pmat analyze deep-context` | Combined deep analysis | `pmat analyze deep-context --path .` |
| `pmat analyze clippy` | Clippy findings | `pmat analyze clippy --path .` |
| `pmat analyze big-o` | Algorithmic complexity estimates | `pmat analyze big-o --path .` |
| `pmat analyze entropy` | Pattern diversity | `pmat analyze entropy --path .` |
| `pmat tdg` | Technical Debt Grading | `pmat tdg . --format json` |
| `pmat extract` | Function boundaries from one file (tree-sitter) | `pmat extract --list src/main.rs` |
| `pmat split` | Suggest semantic file splits | `pmat split --help` |
| `pmat kaizen` | Continuous improvement: scan, fix, commit | `pmat kaizen --dry-run` |

## Code Search and Context

| Command | Description | Example |
|---------|-------------|---------|
| `pmat query` | Semantic code search with quality annotations | `pmat query "error handling" --min-grade B --limit 10` |
| `pmat query --docs-only` | Search only documents (PDF, SVG, markdown) | `pmat query "design spec" --docs-only --limit 5` |
| `pmat query --no-docs` | Code-only search | `pmat query "parse" --no-docs --limit 10` |
| `pmat context` | Project context for an LLM | `pmat context --format llm-optimized` |
| `pmat embed` | Manage search embeddings | `pmat embed status` |
| `pmat sql` | Direct SQL over the function index | `pmat sql --help` |

## Quality Gates and Scores

| Command | Description | Example |
|---------|-------------|---------|
| `pmat quality-gate` | Run quality gate checks | `pmat quality-gate --fail-on-violation` |
| `pmat quality-gates` | Configurable gates for the current project | `pmat quality-gates --help` |
| `pmat verify` | Run the CI-faithful gate set before committing | `pmat verify --format json` |
| `pmat score` | Unified quality score (0-100) | `pmat score --path .` |
| `pmat repo-score` | Repository health score (0-100) | `pmat repo-score --path .` |
| `pmat rust-project-score` | Rust project quality score | `pmat rust-project-score --full` |
| `pmat popper-score` | Falsifiability score | `pmat popper-score --verbose` |
| `pmat perfection-score` | 200-point perfection score | `pmat perfection-score --fast --breakdown` |
| `pmat comply check` | Compliance checks | `pmat comply check` |
| `pmat report` | Analysis report | `pmat report --output-format json --output report.json` |

## Configuration

`pmat config` takes flags, not subcommands.

| Command | Description | Example |
|---------|-------------|---------|
| `pmat config --show` | Show the configuration | `pmat config --show` |
| `pmat config --validate` | Validate the configuration | `pmat config --validate` |
| `pmat config --reset` | Reset to defaults | `pmat config --reset` |

## Memory and Cache

| Command | Description | Example |
|---------|-------------|---------|
| `pmat memory stats` | Memory usage | `pmat memory stats --verbose` |
| `pmat memory cleanup` | Release memory | `pmat memory cleanup` |
| `pmat memory pools` | Memory pool status | `pmat memory pools` |
| `pmat memory pressure` | Memory pressure | `pmat memory pressure` |
| `pmat cache stats` | Cache statistics; the only `cache` subcommand | `pmat cache stats --verbose` |

## MCP and the HTTP Server

| Command | Description | Example |
|---------|-------------|---------|
| `pmat --mode mcp` | MCP server over stdio | `pmat --mode mcp` |
| `pmat serve` | MCP over streamable HTTP at `/`, not a REST API (see Chapter 18) | `pmat serve --port 8080` |
| `pmat mcp connect` | Print how to register pmat with an MCP client | `pmat mcp connect` |
| `pmat mcp token` | Generate a bearer token for `pmat serve` | `pmat mcp token` |

## Work Tracking, Roadmap and Specs

| Command | Description | Example |
|---------|-------------|---------|
| `pmat work list` | List work items | `pmat work list` |
| `pmat work start` | Start a work item | `pmat work start PMAT-001` |
| `pmat work complete` | Complete a work item | `pmat work complete PMAT-001` |
| `pmat roadmap status` | Roadmap status (reads `docs/execution/roadmap.md`) | `pmat roadmap status --format json` |
| `pmat spec score` | Score a specification | `pmat spec score docs/spec.md --verbose` |
| `pmat spec list` | List specifications | `pmat spec list` |
| `pmat five-whys` | Five Whys root-cause analysis | `pmat five-whys --help` |

## Prompts and Templates

| Command | Description | Example |
|---------|-------------|---------|
| `pmat prompt show` | Show a built-in prompt | `pmat prompt show --list` |
| `pmat prompt generate` | Generate a defect-aware prompt | `pmat prompt generate --task "Add auth"` |
| `pmat list` | List templates | `pmat list --format json` |
| `pmat search` | Search templates | `pmat search "web" --limit 10` |
| `pmat generate` | Generate one template | `pmat generate rust cli -p name=app` |
| `pmat scaffold` | Scaffold a project or agent | `pmat scaffold list-templates` |

## Refactoring

| Command | Description | Example |
|---------|-------------|---------|
| `pmat refactor auto` | Automated refactoring | `pmat refactor auto --quality-profile extreme` |
| `pmat refactor interactive` | Interactive refactoring | `pmat refactor interactive --target-complexity 8` |
| `pmat refactor docs` | Documentation cleanup | `pmat refactor docs --dry-run` |

## Hooks

| Command | Description | Example |
|---------|-------------|---------|
| `pmat hooks install` | Install the pre-commit hook | `pmat hooks install` |
| `pmat hooks status` | Hook status | `pmat hooks status` |
| `pmat hooks run` | Run the hooks now | `pmat hooks run` |

## Performance Testing

| Command | Description | Example |
|---------|-------------|---------|
| `pmat test` | Performance tests | `pmat test performance --verbose` |
| `pmat test` with a timeout | All suites | `pmat test all --timeout 300` |

## Feature Builds Only

These exist in `pmat --help` but are compiled only with a cargo feature. On a
default `cargo install pmat` they exit 1 and name the feature to build with.

| Command | Feature | Example |
|---------|---------|---------|
| `pmat agent` | `agent-daemon` (see Chapter 19) | `pmat agent status` |
| `pmat org` | see `pmat org --help` | `pmat org analyze --summarize` |
| `pmat demo` | see `pmat demo --help` | `pmat demo --help` |

## Global Options

These apply to every command.

| Option | Description | Example |
|--------|-------------|---------|
| `--mode <cli\|mcp>` | Force CLI or MCP mode | `pmat --mode mcp` |
| `-v`, `--verbose` | Info-level output | `pmat diagnose --verbose` |
| `-q`, `--quiet` | Errors only | `pmat quality-gate --quiet` |
| `--debug` | Debug-level output | `pmat diagnose --debug` |
| `--trace` | Trace-level output | `pmat diagnose --trace` |
| `--color <auto\|always\|never>` | Colour output | `pmat quality-gate --color never` |
| `-h`, `--help` | Help | `pmat analyze --help` |
| `-V`, `--version` | Version | `pmat --version` |

Output format, output file and dry-run are per-command flags, not global
ones: check `pmat <command> --help`.

## Common Workflows

### Quick Quality Check
```bash
pmat analyze complexity --path . && pmat quality-gate --fail-on-violation
```

### Technical Debt Grade
```bash
pmat tdg . --format json
```

### Report to a File
```bash
pmat report --output-format json --output report.json
```

### Pre-commit Verification
```bash
pmat verify --format json
```

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `RUST_LOG` | Log filter; `--trace-filter` overrides it | `paiml=debug` |
| `PMAT_MCP_HTTP_TOKEN` | Bearer token for `pmat serve` (16 characters minimum); required for a non-loopback `--host` | `$(pmat mcp token)` |

Earlier editions listed `PMAT_CONFIG_PATH`, `PMAT_PROFILE`,
`PMAT_MAX_THREADS`, `PMAT_MEMORY_LIMIT`, `PMAT_CACHE_DIR`, `PMAT_API_TOKEN`,
`PMAT_DEBUG` and `PMAT_LOG_LEVEL`. pmat reads none of them.

## Exit Codes

pmat has no global exit-code table. What was measured with pmat 3.42.0:

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | The command ran and failed, for example a feature-gated command on a default build |
| 2 | Argument error: an unknown command or flag (from the argument parser) |
| 4 | `pmat serve --host 0.0.0.0` (any non-loopback address) with `PMAT_MCP_HTTP_TOKEN` unset |

Individual commands document their own failure codes in `--help`.

## Tips and Tricks

### Create Aliases
```bash
alias pa='pmat analyze'
alias pq='pmat quality-gate'
alias pt='pmat tdg .'
```

### Batch Analysis
```bash
find . -type d -name "src" | xargs -I {} pmat analyze complexity --path {}
```

### JSON Processing
```bash
pmat tdg . --format json | jq .
```

### Pipeline Integration
```bash
pmat quality-gate --fail-on-violation || exit $?
```

## Running Examples

PMAT includes extensive runnable examples demonstrating various features. All examples are located in the `examples/` directory and can be run using Cargo.

### Running Examples

```bash
# From the paiml-mcp-agent-toolkit directory
cargo run --example <example_name>
```

### Key Examples by Category

| Category | Example | Description |
|----------|---------|-------------|
| **Quality Analysis** | `quality_gate` | Comprehensive quality gate demonstration |
| | `analyze_complexity` | Complexity analysis with CI/CD integration |
| | `analyze_dead_code` | Dead code detection with thresholds |
| | `analyze_satd` | Self-Admitted Technical Debt detection |
| | `quality_proxy_demo` | Quality Proxy for AI-generated code |
| | `perfection_score_demo` | Unified 200-point perfection score |
| | `work_commands_demo` | Work management commands |
| **MCP Integration** | `mcp_server_pmcp` | MCP server using pmcp SDK |
| | `unified_mcp_demo` | Unified MCP server architecture |
| | `pmcp_analyze_workflow` | MCP analyze workflow |
| **Mutation Testing** | `rust_mutation_workflow` | Rust mutation testing |
| | `typescript_mutation_workflow` | TypeScript mutation testing |
| | `python_mutation_workflow` | Python mutation testing |
| | `cargo_mutants_detect` | Cargo mutants integration |
| **CI/CD** | `ci_integration` | Multi-platform CI/CD examples |
| | `exit_codes` | Exit code behavior reference |
| **Agent Scaffolding** | `scaffold_agent_basics` | Basic MCP agent setup |
| | `scaffold_agent_hybrid` | Hybrid agent patterns |
| | `scaffold_agent_interactive` | Interactive agents |
| **GitHub Integration** | `analyze_github_repo` | Analyze GitHub repositories |
| | `check_github_repo` | GitHub repository checks |
| | `organizational_intelligence_integration` | Org-wide analysis |
| **Semantic Search** | `semantic_search_demo` | Code semantic search |
| | `similarity_demo` | Code similarity detection |
| | `agent_context_query_demo` | RAG-powered agent context |
| **Extraction** | `extract_demo` | Function boundary extraction (tree-sitter) |
| **Debugging** | `recording_capture_demo` | Time-travel debugging |
| | `complexity_demo` | Complexity pattern testing |

### Quick Start Examples

```bash
# Quality gate check
cargo run --example quality_gate

# Perfection score demo (200-point scale)
cargo run --example perfection_score_demo

# Analyze complexity
cargo run --example analyze_complexity

# MCP server demo
cargo run --example mcp_server_pmcp

# GitHub repo analysis
cargo run --example analyze_github_repo

# Function boundary extraction
cargo run --example extract_demo

# Mutation testing workflow
cargo run --example rust_mutation_workflow
```

### Full Example List

Run `ls examples/*.rs` to see all 80+ available examples.

## Getting Help

- `pmat help` - General help
- `pmat help <command>` - Command-specific help
- `pmat <command> --help` - Alternative help syntax
- `pmat diagnose` - Diagnose issues

## See Also

- [Chapter 5.1: Complete Command Reference](ch05-01-commands.md)
- [Chapter 5.2: Configuration](ch05-02-config.md)
- [Chapter 5.3: Workflows](ch05-03-workflows.md)