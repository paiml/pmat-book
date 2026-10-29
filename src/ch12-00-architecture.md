# Chapter 12: Architecture Analysis

> **⚠️ Superseded, as of pmat 3.32.0 (2026-08-25). `pmat` has no
> `architecture` subcommand, and never has had one.**
>
> This chapter used to document nineteen of them — `architecture analyze`,
> `deps`, `graph`, `validate-layers`, `patterns`, `microservices`, `ddd`,
> `coupling`, `cohesion`, `evolution`, `compare`, `track`, `debt-analysis`,
> `debt-check`, `adr-suggest`, `legacy-assessment`, `review-package`, `report`
> and `validate` — 39 examples in total, along with a `.pmat/architecture.yaml`
> layer-definition format, a `.pmat/microservices.yaml`, a
> `.pmat/patterns/custom-patterns.yaml` and a `.pmat/architecture-exceptions.yaml`.
>
> **None of it ever shipped.** There is no `Architecture` clap variant in any
> commit of pmat's history; the only thing carrying the name is an internal
> `AnalyzeSystemArchitectureArgs` struct for an MCP handler that is not among
> the 19 tools `tools/list` exposes in 3.32.0 either. Every one of those YAML
> files is read by nothing. The chapter's own test script,
> `tests/ch12/test_architecture.sh`, wrote five of them and then asserted that
> the files it had just written existed — it never invoked `pmat`, and it
> passed for a year while the commands it "validated" all exited
> `error: unrecognized subcommand`.
>
> The old status badge claiming "✅ 100% Working (8/8 examples)" has been
> removed, and that test script has been rewritten to run the real binary
> against a real fixture: 19 assertions, each checked to go red when the claim
> behind it is false.
>
> pmat *does* analyze structure — through the dependency graph, churn
> bottlenecks, duplication and community detection. Those commands are
> documented below, and every example was executed against `pmat 3.32.0`.

*What structural analysis `pmat` really offers, what it deliberately does not,
and how to tell the difference.*

## Translation Table

If you arrived from a bookmark, this is what the command you were looking for
maps onto:

| Old (fictional) | Real command in pmat 3.32.0 |
|-----------------|------------------------------|
| `architecture deps`, `architecture graph` | `pmat analyze dag` |
| `architecture analyze` | `pmat analyze deep-context`, `pmat context` |
| `architecture debt-analysis`, `debt-check` | `pmat tdg`, `pmat analyze satd` |
| `architecture cohesion` | `pmat split` (Louvain modularity) |
| `architecture coupling` | partially: edge counts from `pmat analyze dag` |
| `architecture patterns` | *no equivalent* |
| `architecture validate-layers` | *no equivalent* |
| `architecture ddd` | *no equivalent* |
| `architecture microservices` | *no equivalent* |
| `architecture evolution`, `compare`, `track` | partially: `pmat analyze bottleneck` (churn) |
| `architecture adr-suggest`, `legacy-assessment`, `review-package` | *no equivalent* |

"*No equivalent*" means exactly that. `pmat` has no notion of an architectural
layer, a bounded context, a design pattern or a service boundary, and cannot be
configured to acquire one. If you need layer enforcement, use a tool built for
it (`cargo-modules`, `import-linter`, ArchUnit) and gate it separately.

## The Dependency Graph: `pmat analyze dag`

This is the real core of the chapter. It walks the AST, builds a dependency
graph and emits Mermaid.

### A Fixture

```bash
mkdir -p arch/src/{api,domain,store} && cd arch
cat > Cargo.toml << 'EOF'
[package]
name = "arch"
version = "0.1.0"
edition = "2021"
EOF
cat > src/lib.rs << 'EOF'
pub mod api;
pub mod domain;
pub mod store;
EOF
cat > src/api/mod.rs << 'EOF'
use crate::domain::User;
use crate::store::load;

pub fn handler(id: u32) -> Option<User> {
    load(id)
}
EOF
cat > src/domain/mod.rs << 'EOF'
pub struct User {
    pub id: u32,
    pub name: String,
}

impl User {
    pub fn label(&self) -> String {
        format!("{}#{}", self.name, self.id)
    }
}
EOF
cat > src/store/mod.rs << 'EOF'
use crate::domain::User;

pub fn load(id: u32) -> Option<User> {
    if id == 0 {
        return None;
    }
    Some(User { id, name: "demo".into() })
}
EOF
```

### The Default Graph

```bash
pmat analyze dag -p .
```

```
🔄 Generating dependency analysis graph...
📁 Analyzed 4 files
📊 full-dependency: rendered 10 nodes and 4 edges
graph TD
    src_api_mod[mod]
    src_api_mod_handler[handler]
    src_domain_mod[mod]
    src_domain_mod_User[User]
    src_lib[lib]
    src_lib_api[api]
    src_lib_domain[domain]
    src_lib_store[store]
    src_store_mod[mod]
    src_store_mod_load[load]

    src_api_mod -.-> src_domain_mod
    src_api_mod -.-> src_store_mod
    src_store_mod -.-> src_domain_mod
    src_api_mod_handler --> src_store_mod_load
```

Read the header line before the graph. "*rendered 10 nodes and 4 edges*" is the
number that tells you whether the analysis found your code at all — a graph
with plausible nodes and **zero edges** means the parser saw your files but
resolved none of their references, and that is a failure dressed as a result.

### Four Graph Types

`--dag-type` selects what the edges mean:

| Value | Edges are |
|-------|-----------|
| `full-dependency` (default) | everything below, combined |
| `call-graph` | function calls |
| `import-graph` | module imports |
| `inheritance` | trait/class hierarchy |

An empty result explains itself rather than printing a bare `graph TD`:

```
📊 inheritance: rendered 0 nodes and 0 edges
   (empty: 2 functions across 4 files produced 3 edges in total, none of them Inherits/Implements)
```

The call graph on the fixture is two nodes:

```bash
pmat analyze dag -p . --dag-type call-graph
```

```
📊 call-graph: rendered 2 nodes and 1 edges
graph TD
    src_api_mod_handler[handler]
    src_store_mod_load[load]

    src_api_mod_handler --> src_store_mod_load
```

and the import graph is the module-level view most people mean by
"architecture":

```bash
pmat analyze dag -p . --dag-type import-graph --filter-external
```

```
🔗 --filter-external: dropped 0 external node(s) of 3
📊 import-graph: rendered 3 nodes and 3 edges
graph TD
    src_api_mod[mod]
    src_domain_mod[mod]
    src_store_mod[mod]

    src_api_mod -.-> src_domain_mod
    src_api_mod -.-> src_store_mod
    src_store_mod -.-> src_domain_mod
```

`--filter-external` reports what it dropped rather than silently shrinking the
graph, which is the behaviour you want when you are about to draw a conclusion
from the shape.

### Other Options

| Flag | Effect |
|------|--------|
| `--max-depth <N>` | limit traversal depth |
| `--target-nodes <N>` | apply graph reduction above this node count |
| `--show-complexity` | annotate nodes with complexity metrics |
| `--include-dead-code` | fold dead-code analysis into the graph |
| `--include-duplicates` | fold duplicate detection into the graph |
| `-o, --output <FILE>` | write the Mermaid to a file |

```bash
pmat analyze dag -p . --show-complexity -o dag.mmd
```

```
✅ DAG written to: dag.mmd

💡 To view the graph:
   - Copy content to https://mermaid.live
   - Or use VS Code with Mermaid extension
```

On a large repository, start with `--target-nodes 100`: an unreduced graph of a
few thousand nodes is a Mermaid document no renderer will draw.

### Circular Dependencies: Visible, Not Detected

The old chapter advertised `--circular --fail-on-cycles`. There is no such
flag, and **no `pmat` command detects or fails on a dependency cycle** — the one
exception being a Lua-specific `require()` check inside `pmat comply`.

The graph does render the cycle, which is often enough to see it. Two modules
that use each other:

```bash
mkdir -p cyc/src && cd cyc
cat > Cargo.toml << 'EOF'
[package]
name = "cyc"
version = "0.1.0"
edition = "2021"
EOF
printf 'pub mod a;\npub mod b;\n' > src/lib.rs
cat > src/a.rs << 'EOF'
use crate::b::from_b;
pub fn from_a() -> i32 { from_b() + 1 }
pub fn seed() -> i32 { 1 }
EOF
cat > src/b.rs << 'EOF'
use crate::a::seed;
pub fn from_b() -> i32 { seed() + 1 }
EOF
```

```bash
pmat analyze dag -p . --dag-type import-graph
```

```
📊 import-graph: rendered 2 nodes and 2 edges
graph TD
    src_a[a]
    src_b[b]

    src_b -.-> src_a
    src_a -.-> src_b
```

Both directions are present. Nothing flags it, the exit code is 0, and if you
want a build to fail on this you will have to detect it yourself from the
Mermaid output.

## Architectural Hotspots: `pmat analyze bottleneck`

Where `dag` gives you static structure, `bottleneck` gives you the structure
that is actually costing you — files whose churn is high relative to their
size, computed from git history.

```bash
pmat analyze bottleneck -p . --period 365 --threshold 3
```

Run against this book's own repository:

```
Analyzing git churn for last 365 days...
Architectural Bottleneck Analysis

  Period: 365 days
  Total commits: 153
  Files changed: 216

Bottleneck Files

  1. src/SUMMARY.md (High Churn Ratio)
     Touches: 64  Authors: 1  Lines: 129  Churn ratio: 49.6
     Recommendation: This file changes too often relative to its size — consider architectural refactoring

  2. Makefile (High Churn Ratio)
     Touches: 19  Authors: 1  Lines: 322  Churn ratio: 5.9
     Recommendation: This file changes too often relative to its size — consider architectural refactoring

  3. src/appendix-b-commands.md (Feature Development)
     Touches: 15  Authors: 1  Lines: 474  Churn ratio: 3.2

  4. src/ch13-00-language-examples.md (Monolith)
     Touches: 12  Authors: 1  Lines: 1749  Churn ratio: 0.7
     Recommendation: Split this file into focused submodules with `pmat split --auto`
```

Each file is given a **classification** — `High Churn Ratio`, `Monolith`,
`Feature Development` — and only some classifications carry a recommendation.
`--period` (days, default 30) and `--threshold` (minimum touches, default 5)
control the window; `-f` accepts `table`, `json`, `yaml`, `markdown`, `csv`,
`summary`, `text`, `plain` and `junit`.

This command needs git history. In a shallow clone the numbers will be quietly
smaller rather than absent, so check `Total commits` against reality before
trusting a ranking.

## Modularity: `pmat split`

`pmat split` clusters the functions inside one file by their call graph, using
Louvain community detection, and proposes a split along the communities it
finds. It is the closest thing `pmat` has to a cohesion metric.

```bash
pmat split src/store/mod.rs
```

```
⚠  src/store/mod.rs is 8 lines (under 500-line threshold). Showing plan anyway.
Split Plan for: src/store/mod.rs
Total lines: ~8
Modularity: 0.000
Clusters: 0
Unclustered items: 1

Unclustered:
  Function load (L3-L8)

Impact 1 files import this module:
  src/api/mod.rs
```

Two things here are useful beyond the split itself: **Modularity** is the
Louvain score for the file (0 means no separable communities were found), and
**Impact** is the reverse dependency list — who would be affected if you moved
this code. The default is a dry run; `--execute` creates the files, and
`--auto` scans the whole project:

```bash
pmat split --auto
```

```
Automated File Splitting
Project: /path/to/arch
Threshold: 500 lines

✓  No files exceed 500 lines. Project is well-structured.
```

## Duplication Across Modules

Copy-paste across module boundaries is architectural debt that the dependency
graph cannot show you, because duplicated code has no edge between its copies.

```bash
pmat analyze duplicates -p .
```

```
Analyzing code similarity...
✓  Found 0 duplicate blocks
  Duplication: 0.0% (0 / 27 lines)

Duplicate Code Analysis

Summary
  Total duplicate blocks: 0
  Duplicate lines: 0 / 27
  Duplication percentage: 0.0%

Top Files by Duplication

  1. src/api/mod.rs - 0.0% duplication (0 / 6 lines)
  2. src/domain/mod.rs - 0.0% duplication (0 / 10 lines)
  3. src/lib.rs - 0.0% duplication (0 / 3 lines)
  4. src/store/mod.rs - 0.0% duplication (0 / 8 lines)
```

`--detection-type` selects the clone class — `exact` (Type 1), `renamed`
(Type 2), `gapped` (Type 3), `semantic` (AST similarity), `fuzzy`, or `all`
(default). `--threshold` (default `0.85`), `--min-lines` (default `5`) and
`--max-tokens` (default `128`) tune the matcher.

Note the denominator again: "*0 / 27 lines*". A run that examined 0 lines would
also report 0% duplication.

## A Command to Be Careful With: `pmat analyze graph-metrics`

`pmat analyze graph-metrics` advertises degree/betweenness/closeness
centrality, PageRank (`--metrics page-rank`, not `pagerank`), clustering
coefficient and connected components.

```bash
pmat analyze graph-metrics -p . --metrics page-rank
```

```
📊 Analyzing graph metrics...
✅ Built graph with 4 nodes and 0 edges
Graph Metrics Analysis

Graph Statistics
  Total nodes: 4
  Total edges: 0
  Density: 0.000
  Average degree: 0.00
  Max degree: 0
  Connected components: 4
```

**Zero edges** — on the same tree where `pmat analyze dag` found four. That was
reproduced on every tree tried, including real source directories, and it is
the failure mode described earlier: a graph with no edges makes every
centrality measure trivially zero and every node its own component. The
"✅ Built graph" line is not a verdict on whether the graph is usable.

Until that resolves, take structural centrality from `pmat analyze dag`'s edge
list, or from `pmat query --rank-by pagerank`, which is computed over a
different (working) index.

## Whole-Project Structure

For the "give me everything" view the old chapter's `architecture analyze`
promised, the two real commands are:

```bash
pmat context -p .
```

```
# Project Context

**Language**: rust
**Project Path**: .

## Project Structure

- **Total Files**: 5
- **Total Functions**: 2
- **Median Cyclomatic**: 1.00
- **Median Cognitive**: 0.00

## Quality Scorecard

- **Overall Health**: 100.0%
- **Maintainability Index**: not measured
- **Complexity Score**: 100.0
- **Test Coverage**: N/A
```

and, with defect detection and a machine-readable shape:

```bash
pmat analyze deep-context -p . --format json -o deep-context.json
```

whose top-level keys are `summary`, `files` and `recommendations`. `--format`
also accepts `markdown` and `sarif`, and `--dag-type` selects the same four
graph types as above. See [Deep Context Analysis](ch16-00-deep-context.md) for
the full treatment.

## Summary

| The old chapter said | pmat 3.32.0 |
|----------------------|-------------|
| 19 `architecture` subcommands | No `architecture` subcommand has ever existed |
| `.pmat/architecture.yaml` layer rules | Read by nothing |
| `.pmat/microservices.yaml` | Read by nothing |
| `.pmat/patterns/custom-patterns.yaml` | Read by nothing |
| Circular-dependency detection, `--fail-on-cycles` | Cycles are drawn, never flagged |
| Design-pattern detection | No equivalent |
| DDD bounded-context analysis | No equivalent |
| ADR suggestions, legacy assessment | No equivalent |
| HTML/SVG/PNG architecture reports | Mermaid text only |
| "✅ 100% Working (8/8 examples)" | The test never invoked `pmat`; badge removed |

What survives is a smaller, real toolkit: a dependency graph you can render, a
churn-weighted hotspot list, a modularity score with reverse dependencies, and
cross-module duplication. Used together they answer most of the questions the
fictional commands claimed to — they just will not enforce an architecture you
have not written down somewhere else.

## Related Chapters

- [The Analyze Command Suite](ch05-00-analyze-suite.md)
- [Deep Context Analysis](ch16-00-deep-context.md)
- [Custom Quality Rules](ch11-00-custom-rules.md) — what you can actually gate on
- [Graph Statistics and Network Analysis](ch26-00-graph-statistics.md)
