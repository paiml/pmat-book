# Chapter 45: RAG-Powered Agent Context

**Chapter Status**: Working

*PMAT version: pmat 3.0.0*

## The Problem

AI agents like Claude Code, Cline, and Cursor **never** use `pmat context`. When they need to find code, they fall back to `grep` and `glob`:

```bash
# What agents actually do
grep -r "error" src/ | head -50
# Result: 500+ irrelevant matches, no quality info, wasted tokens
```

PMAT already computes rich quality metadata per function -- TDG scores, cyclomatic complexity, SATD markers, Big-O estimates -- but agents don't know this data exists.

## The Solution: `pmat query`

`pmat query` provides **semantic code search** that understands intent and returns quality-ranked results:

```bash
pmat query "error handling in API layer" --min-grade B --limit 5
```

```
Found 5 functions:

1. src/api/error.rs:42 - handle_api_error
   Signature: pub fn handle_api_error(err: ApiError) -> Response
   TDG: A (2.1) | Complexity: 8 | Big-O: O(1)
   Doc: Converts API errors to HTTP responses
   Relevance: 0.92

2. src/api/middleware.rs:128 - error_middleware
   Signature: pub async fn error_middleware(req: Request, next: Next) -> Response
   TDG: B (3.4) | Complexity: 12 | Big-O: O(1)
   Doc: Catches and formats errors in request pipeline
   Relevance: 0.87
```

### How It Works

1. **Index Build**: `pmat query` auto-builds a function index on first run, persisted to `.pmat/context.idx`
2. **AST Extraction**: Every function is extracted with signature, doc comments, and body
3. **Quality Annotation**: TDG score, complexity, Big-O, SATD count computed per function
4. **Term-Based Scoring**: Query terms are matched against function names, signatures, docs, and file paths
5. **Quality Ranking**: Results ranked by `relevance * quality_factor(tdg_grade)`

### Architecture

```
Source Files ──> AST Parser ──> Function Chunks ──> Annotator ──> Index
                (tree-sitter)   (per function)     (TDG, complexity)
                                                        │
                                                        v
                                              ┌─────────────────┐
                                              │ Query Engine     │
                                              │ - pmat query     │
                                              │ - MCP tools      │
                                              │ - quality filter  │
                                              └─────────────────┘
```

## CLI Usage

### Basic Search

```bash
# Semantic search by intent
pmat query "error handling"

# With result limit
pmat query "authentication logic" --limit 10
```

### Quality Filters

```bash
# Only high-quality functions (TDG grade A or B)
pmat query "database connection" --min-grade B

# Low complexity only
pmat query "validation" --max-complexity 10

# Combined filters
pmat query "parsing" --min-grade A --max-complexity 15 --limit 5
```

### Output Formats

```bash
# Text output (default, human-readable)
pmat query "error handling"

# JSON output (for scripting and CI/CD)
pmat query "database connection" --format json

# Markdown output (for reports and documentation)
pmat query "TDG scoring" --format markdown
```

### Language Filter

```bash
# Search only Rust files
pmat query "validation" --language rust

# Search only Python files
pmat query "data processing" --language python
```

### Path Filter

```bash
# Search within a specific directory
pmat query "middleware" --path src/api/
```

### Definition Type Filter (v3.0.0)

Filter results by definition type to find specific kinds of code elements:

```bash
# Search only functions
pmat query "error handling" --type fn

# Search only struct definitions
pmat query "config" --type struct

# Search only enums
pmat query "status" --type enum

# Search only traits
pmat query "serializable" --type trait

# Search only type aliases
pmat query "result" --type type
```

**Available Types:**

| Type | Description | Example Match |
|------|-------------|---------------|
| `fn` | Functions and methods | `fn handle_error()` |
| `struct` | Struct definitions | `struct Config { ... }` |
| `enum` | Enum definitions | `enum Status { ... }` |
| `trait` | Trait definitions | `trait Serializable { ... }` |
| `type` | Type aliases | `type Result<T> = ...` |

**Use Cases:**
- Finding all error-related enums: `pmat query "error" --type enum`
- Finding configuration structs: `pmat query "config" --type struct`
- Finding trait implementations: `pmat query "handler" --type trait`
- Combining with quality filters: `pmat query "parser" --type struct --min-grade B`

### Cross-Project Search

By default, `pmat query` auto-discovers sibling projects with indexes. You can also explicitly include additional projects:

```bash
# Include a specific project (can be specified multiple times)
pmat query "matrix multiplication" --include-project ~/src/aprender

# Include multiple projects
pmat query "graph algorithm" \
  --include-project ~/src/aprender \
  --include-project ~/src/trueno-graph

# Combined with other filters
pmat query "validation" --include-project ~/src/other-project --rank-by pagerank
```

**Note:** The included project must have a `.pmat/context.idx` file. Run `pmat query --rebuild-index` in that project first if needed.

### Graph-Aware Ranking

**NEW in v2.216.0**: Query results can be ranked by graph metrics (PageRank, centrality) instead of pure semantic relevance.

```bash
# Rank by PageRank (most important functions in the call graph)
pmat query "error handling" --rank-by pagerank

# Rank by in-degree (most called functions)
pmat query "format" --rank-by indegree

# Rank by centrality (hub functions with most connections)
pmat query "parse" --rank-by centrality

# Filter by minimum PageRank score
pmat query "mcp" --min-pagerank 0.0001
```

**Ranking Options:**

| Option | Description | Use Case |
|--------|-------------|----------|
| `relevance` | Default. Semantic similarity to query | Finding specific functionality |
| `pagerank` | Function importance (called by important callers) | Finding critical code paths |
| `centrality` | Total connections (in + out degree) | Finding hub functions |
| `indegree` | Most called functions | Finding utility/helper functions |

### Coverage Gap Analysis (v3.0.0)

**NEW in v3.0.0**: Find uncovered code without writing a query string. Auto-detects LLVM coverage data from `cargo llvm-cov`.

```bash
# Top 20 coverage gaps, ranked by uncovered lines
pmat query --coverage-gaps --limit 20 --exclude-tests

# Coverage-enriched semantic search
pmat query "error handling" --coverage --limit 10

# Only uncovered functions
pmat query "parse" --coverage --uncovered-only --limit 10

# ROI ranking: missed_lines * pagerank * (1/complexity)
pmat query --coverage-gaps --rank-by impact --limit 10
```

**Example Output:**

```
Coverage Gaps (20 functions with uncovered code)

   1. 590 uncov |  3.3% cov | src/cli/command_structure.rs:57 execute [F] impact:1.4
   2. 558 uncov |  3.8% cov | src/cli/command_dispatcher/mod.rs:57 route_command [F]
   3. 345 uncov | 23.8% cov | src/tdg/cuda_simd/detection.rs:156 detect_ptx_memory_patterns [F]
```

**How it works:**

1. Auto-detects coverage: checks `--coverage-file` flag, `PMAT_COVERAGE_FILE` env, `.pmat/coverage-cache.json`, or runs `cargo llvm-cov report --json`
2. Enumerates ALL indexed functions (no query string needed)
3. Intersects function line ranges with LLVM coverage data
4. Filters to uncovered/partially-covered functions
5. Sorts by missed lines (descending) for maximum impact

**Impact score** (`--rank-by impact`): `missed_lines * max(pagerank * 10000, 0.1) * (1 / max(complexity, 1))` — prioritizes high-importance, low-complexity uncovered code (best ROI for writing tests).

### Search Modes (v3.0.0)

**NEW in v3.0.0**: `pmat query` now supports regex and literal search modes, replacing most `grep`/`rg` use cases:

```bash
# Regex search (like rg -e)
pmat query --regex "fn\s+handle_\w+" --limit 10

# Literal string search (like rg -F)
pmat query --literal "unwrap()" --exclude-tests --limit 10

# Case-insensitive search
pmat query "Error" -i --limit 10

# Exclude patterns (like grep -v)
pmat query "handler" --exclude "test" --limit 10

# Files with matches only (like rg -l)
pmat query "cache" --files-with-matches

# Count matches per file (like rg -c)
pmat query "unwrap" --count

# Context lines (like grep -C)
pmat query "panic" -A 3 -B 2 --limit 10

# Raw file search (bypass AST index, pure rg-like)
pmat query --raw "TODO" --limit 20
```

### Enrichment Flags (v2.217.0+)

Enrich query results with additional quality signals. All flags compose freely:

```bash
# Git volatility (hot files with high churn)
pmat query "cache" --churn --limit 10

# Code clone detection
pmat query "serialize" --duplicates --limit 10

# Pattern diversity metrics
pmat query "handler" --entropy --limit 10

# Fault pattern annotations (unwrap, panic, unsafe)
pmat query "parse" --faults --exclude-tests --limit 10

# Git commit history fusion (search by intent)
pmat query "fix memory leak" -G --limit 10

# LLVM line coverage enrichment (v3.0.0)
pmat query "error handling" --coverage --limit 10

# Coverage + uncovered only filter
pmat query "parse" --coverage --uncovered-only --limit 10

# Full enrichment (all signals)
pmat query "dispatch" --churn --duplicates --entropy --faults --coverage -G --limit 10
```

#### Coverage Enrichment (v3.0.0)

The `--coverage` flag fuses LLVM line coverage data into query results. Each function gets:

| Field | Description |
|-------|-------------|
| `line_coverage_pct` | Percentage of instrumented lines covered (0.0-100.0) |
| `lines_covered` | Number of lines with at least one execution |
| `lines_total` | Total instrumented lines in function |
| `missed_lines` | Number of uncovered lines |
| `impact_score` | ROI score: `missed_lines * pagerank * (1/complexity)` |

**Coverage data sources** (checked in order):
1. `--coverage-file <path>` — explicit LLVM JSON file
2. `PMAT_COVERAGE_FILE` environment variable
3. `.pmat/coverage-cache.json` — cached from previous run
4. `cargo llvm-cov report --json` — auto-runs instrumented export

**Coverage as fault annotations**: When `--faults` is combined with `--coverage`, three coverage-specific fault patterns are annotated:

| Fault | Condition | Meaning |
|-------|-----------|---------|
| `NO_COVERAGE` | 0% line coverage | Function is completely untested |
| `LOW_COVERAGE` | 1-49% line coverage | Function has significant uncovered paths |
| `COVERAGE_RISK` | Function has uncovered lines in high-pagerank code | High-impact coverage gap |

```bash
# Find fault patterns including coverage faults
pmat query "error" --faults --coverage --exclude-tests --limit 10

# Example output:
#   src/api/handler.rs:42 - process_request
#   TDG: B | Complexity: 12 | 🛡️32% | 📈4.2
#   Faults: LOW_COVERAGE, UNWRAP_CALL
```

#### Impact Ranking (v3.0.0)

`--rank-by impact` sorts results by ROI — uncovered code that matters most:

```bash
# Best ROI for writing tests: high importance, low complexity, many missed lines
pmat query --coverage-gaps --rank-by impact --limit 20

# Impact formula: missed_lines * max(pagerank * 10000, 0.1) * (1 / max(complexity, 1))
```

This prioritizes functions that are:
- **Heavily called** (high pagerank = high blast radius if buggy)
- **Simple** (low complexity = easy to write tests for)
- **Uncovered** (many missed lines = high coverage gain per test)

### Churn Integration (v2.217.0)

Query results include git churn metrics when available:

```
1. src/api/handler.rs:42 - process_request
   Signature: pub async fn process_request(req: Request) -> Response
   TDG: B (3.4) | Complexity: 12 | Big-O: O(n) | 🔥 Hot: 25 commits (80%)
```

- **🔥 Hot** indicator appears for files with churn_score > 0.5 (frequently modified)
- **Commits** count shown for all files with git history
- High-churn files may indicate code that needs attention (bug hotspots, unstable design)

#### Programmatic Churn Enrichment

The API provides functions for enriching query results with churn data:

```rust
use pmat::services::agent_context::{
    enrich_with_churn, enrich_results_with_churn, build_churn_map
};
use std::collections::HashMap;

// Option 1: Manual enrichment with pre-computed churn map
let mut churn_map: HashMap<String, (u32, f32)> = HashMap::new();
churn_map.insert("src/api.rs".to_string(), (42, 0.8)); // 42 commits, 80% churn
enrich_with_churn(&mut results, &churn_map);

// Option 2: Automatic churn computation from git
enrich_results_with_churn(&mut results, project_root, 90).await?;
```

| Function | Description |
|----------|-------------|
| `enrich_with_churn` | Enrich results from pre-computed churn map |
| `build_churn_map` | Convert `FileChurnMetrics` to lookup map |
| `enrich_results_with_churn` | Compute churn from git and enrich results |

**Example Output with Graph Metrics:**

```
1. src/contracts/mcp_impl.rs:40 - error
   Signature: pub fn error(id: Value, code: i32, message: String) -> Self
   TDG: A (0.1) | Complexity: 1 | Big-O: O(1)
   Calls: error, code, message, to_string
   Called by: main, serve_mcp, execute_workflow, (+1443 more)
   Graph: PageRank 0.000426 | In-Degree: 4649 | Out-Degree: 46
   Relevance: 0.59
```

The `Graph:` line shows:
- **PageRank**: Importance score (sum to 1.0 across all functions)
- **In-Degree**: Number of functions that call this function
- **Out-Degree**: Number of functions this function calls

## MCP Tools for Agents

Four MCP tools expose the agent context to AI coding agents:

### `pmat_query_code`

Semantic search for code by intent. This is the primary tool agents should use instead of grep.

**Input:**
```json
{
  "query": "error handling in API layer",
  "limit": 5,
  "min_grade": "B",
  "max_complexity": 15,
  "path": "src/",
  "rank_by": "pagerank",
  "min_pagerank": 0.0001
}
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `query` | string | Natural language query (required) |
| `limit` | integer | Maximum results (default: 10) |
| `min_grade` | string | Minimum TDG grade (A, B, C, D, F) |
| `max_complexity` | integer | Maximum cyclomatic complexity |
| `language` | string | Filter by language (rust, python, etc.) |
| `path` | string | Filter by file path pattern |
| `type` | string | Filter by definition type: fn, struct, enum, trait, type |
| `rank_by` | string | Ranking: relevance, pagerank, centrality, indegree |
| `min_pagerank` | float | Minimum PageRank score filter |

**Output:**
```json
[
  {
    "id": "src/api/error.rs::handle_api_error",
    "name": "handle_api_error",
    "file": "src/api/error.rs",
    "line": 42,
    "signature": "pub fn handle_api_error(err: ApiError) -> Response",
    "doc": "Converts API errors to HTTP responses",
    "tdg_grade": "A",
    "tdg_score": 2.1,
    "complexity": 8,
    "big_o": "O(1)",
    "pagerank": 0.000234,
    "in_degree": 156,
    "out_degree": 12,
    "relevance": 0.92
  }
]
```

### `pmat_get_function`

Get full function source with quality metrics by ID.

**Input:**
```json
{
  "file": "src/api/error.rs",
  "function": "handle_api_error",
  "include_callers": false,
  "include_callees": false
}
```

### `pmat_find_similar`

Find functions similar to a given one. Useful for refactoring and deduplication.

**Input:**
```json
{
  "file": "src/api/error.rs",
  "function": "handle_api_error",
  "limit": 5,
  "min_similarity": 0.7
}
```

### `pmat_index_stats`

Check index health and statistics.

**Output:**
```json
{
  "total_functions": 42168,
  "total_files": 1846,
  "avg_tdg_score": 0.3,
  "index_path": ".pmat/context.idx",
  "languages": ["Rust", "TypeScript", "Python"]
}
```

## CB-130: Agent Context Adoption Compliance

`pmat comply check` includes CB-130 to validate that agent context is set up:

```bash
$ pmat comply check
...
CB-130 Agent Context Adoption
  ok  RAG index exists: .pmat/context.idx
  ok  Index is fresh (updated 2 hours ago)
  ok  Index has 42168 functions
  warn  CLAUDE.md does not reference pmat_query_code
```

### What CB-130 Checks

1. **Index exists**: `.pmat/context.idx` file present
2. **Index fresh**: Updated within last 24 hours
3. **Functions indexed**: At least 1 function in the index
4. **CLAUDE.md configured**: References `pmat_query_code` or `pmat query`

### Configuration

In `.pmat.yaml`:

```yaml
comply:
  cb-130:
    enabled: true
    severity: warning
```

## Index Persistence

The index is stored at `.pmat/context.idx` using bincode serialization:

```
.pmat/context.idx     # Serialized AgentContextIndex
```

The index is:
- **Auto-built** on first `pmat query` run
- **Cached** for subsequent queries (loaded from disk)
- **Rebuilt** when running `pmat query` after significant code changes

Add `.pmat/context.idx` to `.gitignore` -- it is machine-specific and regenerated automatically.

## Example: Running the Demo

```bash
cargo run --example agent_context_query_demo
```

This demo shows:
1. Basic semantic search
2. Quality-filtered search (TDG grade + complexity)
3. JSON output for CI/CD
4. Markdown output for documentation
5. Language-filtered search
6. PageRank ranking (most important functions)
7. InDegree ranking (most called functions)
8. Centrality ranking (hub functions)
9. PageRank filter with JSON output
10. Coverage gap analysis (`--coverage-gaps`)
11. Coverage-enriched search (`--coverage`)
12. Regex search (`--regex`, like rg -e)
13. Literal search (`--literal`, like rg -F)
14. Fault pattern search (`--faults`)
15. Multi-enrichment (`--churn --entropy`)
16. Git history fusion (`-G`)

## grep vs pmat query

| Aspect | `grep -r "error" src/` | `pmat query "error handling"` |
|--------|------------------------|-------------------------------|
| **Results** | 500+ line matches | 5-10 ranked functions |
| **Context** | Raw text lines | Full signatures + docs |
| **Quality** | None | TDG grade, complexity, Big-O |
| **Relevance** | Keyword only | Semantic intent matching |
| **Graph** | None | PageRank, in/out degree |
| **Coverage** | None | Line coverage %, missed lines, impact |
| **Enrichment** | None | Churn, duplicates, entropy, faults |
| **Ranking** | Line order | Relevance, PageRank, centrality, impact |
| **Token cost** | High (noise) | Low (signal) |
| **Speed** | O(n) scan | O(1) index lookup |

## Integration with CLAUDE.md

Add the following to your project's `CLAUDE.md` to instruct agents to use `pmat query`:

```markdown
## Agent Context (RAG-Powered Search)

**PREFER `pmat query` and `pmat_query_code` over grep/glob for code search.**

This project has a RAG-indexed context with quality annotations.

### Available Tools

| Tool | Use Case |
|------|----------|
| `pmat query "..."` | CLI semantic search |
| `pmat_query_code` | MCP semantic search |
| `pmat_get_function` | Get function with metrics |
| `pmat_find_similar` | Find similar functions |
```

## Detecting AI-Generated Technical Debt

**NEW in v2.217.0**: AI coding assistants often use euphemisms to hide technical debt. Use `pmat analyze satd --extended` to catch these:

```bash
# Standard SATD detection
pmat analyze satd --path src/
# Result: 89 violations

# Extended mode (catches AI euphemisms)
pmat analyze satd --extended --path src/
# Result: 441 violations (+352 hidden debt)
```

Extended mode detects: `placeholder`, `stub`, `simplified`, `for demo`, `mock`, `dummy`, `fake`, `hardcoded`, `for now`, `WIP`, `skip/bypass`.

See [Chapter 5: Analyze Suite](ch05-00-analyze-suite.md#extended-mode-issue-149) for details.

## Coverage-First Testing Workflow

The recommended workflow for using coverage enrichment in development:

```bash
# Step 1: Run instrumented test build (creates coverage data)
cargo llvm-cov test --lib --no-report

# Step 2: Export coverage JSON
cargo llvm-cov report --json > /tmp/coverage.json

# Step 3: Find highest-impact coverage gaps
pmat query --coverage-gaps --coverage-file /tmp/coverage.json \
  --rank-by impact --limit 20 --exclude-tests

# Step 4: Write tests for top gaps, re-run
cargo llvm-cov test --lib --no-report
pmat query --coverage-gaps --coverage-file /tmp/coverage.json \
  --rank-by impact --limit 20 --exclude-tests

# Step 5: Verify coverage improvement
pmat query "your_module" --coverage --coverage-file /tmp/coverage.json --limit 10
```

Set `PMAT_COVERAGE_FILE` to avoid repeating the path:

```bash
export PMAT_COVERAGE_FILE=/tmp/coverage.json
pmat query --coverage-gaps --rank-by impact --limit 20
```

## Next Steps

- [Chapter 5: Analyze Suite](ch05-00-analyze-suite.md) - SATD extended mode for AI code cleanup
- [Chapter 35: Semantic Search and Code Clustering](ch35-00-semantic-search.md) - Related semantic analysis
- [Chapter 42: ComputeBrick Compliance](ch42-00-computebrick-compliance.md) - CB-130 and other checks
- [Appendix B: Command Reference](appendix-b-commands.md) - Full CLI reference
