# Appendix B: Command Reference

> **This appendix is generated from the binary, not written by hand.**
> Every command path below was read out of `pmat 3.32.0`'s own `--help` output and
> then re-checked by running `pmat <path> --help` and requiring exit status 0.
> Nothing in the tables is transcribed from memory. Regenerate it with:
>
> ```bash
> python3 scripts/gen-appendix-b.py > src/appendix-b-commands.md
> ```
>
> **If you bookmarked this page before 2026-08-25, what you read here was wrong.**
> Earlier editions listed 31 top-level commands that `pmat` has never had —
> `pmat architecture`, `pmat rules`, `pmat clippy`, `pmat status`, `pmat scan`,
> `pmat dashboard` and more. Of the 150 command paths that edition printed, 73 did
> not resolve. Every one of them is accounted for in
> [Commands earlier editions listed that do not exist](#commands-earlier-editions-listed-that-do-not-exist),
> with the real replacement where there is one.

`pmat 3.32.0` exposes **70 top-level commands** and **202 subcommands**.

## How to read this appendix

- **Aliases are real.** `pmat a cx` is `pmat analyze complexity`. Anything in the
  Aliases column can be substituted for the command name.
- **`--help` works at every level**, and short-circuits before argument validation:
  `pmat <command> --help` and `pmat <command> <subcommand> --help` always print and
  exit 0 if the path exists. That is exactly the check this appendix is built on.
- **A command with subcommands requires one.** `pmat analyze .` is not "analyze the
  current directory" — it exits 2 with `error: unrecognized subcommand`. The path
  goes to the *subcommand*: `pmat analyze complexity --path .`
- **Path arguments are not uniform, and this is the single most common mistake.**
  Some commands take a positional path, some take `--path`, some take
  `--project-path`, and passing a positional to a command that wants a flag exits 2
  with `error: unexpected argument found`. The tables below name the form for every
  command, so check the column rather than guessing:

  ```bash
  pmat tdg .                              # positional
  pmat analyze complexity --path .        # --path
  pmat quality-gate --project-path .      # --project-path
  ```

- **`[NOT AVAILABLE in the default build]`** in a description is pmat's own wording.
  Those commands parse and appear in `--help`, but the shipped `cargo install pmat`
  binary refuses them at runtime; they need a non-default `--features` build. They are
  marked ⚠ below.

## Top-level commands

| Command | Aliases | Subcommands | What it does |
|---------|---------|-------------|--------------|
| `pmat generate` | `gen`, `g` | — | Generate a single template |
| `pmat scaffold` | `sc` | [11](#pmat-scaffold) | Scaffold complete project or agent |
| `pmat list` | `ls` | — | List available templates |
| `pmat search` | `find`, `s` | — | Search templates |
| `pmat validate` | — | — | Validate template parameters |
| `pmat context` | `ctx`, `ast` | — | Generate project context (AST analysis) |
| `pmat query` | `q`, `search-code` | — | Semantic code search with quality annotations (RAG-powered) |
| `pmat analyze` | `a`, `an` | [35](#pmat-analyze) | Analyze code metrics and patterns |
| `pmat qdd` | `qd` | [3](#pmat-qdd) | Quality-Driven Development (QDD) tool for creating and refactoring code with guaranteed quality |
| `pmat demo` | `d`, `show` | — | ⚠ [NOT AVAILABLE in the default build] Interactive demo — needs --features demo |
| `pmat validate-docs` | `docs`, `doc` | — | Validate documentation links |
| `pmat validate-readme` | `readme`, `hallucination` | — | Validate README/documentation for factual accuracy and hallucinations |
| `pmat red-team` | `rt`, `hallucination-detect` | [1](#pmat-red-team) | Red Team Mode: Automated hallucination detection for commits and code |
| `pmat org` | `organization` | [2](#pmat-org) | ⚠ [NOT AVAILABLE in the default build] Organizational intelligence — needs --features org-intelligence |
| `pmat mcp` | — | [3](#pmat-mcp) | Connect `pmat` to an MCP client: every transport, in one place |
| `pmat agy` | `antigravity` | [1](#pmat-agy) | Google Anti-Gravity customizations translator |
| `pmat init` | `bootstrap` | — | Bootstrap an agent-ready workspace: quality hook, MCP registration, skill and root rules file |
| `pmat prompt` | `p` | [9](#pmat-prompt) | AI prompt generation (defect-aware, ticket-based, spec-based) |
| `pmat quality-gate` | `check`, `c`, `gate` | — | Run quality gate checks on the codebase |
| `pmat report` | `r`, `rep` | — | Generate enhanced analysis reports |
| `pmat score` | — | — | Unified quality score — geometric composite (0-100) |
| `pmat repo-score` | `health` | — | Calculate repository health score (0-100 scale) |
| `pmat rust-project-score` | `rust-score` | — | Calculate Rust project quality score (0-289 scale; the reported total excludes categories that do not apply to the project) |
| `pmat popper-score` | `popper`, `falsifiability` | — | Calculate Popper Falsifiability Score (0-100 scale) |
| `pmat demo-score` | `book-score`, `score-demo` | — | Score demo/book repository quality (0-10 Category G scale) |
| `pmat brick-score` | `brick`, `computebrick` | — | ComputeBrick profiling score (0-100 scale) for trueno/realizar ecosystem |
| `pmat infra-score` | `infra`, `ci-score` | — | Infrastructure Score (0-100 + 12 bonus) for CI/CD quality |
| `pmat deps-audit` | `deps`, `audit-deps` | — | Audit dependencies for Sovereign AI stack migration |
| `pmat serve` | `server`, `api` | — | Serve the MCP tool surface over streamable HTTP (`--transport http`) |
| `pmat diagnose` | `diag`, `doctor` | — | Run self-diagnostics to verify all features are working |
| `pmat verify` | `preflight`, `vfy` | — | Pre-flight verification for autonomous agents: run the CI-faithful gate set (format, complexity, satd, clippy, tests) fail-fast before committing |
| `pmat enforce` | `enf` | [1](#pmat-enforce) | Enforce extreme quality standards using state machine |
| `pmat refactor` | `ref`, `rf` | [6](#pmat-refactor) | Refactor code with real-time analysis or interactive mode |
| `pmat roadmap` | `road`, `rm` | [8](#pmat-roadmap) | Roadmap management with PDMT todos and quality gates |
| `pmat test` | — | — | Performance testing per SPECIFICATION.md Section 30 |
| `pmat memory` | — | [5](#pmat-memory) | Memory management and optimization |
| `pmat cache` | — | [1](#pmat-cache) | Cache strategy management and optimization |
| `pmat telemetry` | — | — | Telemetry and system monitoring |
| `pmat config` | — | — | Configuration management and settings |
| `pmat show-metrics` | `metrics`, `trends` | — | Show quality metrics and trends (Phase 3 O(1) Quality Gates) |
| `pmat predict-quality` | `predict` | — | Predict when quality metrics will exceed thresholds (Phase 4 O(1) Quality Gates) |
| `pmat record-metric` | `record` | — | Record a quality metric observation (Phase 3.4 O(1) Quality Gates - CI/CD) |
| `pmat agent` | `ag` | [9](#pmat-agent) | ⚠ [NOT AVAILABLE in the default build] Claude Code background agent — needs --features agent-daemon |
| `pmat tdg` | `grade`, `debt-grade` | [9](#pmat-tdg) | Grade technical debt and code quality (TDG - Technical Debt Grading) |
| `pmat quality-gates` | `gates`, `qg` | [3](#pmat-quality-gates) | Run configurable quality gates on the current project |
| `pmat maintain` | `maint`, `m` | [4](#pmat-maintain) | Project maintenance commands (cleanup, validation, reports) |
| `pmat hooks` | `hook`, `h` | [8](#pmat-hooks) | Pre-commit hook management and installation |
| `pmat embed` | `emb` | [3](#pmat-embed) | Manage semantic search embeddings for code search |
| `pmat semantic` | `sem`, `find-code` | [2](#pmat-semantic) | Semantic code search using embeddings |
| `pmat debug` | `dbg` | [2](#pmat-debug) | Time-travel debugging commands for execution traces |
| `pmat work` | `w` | [24](#pmat-work) | Unified GitHub/YAML workflow management |
| `pmat falsify` | `falsify-spec` | — | Falsify claims in a work item, spec, or ticket against the codebase |
| `pmat qa-work` | `qa`, `quality` | [7](#pmat-qa-work) | QA validation after work completion with Toyota Way quality gates |
| `pmat five-whys` | `why`, `debug-whys` | — | Five Whys root cause analysis (Toyota Way methodology) This is the ONLY acceptable debugging method per CLAUDE.md policy |
| `pmat oracle` | `fix`, `pdca` | [3](#pmat-oracle) | PMAT Oracle - PDCA loop for automated quality improvement (Toyota Way) Converges ANY Rust project toward perfect quality using CITL signals |
| `pmat perfection-score` | `perfection`, `perfect`, `ps` | — | Unified 200-point Perfection Score (master-plan-`pmat`-work-system.md) Aggregates TDG, Repo Score, Rust Score, Coverage, Mutation, Docs, Performance |
| `pmat explain` | `explain-check`, `what-is` | — | Explain what a check, metric, or grade means |
| `pmat spec` | `specification` | [6](#pmat-spec) | Specification management and validation |
| `pmat ci-local` | `ci`, `local-ci` | — | Run local CI simulation (quality gates, clippy, tests, cross-compilation) |
| `pmat comply` | `compliance` | [19](#pmat-comply) | PMAT compliance checking and migration system (runs check by default) |
| `pmat kaizen` | `improve` | — | Autonomous continuous improvement (Toyota Way Kaizen) Scans, fixes, commits, and files GitHub issues for remaining findings |
| `pmat project-diag` | `pdiag`, `proj-diag` | — | Rust project diagnostics (20 checks across 5 categories) |
| `pmat test-discovery` | `test-fix`, `fix-tests` | [6](#pmat-test-discovery) | Systematic test discovery and fixing |
| `pmat test-stability` | `test-flaky`, `flaky` | — | Detect flaky and timeout-sensitive tests |
| `pmat localize` | `fault`, `fl` | — | Fault localization using Spectrum-Based Fault Localization (SBFL) Identify suspicious code locations based on test coverage data |
| `pmat extract` | `ext` | — | Extract function boundaries from a single file (tree-sitter, no index) |
| `pmat split` | `sp` | — | Analyze and suggest semantic file splits using Louvain community detection |
| `pmat cuda-tdg` | `gpu-tdg`, `simd-tdg` | [8](#pmat-cuda-tdg) | CUDA-SIMD Technical Debt Gradient (100-point Popper falsification scoring) Analyzes CUDA PTX, SIMD (AVX2/AVX-512/NEON), and WGPU code for defects Integrates Toyota … |
| `pmat sql` | — | — | Direct SQL access to the function index database |
| `pmat stack` | `stk` | [3](#pmat-stack) | Cross-repo dependency coordination for the sovereign AI stack |

## Commands that take no subcommand

These run directly. The Path column is the form this command accepts a target path in — using the wrong one exits 2.

| Command | Path | Other positional arguments |
|---------|------|----------------------------|
| `pmat generate` | — | `<CATEGORY>` `<TEMPLATE>` |
| `pmat list` | — | — |
| `pmat search` | — | `<QUERY>` |
| `pmat validate` | — | `<URI>` |
| `pmat context` | `--project-path` | — |
| `pmat query` | `--path` | `[QUERY]` |
| `pmat demo` | `--path` | — |
| `pmat validate-docs` | — | — |
| `pmat validate-readme` | — | — |
| `pmat init` | `--path` | — |
| `pmat quality-gate` | `--project-path` | — |
| `pmat report` | `--project-path` | — |
| `pmat score` | `--path` | — |
| `pmat repo-score` | `--path` | — |
| `pmat rust-project-score` | `--path` | — |
| `pmat popper-score` | `--path` | — |
| `pmat demo-score` | `--path` | — |
| `pmat brick-score` | `--path` | — |
| `pmat infra-score` | `--path` | — |
| `pmat deps-audit` | `--path` | — |
| `pmat serve` | — | — |
| `pmat diagnose` | — | — |
| `pmat verify` | — | — |
| `pmat test` | — | `[SUITE]` |
| `pmat telemetry` | — | — |
| `pmat config` | — | — |
| `pmat show-metrics` | — | — |
| `pmat predict-quality` | — | — |
| `pmat record-metric` | — | `<METRIC>` `<VALUE>` |
| `pmat falsify` | `--path` | `<TARGET>` |
| `pmat five-whys` | `--path` | `<ISSUE>` |
| `pmat perfection-score` | `--path` | — |
| `pmat explain` | — | `[PATTERN]` |
| `pmat ci-local` | `--path` | — |
| `pmat kaizen` | `--path` | — |
| `pmat project-diag` | `--path` | — |
| `pmat test-stability` | `--path` | — |
| `pmat localize` | — | — |
| `pmat extract` | — | — |
| `pmat split` | `[FILE]` (positional) | — |
| `pmat sql` | `--path` | `[QUERY]` |

A `—` in the Path column means the command takes no path at all, or takes its
target some other way. Two that catch people out: `pmat extract` takes its file
as the *value* of `--list` (`pmat extract --list src/main.rs`), and `pmat generate`
takes a template category and name (`pmat generate makefile rust/cli -p project_name=demo`).

## Subcommands by parent

<a id="pmat-scaffold"></a>

### `pmat scaffold` (aliases: `sc`)

Scaffold complete project or agent

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat scaffold project` | — | — | Scaffold a complete project with templates |
| `pmat scaffold agent` | — | — | Scaffold a deterministic MCP agent |
| `pmat scaffold wasm` | — | — | Scaffold a WebAssembly project |
| `pmat scaffold list-templates` | — | — | List available agent templates |
| `pmat scaffold validate-template` | — | `<PATH>` (positional) | Validate an agent template |
| `pmat scaffold list-subagents` | — | — | List available Claude Code sub-agents |
| `pmat scaffold create-subagent` | — | — | Create a specific Claude Code sub-agent |
| `pmat scaffold create-all-subagents` | — | — | Create all MVP Claude Code sub-agents |
| `pmat scaffold validate-subagent` | — | — | Validate a sub-agent definition file |
| `pmat scaffold show-tool-mapping` | — | — | Show MCP tool mapping for sub-agents |
| `pmat scaffold export-tool-mapping` | — | — | Export MCP tool mapping as JSON |

<a id="pmat-analyze"></a>

### `pmat analyze` (aliases: `a` `an`)

Analyze code metrics and patterns

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat analyze bottleneck` | `btn`, `hotspot` | `--path` | Detect architectural churn bottleneck files |
| `pmat analyze churn` | `ch` | `--path` | Analyze code churn (change frequency) |
| `pmat analyze complexity` | `cx`, `complex` | `--path` | Analyze code complexity with MCP tool composition support |
| `pmat analyze dag` | `dep`, `graph` | `--path` | Generate dependency graphs using Mermaid |
| `pmat analyze dead-code` | `dead`, `dc` | `--path` | Analyze dead and unreachable code |
| `pmat analyze defects` | `known-defects` | `--path` | Scan project for known defect patterns (e.g., .unwrap() calls in Rust) |
| `pmat analyze reachability` | `orphans`, `unreachable` | `--path` | Report tracked .rs files that no compilation unit reaches |
| `pmat analyze hardcoded-paths` | `abs-paths`, `path-leaks` | `--path` | Find machine-specific absolute paths baked into source |
| `pmat analyze unrun-tests` | `unrun`, `test-ledger` | `--path` | Report tests no CI leg executes, keyed on the full module path |
| `pmat analyze vacuous-tests` | `vacuous`, `fake-tests` | `--path` | Find #[test] functions that cannot fail |
| `pmat analyze satd` | `debt`, `td`, `tech-debt` | `--path` | Analyze Self-Admitted Technical Debt (SATD) in comments |
| `pmat analyze deep-context` | `context`, `ctx`, `deep` | `--path` | Generate comprehensive deep context analysis with defect detection |
| `pmat analyze tdg` | — | `--path` | Analyze Technical Debt Gradient (TDG) scores |
| `pmat analyze build-tdg` | — | `--path` | Build with TDG quality gate (CI/CD optimized) |
| `pmat analyze lint-hotspot` | — | `--path` | Find the file with highest defect density (lint violations per line) |
| `pmat analyze makefile` | — | `<PATH>` (positional) | Analyze Makefile quality and compliance |
| `pmat analyze provability` | — | `--path` | Analyze provability properties using abstract interpretation |
| `pmat analyze duplicates` | — | `--path` | Detect duplicate code using vectorized `MinHash` and AST embeddings |
| `pmat analyze defect-prediction` | — | `--path` | Predict defect probability using ML-based analysis |
| `pmat analyze comprehensive` | — | `--path` | Run comprehensive multi-dimensional analysis with MCP tool composition |
| `pmat analyze graph-metrics` | — | `--path` | Analyze graph metrics and centrality measures |
| `pmat analyze name-similarity` | — | `--path` | Analyze name similarity with embeddings |
| `pmat analyze proof-annotations` | — | `--path` | Collect proof annotations from multiple sources |
| `pmat analyze incremental-coverage` | — | `--path` | Analyze incremental coverage changes with caching |
| `pmat analyze coverage-improve` | `improve-coverage`, `cov-improve` | `--path` | Improve test coverage to target percentage using PMAT tools and Extreme TDD |
| `pmat analyze symbol-table` | — | `--path` | Analyze symbol table with cross-references and usage patterns |
| `pmat analyze big-o` | — | `--path` | Analyze algorithmic complexity (Big-O) of functions |
| `pmat analyze assembly-script` | — | `--path` | Analyze `AssemblyScript` code |
| `pmat analyze web-assembly` | — | `--path` | Analyze WebAssembly binary and text format |
| `pmat analyze clippy` | — | `--path` | Automated clippy fixes with confidence-based filtering |
| `pmat analyze entropy` | — | `--path` | Analyze pattern entropy for actionable quality improvements |
| `pmat analyze wasm` | — | — | ⚠ [NOT AVAILABLE in the default build] Analyze WebAssembly modules — needs --features wasm-ast |
| `pmat analyze cluster` | — | — | Cluster code by semantic similarity |
| `pmat analyze topics` | — | — | Extract semantic topics from codebase |
| `pmat analyze models` | `model`, `mlops` | `--path` | Analyze ML model files (GGUF, APR, SafeTensors) |

<a id="pmat-qdd"></a>

### `pmat qdd` (aliases: `qd`)

Quality-Driven Development (QDD) tool for creating and refactoring code with guaranteed quality

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat qdd create` | — | — | Create high-quality code from specification |
| `pmat qdd refactor` | — | — | Refactor existing code to meet quality standards |
| `pmat qdd validate` | — | `--path` | Validate code against quality standards |

<a id="pmat-red-team"></a>

### `pmat red-team` (aliases: `rt` `hallucination-detect`)

Red Team Mode: Automated hallucination detection for commits and code

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat red-team analyze` | — | `--path` | Analyze a commit message for hallucinations |

<a id="pmat-org"></a>

### `pmat org` (aliases: `organization`)

[NOT AVAILABLE in the default build] Organizational intelligence — needs --features org-intelligence

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat org analyze` | — | — | ⚠ [REMOVED] Analyze GitHub organization for defect patterns — no longer available in any build |
| `pmat org localize` | — | — | Fault localization using Tarantula SBFL algorithm (Phase 5-7) |

<a id="pmat-mcp"></a>

### `pmat mcp`

Connect `pmat` to an MCP client: every transport, in one place

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat mcp manifest` | — | — | Manage the MCP manifest file |
| `pmat mcp connect` | `info`, `setup` | — | Print how to connect `pmat` to an MCP client — every transport, in one place |
| `pmat mcp token` | — | — | Print a fresh conforming bearer token and nothing else |

<a id="pmat-agy"></a>

### `pmat agy` (aliases: `antigravity`)

Google Anti-Gravity customizations translator

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat agy sync` | — | — | Report the PMAT work contracts an AGY transpiler would consume, then refuse the transpile: no Anti-Gravity target schema is defined (MACS-017, #984) |

<a id="pmat-prompt"></a>

### `pmat prompt` (aliases: `p`)

AI prompt generation (defect-aware, ticket-based, spec-based)

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat prompt show` | — | — | Show workflow prompt (original functionality - EXTREME TDD, Toyota Way, etc.) |
| `pmat prompt generate` | `gen`, `defect` | — | Generate defect-aware AI prompt from organizational intelligence |
| `pmat prompt ticket` | `tkt`, `fix` | — | Generate EXTREME TDD workflow prompt for fixing a ticket |
| `pmat prompt implement` | `impl`, `spec` | — | Generate implementation prompt from specification |
| `pmat prompt scaffold-new-repo` | `scaffold`, `new` | — | Generate prompt for scaffolding a new repository |
| `pmat prompt comply` | `compliance` | — | Fix all drift from PMAT's rigid quality processes and restore compliance |
| `pmat prompt book` | `docs`, `mdbook` | — | Create and maintain technical book documentation with EXTREME TDD validation |
| `pmat prompt repo-image` | `readme`, `image` | — | Generate professional repository documentation with badges and polish |
| `pmat prompt github-issue` | `issue`, `gh` | — | Implement GitHub issue/ticket with full EXTREME TDD workflow |

<a id="pmat-enforce"></a>

### `pmat enforce` (aliases: `enf`)

Enforce extreme quality standards using state machine

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat enforce extreme` | — | `--project-path` | Enforce extreme quality standards |

<a id="pmat-refactor"></a>

### `pmat refactor` (aliases: `ref` `rf`)

Refactor code with real-time analysis or interactive mode

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat refactor serve` | — | — | Run refactor server mode for batch processing |
| `pmat refactor interactive` | — | `--project-path` | Run interactive refactoring mode |
| `pmat refactor status` | — | — | Show current refactoring status |
| `pmat refactor resume` | — | — | Resume refactoring from checkpoint |
| `pmat refactor auto` | — | `--project-path` | AI-powered automated refactoring to achieve RIGID extreme quality standards |
| `pmat refactor docs` | — | `--project-path` | AI-assisted documentation cleanup and refactoring |

<a id="pmat-roadmap"></a>

### `pmat roadmap` (aliases: `road` `rm`)

Roadmap management with PDMT todos and quality gates

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat roadmap sync` | — | `--path` | Render a canonical ROADMAP.yaml from the work store + ledger states (MACS F6 / Component 32). Deterministic: ids sorted, generation timestamp excluded from the content … |
| `pmat roadmap init` | — | — | Initialize a new sprint in the roadmap |
| `pmat roadmap todos` | — | — | Generate PDMT todos from roadmap tasks |
| `pmat roadmap start` | — | — | Start working on a task |
| `pmat roadmap complete` | — | — | Complete a task (with quality validation) |
| `pmat roadmap status` | — | — | Check sprint or task status |
| `pmat roadmap validate` | — | — | Validate sprint readiness for release |
| `pmat roadmap quality-check` | — | — | Run quality checks for a task |

<a id="pmat-memory"></a>

### `pmat memory`

Memory management and optimization

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat memory stats` | — | — | Show current memory usage statistics |
| `pmat memory cleanup` | — | — | Force memory cleanup operations |
| `pmat memory configure` | — | — | Configure memory limits and policies |
| `pmat memory pools` | — | — | Show detailed pool statistics |
| `pmat memory pressure` | — | — | Check current memory pressure level |

<a id="pmat-cache"></a>

### `pmat cache`

Cache strategy management and optimization

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat cache stats` | — | — | Display cache statistics and performance metrics |

<a id="pmat-agent"></a>

### `pmat agent` (aliases: `ag`)

[NOT AVAILABLE in the default build] Claude Code background agent — needs --features agent-daemon

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat agent start` | — | `--project-path` | Start the background agent daemon |
| `pmat agent stop` | — | — | Stop the background agent daemon |
| `pmat agent status` | — | — | Show daemon status |
| `pmat agent monitor` | — | `--project-path` | Start monitoring a new project |
| `pmat agent unmonitor` | — | — | Stop monitoring a project |
| `pmat agent health` | — | — | Run health check |
| `pmat agent reload` | — | — | Reload daemon configuration |
| `pmat agent quality-gate` | — | — | Run quality gate through agent |
| `pmat agent mcp-server` | — | — | Start MCP server for testing |

<a id="pmat-tdg"></a>

### `pmat tdg` (aliases: `grade` `debt-grade`)

Grade technical debt and code quality (TDG - Technical Debt Grading)

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat tdg compare` | — | — | Compare two files or directories |
| `pmat tdg history` | — | `--path` | View TDG history at specific commits |
| `pmat tdg baseline` | — | — | Manage TDG baselines for quality regression detection |
| `pmat tdg diagnostics` | — | — | Show TDG system diagnostics and health status |
| `pmat tdg storage` | — | — | Manage TDG storage backends |
| `pmat tdg dashboard` | — | — | ⚠ [NOT AVAILABLE in the default build] Start TDG web dashboard server — needs --features http-server |
| `pmat tdg config` | — | — | Configuration management (single source of truth) |
| `pmat tdg check-regression` | — | `--path` | Check for quality regressions against baseline |
| `pmat tdg check-quality` | — | `--path` | Check files meet minimum quality thresholds |

<a id="pmat-quality-gates"></a>

### `pmat quality-gates` (aliases: `gates` `qg`)

Run configurable quality gates on the current project

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat quality-gates init` | — | — | Initialize .`pmat`-gates.toml with defaults |
| `pmat quality-gates validate` | — | — | Validate configuration file |
| `pmat quality-gates show` | — | — | Show current configuration |

<a id="pmat-maintain"></a>

### `pmat maintain` (aliases: `maint` `m`)

Project maintenance commands (cleanup, validation, reports)

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat maintain roadmap` | — | — | Validate roadmap structure and ticket consistency |
| `pmat maintain health` | — | — | Validate project health (build only by default; --all adds tests, coverage, complexity, SATD) |
| `pmat maintain bug-report` | `bug`, `report` | — | Create bug report from captured error |
| `pmat maintain cleanup-resources` | `clean`, `cleanup`, `purge` | — | Clean up development artifacts and caches |

<a id="pmat-hooks"></a>

### `pmat hooks` (aliases: `hook` `h`)

Pre-commit hook management and installation

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat hooks init` | — | — | Initialize pre-commit hooks (alias for install) |
| `pmat hooks install` | — | — | Install or update pre-commit hooks |
| `pmat hooks uninstall` | — | — | Remove PMAT-managed hooks |
| `pmat hooks status` | — | — | Show hook installation status |
| `pmat hooks verify` | — | — | Verify hooks work with current configuration |
| `pmat hooks refresh` | — | — | Regenerate hooks from current configuration |
| `pmat hooks run` | — | — | Run pre-commit hooks (for CI/CD integration) |
| `pmat hooks cache` | — | — | O(1) cache management for hooks |

<a id="pmat-embed"></a>

### `pmat embed` (aliases: `emb`)

Manage semantic search embeddings for code search

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat embed sync` | — | `--path` | Sync embeddings for codebase |
| `pmat embed status` | — | — | Show embedding database status |
| `pmat embed clear` | — | — | Clear all embeddings (requires --confirm) |

<a id="pmat-semantic"></a>

### `pmat semantic` (aliases: `sem` `find-code`)

Semantic code search using embeddings

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat semantic search` | — | — | Search code by natural language query |
| `pmat semantic similar` | — | — | Find code files similar to a reference file |

<a id="pmat-debug"></a>

### `pmat debug` (aliases: `dbg`)

Time-travel debugging commands for execution traces

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat debug serve` | `srv`, `server` | — | [NOT IMPLEMENTED] DAP (Debug Adapter Protocol) server — exits with an error |
| `pmat debug replay` | `play`, `view` | — | [NOT IMPLEMENTED] Replay an execution recording — exits with an error |

<a id="pmat-work"></a>

### `pmat work` (aliases: `w`)

Unified GitHub/YAML workflow management

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat work add` | `new`, `create`, `a` | `--path` | Add a new work ticket (CREATE) |
| `pmat work list` | `ls`, `l` | `--path` | List all work tickets (READ) |
| `pmat work edit` | `update`, `e` | `--path` | Edit an existing ticket (UPDATE) |
| `pmat work delete` | `rm`, `remove`, `del` | `--path` | Delete a work ticket (DELETE) |
| `pmat work annotate` | `ann`, `quality`, `metrics` | `--path` | Show unified quality annotations for a ticket |
| `pmat work start` | `begin`, `s` | `--path` | Start work on a GitHub issue or YAML ticket |
| `pmat work continue` | `cont`, `c`, `resume` | `--path` | Continue work on existing issue/ticket |
| `pmat work checkpoint` | `ck`, `cp` | `--path` | Run invariant checkpoint (DbC §4.2) |
| `pmat work complete` | `done`, `finish`, `f` | `--path` | Complete work on issue/ticket |
| `pmat work delegate` | `handoff` | `--path` | Delegate an active PMAT work contract to a Google Anti-Gravity agent (MACS-019) |
| `pmat work falsify` | `test-claims` | `--path` | Run falsification tests without completing the work item |
| `pmat work cot` | — | — | Structured chain-of-thought tools: integrity check + derivation (MACS F3 / Component 31) |
| `pmat work ledger` | — | — | Falsification-ledger tools: hash re-verification + provenance report (MACS F1 / Component 32) |
| `pmat work event` | `ev` | `--path` | Record an agent interruption event (refusal, model switch, session restart, workflow spawn) or acknowledge one (MACS F1/E5) |
| `pmat work claim` | `claims` | — | Claim exclusive ownership of paths for one agent, so concurrent agents cannot silently collide on the same file (ULTRA-002) |
| `pmat work triage` | — | — | Record and gate the coverage of a bounded triage pass: what was examined, what was acted on, and what was dropped (ULTRA-003) |
| `pmat work status` | `st`, `stat` | `--path` | Show work status |
| `pmat work sync` | `sy` | `--path` | Synchronize GitHub and YAML |
| `pmat work init` | `setup`, `ini` | `--path` | Initialize roadmap and hooks |
| `pmat work validate` | `check`, `lint`, `v` | `--path` | Validate roadmap.yaml syntax and content (Part B: UX Improvements) |
| `pmat work migrate` | `fix`, `m` | `--path` | Auto-fix common roadmap.yaml issues (Part B: UX Improvements) |
| `pmat work list-statuses` | `values`, `statuses` | — | List all valid status values with descriptions |
| `pmat work score` | `sc`, `quality-score` | `--path` | Score a work contract (DBC spec 5-dimension quality + lint) |
| `pmat work codebase-score` | `cbs`, `portfolio` | `--path` | Aggregate quality score across all work contracts (DBC spec §14.6) |

<a id="pmat-qa-work"></a>

### `pmat qa-work` (aliases: `qa` `quality`)

QA validation after work completion with Toyota Way quality gates

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat qa-work generate-checklist` | `checklist`, `cl` | `--path` | Generate QA checklist for a task |
| `pmat qa-work validate` | `check`, `v` | `--path` | Run automated QA validation |
| `pmat qa-work report` | `r` | `--path` | Generate QA report for audit trail |
| `pmat qa-work summary` | `st`, `status` | `--path` | Show QA status summary |
| `pmat qa-work generate-examples` | `examples`, `ex` | `--path` | Generate example scripts for a feature (V2) |
| `pmat qa-work mcp-sweep` | `sweep`, `mcp` | `--path` | LLM-free deterministic MCP conformance sweep (MACS F5). Spawns the live MCP server over stdio, derives minimal args from each tool's inputSchema, calls every tool, and … |
| `pmat qa-work spec` | `popper` | `--path` | Validate specification with 100-point Popperian falsifiability scoring (Part D & E) |

<a id="pmat-oracle"></a>

### `pmat oracle` (aliases: `fix` `pdca`)

PMAT Oracle - PDCA loop for automated quality improvement (Toyota Way) Converges ANY Rust project toward perfect quality using CITL signals

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat oracle fix` | `f`, `run` | `--path` | Run PDCA fix loop to converge toward perfect project quality Uses CITL (Compiler-In-The-Loop) signals from rustc, clippy, cargo test |
| `pmat oracle status` | `s` | `--path` | Show current project quality status against convergence targets |
| `pmat oracle single` | — | `--path` | Run a single PDCA iteration (for CI/CD integration) |

<a id="pmat-spec"></a>

### `pmat spec` (aliases: `specification`)

Specification management and validation

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat spec score` | `validate`, `v` | — | Validate specification with 100-point Popperian score (S-001) Requires ≥95 points to be worked on |
| `pmat spec comply` | `fix`, `c` | — | Auto-fix spec issues to meet 95-point threshold (S-003) |
| `pmat spec create` | `new`, `n` | — | Create new specification from template |
| `pmat spec list` | `ls`, `l` | `--path` | List all specifications with their scores |
| `pmat spec sync` | `sy`, `link` | — | Sync specs with roadmap (bidirectional ticket linking) |
| `pmat spec drift` | `orphans`, `unlinked` | — | Report specs without roadmap links (drift detection) |

<a id="pmat-comply"></a>

### `pmat comply` (aliases: `compliance`)

PMAT compliance checking and migration system (runs check by default)

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat comply check` | `status` | `--path` | Check project compliance with current PMAT version |
| `pmat comply migrate` | — | `--path` | Migrate project to latest PMAT standards |
| `pmat comply upgrade` | — | `--path` | Upgrade project to a specific quality enforcement style (e.g., Popperian) |
| `pmat comply diff` | — | `--path` | Show changelog since project's PMAT version |
| `pmat comply update` | — | `--path` | Update hooks and configs to latest versions |
| `pmat comply init` | — | `--path` | Initialize .`pmat`/project.toml with current version |
| `pmat comply enforce` | `install`, `hooks` | `--path` | Install git hooks for mandatory work tracking (W-006) Blocks commits without active tickets per master-plan-`pmat`-work-system.md |
| `pmat comply report` | — | `--path` | Generate compliance report (W-009) |
| `pmat comply ledger` | — | `--path` | CB-2100: generate the comply enforcement ledger |
| `pmat comply ratchet` | — | `--path` | CB-2102: check the ratchet baselines, or lower them |
| `pmat comply coherence` | — | `--path` | CB-2101: classify every threshold in `.`pmat`-metrics.toml` |
| `pmat comply numeric-claims` | — | `[PATH]` (positional) | CB-2104: report numbers this repository writes down about itself and then contradicts |
| `pmat comply review` | — | `--path` | Layer 2 (Genchi Genbutsu): Evidence-based review checklist (COMPLY-045) Generates a reviewer checklist with reproducibility, hypothesis, and trace evidence |
| `pmat comply audit` | — | `--path` | Layer 3 (Governance): Generate audit artifact with sovereign trail (COMPLY-045) Requires clean git state. Produces UNSIGNED compliance evidence pinned to the HEAD commit |
| `pmat comply baseline` | — | `--path` | Generate file health baseline for ratchet enforcement Scans source files, calculates health metrics, saves to .`pmat`/file-health-baseline.json |
| `pmat comply refresh-bindings` | `refresh`, `rb` | `--path` | Generate .`pmat`/binding-index.json, O(1) caches, and contracts/work/*.yaml Enables CB-1350 differential obligation verification at commit time |
| `pmat comply ratchet-override` | `override` | `--path` | Override verification level ratchet for a binding (escape hatch for CB-1330). Records signed entry in .`pmat`-metrics/ratchet-overrides.jsonl, expires in 14 days |
| `pmat comply asset-validate` | `av` | `--path` | Validate non-code asset layout contracts (README, Dockerfile, SVG, etc.) Runs CB-1320..1326 checks on a specific asset or all assets |
| `pmat comply cross-crate` | `cc`, `xc` | `--path` | Cross-crate duplication detection (CC-001 through CC-005) Detects copy-paste duplication, API divergence, and churn correlation across workspace crates |

<a id="pmat-test-discovery"></a>

### `pmat test-discovery` (aliases: `test-fix` `fix-tests`)

Systematic test discovery and fixing

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat test-discovery run` | `d` | `--path` | Discover all test failures in workspace |
| `pmat test-discovery categorize` | `cat` | — | Categorize test failures by root cause |
| `pmat test-discovery mark` | `m` | — | Mark tests as #[ignore] with reasons |
| `pmat test-discovery verify` | `v` | `--path` | Verify all tests pass after marking |
| `pmat test-discovery create-tickets` | `tickets`, `t` | — | Create GitHub issues from categorized test failures (Phase 5) |
| `pmat test-discovery resolve-paths` | `resolve`, `r` | `--path` | Resolve test file paths from test names |

<a id="pmat-cuda-tdg"></a>

### `pmat cuda-tdg` (aliases: `gpu-tdg` `simd-tdg`)

CUDA-SIMD Technical Debt Gradient (100-point Popper falsification scoring) Analyzes CUDA PTX, SIMD (AVX2/AVX-512/NEON), and WGPU code for defects Integrates Toyota Production System principles with falsificationist methodology

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat cuda-tdg analyze` | — | `<PATH>` (positional) | Analyze a file or directory for CUDA/SIMD defects |
| `pmat cuda-tdg score` | — | `[PATH]` (positional) | Score codebase with 100-point Popper falsification system |
| `pmat cuda-tdg report` | — | `[PATH]` (positional) | Generate detailed defect report |
| `pmat cuda-tdg barrier-check` | — | `<PATH>` (positional) | Check barrier safety (PARITY-114 detection) |
| `pmat cuda-tdg validate-tiles` | — | — | Validate tile dimensions for attention kernels |
| `pmat cuda-tdg gate` | — | `[PATH]` (positional) | Quality gate for CI/CD (exits non-zero on failure) |
| `pmat cuda-tdg kaizen` | — | `[PATH]` (positional) | Generate Kaizen continuous improvement report |
| `pmat cuda-tdg taxonomy` | — | — | Show Tauranta fault taxonomy |

<a id="pmat-stack"></a>

### `pmat stack` (aliases: `stk`)

Cross-repo dependency coordination for the sovereign AI stack

| Subcommand | Aliases | Path | What it does |
|------------|---------|------|--------------|
| `pmat stack status` | `st` | — | Show dependency status across all stack repos |
| `pmat stack sync` | `s` | — | Sync dependency versions across repos |
| `pmat stack scaffold` | `sc` | — | Generate SQI-compliant boilerplate files for repo hygiene |


## Verified examples

Each block below was **executed** against `pmat 3.32.0` on 2026-08-25, in a two-file Rust
fixture, and the exit status recorded. Output is trimmed for length; nothing else is
edited.

```bash
pmat --version
# pmat 3.32.0                                                     exit 0
```

```bash
pmat analyze complexity --path .
# ✅ Successfully analyzed 1 file(s)
#   Files analyzed: 1
#   Total functions: 3                                            exit 0
```

```bash
pmat analyze satd --path .
# Found 1 SATD violations in 1 files (analysed 1 of 1 file(s) walked)   exit 0
```

```bash
pmat analyze dead-code --path .
#   Files with dead code: 1
#   Dead code percentage: 27.8%                                   exit 0
```

```bash
pmat analyze tdg -p . --format table
#   Average Score: 99.5/100 (A+)                                  exit 0
```

```bash
pmat tdg .
#   Overall Score: 99.5/100 (A+)                                  exit 0
```

```bash
pmat quality-gate -p . --checks complexity
# Quality Gate: PASSED
# Total violations: 0                                             exit 0
```

```bash
pmat analyze dag --target-nodes 10
# 📊 full-dependency: rendered 4 nodes and 0 edges
# graph TD                                                        exit 0
```

```bash
pmat extract --list src/main.rs
# { "file": "src/main.rs", "language": "rust", "items": [ ...     exit 0
```

```bash
pmat search rust --limit 2
#  1. template://readme/rust/cli (score: 9.00)                    exit 0
```

```bash
pmat mcp connect
# prints every way to connect this binary to an MCP client, with
# the exact `claude mcp add` line                                 exit 0
```

Two failures worth knowing, also executed. They are shown as a table rather than a
code block on purpose: this is what a *wrong* form looks like, not something to type.

| Command | Result | Why |
|---------|--------|-----|
| `pmat analyze .` | `error: unrecognized subcommand`, exit 2 | `analyze` requires a subcommand, and the path belongs to it: `pmat analyze complexity --path .` |
| `pmat repo-score .` | `error: unexpected argument found`, exit 2 | `repo-score` takes `--path`; a positional path is rejected |

Between them these two shapes account for most broken `pmat` lines in circulation.
Check the Path column in the tables above before typing a path.


## Commands earlier editions listed that do not exist

Every row here was printed as a working command by this appendix before
2026-08-25. None of them resolve against `pmat 3.32.0`. The middle column is what the
binary actually does when you type it; the right column is the nearest real command,
verified to resolve.

Where the right column says **nothing** — there is no equivalent. `pmat` has no plugin
system, no webhook manager, no notification sender, no team/retrospective features and
no secret scanner. That capability was never built; it was only ever written down.

| Documented command (fiction) | What really happens | Real command in pmat 3.32.0 |
|------------------------------|---------------------|---------------------------|
| `pmat status` | `error: unrecognized subcommand` | `pmat diagnose`, or `pmat score --path .` |
| `pmat scan` | `error: unrecognized subcommand` | `pmat analyze comprehensive --path .` |
| `pmat watch` | `error: unrecognized subcommand` | nothing — there is no watch mode |
| `pmat complexity` | `error: unrecognized subcommand` | `pmat analyze complexity --path .` |
| `pmat dead-code` | `error: unrecognized subcommand` | `pmat analyze dead-code --path .` |
| `pmat satd` | `error: unrecognized subcommand` | `pmat analyze satd --path .` |
| `pmat similarity` | `error: unrecognized subcommand` | `pmat analyze name-similarity`, `pmat analyze duplicates`, `pmat semantic similar` |
| `pmat architecture analyze` (and `deps`, `patterns`, `graph`, `validate-layers`) | `error: unrecognized subcommand` | `pmat analyze dag`, `pmat analyze graph-metrics`, `pmat analyze symbol-table` |
| `pmat rules init` (and `create`, `test`, `validate`) | `error: unrecognized subcommand` | `pmat quality-gates init` writes `.pmat-gates.toml`; `pmat comply` enforces project rules |
| `pmat clippy run` (and `enable`, `fix`) | `error: unrecognized subcommand` | `pmat analyze clippy` |
| `pmat security scan` | `error: unrecognized subcommand` | `pmat quality-gate --checks security` |
| `pmat secrets scan` | `error: unrecognized subcommand` | nothing — `pmat` does not scan for secrets |
| `pmat audit` | `error: unrecognized subcommand` | `pmat deps-audit --path .` (dependencies), `pmat comply audit` (governance artifact) |
| `pmat dependencies` | `error: unrecognized subcommand` | `pmat deps-audit --path .` |
| `pmat performance analyze` (and `hotspots`, `memory`, `compare`) | `error: unrecognized subcommand` | `pmat test performance`, `pmat analyze big-o`, `pmat analyze bottleneck` |
| `pmat benchmark` | `error: unrecognized subcommand` | `pmat test throughput` |
| `pmat compare` / `pmat diff` | `error: unrecognized subcommand` | `pmat tdg compare`, `pmat comply diff` |
| `pmat merge` / `pmat export` / `pmat import` | `error: unrecognized subcommand` | nothing — use each command's own `--format` and `--output` |
| `pmat report executive` | `report` takes no subcommand; exits 2 | `pmat report --format json` |
| `pmat dashboard serve` / `pmat dashboard generate` | `error: unrecognized subcommand` | `pmat tdg dashboard` ⚠ (needs `--features http-server`; not in the shipped build) |
| `pmat team setup` / `pmat retrospective` / `pmat review prepare` | `error: unrecognized subcommand` | nothing — no team, retrospective or review-prep features exist |
| `pmat webhook` / `pmat notify slack` | `error: unrecognized subcommand` | nothing — `pmat` sends no notifications |
| `pmat pipeline validate` | `error: unrecognized subcommand` | `pmat ci-local` |
| `pmat plugin list` (and `install`, `update`) | `error: unrecognized subcommand` | nothing — there is no plugin system |
| `pmat ai analyze` (and `suggest`, `refactor`, `review`) | `error: unrecognized subcommand` | `pmat refactor auto`, `pmat prompt generate`, `pmat oracle fix` |
| `pmat info` | `error: unrecognized subcommand` | `pmat diagnose --format json` |
| `pmat doctor` | works — it is an **alias** of `pmat diagnose` | `pmat diagnose` |
| `pmat check` | works — it is an **alias** of `pmat quality-gate` | `pmat quality-gate` |
| `pmat compliance` | works — it is an **alias** of `pmat comply` | `pmat comply check` |
| `pmat config set` (and `get`, `list`, `reset`, `profiles`, `export`, `import`) | `config` takes no subcommand; exits 2 | `pmat config --show`, `--edit`, `--validate`, `--reset` |
| `pmat cache clear` (and `optimize`, `warmup`, `configure`) | `error: unrecognized subcommand` | only `pmat cache stats` exists; delete the `.pmat/` directory to clear |
| `pmat hooks configure` | `error: unrecognized subcommand` | `pmat hooks refresh`, `pmat hooks verify`, `pmat hooks status` |
| `pmat self-update` | `error: unrecognized subcommand` | `cargo install pmat --force` |
| `pmat mutate` | `error: unrecognized subcommand` | nothing in `pmat` — run `cargo mutants` directly |
| `pmat analyze tdg --detailed` | `--detailed` is not a flag; exits 2 | `pmat analyze tdg -p . --include-components` |


## Global options

These are accepted by every command (from `pmat --help`):

| Option | Description |
|--------|-------------|
| `--mode <cli\|mcp>` | Force CLI or MCP mode instead of auto-detecting. `--mode mcp` starts the MCP stdio server |
| `-v`, `--verbose` | Info-level output |
| `-q`, `--quiet` | Errors only |
| `--debug` | Debug-level output |
| `--trace` | Trace-level output |
| `--trace-filter <FILTER>` | Custom trace filter, e.g. `--trace-filter="paiml=debug,cache=trace"` (env: `RUST_LOG`) |
| `--color <auto\|always\|never>` | Colour control (default `auto`) |
| `-h`, `--help` | Print help |
| `-V`, `--version` | Print version |

`--format` and `--output` are **per-command**, not global: most analysis commands take
`-f, --format` and `-o, --output`, but the accepted values differ per command. Check
`pmat <command> --help`.

## Environment variables

Only variables that `pmat 3.32.0` itself declares in `--help` (as `[env: NAME=]`) or
prints from `pmat mcp connect` are listed. Earlier editions of this appendix listed
eight variables — `PMAT_CONFIG_PATH`, `PMAT_PROFILE`, `PMAT_MAX_THREADS`,
`PMAT_MEMORY_LIMIT`, `PMAT_API_TOKEN`, `PMAT_DEBUG`, `PMAT_LOG_LEVEL` and
`PMAT_CACHE_DIR` — of which seven appear nowhere in the `pmat` source at all.
`PMAT_CACHE_DIR` is the one that is real, but no `--help` declares it, so it is listed
here as a source-level detail rather than a supported interface.

| Variable | Where it applies |
|----------|------------------|
| `MCP_VERSION=1` | Setting it makes a bare `pmat` start the MCP stdio server (equivalent to `pmat --mode mcp`) |
| `PMAT_MCP_HTTP_TOKEN` | Bearer token for `pmat serve --transport http`. Must be ≥16 characters or the server refuses to start |
| `RUST_LOG` | Backs `--trace-filter` on every command |
| `PMAT_COVERAGE_FILE` | `pmat query` — path to the coverage file to enrich results with |
| `PMAT_AGENT_MODEL`, `PMAT_AGENT_HARNESS`, `PMAT_AGENT_EFFORT`, `PMAT_AGENT_PARENT`, `PMAT_AGENT_WORKFLOW_ID` | Agent provenance recorded by `pmat work start`, `work checkpoint`, `work complete`, `work falsify` |

## Exit codes

Measured, not documented by the tool. Earlier editions of this appendix listed ten
codes (3 = analysis failure, 4 = quality gate failure, 5 = security violation, 20 =
license error, …); `pmat` emits none of them.

| Code | Meaning | Example that produces it |
|------|---------|--------------------------|
| 0 | Success — including an analysis that *found* problems but was not asked to fail on them | `pmat analyze satd --path .` |
| 1 | The command ran and failed: a gate tripped, a target could not be analysed, a subprocess died | `pmat analyze satd --path . --fail-on-violation`, `pmat analyze complexity --path /nonexistent` |
| 2 | Usage error from the argument parser — unknown subcommand, unknown flag, unexpected positional | `pmat analyze .`, `pmat repo-score .` |

A `--fail-on-*` style flag is what turns a finding into exit 1; without one, most
analysis commands report and exit 0. Do not build CI on "pmat exited 0 therefore the
code is clean" — check the flag list for the command you are running.

## See also

- [Chapter 5: The Analyze Command Suite](ch05-00-analyze-suite.md) — `pmat analyze` with worked examples
- [Chapter 3.4: MCP Transports](ch03-04-mcp-transports.md) — the verified MCP surface
- [Chapter 15: Complete MCP Tools Reference](ch15-00-mcp-tools.md) — the 19 MCP tools, read out of the server
- `pmat <command> --help` — always the authority; this appendix is generated from it
