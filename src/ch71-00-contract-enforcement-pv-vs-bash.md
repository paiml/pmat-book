# Chapter 71: Contract Enforcement via `pv`, not Bash (MUDA)

On 2026-04-18, same day as the R8 / R9 dogfood rounds documented in Chapters 69 and 70, a separate policy round (R11) took the knife to an adjacent problem: **the shell-script layer that had accumulated around pmat's contract gates**. Where R8 measured the slow tail and R9 named the execve coupling, R11 asked a blunter question: *how much of the enforcement layer in this codebase is even code?* The answer was that a non-trivial fraction was adhoc bash, and bash is the wrong tool for that job. This chapter is the written-down version of the policy that came out of R11.

The policy is one sentence:

> Contract enforcement must go through `pv` (aprender-contracts-cli). Adhoc bash for enforcement is MUDA — must be deleted or migrated.

The rest of this chapter is the operational "why" and "how".

## 71.1 The MUDA Principle

Toyota Production System names seven classes of waste ("muda" — 無駄), and *Overprocessing* is the one that bites software teams hardest: doing more work than the downstream step requires, in a way that still looks productive. A 40-line bash gate that re-implements a substring scan and an integer threshold check — when a purpose-built contract linter already performs the same check with proper provenance, severity, and CI reporters — is textbook overprocessing. Every additional shim is:

* one more thing to read in a review,
* one more place where severity rules drift,
* one more surface where `set -e` / `set -o pipefail` gets it subtly wrong,
* one more item to delete during the next dogfood round.

The rule from R11 draws the line cleanly. Measurement is welcome — running `/usr/bin/time -v cargo check` and saving a JSON row is data collection, which is how Chapters 68–70 even got written. **Enforcement** is different. The moment a shell script flips into `if grep -q X foo; then exit 1; fi`, it has become a contract gate without the provenance of one, and the MUDA counter ticks up by one.

## 71.2 Measurement vs Enforcement

The distinction is worth spelling out because it is where teams resist the policy.

| Step | OK in bash? | Why |
|---|---|---|
| `/usr/bin/time -v pmat score > runlog.txt` | yes | Pure measurement; no gating. |
| `python3 scripts/parse_runlog.py runlog.txt` | yes | Data shaping for a report. |
| `jq '.wall_p50' runs.json > p50.txt` | yes | Projection over collected data. |
| `if grep -q "unwrap()" src/; then exit 1; fi` | **no** | Adhoc enforcement. Migrate to `pv audit` rule. |
| `tdg_score=$(pmat tdg . | awk '...') ; [[ $tdg_score < 85 ]] && exit 1` | **no** | Adhoc enforcement. Use `pv lint --min-score`. |
| `find src/ -name '*.rs' | xargs wc -l | sort -n | tail -5` | yes | Reporting; no gate. |
| Same command piped into `if [[ $biggest -gt 700 ]]; then exit 1; fi` | **no** | Became a gate. Migrate to `pv audit --threshold file-size=700`. |

The rule of thumb: **if a shell pipeline ends in `exit 1`, `exit $?`, or `set -e`-dependent branching on a substantive predicate, it is enforcement and it is on the migration list.** If it ends in a file, a JSON blob, or a printed table, it is measurement and it lives.

## 71.3 The `pv` Subcommand Surface

`pv` is the aprender-contracts-cli binary installed at `~/.cargo/bin/pv`. The subset relevant to enforcement is:

| Subcommand | One-line purpose |
|---|---|
| `pv lint [DIR]` | **Run all contract quality gates** (validate + audit + score + verify + enforce + composition). Single entry point for CI. |
| `pv score` | Composite contract score across a directory; emits JSON/SARIF for dashboards. |
| `pv audit` | Contract audit — unreferenced bindings, missing obligations, SATD-style findings. |
| `pv validate` | YAML schema + semantic validation of a single contract file. |
| `pv kaizen` | Fleet-wide enforcement loop; used by the CI side that wants "all repos green". |
| `pv verify-structure` | Architecture-shape verification against declared contracts. |
| `pv verify-pipeline` | Cross-repo compositional shape-flow verification (used by certify). |

`pv lint` is the canonical enforcement entry point. It emits a gate table:

```text
pv lint — contract quality gate
================================
  Gate 1: validate             ✓  (12 contracts, 0 errors, 0 warnings) [22ms]
  Gate 2: audit                ✓  (12 contracts, 0 findings) [18ms]
  Gate 3: score                ✓  (mean=0.91, threshold=0.80) [9ms]
  Gate 4: verify               ✓  (214 refs, 214 found, 0 missing) [43ms]
  ...
Result: PASS
```

and exits non-zero on any red gate. That is the exact table the `pv_contract_gate.rs` harness in §71.6 parses.

## 71.4 The Migration Pattern — Before and After

The migration is mechanical once the gate is identified. Four representative translations:

```bash
# Before (MUDA) — ad-hoc SATD threshold
if grep -r "TODO\|FIXME" src/ | wc -l | awk '{exit $1>100}'; then exit 1; fi

# After — explicit, typed threshold, structured output
pv audit --threshold satd=100
```

```bash
# Before (MUDA) — ad-hoc TDG floor
tdg=$(pmat tdg . --format json | jq '.overall_score')
awk -v t="$tdg" 'BEGIN { exit (t < 85.0) ? 1 : 0 }'

# After — one call, same semantics, gate-table emits provenance
pv lint --min-score 0.85
```

```bash
# Before (MUDA) — ad-hoc file-size gate
biggest=$(find src -name '*.rs' -exec wc -l {} \; | sort -n | tail -1 | awk '{print $1}')
[[ $biggest -gt 700 ]] && { echo "file too big"; exit 1; }

# After — rule lives in .pv.toml, same verdict, better error
pv audit --rule PV-FILE-SIZE=700
```

```bash
# Before (MUDA) — ad-hoc cross-repo check via a bespoke shell loop
for repo in pmat aprender trueno renacer; do
  cd "../$repo" && ./scripts/local-check.sh || exit 1
done

# After — fleet loop is first-class
pv kaizen --repos pmat,aprender,trueno,renacer
```

In each case, the `After` form is strictly shorter, strictly better-provenanced, and strictly easier to suppress-with-justification via `.pv.toml` than the `Before` form. There is no case where the bash version wins on merit once the rule is codifiable.

## 71.5 What Bash IS Still Good For

The policy is not "delete all shell scripts". Four classes survive:

1. **Installers and setup** — `scripts/install.sh`, `scripts/install-git-hooks.sh`. Bootstrapping a toolchain is exactly where bash is strongest; `pv` cannot install itself.
2. **Pure measurement with no gate** — `scripts/benchmark_build.sh`, `scripts/profile_context.sh`. These emit data; downstream tools decide.
3. **Tool wrappers that delegate** — a three-line wrapper that just forwards arguments to `pv lint` with a repo-specific default is a reasonable ergonomic shim.
4. **One-off archaeology** — grep-for-a-string during a debugging session, deleted before commit.

The failure mode to watch for is (3) growing into (migration target). A wrapper that starts life as `exec pv lint "$@"` and a year later has five `case` arms and two `jq` pipelines has become enforcement logic that lives outside `pv`. Review for it.

## 71.6 The `pv_contract_gate.rs` Template

The pmat repo ships a stdlib-only Rust harness at `examples/pv_contract_gate.rs` that is the canonical replacement for the shell gates above. It:

1. Probes `pv --version` for tool presence, exits 2 with an install hint if missing.
2. Runs `pv lint <dir>` and reproduces the gate table verbatim so human and CI logs stay legible.
3. Parses the final `Result: PASS / FAIL` line and exits 0 or 1 accordingly.
4. Is 110 lines of `std::process::Command` + `Instant` — no deps, no async runtime, no tokio. Same pattern as the `http_stub_probe.rs` / `o1_hook_probe.rs` / `exit_code_audit_driver.rs` harnesses from Chapter 69.

The harness can be wired into `make lint`, a pre-commit hook, or a CI step as a single command:

```bash
cargo run --example pv_contract_gate
cargo run --example pv_contract_gate -- path/to/contracts
```

Distinct exit codes (0 = pass, 1 = violation, 2 = pv missing, 3 = spawn failure) let the caller decide whether a missing toolchain is tolerable (useful during onboarding) or fatal (useful in CI). The file is small enough to copy into any downstream repo as a starting point — the aprender #895 migration is doing exactly that.

## 71.7 The pmat Dogfood Target

pmat itself has 32 shell scripts under `scripts/`. R11 agent #1's audit will publish the specific deletion candidates; the categories already visible from filenames are:

* **Measurement survivors** — `benchmark_build.sh`, `profile_context.sh`, `property_test_metrics.sh`, `complexity-distribution.sh`. These emit data, no `exit 1` on predicates. Keep.
* **Installer survivors** — `install.sh`, `install-git-hooks.sh`, `configure-swap.sh`. Bootstrap flows, no gate semantics. Keep.
* **Enforcement migration targets** — `check_dependency_duplicates.sh`, `dead-code-calibration.sh`, `pre-commit-property-tests.sh`, `compute-metric-hash.sh`. These embed thresholds and `exit 1` on predicate. Each maps to a `pv audit` rule or a `pv lint` gate with a `.pv.toml` threshold. Migrate.
* **One-off archaeology to delete outright** — `final_property_test_fix.sh`, `fix_property_test_syntax.sh`, the `.ts` variants. Names alone betray fix-in-flight scripts that outlived their patch.

Order of operations for the migration: convert enforcement shell scripts to `.pv.toml` rules first, wire them into `pv lint`, then delete the `.sh` files in a separate commit so the history shows the verdict clearly. **Delete; do not comment out. Commented-out bash enforcement is still MUDA**, just quieter.

## 71.8 The aprender #895 Cross-Reference

The pattern in this chapter is pmat-local, but the policy is organisation-wide. aprender issue **#895** tracks the equivalent migration inside aprender itself — deleting the bespoke benchmark-gate shell glue in favour of `pv lint` with an `aprender-contracts` rule set. The two migrations are deliberately parallel: the aprender-side work teaches `pv` any rules that pmat's migration exposes as missing, and the pmat-side work validates that those rules generalise.

When both migrations land, the shape of the story is: `pv` is the single binary that enforces contracts across the whole batuta stack, and every repo gates on `pv lint` plus at most one wrapper script that exists purely to pass repo-specific defaults. That is the end state implied by R11, and the one the chapter you are reading is meant to make impossible to forget.

## 71.9 Related Chapters

* **Chapter 62** — Provable Contracts (CB-1200..CB-1214). The contract substrate that `pv` operates on.
* **Chapter 66** — Kaizen R4 roadmap. The KAIZEN ticket surface that tracks contract-gate migrations.
* **Chapter 67 §67.4** — Lesson 3 (a quality-gate that cannot fail cannot gate). Same principle applied to shell gates.
* **Chapter 68 §68.1** — The exit-0-on-error family. The symmetric defect on the other side of the fence: tools that silently pass when they should fail.
* **Chapter 69 §69.7** — the `o1_hook_probe.rs` / `http_stub_probe.rs` / `exit_code_audit_driver.rs` harness siblings. `pv_contract_gate.rs` slots into that family.

## 71.10 Summary

The 2026-04-18 rule is simple enough to put on a sticker: **measurement in bash, enforcement in `pv`**. The 32 shell scripts in `scripts/` and their equivalents across the batuta stack are in scope for migration. `examples/pv_contract_gate.rs` is the copy-paste template. aprender #895 is the org-wide tracker. Every further shell gate added from here on is, by policy, a regression.
