# Chapter 58: Extract Candidates (`--extract-candidates`)

The `pmat query --extract-candidates` flag scans all functions in your codebase, classifies each as **PURE** (no I/O) or **IO** (prints, filesystem, network, database, etc.), groups them by name prefix and call graph clusters, and suggests module extractions.

## Why Extract Candidates?

When refactoring large files (e.g., a 16K-line `commands.rs` with 346 functions), developers manually inspect each function to classify as pure-logic (extractable) vs I/O-heavy (must stay as stub). `--extract-candidates` automates this classification and grouping.

**Key insight**: Pure functions are easier to test, reason about, and extract into separate modules. I/O functions often need to stay in place as thin stubs that delegate to the extracted pure logic.

## Quick Start

```bash
# Find top extraction candidates
pmat query --extract-candidates --limit 10

# Scope to a specific directory
pmat query --extract-candidates --path src/cli --exclude-tests

# JSON output for CI/CD
pmat query --extract-candidates --format json --limit 5

# Limit suggested module size
pmat query --extract-candidates --max-module-lines 300

# Markdown for reports
pmat query --extract-candidates --format markdown --limit 10
```

## I/O Classification

Each function's source is scanned for 20+ I/O patterns across 8 categories:

| Category | Patterns | Label |
|----------|----------|-------|
| Print | `println!`, `print!` | PRINT |
| Error Print | `eprintln!`, `eprint!` | EPRINT |
| Write | `write!`, `writeln!` | WRITE |
| Filesystem | `std::fs::`, `File::open`, `File::create`, `OpenOptions` | FS |
| Process | `std::process::Command`, `Command::new` | PROCESS |
| Stdio | `std::io::stdin`, `stdout()`, `stderr()` | STDIN/STDOUT/STDERR |
| Network | `reqwest::`, `hyper::`, `tokio::net::` | HTTP/NET |
| Database | `sqlx::`, `rusqlite::`, `Connection::open` | DB |

Functions with **zero** detected patterns are classified as **PURE**. Functions with one or more patterns are classified as **IO** with the specific pattern labels listed.

## Grouping Signals

Functions are grouped using two complementary signals:

### 1. Name Prefix Grouping

Functions sharing a common prefix before the first `_` are grouped together. Requirements:
- Prefix must be longer than 2 characters
- Group must have 3+ members
- Only functions (not structs/enums/traits)

Example: `parse_header`, `parse_body`, `parse_footer` → group `parse`

### 2. Call Graph Clustering

Functions in the same file that call each other are grouped into clusters. Requirements:
- Functions must be co-located (same file)
- Must have direct call relationships
- Group must have 3+ members

## Output Formats

### Text (Default)

```text
Extract Candidates (5 groups)

  1. parse (12 fns, 500 LOC, 91% pure) [prefix]
     from: src/cli/handlers/deps_audit_handlers.rs
       126: parse_cargo_lock [PURE] (47 LOC, [A])
       158: parse_apr_header [PURE] (48 LOC, [A])
       193: parse_with_suggestions [IO: PRINT] (43 LOC, [A])
       207: parse_safetensors_header [PURE] (47 LOC, [A])
       ...
```

Each group shows:
- **Module name**: suggested extraction target
- **Function count and total LOC**
- **Purity percentage**: ratio of PURE to total functions
- **Grouping signal**: `prefix` or `call_cluster`
- Per-function: line number, name, `[PURE]`/`[IO: patterns]` badge, LOC, TDG grade

### JSON

```bash
pmat query --extract-candidates --format json --limit 2
```

```json
[
  {
    "module_name": "parse",
    "source_file": "src/cli/handlers/deps_audit_handlers.rs",
    "functions": [
      {
        "function_name": "parse_cargo_lock",
        "file_path": "src/cli/handlers/deps_audit_handlers.rs",
        "start_line": 126,
        "loc": 47,
        "io_classification": "PURE",
        "io_patterns": [],
        "complexity": 8,
        "tdg_grade": "A"
      }
    ],
    "total_loc": 500,
    "pure_count": 11,
    "io_count": 1,
    "grouping_signal": "prefix"
  }
]
```

### Markdown

```bash
pmat query --extract-candidates --format markdown --limit 2
```

Produces tables suitable for documentation and pull request descriptions.

## Options

| Flag | Description | Default |
|------|-------------|---------|
| `--extract-candidates` | Enable extraction analysis mode | — |
| `--max-module-lines N` | Maximum LOC per suggested module | 500 |
| `--limit N` | Maximum number of groups to show | 10 |
| `--path PATTERN` | Filter functions by file path | — |
| `--language LANG` | Filter by programming language | — |
| `--exclude-tests` | Exclude test functions | false |
| `--format FORMAT` | Output format: text, json, markdown | text |

## Use Cases

### 1. Refactoring Large Files

```bash
# Find extractable groups in a large file
pmat query --extract-candidates --path src/cli/commands/mod.rs --exclude-tests

# Review groups with high purity (easy to extract)
# Groups with 80%+ pure functions are ideal extraction targets
```

### 2. Architecture Review

```bash
# Find I/O boundaries across the codebase
pmat query --extract-candidates --limit 20 --format json | \
  jq '[.[] | {module: .module_name, pure_pct: (.pure_count * 100 / (.functions | length))}]'
```

### 3. CI/CD Quality Gate

```bash
# Fail if any file has >500 LOC of extractable pure functions
pmat query --extract-candidates --format json --max-module-lines 500 | \
  jq 'if length > 0 then error("Extraction candidates found") else empty end'
```

### 4. Migration Planning

```bash
# Identify pure-logic modules that can be extracted to a shared library
pmat query --extract-candidates --exclude-tests --format markdown > extraction-plan.md
```

## Algorithm

1. **Load Source** — `load_all_source()` fetches function source from SQLite
2. **Load Call Graph** — `ensure_call_graph()` loads caller/callee relationships
3. **Build Results** — Creates `QueryResult` with graph metrics and call context
4. **Filter** — Apply language, path, and test exclusion filters
5. **Classify I/O** — Scan each function's source for I/O patterns
6. **Group by Prefix** — Functions sharing name prefix before first `_` (3+ members)
7. **Group by Call Cluster** — Co-located functions with call relationships (3+ members)
8. **Build Groups** — Merge groupings, enforce `max_module_lines`, sort by LOC descending

## Example

Run the demo:

```bash
cargo run --example extract_candidates_demo
```
