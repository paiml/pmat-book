# Chapter 62: Provable Contracts (CB-1200 to CB-1214)

Provable-contracts is a Rust library and CLI (`pv`) for contract-first development of computational kernels. It converts peer-reviewed research papers into mathematically provable implementations via YAML contract intermediaries, Kani bounded model checking, and Lean 4 theorem proving. PMAT enforces contract compliance fleet-wide through the CB-1200 enforcement chain.

## The Seven-Phase Pipeline

Every kernel implementation follows seven phases. Skipping a phase produces either a lint failure or a compiler error.

| Phase | Action | Tool |
|-------|--------|------|
| 1. **Extract** | Parse a paper into canonical math (equations, domains, invariants) | `pv extract-pytorch`, manual |
| 2. **Specify** | Encode the math as a YAML contract with proof obligations | Editor + `pv validate` |
| 3. **Scaffold** | Generate Rust trait stubs and failing test skeletons | `pv scaffold` |
| 4. **Implement** | Write the scalar reference, then SIMD-accelerated version | Editor + `cargo test` |
| 5. **Falsify** | Run Popperian falsification via property-based testing | `pv probar` + certeza |
| 6. **Verify** | Prove correctness bounds via Kani bounded model checking | `pv kani` + `cargo kani` |
| 7. **Prove** | Prove correctness in Lean 4 type theory | `pv lean` + `lake build` |

### Walking Through the Pipeline

**Phase 1-2: Extract and Specify.** Start with a softmax kernel. The paper defines `softmax(x)_i = exp(x_i) / sum(exp(x))`. Encode this as YAML:

```yaml
name: softmax-kernel-v1
version: "1.0"
metadata:
  description: "Numerically stable softmax"
  paper: "https://arxiv.org/abs/..."

equations:
  softmax:
    formula: "softmax(x)_i = exp(x_i - max(x)) / sum(exp(x - max(x)))"
    preconditions:
      - 'x.iter().all(|v| v.is_finite())'
      - 'x.len() > 0'
    postconditions:
      - '(result.iter().sum::<f32>() - 1.0).abs() < 1e-5'
      - 'result.iter().all(|v| *v >= 0.0 && *v <= 1.0)'
    proof_obligations:
      - type: invariant
        description: "Output sums to 1 (partition of unity)"
      - type: bound
        description: "All outputs in [0, 1]"
      - type: monotonicity
        description: "Larger input produces larger output"

falsification_tests:
  - rule: "empty input panics"
    input: "[]"
    expect: panic
  - rule: "NaN input detected"
    input: "[NaN, 1.0]"
    expect: panic
```

**Phase 3: Scaffold.** Generate Rust stubs:

```bash
pv scaffold contracts/softmax-kernel-v1.yaml
```

This produces a trait definition with `fn softmax(&self, x: &[f32]) -> Vec<f32>` and failing tests for each postcondition. You fill in the implementation.

**Phase 4-5: Implement and Falsify.** Write the implementation, then generate property tests:

```bash
pv probar contracts/softmax-kernel-v1.yaml \
    --binding contracts/aprender/binding.yaml
```

**Phase 6-7: Verify and Prove.** Generate Kani harnesses and Lean theorems:

```bash
pv kani contracts/softmax-kernel-v1.yaml
pv lean contracts/softmax-kernel-v1.yaml
```

The fleet currently has 266 contracts, 93 Lean theorems (1 sorry), and 660 bindings across 33 repos.

## How pmat comply Integrates

`pmat comply check` runs 13 checks (CB-1200 through CB-1214) spanning the verification ladder from L0 (paper-only) to L5 (Lean-proved):

```bash
# Run all compliance checks
pmat comply check

# Filter to provable-contracts checks only
pmat comply check 2>&1 | grep 'CB-12'

# Get infra-score bonus (PV-01..PV-05, up to 12 points)
pmat infra-score
```

### Enforcement Chain

| Check | Level | What it enforces |
|-------|-------|-----------------|
| CB-1200 | L0.5 | Contract existence + pv lint + binding coverage |
| CB-1201 | L0.5 | pv lint pass/fail with error detail |
| CB-1202 | L1 | Critical keyword coverage (forward, backward, kernel) |
| CB-1203 | L3 | Contract annotation coverage on bound functions |
| CB-1204 | L1 | build.rs pipeline enforcement |
| CB-1205 | L4 | Provability invariant (obligations to kani harnesses) |
| CB-1206 | L4/L5 | Verification level distribution per-project |
| CB-1207 | -- | Contract drift (stale YAML vs source, 90-day threshold) |
| CB-1208 | L1-L3 | Binding existence + enforcement level (L0-L3) |
| CB-1209 | L2 | Contract trait enforcement (13 kernel traits) |
| CB-1210 | L3 | YAML precondition diversity |
| CB-1211 | L3 | Codegen fidelity -- placeholder ratio check |
| CB-1214 | L3 | Enforcement quality -- call-site penetration x quality |

### Enforcement Levels (CB-1208)

CB-1208 detects the enforcement level for each project dynamically:

| Level | Mechanism | Detection |
|-------|-----------|-----------|
| L3 | build.rs + traits | `build.rs` contains contract keywords AND `tests/contract_traits.rs` exists |
| L2 | traits only | `tests/contract_traits.rs` exists, no build.rs enforcement |
| L1 | build.rs only | `build.rs` contains "binding", "contract", or "AllImplemented" |
| L0 | paper-only | Neither mechanism present -- **FAIL** (ghost bindings) |

L0 repos with binding.yaml entries but no enforcement are flagged as "ghost bindings" and fail CB-1208. Workspace projects with `crates/*/src/` layouts are fully scanned.

## Example: Writing and Validating a Contract

### Step 1: Write a Contract YAML

Create `contracts/my-project/my-kernel-v1.yaml`:

```yaml
name: my-kernel-v1
version: "1.0"
metadata:
  description: "Vector normalization kernel"

equations:
  normalize:
    formula: "normalize(x)_i = x_i / ||x||_2"
    preconditions:
      - 'x.iter().all(|v| v.is_finite())'
      - 'x.iter().any(|v| *v != 0.0)'
    postconditions:
      - '(result.iter().map(|v| v * v).sum::<f32>() - 1.0).abs() < 1e-5'
    proof_obligations:
      - type: invariant
        description: "Output has unit L2 norm"
      - type: bound
        description: "All outputs in [-1, 1]"

falsification_tests:
  - rule: "zero vector panics"
    input: "[0.0, 0.0, 0.0]"
    expect: panic
```

### Step 2: Validate and Lint

```bash
# Validate schema correctness
pv validate contracts/my-project/my-kernel-v1.yaml

# Run the 7-gate quality pipeline
pv lint contracts/my-project/
```

The 7 lint gates are: validate, audit, score, verify (test refs), enforce (pre/post/Lean), enforcement-level, and reverse-coverage.

### Step 3: Score

```bash
pv score contracts/my-project/my-kernel-v1.yaml
```

Output shows five dimensions: Spec depth, Falsification coverage, Kani harness coverage, Lean proof coverage, and Binding coverage, with an A-F letter grade.

### Step 4: Scaffold Implementation

```bash
pv scaffold contracts/my-project/my-kernel-v1.yaml
```

This generates a Rust trait with the function signature and failing test stubs for each postcondition and proof obligation.

### Step 5: Generate Enforcement Code

```bash
# Generate debug_assert!() macros from preconditions/postconditions
pv codegen contracts/my-project/ --output src/generated_contracts.rs

# Generate Kani bounded model checking harnesses
pv kani contracts/my-project/my-kernel-v1.yaml
```

## The pmat-work Lifecycle Contract (DBC-for-DBC)

The `work-dbc-v1.yaml` contract applies Design by Contract to the `pmat work` lifecycle itself -- a "contract about contracts" ensuring the quality gate system is self-consistent.

Key equations in the work DBC contract:

- **work_lifecycle**: Planned -> InProgress -> Review -> Completed state machine (mirrors `ItemStatus` enum)
- **meyer_triad**: require/ensure/invariant clause checking at Start/Checkpoint/Complete phases
- **checkpoint_verification**: idempotent invariant checking with score delta from baseline
- **falsifiable_claim**: Popperian claims with deterministic verdicts
- **override_accountability**: `--override-claims` requires `--ticket` for accountability
- **rescue_protocol**: Meyer Section 11 bounded retry strategies

This contract scores 0.88 (B) with 10 falsification tests, 10 proof obligations, and 10 Kani harnesses. It lives at `contracts/pmat/work-dbc-v1.yaml` in the provable-contracts repo.

## Running Examples

The provable-contracts crate ships examples for each pipeline phase:

```bash
# Validate contract schema
cargo run --example validate_contracts

# Score contracts (five-dimension quality metric)
cargo run --example score_contracts

# Generate scaffolding (trait stubs + failing tests)
cargo run --example scaffold_generation

# Generate Lean 4 codegen
cargo run --example lean_codegen

# Check Lean proof status
cargo run --example lean_status

# Run traceability audit
cargo run --example audit

# Generate Kani harnesses
# (requires provable-contracts repo checked out)
cargo run --example proof_status

# Design by Contract demo
cargo run --example design_by_contract
```

All examples run against contracts shipped in the `contracts/` directory and require no external tooling beyond `cargo`.

## Fleet-Wide Enforcement

`pv kaizen` measures contract enforcement across the entire sovereign stack:

```bash
cd provable-contracts && pv kaizen
```

Current fleet status (33 repos):

| Metric | Value |
|--------|-------|
| Total bindings | 660 |
| Call sites | 411+ |
| Penetration | 62.3% |
| E0 (generic assertions) | 43 |
| E1 (domain precondition) | 136 |
| E2 (pre + postcondition) | 232 |
| Total assertions | 14,436+ |

### E-Level Classification

| Level | Score | Meaning |
|-------|-------|---------|
| E0 | 0.1 | Generic `!is_empty()` assertion at call site |
| E1 | 0.5 | Domain-specific precondition check only |
| E2 | 1.0 | Both precondition and postcondition checks |

Repos are graded A-F based on call-site enforcement quality. Mature repos (bashrs, decy, forjar, batuta) score A; repos with bindings but no call sites score F. `pv kaizen` identifies the highest-ROI upgrade targets by sorting unbound call sites by PageRank criticality.

### Sibling Contract Resolution

`pmat comply` resolves contract YAML from a sibling `provable-contracts` repository rather than requiring contracts inside each project. It reads `Cargo.toml` to extract the package name, then probes `../provable-contracts/contracts/<pkg>/` for YAML files. This enables a single monorepo of contracts to serve the entire fleet without duplicating YAML across repositories.

## Agent Contract Enforcement (CB-1400 to CB-1410)

AI agents operating on the sovereign stack must work contract-first. The CB-1400 series ensures no agent generates code without a prior contract:

| Check | Enforcement |
|-------|------------|
| CB-1400 | Agent context files (CLAUDE.md, GEMINI.md) reference contract-first |
| CB-1401 | Work contracts have falsifiable claims with evidence |
| CB-1402 | Verification level >= L1 (L0 paper-only blocked for autonomous agents) |
| CB-1403 | Assume-guarantee chains validated for multi-agent workflows |
| CB-1408 | Evidence mechanisms are executable (not placeholder) |
| CB-1409 | AI-authored commits (Co-Authored-By) have work contracts |
| CB-1410 | Iterative contracts compose correctly (Liskov substitution) |

CB-1402 enforces a hard floor: autonomous agents may NOT operate at L0 (human review only). Every AI commit must trace to a work contract with at least L1 verification (type-system or quality-gate enforcement).

## Key Metrics

| Metric | Value |
|--------|-------|
| Contract YAML files | 315+ |
| Scored contracts | 266 |
| Mean score | 0.70 (C) |
| Lean theorems | 93 (1 sorry) |
| Lean theorem files | 56 |
| Binding registries | 15 crates |
| Fleet repos | 33 |
| Proof obligation types | 26 |
| Lint gates | 7 |
| CB enforcement checks | 20 (CB-1200..1214 + CB-1400..1410) |

## Configurable Thresholds

Configure PV enforcement strictness in `.pmat.yaml`:

```yaml
comply:
  thresholds:
    pv_lint_is_error: true
    min_binding_existence: 95
    require_all_traits: true
    min_kani_coverage: 20
```

## Adding Provable Contracts to Your Project

1. **Create a contract** in `../provable-contracts/contracts/<your-crate>/`:

```yaml
name: my-kernel-v1
version: "1.0"
equations:
  my_function:
    preconditions:
      - 'x.iter().all(|v| v.is_finite())'
    postconditions:
      - 'result.len() == x.len()'
```

2. **Generate assertions**: `pv codegen contracts/<your-crate>/ -o src/generated_contracts.rs`

3. **Add macro invocations** at call sites:

```rust
pub fn my_function(x: &[f32]) -> Vec<f32> {
    contract_pre_my_function!(x);
    let result = my_function_impl(x);
    contract_post_my_function!(result);
    result
}
```

4. **Add build.rs enforcement** for L1+ level (compiler refuses to build if bindings are missing).

5. **Add trait tests** for L2+ level: create `tests/contract_traits.rs` with trait implementations from `provable_contracts::traits`.

6. **Run compliance**: `pmat comply check` to verify all CB-1200 checks pass.

## TDD Verification

```bash
$ pmat comply check 2>&1 | grep CB-1210
# CB-1210: Precondition Quality: 1881 preconditions, 899 unique (86% diverse)

$ pmat comply check 2>&1 | grep CB-1214
# CB-1214: Enforcement Quality: 47 call sites, quality=0.80, enforcement=0.71
```
