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

## The 3.18.2 Follow-Up: Fixing What the Dogfood Found

The 111-command dogfood that validated 3.18.1 also catalogued seven
pre-existing defects. v3.18.2 (same day) fixed all of them:

| Surface | Defect | Fix |
|---------|--------|-----|
| `perfection-score` | RPS raw points divided by a stale hardcoded 134.0 scale → "184%" → total clamped to 200/200 A+ | Normalize by the orchestrator-reported `total_possible`; categories clamp to `[0, max]` |
| `semantic search` | "Found 3 results", zero rows rendered (empty embeddings store) | Count and rows derive from one result set; empty store yields explicit `pmat embed sync` guidance |
| `tdg baseline list/compare`, `check-regression`, `check-quality` | Decorated banners and ephemeral-baseline progress polluted `--format json` stdout | JSON-mode stdout is exactly one document; decoration → stderr; `check-quality` merges both gates into `{gate, f_grade_gate, passed}` |
| `oracle status/fix/single` | Banner before JSON | Gated on format |
| `qdd validate` | ANSI header before JSON; `--output` claimed to write a report it never wrote | Header gated; report actually written before the notice |
| `falsify` | `--format json` accepted, silently ignored | Implemented for dry-run and full runs, honors `--failures-only` |
| `enforce extreme --file` | Single-file mode analyzed all 2,717 project files | `AnalysisScope` threads the file through every phase |
| TDG penalty ordering | `penalties_applied` reordered between identical runs (HashMap in `PenaltyTracker`) — caught when the re-dogfood's byte-identical baseline check flaked | BTreeMap keyed by issue id; 4/4 runs byte-identical |

The fix diff went through the same adversarial review as 3.18.1 — and again
it caught a contract violation in the fix itself: `check-quality --format
json` still emitted **two** concatenated JSON documents on exactly the path
CI cares about (F-grade violations present), because two `display_gate_result`
calls each printed their own document. The review's JSON-contract lens traced
every `println!` reachable in JSON mode across all six surfaces and found the
one conditional path the new tests didn't cover. The shipped fix merges both
gate verdicts into a single document.

## The MCP Pass: Validating the Agent-Facing Surface

Before release, all 20 live MCP tools were validated over real stdio
JSON-RPC the way a fleet of workflow agents uses them: every tool called
with schema-derived arguments, two 8-way concurrent-session bursts (zero
lock errors, zero scratch leftovers — the concurrency fixes hold through
MCP), and byte-level framing checks (no non-JSON-RPC stdout anywhere). The
SDK was bumped to the latest pmcp (2.3.0 → 2.9.0) with the full MCP test
suite green.

Five confirmed defects were fixed, the worst being an **index source-wipe**:
every incremental index save rewrote the SQLite DB from lightweight-loaded
entries whose `source` column was never read, so each save wiped source for
all unchanged functions until the entire index (21k rows) returned empty
source — silently breaking the documented agent workflow (`pmat_get_function`,
`--include-source`). A second bug hid the first: the incremental path dropped
`db_path`, so the on-demand backfill that would have masked the wipe
early-returned. Four months of "use the index, not Read/grep" guidance ran
on a dead path. The fix restores source before each rewrite, propagates
`db_path`, self-heals wiped DBs, and pins it all with regression tests.

Also fixed: an inverted `passed` verdict in the `quality_gate` tool (and the
same Grade-ordering inversion in CLI `--min-grade`), three tools advertising
empty schemas that made them uncallable by schema-validating clients,
`pdmt_deterministic_todos` generating random UUIDs, and the stdio server
never exiting on stdin EOF (one leaked process per scripted session).
