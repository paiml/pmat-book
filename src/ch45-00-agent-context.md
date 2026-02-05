# Chapter 45: RAG-Powered Agent Context

**Chapter Status**: Working

*PMAT version: pmat 2.216.0*

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

## grep vs pmat query

| Aspect | `grep -r "error" src/` | `pmat query "error handling"` |
|--------|------------------------|-------------------------------|
| **Results** | 500+ line matches | 5-10 ranked functions |
| **Context** | Raw text lines | Full signatures + docs |
| **Quality** | None | TDG grade, complexity, Big-O |
| **Relevance** | Keyword only | Semantic intent matching |
| **Graph** | None | PageRank, in/out degree |
| **Ranking** | Line order | Relevance, PageRank, centrality |
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

## Next Steps

- [Chapter 35: Semantic Search and Code Clustering](ch35-00-semantic-search.md) - Related semantic analysis
- [Chapter 42: ComputeBrick Compliance](ch42-00-computebrick-compliance.md) - CB-130 and other checks
- [Appendix B: Command Reference](appendix-b-commands.md) - Full CLI reference
