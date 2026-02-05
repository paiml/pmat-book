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
  "path": "src/"
}
```

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

## grep vs pmat query

| Aspect | `grep -r "error" src/` | `pmat query "error handling"` |
|--------|------------------------|-------------------------------|
| **Results** | 500+ line matches | 5-10 ranked functions |
| **Context** | Raw text lines | Full signatures + docs |
| **Quality** | None | TDG grade, complexity, Big-O |
| **Relevance** | Keyword only | Semantic intent matching |
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
