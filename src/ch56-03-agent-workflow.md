# Agent Workflow: From `pmat work start --implements` to CB-1620 Cutoff

*Deep dive: Chapter 56, Section 3*

The CB-16xx gates describe what PMAT checks for. This sub-chapter shows what an agent *does*, start to finish — creating a ticket, binding it to a provable-contracts YAML, watching tiered-skip checks turn green as evidence files are produced, and handling the CB-1620 migration cutoff.

The worked example uses a real kernel scenario: implementing RoPE (Rotary Position Embedding) from the bound contract `contracts/rope-kernel-v1.yaml`. Every command is a real `pmat work` or `pmat comply` invocation, and every file written is shown with its actual schema.

## Scenario: Implementing RoPE at L4

The YAML contract already exists in `../provable-contracts/contracts/rope-kernel-v1.yaml`. It declares two equations (`rope`, `rope_inverse`), three falsification tests, two Kani harnesses, and a Lean theorem (status: `"proved"`). Attainable ceiling: **L5**. Our target: **L4** (Kani-verified without Lean work).

The author's mental model: "I'll write the Rust implementation, bind to the equation, generate codegen preconditions, run the falsification suite, then cargo-kani. If all of that passes, I've reached L4."

## Step 1: Create the Ticket

```bash
pmat work start PMAT-301 --title "Implement rope kernel SIMD path"
```

This scaffolds `.pmat-work/PMAT-301/contract.json` with default claims (22 Popperian falsification claims per `work_contract.rs`). The full struct is in `work_contract_core.rs`:

```json
{
  "version": "4.0",
  "work_item_id": "PMAT-301",
  "created_at": "2026-04-17T09:00:00Z",
  "baseline_commit": "abc1234",
  "baseline_tdg": 87.3,
  "baseline_coverage": 94.8,
  "baseline_rust_score": 238,
  "baseline_file_manifest": { "files": [] },
  "thresholds": { "min_coverage_pct": 95.0, "min_tdg_regression": 0.0, "…": "…" },
  "claims": [
    { "hypothesis": "baseline coverage regression", "falsification_method": "AbsoluteCoverage", "…": "…" }
  ],
  "require": [],
  "ensure": [],
  "invariant": [],
  "verification_level": "L3",
  "implements": []
}
```

Notice `verification_level: "L3"` — the default baked into `default_verification_level()`. Notice also `implements: []` — the ticket is **unbound** at this stage.

Run `pmat comply check` now and every CB-16xx check returns Skip:

```
CB-1600: Binding Scope Orphan: Pass (0 staged bound file(s))
CB-1601: Binding SHA Drift: Skip (No ticket has `implements:` bindings)
CB-1610: Verification Level Parses: Pass (1 ticket level(s) parse to L0..L5)
CB-1611: Target ≤ Max Attainable: Skip (No ticket has `implements:` bindings)
CB-1612: L1 Test Evidence: Skip (No ticket has `verification-report.json` yet)
CB-1613: L3 Falsification Evidence: Skip (No L3+ ticket has a `falsification.log` yet)
CB-1614: L4 Kani Evidence: Skip (No L4+ ticket present)
CB-1615: Kani Harness SHA: Skip (No L4+ ticket present)
CB-1616: L5 Lean Proof Zero-Sorry: Skip (No L5 ticket present)
CB-1620: Inherited Roster Coverage: Skip (No ticket has `implements:` bindings)
...
```

All informational. The checks are live but there's nothing yet to check.

## Step 2: Bump Target Level and Bind

In v3.14.0 the binding step is folded into `pmat work start` via the repeatable `--implements <CONTRACT>/<EQUATION>` flag. A standalone `pmat work bind` subcommand is planned for a follow-up release; today, re-run `start` (or the alias `begin`) with `--implements` to establish the binding, and edit `.pmat-work/PMAT-301/contract.json` directly to promote `verification_level` to `"L4"`:

```bash
pmat work start PMAT-301 --implements rope-kernel-v1/rope
```

What happens inside the bind step (see `work_contract_binding.rs`):

1. Parse `rope-kernel-v1/rope` into `(contract="rope-kernel-v1", equation="rope")`.
2. Locate the YAML via the search path:
   - `contracts/rope-kernel-v1.yaml`
   - `../provable-contracts/contracts/rope-kernel-v1.yaml`
   - Any entry in `$PMAT_CONTRACTS_PATH`
3. Read the YAML bytes; compute SHA-256.
4. Write a `ContractBinding` into `contract.json`:

```json
{
  "implements": [
    {
      "contract": "rope-kernel-v1",
      "equation": "rope",
      "file": "../provable-contracts/contracts/rope-kernel-v1.yaml",
      "sha": "7f3a9b2e8c1d4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a",
      "bound_at": "2026-04-17T09:02:00Z"
    }
  ]
}
```

5. **Capture the ProvableContract snapshot.** Read the YAML's `falsification_tests[]` array and seed one `FalsificationMethod::ProvableContract{}` entry into `claims[]` per test. From `work_contract_falsification.rs`:

```rust
FalsificationMethod::ProvableContract {
    yaml_path: PathBuf::from("../provable-contracts/contracts/rope-kernel-v1.yaml"),
    equation: "rope".into(),
    test_id: "rope_periodicity_test".into(),
    expected: "true".into(),   // canonical JSON of the YAML's `expected:` scalar
}
```

Three such entries are added, one per YAML test (`rope_periodicity_test`, `rope_linearity_test`, `rope_bounded_rotation_test`).

6. **Write the Kani harness SHA snapshot.** `.pmat-work/PMAT-301/kani-harness-shas.json`:

```json
{
  "harnesses": [
    { "name": "verify_rope_periodicity", "sha": "a1b2c3d4e5f67890abcdef1234567890abcdef1234567890abcdef1234567890" },
    { "name": "verify_rope_linearity",   "sha": "b2c3d4e5f67890a1bcdef1234567890abcdef1234567890abcdef1234567890a" }
  ]
}
```

The `sha:` values are the SHA-256 of each harness body as declared in the YAML's `kani_harnesses:` block at bind time. CB-1615 will later compare these against current YAML values to detect drift.

7. Update `contract.json`'s `require:` / `ensure:` arrays with inherited clauses from the YAML's `equations.rope.preconditions` and `equations.rope.postconditions`. CB-1603 (inherited clause integrity) now has something to check.

## Step 3: Re-Run comply — Watch Skips Collapse

```bash
pmat comply check 2>&1 | grep 'CB-16'
```

New output after bind:

```
CB-1600: Binding Scope Orphan: Pass (1 staged bound file(s))
CB-1601: Binding SHA Drift: Pass (All 1 binding SHA(s) match current YAML bytes)
CB-1603: Inherited Clauses: Pass (1 binding(s) with inherited clauses preserved)
CB-1605: Kani Binding: Skip (No `kani-report.json` yet for any ticket)
CB-1607: Binding Equation Identifier: Pass (All 1 equation(s) resolve in their YAML)
CB-1608: Cross-Binding Consistency: Skip (No multi-bind ticket has a log yet)
CB-1609: Binding File Tracked: Pass (YAML tracked in git)
CB-1611: Target ≤ Max Attainable: Pass (1 bound ticket(s) within max-attainable ceiling)
CB-1614: L4 Kani Evidence: Skip (No L4+ ticket has a `kani-report.json` yet (1 eligible))
CB-1615: Kani Harness SHA: Skip (Bind-time snapshot(s) found but all empty)
CB-1620: Inherited Roster Coverage: Pass (All bound tickets have inherited ProvableContract entries)
CB-1621: Expected Snapshot Drift: Pass (3 ProvableContract snapshot(s) match current YAML `expected:`)
CB-1622: Roster Execution Coverage: Skip (No log yet)
CB-1623: No Duplicate ProvableContract Entries: Pass
CB-1626: Referenced test_id Exists in YAML: Pass (all 3 resolve)
```

Eight checks transitioned **Skip → Pass** purely from the bind step. Three remain Skip pending runner execution: CB-1605 (Kani report), CB-1614 (Kani evidence), CB-1622 (falsification execution).

This is the tiered-skip design paying off: no configuration change, no flag, just evidence-driven activation.

## Step 4: Run Code + Unit Tests (L1 Evidence)

Write the Rust implementation. Add `#[pmat_work_contract]` attributes on the public functions:

```rust
#[pmat_work_contract(id = "PMAT-301", require = "R1", ensure = "E1")]
pub fn rope_rotate(x: &[f32], theta: f32) -> Vec<f32> {
    // …SIMD implementation…
}
```

Run `cargo test --lib`, then:

```bash
pmat work verify PMAT-301
```

This writes `.pmat-work/PMAT-301/verification-report.json`:

```json
{
  "target_level": "L4",
  "achieved_level": "L1",
  "l1_test_evidence": {
    "success": true,
    "exit_code": 0,
    "status": "pass",
    "passed": 47,
    "failed": 0
  },
  "verified_at": "2026-04-17T10:30:00Z"
}
```

CB-1612 now passes:

```
CB-1612: L1 Test Evidence: Pass (1 ticket(s) recorded green L1 test evidence)
```

CB-1619 also passes *for now* because `achieved_level: "L1"` is not less than itself — the comparison is `achieved < target`, and this ticket is still mid-journey so `achieved` is the running value. The ticket only fails CB-1619 if it gets *closed* with `achieved_level < target_level`.

## Step 5: Codegen — `contracts/work/PMAT-301.rs`

```bash
pmat work codegen PMAT-301
```

This reads the contract's `require:` and `ensure:` clauses, emits a Rust module at `contracts/work/PMAT-301.rs`:

```rust
// GENERATED — do not edit. Source: .pmat-work/PMAT-301/contract.json
pub fn r1_precondition(x: &[f32], theta: f32) -> bool {
    !x.is_empty() && theta.is_finite()
}

pub fn e1_postcondition(result: &[f32], x: &[f32]) -> bool {
    result.len() == x.len()
}
```

Writes `contracts/work/PMAT-301.manifest.json`:

```json
{
  "files": [
    { "path": "contracts/work/PMAT-301.rs", "sha256": "c3d4e5f67890abcdef…" }
  ]
}
```

Writes `codegen/last-run.json`:

```json
{
  "status": "pass",
  "exit_code": 0,
  "generated": ["contracts/work/PMAT-301.rs"],
  "at": "2026-04-17T11:00:00Z"
}
```

Writes `codegen/compile-status.json` after running `cargo check --profile dev` and `cargo check --release`:

```json
{ "debug": true, "release": true }
```

The codegen gates now light up:

```
CB-1630: Codegen Receipt: Pass (Most recent codegen exit=0, status=pass)
CB-1631: Module Existence: Pass (1 attribute usage has matching module)
CB-1632: Clause Match: Pass (1 attribute require/ensure matches clause ids)
CB-1633: Manifest SHA: Pass (1 manifest entry matches)
CB-1634: expr Clauses Have binds_to: Pass (all expr clauses have binds_to + attribute coverage)
CB-1636: Compile Profiles: Pass (debug and release compile)
CB-1638: Generated Modules Tracked: Pass (contracts/work/PMAT-301.rs tracked)
```

Seven more Skip → Pass transitions.

## Step 6: Run Falsification Suite (L3 Evidence)

```bash
pmat work falsify PMAT-301
```

This Component 29 runner executes the bound YAML's `falsification_tests[]` and appends JSONL lines to `.pmat-work/PMAT-301/falsification.log`:

```jsonl
{"yaml":"../provable-contracts/contracts/rope-kernel-v1.yaml","equation":"rope","test_id":"rope_periodicity_test","status":"pass","duration_ms":18}
{"yaml":"../provable-contracts/contracts/rope-kernel-v1.yaml","equation":"rope","test_id":"rope_linearity_test","status":"pass","duration_ms":24}
{"yaml":"../provable-contracts/contracts/rope-kernel-v1.yaml","equation":"rope","test_id":"rope_bounded_rotation_test","status":"pass","duration_ms":12}
```

The 4-field shape `{yaml, test_id, status, duration_ms}` is what CB-1628 expects. CB-1613, CB-1622, CB-1625, CB-1628 all transition to Pass:

```
CB-1613: L3 Falsification Evidence: Pass (1 L3+ log(s) checked, all entries pass)
CB-1622: Roster Execution Coverage: Pass (every roster entry has receipt)
CB-1625: Inherited Failure Fatal: Pass (all 3 inherited line(s) passed)
CB-1628: Per-run Log Line Emitted: Pass (1 log(s), 3 inherited line(s) carry 4-field shape)
```

At this point the ticket has discharged L3. The verification report is updated:

```json
{
  "target_level": "L4",
  "achieved_level": "L3",
  "l1_test_evidence": { "success": true, "status": "pass" },
  "falsification_summary": { "pass": 3, "fail": 0, "timeout": 0 }
}
```

## Step 7: Kani Verification (L4 Evidence)

```bash
pmat work kani PMAT-301
```

The Component 24 Kani runner executes `cargo kani --harness verify_rope_periodicity` and `cargo kani --harness verify_rope_linearity`, writes `.pmat-work/PMAT-301/kani-report.json`:

```json
{
  "success": true,
  "harnesses": ["verify_rope_periodicity", "verify_rope_linearity"],
  "counterexamples": [],
  "verified_at": "2026-04-17T13:45:00Z"
}
```

CB-1605 Kani Binding, CB-1614 L4 Kani Evidence, and CB-1615 Kani Harness SHA all transition to Pass:

```
CB-1605: Kani Harnesses Discharged: Pass (2/2 harness(es) green)
CB-1614: L4 Kani Evidence: Pass (1 L4+ Kani report(s) pass)
CB-1615: Kani Harness SHA: Pass (1 ticket(s) — Kani harness SHAs match bind-time snapshot)
```

CB-1615 specifically reads the bind-time `kani-harness-shas.json` and compares each entry against the current YAML's `kani_harnesses:` block. If between Step 2 (bind) and Step 7 (kani run) someone edited `verify_rope_periodicity` in the YAML without re-binding, the SHAs would differ and CB-1615 would fail with:

```
CB-1615: Kani Harness SHA:
  PMAT-301 [rope-kernel-v1/rope] harness `verify_rope_periodicity` SHA drifted: a1b2c3d4… → f9e8d7c6…
```

CB-1629 (L4 timeout) also passes because the falsification log had no `status: "timeout"` entries.

## Step 8: Complete the Ticket

```bash
pmat work complete PMAT-301
```

This updates `.pmat-work/PMAT-301/verification-report.json` with:

```json
{
  "target_level": "L4",
  "achieved_level": "L4",
  "l1_test_evidence": { "status": "pass" },
  "falsification_summary": { "pass": 3 },
  "kani_summary": { "success": true, "harnesses": 2 },
  "completed_at": "2026-04-17T14:30:00Z"
}
```

CB-1619 is now green: `achieved_level: "L4" >= target_level: "L4"`. The ticket passes compliance.

Final report:

```
Compliance Check Summary:
  Pass: 41    ← every CB-16xx check that has upstream evidence
  Skip: 9     ← L5 Lean, agent-runs, cot-digest, some others
  Warn: 0
  Fail: 0
```

Every Skip remaining is for evidence the ticket genuinely doesn't need (e.g. L5 Lean proof on an L4 ticket). The ticket is complete and every claim is discharged.

## What Happens if Evidence Drifts After Completion?

The gates keep watching. Suppose a week after completing PMAT-301, someone edits the YAML to add a fourth `falsification_tests[]` entry (`rope_orthogonality_test`) without re-binding any ticket. Run `pmat comply check` again:

```
CB-1601: Binding SHA Drift: Fail:
  SHA drift in 1/1 binding(s)
  PMAT-301 [rope-kernel-v1/rope] recorded 7f3a9b2e… current 9e8d7c6b…

CB-1627: Post-Bind YAML Drift: Fail:
  PMAT-301: new YAML test `rope_orthogonality_test` not in roster
```

Two gates flag the drift. CB-1601 sees the YAML bytes changed; CB-1627 sees the YAML has new test IDs that the ticket's roster doesn't cover. The fix is to re-bind:

```bash
pmat work rebind PMAT-301 --implements rope-kernel-v1/rope
```

Re-bind re-computes the SHA, re-seeds the `ProvableContract{}` entries for all tests (including `rope_orthogonality_test`), and writes a fresh `kani-harness-shas.json`. The next compliance run is green again — assuming the new test passes.

## CB-1620 Cutoff Story: Why a Dated Promotion?

CB-1620 is the only CB-16xx check with a hard calendar cutoff (2026-05-17). Every other gate promotes Skip → Pass/Fail when evidence lands. Why does CB-1620 need a date?

The answer is in `check_falsification_unification_roster.rs`:

```rust
fn cb1620_fail_mode_cutoff() -> NaiveDate {
    NaiveDate::from_ymd_opt(2026, 5, 17).expect("valid date")
}
```

CB-1620 enforces that every binding has matching `ProvableContract{}` entries per YAML `falsification_tests[]` id. This is not a "writer is pending" situation — the evidence (roster entries) is always present on every bound ticket. The question is whether it has the right shape.

Before v3.14.0, the bind step did not seed `ProvableContract{}` entries automatically. Every ticket bound between, say, v3.10.0 and v3.14.0 has an empty roster — it was bound cleanly under the old behavior, but the new CB-1620 check reads a spec that didn't exist at bind time.

If CB-1620 had shipped as Fail-on-day-one, every legacy ticket in every repo in the fleet would have failed compliance on the v3.14.0 release day. That would have been unmissable — and also unfair, because the author did nothing wrong.

The migration-window compromise:

- **2026-04-17 to 2026-05-16 (30 days)**: CB-1620 returns **Warn**. Message reads:
  ```
  3 inherited test(s) missing from roster. Run `pmat work migrate --seed-inherited-falsification`.
  Migration window closes 2026-05-17; this is a warning until then.
  ```
- **2026-05-17 onward**: CB-1620 returns **Fail**. Message reads:
  ```
  3 inherited test(s) missing from roster. Run `pmat work migrate --seed-inherited-falsification`.
  Migration window closed on 2026-05-17.
  ```

The migration tool `pmat work migrate --seed-inherited-falsification` walks every active ticket, reads each binding's YAML, and backfills the `ProvableContract{}` entries to match. It's idempotent — running it twice leaves the roster in the same shape.

The rationale for dating rather than flagging: **teams prefer deadlines to opt-in flags**. A flag says "you should do this eventually." A dated cutoff says "you have until May 17." The second is more actionable, and the Warn→Fail transition is automatic — no one has to remember to flip it.

## Golden Trace Replay (CB-1644 + Renacer)

The agent workflow above has one more layer: the entire interaction can be *replayed deterministically* via golden tracing.

Every time the agent runs a command that produces evidence, Component 10 writes `.pmat-work/<ID>/agent-runs/<run_id>.json`:

```json
{
  "run_id": "01HG9K3N7M2P8Q5R6S7T8V9W0X",
  "prompt_sha": "d4e5f67890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
  "commit_sha": "abc1234",
  "tool_calls": [
    { "tool": "pmat_work_bind", "args": { "id": "PMAT-301", "implements": "rope-kernel-v1/rope" } },
    { "tool": "pmat_work_falsify", "args": { "id": "PMAT-301" } },
    { "tool": "pmat_work_kani", "args": { "id": "PMAT-301" } }
  ],
  "recorded_at": "2026-04-17T14:35:00Z"
}
```

CB-1644 enforces that every agent run file has `prompt_sha`, `tool_calls: [...]` (must be an array), and `commit_sha`:

```rust
const REQUIRED_FIELDS: &[&str] = &["prompt_sha", "tool_calls", "commit_sha"];
// tool_calls must specifically be an array, not any non-null shape
let tool_calls_ok = map.get("tool_calls").map(|v| v.is_array()).unwrap_or(false);
```

The `prompt_sha` anchors the run to the exact prompt the agent received. The `commit_sha` anchors the run to the exact repo state. The `tool_calls` array captures the ordered sequence of actions the agent took.

`renacer capture` records this run as a golden trace. `renacer validate --all` replays the trace and asserts the same tool sequence produces the same evidence files. If the implementation ever drifts such that `pmat work falsify` no longer writes the expected log lines, the replay fails and Renacer surfaces the exact divergence.

This closes the loop: CB-1644 ensures the evidence is *recorded*; Renacer ensures the evidence is *reproducible*. Together they make the agent's contribution to the ticket fully auditable — any future maintainer can replay the exact run that produced the L4 claim and verify the claim still holds.

## The Full Gate Timeline for a Well-Behaved Ticket

| Step | Gate transitions |
|------|------------------|
| 1. `pmat work start` | CB-1610 Pass (parseable level), others remain Skip |
| 2. `pmat work start --implements` | CB-1601, CB-1603, CB-1607, CB-1609, CB-1611, CB-1620, CB-1621, CB-1623, CB-1626 → Pass |
| 3. `pmat work verify` (planned) | CB-1612, CB-1619 → Pass (at current achieved level) |
| 4. `pmat work codegen` (planned) | CB-1630, CB-1631, CB-1632, CB-1633, CB-1634, CB-1636, CB-1638 → Pass |
| 5. `pmat work falsify` | CB-1613, CB-1622, CB-1625, CB-1628 → Pass |
| 6. `pmat work kani` | CB-1605, CB-1614, CB-1615, CB-1629 → Pass |
| 7. `pmat work complete` | CB-1619 re-checked with `achieved == target` |
| 8. (Ongoing) | CB-1601, CB-1627 re-watch for YAML drift |

Eight steps, 29 gate transitions, zero configuration changes. Every Skip converts to Pass because the evidence it reads shows up — no flags, no disables, no migration scripts except the one-off CB-1620 backfill.

## Summary

The agent workflow is a linear pipeline of commands that each produce specific evidence files. CB-16xx gates read those files. Skip semantics let the gates ship before every writer lands. The one dated exception — CB-1620 on 2026-05-17 — is a deliberate backfill deadline, not a writer-ship deadline.

Running `pmat comply check` after every step is the concrete feedback loop: you watch Skip counts drop as the ticket progresses through bind → verify → codegen → falsify → kani → complete. When you run `pmat work complete` and every CB-16xx applicable to your target level is Pass, the ticket has discharged its claim.

Renacer golden traces close the audit loop — every agent action is recorded in `.pmat-work/<ID>/agent-runs/` and replayable. CB-1644 enforces that the replay schema is present; Renacer enforces that replaying reproduces the same evidence.

---

*Cross-references*:
- Chapter 56 main: `src/ch56-00-comply.md`
- Section 1: `src/ch56-01-verification-ladder.md` (the L0..L5 ordinal driving this workflow)
- Section 2: `src/ch56-02-tiered-skip-semantics.md` (why skips are the default)
- Chapter 62: `src/ch62-00-provable-contracts.md` (provable-contracts ecosystem and the YAML format)
- Binding resolver: `src/cli/handlers/work_contract_binding.rs` in the pmat repo
- Falsification method: `src/cli/handlers/work_contract_falsification.rs` in the pmat repo
