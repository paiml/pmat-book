# Chapter 26: Graph Statistics and Network Analysis

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ Verified against pmat 3.32.0

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 17 | Executed against pmat 3.32.0; output pasted verbatim |
| ⚠️ Not Implemented | 0 | — |
| ❌ Broken | 0 | — |
| 📋 Planned | 0 | — |

*Last updated: 2026-08-25*
*PMAT version: pmat 3.32.0*
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

Every command below runs against this five-file Rust crate:

```
src/lib.rs     pub mod core; pub mod api; pub mod utils;   (3 outgoing edges)
src/core.rs    use crate::utils;
src/api.rs     use crate::core; use crate::utils;
src/utils.rs   (no imports)
src/main.rs    (no imports of the crate's own modules)
```

`pmat` resolves this to **5 nodes and 3 edges** — the three `pub mod` declarations
in `lib.rs`. Note what that implies: `use crate::…` statements inside `core.rs`
and `api.rs` did *not* become edges. The graph is built from module declarations,
not from every use-path, so `in_degree` counts "who declares me" rather than "who
calls me". Keep that in mind before reading architectural meaning into a score.

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
- **Total Functions**: 8
- **Median Cyclomatic**: 1.00
- **Median Cognitive**: 0.00

## Quality Scorecard

- **Overall Health**: 100.0%
- **Maintainability Index**: not measured
- **Complexity Score**: 100.0
- **Test Coverage**: N/A

## Files
### ./src/api.rs
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
✅ Built graph with 5 nodes and 3 edges
Graph Metrics Analysis

Graph Statistics
  Total nodes: 5
  Total edges: 3
  Density: 0.300
  Average degree: 1.20
  Max degree: 3
  Connected components: 2
```

`--format summary` is the default. It stops at the aggregate. To see per-node
scores you need `--format detailed`, `json`, `csv` or `markdown`.

### Example 3: PageRank, per node

```bash
pmat analyze graph-metrics --metrics page-rank --format detailed
```

```
📊 Analyzing graph metrics...
✅ Built graph with 5 nodes and 3 edges
Graph Metrics Analysis

Graph Statistics
  Total nodes: 5
  Total edges: 3
  Density: 0.300
  Average degree: 1.20
  Max degree: 3
  Connected components: 2

Top Nodes by Centrality

  1. lib.rs
     Degree: 0.750 (in: 0, out: 3)
     Betweenness: n/a
     Closeness: n/a
     PageRank: 0.171
     Clustering: n/a
     Component: n/a

  2. api.rs
     Degree: 0.250 (in: 1, out: 0)
     Betweenness: n/a
     Closeness: n/a
     PageRank: 0.219
     Clustering: n/a
     Component: n/a
```

The `n/a` entries are the point of Example 1's note: only `page-rank` was
requested, so only PageRank and the always-present degree are filled in.

Notice that `lib.rs` has the *lowest* PageRank despite the highest degree.
PageRank flows along incoming edges, and `lib.rs` has none — it declares three
modules and nothing declares it. This is the correct answer for a dependency
graph and the opposite of what the old chapter's invented table showed.

### Example 4: Every metric at once

```bash
pmat analyze graph-metrics --metrics all --format detailed
```

```
📊 Analyzing graph metrics...
✅ Built graph with 5 nodes and 3 edges
Graph Metrics Analysis

Graph Statistics
  Total nodes: 5
  Total edges: 3
  Density: 0.300
  Average degree: 1.20
  Max degree: 3
  Connected components: 2

Top Nodes by Centrality

  1. lib.rs
     Degree: 0.750 (in: 0, out: 3)
     Betweenness: 0.000
     Closeness: 0.750
     PageRank: 0.171
     Clustering: 0.000
     Component: 0

  2. api.rs
     Degree: 0.250 (in: 1, out: 0)
     Betweenness: 0.000
     Closeness: 0.000
     PageRank: 0.219
     Clustering: 0.000
     Component: 0
```

Same graph, but every field now holds a number rather than `n/a`.

### Example 5: Machine-readable output

JSON, for tooling:

```bash
pmat analyze graph-metrics --metrics page-rank --format json
```

```json
{
  "nodes": [
    {
      "name": "lib.rs",
      "degree_centrality": 0.75,
      "betweenness_centrality": null,
      "closeness_centrality": null,
      "pagerank": 0.17096444130663302,
      "clustering_coefficient": null,
      "component_id": null,
      "in_degree": 0,
      "out_degree": 3
    },
    {
      "name": "api.rs",
      "degree_centrality": 0.25,
      "betweenness_centrality": null,
      "closeness_centrality": null,
      "pagerank": 0.21935703912891136,
      "clustering_coefficient": null,
      "component_id": null,
      "in_degree": 1,
      "out_degree": 0
    }
  ]
}
```

CSV, for a spreadsheet:

```bash
pmat analyze graph-metrics --format csv
```

```
📊 Analyzing graph metrics...
✅ Built graph with 5 nodes and 3 edges
name,degree_centrality,betweenness,closeness,pagerank,clustering,component_id,in_degree,out_degree
lib.rs,0.750,0.000,0.750,0.171,0.000,0,0,3
api.rs,0.250,0.000,0.000,0.219,0.000,0,1,0
core.rs,0.250,0.000,0.000,0.219,0.000,0,1,0
utils.rs,0.250,0.000,0.000,0.219,0.000,0,1,0
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
| Total Nodes | 5 |
| Total Edges | 3 |
| Density | 0.300 |
| Average Degree | 1.20 |
| Max Degree | 3 |
| Connected Components | 2 |

## Top Nodes

| Node | Degree | Betweenness | Closeness | PageRank | Clustering | Component |
|------|--------|-------------|-----------|----------|------------|-----------|
| lib.rs | 0.750 | 0.000 | 0.750 | 0.171 | 0.000 | 0 |
| api.rs | 0.250 | 0.000 | 0.000 | 0.219 | 0.000 | 0 |
| core.rs | 0.250 | 0.000 | 0.000 | 0.219 | 0.000 | 0 |
| utils.rs | 0.250 | 0.000 | 0.000 | 0.219 | 0.000 | 0 |
```

The CSV and Markdown writers emit every column regardless of `--metrics`; an
unrequested metric is written as an empty field (CSV) or the default (Markdown).
Only the text and JSON formats distinguish "not computed" honestly.

Note also that all four output formats list **4 nodes for a 5-node graph**.
`main.rs` has degree 0 and is dropped from the per-node table while still
counting in `Total nodes`. Reconcile those two numbers before you build a
dashboard on them.

### Example 6: GraphML export for Gephi / Cytoscape

```bash
pmat analyze graph-metrics --export-graphml -o graph_export.graphml
```

```
📊 Analyzing graph metrics...
✅ Built graph with 5 nodes and 3 edges
✅ Results written to: graph_export.graphml
```

And the file, in full — this is the entire export, not an excerpt:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns">
  <key id="d0" for="node" attr.name="label" attr.type="string"/>
  <graph id="G" edgedefault="directed">
    <node id="n0"><data key="d0">utils.rs</data></node>
    <node id="n1"><data key="d0">main.rs</data></node>
    <node id="n2"><data key="d0">lib.rs</data></node>
    <node id="n3"><data key="d0">core.rs</data></node>
    <node id="n4"><data key="d0">api.rs</data></node>
    <edge source="n2" target="n3" />
    <edge source="n2" target="n4" />
    <edge source="n2" target="n0" />
  </graph>
</graphml>
```

One data key: `label`. The scores are **not** exported. If you want PageRank in
Gephi you have to join it in yourself from the CSV in Example 5. The old
edition showed a GraphML file with `pagerank`, `community` and `complexity`
keys; no version of `pmat` has written one.

Note `-o` takes the full filename including extension. Passing `-o graph_export`
writes a file literally named `graph_export`.

### Example 7: Tuning PageRank

`--pagerank-seeds` biases the random-walk restart toward named nodes, and
`--damping-factor` sets the restart probability. Both work, and both move the
numbers:

```bash
pmat analyze graph-metrics --metrics page-rank --format csv
pmat analyze graph-metrics --metrics page-rank --pagerank-seeds "lib.rs" --format csv
pmat analyze graph-metrics --metrics page-rank --damping-factor 0.5 --format csv
```

The `pagerank` column across those three runs:

| Node | default | seeded on `lib.rs` | damping 0.5 |
|------|---------|--------------------|-------------|
| lib.rs | 0.171 | 0.172 | 0.182 |
| api.rs | 0.219 | 0.221 | 0.212 |
| core.rs | 0.219 | 0.221 | 0.212 |
| utils.rs | 0.219 | 0.221 | 0.212 |

Seeding moves the scores by about 0.6% on a graph this small — a real effect,
but a much weaker one than the old chapter's fabricated table implied. Lowering
the damping factor flattens the distribution, as theory says it should.

`--max-iterations` (default 100) and `--convergence-threshold` (default 0.001)
also parse and run. On this graph PageRank has already converged, so raising the
iteration cap changes nothing:

```bash
pmat analyze graph-metrics --metrics page-rank --max-iterations 200 \
    --convergence-threshold 0.00000001 --format csv
```

```
lib.rs,0.750,,,0.171,,,0,3
api.rs,0.250,,,0.219,,,1,0
core.rs,0.250,,,0.219,,,1,0
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
✅ Built graph with 4 nodes and 3 edges
```

Four nodes: `main.rs` was excluded because its path contains `main`. Credit to
the command for failing loudly rather than reporting a confident zero — the
error text says in so many words that this is not a clean result.

`--top-k` (default 20) and `--min-centrality` (default 0.001) trim the per-node
table:

```bash
pmat analyze graph-metrics --top-k 2 --format csv
pmat analyze graph-metrics --min-centrality 0.5 --format csv
```

The first prints two rows; the second prints one, since only `lib.rs` clears a
degree centrality of 0.5.

`--perf` appends a timing line:

```bash
pmat analyze graph-metrics --metrics page-rank --perf
```

```
⏱️  perf: analyze graph-metrics completed in 2.3 ms
```

### Example 9: Louvain community detection — `pmat split`

`pmat` does ship Louvain, but not in `graph-metrics`. `pmat split` builds the
**function** call graph inside a single file and clusters it, to suggest where
the file should be cut:

```bash
pmat split src/api.rs
```

```
Computing annotations for 8 functions...
  Git churn: 0 files with commits (max=1)
  Clones: 0 functions with duplicates
  Diversity: 5 files analyzed
  Faults: 0 functions with patterns
  Applied: churn=0, clones=0, diversity=8, faults=0
⚠  src/api.rs is 4 lines (under 500-line threshold). Showing plan anyway.
Split Plan for: src/api.rs
Total lines: ~4
Modularity: 0.000
Clusters: 0
Unclustered items: 2

Unclustered:
  Function handle (L3-L3)
  Function health (L4-L4)

Impact 1 files import this module:
  src/lib.rs
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

Zero-degree files count toward `Total nodes` but are omitted from the per-node
table. See the note under Example 5.

### PageRank ranks the entry point last

That is correct. PageRank rewards incoming edges; a crate root declares modules
and is declared by none, so it sinks. Use degree centrality, not PageRank, if
you want "how much does this file reach".

## Best Practices

1. **Ask for the metric you need.** Unrequested metrics come back `n/a`, and in
   CSV that is an empty field, which a spreadsheet will read as zero.
2. **Use substrings, not globs**, in `--include` / `--exclude`.
3. **Check the edge count first.** Three edges over five files says the graph is
   thin; centrality over a thin graph is noise.
4. **Export CSV, not GraphML**, if you want scores — GraphML carries labels only.
5. **Reach for `pmat split`** when the question is "where should this file be
   cut", not `graph-metrics`.
6. **Write your own thresholds.** There is no built-in quality gate on these
   numbers; the JSON output is the integration point.

## Summary

`pmat analyze graph-metrics` computes six standard network measures over a
project's module-declaration graph and emits them as text, JSON, CSV, Markdown
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
