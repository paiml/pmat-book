# Chapter 73: v3.18.1 — Concurrency and Determinism Fixes from an Adversarial Audit

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ Case study — released as pmat v3.18.1

*Released: 2026-06-12*
*PMAT version: 3.18.1*
*Found by: 21-agent adversarially-verified audit of the 3.18.0 capability surface*
<!-- DOC_STATUS_END -->

## Why This Chapter Exists

pmat increasingly runs *underneath* fleets of autonomous agents: sixteen
concurrent invocations on one working tree is no longer an edge case, it is
the target workload. A multi-agent audit of 3.18.0 — every claim re-verified
by an adversarial second agent that re-ran the cited commands — surfaced a
cluster of bugs that only matter under exactly that workload: lost updates,
machine-global scratch paths, and nondeterministic serialization.

v3.18.1 fixes all of them. This chapter documents the bugs, the fixes, and
two meta-lessons: the review of the fix found regressions *in the fix*, and
thirteen existing tests turned out to pass only **because of** one of the
bugs.

## The Bugs

| # | Surface | Symptom | Root cause |
|---|---------|---------|------------|
| 1 | `pmat record-metric` | Each invocation erased all prior history for the metric | `MetricTrendStore::record()` persisted only its in-memory cache; a fresh store (one per CLI invocation) never loaded `<metric>.json` before writing it |
| 2 | `tdg check-regression`, `tdg baseline compare`, `tdg check-quality` | Two concurrent invocations corrupted each other's comparison | Ephemeral "current state" baseline written to **fixed machine-global** paths (`/tmp/pmat-regression-check.json`, `/tmp/pmat-current-baseline.json`, `/tmp/pmat-quality-check.json`) |
| 3 | TDG baseline JSON | Same tree, different bytes across runs/machines | `files`, `grade_distribution`, `languages` were `HashMap`s — key order followed hash-seed iteration order |
| 4 | SQLite index save | Concurrent savers could rename each other's half-built DB into place | Atomic-rename was correct, but every saver built into the same fixed scratch `<db>.db.tmp` |
| 5 | `tdg baseline create --name` | Flag accepted, silently discarded | Clap field bound as `name: _name` |
| 6 | `pmat verify` spec | Example JSON showed a `fixable` field the shipped struct doesn't have | Doc drift in the release the spec shipped with |

## The Fixes

**Lost updates (1)**: `record()` now holds an exclusive advisory lock (fs2)
on `<metric>.lock` for the whole read-modify-write, reloads from disk before
appending, and persists via scratch-then-rename. The lock wait is bounded
(5s) so a stuck holder cannot hang recording. A torn history file left
behind by pre-3.18.1 writes is moved aside to `<metric>.json.corrupt` and
recording continues.

**Machine-global scratch (2, 4)**: every scratch path now embeds the PID
(plus a per-process counter for the ephemeral baselines), via a shared
`utils::scratch` helper. Crash-orphaned scratch files — the SQLite ones can
be hundreds of MB — are swept on the next save once they're over an hour
old; the age guard protects concurrent live savers.

**Nondeterminism (3)**: the three maps are now `BTreeMap`s. Same JSON shape,
sorted keys, byte-stable across runs; pre-3.18.1 baseline files load
unchanged. `TdgBaseline::save()` is also atomic now.

**`--name` (5)**: baselines carry an optional `name` label that round-trips
through save/load, shows in `tdg baseline list --format json`, and is
preserved by `tdg baseline update`.

## Lesson 1: The Review of the Fix Found Bugs in the Fix

The fix diff went through the same adversarial process as the audit (four
review lenses, every finding re-verified by a skeptic agent). Two confirmed
regressions **introduced by the first version of the fix**:

1. **The corrupt-file brick.** Once `record()` loads before writing, a
   pre-existing torn file fails JSON parsing — forever. The old, buggy code
   "self-healed" by blindly overwriting. Robustness invariants can hide
   inside bugs; the fix had to re-add self-healing explicitly (move the bad
   file aside, warn, continue).
2. **The orphan leak.** PID-unique scratch names fix the clobbering race but
   break the old fixed name's accidental self-cleanup — nothing ever reuses
   a dead PID's name. The fix needed an explicit stale-scratch sweep.

Both share a shape worth remembering: *replacing a buggy mechanism removes
the buggy mechanism's side effects, and some of those side effects were
load-bearing.*

## Lesson 2: Thirteen Tests Passed Because of the Bug

Every pre-existing test of `MetricTrendStore` used a **fixed** path like
`/tmp/pmat-test-trends`. They were repeatable only because `record()`
truncated history on every call — the data-loss bug *was* their test
isolation. Fixing the bug made observations accumulate across test runs and
four of them immediately failed with counts like `left: 40, right: 10`.

If a test suite depends on a bug for isolation, the suite is silently
asserting the bug. All thirteen now use per-test `tempfile::TempDir`s.

## Verifying the Fixes

```bash
# Lost-update fix: two invocations, two observations
pmat record-metric --metric demo --value 1.0
pmat record-metric --metric demo --value 2.0
jq length .pmat-metrics/trends/demo.json   # → 2 (was 1 before v3.18.1)

# --name now honored and listed
pmat tdg baseline create --path src/ --output /tmp/b.json --name sprint-66
pmat tdg baseline list --path /tmp --format json | jq '.[0].name'  # "sprint-66"

# Deterministic serialization: stable bytes modulo timestamp
pmat tdg baseline create --path src/ --output /tmp/b1.json
pmat tdg baseline create --path src/ --output /tmp/b2.json
diff <(jq 'del(.created_at)' /tmp/b1.json) <(jq 'del(.created_at)' /tmp/b2.json)
```

Each fix ships with a regression test, including threaded lost-update tests
(8 concurrent recorders, 8 surviving observations) and a sorted-key-order
assertion that fails a `HashMap` revert deterministically rather than the
~97% of the time plain JSON equality would.
