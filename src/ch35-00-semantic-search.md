# Chapter 35: Semantic Search and Code Clustering

PMAT provides powerful semantic search, topic modeling, and code clustering capabilities using **pure Rust implementations**. No API keys or external services required.

## Overview

The semantic search stack uses three core libraries:

| Library | Purpose | Key Algorithms |
|---------|---------|----------------|
| **aprender** | Machine Learning | TF-IDF, LDA, K-means, DBSCAN |
| **trueno-rag** | RAG Pipeline | Hybrid retrieval, RRF fusion |
| **trueno-graph** | Graph Database | PageRank, BFS, Louvain |

## Quick Start

### Topic Extraction

Extract semantic topics from your codebase using Latent Dirichlet Allocation (LDA):

```bash
# Extract 5 topics
pmat analyze topics --num-topics 5

# Filter by language
pmat analyze topics --num-topics 5 --language rust

# JSON output for CI/CD
pmat analyze topics --num-topics 5 --format json
```

**Example Output:**

```
📊 Topic Extraction Results:
   Documents: 1270
   Topics: 5

   Topic 0 (854 documents):
     Top terms:
       - pub (0.039)
       - fn (0.025)
       - let (0.021)
       - impl (0.015)

   Topic 1 (412 documents):
     Top terms:
       - test (0.045)
       - assert (0.032)
       - #[test] (0.028)
```

### Code Clustering

Group similar code files using various clustering algorithms:

```bash
# K-means clustering (specify number of clusters)
pmat analyze cluster --method kmeans --k 8

# DBSCAN (density-based, automatic cluster count)
pmat analyze cluster --method dbscan

# Hierarchical clustering
pmat analyze cluster --method hierarchical --k 5
```

**Example Output:**

```
📊 Clustering Results (kmeans):
   Documents: 1270
   Clusters: 8

   Cluster 0 (425 files):
     - src/services/analysis.rs
     - src/services/complexity.rs
     - src/services/dead_code.rs
     ... and 422 more

   Cluster 1 (312 files):
     - src/cli/commands.rs
     - src/cli/handlers/mod.rs
     ... and 309 more
```

## trueno-rag Integration (Sprint 76+)

PMAT now uses **trueno-rag** for enhanced RAG pipeline performance:

### BM25 Keyword Search

True relevance scoring replacing RRF heuristics:

```rust
// Internally uses trueno-rag's BM25Index
use trueno_rag::index::BM25Index;

let mut index = BM25Index::new();
index.add(chunk_id, &document_text);
let results = index.search(&query, 10);
```

**Benefits over RRF:**
- IDF-weighted term importance (rare terms score higher)
- Term frequency saturation (BM25's k1 parameter)
- True relevance vs rank-based fusion

### SIMD Cosine Similarity

4-way loop unrolling for LLVM auto-vectorization:

```rust
// 2-4x speedup on AVX2, 4-8x on AVX-512
let similarity = TursoVectorDB::cosine_similarity_simd(&v1, &v2);
```

### RecursiveChunker

Text chunking with overlap for RAG retrieval:

```rust
use trueno_rag::chunk::{Chunker, RecursiveChunker};

let chunker = RecursiveChunker::new(512, 64)  // chunk_size, overlap
    .with_separators(vec!["\n\n", "\n", ". ", " "]);
let chunks = chunker.chunk(&document)?;
```

### LSH Index for Duplicate Detection

O(1) approximate nearest neighbor lookup:

```rust
let mut lsh = LshIndex::new(20, 5);  // bands, rows_per_band
lsh.insert(fragment_id, minhash_signature);
let candidates = lsh.query(&query_signature);  // O(1) vs O(n)
```

**Collision Probability:** `P = 1 - (1 - s^r)^b`
- s=0.9 → P≈1.0 (high similarity → always candidates)
- s=0.5 → P≈0.47 (medium similarity)
- s=0.2 → P≈0.04 (low similarity → rarely candidates)

## Algorithms

### TF-IDF Vectorization

Converts code files to numerical vectors based on term frequency:

- **TF (Term Frequency)**: How often a term appears in a document
- **IDF (Inverse Document Frequency)**: Penalizes common terms across all documents

```rust
// Internally uses aprender's TfidfVectorizer
let vectorizer = TfidfVectorizer::new()
    .with_max_features(1000)
    .with_min_df(2);
```

**Citation**: Manning, C. D., Raghavan, P., & Schütze, H. (2008). "Introduction to Information Retrieval."

### LDA Topic Modeling

Discovers latent topics in your codebase:

- Each document is a mixture of topics
- Each topic is a distribution over terms
- Uses Gibbs sampling for inference

**Citation**: Blei, D. M., Ng, A. Y., & Jordan, M. I. (2003). "Latent Dirichlet Allocation." JMLR.

### K-means Clustering

Partitions code into k clusters by minimizing within-cluster variance:

1. Initialize k centroids randomly
2. Assign each document to nearest centroid
3. Recompute centroids as cluster means
4. Repeat until convergence

**Citation**: MacQueen, J. (1967). "Some Methods for Classification and Analysis of Multivariate Observations."

### DBSCAN Clustering

Density-based clustering that finds arbitrarily shaped clusters:

- **eps**: Maximum distance between neighbors
- **min_samples**: Minimum points to form a cluster
- Automatically identifies outliers (noise points)

**Citation**: Ester, M., Kriegel, H. P., Sander, J., & Xu, X. (1996). "A Density-Based Algorithm for Discovering Clusters."

## CI/CD Integration

### JSON Output

```bash
pmat analyze topics --num-topics 5 --format json > topics.json
pmat analyze cluster --method kmeans --k 8 --format json > clusters.json
```

### GitHub Actions Example

```yaml
name: Code Analysis
on: [push]

jobs:
  semantic-analysis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install PMAT
        run: cargo install pmat

      - name: Extract Topics
        run: pmat analyze topics --num-topics 10 --format json > topics.json

      - name: Cluster Code
        run: pmat analyze cluster --method kmeans --k 5 --format json > clusters.json

      - name: Upload Results
        uses: actions/upload-artifact@v4
        with:
          name: semantic-analysis
          path: |
            topics.json
            clusters.json
```

## Use Cases

### 1. Understanding New Codebases

```bash
# What are the main themes in this codebase?
pmat analyze topics --num-topics 10

# How is the code organized?
pmat analyze cluster --method hierarchical --k 5
```

### 2. Finding Related Code

```bash
# Group similar files together
pmat analyze cluster --method kmeans --k 10

# Find outliers (unusual code)
pmat analyze cluster --method dbscan
```

### 3. Identifying Code Modules

```bash
# Discover natural module boundaries
pmat analyze cluster --method hierarchical --k 8

# Topics often align with modules
pmat analyze topics --num-topics 8
```

### 4. Code Review Preparation

```bash
# Understand code themes before review
pmat analyze topics --num-topics 5 --language rust
```

## Performance

| Operation | Files | Time |
|-----------|-------|------|
| Topic Extraction (5 topics) | 1,000 | ~2s |
| K-means (k=5) | 1,000 | ~1s |
| DBSCAN | 1,000 | ~3s |
| Hierarchical | 1,000 | ~2s |

## Comparison with API-Based Solutions

| Factor | PMAT (Local) | API-Based |
|--------|--------------|-----------|
| **Latency** | 10-50ms | 200-500ms |
| **Cost** | $0 | $0.10-$1/project |
| **Privacy** | Code stays local | Code sent to cloud |
| **Offline** | Works offline | Requires internet |
| **Reproducibility** | Deterministic | Model versions change |

## Specification

For implementation details, see:
- `docs/specifications/semantic-search-feature.md`
- 10 peer-reviewed citations supporting algorithm choices

## Example

Run the demo example:

```bash
cargo run --example semantic_search_demo
```

## Summary

PMAT's semantic search provides:

- **Topic modeling** with LDA for understanding code themes
- **Clustering** with K-means, DBSCAN, and hierarchical methods
- **Pure Rust** implementation with zero external dependencies
- **Offline operation** - no API keys required
- **CI/CD ready** with JSON output support
