# Chapter 63: DbPC Scaffolding (CB-1900..1949)

*Design by Provable Contract — compliant on day one*

`pmat scaffold rust-project --dbpc-level L3` emits a tree that passes `pmat comply check` the first time you run it, before you have written a single line of application code. This chapter explains what that sentence actually means: what DbPC is, which artifacts the scaffold has to generate, why every CB-16xx gate must either Pass or Skip on a fresh tree, and how the 12-ticket CB-1900..1949 roadmap delivers the full posture.

This is Chapter 63. The chapter assumes you have read Chapter 56 (CB-16xx Compliance Governance) and Chapter 62 (Provable Contracts CB-1200..1214). DbPC scaffolding sits on top of both — it takes the enforcement rules from Chapter 56 and the contract surface from Chapter 62 and inverts them: instead of retrofitting a project to compliance, it generates compliance on day one.

## Why "Scaffolding" Needs a Spec

`pmat scaffold` has shipped templates since v2.x. What it did not do is wire up Design-by-Provable-Contract. A freshly-scaffolded project would compile, pass `cargo test`, and then fail `pmat comply check` the first time you bound a ticket. The author had to hand-assemble:

* ProvableContract YAMLs under `contracts/`
* Work tickets under `.pmat-work/<ID>/contract.json` with SHA snapshots
* `verification-report.json` and `falsification.log` placeholders so CB-1610..1613 could Pass
* A `build.rs` invoking `pmat contract codegen`
* A `renacer.toml` with at least one scenario stub
* Kani / Lean harness files if the project targeted L4 / L5
* A `.pmat-gates.toml` calibrated for the project size
* A project-local `CLAUDE.md` encoding the pmat-query / no-grep / pre-commit policies

Each new project re-invented this setup. The DbPC posture was lost the moment one file went missing. The v3.14.0 dogfood report flagged `pmat-dashboard` at 0% enforcement penetration for exactly this reason — the team had all the primitives but never bothered to glue them together. CB-1340 (2026-04-18) tracked that finding; CB-1900..1949 is the fix.

The goal of the spec: **scaffolding emits a tree that is COMPLIANT out of the box**. Every CB-16xx gate that *can* be satisfied at the chosen verification level is already satisfied. Every other gate Skips with the intended reason. Zero Fail on the first `pmat comply check`. This is what "DbPC on day one" actually means.

## Design by Contract, Upgraded

Bertrand Meyer's Design by Contract put preconditions and postconditions on individual methods. DbPC evolves that into a five-step binding lifecycle:

1. **Declared** in YAML. Contracts live under `contracts/*.yaml` with `equations:`, `preconditions:`, `postconditions:`, `falsification_tests:`, `kani_harnesses:`, and optionally `lean_theorem:` blocks.
2. **Compiled** via `build.rs`. The scaffolded `build.rs` calls `pmat contract codegen --out $OUT_DIR/contract_traits.rs` so that Rust sees `debug_assert!` bindings and trait implementations (CB-1203).
3. **Bound** to tickets. Each `.pmat-work/<ID>/contract.json` declares `implements: [...]` — a list of equations the ticket promises to satisfy. Bind-time SHA snapshots of the YAML are recorded under `.pmat-work/<ID>/kani-harness-shas.json` and `expected-snapshot.json` to catch silent post-bind drift.
4. **Verified** at escalating levels. L0 paper → L1 `cargo test` asserts → L2 equations instantiated → L3 `falsification_tests[]` clean → L4 `cargo kani` discharges → L5 `lake build` produces a zero-sorry proof.
5. **Enforced** by `pmat comply check`. The CB-1200..1214 and CB-1600..1649 gates read evidence files produced in steps 1-4 and fail closed on any drift.

Classic DbC let authors silently relax contracts mid-development. DbPC prevents that with three specific controls:

* **Verification-level monotonicity (CB-1618)** — a ticket's achieved level cannot regress between checkpoints without a documented CB-1617 downgrade note. You cannot climb to L4 and then quietly drop back to L3.
* **Bind-time SHA snapshots (CB-1615, CB-1621)** — the Kani harness body hashes and scalar `expected:` values are recorded at bind time, so the gate fires when a YAML edit silently drifts a bound value.
* **Liskov-Wing weakest-binding-dominates (CB-1617)** — a ticket bound to multiple YAMLs is capped at the weakest binding's max-attainable level. You can't claim L4 for a ticket whose second binding lacks `kani_harnesses:`.

DbPC is the target posture. Scaffolding is the one-shot bootstrap that gets a project there in a single command.

## The Scope Delta: What Changes in the Scaffold Output

The spec enumerates 14 artifacts the scaffold generates or extends compared to today's templates. Here is the full delta table:

| Artifact | Today | After CB-1900..1949 |
|---|---|---|
| `Makefile` | Generated (wasm template) | Plus `dbpc-check`, `dbpc-bind`, `dbpc-promote` targets |
| `README.md` | Basic template | DbPC section: CB-16xx pointers, pmat-query policy, ladder table, `make dbpc-check` quick-start |
| `Cargo.toml` | Generated | Plus `[build-dependencies]` for contract codegen; `coverage(off)` on codegen output |
| `src/lib.rs` | Hello world | `#[cfg(contract_traits)] pub mod contract_traits; include!(concat!(env!("OUT_DIR"), "/contract_traits.rs"));` |
| `build.rs` | Not generated | Invokes `pmat contract codegen --out $OUT_DIR/contract_traits.rs` |
| `contracts/example.yaml` | Not generated | One equation with `preconditions`, `postconditions`, `falsification_tests:` + (optionally) `kani_harnesses:` / `lean_theorem:` |
| `.pmat-work/EXAMPLE-001/contract.json` | Not generated | Ticket at the chosen `--dbpc-level`, `implements:` bound to `contracts/example.yaml` |
| `.pmat-work/EXAMPLE-001/verification-report.json` | Not generated | Seeded so CB-1610 Passes on first scaffold |
| `.pmat-work/EXAMPLE-001/falsification.log` | Not generated | Seeded so CB-1611 Passes at L3+ |
| `.pmat-work/EXAMPLE-001/kani-harness-shas.json` | Not generated | Seeded when `--with-kani` |
| `.pmat-work/EXAMPLE-001/lean-proof.json` | Not generated | Seeded when `--with-lean` |
| `.pmat-work/ledger/roster-mutations.json` | Not generated | Empty array so CB-1624 Passes |
| `renacer.toml` | Not generated | One scenario stub |
| `.pmat-gates.toml` | Partial | All CB-16xx thresholds; CB-1620 `2026-05-17` cutoff noted |
| `CLAUDE.md` (project-local) | Not generated | pmat-query policy, no-grep rule, `--faults` enrichment, CB-16xx pointer, batuta-stack link |

Explicitly non-goals (deferred to later CB series):

* Monorepo / workspace scaffolding (`pmat-workspace scaffold` is separate)
* Non-Rust language scaffolds — Python / JavaScript DbPC is the CB-2000 series, future
* Auto-filling `kani_harnesses:` proof bodies — the scaffold emits a compiling stub; the author writes the actual proof

## The CLI Surface

A new flag family lands on existing `pmat scaffold rust-project` (and by extension `scaffold agent` / `scaffold wasm`):

```bash
pmat scaffold rust-project \
    --name my-crate \
    --dbpc-level L3 \                    # L0..L5; default L1
    --with-contracts example,invariant \ # comma-list of seed YAMLs
    --with-kani \                        # implies L4 minimum
    --with-lean \                        # implies L5
    --claude-md                          # emit project-local CLAUDE.md (default: true)
```

Flag interactions are explicit:

* `--with-kani` upgrades `--dbpc-level` to at least L4 — if the author asked for lower, the scaffold warns and proceeds at L4
* `--with-lean` upgrades to L5 under the same rule
* `--dbpc-level L0` emits paper-only YAML plus skip-compliant stubs; the tree still passes `comply check` because every non-L0 gate Skips with a level-adequate reason
* Omitting `--dbpc-level` defaults to **L1** — the minimal DbPC obligation, `debug_assert!` bindings only, no proof infrastructure required

The default L1 is deliberately almost free. L1 adds a few crate dependencies and a `build.rs` that compiles in under two seconds. For teams that want DbPC but aren't ready to write Kani harnesses, L1 gets them on the ladder with no verification cost.

## The Acceptance Invariant: Zero Fail on Day One

This is the hard acceptance gate for CB-1900..1949 — the spec's executable definition of done:

```bash
pmat scaffold rust-project --name foo --dbpc-level L3 --with-contracts example
cd foo
cargo build           # succeeds — build.rs runs pmat contract codegen
cargo test            # passes — seeded falsification_tests compile and run
pmat comply check     # exits 0 with COMPLIANT status
```

Within `pmat comply check` output, at L3, the gate tally must be:

* **CB-1610..CB-1616 Pass** — ladder evidence present, SHAs match, report values green
* **CB-1620 Pass** — derived obligations match the seeded ProvableContract entries
* **CB-1621 Pass** — no expected-snapshot drift on a fresh bind
* **CB-1624 Pass** — empty roster-mutations ledger
* **CB-1617..CB-1619 Skip** — no downgrades filed yet, no Lean evidence at L3
* **CB-1640..CB-1649 (codegen) Pass** when `build.rs` ran cleanly

At L5 with `--with-lean`, all 50 CB-16xx gates are either **Pass** or **Skip with a documented reason**. **Zero Fail on a freshly-scaffolded tree** is the hard acceptance gate. CI on this spec runs exactly `pmat scaffold ... && pmat comply check` as the definition of done. If that two-line invocation emits a Fail, the spec is wrong or the scaffold is wrong — either way it blocks merge.

## The 12-Ticket Roadmap

CB-1900..1949 decomposes into 12 tickets, totaling approximately 2 weeks for a single engineer:

| CB | Title | Effort | Depends on |
|---|---|---|---|
| CB-1900 | Define DbPC terminology + this spec | S | — |
| CB-1910 | Extend Makefile scaffold with `dbpc-check/bind/promote` targets | S | CB-1900 |
| CB-1920 | Rewrite `README.md.tmpl` with DbPC section; emit project-local CLAUDE.md | M | CB-1900 |
| CB-1930 | `--dbpc-level` + `--with-contracts` CLI flags on `scaffold rust-project` | M | CB-1910, CB-1920 |
| CB-1940 | Seed `.pmat-work/EXAMPLE-001/` tree (contract.json + evidence stubs) | M | CB-1930 |
| CB-1941 | Seed `contracts/example.yaml` matching chosen level | S | CB-1940 |
| CB-1942 | Seed `build.rs` invoking `pmat contract codegen` | S | CB-1940 |
| CB-1943 | Seed `.pmat-gates.toml` with all CB-16xx thresholds | S | CB-1940 |
| CB-1944 | Seed `renacer.toml` scenario stub | S | CB-1940 |
| CB-1945 | Kani harness scaffold stub (`--with-kani`) | S | CB-1940 |
| CB-1946 | Lean theorem scaffold stub (`--with-lean`) | S | CB-1940 |
| CB-1949 | Acceptance harness: `pmat scaffold ... && pmat comply check` passes in CI | M | all above |

Effort totals: **4 × S + 3 × M ≈ 2 weeks for one engineer** end-to-end. The critical path is CB-1900 → CB-1930 → CB-1940 → CB-1949. Once CB-1930 lands the flag plumbing, CB-1910 / CB-1920 / CB-1942 / CB-1943 / CB-1944 / CB-1945 / CB-1946 are independent and can fan out across a pair or a small team.

## The Sentinel `EXAMPLE-001` Ticket

The seeded ticket has a specific ID — `EXAMPLE-001` — and a flag in its `contract.json`:

```json
{
  "work_item_id": "EXAMPLE-001",
  "example": true,
  "verification_level": "L3",
  "implements": [
    { "yaml": "contracts/example.yaml", "equation": "example_placeholder_do_not_ship", "sha": "..." }
  ]
}
```

Three design decisions live in those fifteen lines:

1. **The ID is a sentinel.** `EXAMPLE-001` is reserved — real tickets cannot use it. `pmat work list` filters it out by default. This keeps the scaffolded ticket out of the author's real work queue while still counting as a live ticket for CB-16xx purposes.
2. **The `"example": true` flag is load-bearing.** A future CB-1900 gate (not to be confused with the spec ticket number) fails if any *active* ticket binds to an equation whose name matches the pattern `example_placeholder_*`. The flag is what allows `EXAMPLE-001` itself to bind without tripping the gate — anyone else binding to the example YAML trips immediately.
3. **The equation name is adversarial.** `example_placeholder_do_not_ship` is the name on purpose. If an author copy-pastes the example YAML into a real contract without renaming the equation, the gate fails on their first `pmat comply check`. The scaffold forces a rename; there is no accidental path from example to production.

Together these three controls make the seed ticket useful (CB-1611 can read an `implements:` block and pass) without any risk of it leaking into a real production contract.

## The `build.rs` Fallback

Scaffolded projects will be copied into offline environments, CI containers without `pmat` on `$PATH`, and contributors' laptops before they've installed pmat. The scaffolded `build.rs` must handle all three without breaking `cargo build`:

```rust
fn main() {
    let pmat = std::env::var("PMAT")
        .ok()
        .or_else(|| which::which("pmat").ok().map(|p| p.display().to_string()));

    let Some(pmat) = pmat else {
        println!("cargo:warning=pmat not found on PATH. DbPC contract codegen skipped. \
                   Install pmat (https://github.com/paiml/paiml-mcp-agent-toolkit) \
                   or set PMAT=/path/to/pmat to enable L2+ verification.");
        return;
    };

    let out_dir = std::env::var("OUT_DIR").expect("cargo sets OUT_DIR");
    let status = std::process::Command::new(&pmat)
        .args(["contract", "codegen", "--out"])
        .arg(format!("{out_dir}/contract_traits.rs"))
        .status()
        .expect("failed to spawn pmat");

    if !status.success() {
        panic!("pmat contract codegen failed");
    }

    println!("cargo:rustc-cfg=contract_traits");
}
```

The key line is `println!("cargo:warning=...")` on the absent-pmat path. `cargo build` still succeeds — the project just builds without DbPC bindings wired up. This preserves two things the spec cares about:

* **Contributors can build immediately** — they don't have to install pmat to see `cargo check` go green on a freshly-cloned repo
* **L2+ verification still fails closed** — because the `contract_traits` cfg isn't set, any `#[cfg(contract_traits)]` assertion is compiled out, and `pmat comply check` will see no evidence of contract codegen running, which fails CB-1630 (codegen receipt required)

The L1 path is unaffected — `debug_assert!` bindings don't depend on the `contract_traits` cfg. A team that scaffolded at L1 and never installed pmat still gets the asserts.

## The Project-Local CLAUDE.md

The scaffold emits a CLAUDE.md at the repo root (unless `--claude-md=false`). This file is how AI agents discover the policies that the human team has agreed to. It MUST include, by reference or inline:

1. **pmat query policy** — the decision table from the PMAT repo CLAUDE.md lines 45-70
2. **"No grep for code search"** — explicit rule, with reasoning
3. **Pre-commit gate thresholds** — link to the generated `.pmat-metrics.toml`
4. **CB-16xx pointer** — "run `pmat comply check` before every commit; see `docs/specifications/components/commit-level-contract-enforcement.md`"
5. **Batuta stack priority** — if the generated `Cargo.toml` pulls in math / ML deps, remind the agent to prefer aprender / trueno / renacer
6. **Documentation accuracy** — `pmat validate-readme` before shipping README edits

Generation goes through `readme_dbpc_section.md.tmpl` + `claude_md.tmpl` with variable substitution so the CB-16xx link target matches the scaffolded project's layout. The point of this file is not to be exhaustive — the PMAT root CLAUDE.md is the source of truth — but to give every new project a stub that names the policies an agent will encounter.

## The README DbPC Section

The generated README.md gets a new top-level section, rendered from `readme_dbpc_section.md.tmpl`:

```markdown
## Design by Provable Contract (DbPC)

This project was scaffolded at verification level **L3**.

### Quick Start

    make dbpc-check   # runs pmat comply check on the tree
    make dbpc-bind    # attach a work ticket to an equation
    make dbpc-promote # climb a ticket one level up the ladder

### Ladder Status

| Level | Status | Evidence |
|---|---|---|
| L0 documentation | Pass | `contracts/example.yaml` |
| L1 debug_assert | Pass | `cargo test` green |
| L2 equations bound | Pass | `build.rs` codegen succeeded |
| L3 falsification tests | Pass | `.pmat-work/EXAMPLE-001/falsification.log` |
| L4 Kani discharges | Not attempted | (set `--with-kani` at scaffold time) |
| L5 Lean proof | Not attempted | (set `--with-lean` at scaffold time) |

### Pre-commit posture

Every commit runs `pmat comply check`. The CB-16xx gate tally is recorded in `.pmat-metrics/commit-<short_sha>-meta.json`.
```

This section is the first thing a human reader sees when they clone the repo. It tells them the level, how to exercise it, and what the next rung on the ladder costs (another Kani harness, or a Lean theorem). The Ladder Status table updates automatically each time `pmat comply check` runs — the section is regenerated from the latest report.

## Artifact → CB Gate Map

One useful mental model: each scaffolded artifact exists to satisfy one or more specific CB-16xx gates. If you understand the map, you can read the acceptance invariant line by line.

| Artifact | Gates satisfied | Why |
|---|---|---|
| `contracts/example.yaml` | CB-1610, CB-1611, CB-1621, CB-1626, CB-1627 | Ladder root — every CB-16xx check eventually walks back here |
| `.pmat-work/EXAMPLE-001/contract.json` | CB-1600, CB-1601, CB-1605, CB-1619 | Declares the binding, SHA snapshot, target level |
| `.pmat-work/EXAMPLE-001/verification-report.json` | CB-1612, CB-1619 | Carries `l1_test_evidence` and `achieved_level` |
| `.pmat-work/EXAMPLE-001/falsification.log` (L3+) | CB-1613, CB-1622, CB-1625, CB-1628, CB-1629, CB-1608 | Every L3+ gate reads this log |
| `.pmat-work/EXAMPLE-001/kani-harness-shas.json` (L4+) | CB-1614, CB-1615 | Kani report + bind-time hash |
| `.pmat-work/EXAMPLE-001/lean-proof.json` (L5) | CB-1616, CB-1648, CB-1649 | Lean proof receipt |
| `.pmat-work/ledger/roster-mutations.json` | CB-1624 | Deletion audit |
| `.pmat-work/ledger/downgrades.json` | CB-1617, CB-1618 | Monotonicity excuse |
| `build.rs` + `contracts/work/*.rs` | CB-1630, CB-1631, CB-1633, CB-1636, CB-1638 | Codegen receipt + manifest + tracked in git |
| `codegen/last-run.json` | CB-1630 | Codegen succeeded on last pass |
| `codegen/compile-status.json` | CB-1636 | Debug and release both compile |
| `renacer.toml` scenario | CB-1644 | Golden-trace replay (via `agent-runs/`) |
| `.pmat-gates.toml` | All CB-16xx thresholds | Gate parameters (warnings vs fails, cutoffs) |
| `CLAUDE.md` (project-local) | Out of CB-16xx scope | Agent policy anchor |

There are 50 CB-16xx gates total. At L3, the scaffold satisfies ≈30 of them Pass and ≈15 Skip cleanly with intended reasons. At L5 with `--with-kani` and `--with-lean`, the count climbs to ≈40 Pass and ≈10 Skip (the remaining Skips are for L5-specific features like `cot-digest.json` which are out of scope for a fresh scaffold).

The table is the "why does this file exist" map. Every file has at least one gate that reads it. No file is generated for aesthetic reasons.

## Debugging a Failed Fresh-Scaffold Comply Check

When CB-1949's acceptance invariant fires in CI and the freshly-scaffolded tree emits a Fail, walk the diagnosis in this order:

**Step 1: Identify which gate failed.** `pmat comply check --format json | jq '.checks[] | select(.status == "fail")'` lists every non-passing check with its reason field. A fresh scaffold should produce zero failures, so any Fail is a regression in the scaffold output.

**Step 2: Cross-reference the artifact map.** Each failing gate maps to one or more artifacts in the table above. If CB-1613 fails, the artifact is `.pmat-work/EXAMPLE-001/falsification.log` — the scaffold either didn't emit it, emitted it with a non-pass line, or emitted the wrong JSON shape (CB-1628 enforces the four-field shape).

**Step 3: Diff against a known-good scaffold.** Run `pmat scaffold rust-project --name reference --dbpc-level L3 --with-contracts example` into a scratch directory, then `diff -r reference/.pmat-work/ failing/.pmat-work/`. The missing or wrong file is the delta.

**Step 4: Regenerate.** `rm -rf failing/.pmat-work failing/contracts failing/build.rs && pmat scaffold rust-project --name failing --dbpc-level L3 --skip-dir-check --with-contracts example` regenerates the DbPC artifacts in place without re-creating `src/` or `Cargo.toml`. If the regenerated tree passes, the original failure was template drift between scaffold runs; file it as a CB-1949 regression.

**Step 5: If regeneration still fails**, the bug is in the template itself or in `pmat comply check`. Report it with the fresh-scaffold reproducer attached — the scaffold command line plus the failing gate's JSON output is a complete bug report.

This workflow mirrors Chapter 56's "debugging workflow" for existing projects but collapses to a shorter path because a fresh scaffold has no prior state. Every failure is either a missing template or a mis-generated template; there is no "someone forgot to update the YAML three months ago" explanation.

## Template-System Hooks

CB-1930 and later land new templates under `src/scaffold/templates/dbpc/`:

* `contract_example.yaml.tmpl` — the seed equation YAML
* `contract_json.tmpl` — the `.pmat-work/<ID>/contract.json` skeleton
* `verification_report.json.tmpl` — seeded `target_level` / `achieved_level` / `l1_test_evidence`
* `kani_harness.rs.tmpl` — gated on `--with-kani`
* `lean_theorem.lean.tmpl` — gated on `--with-lean`
* `build.rs.tmpl` — the fallback-friendly `build.rs` above
* `renacer.toml.tmpl` — one scenario stub
* `pmat_gates.toml.tmpl` — the CB-16xx thresholds
* `claude_md.tmpl` — the project-local CLAUDE.md
* `readme_dbpc_section.md.tmpl` — injected into the existing README.md.tmpl

A new hook — `generate_dbpc_artifacts(level, contracts, with_kani, with_lean)` — runs after the existing `generate_pre_commit_hook_with_gates_fast()` pass. The `{{dbpc_level}}`, `{{with_kani}}`, `{{with_lean}}`, and `{{contract_names}}` template variables flow through both the `Makefile` and the `README.md` emitters so the Ladder Status table and the `make` targets stay consistent.

## Risks and Mitigations

The spec names four concrete risks and one mitigation per risk:

* **Risk: Scaffolded `build.rs` fails in offline environments where `pmat` isn't on PATH.** Mitigation: the `build.rs` fallback pattern shown above emits a `cargo:warning=` and returns cleanly. `cargo build` succeeds; L2+ verification fails closed by design.
* **Risk: Seeded `.pmat-work/EXAMPLE-001/` pollutes the real ticket queue.** Mitigation: the sentinel ID is reserved, `"example": true` is set, `pmat work list` filters it out by default.
* **Risk: Users copy-paste the example YAML into production and ship it.** Mitigation: the example equation name is `example_placeholder_do_not_ship`; a new CB-1900 gate fails if any active non-example ticket binds to a matching pattern.
* **Risk: Drift between this spec's CB list and the code reality.** Mitigation: CB-1949's acceptance harness (`pmat scaffold ... && pmat comply check` in CI) is the spec's executable contract. If the harness fails, the spec is wrong, not the code. Bijection via CB-1700 (Chapter on spec-code bijection, future).

Every risk has a mechanical mitigation. None rely on the author remembering a convention.

## The Non-DbPC Fallback

For teams that want a fast Rust stub and aren't ready to adopt DbPC, `pmat scaffold rust-project --dbpc-level none` emits today's non-DbPC scaffolding unchanged. No `contracts/`, no `.pmat-work/`, no `build.rs`, no CLAUDE.md. This is the fast-path.

The default remains **L1** because L1 is nearly free — `debug_assert!` bindings only, no verification infrastructure required. Teams that want to stay on DbPC without investing in Kani / Lean get the ladder root and can climb later. The `--dbpc-level none` escape hatch exists only for teams who need a 10-second scaffold and will enable DbPC on a follow-up pass.

## What "Compliant on Day One" Means for the Ecosystem

Every PMAT-consumer project (pmat-dashboard, pmat-book, certeza, aprender, trueno) was born before CB-1900. Each one has a manual DbPC retrofit in its history — an engineer wiring up `contracts/`, seeding `.pmat-work/`, discovering that `pmat comply check` flagged 14 gates, fixing each one, committing the mess. That retrofit cost an average of 4 hours per project and produced inconsistent results across repos.

CB-1900..1949 puts that retrofit in the scaffold. The next PMAT-ecosystem project — a hypothetical `pmat-graph-kernel` — gets scaffolded with:

```bash
pmat scaffold rust-project --name pmat-graph-kernel --dbpc-level L3
```

and the tree is compliant before the first commit. No 14-gate retrofit. No 4-hour detour. No inconsistency. The developer writes application code against `contract_traits` from day one.

That is the point of the spec. Scaffolding is not about generating boilerplate — it is about making the posture the team has agreed to be the posture the tree has, automatically, on every new project.

---

*Cross-references:*
- Spec: `docs/specifications/components/dbpc-scaffolding.md` (PR #326)
- Chapter 56: `src/ch56-00-comply.md` and sub-sections — CB-16xx gate catalog
- Chapter 62: `src/ch62-00-provable-contracts.md` — CB-1200..1214 contract surface
- Chapter 6: `src/ch06-00-scaffold.md` — baseline scaffold command
- Related specs: `provable-contracts.md`, `pmat-work-verification-ladder.md`, `commit-level-contract-enforcement.md`
- Acceptance harness (CB-1949): `pmat scaffold rust-project --dbpc-level L3 && pmat comply check`
