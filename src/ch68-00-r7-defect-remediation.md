# Chapter 68: R7 Defect Remediation Patterns

The R7 dogfood round (2026-04-18) followed immediately on the heels of the five-round sweep catalogued in [Chapter 67](ch67-00-dogfooding.md). Where R1–R5 had produced a raw defect catalogue (D1..D58), R7 was the first round to ask a harder question: *now that the defects are known, what remediation patterns actually hold across the classes?* This chapter is the answer. It covers four pattern groups — each rooted in a named defect family — and closes with a patch-sketch (**CB-1800**) that ties them together as a shared-file-analysis algebra.

R7 adds 13 new defects to the catalogue. D59–D63 cover hook / worktree self-destructive side-effects; D64–D71 cover a second, more severe exit-0-on-error family found during the cuda-tdg audit. All R7 work is tracked in GitHub issues [#337](https://github.com/paiml/paiml-mcp-agent-toolkit/issues/337), [#342](https://github.com/paiml/paiml-mcp-agent-toolkit/issues/342), and [#343](https://github.com/paiml/paiml-mcp-agent-toolkit/issues/343).

## 68.1 Pattern One — The Exit-0-on-Error Family (D64..D71)

Chapter 67 documented five instances of pmat exiting 0 on a user-facing error (D16 / D25 / D26 / D35 / D57). R7 added eight more (D64..D71), and one of them is materially worse than anything in R1..R5:

> `pmat cuda-tdg score /nonexistent/path` prints a green line:
>
> ```text
> Grade: D  Gateway: PASSED
> Path: /nonexistent/path
> ```
>
> and returns exit code `0`.

A CI pipeline that shelled out to `pmat cuda-tdg score "$path"` to gate a merge is, in v3.14.0, **mathematically guaranteed to pass** regardless of whether the path exists. The entire class of path-validating sub-commands is thus also suspect. R7 audited eight:

| # | Command | Input | Observed Exit | Expected | Defect |
|---|---------|-------|---------------|----------|--------|
| 1 | `pmat cuda-tdg score /nonexistent/path` | invalid path | 0 | ≠0 | D64 |
| 2 | `pmat search nonexistent-term` | zero hits | 0 | ≠0 | D65 |
| 3 | `pmat five-whys "garbage"` | malformed question | 0 | ≠0 | D66 |
| 4 | `pmat scaffold project garbage` | unknown template | 0 | ≠0 | D67 |
| 5 | `pmat spec validate` | no arg | 0 | ≠0 | D68 |
| 6 | `pmat predict-quality` | no arg | 0 | ≠0 | D69 |
| 7 | `pmat split` | no arg | 0 | ≠0 | D70 |
| 8 | `pmat score --quick` | no arg | 0 | ≠0 | D71 |

### The Remediation Pattern

The instinct is to patch each subcommand individually. The R7 finding is that this is the *wrong* instinct: every one of D64..D71 lives at the boundary between a *subcommand handler* that has already set `result.status = Err(…)` and an *output renderer* that swallows the error because it is templating a "success-shaped" report. The fix is a shared contract:

1. **A single `handle_output(cli_ctx, result) -> ExitCode`** enforces the rule `result.is_err() → exit code ≠ 0`.
2. **Every handler returns `Result<Report, UserError>`**. Renderers that want to display a failing `Report` do so under a `Display<ErrorReport>` impl that still bubbles the exit code up.
3. **A regression harness** — `examples/exit_code_audit_driver.rs` in the pmat repo — probes D64..D71 on every CI run and fails if any of them newly exits zero.

That last item is load-bearing. Chapter 67 Lesson 3 put it bluntly: *a quality-gate that cannot fail is a quality-gate that cannot gate*. If the regression harness is skipped, the class regresses silently; we have the five-round proof.

### Pull Requests and KAIZEN Linkage

R6 opened `KAIZEN-0053` (exit-code correctness harness) and `KAIZEN-0054` (cuda-tdg path-validation). R7's contribution is to tighten both tickets with the D64..D71 numbered probes. The harness lives in the PMAT source tree at `examples/exit_code_audit_driver.rs` and is reproducible by any consumer of pmat — see §68.5.

## 68.2 Pattern Two — Hostile Hook Class (D62)

D62 is a small defect by count (one line in one hook file) but a large defect by blast radius. The pre-commit file `.git/hooks/pre-commit-branch-enforcer` in v3.14.0 contained a self-destructive side-effect:

- If the current branch was not on an allowlist, it would print a warning **and then move the failing hook file out of the way**.
- On next invocation the hook was simply gone.
- Once gone, the gate it enforced (branch naming) was disabled until a human noticed.

The class is *hostile*: a pre-commit that mutates its own enabling infrastructure is indistinguishable, from the outside, from a corrupt install. Worse, the same file name recurs across agent worktrees (`pre-commit-branch-enforcer.disabled-r6`, `.disabled-r7`, `.disabled-r8`, …) — a trail of evidence that every agent that touched the repo had to first disable the hook to get work done, which is precisely the signal a brittle hook is supposed to surface.

### The Remediation Pattern

1. **Pre-commit hooks must be read-only with respect to the hook tree itself.** The hook reports `exit 0` if the check passes, `exit 1` with a human message if it fails, and *nothing else*. It never `mv`s, never `rm`s, never `chmod`s.
2. **Enforcement lives in a separate place** from the pre-commit binary. If the branch-enforcer needs to quarantine a hook, it does so via an out-of-band tool (`pmat hooks disable`), never from inside the hook itself.
3. **Hook self-integrity test**: each pre-commit check should begin with a SHA-256 check of its own file; if the hash differs from a checked-in manifest (`.pmat/hooks.sha256`), the hook fails loudly and refuses to take further action. This makes tampering observable.

### Observable Failure Signal

The easiest way to spot this pattern during dogfooding is the *disabled-rN* file trail in `.git/hooks/`. If `.git/hooks/pre-commit-branch-enforcer.disabled-*` exists for more than one round, the hook is hostile — no healthy hook gets disabled N times by N different agents for no reason.

Tracked as `KAIZEN-0055` (hook non-hostility contract) and `KAIZEN-0056` (SHA manifest).

## 68.3 Pattern Three — Comply-Check Profile (D10 / D54)

Chapter 67 §Lesson 1 argued that an O(1) contract is only O(1) if it is measured. R7 closed the loop by *profiling* the offender — `pmat comply check` — which R2 measured at 51.39 s / 1.44 GB and R5 measured at 52.06 s / 1.44 GB, an 11 % regression-to-noise ratio across nine commits' worth of intervening work.

### The Profile

R7 instrumented the call with `perf record` + `/usr/bin/time -v` + a lightweight `rusage` capture. The headline findings:

- **35 `walkdir::WalkDir` invocations** across the `comply` crate, every one of them a fresh descent of the project tree.
- **168 `std::fs::read_to_string` sites** on source files — many of them re-reading the same file in different checks.
- **No per-check instrumentation**: the `Timer` helper in `comply/src/profile.rs` exists but is called in exactly two places. The 9 compliance checks share one outer timer and never report which of them owns which second.
- **Peak RSS 1.44 GB**, of which roughly 0.9 GB is from a single `serde_json::Value` graph materialised once per check — i.e. the same JSON is deserialised up to 9 times per run.

### The Remediation Pattern

The fix is the subject of §68.5 (CB-1800 patch-sketch), but as a pattern:

1. **Share the WalkDir.** Any check that needs `Vec<PathBuf>` for the project tree reads from a single `Arc<ProjectSnapshot>` computed once per `pmat comply check` invocation.
2. **Share file contents.** A `FileCorpus` wrapper memoises `read_to_string` on a path-keyed LRU; 168 reads collapse to at most *N-unique-paths* reads.
3. **Per-check Timer.** Wrap each check in `Timer::named("cb-081")` / `Timer::named("cb-130")` / etc. so `pmat comply check --profile` reports a flame-graph-ready JSON blob.
4. **Drop the contract-lie.** Until these three changes land, stop calling `comply check` "O(1)" anywhere in docs or hook messages. The 52-second reality is the contract; the prose caught up to the reality is the fix.

Tracked as `KAIZEN-0057` (ProjectSnapshot), `KAIZEN-0058` (FileCorpus LRU), `KAIZEN-0059` (per-check Timer).

## 68.4 Pattern Four — Cross-Reference to R6 arxiv Kaizen (KAIZEN-0053..0061)

R6 published a smaller arxiv-driven research round (KAIZEN-0045..0052 appear in [Chapter 66](ch66-00-kaizen-roadmap.md)) and R7 extends it with the following defect-driven tickets. These are *not* arxiv-derived; they are the remediation backbone for the defect patterns above, filed so the backlog and the dogfood trail reconcile:

| Ticket | Title | Source |
|---|---|---|
| KAIZEN-0053 | Exit-code audit harness (D16/D25/D26/D35/D57/D64..D71) | R5 + R7 |
| KAIZEN-0054 | `cuda-tdg score` path-validation gate | R7 D64 |
| KAIZEN-0055 | Pre-commit non-hostility contract | R7 D62 |
| KAIZEN-0056 | `.pmat/hooks.sha256` manifest + self-integrity check | R7 D62 |
| KAIZEN-0057 | `ProjectSnapshot` shared walker | R7 D10 |
| KAIZEN-0058 | `FileCorpus` LRU for repeated reads | R7 D10 |
| KAIZEN-0059 | Per-check `Timer::named` instrumentation | R7 D10/D54 |
| KAIZEN-0060 | MCP tool-name agreement test (D39/D47/D48/D52) | R4/R5 |
| KAIZEN-0061 | Hook timing probe example (O(1) budget check) | R7 |

KAIZEN-0060 and KAIZEN-0061 ship *with* a test harness, not just as a ticket. The examples `examples/mcp_timing_bench.rs`, `examples/o1_hook_probe.rs`, and `examples/exit_code_audit_driver.rs` in the pmat source tree are the executable versions of KAIZEN-0061, KAIZEN-0061, and KAIZEN-0053 respectively — which closes the Toyota-Way loop: *every remediation ticket has a harness that will fail if the remediation regresses*.

Cross-reference to R6 arxiv kaizen (KAIZEN-0045..0052, Chapter 66) is maintained by title-prefix convention: KAIZEN-0053+ are R7-originated and defect-driven; KAIZEN-0045..0052 are R6-originated and research-driven. Both streams converge on the same execution plan laid out in §Chapter 66 *Execution Plan*.

## 68.5 Patch Sketch — CB-1800 Shared-File-Analysis Algebra

CB-1800 is the R7 compliance-brick that unifies the three D10-family remediations (KAIZEN-0057/58/59) into a single algebraic contract. The point of CB-1800 is to make the statement *"this check reads file X"* a first-class, cacheable, measurable operation. Everything else — per-check timing, snapshot sharing, corpus memoisation — falls out as a free consequence.

### The Data Types

```rust
/// A single, canonical snapshot of the project tree, taken once per
/// `pmat comply check` invocation. Shared across all 9 checks.
pub struct ProjectSnapshot {
    root: PathBuf,
    files: Arc<[PathBuf]>,         // one WalkDir, produced lazily
    sha: SnapshotSha,              // hashed for cache keying
}

/// Content-addressed corpus of file contents. Collapses the 168
/// `read_to_string` sites down to at most (# unique files) reads.
pub struct FileCorpus {
    inner: Arc<RwLock<LruCache<PathBuf, Arc<str>>>>,
    stats: Arc<FileCorpusStats>,   // hits, misses, byte counts
}

/// A named timer. One instance per compliance check, so the flame graph
/// is per-check, not per-run.
pub struct NamedTimer {
    check_id: &'static str,         // e.g. "cb-081", "cb-130"
    start: Instant,
}

/// The shared context every compliance check receives.
pub struct ComplyCtx<'a> {
    pub snapshot: &'a ProjectSnapshot,
    pub corpus:   &'a FileCorpus,
    pub timer:    NamedTimer,
}
```

### The Algebra

Each check goes from:

```rust
// v3.14.0 — O(N*M) where N=files, M=checks
fn cb_081_dependency_health(root: &Path) -> CheckResult {
    let files = WalkDir::new(root).into_iter().collect::<Vec<_>>(); // walk #1
    let cargo_toml = std::fs::read_to_string(root.join("Cargo.toml"))?; // read #1
    // …
}

fn cb_130_agent_context(root: &Path) -> CheckResult {
    let files = WalkDir::new(root).into_iter().collect::<Vec<_>>(); // walk #2
    let claude_md = std::fs::read_to_string(root.join("CLAUDE.md"))?; // read #2
    // …
}
```

to:

```rust
// CB-1800 — single walk, cached reads, per-check timer
fn cb_081_dependency_health(ctx: &ComplyCtx<'_>) -> CheckResult {
    let _timer = ctx.timer.clone(); // auto-reports on drop
    let cargo_toml = ctx.corpus.get(&ctx.snapshot.root.join("Cargo.toml"))?;
    // …
}

fn cb_130_agent_context(ctx: &ComplyCtx<'_>) -> CheckResult {
    let _timer = ctx.timer.clone();
    let claude_md = ctx.corpus.get(&ctx.snapshot.root.join("CLAUDE.md"))?;
    // …
}
```

The algebraic laws CB-1800 enforces:

1. **Walk uniqueness.** For a given `comply check` run, `ProjectSnapshot::files` is computed at most once. A reader that wants a path list *must* request it from the snapshot.
2. **Read memoisation.** `FileCorpus::get(path)` is `O(1)` after the first call per unique path; the invariant is `forall p, calls(p) ≤ 1 for disk read, ≥ 1 for cache hit`.
3. **Timer ownership.** Each check owns exactly one `NamedTimer`. The timer drops when the check returns, emitting a `{ check_id, elapsed_us }` record into a per-run `Vec<TimerRecord>` that `pmat comply check --profile` renders as JSON.

### Expected Impact

A back-of-envelope estimate using the R7 profile:

- 35 WalkDirs → 1 WalkDir: ~25× reduction in directory-traversal work.
- 168 `read_to_string` → ~20 unique reads (the 168 were 9 checks × ~20 common files): ~8× reduction in I/O.
- Per-check Timer = O(1) additional overhead, measurable gain in developer productivity.
- Projected wall-clock: **52 s → <5 s**, projected RSS **1.44 GB → <200 MB**.

When CB-1800 lands, the O(1) contract (<100 ms) on hook-path is still violated — 5 s is not 100 ms — but the 10× gap is attackable by pipelining checks and lazy-loading the JSON deserialisation. **52 s is not attackable without this refactor first.** CB-1800 is therefore a prerequisite, not a victory lap.

Tracked as work item **CB-1800** (component-brick, component 32) and planned for the v3.15.x series. The companion book section will move from this patch-sketch into a worked-example chapter once the first half of CB-1800 lands.

## 68.6 How to Reproduce R7

You can run the R7 remediation suite against your own checkout:

```bash
# 1. Rebuild — no stale binaries
cd /path/to/paiml-mcp-agent-toolkit
cargo install --path .

# 2. D64..D71 exit-code audit (Pattern One)
cargo run --example exit_code_audit_driver
#    expect: 8/8 probes exit non-zero on error
#    observed (v3.14.0): 0/8 — all eight exit zero

# 3. Hook hostility detector (Pattern Two)
ls .git/hooks/pre-commit-branch-enforcer.disabled-* 2>&1
#    expect: No such file or directory
#    observed: files for r6, r7, r8, ... (trail of forced disables)

# 4. Comply-check profile (Pattern Three)
/usr/bin/time -v pmat comply check 2>&1 | grep -E "(Elapsed|Maximum resident)"
#    expect: <100 ms, <50 MB (per declared O(1) contract)
#    observed: ~52 s, ~1.44 GB — violates by 500× / 30×

# 5. MCP tool name / schema audit (Pattern Four)
cargo run --example mcp_timing_bench
#    verify tools/list returns non-empty inputSchema for every tool
#    observed (v3.14.0): every tool returns inputSchema.properties: {} (R7 D14/D32)

# 6. O(1) hook-path probe
cargo run --example o1_hook_probe
#    expect: 6/6 probes within 100 ms budget
#    observed: all 6 pass for v3.14.0 — keep the gate honest
```

## 68.7 Closing — The Discipline of Remediation

R1–R5 produced a defect catalogue. R7 is the first round that asked *how does a defect turn into a pattern?* and the answer is: when you can write a regression harness for it. Of the four pattern groups in this chapter, three ship with a harness (§68.1 via `exit_code_audit_driver`, §68.3 via `mcp_timing_bench`, §68.6 as the test plan for `o1_hook_probe`). §68.2 is still on manual probe (the `.disabled-*` trail) — which is a gap.

The closing rule from Chapter 67 holds with an addendum from R7:

> If you cannot reproduce a defect, it is not a defect. If you cannot gate a defect, it will regress. If the tool cannot pass its own rubric, the rubric is the defect. **If a remediation has no harness, the remediation is a promise — and promises regress.**

Cross-references:

- [Chapter 67 — Dogfooding pmat](ch67-00-dogfooding.md) (D1..D58)
- [Chapter 66 — Kaizen Roadmap R4](ch66-00-kaizen-roadmap.md) (KAIZEN-0017..0044)
- GitHub issues [#342](https://github.com/paiml/paiml-mcp-agent-toolkit/issues/342) (R7 defects), [#337](https://github.com/paiml/paiml-mcp-agent-toolkit/issues/337) (KAIZEN roadmap), [#343](https://github.com/paiml/paiml-mcp-agent-toolkit/issues/343) (CB-1800 tracking)
- Source examples: `examples/exit_code_audit_driver.rs`, `examples/mcp_timing_bench.rs`, `examples/o1_hook_probe.rs` in the pmat source tree
