# Chapter 44: Dependency Health (CB-081)

The Dependency Health system analyzes Cargo.toml and Cargo.lock to score project dependency hygiene. Excessive dependencies increase supply chain risk, bloat binaries, and slow builds.

## Overview

CB-081 provides 5 sub-checks following the rust-project-score-v1.1 specification:

| ID | Check | Description |
|----|-------|-------------|
| CB-081-A | Base Count | Direct and transitive dependency scoring (0-5 points) |
| CB-081-B | Duplicates | Multiple versions of same crate |
| CB-081-C | Feature Flags | `default-features = false` usage |
| CB-081-D | Sovereign Stack | Bonus for batuta ecosystem crates |
| CB-081-E | Trend Tracking | Delta since last compliance check |

## Quick Start

```bash
# Check dependency health
pmat comply check

# Example output:
# CB-081: Dependency Health: Score: 3/5 | 25 direct, 120 transitive
#   | 5 duplicates | 45% feature-gated | +2 sovereign (aprender, trueno)
```

## Scoring Tiers

Scores are based on rust-project-score-v1.1 thresholds:

| Score | Direct Deps | Transitive Deps | Description |
|-------|-------------|-----------------|-------------|
| 5 | ≤20 | ≤100 | Excellent |
| 3 | ≤30 | ≤150 | Good |
| 2 | ≤40 | ≤200 | Moderate |
| 1 | ≤50 | ≤250 | High |
| 0 | >50 | >250 | Critical |

## CB-081-A: Base Dependency Count

Counts dependencies from Cargo.toml and Cargo.lock:

```rust
// From Cargo.toml
[dependencies]
serde = "1.0"           // Counted (direct)
tokio = "1.0"           // Counted (direct)

[dev-dependencies]
criterion = "0.5"       // NOT counted (dev-only)
proptest = "1.0"        // NOT counted (dev-only)

[build-dependencies]
cc = "1.0"              // NOT counted (build-only)
```

Only `[dependencies]` are counted. Dev and build dependencies are excluded from scoring as they don't affect the deployed artifact.

## CB-081-B: Duplicate Crate Detection

Detects multiple versions of the same crate in Cargo.lock:

```bash
# View duplicates manually
cargo tree --duplicates

# Example violations:
# ⚠ 5 duplicate crates: rand, syn, quote, hashbrown, itertools
```

Common causes:
- Different dependencies require different versions
- Transitive dependencies with version conflicts
- Stale Cargo.lock not updated

### Remediation

```bash
# Update all dependencies to latest compatible versions
cargo update

# Check for unnecessary duplication
cargo tree --duplicates -i <crate_name>

# Consider unifying versions in [patch.crates-io]
[patch.crates-io]
syn = { git = "https://github.com/dtolnay/syn", tag = "2.0.0" }
```

## CB-081-C: Feature Flag Hygiene

Checks percentage of dependencies using `default-features = false`:

```toml
# ✅ Good: Minimal feature set
serde = { version = "1.0", default-features = false, features = ["derive"] }
tokio = { version = "1.0", default-features = false, features = ["rt-multi-thread"] }

# ❌ Bad: All default features enabled
serde = "1.0"       # Includes everything
tokio = "1.0"       # Includes everything
```

Thresholds:
- **≥50%**: No warning
- **30-49%**: Info-level suggestion
- **<30%** (with >20 deps): Warning to optimize

### Benefits of Disabling Default Features

1. **Smaller binaries**: Only compile what you use
2. **Faster builds**: Less code to compile
3. **Fewer transitive deps**: Each feature may pull more crates
4. **Better security**: Smaller attack surface

## CB-081-D: Sovereign Stack Bonus

Awards bonus points for using the batuta sovereign stack:

| Crate | Category |
|-------|----------|
| `aprender` | ML, statistics, text similarity |
| `trueno` | SIMD/GPU compute |
| `trueno-graph` | Graph database, PageRank |
| `trueno-db` | Columnar storage |
| `trueno-rag` | RAG pipeline |
| `trueno-viz` | Terminal visualization |
| `trueno-zram-core` | SIMD compression |
| `pmcp` | MCP protocol SDK |
| `presentar-core` | TUI framework |
| `renacer` | Golden tracing |
| `certeza` | Quality validation |
| `bashrs` | Bash/Makefile linting |
| `probar` | Property-based testing |
| `ruchy` | Ruchy language parser |

Each sovereign crate adds +1 to the sovereign bonus, displayed in output:
```
+3 sovereign (aprender, trueno, trueno-graph)
```

## CB-081-E: Trend Tracking

Tracks dependency count changes over time via `.pmat/metrics/dependencies.json`:

```json
{
  "direct_count": 25,
  "transitive_count": 120,
  "timestamp": "2025-01-15T10:30:00Z"
}
```

When running `pmat comply check`, the trend is shown:
```
ℹ Trend: +2 direct, -5 transitive since 2025-01-15
```

This helps detect dependency bloat early before it becomes critical.

## Severity Levels

| ID | Severity | Condition |
|----|----------|-----------|
| CB-081-A | Critical | >50 direct OR >250 transitive |
| CB-081-A | Warning | >30 direct OR >150 transitive |
| CB-081-B | Warning | Any duplicate crates detected |
| CB-081-C | Info | <30% feature-gated (when >20 deps) |
| CB-081-E | Warning | Trend regression detected |

## CI/CD Integration

```yaml
# .github/workflows/dependencies.yml
name: Dependency Health
on: [push, pull_request]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Check Dependencies
        run: |
          pmat comply check --format json | tee comply.json
          SCORE=$(jq '.cb081.score' comply.json)
          if [ "$SCORE" -lt 3 ]; then
            echo "::error::Dependency score $SCORE < 3"
            exit 1
          fi
```

## Best Practices

### 1. Minimize Direct Dependencies

```toml
# Before: 3 dependencies for logging
log = "0.4"
env_logger = "0.10"
tracing = "0.1"

# After: 1 dependency
tracing = { version = "0.1", features = ["log"] }
```

### 2. Use Feature Flags

```toml
# Before: Kitchen sink
tokio = "1.0"  # ~50+ transitive deps

# After: Just what you need
tokio = { version = "1.0", default-features = false, features = ["rt-multi-thread", "macros"] }
```

### 3. Prefer Sovereign Stack

Replace external dependencies with batuta crates when functionality overlaps:

| External | Sovereign Alternative |
|----------|----------------------|
| `nalgebra` | `aprender::primitives` |
| `petgraph` | `trueno-graph` |
| `polars` | `trueno-db` |
| `plotters` | `trueno-viz` |

### 4. Audit Regularly

```bash
# Weekly dependency audit
cargo tree --duplicates > deps-audit.txt
cargo outdated >> deps-audit.txt
cargo audit >> deps-audit.txt
```

## Related Commands

- `cargo tree --duplicates` - View duplicate crates
- `cargo outdated` - Check for newer versions
- `cargo audit` - Security vulnerability scan
- `pmat rust-project-score` - Full project scoring including dependencies
