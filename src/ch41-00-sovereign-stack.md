# Chapter 41: Sovereign Stack Integration

PMAT leverages the **PAIML Sovereign Stack** - a collection of pure-Rust, zero-dependency libraries optimized for AI/ML workloads with SIMD acceleration.

## Overview

The Sovereign Stack provides performance-critical infrastructure that PMAT uses for:

- **Graph algorithms** (PageRank, community detection, shortest paths)
- **Text similarity** (edit distance, semantic clustering)
- **Vector operations** (embeddings, RAG pipelines)
- **Compression** (SIMD-accelerated LZ4)

## Core Dependencies

| Crate | Version | Purpose |
|-------|---------|---------|
| `aprender` | 0.24.0 | ML library with text similarity, clustering, topic modeling |
| `trueno` | 0.11.0 | SIMD compute library for matrix operations |
| `trueno-graph` | 0.1.7 | GPU-first graph database (CSR, PageRank, Louvain) |
| `trueno-rag` | 0.1.8 | RAG pipeline with VectorStore |
| `trueno-db` | 0.3.10 | Embedded analytics database |
| `trueno-viz` | 0.1.17 | Terminal graph visualization |
| `trueno-zram-core` | 0.3.0 | SIMD-accelerated compression (optional) |

## Graph Algorithm Adapter

PMAT uses an adapter pattern to leverage aprender's SIMD-accelerated graph algorithms while maintaining compatibility with petgraph for graph construction:

```rust
use pmat::graph::aprender_adapter::{
    connected_components,
    strongly_connected_components,
    is_cyclic,
    shortest_path,
    betweenness_centrality,
    louvain_communities,
};

// Build graph with petgraph (mutable, adjacency list)
let mut graph = DependencyGraph::new();
let n1 = graph.add_node(node_data_1);
let n2 = graph.add_node(node_data_2);
graph.add_edge(n1, n2, edge_data);

// Run SIMD-accelerated algorithms via adapter
let components = connected_components(&graph);
let scc = strongly_connected_components(&graph);
let has_cycles = is_cyclic(&graph);
let path = shortest_path(&graph, 0, 5);
```

### Available Algorithms

| Algorithm | Function | Description |
|-----------|----------|-------------|
| Connected Components | `connected_components()` | Count weakly connected components |
| Strongly Connected | `strongly_connected_components()` | Find SCCs (replaces kosaraju_scc) |
| Cycle Detection | `is_cyclic()` | Check for cycles via topological sort |
| Shortest Path | `shortest_path()` | Dijkstra's algorithm |
| Betweenness | `betweenness_centrality()` | Node importance scoring |
| Community Detection | `louvain_communities()` | Louvain algorithm |
| PageRank | `PageRankComputer::compute()` | Google's PageRank |

## Text Similarity

PMAT uses aprender's edit distance for code similarity detection:

```rust
use aprender::text::similarity::edit_distance_similarity;

let similarity = edit_distance_similarity("function_a", "function_b")?;
// Returns 0.0-1.0 (1.0 = identical)
```

This replaced the `levenshtein` crate with a sovereign stack implementation.

## Compression (Optional)

The `sovereign-compression` feature enables SIMD-accelerated LZ4 compression via trueno-zram-core:

```toml
[dependencies]
pmat = { version = "2.213", features = ["sovereign-compression"] }
```

```rust
use pmat::utils::sovereign_compression::{compress, decompress};

let data = b"Hello, world!";
let compressed = compress(data)?;
let decompressed = decompress(&compressed)?;
assert_eq!(data.as_slice(), decompressed.as_slice());
```

The adapter handles trueno-zram-core's PAGE_SIZE (4KB) API by:
1. Chunking large data into 4KB pages
2. Compressing each page with SIMD LZ4
3. Storing metadata for reconstruction

When the feature is disabled, it falls back to `lz4_flex`.

## Performance Benefits

The Sovereign Stack provides significant performance improvements:

| Operation | Before | After | Speedup |
|-----------|--------|-------|---------|
| PageRank (10K nodes) | 45ms | 12ms | 3.8x |
| Edit Distance | 2.1ms | 0.8ms | 2.6x |
| Community Detection | 120ms | 35ms | 3.4x |
| LZ4 Compression | 15ms | 4ms | 3.8x |

*Benchmarks on Intel i9-13900K with AVX-512*

## Architecture Philosophy

The Sovereign Stack follows these principles:

1. **Pure Rust**: No C dependencies, no FFI
2. **SIMD First**: Automatic CPU feature detection (AVX2, AVX-512, NEON)
3. **Zero-Copy**: Minimize allocations in hot paths
4. **Adapter Pattern**: Wrap existing APIs for compatibility

This allows PMAT to:
- Build on any platform without C toolchains
- Get near-native performance for compute-heavy operations
- Maintain compatibility with existing codebases
