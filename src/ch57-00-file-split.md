# Chapter 57: File Splitting (`pmat split`)

The `pmat split` command analyzes large source files and suggests semantically coherent splits using Louvain community detection on the intra-file function call graph. Each suggested cluster receives a meaningful name derived from signal analysis (dominant types, function themes, common prefixes, doc comment consensus).

## Why Split Files?

Research shows files exceeding 500 lines exhibit exponential defect density increase (Hindle et al., 2008). PMAT enforces file health through:

1. **Pre-commit hooks** — block new files >500 lines and growth past the threshold
2. **`pmat split`** — provides actionable guidance on *how* to split, not just *that* you should

## Quick Start

```bash
# Analyze a file (dry-run, shows split plan)
pmat split src/services/file_health.rs

# JSON output for CI/CD
pmat split src/services/file_health.rs --format json

# Execute: create split files with include!() pattern
pmat split src/services/file_health.rs --execute

# Tune clustering: more granular clusters
pmat split src/services/file_health.rs --resolution 1.5 --min-cluster-lines 30
```

## Algorithm

The split algorithm follows five steps:

1. **Index Lookup** — Retrieves all function/struct/enum/trait entries for the target file from the agent context index
2. **Call Graph Construction** — Builds an undirected graph where nodes are definitions and edges represent intra-file call relationships
3. **Community Detection** — Runs Louvain modularity optimization (via `aprender`) to find cohesive clusters. For files with <10 functions, falls back to connected components
4. **Cluster Naming** — Names each cluster using a signal cascade:
   - **DominantType**: A single struct/enum/trait dominates the cluster
   - **FunctionTheme**: >70% of functions share a keyword theme
   - **CommonPrefix**: Longest common prefix across function names (min 4 chars)
   - **DocCommentConsensus**: Dominant keyword from doc comments
   - **ContextWord**: Most frequent non-trivial word in function names
5. **Impact Analysis** — Scans the index for files that import functions from the target file

## Output Format

### Text (Default)

```
Split Plan for: src/services/file_health.rs
Total lines: ~468
Modularity: 0.412
Clusters: 3
Unclustered items: 2

Cluster 1 — baseline (signal: FunctionTheme, confidence: 80%)
  ~120 lines, cohesion: 0.67
    Struct FileHealthBaseline (L310-L316)
    Function new (L328-L333)
    Function add_file (L336-L348)
    Function save (L350-L353)
    Function load (L355-L359)
    Function check_ratchet (L362-L375)
```

### JSON

Use `--format json` for programmatic consumption. The JSON includes all clusters, items, line ranges, cohesion scores, and impact data.

## Flags Reference

| Flag | Default | Description |
|------|---------|-------------|
| `file` | (required) | Source file to analyze |
| `-p, --path` | `.` | Project root directory |
| `--execute` | false | Create split files (default is dry-run) |
| `-f, --format` | `text` | Output format: `text` or `json` |
| `-o, --output` | stdout | Write output to file |
| `--min-cluster-lines` | `50` | Minimum lines for a cluster |
| `--resolution` | `1.0` | Louvain resolution (higher = more clusters) |

## Integration with Pre-Commit Hooks

The TDG pre-commit hook (`pmat hooks install --tdg-enforcement`) automatically checks file health:

- **New files >500 lines**: Blocked. Error message suggests `pmat split <file>`
- **Existing files growing past 500 lines**: Blocked with ratchet enforcement
- **Files 400-500 lines**: Warning displayed

When a file is blocked, run `pmat split <file>` to see the recommended split plan, then `pmat split <file> --execute` to create the cluster files.

## Cross-Stack Health (`pmat comply check --include-project`)

For multi-project workspaces, use `--include-project` to check file health across the stack:

```bash
# Check file health across primary project + siblings
pmat comply check --include-project ../aprender --include-project ../trueno
```

This produces a **Stack Health Report** with:
- Per-project grade and average health score
- Top-10 worst files across all projects
- Overall stack grade

## Example

```bash
# Run the built-in demo
cargo run --example split_demo
```

## See Also

- [Chapter 56: Compliance Governance](ch56-00-comply.md) — `pmat comply check` with `--include-project`
- [Pre-commit hook template](../templates/hooks/pre-commit-tdg.sh) — File health enforcement
- [File Health Specification](../docs/specifications/max-lines.md) — Scientific foundation
