# Chapter 54: Function Boundary Extraction (`pmat extract`)

## Overview

The `pmat extract` command provides direct tree-sitter AST parsing of individual files, outputting function boundaries as structured JSON. Unlike `pmat query` which requires an index, `extract` works on any single file with zero setup — making it ideal for editor integrations, CI scripts, automated file splitting, and quick structural analysis.

Since v3.3.0, the output includes file-level metadata (imports, test boundaries) and per-item visibility — everything needed to split large files into compilable parts.

## Usage

```bash
# Extract all function/struct/enum/trait boundaries from a file
pmat extract --list src/main.rs

# Pipe to jq for analysis
pmat extract --list src/handlers.rs | jq '.items[] | select(.type == "function")'

# Count items by type
pmat extract --list src/lib.rs | jq '.items | group_by(.type) | map({type: .[0].type, count: length})'

# Find largest functions (by line count)
pmat extract --list src/parser.rs | jq '.items | sort_by(-.lines) | .[0:5]'

# List all imports
pmat extract --list src/lib.rs | jq '.imports[]'

# Find public functions only
pmat extract --list src/lib.rs | jq '.items[] | select(.visibility == "pub" and .type == "function")'

# Get test module boundary
pmat extract --list src/lib.rs | jq '.cfg_test_line'
```

## Output Format

The output is a JSON object with file-level metadata and an items array:

### Top-Level Fields

| Field | Type | Description |
|-------|------|-------------|
| `file` | string | File path as provided |
| `language` | string | Detected language (`rust`, `typescript`, `python`, `c`, `cpp`, `go`, `lua`) |
| `imports` | string[] | Top-level import/use statements (full text) |
| `cfg_test_line` | number? | Line where `#[cfg(test)]` appears (Rust only, absent if none) |
| `items` | object[] | Extracted code items |

### Item Fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Function/struct/enum/trait name |
| `type` | string | One of: `function`, `struct`, `enum`, `trait`, `impl`, `class`, `module`, `type_alias` |
| `start_line` | number | First line (1-indexed) |
| `end_line` | number | Last line (inclusive) |
| `lines` | number | Total line count (`end_line - start_line + 1`) |
| `visibility` | string | Visibility: `pub`, `pub(crate)`, `pub(super)`, `export`, or `""` (private) |

### Visibility by Language

| Language | Public | Crate-scoped | Private |
|----------|--------|-------------|---------|
| Rust | `"pub"` | `"pub(crate)"`, `"pub(super)"` | `""` |
| TypeScript | `"export"` | — | `""` |
| Go | `"pub"` (uppercase name) | — | `""` (lowercase name) |
| Python, C, C++, Lua | — | — | `""` (always) |

### Example Output

```bash
$ pmat extract --list src/cache.rs
```

```json
{
  "file": "src/cache.rs",
  "language": "rust",
  "imports": [
    "use std::collections::HashMap;"
  ],
  "cfg_test_line": 42,
  "items": [
    {
      "name": "Cache",
      "type": "struct",
      "start_line": 4,
      "end_line": 8,
      "lines": 5,
      "visibility": "pub"
    },
    {
      "name": "Cache",
      "type": "class",
      "start_line": 10,
      "end_line": 30,
      "lines": 21,
      "visibility": ""
    },
    {
      "name": "new",
      "type": "function",
      "start_line": 11,
      "end_line": 17,
      "lines": 7,
      "visibility": "pub"
    },
    {
      "name": "get",
      "type": "function",
      "start_line": 19,
      "end_line": 23,
      "lines": 5,
      "visibility": "pub"
    },
    {
      "name": "evict_expired",
      "type": "function",
      "start_line": 25,
      "end_line": 29,
      "lines": 5,
      "visibility": ""
    }
  ]
}
```

## Supported Languages

| Language | Extensions | Imports Detected | Visibility |
|----------|-----------|-----------------|------------|
| Rust | `.rs` | `use`, `extern crate` | `pub`, `pub(crate)`, `pub(super)` |
| TypeScript/JavaScript | `.ts`, `.tsx`, `.js`, `.jsx`, `.mjs` | `import` | `export` |
| Python | `.py`, `.pyi` | `import`, `from ... import` | — |
| C | `.c`, `.h` | `#include` | — |
| C++ | `.cpp`, `.cc`, `.cxx`, `.hpp`, `.hxx` | `#include` | — |
| Go | `.go` | `import` | Uppercase = exported |
| Lua | `.lua` | — | — |

## Use Cases

### Automated File Splitting

The primary motivation for rich metadata: split large files while preserving compilability.

```bash
# Extract boundaries for a large file
pmat extract --list src/big_module.rs > boundaries.json

# A splitting tool can:
# 1. Read imports → prepend to each split part
# 2. Read cfg_test_line → separate test code from production code
# 3. Read visibility → determine which items belong in the public API
```

### Editor Integration

Extract function boundaries for jump-to-definition or outline views:

```bash
# Get function list for editor sidebar
pmat extract --list "$FILE" | jq '[.items[] | {name, type, line: .start_line, visibility}]'
```

### CI Pipeline — File Complexity Gate

```bash
# Fail if any function exceeds 100 lines
MAX_LINES=100
pmat extract --list src/handler.rs | \
  jq --argjson max "$MAX_LINES" '[.items[] | select(.type == "function" and .lines > $max)]' | \
  jq -e 'length == 0' || { echo "Functions exceed $MAX_LINES lines"; exit 1; }
```

### API Surface Analysis

```bash
# List all public functions across a crate
for f in src/**/*.rs; do
  pmat extract --list "$f" | \
    jq --arg file "$f" '.items[] | select(.visibility == "pub" and .type == "function") | {file: $file, name}'
done
```

### Compare File Structure Across Versions

```bash
# Before refactoring
pmat extract --list src/old.rs > before.json

# After refactoring
pmat extract --list src/new.rs > after.json

# Diff item names
diff <(jq '.items[].name' before.json) <(jq '.items[].name' after.json)
```

### Feed into `pmat context --format json`

The `extract` command complements `context --format json` (see Chapter 2). While `context` provides project-wide structure with quality metrics, `extract` provides per-file granularity with exact line boundaries:

```bash
# Project-level overview
pmat context --format json -p . | jq '.files | length'

# File-level detail
pmat extract --list src/main.rs | jq '.items | length'
```

## Running the Example

```bash
cargo run --example extract_demo
```

This demonstrates extraction across Rust, Python, and TypeScript files with imports, visibility, and test boundary detection.
