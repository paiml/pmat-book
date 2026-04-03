# Chapter 62: Provable Contracts (CB-1200 to CB-1214)

The provable-contracts enforcement chain validates that Design by Contract (DbC) principles are applied correctly across the sovereign AI stack. It checks contract YAML quality, codegen fidelity, binding existence, and call-site enforcement quality.

## Overview

`pmat comply check` runs 13 provable-contracts checks (CB-1200 through CB-1214, with CB-1212 and CB-1213 specified but not yet implemented). These checks span the verification ladder from L0 (paper-only) to L5 (Lean-proved).

```bash
# Run all compliance checks
pmat comply check

# Filter to PV checks only
pmat comply check 2>&1 | grep 'CB-12'

# Get infra-score bonus (PV-01..PV-05, up to 12 points)
pmat infra-score
```

## Enforcement Chain

| Check | Level | What it enforces |
|-------|-------|-----------------|
| CB-1200 | L0.5 | Contract existence + pv lint + binding coverage |
| CB-1201 | L0.5 | pv lint pass/fail with error detail |
| CB-1202 | L1 | Critical keyword coverage (forward, backward, kernel, etc.) |
| CB-1203 | L3 | Contract annotation coverage on bound functions |
| CB-1204 | L1 | build.rs pipeline enforcement |
| CB-1205 | L4 | Provability invariant (obligations → kani harnesses) |
| CB-1206 | L4/L5 | Verification level distribution per-project |
| CB-1207 | — | Contract drift (stale YAML vs source, 90-day threshold) |
| CB-1208 | L1-L3 | Binding existence + enforcement level (L0-L3) |
| CB-1209 | L2 | Contract trait enforcement (13 kernel traits) |
| CB-1210 | L3 | YAML precondition diversity |
| CB-1211 | L3 | Codegen fidelity — placeholder ratio check |
| CB-1214 | L3 | Enforcement quality — call-site penetration × quality |

## Enforcement Levels (CB-1208)

CB-1208 detects the enforcement level for each project dynamically:

| Level | Mechanism | Detection |
|-------|-----------|-----------|
| L3 | build.rs + traits | `build.rs` contains contract keywords AND `tests/contract_traits.rs` exists |
| L2 | traits only | `tests/contract_traits.rs` exists, no build.rs enforcement |
| L1 | build.rs only | `build.rs` contains "binding", "contract", or "AllImplemented" |
| L0 | paper-only | Neither mechanism present — **FAIL** (ghost bindings) |

L0 repos with binding.yaml entries but no enforcement are flagged as "ghost bindings" and fail CB-1208.

**Workspace support**: CB-1208 scans both `src/` and `crates/*/src/` when searching for bound functions, so workspace projects with multiple crates are fully supported.

## Precondition Quality (CB-1210)

CB-1210 scans YAML contract preconditions for diversity and flags mass-generated placeholder patterns.

**FAIL when:**
- YAML precondition diversity < 30% (>70% of preconditions are identical)
- More than 5% of equations have only placeholder preconditions like `!input.is_empty()`

```yaml
# Good: domain-specific preconditions
equations:
  softmax:
    preconditions:
      - 'x.iter().all(|v| v.is_finite())'
      - 'x.len() > 0'

# Bad: placeholder-only preconditions (CB-1210 will flag)
equations:
  my_kernel:
    preconditions:
      - '!input.is_empty()'
```

## Codegen Fidelity (CB-1211)

CB-1211 verifies that generated `debug_assert!` assertions are not dominated by placeholder patterns.

**Detection:** Counts total `debug_assert!` lines in `generated_contracts.rs` (excluding comments) and how many contain the known placeholder `_contract_input.is_empty()`.

| Result | Condition |
|--------|-----------|
| FAIL | Placeholder assertions > 50% of total |
| WARN | 0 assertions from N preconditions (all skipped by `has_unbound_vars()`) |
| SKIP | No generated file and pv CLI not available |
| PASS | Placeholder ratio ≤ 50% |

**Note:** Generated assertion count may be less than YAML precondition count because codegen skips assertions with unbound variables (e.g., multi-arg equations where `m`, `k`, `n` can't be mapped to the macro's single input parameter).

## Enforcement Quality (CB-1214)

CB-1214 runs `pv coverage --enforcement` to measure contract call-site penetration and quality.

### E-Level Classification

| Level | Score | Meaning |
|-------|-------|---------|
| E0 | 0.1 | Generic `!is_empty()` assertion at call site |
| E1 | 0.5 | Domain-specific precondition check only |
| E2 | 1.0 | Both precondition and postcondition checks |

**Quality** = weighted average of E-levels across call sites.
**Enforcement** = penetration (call sites / bindings) × quality.

### Decision Logic

| Result | Condition |
|--------|-----------|
| FAIL | quality < 0.3 AND >30 call sites AND has mixed E-levels |
| WARN | quality < 0.3 with E0-only (legitimate transition) |
| WARN | 0 call sites (contracts exist but never invoked) |
| SKIP | pv CLI not available |
| PASS | quality ≥ 0.3 |

### Example Output

```text
✓ CB-1214: Enforcement Quality: 47 call sites (E0=0, E1=19, E2=28), quality=0.80, enforcement=0.71
```

## Contract Annotations (CB-1203)

CB-1203 checks that functions matching contract equation names have contract annotations. It recognizes:

- `#[contract(equation = "...")]` proc-macro attribute
- `#[requires(...)]` / `#[ensures(...)]` attributes
- `contract_pre_*!` macro invocations in the function body
- `// Contract:` comments in the function body

## Infra-Score Bonus (PV-01..PV-05)

`pmat infra-score` awards up to 12 bonus points for provable-contracts quality:

| Check | Points | What it checks |
|-------|--------|----------------|
| PV-04 | 2 | contracts/ directory exists with schema-valid YAML |
| PV-01 | 3 | `pv lint` passes (falls back to YAML structure check) |
| PV-02 | 3 | `pv score >= 0.5` (requires pv CLI) |
| PV-03 | 2 | At least one contract at proof level L2+ |
| PV-05 | 2 | Enforcement quality — `pv coverage --enforcement` finds call sites |

## Configurable Thresholds

Configure PV enforcement strictness in `.pmat.yaml`:

```yaml
comply:
  thresholds:
    pv_lint_is_error: true        # CB-1201: treat lint failure as error
    min_binding_existence: 95     # CB-1208: % threshold for binding verification
    require_all_traits: true      # CB-1209: require 13/13 traits
    min_kani_coverage: 20         # CB-1206: minimum Kani proof %
```

Additional thresholds are hardcoded (not yet configurable):

| Check | Threshold | Value |
|-------|-----------|-------|
| CB-1210 | Precondition diversity minimum | 30% |
| CB-1210 | Placeholder-only equation maximum | 5% |
| CB-1211 | Placeholder assertion ratio maximum | 50% |
| CB-1214 | Enforcement quality minimum | 0.3 (with >30 call sites and mixed E-levels) |

## Adding Provable Contracts to Your Project

1. **Create contracts/** with YAML files following the provable-contracts schema:

```yaml
metadata:
  version: "1.0.0"
  description: "My kernel contract"

equations:
  my_function:
    formula: "f(x) = ..."
    preconditions:
      - 'x.iter().all(|v| v.is_finite())'
    postconditions:
      - 'result.len() == x.len()'
```

2. **Generate assertions**: `pv codegen contracts/ -o src/generated_contracts.rs`

3. **Add macro invocations** at call sites:

```rust
pub fn my_function(x: &[f32]) -> Vec<f32> {
    contract_pre_my_function!(x);
    let result = my_function_impl(x);
    contract_post_my_function!(result);
    result
}
```

4. **Add build.rs enforcement** for L1+ level:

```rust
fn main() {
    // AllImplemented policy: binding.yaml entries must exist in source
    println!("cargo:rerun-if-changed=contracts/");
}
```

5. **Add trait tests** for L2+ level: create `tests/contract_traits.rs` with trait implementations from `provable_contracts::traits`.

## Examples

```bash
# Run the provable contracts demo
cargo run --example provable_contracts_demo

# Run the enforcement quality demo
cargo run --example enforcement_quality_demo
```

## TDD Verification

```rust
# // Verify CB-1210 detects placeholder preconditions
# let yaml = "equations:\n  test:\n    preconditions:\n      - '!input.is_empty()'";
# // CB-1210 flags this as placeholder-only
```

```bash
$ pmat comply check 2>&1 | grep CB-1210
✓ CB-1210: Precondition Quality: 1881 preconditions, 899 unique (86% diverse), 27 postconditions
```

```bash
$ pmat comply check 2>&1 | grep CB-1214
✓ CB-1214: Enforcement Quality: 47 call sites (E0=0, E1=19, E2=28), quality=0.80, enforcement=0.71
```

## Sibling Contract Resolution

`pmat comply` now resolves contract YAML from a sibling `provable-contracts` repository rather than requiring contracts to live inside each project. The `resolve_contracts_dir` function reads the project's `Cargo.toml` to extract the package name, then probes `../provable-contracts/contracts/<pkg>/` for YAML files. If the directory exists but is empty (no `.yaml` files), the check is skipped cleanly instead of producing a misleading PASS. This enables a single monorepo of contracts to serve an entire fleet of sovereign-stack crates without duplicating YAML across 27 repositories.

## Sovereign Stack Coverage

The provable-contracts fleet now covers **178+ contracts across 37+ repos** (full sovereign stack penetration).

| Domain | Contracts | Key repos |
|--------|-----------|-----------|
| Math/ML kernels | 95 | entrenar, aprender, trueno |
| PMAT infrastructure | 14 | CLI, MCP, graph, concurrency, memory, state machine, work DBC (v2.0) |
| IaC heavy types | 13 | forjar |
| CLI/MCP/HTTP boundaries | 8 | aprender (cli-dispatch, http-api, mcp-tool-schema), depyler (cli-transpile), bashrs (cli-lint), batuta (cli-oracle), presentar (tui-lifecycle) |
| Sovereign stack (remaining) | 48+ | trueno-graph, trueno-db, trueno-rag, trueno-viz, trueno-zram-core, renacer, certeza, probar, pmcp, pzsh, rclean, zenith, and others |

### Work DBC Contract (v2.0)

The `work-dbc-v1.yaml` contract enforces Design by Contract on the `pmat work` lifecycle itself — a "contract about contracts" that ensures the quality gate system is self-consistent.

Key equations:
- **work_lifecycle**: Planned→InProgress→Review→Completed state machine (matches `ItemStatus` enum)
- **meyer_triad**: require/ensure/invariant clause checking at Start/Checkpoint/Complete phases
- **checkpoint_verification**: idempotent invariant checking with score delta from baseline
- **falsifiable_claim**: 22 Popperian claims with deterministic verdicts
- **override_accountability**: `--override-claims` requires `--ticket` for accountability
- **rescue_protocol**: Meyer Section 11 bounded retry strategies

Score: **0.88 (B)** with binding (D2=1.00, D3=0.96). The contract has 10 falsification tests, 10 proof obligations, and 10 kani harnesses.

Every repo has at least one domain-specific contract with preconditions beyond placeholder `!input.is_empty()` patterns. CB-1210 precondition diversity holds at 86% fleet-wide.

## Section 34 Systems Contract Patterns

The `provable-contracts` repository now includes **29 reusable systems-contract patterns** in `section-34/`, backed by **52 arXiv papers**. These patterns provide ready-made YAML templates for contract obligations that arise repeatedly in systems programming.

The 7 pattern domains:

| Domain | Scope |
|--------|-------|
| **Threading** | Mutex ordering, deadlock freedom, thread-pool bounds |
| **Async** | Future cancellation safety, waker correctness, backpressure |
| **Compute** | SIMD lane invariants, numerical stability, kernel convergence |
| **Memory** | Arena lifetime, pool exhaustion, alignment guarantees |
| **LLM** | Token budget, prompt injection guards, embedding dimension |
| **Transpiler** | Semantic equivalence, round-trip fidelity, AST invariant preservation |
| **Cross-cutting** | Idempotency, retry budgets, graceful degradation |

Each pattern includes a motivation section citing the relevant paper, a YAML template with parameterized preconditions and postconditions, and a verification-level recommendation (L1 through L5).

## Fleet Enforcement Status (pv kaizen)

`pv kaizen` reports fleet-wide enforcement health:

| Metric | Value |
|--------|-------|
| Grade | **B** (0.53) |
| Penetration | 71% (call sites / bindings) |
| Bindings | 559 |
| Call sites | 398 |

The grade reflects the transition from E0 placeholder assertions to E1/E2 domain-specific checks still in progress across the fleet. Repos with mature contracts (entrenar, aprender, trueno) score above 0.7; newer repos pull the average down. The `pv kaizen` command identifies the highest-ROI upgrade targets by sorting bindings without call sites by PageRank criticality.
