# Chapter 54: Function Boundary Extraction (`pmat extract`)

## Overview

The `pmat extract` command provides direct tree-sitter AST parsing of individual files, outputting function boundaries as structured JSON. Unlike `pmat query` which requires an index, `extract` works on any single file with zero setup — making it ideal for editor integrations, CI scripts, and quick structural analysis.

## Usage

```bash
# Extract all function/struct/enum/trait boundaries from a file
pmat extract --list src/main.rs

# Pipe to jq for analysis
pmat extract --list src/handlers.rs | jq '.[] | select(.type == "function")'

# Count items by type
pmat extract --list src/lib.rs | jq 'group_by(.type) | map({type: .[0].type, count: length})'

# Find largest functions (by line count)
pmat extract --list src/parser.rs | jq 'sort_by(-.lines) | .[0:5]'
```

## Output Format

Each item in the JSON array contains:

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Function/struct/enum/trait name |
| `type` | string | One of: `function`, `struct`, `enum`, `trait`, `impl`, `class`, `module`, `type_alias` |
| `start_line` | number | First line (1-indexed) |
| `end_line` | number | Last line (inclusive) |
| `lines` | number | Total line count (`end_line - start_line + 1`) |

### Example Output

```bash
$ pmat extract --list src/cache.rs
```

```json
[
  {
    "name": "Cache",
    "type": "struct",
    "start_line": 5,
    "end_line": 9,
    "lines": 5
  },
  {
    "name": "Cache",
    "type": "impl",
    "start_line": 11,
    "end_line": 30,
    "lines": 20
  },
  {
    "name": "new",
    "type": "function",
    "start_line": 12,
    "end_line": 18,
    "lines": 7
  },
  {
    "name": "get",
    "type": "function",
    "start_line": 20,
    "end_line": 24,
    "lines": 5
  },
  {
    "name": "insert",
    "type": "function",
    "start_line": 26,
    "end_line": 29,
    "lines": 4
  }
]
```

## Supported Languages

| Language | Extensions |
|----------|-----------|
| Rust | `.rs` |
| TypeScript/JavaScript | `.ts`, `.tsx`, `.js`, `.jsx`, `.mjs` |
| Python | `.py`, `.pyi` |
| C | `.c`, `.h` |
| C++ | `.cpp`, `.cc`, `.cxx`, `.hpp`, `.hxx` |
| Go | `.go` |
| Lua | `.lua` |

## Use Cases

### Editor Integration

Extract function boundaries for jump-to-definition or outline views:

```bash
# Get function list for editor sidebar
pmat extract --list "$FILE" | jq '[.[] | {name, type, line: .start_line}]'
```

### CI Pipeline — File Complexity Gate

```bash
# Fail if any function exceeds 100 lines
MAX_LINES=100
pmat extract --list src/handler.rs | \
  jq --argjson max "$MAX_LINES" '[.[] | select(.type == "function" and .lines > $max)]' | \
  jq -e 'length == 0' || { echo "Functions exceed $MAX_LINES lines"; exit 1; }
```

### Compare File Structure Across Versions

```bash
# Before refactoring
pmat extract --list src/old.rs > before.json

# After refactoring
pmat extract --list src/new.rs > after.json

# Diff
diff <(jq '.[].name' before.json) <(jq '.[].name' after.json)
```

### Feed into `pmat context --format json`

The `extract` command complements `context --format json` (see Chapter 2). While `context` provides project-wide structure with quality metrics, `extract` provides per-file granularity with exact line boundaries:

```bash
# Project-level overview
pmat context --format json -p . | jq '.files | length'

# File-level detail
pmat extract --list src/main.rs | jq 'length'
```

## Running the Example

```bash
cargo run --example extract_demo
```

This demonstrates extraction across Rust, Python, and TypeScript files.
