# Chapter 33: Rust Project Score

The `pmat rust-project-score` command provides comprehensive quality scoring specifically for Rust projects, scoring them on a 0-159 scale across **10 quality categories** including formal verification and build performance.

## Overview

Rust project scoring helps teams:
- **Quantify Rust-specific quality** with evidence-based metrics
- **Leverage Rust tooling** (clippy, rustfmt, cargo-audit, Miri, Kani)
- **Track improvement** over time with consistent grading
- **Enforce best practices** with automated quality gates
- **Validate build configuration** with comprehensive diagnostics

## Version History

- **v1.0** (Initial): 6 categories, 106 points
- **v1.1** (Evidence-Based): Refined weights based on peer-reviewed research
- **v1.2** (Formal Verification): 7th category - Miri + Kani integration (114 points total)
- **v2.2** (Extended): 9 scorers, 144 points
- **v2.3** (Build Performance): **10 scorers, 159 points** - NEW BuildPerfScorer + extended RustTooling

## Score Categories (159 Total Points)

### Category 1: Rust Tooling Compliance (37 points)

**Clippy - Tiered Scoring (15 points)**
- Correctness lints (9 points): Critical safety issues
- Suspicious patterns (4 points): Likely bugs
- Pedantic style (2 points): Code quality

**rustfmt (5 points)**
- Code formatting consistency

**cargo-audit (3 points)**
- Security vulnerability scanning
- Risk-based tiered scoring

**cargo-deny (2 points)**
- Dependency policy enforcement

**MSRV Defined (5 points)** - NEW in v2.3
- Checks for `rust-version` field in Cargo.toml
- Ensures minimum supported Rust version is documented
- Important for compatibility guarantees

**CI Configured (7 points)** - NEW in v2.3
- Validates presence of CI/CD pipeline
- Checks for `.github/workflows/*.yml`
- Also checks `.gitlab-ci.yml` and `Jenkinsfile`

**Example:**
```bash
$ pmat rust-project-score .

Rust Tooling Compliance: 37/37 (100%) - Grade: A
├─ Clippy (correctness): 9/9
├─ Clippy (suspicious): 4/4
├─ Clippy (pedantic): 2/2
├─ rustfmt: 5/5
├─ cargo-audit: 3/3
├─ cargo-deny: 2/2
├─ MSRV Defined: 5/5 ✅
└─ CI Configured: 7/7 ✅
```

### Category 2: Code Quality (26 points)

**Cyclomatic Complexity (3 points)** - Reduced from 8pts based on research
- All functions ≤20 complexity
- Evidence: arXiv 2024 - "No correlation between complexity and bugs"

**Unsafe Code (9 points)** - Increased from 6pts
- Proper `unsafe` documentation
- Safety comments required
- Rationale: Memory safety is Rust's core value

**Mutation Testing (8 points)** - Increased from 5pts
- ≥80% mutation score
- Evidence: ICST 2024 - Developers find highly valuable

**Build Time (4 points)**
- Fast incremental builds
- Optimized compilation

**Dead Code (2 points)**
- No unused code

**Example:**
```bash
Code Quality: 22/26 (84.6%) - Grade: B
├─ Cyclomatic Complexity: 3/3 ✅
├─ Unsafe Code: 7/9 ⚠️
│  Missing safety comments: 2 instances
├─ Mutation Testing: 6/8 ⚠️
│  Mutation score: 75% (target: 80%)
├─ Build Time: 4/4 ✅
└─ Dead Code: 2/2 ✅
```

### Category 3: Testing Excellence (20 points)

**Coverage (8 points)**
- ≥85% line coverage
- Use cargo-llvm-cov

**Integration Tests (4 points)**
- Comprehensive integration testing

**Doc Tests (3 points)**
- Examples in rustdoc comments

**Mutation Coverage (5 points)**
- Test quality validation
- cargo-mutants integration

**Example:**
```bash
Testing Excellence: 18/20 (90%) - Grade: A
├─ Coverage: 8/8 ✅ (87.5%)
├─ Integration Tests: 4/4 ✅
├─ Doc Tests: 3/3 ✅
└─ Mutation Coverage: 3/5 ⚠️
```

### Category 4: Documentation (15 points)

**Rustdoc (7 points)**
- Comprehensive API documentation
- Public items documented

**README (5 points)**
- Project overview
- Installation, usage examples

**Changelog (3 points)**
- Version history tracking
- Semantic versioning

**Example:**
```bash
Documentation: 15/15 (100%) - Grade: A
├─ Rustdoc: 7/7 ✅
├─ README: 5/5 ✅
└─ Changelog: 3/3 ✅
```

### Category 5: Performance & Benchmarking (10 points)

**Criterion Benchmarks (5 points)**
- Performance baselines established

**Profiling (5 points)**
- Performance analysis tooling
- Flamegraph integration

**Example:**
```bash
Performance & Benchmarking: 8/10 (80%) - Grade: B
├─ Criterion Benchmarks: 5/5 ✅
└─ Profiling: 3/5 ⚠️
```

### Category 6: Dependency Health (12 points)

**Dependency Count (5 points)**
- Minimal dependency footprint
- Fewer dependencies = better score

**Feature Flags (4 points)**
- Modular dependencies
- Optional features properly gated

**Tree Pruning (3 points)**
- Optimized dependency tree
- cargo-tree analysis

**Example:**
```bash
Dependency Health: 10/12 (83.3%) - Grade: B
├─ Dependency Count: 4/5 ✅ (38 deps)
├─ Feature Flags: 4/4 ✅
└─ Tree Pruning: 2/3 ⚠️
```

### Category 7: Formal Verification (8 points) - NEW in v1.2

**Miri Integration (3 points)** - Undefined Behavior Detection
- Interpreter for Rust's MIR (Mid-level Intermediate Representation)
- **Detects:**
  - Use-after-free
  - Double-free
  - Uninitialized memory access
  - Invalid pointer arithmetic
  - Data races in unsafe code

**Scoring:**
- 3 points: Clean Miri run, all tests pass
- 2 points: Minor warnings, tests pass
- 0 points: UB detected or Miri unavailable

**Kani Formal Verification (5 points)** - Mathematical Proof of Correctness
- Model checker using CBMC (Bounded Model Checking)
- **Verifies:**
  - Mathematical proofs of correctness
  - Absence of panics
  - Memory safety guarantees
  - Functional correctness properties

**Scoring:**
- 5 points: All proofs verified, no counterexamples
- 3 points: Some proofs verified
- 0 points: Verification failures or Kani unavailable

**Example:**
```bash
$ pmat rust-project-score --full

Formal Verification: 8/8 (100%) - Grade: A
├─ Miri Integration: 3/3 ✅
│  All unsafe code validated
│  0 UB instances detected
│  Tests passed: 247/247
└─ Kani Formal Verification: 5/5 ✅
   Proofs verified: 12/12
   0 counterexamples found
   Properties checked: memory safety, panic-freedom
```

**Toyota Way Principles:**
- **Jidoka (自働化)**: Stop the line on undefined behavior
- **Genchi Genbutsu**: Go see for yourself - empirical evidence via formal methods
- **Kaizen (改善)**: Continuous improvement through formal verification

### Category 8: Build Performance (15 points) - NEW in v2.3

This category validates build configuration for reproducible, optimized builds.

**LTO Enabled (2 points)**
- Checks for Link-Time Optimization in release profile
- Validates `[profile.release] lto = true/thin/"fat"`
- Smaller binaries, better runtime performance

**Target Dir Size <= 10GB (2 points)**
- Measures target/ directory size
- Warns if exceeds 10GB (indicates build cache bloat)
- Skipped if target/ doesn't exist

**Cargo.lock Present (2 points)**
- Ensures reproducible builds
- Critical for applications and binary crates
- 2 points if present, 0 if missing

**.cargo/config.toml (2 points)**
- Validates build configuration file exists
- Enables project-specific build settings

**Incremental Builds (2 points)**
- Checks incremental compilation settings
- Faster development iteration

**Codegen Units (2 points)**
- Validates `codegen-units = 1` for release
- Maximum optimization at release time

**Build System (3 points)**
- Checks for build automation presence
- Validates Makefile, justfile, or build.rs
- 3 points for multiple, 2 for single, 0 for none

**Example:**
```bash
$ pmat rust-project-score .

Build Performance: 15/15 (100%) - Grade: A
├─ LTO Enabled: 2/2 ✅ (lto = "thin")
├─ Target Dir Size: 2/2 ✅ (2.3 GB)
├─ Cargo.lock Present: 2/2 ✅
├─ Cargo Config: 2/2 ✅
├─ Incremental Builds: 2/2 ✅
├─ Codegen Units: 2/2 ✅ (codegen-units = 1)
└─ Build System: 3/3 ✅ (Makefile + build.rs)
```

**Relationship to project-diag:**
The Build Performance scorer aligns with `pmat project-diag` checks, providing the same configuration validation integrated into the overall project score. For a quick standalone assessment, use:
```bash
pmat project-diag --category build
```

## Grading System

| Grade | Score Range | Percentage | Description |
|-------|-------------|------------|-------------|
| **A+** | 147-159 | 92-100% | Exceptional (includes formal verification + build perf) |
| **A** | 135-146 | 85-92% | Excellent |
| **A-** | 127-134 | 80-85% | PMAT standard (minimum for production) |
| **B+** | 119-126 | 75-80% | Good |
| **B** | 111-118 | 70-75% | Acceptable |
| **C** | 95-110 | 60-70% | Needs improvement |
| **D** | 79-94 | 50-60% | Poor |
| **F** | 0-78 | 0-50% | Failing |

*Note: v2.3 increased max from 114 to 159 points with new BuildPerfScorer and extended RustTooling categories.*

## Usage

### Fast Mode (Default)

```bash
# Quick check (~2-3 minutes on large projects)
pmat rust-project-score

# Fast mode skips:
# - clippy (60-90s on 50K+ projects)
# - Mutation testing (hours)
# - Build time measurement (minutes)
# - Miri (if slow on large test suites)

# Provides moderate credit for skipped checks
```

### Full Mode (Comprehensive)

```bash
# Full analysis (~10-15 minutes)
pmat rust-project-score --full

# Includes ALL checks:
# - Complete clippy analysis
# - Miri undefined behavior detection
# - Kani formal verification
# - Mutation testing
# - Build time profiling
```

### Output Formats

```bash
# Text (default, colored terminal output)
pmat rust-project-score

# JSON (for CI/CD integration)
pmat rust-project-score --format json

# Markdown (for documentation)
pmat rust-project-score --format markdown --output SCORE.md

# YAML (for config-based workflows)
pmat rust-project-score --format yaml
```

### Specific Project Path

```bash
pmat rust-project-score --path /path/to/rust/project
```

### Verbose Breakdown

```bash
pmat rust-project-score --verbose
```

### Show Only Failures

```bash
pmat rust-project-score --failures-only
```

## Complete Example

```bash
$ pmat rust-project-score --full --verbose

🦀 Rust Project Score v1.2 - Formal Verification

Overall Score: 98.5/114 (86.4%) - Grade: A-

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Category Breakdown:

✅ Rust Tooling Compliance: 25/25 (100%) - Grade: A
   ✅ Clippy (correctness): 9/9
   ✅ Clippy (suspicious): 4/4
   ✅ Clippy (pedantic): 2/2
   ✅ rustfmt: 5/5
   ✅ cargo-audit: 3/3
   ✅ cargo-deny: 2/2

⚠️ Code Quality: 20/26 (76.9%) - Grade: C
   ✅ Cyclomatic Complexity: 3/3
   ⚠️ Unsafe Code: 6/9
      Missing safety comments: 3 instances
      - src/ffi/bindings.rs:142 (unsafe fn from_raw)
      - src/ffi/bindings.rs:198 (unsafe impl Send)
      - src/allocator.rs:67 (unsafe trait GlobalAlloc)
   ✅ Mutation Testing: 6/8 (75% score, target: 80%)
   ✅ Build Time: 4/4
   ✅ Dead Code: 2/2

✅ Testing Excellence: 19/20 (95%) - Grade: A
   ✅ Coverage: 8/8 (88.3%)
   ✅ Integration Tests: 4/4
   ✅ Doc Tests: 3/3
   ⚠️ Mutation Coverage: 4/5

✅ Documentation: 15/15 (100%) - Grade: A
   ✅ Rustdoc: 7/7 (98% documented)
   ✅ README: 5/5
   ✅ Changelog: 3/3

⚠️ Performance & Benchmarking: 7/10 (70%) - Grade: C
   ✅ Criterion Benchmarks: 5/5
   ⚠️ Profiling: 2/5 (flamegraph setup incomplete)

✅ Dependency Health: 10/12 (83.3%) - Grade: B
   ✅ Dependency Count: 4/5 (42 deps)
   ✅ Feature Flags: 4/4
   ⚠️ Tree Pruning: 2/3

✅ Formal Verification: 7.5/8 (93.8%) - Grade: A
   ✅ Miri Integration: 3/3
      UB instances: 0
      Tests passed: 247/247
      Execution time: 18.3s
   ⚠️ Kani Formal Verification: 4.5/5
      Proofs verified: 10/12
      Counterexamples: 2
      - Property: "buffer_overflow_free" (src/parser.rs:89)
      - Property: "no_panic_on_invalid_utf8" (src/validator.rs:124)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔴 Recommendations (Priority Order):

CRITICAL (6 points potential):
1. Fix Kani verification failures (1.5 points)
   → Address buffer_overflow_free proof failure
   → Fix no_panic_on_invalid_utf8 property
   → Commands:
     cargo kani --harness verify_buffer_bounds
     cargo kani --harness verify_utf8_handling

2. Add unsafe code safety comments (3 points)
   → Document safety invariants for 3 unsafe blocks
   → Reference: Rust RFC 2585

3. Improve mutation score to ≥80% (2 points)
   → Add tests for uncovered mutations
   → cargo mutants --list > mutations.txt

HIGH (3 points potential):
4. Complete profiling setup (3 points)
   → cargo install flamegraph
   → Add perf permissions: echo -1 | sudo tee /proc/sys/kernel/perf_event_paranoid

MEDIUM (1 point potential):
5. Improve mutation coverage (1 point)
   → Target weak test cases identified by cargo-mutants

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📈 Evidence-Based Scoring Rationale:

Complexity Weight (3pts): arXiv 2024 - "No correlation between complexity and bugs"
Unsafe Weight (9pts): Memory safety is Rust's core value proposition
Mutation Testing (8pts): ICST 2024 - High developer-reported value
Clippy Tiers: 2023 - "Unleashing the Power of Clippy" study

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Metadata:
Project: my-rust-project
Path: /home/noah/src/my-rust-project
Version: 2.197.0
Analyzed: 2025-11-18 20:45:12 UTC
Execution Time: 8m 34s (full mode)
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Rust Project Score

on:
  push:
    branches: [ main ]
  pull_request:

jobs:
  score:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install Rust Toolchain
        uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
          components: rustfmt, clippy

      - name: Install PMAT
        run: cargo install pmat

      - name: Install Miri
        run: rustup component add miri

      - name: Install Kani
        run: cargo install --locked kani-verifier

      - name: Run Rust Project Score
        run: pmat rust-project-score --full --format json > score.json

      - name: Upload Score
        uses: actions/upload-artifact@v3
        with:
          name: rust-project-score
          path: score.json

      - name: Enforce Minimum Score
        run: |
          SCORE=$(jq '.total_earned' score.json)
          if (( $(echo "$SCORE < 85" | bc -l) )); then
            echo "❌ Score $SCORE below A- threshold (85)"
            exit 1
          fi
```

### Fast Mode for Pull Requests

```yaml
# For faster PR checks
- name: Quick Rust Score (Fast Mode)
  run: pmat rust-project-score --format text
```

## Formal Verification Deep Dive

### Miri - Undefined Behavior Detection

**What is Miri?**
- Official Rust tool for detecting undefined behavior
- Interprets MIR (Mid-level Intermediate Representation)
- Catches bugs that tests miss

**Example Usage:**
```bash
# Run Miri on all tests
cargo +nightly miri test

# Run Miri on specific test
cargo +nightly miri test test_unsafe_operations
```

**What Miri Detects:**
- Use-after-free
- Double-free
- Uninitialized memory reads
- Invalid pointer arithmetic
- Data races in unsafe code
- Misaligned pointers
- Null pointer dereferences

**Example Miri Finding:**
```rust
// ❌ Miri detects use-after-free
unsafe {
    let mut v = vec![1, 2, 3];
    let ptr = v.as_ptr();
    drop(v);
    println!("{}", *ptr); // UB: use-after-free
}
```

### Kani - Formal Verification

**What is Kani?**
- AWS-developed model checker for Rust
- Uses CBMC (Bounded Model Checking) backend
- Provides mathematical proofs of correctness

**Example Usage:**
```bash
# Verify all harnesses
cargo kani

# Verify specific harness
cargo kani --harness verify_buffer_safety
```

**Example Kani Harness:**
```rust
#[cfg(kani)]
#[kani::proof]
fn verify_no_buffer_overflow() {
    let size: usize = kani::any();
    kani::assume(size < 1000); // Bound the search space

    let buffer = vec![0u8; size];
    let idx: usize = kani::any();

    // Prove: If idx < size, access is safe
    if idx < size {
        let _ = buffer[idx]; // Kani proves: never panics
    }
}

#[cfg(kani)]
#[kani::proof]
fn verify_utf8_validation_never_panics() {
    let bytes: Vec<u8> = kani::any();
    kani::assume(bytes.len() < 100);

    // Prove: from_utf8 never panics (returns Result)
    let _ = std::str::from_utf8(&bytes);
}
```

**Properties Kani Can Prove:**
- Absence of panics
- Memory safety (no out-of-bounds access)
- Functional correctness
- Absence of arithmetic overflow
- Absence of deadlocks

## Performance Characteristics

### What's Fast (<10 seconds):
- File-based analysis (dead code, unsafe detection)
- Dependency counting
- README/Changelog validation

### What's Moderate (10-60 seconds):
- cargo-audit (security scanning)
- cargo-deny (policy enforcement)
- rustfmt check

### What's Slow (minutes to hours):
- **Clippy**: 60-90s on 50K+ SLOC projects (skipped in fast mode)
- **Mutation Testing**: Hours on large projects (skipped in fast mode)
- **Miri**: 10-60s depending on test suite size (conditional in fast mode)
- **Kani**: Minutes per proof (skipped in fast mode)
- **Build Time**: Minutes for release builds (skipped in fast mode)

## Troubleshooting

### Miri Issues

**Problem:** Miri reports "unsupported operation"

**Solution:**
- Miri doesn't support all operations (FFI, inline assembly)
- Mark unsupported tests with `#[cfg_attr(miri, ignore)]`

```rust
#[test]
#[cfg_attr(miri, ignore)] // Skip in Miri (uses FFI)
fn test_c_interop() {
    // FFI code
}
```

### Kani Verification Failures

**Problem:** Kani reports counterexamples

**Solution:**
- Review the counterexample trace
- Add preconditions with `kani::assume`
- Fix the actual bug if counterexample is valid

**Problem:** Kani times out

**Solution:**
- Reduce bounds on symbolic inputs
- Split complex proofs into smaller properties
- Use `--default-unwind` to limit loop iterations

### Low Mutation Score

**Problem:** Mutation testing reports low score

**Solution:**
```bash
# List surviving mutants
cargo mutants --list

# Focus on specific mutants
cargo mutants --file src/critical.rs
```

## Related Commands

- `pmat repo-score` - General repository health (language-agnostic)
- `pmat quality-gate` - Enforce quality thresholds
- `pmat analyze` - Deep code analysis

## Summary

The `pmat rust-project-score` command provides:
- **Evidence-based scoring** from 15 peer-reviewed papers (2022-2025)
- **Formal verification** integration (Miri + Kani)
- **Build performance** validation (NEW in v2.3)
- **Toyota Way principles** (Jidoka, Genchi Genbutsu, Kaizen)
- **Fast & Full modes** for different use cases
- **CI/CD integration** with JSON/YAML output

**v2.3 Highlights:**
- **10 scorers, 159 points** (up from 114 in v1.2)
- **BuildPerfScorer** (15pts): LTO, Cargo.lock, target dir, incremental, codegen-units
- **Extended RustTooling** (+12pts): MSRV defined, CI configured
- **Aligned with project-diag**: Same configuration checks as `pmat project-diag`

**Key Differentiators from `repo-score`:**
- Rust-specific tooling (clippy, cargo-audit, Miri, Kani)
- 159-point scale (vs 110 for repo-score)
- Formal verification category (unique to Rust)
- Build performance validation
- Evidence-based weight adjustments

**Related Commands:**
- `pmat project-diag` - Quick 20-check project health assessment (see Chapter 40)
- `pmat comply check` - Compliance validation with PMAT best practices

**Next Steps:**
1. Run `pmat rust-project-score` on your Rust project
2. Review recommendations
3. Target "Critical" priority items first
4. Re-score to track improvement
5. Integrate into CI/CD for continuous monitoring

**Academic Foundation:**
Based on 15 peer-reviewed references from IEEE, ACM, arXiv (2022-2025) covering empirical software engineering, mutation testing effectiveness, formal verification methods, and code quality metrics.
