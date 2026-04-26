# Chapter 72: Wave 39 — 80% Coverage Milestone and Four Real Bugs Found by PIN Tests

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ Case study — released as pmat v3.16.0

*Released: 2026-04-26*
*PMAT version: 3.16.0*
*Coverage trajectory: 78.74% → 80.02% broad-gate*
*PR: paiml/paiml-mcp-agent-toolkit#552*
<!-- DOC_STATUS_END -->

## Why This Chapter Exists

The previous chapters (R7, R8, R9, R11) documented dogfooding rounds where pmat
hunted bugs in *other* repos. Wave 39 is the inverse: the coverage initiative
hunted bugs **in pmat itself**. Four of them. All caught by the same mechanism —
PIN tests on freshly-covered pure helpers.

The chapter is a worked example of three claims that the coverage spec
(`docs/specifications/improve-coverage-80-95.md`) had only asserted abstractly:

1. Drip-feed unit tests on pure helpers do **not** lift broad coverage on their
   own — they pin behavior.
2. Pinning behavior on freshly-touched code routinely surfaces real bugs.
3. Lever (d) — integration tests on multi-branch entry points — is the only
   mover for the broad gate, but it produces heterogeneous yield.

## The Four Bugs

| # | File | Symptom | Root cause | Fix |
|---|------|---------|------------|-----|
| 1 | `src/handlers/tools_advanced_part3.rs` | `count_violations_by_severity` returned the total violation count regardless of `target_severity` | Missing `.filter(...)` before `.count()` | One-line `.filter(\|v\| v.severity == target_severity)` |
| 2 | `src/services/deep_wasm/disassembler_formatting.rs` | F32/F64 arithmetic ops emitted `f64add` (no dot) instead of WASM-canonical `f64.add` | All eight ops fell through `_ =>` default which lowercases `Debug` output (`Operator::F64Add` → `"f64add"`) | Eight explicit arms matching the I32/I64 family |
| 3 | `src/services/rust_project_score/orchestrator.rs` | `discover_workspace_members` failed on multi-line `members = [ ... ]` arrays with trailing commas | `.trim_matches('"').trim_matches(',')` only strips one char per call (greedy left-to-right) | `trim_matches(\|c\| c == '"' \|\| c == '\'' \|\| c == ',')` |
| 4 | `src/services/cargo_dead_code_analyzer/analysis.rs` | Dead-code analysis crashed on bin-only crates (no `lib.rs`) | Always passed `--lib` to cargo regardless of crate kind | New `project_has_library()` helper checks `src/lib.rs` OR `[lib]` section, conditionally chooses `--lib` vs `--bins` |

Every fix is paired with a renamed PIN test that asserts the **fixed** behavior,
plus a contract decorator on the helper. So the regression armor is dual: a
locked-in test + a Hoare-style precondition checked at every call site.

## The PIN-Test Discipline

The mechanism that surfaces bugs:

1. Pick a fat-target file (~500 lines, 0 tests, mostly pure helpers).
2. Write a unit test for one helper. Compute the *expected* output by hand —
   not by running the helper.
3. If the test fails, you have one of two things:
   - A bug in the helper.
   - A wrong expectation.
4. Diff between the expected and the actual until you know which.

The four bugs in this chapter were all in case 4(a): the helper was wrong, the
expectation was right, and the test caught it.

This is the inverse of the more common "the test asserts whatever the function
returns" anti-pattern. The Wave 39 PR retroactively renamed several existing
"agent-added test with incorrect assertion" cases (35 deleted across the
codebase) — these were written by tests-asserting-actual rather than
tests-asserting-expected.

## What Did *Not* Move the Coverage Gate

The same wave produced an empirical lever model (spec §4.11). Seven broad-gate
measurements over 28 PRs:

| Lever | Δ broad-gate | Mechanism |
|-------|--------------|-----------|
| (a) orphan-delete unreached files | **0pp** | LOC denominator drop only matters if file was truly unreached |
| (b) drip-feed unit tests on pure helpers | **0pp** | Helpers were already reachable from existing parent tests |
| (c) snapshot-suite reactivation | exhausted | One-shot |
| (d) integration tests on multi-branch entry points | **+0.3 to +1.0pp / PR** | Only mover; yield heterogeneous (4× spread) |
| (e) `coverage(off)` removal | **0pp** | Confirmed per spec §4.6 R3 |

The HIGH-yield integration PRs added 27–35 lines covered per test. The
LOW-yield drip-feed PRs added 1–10 lines. Same line of effort, ~4× yield gap.
The takeaway in §4.11: **discipline-vs-volume**. Pick the right lever (d), and
write integration tests against multi-branch entry points like `analyze_source`
or `analyze_program`, not unit tests against pure helpers — the helpers are
already reached.

## What the Drip-Feed *Did* Buy

Reframed as **pinning, not convergence** (memory:
`feedback_fat_target_falsified_on_broad.md`):

- 354 new tests across 28 PRs.
- 7 new `#[contract("pmat-core.yaml", equation = "check_compliance")]`
  decorators on pure public/static helpers (per the always-improving-contracts
  directive).
- 4 real bugs surfaced and fixed.
- Net codebase shrunk by **−16,733 LOC** (orphan + dead-code cleanup outweighs
  new tests).
- Crossed the 80% line for the first time, primarily on lever (d) PRs that
  rode in alongside the drip-feed.

The drip-feed earned its keep as **regression armor**, not as a coverage
mover. Every helper now has a test that will fail if its semantics drift.

## Reproducing

```bash
# Verify the bugs are fixed in v3.16.0
cargo install pmat --version 3.16.0
pmat --version  # → pmat 3.16.0

# BUG #2 fix — check WASM disassembler emits dotted form
echo "(module (func (result f64) f64.const 1.0 f64.const 2.0 f64.add))" \
  | wat2wasm - -o /tmp/add.wasm
pmat analyze deep-wasm /tmp/add.wasm --format json | grep -F '"f64.add"'
# Should print: "mnemonic": "f64.add"   (NOT "f64add")

# BUG #3 fix — workspace member discovery on multi-line arrays
cat > /tmp/Cargo.toml <<'EOF'
[workspace]
members = [
    "crate-a",
    "crate-b",
]
EOF
pmat analyze cargo-rust-project-score --workspace /tmp 2>&1 | grep -E "crate-a|crate-b"
# Should detect both members (BUG #3 dropped them due to trailing commas)
```

## The Spec the Wave Produced

The most durable artifact is **§4.11** of
`docs/specifications/improve-coverage-80-95.md` — the empirical lever model.
It replaces an earlier hopeful prediction ("each cleanup wave should add ~2pp")
with the measured reality (cleanup waves add 0pp; only multi-branch integration
tests move the gate). Future coverage work in pmat should plan against the
measured model, not the hopeful one.

## See Also

- Spec: `docs/specifications/improve-coverage-80-95.md` §4.11
- PR: [paiml/paiml-mcp-agent-toolkit#552](https://github.com/paiml/paiml-mcp-agent-toolkit/pull/552)
- Tag: [v3.16.0](https://github.com/paiml/paiml-mcp-agent-toolkit/releases/tag/v3.16.0)
- crates.io: [pmat 3.16.0](https://crates.io/crates/pmat/3.16.0)
- Chapter 62: Provable Contracts (the contract decorators added in this wave)
- Chapter 67: Dogfooding pmat (R5 — original 58 defects in 5 rounds)
