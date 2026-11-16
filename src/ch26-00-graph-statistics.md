# Chapter 26: Graph Statistics and Network Analysis

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ Verified against pmat 3.44.0 (except `--pagerank-seeds`, see Example 7)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 16 | Executed against pmat 3.44.0; output pasted verbatim |
| ⚠️ Not Implemented | 0 | — |
| ❌ Broken | 1 | `--pagerank-seeds` is accepted but does not change the scores (reported upstream) |
| 📋 Planned | 0 | — |

*Last updated: 2026-11-16*
*PMAT version: pmat 3.44.0*
<!-- DOC_STATUS_END -->

> **What changed in this rewrite.** The 2025 edition of this chapter documented
> twenty-two flags that `pmat analyze graph-metrics` has never accepted
> (`--pagerank-damping`, `--community-resolution`, `--quality-assessment`,
> `--hotspot-detection`, `--parallel`, `--cache-enabled`, `--incremental`,
> `--sample-ratio`, `--memory-limit`, …), a metric name (`community`) that is not
> in the enum, and a subcommand (`pmat analyze graph-trends`) that does not exist.
> Every one of those examples exited 2 with a clap error. They are gone rather
> than guessed at. Three specific corrections worth calling out, because the old
> text asserted the opposite:
>
> - **The metric is `page-rank`, not `pagerank`.** `--metrics pagerank` is
>   rejected: "one of the values isn't valid for an argument".
> - **`pmat context` does not emit graph statistics.** There is no "Graph
>   Analysis Results" section, no PageRank table and no community listing in its
>   output. See Example 1 for what it actually prints.
> - **The GraphML export carries labels only** — no `pagerank`, `community` or
>   `complexity` data keys. See Example 6 for the real file.
>
> Louvain community detection is real in pmat, but it lives in `pmat split`, not
> in `graph-metrics`, and it clusters *functions within one file*. See
> Example 9.

## The Problem

Understanding code architecture means knowing which files everything else leans
on. `pmat analyze graph-metrics` builds a directed dependency graph from a
project's imports and reports standard network measures over it: degree,
betweenness and closeness centrality, PageRank, clustering coefficient and
connected components.

This chapter documents exactly what that command computes, on a project small
enough that you can check the arithmetic by hand.

## The Worked Example

Every command below runs from the root of this five-file Rust crate:

```
src/lib.rs     pub mod core; pub mod api; pub mod utils;
src/core.rs    use crate::utils;
src/api.rs     use crate::core; use crate::utils; pub fn handle() {} pub fn health() {}
src/utils.rs   (empty)
src/main.rs    fn main() {}
```

`pmat` resolves this to **11 nodes and 3 edges**. The nodes are the five files
(`src_lib`, `src_core`, `src_api`, `src_utils`, `src_main`), the three functions
(`src_api::handle`, `src_api::health`, `src_main::main`) and the three
`pub mod` declarations in `lib.rs` (`src_lib::core`, `src_lib::api`,
`src_lib::utils`). The three edges are the `use crate::…` statements:
`api → core`, `api → utils` and `core → utils`. The `pub mod` declarations make
nodes but **no edges**, so `in_degree` counts "who imports me" and `out_degree`
counts "what do I import". Eight of the eleven nodes have no edge at all, which
is why the graph falls into 9 connected components (the one chain above plus
eight isolated nodes). Keep that in mind before reading architectural meaning
into a score.

## Core Concepts

### What the metrics mean here

| Metric | `--metrics` value | Computed |
|--------|-------------------|----------|
| Degree centrality | `centrality` | (in + out) / (n − 1) |
| Betweenness centrality | `betweenness` | Fraction of shortest paths through the node |
| Closeness centrality | `closeness` | Inverse mean distance to reachable nodes |
| PageRank | `page-rank` | Power iteration, damping 0.85 by default |
| Clustering coefficient | `clustering` | Triangle density around the node |
| Connected components | `components` | Weakly connected component id |
| All of the above | `all` (default) | — |

A metric you do not request is reported as `n/a` in text and `null` in JSON —
it is not computed, not computed-and-zero. That distinction matters when you
are parsing the JSON.

## Practical Examples

### Example 1: What `pmat context` actually gives you

The old edition opened by claiming `pmat context` prints graph statistics. It
does not. Here is the whole head of its output on the worked example:

```bash
pmat context --output deep_analysis.md
```

```markdown
# Project Context

**Language**: rust
**Project Path**: .

## Project Structure

- **Total Files**: 5
- **Total Functions**: 3
- **Median Cyclomatic**: 1.00
- **Median Cognitive**: 0.00

## Quality Scorecard

- **Overall Health**: 100.0%
- **Maintainability Index**: not measured
- **Complexity Score**: 100.0
- **Test Coverage**: N/A

## Files

### ./src/api.rs

**File Complexity**: 1 | **Functions**: 2

- **Function**: `handle` [complexity: 1] [cognitive: 0] [big-o: O(1)] [satd: 0] [churn: low(1)]
- **Function**: `health` [complexity: 1] [cognitive: 0] [big-o: O(1)] [satd: 0] [churn: low(1)]

### ./src/core.rs
```

No PageRank, no communities. `grep -i pagerank deep_analysis.md` returns
nothing. For graph statistics you need `analyze graph-metrics`, below.

`--skip-expensive-metrics` is real and skips TDG and complexity analysis:

```bash
pmat context --skip-expensive-metrics
```

### Example 2: The default run

With no flags, `graph-metrics` computes all metrics and prints the summary
format:

```bash
pmat analyze graph-metrics
```

```
📊 Analyzing graph metrics...
✅ Built graph with 11 nodes and 3 edges
Graph Metrics Analysis

Graph Statistics
  Total nodes: 11
  Total edges: 3
  Density: 0.055
  Average degree: 0.55
  Max degree: 2
  Connected components: 9
```

`--format summary` is the default. It stops at the aggregate. To see per-node
scores you need `--format detailed`, `json`, `csv` or `markdown`.

Density here is `2 × edges / (nodes × (nodes − 1))` = 6 / 110 = 0.055, and the
average degree is `2 × edges / nodes` = 6 / 11 = 0.55. Both are low because
eight of the eleven nodes have no edge at all.

### Example 3: PageRank, per node

```bash
pmat analyze graph-metrics --metrics page-rank --format detailed
```

```
📊 Analyzing graph metrics...
✅ Built graph with 11 nodes and 3 edges
Graph Metrics Analysis

Graph Statistics
  Total nodes: 11
  Total edges: 3
  Density: 0.055
  Average degree: 0.55
  Max degree: 2
  Connected components: 9

Top Nodes by Centrality

  1. src_utils
     Degree: 0.200 (in: 2, out: 0)
     Betweenness: n/a
     Closeness: n/a
     PageRank: 0.202
     Clustering: n/a
     Component: n/a

  2. src_core
     Degree: 0.200 (in: 1, out: 1)
     Betweenness: n/a
     Closeness: n/a
     PageRank: 0.109
     Clustering: n/a
     Component: n/a

  3. src_api
     Degree: 0.200 (in: 0, out: 2)
     Betweenness: n/a
     Closeness: n/a
     PageRank: 0.077
     Clustering: n/a
     Component: n/a


Ranked by PageRank

  1. src_utils 0.202
  2. src_core 0.109
  3. src_api 0.077

Ranked by Betweenness

  not computed — add it to --metrics (or use --metrics all)

Ranked by Closeness

  not computed — add it to --metrics (or use --metrics all)

Ranked by Clustering

  not computed — add it to --metrics (or use --metrics all)

Ranked by Degree

  1. src_api 0.200
  2. src_core 0.200
  3. src_utils 0.200
```

The `n/a` entries show that only
`page-rank` was requested, so only PageRank and the always-present degree are
filled in. Degree centrality is `(in + out) / (nodes − 1)` = 2 / 10 = 0.200 for
all three connected nodes, so the "Ranked by Degree" list is a three-way tie
broken by name.

Notice that `src_utils` has the *highest* PageRank and `src_api` the *lowest*.
PageRank flows along incoming edges: `src_utils` is imported by both other
modules, while nothing imports `src_api`. That is the right answer for a
dependency graph: the most depended-on file ranks first.

### Example 4: Every metric at once

```bash
pmat analyze graph-metrics --metrics all --format detailed
```

```
📊 Analyzing graph metrics...
✅ Built graph with 11 nodes and 3 edges
Graph Metrics Analysis

Graph Statistics
  Total nodes: 11
  Total edges: 3
  Density: 0.055
  Average degree: 0.55
  Max degree: 2
  Connected components: 9

Top Nodes by Centrality

  1. src_api
     Degree: 0.200 (in: 0, out: 2)
     Betweenness: 0.000
     Closeness: 0.200
     PageRank: 0.077
     Clustering: 1.000
     Component: 0

  2. src_core
     Degree: 0.200 (in: 1, out: 1)
     Betweenness: 0.000
     Closeness: 0.100
     PageRank: 0.109
     Clustering: 1.000
     Component: 0

  3. src_utils
     Degree: 0.200 (in: 2, out: 0)
     Betweenness: 0.000
     Closeness: 0.000
     PageRank: 0.202
     Clustering: 1.000
     Component: 0


Ranked by PageRank

  1. src_utils 0.202
  2. src_core 0.109
  3. src_api 0.077

Ranked by Betweenness

  1. src_api 0.000
  2. src_core 0.000
  3. src_utils 0.000

Ranked by Closeness

  1. src_api 0.200
  2. src_core 0.100
  3. src_utils 0.000

Ranked by Clustering

  1. src_api 1.000
  2. src_core 1.000
  3. src_utils 1.000

Ranked by Degree

  1. src_api 0.200
  2. src_core 0.200
  3. src_utils 0.200
```

Same graph, but every field now holds a number rather than `n/a`. The three
connected nodes form a triangle (`api → core → utils`, `api → utils`), hence
clustering 1.000 for each.

### Example 5: Machine-readable output

JSON, for tooling:

```bash
pmat analyze graph-metrics --metrics page-rank --format json
```

```json
{
  "nodes": [
    {
      "name": "src_utils",
      "degree_centrality": 0.2,
      "betweenness_centrality": null,
      "closeness_centrality": null,
      "pagerank": 0.20186741794123947,
      "clustering_coefficient": null,
      "component_id": null,
      "in_degree": 2,
      "out_degree": 0
    },
    {
      "name": "src_core",
      "degree_centrality": 0.2,
      "betweenness_centrality": null,
      "closeness_centrality": null,
      "pagerank": 0.10910070628504788,
      "clustering_coefficient": null,
      "component_id": null,
      "in_degree": 1,
      "out_degree": 1
    },
    {
      "name": "src_api",
      "degree_centrality": 0.2,
      "betweenness_centrality": null,
      "closeness_centrality": null,
      "pagerank": 0.07655909730819029,
      "clustering_coefficient": null,
      "component_id": null,
      "in_degree": 0,
      "out_degree": 2
    }
  ],
  "total_nodes": 11,
  "total_edges": 3,
  "density": 0.05454545454545454,
  "average_degree": 0.5454545454545454,
  "max_degree": 2,
  "connected_components": 9
}
```

CSV, for a spreadsheet:

```bash
pmat analyze graph-metrics --format csv
```

```
📊 Analyzing graph metrics...
✅ Built graph with 11 nodes and 3 edges
name,degree_centrality,betweenness,closeness,pagerank,clustering,component_id,in_degree,out_degree
src_api,0.200,0.000,0.200,0.077,1.000,0,0,2
src_core,0.200,0.000,0.100,0.109,1.000,0,1,1
src_utils,0.200,0.000,0.000,0.202,1.000,0,2,0
```

Markdown, for a report:

```bash
pmat analyze graph-metrics --format markdown
```

```markdown
# Graph Metrics Report

## Summary

| Metric | Value |
|--------|-------|
| Total Nodes | 11 |
| Total Edges | 3 |
| Density | 0.055 |
| Average Degree | 0.55 |
| Max Degree | 2 |
| Connected Components | 9 |

## Top Nodes

| Node | Degree | Betweenness | Closeness | PageRank | Clustering | Component |
|------|--------|-------------|-----------|----------|------------|-----------|
| src_api | 0.200 | 0.000 | 0.200 | 0.077 | 1.000 | 0 |
| src_core | 0.200 | 0.000 | 0.100 | 0.109 | 1.000 | 0 |
| src_utils | 0.200 | 0.000 | 0.000 | 0.202 | 1.000 | 0 |
```

The CSV and Markdown writers emit every column regardless of `--metrics`; an
unrequested metric is written as an empty field (CSV) or the default (Markdown).
Only the text and JSON formats distinguish "not computed" honestly.

Note also that all four output formats list **3 nodes for an 11-node graph**.
The eight nodes with degree 0 are dropped from the per-node table while still
counting in `Total nodes`. Reconcile those two numbers before you build a
dashboard on them.

### Example 6: GraphML export for Gephi / Cytoscape

```bash
pmat analyze graph-metrics --export-graphml -o graph_export.graphml
```

```
📊 Analyzing graph metrics...
✅ Built graph with 11 nodes and 3 edges
✅ Results written to: graph_export.graphml
```

And the file, in full — this is the entire export, not an excerpt:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns">
  <key id="d0" for="node" attr.name="label" attr.type="string"/>
  <graph id="G" edgedefault="directed">
    <node id="n0"><data key="d0">src_api</data></node>
    <node id="n1"><data key="d0">src_api::handle</data></node>
    <node id="n2"><data key="d0">src_api::health</data></node>
    <node id="n3"><data key="d0">src_core</data></node>
    <node id="n4"><data key="d0">src_lib</data></node>
    <node id="n5"><data key="d0">src_lib::api</data></node>
    <node id="n6"><data key="d0">src_lib::core</data></node>
    <node id="n7"><data key="d0">src_lib::utils</data></node>
    <node id="n8"><data key="d0">src_main</data></node>
    <node id="n9"><data key="d0">src_main::main</data></node>
    <node id="n10"><data key="d0">src_utils</data></node>
    <edge source="n0" target="n3" />
    <edge source="n0" target="n10" />
    <edge source="n3" target="n10" />
  </graph>
</graphml>
```

Unlike the per-node tables, the export lists all 11 nodes, including the
zero-degree ones.

One data key: `label`. The scores are **not** exported. If you want PageRank in
Gephi you have to join it in yourself from the CSV in Example 5. The old
edition showed a GraphML file with `pagerank`, `community` and `complexity`
keys; no version of `pmat` has written one.

Note `-o` takes the full filename including extension. Passing `-o graph_export`
writes a file literally named `graph_export`.

### Example 7: Tuning PageRank

`--damping-factor` sets the damping of the random walk (default 0.85) and does
move the numbers. `--pagerank-seeds` is documented in `--help` as "Personalized
PageRank seed nodes (file paths or function names)":

```bash
pmat analyze graph-metrics --metrics page-rank --format csv
pmat analyze graph-metrics --metrics page-rank --damping-factor 0.5 --format csv
```

The `pagerank` column across those two runs:

| Node | default (0.85) | damping 0.5 |
|------|----------------|-------------|
| src_utils | 0.202 | 0.155 |
| src_core | 0.109 | 0.103 |
| src_api | 0.077 | 0.082 |

Lowering the damping factor flattens the distribution, as theory says it should.

> **Known issue: `--pagerank-seeds` ignores which node you name.** On pmat
> 3.44.0 the flag is accepted, but `--pagerank-seeds src_utils`,
> `--pagerank-seeds src_api` and `--pagerank-seeds src_core` all print the same
> scores (`src_utils` 0.203, `src_core` 0.110, `src_api` 0.077), and a name that
> is not a node at all prints the default scores. Personalised PageRank should
> favour the seed, so this chapter does not document seeding behaviour: the tool
> does not currently show any. It is reported upstream.

`--max-iterations` (default 100) and `--convergence-threshold` (default 0.001)
also parse and run. On this graph PageRank has already converged, so raising the
iteration cap changes nothing:

```bash
pmat analyze graph-metrics --metrics page-rank --max-iterations 200 \
    --convergence-threshold 0.00000001 --format csv
```

```
src_utils,0.200,,,0.202,,,2,0
src_core,0.200,,,0.109,,,1,1
src_api,0.200,,,0.077,,,0,2
```

### Example 8: Scoping the graph

`--include` and `--exclude` are **substring filters on the path, not globs.**
This is the single most common way to get a wrong answer out of this command:

```bash
pmat analyze graph-metrics --include "src/**/*.rs"
```

```
📊 Analyzing graph metrics...
✅ Built graph with 0 nodes and 0 edges
Error: no source files were found under ., so no graph-metrics measurement was taken. This is not a clean result.
```

Exit code 5. Every glob form — `**/*.rs`, `src/*.rs`, `*.rs` — matches nothing.
Pass a substring instead:

```bash
pmat analyze graph-metrics --include src --exclude main
```

```
✅ Built graph with 9 nodes and 3 edges
```

Nine nodes instead of eleven: `src_main` and `src_main::main` were excluded because their path contains `main`. Credit to
the command for failing loudly rather than reporting a confident zero — the
error text says in so many words that this is not a clean result.

`--top-k` (default 20) and `--min-centrality` (default 0.001) trim the per-node
table:

```bash
pmat analyze graph-metrics --top-k 2 --format csv
pmat analyze graph-metrics --min-centrality 0.5 --format csv
```

The first prints two rows; the second prints none, since the highest degree
centrality in this graph is 0.200, below 0.5. Lower the threshold to 0.2 and all three connected nodes come back.

`--perf` appends a timing line:

```bash
pmat analyze graph-metrics --metrics page-rank --perf
```

```
⏱️  perf: analyze graph-metrics completed in 1.9 ms
```

### Example 9: Louvain community detection — `pmat split`

`pmat` does ship Louvain, but not in `graph-metrics`. `pmat split` builds the
**function** call graph inside a single file and clusters it, to suggest where
the file should be cut:

```bash
pmat split src/api.rs
```

```
Computing annotations for 3 functions...
  Git churn: 0 files with commits (max=1)
  Clones: 0 functions with duplicates
  Diversity: 2 files analyzed
  Faults: 0 functions with patterns
  Applied: churn=0, clones=0, diversity=3, faults=0
⚠  src/api.rs is 4 lines (under 500-line threshold). Showing plan anyway.
Split Plan for: src/api.rs
Total lines: ~4
Modularity: 0.000
Clusters: 0
Unclustered items: 2

Unclustered:
  Function handle (L3-L3)
  Function health (L4-L4)

```

`--resolution` is the Louvain resolution parameter (higher gives more clusters),
`--min-cluster-lines` (default 50) discards small clusters, and `--execute`
turns the dry-run plan into real files. `--auto` scans the whole project for
oversized files.

This is a file-splitting tool, not a project-modularization report. If you came
here for the old chapter's "Community 0: Core Application (8 files)" output,
that report does not exist in pmat.

## Integration with CI/CD

The honest version of a graph gate is a threshold check over the JSON, because
`graph-metrics` has no `--fail-on-degradation` flag and exits 0 whenever it
measured something:

```yaml
name: Architectural Quality Check
on: [push, pull_request]

jobs:
  graph-analysis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install PMAT
        run: cargo install pmat
      - name: Run graph analysis
        run: |
          pmat analyze graph-metrics --metrics all --format json \
            -o graph_report.json
      - name: Fail on excessive density
        run: |
          # graph-metrics exits 0 on success and 5 when it found no source
          # files; any threshold policy is yours to write.
          python3 - <<'PY'
          import json, sys
          g = json.load(open("graph_report.json"))
          worst = max(n["degree_centrality"] for n in g["nodes"])
          print(f"max degree centrality: {worst:.3f}")
          sys.exit(1 if worst > 0.9 else 0)
          PY
      - uses: actions/upload-artifact@v3
        with:
          name: graph-analysis
          path: graph_report.json
```

## Troubleshooting

### "Built graph with 0 nodes and 0 edges"

You passed a glob to `--include`. See Example 8 — it is a substring match. The
command exits 5 and says explicitly that no measurement was taken.

### `--metrics pagerank` is rejected

The enum value is `page-rank`, with a hyphen. The full list is `centrality`,
`betweenness`, `closeness`, `page-rank`, `clustering`, `components`, `all`.

### Every score is `n/a` except degree

You requested one metric. `--metrics all` (the default) fills them all in.

### The node count and the table length disagree

Zero-degree nodes (here 8 of 11) count toward `Total nodes` but are omitted from the per-node
table. See the note under Example 5.

### PageRank ranks the file nobody imports last

That is correct. PageRank rewards incoming edges, so the file that imports
others but is imported by none (`src_api` here) sinks, and the most-imported
file (`src_utils`) floats to the top. Use degree centrality, not PageRank, if
you want "how much does this file reach".

## Best Practices

1. **Ask for the metric you need.** Unrequested metrics come back `n/a`, and in
   CSV that is an empty field, which a spreadsheet will read as zero.
2. **Use substrings, not globs**, in `--include` / `--exclude`.
3. **Check the edge count first.** Three edges over eleven nodes says the graph is
   thin; centrality over a thin graph is noise.
4. **Export CSV, not GraphML**, if you want scores — GraphML carries labels only.
5. **Reach for `pmat split`** when the question is "where should this file be
   cut", not `graph-metrics`.
6. **Write your own thresholds.** There is no built-in quality gate on these
   numbers; the JSON output is the integration point.

## Summary

`pmat analyze graph-metrics` computes six standard network measures over a
project's import graph (files, functions and `pub mod` declarations as nodes; `use crate::…` as edges) and emits them as text, JSON, CSV, Markdown
or GraphML. It is a measurement tool, not an advisor: it has no quality
assessment, no trend analysis, no hotspot detection and no incremental mode,
and every flag that claimed otherwise in the previous edition of this chapter
was rejected by the argument parser.

Key takeaways:
- The metric is `page-rank`; `--metrics` values are a fixed enum.
- Unrequested metrics are `n/a`/`null` — absent, not zero.
- `--include` / `--exclude` are substring filters; globs silently match nothing
  and the command exits 5 rather than pretending.
- GraphML export contains labels only; join the CSV for scores.
- Louvain community detection lives in `pmat split`, at function granularity
  within one file.
