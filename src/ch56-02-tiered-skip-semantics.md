# Tiered Skip Semantics

*Deep dive: Chapter 56, Section 2*

Every CB-16xx check follows the same decision pattern: **Skip first, Fail only on evidence of drift**. This sub-chapter explains why. If you have ever looked at `pmat comply check` on a fresh project and seen a long run of `Skip` entries and wondered whether something was broken — this is the chapter that tells you the skips are the feature, not a bug.

## The Problem: Enforcement Gates Shipped Before Writers

PMAT v3.14.0 landed 50 CB-16xx gates at once. Most of them read evidence files that are produced by components that were still being built:

- Component 24 (Kani and Lean runners) — `.pmat-work/<ID>/kani-report.json`, `.pmat-work/<ID>/lean-proof.json`
- Component 29 (unified falsification runner) — `.pmat-work/<ID>/falsification.log`
- Component 10 (agent run writer) — `.pmat-work/<ID>/agent-runs/<run_id>.json`
- Component 27 bind step — `.pmat-work/<ID>/kani-harness-shas.json`
- `pmat work codegen` — `contracts/work/<ID>.rs`, `contracts/work/<ID>.manifest.json`
- `pmat work cot derive` — `.pmat-work/<ID>/cot-digest.json`

A naive design would have gated those checks behind feature flags or a version number: "turn on CB-1614 once the Kani runner lands." That approach has a failure mode. The runner lands, someone forgets to flip the flag, and CB-1614 never actually enforces anything in production.

The tiered-skip design avoids that trap. The gate is *always on*. It knows the full set of upstream pre-conditions that would make its evidence available. If any pre-condition is missing it returns **Skip with a tiered informational message**. The moment the writer starts producing output, the gate *automatically* transitions to Pass / Warn / Fail without any configuration change on the consumer side.

## The Skip Ladder Pattern

Read `check_ladder_l1_test_evidence` — the structure is repeated across all 50 gates:

```rust
let contracts = load_active_contracts(project_path);
if contracts.is_empty() {
    return skip_no_contracts(name);
}

let mut any_report = false;
let mut any_evidence = false;
let mut failing = Vec::new();

for c in &contracts {
    let report = project_path.join(".pmat-work").join(&c.work_item_id)
        .join("verification-report.json");
    if !report.exists() {
        continue;
    }
    any_report = true;
    // …parse JSON, inspect `l1_test_evidence`…
    any_evidence = true;
    match evaluate_l1_evidence(evidence) {
        L1Outcome::Pass => {}
        L1Outcome::Fail(reason) => failing.push(format!("{} → {}", c.work_item_id, reason)),
    }
}

if !failing.is_empty() {
    return fail(failing);
}
if !any_report {
    return skip("No ticket has `verification-report.json` yet");
}
if !any_evidence {
    return skip("No verification-report.json carries `l1_test_evidence` yet");
}

pass(checked)
```

Notice the ordering of the terminal arms — **failures win first**, then the skip ladder decides which informational message to return. Each level of the ladder is progressively more specific:

1. **Tier 0: "no tickets at all"** — the `.pmat-work/` directory is empty. The check has nothing to look at.
2. **Tier 1: "no ticket has *file-name.json*"** — tickets exist but none carry the specific evidence file. The writer hasn't started for any of them.
3. **Tier 2: "files exist but don't carry *field-name*"** — the writer has started but the schema has not extended to the field this check needs.
4. **Tier 3: "field exists but is empty / not-applicable"** — the schema is there but the payload is empty for this specific ticket.
5. **Fail**: at least one piece of evidence indicates the claim is falsified.

Each transition from one tier to the next is a genuine signal: "the writer is closer to landing now." You can grep the comply output for skip messages and watch them disappear as upstream components ship.

## Per-Check Skip→Pass Transitions

| Check | Skip (pre-writer) | Skip (partial evidence) | Pass | Fail |
|-------|-------------------|------------------------|------|------|
| CB-1600 Orphan | No `.pmat/binding-index.json` or no staged files | No staged bound files | Staged bound files declared in `implements:` | Staged bound file missing from every active ticket |
| CB-1601 SHA Drift | No ticket has `implements:` bindings | — | Every binding SHA matches current YAML bytes | Any binding's recorded SHA differs from current YAML SHA |
| CB-1602 Unbind Audit | `.pmat-work/ledger/unbinds.json` absent | — | Every unbind entry cites a DEBT ticket | Any entry missing `debt_ticket` |
| CB-1605 Kani Binding | No `kani_harnesses:` in YAML / no `kani-report.json` | Report exists but ticket has no `kani_harnesses` citation | Declared harnesses are all `success: true` in the report | Declared harness missing or failing |
| CB-1606 Lean Theorem | No YAML has `lean_theorem:` blocks | — | Every unproved theorem has a BLOCK-ON-PROOF follow-up | Unproved theorem without block-on-proof |
| CB-1608 Cross-Binding | No multi-bind ticket has falsification.log | — | Every multi-bind ticket's bindings are uniformly green | Any multi-bind ticket mixes passing and failing per-binding entries |
| CB-1612 L1 Evidence | No `verification-report.json` anywhere | Reports exist, no `l1_test_evidence` field yet | At least one report carries passing L1 evidence | Any report's evidence indicates failure |
| CB-1613 L3 Falsification | No L3+ ticket / no `falsification.log` for any L3+ ticket | — | Every log entry of every L3+ ticket is `status: "pass"` | Any non-pass entry |
| CB-1614 L4 Kani | No L4+ ticket / no `kani-report.json` for any L4+ ticket | — | Every L4+ report is `success: true` | Missing `success` field, or `success: false` |
| CB-1615 Harness SHA | No L4+ bound ticket / no `kani-harness-shas.json` | Snapshot present but empty | Every snapshot harness still matches current YAML `sha:` | Harness removed or sha drifted |
| CB-1616 L5 Lean | No L5 ticket / no `lean-proof.json` | — | Every L5 report is `sorry_count: 0` | Any non-zero or missing `sorry_count` |
| CB-1617 Downgrade Reason | `.pmat-work/ledger/downgrades.json` absent | — | Every entry carries a non-empty `reason` | Any entry with empty/missing `reason` |
| CB-1618 Monotonicity | No `.pmat-work/` dir / no ticket has `checkpoints/` | Checkpoints exist, none carry `verification_level` | Per-ticket level is non-decreasing or has a matching ledger entry | Regression without ledger entry |
| CB-1619 Completion == Target | No tickets / no ticket has `verification-report.json` | — | Every completed ticket has `achieved_level >= target_level` | Any completion below target |
| CB-1620 Roster Coverage | No bindings | — | Every binding has matching `ProvableContract{}` entries | **Warn** until 2026-05-17, then **Fail** |
| CB-1621 Expected Snapshot | No `ProvableContract{expected}` non-empty snapshot | No YAML declares scalar `expected:` for any seeded test_id | Every seeded snapshot matches the current YAML | Silent drift since bind |
| CB-1622 Roster Execution | No ticket has `falsification.log` | — | Every roster entry has at least one log line | Any roster entry never executed |
| CB-1623 No Duplicates | No `ProvableContract` entries anywhere | — | No ticket has duplicate `(yaml_path, test_id)` pairs | Duplicate roster entry |
| CB-1624 Deletion Audit | `.pmat-work/ledger/roster-mutations.json` absent | — | Every deletion entry carries `via_unbind: true` | Deletion without unbind flag |
| CB-1625 Inherited Fatal | No `falsification.log` | — | Every inherited line is `status: "pass"` | Any non-pass inherited line |
| CB-1626 Referenced test_id | No bindings | — | Every referenced `test_id` exists in current YAML | `test_id` removed from YAML post-bind |
| CB-1627 Post-Bind Drift | No bindings | — | Every current YAML `falsification_tests[]` id is in the roster | New YAML test not seeded into roster |
| CB-1628 Log Line Shape | No `falsification.log` files | — | Every inherited line has `{yaml, test_id, status, duration_ms}` | Any line missing a required field |
| CB-1629 L4 Timeout | No L4+ ticket / no log for any L4+ ticket | — | No L4+ log line is `status: "timeout"` | Any timeout in an L4+ log |
| CB-1630 Codegen Receipt | `codegen/last-run.json` absent | — | Most recent run reports `status: "pass"` + `exit_code: 0` | Non-zero exit or non-pass status |
| CB-1631 Module Existence | No `#[pmat_work_contract]` attribute usages in `src/` | — | Every attribute usage has matching `contracts/work/<TICKET>.rs` | Missing generated module |
| CB-1632 Clause Match | No attribute usages | — | Every `require=` / `ensure=` ID matches a clause in the ticket's contract | Clause id not found |
| CB-1633 Manifest SHA | No manifests emitted | — | Every manifest entry matches current file SHA | Manifest out of sync |
| CB-1634 expr/binds_to | No clause has `expr` yet | — | Every `expr` clause has `binds_to` AND attribute usage in `src/` | Orphan `expr` or missing attribute |
| CB-1635 binds_to / diff | No `modified-files.json` receipts | — | Every `binds_to` target is in the ticket's modified-files set | Target file not modified in the ticket |
| CB-1636 Compile Profiles | `codegen/compile-status.json` absent | — | Debug and release both compile | Either profile failed |
| CB-1637 pub fn Coverage | No L2+ ticket / no `modified-files.json` | — | Every modified `pub fn` has `#[pmat_work_contract]` | Public fn left unwrapped |
| CB-1638 Tracked in Git | No `contracts/work/*.rs` files | — | Every generated module is tracked in git | Ungenerated or untracked |
| CB-1639 Harness Refs | No L4+ ticket / no `kani_harnesses:` | — | Every harness name resolves to a harness body referencing `contracts::work::<ID>` or the attribute | Harness name doesn't resolve |
| CB-1640 CoT References | No structured CoT steps | — | Every `assumption.references` resolves | Dangling reference |
| CB-1641 CoT Evidence | No structured steps | — | Every structured step has `evidence_method` | Structured step without evidence |
| CB-1642 ExistingTest | No `ExistingTest` steps | — | Every `ExistingTest` path/name exists on disk | Test file or name not found |
| CB-1643 L3+ expr | No L3+ ticket / no structured steps | — | Every L3+ structured step has `assumption.expr` or `implication.expr` | Structured step missing codegen-ready expr |
| CB-1644 Replayable | No `agent-runs/` dir anywhere | No run files | Every run has `prompt_sha`, `tool_calls: []`, `commit_sha` | Replay field missing |
| CB-1645 Derived YAML | No `contracts/work/<ID>.yaml` derived | — | Derived YAML up-to-date with contract.json | Derived YAML stale |
| CB-1646 CoT Digest | No `cot-digest.json` | — | Digest matches canonical hash of `chain_of_thought` | Manual edit drift |
| CB-1647 CoT Orphans | No structured steps | — | Every step chains via `discharged_by` | Unchained step |
| CB-1648 Axiomatic | No L4+ axiomatic discharges | — | Every `Axiomatic` is a bound invariant or documented lemma | Undocumented axiomatic |
| CB-1649 L5 Lean Mapping | No L5 ticket | — | Every structured step carries a Lean theorem/lemma mapping | Step missing Lean mapping |

Reading across rows: the moment *any* upstream writer starts emitting evidence, the corresponding check's skip tier becomes more specific. The moment every writer has landed and every evidence file is present, the same check flips to Pass or Fail.

## Why Not Just Disable the Check?

Three failure modes the disable-by-flag approach doesn't handle:

1. **Forgotten re-enable.** Once a team disables a check for "writer not landed yet," the TODO to re-enable it lives in someone's head. Tiered skip removes the TODO — the check automatically lights up when the writer lands.
2. **Partial rollout.** In a monorepo, some tickets might have the new evidence and others don't. A binary enable flag can't handle that. Tiered skip handles it per-ticket: the gate skips the tickets lacking evidence and evaluates the ones that have it.
3. **Regression detection.** If a writer lands and then regresses (stops producing evidence for a class of tickets), tiered skip detects the regression. A disabled check doesn't.

## The Kaizen Argument

Kaizen is continuous small improvements. The tiered-skip model embraces that philosophy at the gate level:

- Ship the gate today with the skip ladder.
- Observe the skip messages in `pmat comply check` output. They enumerate what the writers have not yet produced.
- Prioritize the writers whose skips show up most.
- As each writer lands, its corresponding skip message disappears and the gate starts enforcing on that slice of evidence.

Every commit that lands a writer measurably tightens enforcement. There is never a point where "the gates are there but disabled" — they enforce whatever evidence exists, from the first day.

## CB-1620: The Only Gate With a Hard Cutoff

The exception that proves the rule: **CB-1620 carries a hard-coded cutoff date**.

```rust
/// End of the 30-day migration window defined by the spec
/// (§Migration: "CB-1620 enters warn mode for 30 days, then fail"). CB-1620
/// landed 2026-04-17, so the window closes 2026-05-17 — on or after that
/// date, missing inherited entries promote from Warn to Fail.
fn cb1620_fail_mode_cutoff() -> NaiveDate {
    NaiveDate::from_ymd_opt(2026, 5, 17).expect("valid date")
}

fn cb1620_gap_severity(today: NaiveDate) -> (CheckStatus, Severity) {
    if today >= cb1620_fail_mode_cutoff() {
        (CheckStatus::Fail, Severity::Error)
    } else {
        (CheckStatus::Warn, Severity::Warning)
    }
}
```

Unlike every other CB-16xx check that auto-promotes when evidence appears, CB-1620 auto-promotes when the calendar flips. The reasoning is specific to CB-1620:

- CB-1620 checks that every binding's YAML `falsification_tests[]` has been seeded into the ticket's `ProvableContract{}` roster at bind time.
- Every ticket that was bound *before* CB-1620 landed needs its roster backfilled via `pmat work migrate --seed-inherited-falsification`.
- If CB-1620 had shipped as Fail-on-day-one, every legacy ticket would have failed compliance the day v3.14.0 released.
- A skip ladder doesn't help here — the evidence ("roster entries") exists, it just doesn't have the right shape.

So CB-1620 picks the migration-window compromise: **Warn until 2026-05-17, Fail after**. The Warn message tells you the cutoff date:

```
CB-1620: Inherited Roster Coverage:
  3 inherited test(s) missing from roster (e.g. PMAT-033 → rope-kernel-v1/rope#rope_periodicity_test). 
  Run `pmat work migrate --seed-inherited-falsification`. 
  Migration window closes 2026-05-17; this is a warning until then.
```

After the cutoff the message becomes:

```
CB-1620: Inherited Roster Coverage:
  3 inherited test(s) missing from roster … 
  Migration window closed on 2026-05-17.
```

and the check returns `Fail`. The cutoff is hard-coded in `check_falsification_unification_roster.rs` precisely because this is not a writer-is-pending situation — it is a deliberate backfill deadline.

This is the only dated promotion in the entire CB-16xx family. Every other gate uses the tiered-skip pattern and promotes automatically on evidence, not calendar.

## Reading the Skip Messages

The skip messages are intentionally informational — they tell you which upstream producer is still outstanding. A few canonical examples from the production handlers:

```
CB-1612: L1 Test Evidence: No verification-report.json carries `l1_test_evidence` yet
```
→ `pmat work verify` is not yet recording the `l1_test_evidence` field.

```
CB-1614: L4 Kani Evidence: No L4+ ticket has a `kani-report.json` yet (2 eligible)
```
→ Component 24 Kani runner hasn't executed on the two L4+ tickets in the repo.

```
CB-1615: Kani Harness SHA: No L4+ ticket has `kani-harness-shas.json` yet (2 eligible)
```
→ The bind step (`pmat work start --implements`) isn't writing the bind-time snapshot file yet; the dedicated `pmat work bind` subcommand that will own this artifact is planned but not shipped.

```
CB-1618: Level Monotonicity: No checkpoint records the `verification_level` field yet
```
→ Checkpoints exist, but the writer hasn't been extended to include the level field.

```
CB-1644: Agent Run Replayable: No `.pmat-work/<ID>/agent-runs/*.json` files — Component 10 writer hasn't emitted runs yet
```
→ Component 10 agent run writer is still pending.

Each message names the specific file or field that is absent, plus (where relevant) the count of tickets that would be evaluated once the writer lands. Grepping the comply report for these messages gives you a crisp prioritization list for upstream work.

## Not a Silent Failure

One failure mode worth calling out: **`Skip` is not `Pass`**. A project can be entirely green on its CB-16xx checks today because every applicable check is skipping. That is genuinely green: it means the repo has no evidence of drift. But it is also a signal that the enforcement *potential* of those checks is not yet realized.

`pmat comply report` surfaces this via the check count breakdown:

```
Compliance Check Summary:
  Pass: 18
  Skip: 32   ← upstream evidence pending for these
  Warn: 1    ← CB-1620 migration window
  Fail: 0
```

A healthy repo in the CB-16xx transition period looks like the above: 18-30 passes, most of the rest skipping with informational messages, a single CB-1620 warning until 2026-05-17. Once the writers land, the Skips migrate to Passes. The Pass count climbing while Skip drops is the concrete signal that enforcement is tightening.

## Debugging a Specific Skip

When you want to understand why a specific check is skipping, the skip message is deliberately structured so it names one or more files. The debugging procedure is always the same:

1. Grep the check output for the check ID.
2. Read the skip message — it names the file or field the check expected.
3. Check whether that file is supposed to exist given your current pipeline state.
4. If yes, check who the writer is and whether it ran.
5. If no, the skip is genuine and self-documenting: "the writer has not landed yet."

Example debug session:

```
$ pmat comply check 2>&1 | grep 'CB-1622'
CB-1622: Roster Execution Coverage: Skip — No `.pmat-work/<ID>/falsification.log` files — unified runner hasn't executed rosters yet
```

The message says the unified runner hasn't executed. Check what `pmat-work` looks like:

```
$ ls .pmat-work/PMAT-301/
contract.json
verification-report.json
kani-report.json
```

No `falsification.log`. CB-1622 is genuinely skipping because `pmat work falsify` has not been run yet on this ticket. The fix is to run the falsification step, not to configure around the check.

### When Skip Indicates a Bug

Occasionally a Skip can indicate that *you* forgot to run something:

```
$ pmat comply check 2>&1 | grep 'CB-1612'
CB-1612: L1 Test Evidence: Skip — No verification-report.json carries `l1_test_evidence` yet
```

If you just ran `cargo test --lib` and every test passed, you might expect this check to be Pass. The skip message says otherwise: the *field* `l1_test_evidence` is missing from the `verification-report.json`. Two possibilities:

1. `pmat work verify` wasn't run — `cargo test --lib` alone does not write the verification report.
2. `pmat work verify` was run, but your pmat version is older than v3.14.0 and doesn't know to emit the `l1_test_evidence` field.

Run `pmat --version` and `pmat work verify PMAT-301` to diagnose. The Skip message is telling you *exactly* which field is missing — you can pipe the report through `jq`:

```
$ jq '.l1_test_evidence' .pmat-work/PMAT-301/verification-report.json
null
```

If you get `null`, the writer version is too old. If you get a JSON object with `success: true`, the check would have been Pass — something else is going on.

## CI Integration: Counting Skip vs Pass

In CI you want to track **Pass count trending up** and **Skip count trending down** over releases. Here's a pattern for extracting the counts:

```bash
# Run comply, capture JSON
pmat comply check --format json > compliance.json

# Count CB-16xx statuses
jq '[.checks[] | select(.name | startswith("CB-16"))] | group_by(.status) | map({status: .[0].status, count: length})' compliance.json
```

Typical output at the start of the v3.14.0 rollout:

```json
[
  {"status": "Pass", "count": 4},
  {"status": "Skip", "count": 46}
]
```

Four weeks later after Component 29 lands:

```json
[
  {"status": "Pass", "count": 18},
  {"status": "Skip", "count": 32}
]
```

Six weeks later after Component 24 lands:

```json
[
  {"status": "Pass", "count": 32},
  {"status": "Skip", "count": 18}
]
```

The Skip count dropping over time is the primary indicator of enforcement tightening. You can turn this into a dashboard metric without ever modifying `.pmat.yaml`.

### Threshold-Based Gating in CI

If you want CI to enforce "CB-16xx checks never regress from Pass to Skip", record the current Pass count as a baseline:

```bash
# Record baseline
pmat comply check --format json | \
  jq '[.checks[] | select(.name | startswith("CB-16") and .status == "Pass")] | length' > .pmat/cb16xx-baseline.txt
```

Then gate future runs against it:

```bash
current=$(pmat comply check --format json | \
  jq '[.checks[] | select(.name | startswith("CB-16") and .status == "Pass")] | length')
baseline=$(cat .pmat/cb16xx-baseline.txt)
if [ "$current" -lt "$baseline" ]; then
    echo "CB-16xx regression: $current passing (was $baseline)"
    exit 1
fi
```

This catches the case where a writer was uninstalled, a file was deleted, or a check genuinely regressed.

## Skip vs Disable: Two Different Mechanisms

There is a separate mechanism for disabling a check via `.pmat.yaml`:

```yaml
comply:
  checks:
    cb-1614: { enabled: false }
```

A disabled check returns `Skip` with a *different* message: `"Disabled in .pmat.yaml"`. This is intentional — disabling is a deliberate suppression with a reason, whereas tiered skip is an evidence-pending state. You can tell them apart by the message:

- Tiered skip: "No L4+ ticket has a `kani-report.json` yet"
- Explicit disable: "Disabled in .pmat.yaml"

A project that disables CB-1614 will see the same `Skip` status code, but the message will point to the `.pmat.yaml` opt-out. CI tooling that wants to enforce "no opt-outs" can grep for `"Disabled in .pmat.yaml"` specifically.

We deliberately chose not to introduce a third status `Disabled` because the existing four-state machine (Pass/Warn/Fail/Skip) is enough — the distinguishing information is in the message, not the status code.

## How the Skip Message Is Constructed

The message format is stable and grep-friendly. Every CB-16xx check emits one of these three message shapes when it skips:

1. **"No X yet"** — the upstream writer hasn't produced file or field X.
2. **"No Y has X yet (N eligible)"** — there are eligible candidates for the check but none carry the evidence. The `(N eligible)` count tells you how many tickets *would* be checked once the writer lands.
3. **"X not applicable"** — the ticket or project structurally doesn't need this check (e.g. "No L5 ticket present" for CB-1616 when nothing claims L5).

The eligible count in pattern 2 is valuable for prioritization. If you see:

```
CB-1614: L4 Kani Evidence: Skip — No L4+ ticket has a `kani-report.json` yet (12 eligible)
```

then 12 tickets are claiming L4 today and waiting for the Kani runner. That is a concrete signal for the team shipping Component 24: their work will affect 12 tickets on day one.

## Evolution: When Skip Semantics Get More Granular

As writers land, some checks will split their single Skip message into multiple tiered messages. CB-1612 already does this:

- Tier 1: `"No ticket has `verification-report.json` yet"` — writer not emitting reports at all
- Tier 2: `"No verification-report.json carries `l1_test_evidence` yet"` — writer emitting reports but not the new field

This two-tier pattern will propagate to other checks as their writers gain incremental capabilities. The pattern is always: the skip message should name the *most specific* missing thing.

## Anti-Pattern: Using --failures-only Without Reading Skips

`pmat comply check --failures-only` hides Skip and Pass entries:

```bash
pmat comply check --failures-only
```

This is useful when you're triaging for fixes, but it's a trap if you read it as "everything is fine". A repo with 0 failures and 46 skips has significant enforcement headroom — it's not a fully-green repo, it's a repo waiting for writers.

The right consumer workflow:

1. **Triage mode**: `pmat comply check --failures-only` to find things that need fixing *now*.
2. **Enforcement mode**: `pmat comply check` (no filter) to see the full skip ladder and plan what to ship next.
3. **CI mode**: `pmat comply check --format json` to extract counts and track trends.

Skip is information. Hiding it is a choice with trade-offs, not a sensible default.

## Summary

Tiered skip semantics encode a specific engineering philosophy: **ship enforcement gates alongside the spec, not after the producers**. The gates read evidence files that do not yet exist and return Skip-with-reason instead of failing or being disabled. As producers land, skips collapse to Pass/Fail automatically. There is no flag to flip, no CI config to update. The only dated promotion in the family is CB-1620's 2026-05-17 cutoff — and that is specifically the migration-backfill deadline, not a writer-ship deadline.

The practical benefit: on the day a new runner lands, CB-16xx compliance scores change across every project in the fleet without anyone updating `pmat` or editing `.pmat.yaml`. That is the kaizen argument.

Skips are the feature. Read them, track them, watch them shrink over time. They are the most honest possible report of how much of the spec is currently actionable in your repo.

---

*Cross-references*:
- Chapter 56 main: `src/ch56-00-comply.md`
- Section 1: `src/ch56-01-verification-ladder.md` (the L0..L5 ordinal these gates enforce)
- Section 3: `src/ch56-03-agent-workflow.md` (worked example — watch skips turn green in real time)
- CB-1620 handler: `src/cli/handlers/comply_handlers/check_handlers/check_falsification_unification_roster.rs` in the pmat repo
