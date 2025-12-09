# Chapter 38: Terminal Graph Visualization

<!-- DOC_STATUS_START -->
**Chapter Status**: 100% Working (4/4 examples)

| Status | Count | Examples |
|--------|-------|----------|
| Working | 4 | All visualization features tested |
| Not Implemented | 0 | N/A |
| Broken | 0 | N/A |
| Planned | 0 | N/A |

*Last updated: 2025-12-09*
*PMAT version: pmat 2.211.0*
*Test-Driven: All examples validated*
*New in v2.211.0: trueno-viz integration for terminal graph rendering*
<!-- DOC_STATUS_END -->

## Overview

PMAT v2.211.0 introduces terminal graph visualization powered by **trueno-viz**, a SIMD/GPU-accelerated visualization library. This feature renders TDG (Technical Debt Grading) dependency graphs directly in your terminal with ANSI TrueColor support.

## Key Features

- **Force-Directed Layout**: Fruchterman-Reingold algorithm for optimal node placement
- **PageRank Criticality**: Functions ranked by importance (incoming edges)
- **ANSI TrueColor**: 16.7 million color support for rich gradients
- **Accessibility**: Dual encoding (shape + color) for WCAG 2.1 compliance
- **Multiple Themes**: Default, high-contrast, light, and colorblind-safe (Okabe-Ito palette)
- **Semantic Zooming**: Limits display to top N nodes by criticality

## Basic Usage

### Visualize Project Dependencies

```bash
# Render dependency graph in terminal
pmat tdg --viz

# Analyze specific path
pmat tdg src/ --viz

# Use colorblind-safe theme
pmat tdg --viz --viz-theme colorblind-safe
```

### Available Themes

| Theme | Description | Use Case |
|-------|-------------|----------|
| `default` | Green/yellow/red gradient | Standard terminals |
| `high-contrast` | Bold, high-contrast colors | Low-visibility environments |
| `light` | Optimized for light backgrounds | Light terminal themes |
| `colorblind-safe` | Okabe-Ito palette | Colorblind users (WCAG 2.1) |

### Example Output

```
--- TDG Dependency Graph ---
Theme: Default
Nodes: 32 functions
Edges: 528 dependencies

    ┌─────────────────────────────────────────────────────────┐
    │                        [main]                           │
    │                          │                              │
    │            ┌─────────────┼─────────────┐                │
    │            ▼             ▼             ▼                │
    │       [parse]       [validate]    [process]             │
    │            │             │             │                │
    │            └─────────────┴─────────────┘                │
    │                          │                              │
    │                          ▼                              │
    │                      [utils]                            │
    └─────────────────────────────────────────────────────────┘

Legend:
  ● High criticality (PageRank > 0.1)
  ◐ Medium criticality
  ○ Low criticality

Top Critical Functions (by PageRank):
  1. utils (score: 0.2541)
  2. validate (score: 0.1832)
  3. process (score: 0.1456)
  4. parse (score: 0.1023)
  5. main (score: 0.0891)
```

## Programmatic Usage

### Rust Example

```rust
use pmat::tdg::tdg_graph::TdgGraph;
use pmat::viz::terminal::{RenderConfig, TerminalTheme, Visualizable};

fn main() -> anyhow::Result<()> {
    // Build dependency graph
    let mut graph = TdgGraph::new();

    graph.add_function("main".to_string())?;
    graph.add_function("helper".to_string())?;
    graph.add_function("utils".to_string())?;

    graph.add_edge("main", "helper")?;
    graph.add_edge("helper", "utils")?;
    graph.add_edge("main", "utils")?;

    // Compute PageRank criticality
    graph.update_criticality()?;

    // Render to terminal
    let config = RenderConfig {
        width: 80,
        height: 40,
        show_legend: true,
        max_nodes: 50,
        theme: TerminalTheme::Default,
    };

    let output = graph.render_terminal(&config)?;
    println!("{}", output);

    Ok(())
}
```

### Run the Demo Example

```bash
# Default theme
cargo run --example viz_demo --features viz

# Colorblind-safe theme
cargo run --example viz_demo --features viz -- --theme colorblind-safe
```

## Understanding PageRank Criticality

PageRank identifies the most **critical functions** in your codebase based on how many other functions depend on them.

### Interpretation

| PageRank Score | Interpretation | Action |
|----------------|----------------|--------|
| > 0.15 | Highly critical | Prioritize testing, avoid breaking changes |
| 0.05 - 0.15 | Moderately critical | Regular testing coverage |
| < 0.05 | Low criticality | Standard maintenance |

### Example: Hub Detection

```bash
# Identify hub functions (many callers)
pmat tdg --viz --format json | jq '.critical_functions[:5]'
```

A hub-and-spoke pattern indicates a central function that many others depend on:

```
    parse_json ──┐
    parse_xml  ──┤
    parse_yaml ──┼──► validate_input (PageRank: 0.35)
    parse_toml ──┤
    parse_csv  ──┘
```

In this pattern, `validate_input` is highly critical - any bug here affects all parsers.

## Configuration

### Terminal Requirements

- **TrueColor support**: Most modern terminals (iTerm2, Alacritty, Kitty, Windows Terminal)
- **Fallback**: 256-color mode for older terminals
- **Minimum size**: 60x20 for readable graphs

### Environment Variables

```bash
# Force TrueColor mode
export COLORTERM=truecolor

# Disable colors (for piping)
export NO_COLOR=1
```

### Render Configuration

```rust
let config = RenderConfig {
    width: 80,          // Terminal columns
    height: 40,         // Terminal rows
    show_legend: true,  // Display color legend
    max_nodes: 50,      // Limit for large graphs (semantic zooming)
    theme: TerminalTheme::ColorblindSafe,
};
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Dependency Graph

on:
  pull_request:

jobs:
  visualize:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install PMAT
        run: cargo install pmat

      - name: Generate Graph
        run: |
          # JSON output for automation
          pmat tdg --viz --format json > graph.json

          # Extract top 10 critical functions
          jq '.critical_functions[:10]' graph.json
```

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Visualize changes before commit
pmat tdg --viz --quiet

# Check for highly critical function modifications
CRITICAL=$(pmat tdg --format json | jq '.critical_functions[:5][].name')
for file in $(git diff --cached --name-only); do
    for func in $CRITICAL; do
        if grep -q "$func" "$file"; then
            echo "Warning: Modifying critical function: $func"
        fi
    done
done
```

## Performance

### Benchmarks

| Operation | Time | Notes |
|-----------|------|-------|
| O(1) function lookup | <1ms | HashMap-based |
| PageRank (100 nodes) | <5ms | 20 iterations |
| PageRank (1000 nodes) | <50ms | Scales linearly |
| Terminal render | <10ms | Force-directed layout |

### Optimization Tips

1. **Limit nodes**: Use `max_nodes` for large codebases
2. **Cache results**: PageRank scores are deterministic
3. **Semantic zooming**: Focus on top N critical functions

## Accessibility

### WCAG 2.1 Compliance

The visualization uses **dual encoding**:
1. **Color**: Gradient from green (low) to red (high) criticality
2. **Shape**: Different node shapes for criticality levels

This ensures information is accessible even without color perception.

### Colorblind-Safe Palette

The `colorblind-safe` theme uses the [Okabe-Ito palette](https://jfly.uni-koeln.de/color/), designed for all types of color vision deficiency:

```bash
pmat tdg --viz --viz-theme colorblind-safe
```

## Troubleshooting

### Graph Too Large

```bash
# Limit to top 20 functions by criticality
pmat tdg --viz --max-nodes 20
```

### Colors Not Displaying

```bash
# Check terminal color support
echo $COLORTERM  # Should be 'truecolor' or '24bit'

# Force 256-color mode
pmat tdg --viz --color-mode 256
```

### No Functions Detected

Ensure the path contains analyzable code:

```bash
# Check what's being analyzed
pmat tdg src/ --format json | jq '.files_analyzed'
```

## Summary

Terminal graph visualization provides:
- **Visual Understanding**: See dependency relationships at a glance
- **Critical Path Identification**: PageRank highlights most important functions
- **Accessibility**: Colorblind-safe themes and dual encoding
- **Performance**: O(1) lookups and fast PageRank computation

Use `pmat tdg --viz` to understand your codebase architecture and identify critical refactoring targets.

## Next Steps

- [Chapter 4: Technical Debt Grading](ch04-01-tdg.md) - Full TDG documentation
- [Chapter 26: Graph Statistics](ch26-00-graph-statistics.md) - Network analysis metrics
- [Chapter 7: Quality Gates](ch07-00-quality-gate.md) - Enforce quality thresholds
