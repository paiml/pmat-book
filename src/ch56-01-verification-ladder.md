# The L0..L5 Verification Ladder

*Deep dive: Chapter 56, Section 1*

The CB-16xx gates are all anchored to a single ordinal: the **verification level** that a work ticket claims. Level is the one piece of vocabulary every check eventually consults — it decides which evidence files must exist, which gates apply, and whether a report that was green yesterday is allowed to stay green today.

This sub-chapter gives each level a precise definition backed by the evidence PMAT reads, a decision tree for choosing a target level, the JSON schemas that writers populate, and a walkthrough of how monotonicity (CB-1618) and downgrade audit (CB-1617) keep the ladder honest.

## Why an Ordinal?

Most quality systems pile up Boolean flags: "tests pass? yes/no", "property tests pass? yes/no", "coverage high? yes/no". The result is a bag of signals nobody can order. PMAT takes the opposite approach — it collapses the entire "how strongly is this claim discharged" question onto one ordered variable named `VerificationLevel`.

The type is defined in `src/cli/handlers/work_verification_level.rs`:

```rust
/// Ordered verification ladder. `Ord` matters: `L5 > L4 > … > L0` so the
/// completion gate can compare achieved vs. target and reject regressions.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
pub enum VerificationLevel {
    /// Documentation/review only — no executable check.
    L0,
    /// `debug_assert!` contract macros compile and run during `cargo test`.
    L1,
    /// `#[contract]` attribute bound; trait-based equations instantiated.
    L2,
    /// Bound equation's `falsification_tests[]` execute and pass.
    L3,
    /// Bound equation's `kani_harnesses[]` verified (zero counterexamples).
    L4,
    /// Bound equation's `lean_theorem.status == "proved"`, zero `sorry`.
    L5,
}
```

`PartialOrd` + `Ord` are derived — the compiler literally encodes `L5 > L4 > L3 > L2 > L1 > L0`. Every CB-16xx gate exploits that ordering. CB-1619's "achieved level == target level" check is a three-line comparison once levels are typed:

```rust
if achieved < target {
    return fail_closed_below_target();
}
```

That single `Ord` bound removes an entire class of "it passed but kinda downgraded quietly" escape hatches.

## The Six Levels, in Prose

### L0 — Documentation-only

No executable evidence. The ticket recorded a plan, a design note, or a spec reference. `pmat work verify` runs nothing but presence checks. L0 is the honest floor — it exists so you can file work that is review-only without lying about having run tests.

Evidence required: none beyond `.pmat-work/<ID>/contract.json` existing.

When to target L0: changelogs, design documents, research tickets that cite a paper but don't touch code, spike exploration.

### L1 — Runtime assertions green

`cargo test --lib` passed under the current baseline. Contract clauses that the codegen wraps as `debug_assert!` macros fire at call sites. Unit tests exercise them.

Evidence consumed by CB-16xx:
- `.pmat-work/<ID>/verification-report.json` — must carry an `l1_test_evidence` field.
- Any of these shapes pass CB-1612:

```json
{ "l1_test_evidence": true }
```

```json
{ "l1_test_evidence": { "success": true } }
```

```json
{ "l1_test_evidence": { "exit_code": 0 } }
```

```json
{ "l1_test_evidence": { "status": "pass" } }
```

Case-insensitive `"passed"`, `"ok"`, `"success"` are accepted on the `status` shape. Anything else fails the gate.

When to target L1: any production code change. This is the practical baseline for anything that compiles.

### L2 — Contract attribute wrapping

The function under test is wearing `#[pmat_work_contract(id = "<TICKET>", require = "R1", ensure = "E1")]`. The attribute macro invocation compiles and runs the generated `contracts/work/<ID>.rs` module. Preconditions and postconditions are actively evaluated at every call site.

Evidence consumed:
- Source tree must contain the attribute (CB-1631 checks every ticket has a matching `contracts/work/<ID>.rs`).
- `contracts/work/<ID>.manifest.json` — SHA-256 of each generated file, so CB-1633 can detect post-generation tampering.
- `codegen/last-run.json` — `pmat work codegen`'s receipt:

```json
{
  "status": "pass",
  "exit_code": 0,
  "generated": ["contracts/work/PMAT-033.rs"],
  "at": "2026-04-17T10:15:00Z"
}
```

When to target L2: any ticket whose contract has `require:` / `ensure:` clauses that are executable Rust expressions. The attribute adds no provable strength over L1 alone, but it documents the binding and creates an anchor for L3+.

### L3 — Falsification suite clean

The bound equation's `falsification_tests[]` have all been executed and every line in `.pmat-work/<ID>/falsification.log` reads `status: "pass"`. This is the level where "tested" becomes "falsified" in the Popperian sense — you actively tried to break it and every attempt failed.

The canonical log line format (CB-1628 enforces it):

```json
{"yaml":"contracts/rope-kernel-v1.yaml","equation":"rope","test_id":"rope_periodicity_test","status":"pass","duration_ms":18}
```

CB-1613 fails the gate on any line whose `status != "pass"`. CB-1625 extends that to *any inherited line anywhere* regardless of level — an inherited failure is fatal whether the ticket claims L3 or L5.

When to target L3: the default for production kernel work. If the YAML has a `falsification_tests:` section and a runner to execute it, you should be at L3.

### L4 — Kani bounded model checking discharges

`cargo kani` verified every `kani_harnesses[]` declared in the bound YAML. The result is recorded in `.pmat-work/<ID>/kani-report.json` with `success: true`:

```json
{
  "success": true,
  "harnesses": ["verify_rope_periodicity", "verify_rope_linearity"],
  "counterexamples": []
}
```

CB-1614 fails if the report is missing or reports `success: false`. CB-1615 adds a sharper teeth: the harness body hash recorded at bind time in `.pmat-work/<ID>/kani-harness-shas.json`:

```json
{
  "harnesses": [
    { "name": "verify_rope_periodicity", "sha": "a1b2c3d4e5f6…" },
    { "name": "verify_rope_linearity",   "sha": "f6e5d4c3b2a1…" }
  ]
}
```

must still match the YAML's current `kani_harnesses:` entries. If a harness body was edited post-bind, the SHAs diverge and CB-1615 fails even though CB-1614 sees a green report — because the report is for the *old* harness, not the one in the current YAML.

Finally, CB-1629 forbids any `status: "timeout"` line in the falsification log for an L4+ ticket. A Kani-adjacent property test that timed out defeats the L4 claim; there is no middle ground.

When to target L4: numerically-sensitive kernels (SIMD, fixed-point arithmetic, pointer arithmetic), concurrency primitives, parsers with unbounded input.

### L5 — Lean 4 theorem proved, zero sorry

`lake build` succeeded on a Lean 4 proof for the bound equation. The evidence lives in `.pmat-work/<ID>/lean-proof.json`:

```json
{
  "sorry_count": 0,
  "theorem": "rope_periodicity_thm",
  "verified_at": "2026-04-17T14:22:19Z"
}
```

CB-1616 fails on any non-zero `sorry_count` — a proof with `sorry` is a placeholder, not a proof. The YAML must declare a `lean_theorem:` block with `status: "proved"` for the max-attainable level to climb to L5 in the first place (that's how `VerificationLevel::max_attainable_from_yaml` decides).

CB-1649 layers on: every structured chain-of-thought step in an L5 ticket must map to a Lean theorem or lemma via `lean_theorem`, `lean_lemma`, `evidence_method.LeanTheorem`, `evidence_method.LeanLemma`, or `discharged_by.Lean`.

When to target L5: cryptographic primitives, consensus protocols, anything where a counter-example would be catastrophic and Kani's bounded horizon isn't convincing.

## Max-Attainable Level: Weakest-Binding-Dominates

The ladder is claim-driven, but the YAML decides the ceiling. `VerificationLevel::max_attainable_from_yaml` scans a contract YAML and returns the strongest level its evidence sections support:

```rust
pub fn max_attainable_from_yaml(yaml: &str) -> Self {
    let has_lean_proved = yaml_lean_theorem_proved(yaml);
    let has_kani = yaml_section_non_empty(yaml, "kani_harnesses");
    let has_fals = yaml_section_non_empty(yaml, "falsification_tests");
    let has_eqs = yaml_section_non_empty(yaml, "equations");

    if has_lean_proved {
        Self::L5
    } else if has_kani {
        Self::L4
    } else if has_fals {
        Self::L3
    } else if has_eqs {
        Self::L2
    } else {
        Self::L1
    }
}
```

Notice the cascade: to reach L4 you need a `kani_harnesses:` block; to reach L3 you need `falsification_tests:`; to reach L2 you need `equations:`. Absence of any of those drops the ceiling.

For a multi-bind ticket, CB-1611 applies **Liskov-Wing weakest-binding-dominates**:

```rust
let mut weakest = VerificationLevel::L5;
for binding in &c.implements {
    let level = VerificationLevel::max_attainable_from_yaml(&yaml);
    if level < weakest {
        weakest = level;
    }
}
```

A ticket bound to two YAMLs where one supports L4 and the other supports L2 is capped at **L2**. The reasoning: the ticket claims one atomic verification level, so the strongest defensible claim is whatever its weakest binding supports.

This is where CB-1611 bites: if `verification_level: "L4"` but one bound YAML has no `kani_harnesses:`, the gate fails with:

```
CB-1611: Target ≤ Max Attainable:
  PMAT-033 claims L4 but bindings cap at L2
```

## Decision Tree: Which Level Do I Target?

```
Is this a design/review/spec ticket?
├── Yes → L0 (no evidence expected)
└── No  → Continue

Does the code compile and does `cargo test --lib` pass?
├── No  → Blocked; nothing above L1 is reachable
└── Yes → L1 is your floor

Does the contract YAML have `equations:` with require/ensure clauses
that are expressible as Rust expressions (`expr:` field)?
├── No  → Stop at L1; you can't meaningfully go higher without a contract
└── Yes → Continue; L2 is reachable

Does the YAML have `falsification_tests:` that execute today
(i.e. a runner emits `.pmat-work/<ID>/falsification.log`)?
├── No  → Target L2
└── Yes → Continue; L3 is reachable

Does the YAML have `kani_harnesses:` and `cargo kani` succeed
against the current harness bodies?
├── No  → Target L3
└── Yes → Continue; L4 is reachable

Does the YAML have `lean_theorem: status: "proved"` and does
`lake build` produce a zero-sorry proof?
├── No  → Target L4
└── Yes → Target L5
```

In practice: **L3 is the default for kernel work**; **L4 for anything numerically sensitive or concurrency-adjacent**; **L5 is reserved for primitives whose counter-examples would be catastrophic**. L0/L1/L2 are what you fall back to when the evidence chain breaks — not what you should be planning for.

## Evidence File Catalogue

This is the authoritative list of files PMAT reads when scoring the ladder. Each file has a single producer (writer) and one or more consumers (checks).

| Path | Shape | Writer | CB checks that read it |
|------|-------|--------|-------|
| `.pmat-work/<ID>/contract.json` | Full `WorkContract` struct (see `work_contract_core.rs`) | `pmat work start`, `pmat work bind` | Every CB-16xx; ladder root |
| `.pmat-work/<ID>/verification-report.json` | `{ target_level, achieved_level, l1_test_evidence }` | `pmat work verify` | CB-1612 (L1 test), CB-1619 (target==achieved) |
| `.pmat-work/<ID>/falsification.log` | JSONL, 4-field shape | Component 29 unified falsification runner | CB-1613 L3, CB-1622 coverage, CB-1625 inherited-fatal, CB-1628 shape, CB-1629 L4 timeout, CB-1608 cross-binding |
| `.pmat-work/<ID>/kani-report.json` | `{ success: bool, harnesses, counterexamples }` | Component 24 Kani runner | CB-1605 binding, CB-1614 L4 |
| `.pmat-work/<ID>/kani-harness-shas.json` | `{ harnesses: [{name, sha}] }` or `{ harnesses: {name: sha} }` | `pmat work bind` at bind time | CB-1615 drift |
| `.pmat-work/<ID>/lean-proof.json` | `{ sorry_count: int, theorem, verified_at }` | Component 24 Lean runner | CB-1606, CB-1616, CB-1648, CB-1649 |
| `.pmat-work/<ID>/checkpoints/*.json` | `{ timestamp, verification_level, … }` | Checkpoint writer (Component 28) | CB-1618 monotonicity |
| `.pmat-work/<ID>/agent-runs/<run_id>.json` | `{ prompt_sha, tool_calls: [], commit_sha }` | Component 10 agent writer | CB-1644 replayability |
| `.pmat-work/<ID>/cot-digest.json` | Canonical SHA of the `chain_of_thought` array | `pmat work cot derive` | CB-1646 anti-tamper |
| `.pmat-work/ledger/downgrades.json` | Array of `{ ticket, reason, from, to, at }` | `pmat work downgrade --reason …` | CB-1617 reason audit, CB-1618 monotonicity excuse |
| `.pmat-work/ledger/unbinds.json` | Array of `{ ticket, debt_ticket, at }` | `pmat work unbind --debt DEBT-…` | CB-1602 debt citation |
| `.pmat-work/ledger/roster-mutations.json` | Array of `{ action, ticket, via_unbind, at }` | Roster mutation hooks | CB-1624 deletion audit |
| `contracts/work/<ID>.rs` | Generated `debug_assert!` module | `pmat work codegen` | CB-1631 existence, CB-1638 tracked-in-git |
| `contracts/work/<ID>.manifest.json` | `{ files: [{path, sha256}] }` | `pmat work codegen` | CB-1633 manifest SHA |
| `codegen/last-run.json` | `{ status, exit_code, generated, at }` | `pmat work codegen` | CB-1630 last run green |
| `codegen/compile-status.json` | `{ debug: bool, release: bool }` | `pmat work codegen --check` | CB-1636 both profiles compile |

A ticket aiming at L5 will produce **all 16** of these files. A pure-L1 ticket produces only `contract.json` + `verification-report.json`. The ladder itself is what tells you which files you need.

## Monotonicity and Downgrade Audit

The ladder is only useful if you cannot silently downgrade it. Two gates enforce that:

### CB-1618: Level Monotonicity Across Checkpoints

Every long-running ticket writes checkpoint files under `.pmat-work/<ID>/checkpoints/`:

```json
{
  "timestamp": "2026-04-17T09:00:00Z",
  "verification_level": "L3",
  "note": "baseline after initial implementation"
}
```

```json
{
  "timestamp": "2026-04-17T14:00:00Z",
  "verification_level": "L4",
  "note": "Kani harnesses landed"
}
```

CB-1618 reads every checkpoint, sorts by `timestamp`, and scans for *regressions* — any pair where `cp[i+1].verification_level < cp[i].verification_level`. A regression is allowed **only if** the ticket also appears in `.pmat-work/ledger/downgrades.json`:

```json
[
  {
    "ticket": "PMAT-033",
    "from": "L4",
    "to": "L3",
    "reason": "Kani runner OOM'd on macOS CI; splitting harness is out of scope",
    "at": "2026-04-17T15:00:00Z"
  }
]
```

Absent that ledger entry, the regression fails the gate with:

```
CB-1618: Level Monotonicity:
  PMAT-033: checkpoint level regresses without a downgrade ledger entry (L3 → L4 → L3)
```

Summary line format is deterministic — `summarize_timeline()` joins level strings with `→`.

### CB-1617: Downgrade Reason Audit

Every entry in `.pmat-work/ledger/downgrades.json` must carry a non-empty `reason`. A downgrade with `reason: ""` or missing `reason` is "silent scope reduction" — the team reduced the claim without justifying why:

```
CB-1617: Downgrade Reason Audit:
  entry[0] ticket=PMAT-033 reason=empty
```

This is a hard fail. CB-1617 and CB-1618 are deliberately layered — CB-1617 audits the ledger content, CB-1618 audits that the ledger *exists* for any checkpoint regression. You can't satisfy CB-1618 by writing an empty-reason entry because CB-1617 will fail instead.

## The `WorkContract::verification_level` Field

Today the field is still a `String` on `WorkContract` (see `work_contract_core.rs`):

```rust
/// Verification level target: L0 (review) through L5 (Lean proof)
#[serde(default = "default_verification_level")]
pub verification_level: String,
```

The default is `"L3"` — picking up the practical baseline. The string is parsed per check via `VerificationLevel::parse_strict` (which rejects `"L3 "`, `"l4"`, `"strong"`) or `parse_lenient` (which trims and upper-cases for migration-era tolerance).

CB-1610 fails on any ticket whose string doesn't strict-parse to a known variant. Typos like `verification_level: "strong"` stop at the gate rather than silently skipping every downstream evidence check.

A future migration (documented inline in `work_verification_level.rs`) will swap the string for the typed `VerificationLevel` enum once all writers are audited. Until then, the spec and the checks agree on the same six-variant vocabulary.

## Lenient vs Strict Parsing

`VerificationLevel` exposes two parsers; use cases differ:

```rust
/// Parse a level string strictly. Rejects whitespace, case variants,
/// and anything outside `L0..=L5`. Used by CB-1610 to flag typos like
/// `"L3 "`, `"l4"`, or `"strong"`.
pub fn parse_strict(s: &str) -> Option<Self> { /* exact match only */ }

/// Migration-friendly parse: trims, uppercases, accepts `l3`, `L3 `.
/// Returns `None` for values outside the ladder so downstream code can
/// record `MIGRATION-LEVEL-UNKNOWN`.
pub fn parse_lenient(s: &str) -> Option<Self> {
    let canonical = s.trim().to_ascii_uppercase();
    Self::parse_strict(&canonical)
}
```

CB-1610 uses `parse_strict` — any deviation from the canonical `L0..L5` tokens is a hard fail. Typos are a quality signal and the team should see them.

Downstream checks that read the level after CB-1610 has already validated it use `parse_lenient` for tolerance — if a level string has slipped past CB-1610 for any reason (e.g. the writer lagged behind CB-1610's strictness), lenient parsing lets us still compare ordinals. The combination: **strict at the gate, lenient at the consumers**.

The `is_l3_or_higher` helper in `check_work_ladder_l3_falsification.rs` shows the downstream pattern:

```rust
fn is_l3_or_higher(contract: &WorkContract) -> bool {
    let token = contract
        .verification_level
        .split_whitespace()
        .next()
        .unwrap_or("");
    VerificationLevel::parse_lenient(token)
        .map(|lvl| lvl >= VerificationLevel::L3)
        .unwrap_or(false)
}
```

`split_whitespace().next()` handles annotated level strings like `"L4 (kani_proof)"` — the consumer grabs `"L4"` and ignores the annotation. This is deliberately forgiving at the consumer side so the spec can evolve the annotation format without cascading check failures.

## Staying Below Target Is Fine; Going Below Target at Completion Is Not

A ticket mid-work with `target_level: "L4"` and `achieved_level: "L1"` is **not** failing CB-1619. The gate only fires on *completed* tickets. Read the check:

```rust
// CB-1619: on completion, achieved level == target level
for c in &contracts {
    let report = project_path.join(".pmat-work").join(&c.work_item_id)
        .join("verification-report.json");
    if !report.exists() {
        continue;
    }
    // … read target and achieved from the report …
    if achieved < target {
        mismatches.push(format!("  {} target={} achieved={}", c.work_item_id, target, achieved));
    }
}
```

A ticket that has never been through `pmat work complete` doesn't have a verification report at completion state. CB-1619 silently skips such tickets. The gate only fails when the author explicitly marks a ticket complete with an achieved level below target — that's the "closing below your claim" case.

This matters for CI integration. A long-running ticket in flight is not a compliance failure. Only a closed ticket that under-delivered is.

## The Single Ordinal Idea

The key design move is that **the ladder collapses many dimensions onto one number**. Consider an alternative design where a ticket has independent booleans:

```yaml
tests_pass: true
contracts_wrapped: true
falsification_clean: true
kani_discharged: false
lean_proved: false
```

This gives you five signals, but it doesn't answer the question "how strong is this claim?" Someone could set `kani_discharged: false` for L4 work and argue the other four greens mean the work is "mostly done." There's no ordering.

The PMAT design collapses those five booleans onto the ordinal `L0..L5` with a fixed climb order: you must have L1 before L2, L2 before L3, and so on. The single number is the strongest level for which *all lower levels are also satisfied*. If `kani_discharged` is false, you are at most L3, regardless of the other booleans.

This is analogous to how tolerance levels work in manufacturing: tolerance level 5 requires meeting levels 1-4 plus the additional level 5 criteria. You can't skip a level and claim the higher one.

CB-1611 enforces this at bind time: you can't claim L4 if your YAML lacks `kani_harnesses:`. CB-1619 enforces it at completion: you can't close below your stated target. CB-1618 enforces it across the ticket's timeline: you can't silently retreat. Together the three gates make the single ordinal meaningful.

## Why This Shape?

The design goal was one ordered variable per ticket plus a hard anchor to YAML evidence. Every alternative we considered either hid silent downgrades or let authors cherry-pick which dimensions to report. An ordinal with `Ord` derived gives you the completion gate, the monotonicity check, and the "achieved >= target" check for free. The max-attainable-from-YAML scanner gives you a hard ceiling that the team can't lie about without also editing the YAML (and that edit trips CB-1601 SHA drift).

The result is a single number you can look at on any ticket and say "this is how strongly the claim is discharged, and PMAT will notice if it ever slips."

---

*Cross-references*:
- Chapter 56 main: `src/ch56-00-comply.md` (CB-16xx overview table)
- Section 2: `src/ch56-02-tiered-skip-semantics.md` (why every check starts Skip)
- Section 3: `src/ch56-03-agent-workflow.md` (worked example from `work bind` to cutoff)
- Component 28 spec: `docs/specifications/components/pmat-work-verification-ladder.md` in the pmat repo
