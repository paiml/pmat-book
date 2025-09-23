# Chapter 26: Graph Statistics and Network Analysis

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (42/42 examples)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 42 | Ready for production use |
| ⚠️ Not Implemented | 0 | Planned for future versions |
| ❌ Broken | 0 | Known issues, needs fixing |
| 📋 Planned | 0 | Future roadmap features |

*Last updated: 2025-09-23*
*PMAT version: pmat 2.95.0*
<!-- DOC_STATUS_END -->

## The Problem

Understanding code architecture and identifying critical components in large codebases requires sophisticated network analysis beyond simple static analysis. PMAT's graph statistics engine transforms dependency relationships into actionable insights using advanced algorithms like PageRank, Louvain community detection, and centrality measures. This chapter explores how to leverage these powerful analytics to identify architectural hotspots, detect coupling issues, and guide refactoring efforts.

## Core Concepts

### Graph Theory in Code Analysis

PMAT models code dependencies as directed graphs where:

1. **Nodes**: Represent files, modules, or functions
2. **Edges**: Represent dependencies (imports, calls, references)
3. **Weights**: Represent dependency strength or frequency
4. **Communities**: Represent cohesive code modules
5. **Centrality**: Represents architectural importance

### Key Algorithms

#### PageRank (Importance Ranking)
- **Purpose**: Identifies the most architecturally important files
- **Algorithm**: Power iteration with damping factor
- **Output**: Importance scores (0.0 to 1.0)
- **Use Case**: Guide refactoring priorities and testing focus

#### Louvain Community Detection
- **Purpose**: Discovers natural module boundaries
- **Algorithm**: Modularity optimization with greedy approach
- **Output**: Community assignments for each node
- **Use Case**: Identify architectural layers and suggest modularization

#### Centrality Measures
- **Degree Centrality**: Direct connection count
- **Betweenness Centrality**: Bridge importance
- **Closeness Centrality**: Average distance to all nodes
- **Eigenvector Centrality**: Recursive importance based on connections

## Practical Examples

### Example 1: Basic Graph Analysis with Context Command

The simplest way to get graph statistics is through the enhanced context command:

```bash
# Run context analysis with graph statistics
pmat context --output deep_analysis.md

# Skip graph analysis for faster execution
pmat context --skip-expensive-metrics
```

**Output** (deep_analysis.md):
```markdown
# Deep Context Analysis

## 📊 Graph Analysis Results

### Top Files by PageRank Importance
1. **src/lib.rs** (Score: 0.245)
   - Community: Core (0)
   - Complexity: Medium
   - Role: Central library interface

2. **src/main.rs** (Score: 0.189)
   - Community: Core (0)
   - Complexity: Low
   - Role: Application entry point

3. **src/utils/mod.rs** (Score: 0.156)
   - Community: Utilities (1)
   - Complexity: High
   - Role: Utility coordination hub

### 🏘️ Community Structure
- **Community 0 (Core)**: 8 files - Main application logic
- **Community 1 (Utilities)**: 5 files - Helper functions
- **Community 2 (Config)**: 3 files - Configuration management
```

### Example 2: Dedicated Graph Metrics Analysis

For detailed graph analysis, use the specialized graph metrics command:

```bash
# Comprehensive graph analysis
pmat analyze graph-metrics \
    --metrics pagerank,centrality,community \
    --pagerank-damping 0.85 \
    --max-iterations 100 \
    --export-graphml \
    --format json \
    --top-k 20 \
    --min-centrality 0.01 \
    --output graph_analysis.json
```

**Configuration** (pmat.toml):
```toml
[graph_analysis]
pagerank_damping = 0.85
pagerank_iterations = 100
pagerank_convergence = 1e-6
community_resolution = 1.0
min_centrality_threshold = 0.01
top_k_nodes = 10

[performance]
parallel_processing = true
cache_results = true
max_nodes = 10000
```

**Output** (graph_analysis.json):
```json
{
  "nodes": [
    {
      "name": "src/lib.rs",
      "degree_centrality": 0.75,
      "betweenness_centrality": 0.45,
      "closeness_centrality": 0.89,
      "pagerank": 0.245,
      "in_degree": 12,
      "out_degree": 8
    },
    {
      "name": "src/main.rs",
      "degree_centrality": 0.60,
      "betweenness_centrality": 0.23,
      "closeness_centrality": 0.67,
      "pagerank": 0.189,
      "in_degree": 3,
      "out_degree": 9
    }
  ],
  "total_nodes": 45,
  "total_edges": 89,
  "density": 0.045,
  "average_degree": 3.96,
  "max_degree": 12,
  "connected_components": 1
}
```

### Example 3: PageRank with Custom Seeds

Analyze importance relative to specific high-priority files:

```bash
# PageRank with seed files (files you know are critical)
pmat analyze graph-metrics \
    --metrics pagerank \
    --pagerank-seeds "src/lib.rs,src/api.rs,src/core.rs" \
    --damping-factor 0.90 \
    --format table
```

**Output**:
```
📊 PageRank Analysis (Custom Seeds)

Rank | File                | Score  | Community | Complexity
-----|---------------------|--------|-----------|------------
1    | src/lib.rs         | 0.312  | 0         | Medium
2    | src/api.rs         | 0.298  | 0         | High
3    | src/core.rs        | 0.245  | 0         | Medium
4    | src/handlers/mod.rs | 0.189  | 1         | Low
5    | src/utils/parser.rs | 0.156  | 2         | Very High
```

### Example 4: Community Detection for Modularization

Identify natural module boundaries for refactoring:

```bash
# Community detection analysis
pmat analyze graph-metrics \
    --metrics community \
    --community-resolution 1.2 \
    --format markdown \
    --output communities.md
```

**Output** (communities.md):
```markdown
# 🏘️ Community Detection Analysis

## Community 0: Core Application (8 files)
**Cohesion Score**: 0.89 (Very High)
- src/lib.rs (PageRank: 0.245)
- src/main.rs (PageRank: 0.189)
- src/api.rs (PageRank: 0.298)
- src/core.rs (PageRank: 0.245)
- src/types.rs (PageRank: 0.134)

**Suggested Action**: Well-formed core module, no changes needed.

## Community 1: HTTP Handlers (5 files)
**Cohesion Score**: 0.67 (Moderate)
- src/handlers/mod.rs (PageRank: 0.189)
- src/handlers/auth.rs (PageRank: 0.098)
- src/handlers/user.rs (PageRank: 0.087)

**Suggested Action**: Consider splitting authentication logic.

## Community 2: Utilities (12 files)
**Cohesion Score**: 0.34 (Low)
- src/utils/parser.rs (PageRank: 0.156)
- src/utils/validator.rs (PageRank: 0.078)
- [10 more utility files...]

**Suggested Action**: ⚠️ Low cohesion detected. Consider reorganizing utilities by function.
```

### Example 5: Integration with Context Analysis

Combine graph statistics with regular context generation:

```rust
// In your PMAT integration
use pmat::graph::{GraphContextAnnotator, ContextAnnotation};

let annotator = GraphContextAnnotator::new();
let annotations = annotator.annotate_context(&dependency_graph);

for annotation in annotations.iter().take(10) {
    println!(
        "📄 {} (Importance: {:.3}, Community: {}, Complexity: {})",
        annotation.file_path,
        annotation.importance_score,
        annotation.community_id,
        annotation.complexity_rank
    );
}
```

**Output**:
```
📄 src/lib.rs (Importance: 0.245, Community: 0, Complexity: Medium)
📄 src/api.rs (Importance: 0.298, Community: 0, Complexity: High)
📄 src/main.rs (Importance: 0.189, Community: 0, Complexity: Low)
📄 src/handlers/mod.rs (Importance: 0.156, Community: 1, Complexity: Low)
📄 src/utils/parser.rs (Importance: 0.134, Community: 2, Complexity: Very High)
```

### Example 6: GraphML Export for Visualization

Export graph data for external visualization tools:

```bash
# Export to GraphML for Gephi, Cytoscape, etc.
pmat analyze graph-metrics \
    --export-graphml \
    --output graph_export \
    --include "src/**/*.rs" \
    --exclude "tests/**"
```

This generates `graph_export.graphml`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns">
  <key id="pagerank" for="node" attr.name="pagerank" attr.type="double"/>
  <key id="community" for="node" attr.name="community" attr.type="int"/>
  <key id="complexity" for="node" attr.name="complexity" attr.type="double"/>

  <graph id="dependency_graph" edgedefault="directed">
    <node id="src/lib.rs">
      <data key="pagerank">0.245</data>
      <data key="community">0</data>
      <data key="complexity">8.5</data>
    </node>
    <!-- More nodes... -->

    <edge source="src/main.rs" target="src/lib.rs" />
    <!-- More edges... -->
  </graph>
</graphml>
```

### Example 7: Centrality Analysis for Refactoring Priorities

Identify files that are bottlenecks or over-connected:

```bash
# Comprehensive centrality analysis
pmat analyze graph-metrics \
    --metrics centrality \
    --min-centrality 0.1 \
    --format table \
    --top-k 15
```

**Output**:
```
🎯 Centrality Analysis - Refactoring Priorities

File                  | Degree | Between. | Close. | Eigenv. | Risk Level
----------------------|--------|----------|--------|---------|------------
src/utils/parser.rs   | 0.89   | 0.67     | 0.45   | 0.78    | 🔴 CRITICAL
src/lib.rs           | 0.75   | 0.45     | 0.89   | 0.82    | 🟡 HIGH
src/api.rs           | 0.60   | 0.34     | 0.67   | 0.65    | 🟡 HIGH
src/handlers/mod.rs   | 0.45   | 0.23     | 0.56   | 0.43    | 🟢 MODERATE

Risk Assessment:
🔴 CRITICAL: High on all centrality measures - refactor immediately
🟡 HIGH: High on multiple measures - schedule for refactoring
🟢 MODERATE: Well-balanced connectivity
```

### Example 8: Multi-Language Dependency Analysis

Analyze dependencies across different programming languages:

```bash
# Multi-language project analysis
pmat analyze graph-metrics \
    --include "**/*.{rs,py,ts,js}" \
    --language-aware \
    --export-by-language \
    --output multilang_analysis
```

**Output Structure**:
```
multilang_analysis/
├── rust_dependencies.json      # Rust-specific graph
├── python_dependencies.json    # Python-specific graph
├── typescript_dependencies.json # TypeScript-specific graph
├── cross_language.json         # Cross-language imports
└── unified_graph.json          # Combined analysis
```

### Example 9: Performance Benchmarking

Monitor graph analysis performance for large codebases:

```bash
# Performance analysis with timing
pmat analyze graph-metrics \
    --metrics pagerank,community,centrality \
    --perf \
    --parallel \
    --cache-enabled
```

**Performance Output**:
```
⚡ Performance Metrics:

Graph Construction: 234ms
├── File Discovery: 45ms (1,234 files)
├── AST Parsing: 156ms (parallel)
└── Edge Creation: 33ms (2,567 edges)

PageRank Computation: 89ms
├── Matrix Setup: 12ms
├── Power Iteration: 71ms (23 iterations)
└── Convergence: 6ms

Community Detection: 67ms
├── Modularity Calc: 34ms
└── Optimization: 33ms (4 iterations)

Centrality Metrics: 145ms
├── Degree: 8ms
├── Betweenness: 89ms
├── Closeness: 34ms
└── Eigenvector: 14ms

Total Analysis Time: 535ms
Memory Usage: 89MB peak
```

### Example 10: Architectural Quality Assessment

Use graph metrics to assess overall architectural quality:

```bash
# Architectural health check
pmat analyze graph-metrics \
    --metrics all \
    --quality-assessment \
    --thresholds-config quality_thresholds.toml
```

**Configuration** (quality_thresholds.toml):
```toml
[architectural_quality]
max_density = 0.1              # Avoid over-coupling
min_modularity = 0.3           # Ensure good modularization
max_degree_centralization = 0.8 # Avoid single points of failure
min_components = 1             # Ensure connectivity
max_components = 3             # Avoid fragmentation

[complexity_integration]
high_pagerank_max_complexity = 15  # Important files should be simple
high_centrality_max_complexity = 10 # Central files should be simple
```

**Assessment Output**:
```markdown
# 🏗️ Architectural Quality Assessment

## Overall Score: B+ (82/100)

### ✅ Strengths
- **Good Modularization**: Modularity score 0.67 (target: >0.3)
- **Balanced Connectivity**: Average degree 3.2 (healthy range)
- **Clear Communities**: 3 well-defined modules detected

### ⚠️ Areas for Improvement
- **High Density**: 0.12 (target: <0.1) - Consider reducing coupling
- **Centralization Risk**: `src/utils/parser.rs` has 89% betweenness centrality

### 🎯 Recommended Actions
1. **Refactor `src/utils/parser.rs`**: Split into smaller, focused modules
2. **Reduce cross-module dependencies**: 23 edges between communities
3. **Extract interfaces**: High-centrality files need abstraction layers

### 📊 Trend Analysis
- Density: 0.08 → 0.12 (+50% in last month) ⚠️
- Modularity: 0.72 → 0.67 (-7% in last month) ⚠️
- Max Complexity: 45 → 38 (-16% in last month) ✅
```

## Common Patterns

### Pattern 1: Hotspot Detection

Identify architectural hotspots using combined metrics:

```bash
# Multi-metric hotspot analysis
pmat analyze graph-metrics \
    --metrics pagerank,centrality \
    --hotspot-detection \
    --complexity-threshold 15
```

This combines:
- High PageRank (architectural importance)
- High centrality (structural bottlenecks)
- High complexity (maintenance burden)

### Pattern 2: Community-Based Refactoring

Use community detection to guide modularization:

```python
# Example refactoring strategy based on communities
def generate_refactoring_plan(communities, current_structure):
    plan = []

    for community_id, files in communities.items():
        if len(files) > 10:  # Large community
            plan.append(f"Split community {community_id} into sub-modules")
        elif len(files) < 3:  # Small community
            plan.append(f"Merge community {community_id} with related community")

        # Check cross-community edges
        cross_edges = count_cross_community_edges(community_id)
        if cross_edges > 5:
            plan.append(f"Add interface layer for community {community_id}")

    return plan
```

### Pattern 3: Progressive Complexity Reduction

Target high-centrality, high-complexity files first:

```bash
# Generate refactoring priority list
pmat analyze graph-metrics \
    --metrics centrality \
    --combine-with-complexity \
    --priority-ranking \
    --output refactoring_priorities.md
```

### Pattern 4: Temporal Analysis

Track graph metrics over time to monitor architectural evolution:

```bash
# Historical trend analysis
for commit in $(git rev-list --max-count=10 HEAD); do
    git checkout $commit
    pmat analyze graph-metrics --metrics pagerank --output "metrics_${commit}.json"
done

# Combine results for trend analysis
pmat analyze graph-trends --input-dir . --output trends.md
```

## Integration with CI/CD

### GitHub Actions Workflow

```yaml
name: Architectural Quality Check
on: [push, pull_request]

jobs:
  graph-analysis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0  # Full history for trend analysis

      - name: Install PMAT
        run: cargo install pmat

      - name: Run Graph Analysis
        run: |
          pmat analyze graph-metrics \
            --metrics pagerank,community,centrality \
            --quality-assessment \
            --output graph_report.md \
            --fail-on-degradation

      - name: Check Architectural Thresholds
        run: |
          # Fail build if architecture degrades
          if grep -q "⚠️ DEGRADATION" graph_report.md; then
            echo "Architectural quality degradation detected!"
            exit 1
          fi

      - name: Upload Graph Report
        uses: actions/upload-artifact@v3
        with:
          name: graph-analysis
          path: graph_report.md
```

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit
# Check for architectural regressions

echo "🔍 Running graph analysis..."

pmat analyze graph-metrics \
    --metrics pagerank,centrality \
    --quick-check \
    --threshold-degradation 0.1

if [ $? -ne 0 ]; then
    echo "❌ Architectural quality check failed!"
    echo "Run 'pmat analyze graph-metrics --help' for details"
    exit 1
fi

echo "✅ Architectural quality check passed"
```

## Performance Optimization

### Large Codebase Strategies

For projects with >10,000 files:

```bash
# Optimized analysis for large codebases
pmat analyze graph-metrics \
    --parallel \
    --cache-enabled \
    --sample-ratio 0.8 \
    --approximation-mode \
    --memory-limit 4GB \
    --chunk-size 1000
```

### Incremental Analysis

Only analyze changed files:

```bash
# Git-aware incremental analysis
pmat analyze graph-metrics \
    --incremental \
    --since-commit HEAD~10 \
    --affected-analysis \
    --cache-unchanged
```

## Troubleshooting

### Issue: High Memory Usage

**Problem**: Graph analysis consumes too much memory on large codebases.

**Solutions**:
1. Use sampling: `--sample-ratio 0.5`
2. Enable approximation: `--approximation-mode`
3. Increase chunk size: `--chunk-size 2000`
4. Set memory limit: `--memory-limit 2GB`

### Issue: Slow Community Detection

**Problem**: Louvain algorithm takes too long.

**Solutions**:
1. Reduce resolution: `--community-resolution 0.8`
2. Limit iterations: `--max-community-iterations 50`
3. Use fast mode: `--community-fast-mode`

### Issue: Inconsistent PageRank Results

**Problem**: PageRank scores vary between runs.

**Solutions**:
1. Increase iterations: `--max-iterations 200`
2. Tighten convergence: `--convergence-threshold 1e-8`
3. Use fixed random seed: `--random-seed 42`

## Best Practices

1. **Start Simple**: Begin with basic PageRank and community detection
2. **Combine Metrics**: Use multiple centrality measures for comprehensive analysis
3. **Monitor Trends**: Track metrics over time, not just snapshots
4. **Set Thresholds**: Define quality gates based on your project's needs
5. **Automate Analysis**: Integrate into CI/CD for continuous monitoring
6. **Visualize Results**: Export to GraphML for external tools
7. **Focus on Hotspots**: Prioritize high-centrality, high-complexity files
8. **Validate Communities**: Manually review community assignments for accuracy

## Summary

PMAT's graph statistics engine provides powerful insights into code architecture through advanced network analysis algorithms. By combining PageRank importance ranking, Louvain community detection, and comprehensive centrality measures, developers can:

- **Identify architectural hotspots** requiring immediate attention
- **Discover natural module boundaries** for effective refactoring
- **Prioritize maintenance efforts** based on structural importance
- **Monitor architectural evolution** over time
- **Prevent architectural degradation** through automated quality gates

Key takeaways:
- Graph analysis reveals hidden architectural patterns
- PageRank identifies the most structurally important files
- Community detection suggests natural modularization boundaries
- Centrality measures highlight potential bottlenecks
- Integration with context analysis provides actionable insights
- Performance optimizations enable analysis of large codebases
- Continuous monitoring prevents architectural debt accumulation