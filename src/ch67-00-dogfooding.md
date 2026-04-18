# Chapter 67: Dogfooding pmat — 58 Defects Found in 5 Rounds

Over a single day (2026-04-18), the pmat team ran five consecutive *dogfood rounds* against `pmat 3.14.0`, the same binary being prepared for release. Every CLI subcommand, every MCP tool, and the HTTP transport were exercised; wall-clock and RSS were recorded for each run; every broken behaviour became a numbered defect (D1..D58) and — in most cases — a GitHub issue. The result is a case study in how to dogfood a developer tool: what to probe, how to measure, and how to avoid flattering the tool under test. This chapter teaches that methodology using the 58 defects as worked examples.

The five rounds were filed in GitHub issues [#330](https://github.com/paiml/paiml-mcp-agent-toolkit/issues/330), [#333](https://github.com/paiml/paiml-mcp-agent-toolkit/issues/333), [#336](https://github.com/paiml/paiml-mcp-agent-toolkit/issues/336), [#339](https://github.com/paiml/paiml-mcp-agent-toolkit/issues/339), and a round-5 follow-up comment on #339. No new features were shipped between rounds; the defects are all latent in the same build.

## Why Dogfooding Matters (Toyota Way, Jidoka)

The Toyota Production System gives us two terms that frame this chapter: *jidoka* — "autonomation", or the authority of any worker on the line to stop production the moment a defect is seen — and *genchi genbutsu* — "go and see for yourself", the principle that you must inspect the real thing, not a proxy. Dogfooding is both. You run the product the way a real user runs it, and when the product misbehaves you do not paper over it, you file the defect and stop the line.

pmat in particular needs dogfooding because it claims to be a *quality* tool. Every capability — `quality-gate`, `rust-project-score`, `comply check`, `perfection-score`, `spec score`, `oracle status` — returns a verdict about someone else's code. If pmat's own defects silently corrupt those verdicts (returning exit 0 on error, mislabelling MCP tools, failing to meet its own O(1) contract), then every consumer of pmat is being lied to by the same bug. The credibility of the tool rests on its willingness to be judged by its own rubric.

### The Five-Round Process

Each round followed the same recipe:

1. **Rebuild from source.** `cd /home/noah/src/paiml-mcp-agent-toolkit && cargo install --path .` — no stale binaries.
2. **Probe the surface.** Every subcommand visible in `pmat --help`, every MCP tool returned by `tools/list`, and the `--transport http` mode. No cherry-picking.
3. **Measure, don't guess.** Wall-clock and RSS captured for every invocation with `/usr/bin/time -v`. Commands that should be O(1) (<1s, <30MB) were compared against their budget.
4. **File on sight.** The moment a defect was reproducible, it got a D-number and, in most cases, a GitHub issue.
5. **Never trust a prior pass.** Every round re-ran the headline regressions from previous rounds. `pmat comply check` was re-benchmarked in R5 exactly as in R2; the numbers had not moved.

This chapter catalogs what that process found.

## Defect Taxonomy

Across 58 defects the failures clustered into six families. For each we cite a single representative D-number; the full list appears in the round-by-round sections.

### 1. Contract / O(1) Regression — D10, D54

pmat's pre-commit workflow asserts that `pmat comply check` is **O(1)** and must complete in under 30ms. The round 2 benchmark measured it at **51.39 s** wall-clock and **1.44 GB** peak RSS — a 1,700× miss against the declared contract. Round 5 re-ran the same command against the same master branch: **52.06 s / 1.44 GB**. Not fixed; the contract is a lie a developer reads at every commit.

This is the defect class that most threatens dogfooding discipline. O(1) contracts are only contracts if they are measured. Declaring them in prose while the actual code allocates 1.4 GB is not an O(1) promise, it is a marketing claim.

### 2. MCP Schema / Behaviour — D14, D32, D37, D47, D48, D52

Three subpatterns, all in pmat's MCP server:

- **Empty `inputSchema.properties`** for every one of the 16 tools exposed on `tools/list` (D14, confirmed D32). A conforming MCP client has nothing to bind to; Claude Code cannot auto-call any pmat tool. This is not a missing feature, it is a protocol violation.
- **Missing advertised tools.** `CLAUDE.md` promises `pmat_query_code`, `pmat_get_function`, `pmat_find_similar`, `pmat_index_stats` (D15). None appear on the wire.
- **Tool names lie.** `analyze_big_o` returns coupling metrics; `analyze_deep_context` returns churn; `analyze_dag` returns a lint-hotspot list (D39/D47/D48, summarised in D52). Three of sixteen tools are mislabelled — and the unit test in `simple_unified_server.rs:337-342` *asserts* the misnaming. The test locks in the defect.

### 3. Exit-Code Correctness — D16, D25, D26, D35, D57

A user who types `pmat split` with no argument sees a red ERROR line — and then a shell that believes the command succeeded. Exit code is 0. The same pattern appears in `pmat spec validate` (D16), `pmat predict-quality` (D26), `pmat roadmap list` (D57), `pmat cache inspect` (D57), and `pmat score --quick` (D57). A shared error-handling helper is returning `Ok(())` where it should return `Err`. **Every CI gate that tests exit code silently passes against these commands.** A quality-gate that cannot fail is a quality-gate that cannot gate.

### 4. Help-Leak on Subcommand Errors — D11, D29, D30, D31, D53

`pmat hooks list`, `pmat tdg . --format summary`, `pmat roadmap` (no sub), `pmat fix` (no-arg), `pmat comply check --format summary`: each prints the main `pmat` help block when the actual error belongs to the subcommand. The reader gets exit code 2, the wrong help, and no hint that the subcommand was even recognised. Clap dispatch is collapsing to the root parser instead of the scoped one.

### 5. Feature-Gate Footgun — D27, D55

`pmat agent start` / `pmat agent status` fail with *"Agent daemon feature not enabled. Build with --features agent-daemon"* and exit 1. The subcommand is in the shipped CLI surface. Users have no way to satisfy the gate — the published binary did not enable it. A feature gate that is a runtime error instead of a compile-time exclusion is a UX trap.

### 6. Self-Validation Paradox — D5, D17, D19, D58

`pmat spec score docs/specifications/components/provable-contracts.md` returns **47/100** against a 95-point threshold. The file is a pmat spec, written by pmat developers, intended to be graded by pmat's rubric. None of the 35 tracked specs pass (D5); a real, well-formed pmat spec scores below half (D17). Meanwhile `pmat rust-project-score` flags **487 unwrap()** calls in pmat's own production source (D19) — a self-declared Cloudflare-class defect against pmat's own rule.

Either the rubric is miscalibrated, or the tool fails its own rubric. Both are bugs. The one thing pmat cannot be is silent.

## Round-by-Round Narrative

### Round 1 — Baseline

Round 1 (not reproduced in full here) established the bench: `pmat --version`, the help tree, and the fast O(1)-class commands (`pmat work list`, `pmat cache stats`, `pmat show-metrics`) all pass in under 30 ms at under 20 MB RSS. Two defects surfaced but were left open for re-test: D1 (`pmat analyze symbol-table` reports 0 symbols on a 20k-function codebase) and D2 (`pmat work list` shows PMAT-620..624 stuck `inprogress` after the underlying PRs merged). Round 1 was filed as part of the lead-up to issue [#330](https://github.com/paiml/paiml-mcp-agent-toolkit/issues/330).

### Round 2 — Aggregation Math, Rubric Calibration (D4–D9)

Round 2 attacked the composite scoring commands. The headline was **D4**: `pmat perfection-score --breakdown` reports "200.0/200.0 A+" overall, but the per-category breakdown shows "Rust Project Quality 54.9/30.0 (F)" — *earned exceeds max* AND is graded F. Sum of capped categories is 185.3, not 200.0. The aggregation is inconsistent with itself. **D5** reported 0/35 specs passing against the 95-point threshold; **D8** found `pmat oracle status` reporting all metrics at 0.0 on a repo that had just scored A-. **D9** showed `pmat explain rust-project-score` returning *"No checks matching 'rust-project-score'"* — the tool cannot explain its own primary score. Filed in issue [#330](https://github.com/paiml/paiml-mcp-agent-toolkit/issues/330).

### Round 2 Session 2 — O(1) Regression, MCP Protocol Violation, HTTP Stub (D10–D20)

Session 2 ran the full CLI bench plus the first MCP probes. **D10** (`pmat comply check`: 51.39 s / 1.44 GB vs a <30 ms O(1) contract) became the headline of the day. **D13** revealed that `pmat serve --transport http` announces "Server ready!" but does not bind the port — the HTTP transport is a stub in v3.14.0. **D14** showed every MCP tool returning `{"type":"object","properties":{}}` for `inputSchema` — protocol-level undiscoverability. **D15** showed `CLAUDE.md` promising four `pmat_*` MCP tools that are not exposed on the wire. **D16** introduced the exit-0-on-error pattern (`pmat spec validate` with no arg). **D18** caught `pmat analyze dead-code` recursing into 107 agent worktrees, multiplying its workload by ~100×. **D19** and **D20** counted 487 `unwrap()` calls and 21,015 quality-gate violations in pmat's own source. Filed in issue [#333](https://github.com/paiml/paiml-mcp-agent-toolkit/issues/333).

### Round 3 — Hanging Subcommands, Help-Leak Pattern, MCP Schema Confirmed (D21–D36)

Round 3 probed the long-running commands and the help surface. **D21** (`pmat quality-gates`) and **D22** (`pmat kaizen`) both hung past 30 s with no progress output, no cancellation. **D23** (`pmat ci-local`) allocated 225 MB in 15 s before being killed. **D25** and **D26** extended the exit-0-on-error pattern to `pmat split` and `pmat predict-quality`. **D27** caught the `pmat agent start` feature-gate footgun. **D29–D31** catalogued help-leak: `pmat tdg . --format summary`, `pmat roadmap`, `pmat fix` — all exit 2 with the main pmat help instead of a scoped error. **D32** confirmed D14's empty-schema defect on a second binary build, and **D33** showed the cost to a caller: invoking `analyze_complexity {"path":"."}` returns a `-32603` error saying the required field is `paths` — plural, undocumented in the schema. **D34** noted the MCP server never exits cleanly. **D35** elevated the exit-0-on-error pattern to a systemic defect. Filed in issue [#336](https://github.com/paiml/paiml-mcp-agent-toolkit/issues/336).

### Round 4 — MCP Tool-Behaviour Defects (D37–D45)

Round 4 focused entirely on MCP tool behaviour. **D39** found that `analyze_big_o` returns coupling-analysis output — the tool name and the response disagree. **D37/D38/D40-D45** catalogued silent zeroes (tools returning `{"score":0}` instead of errors), missing `shutdown` method, and the fact that several tools lack any authoritative documentation of their actual behaviour vs their advertised name. Filed in issue [#339](https://github.com/paiml/paiml-mcp-agent-toolkit/issues/339).

### Round 5 — Regression Watch + Tool-Name-Lies Confirmed (D46–D58)

Round 5 re-benchmarked the headline regressions (did R2 actually get fixed?) and finished the MCP probe. **D46** showed `pdmt_deterministic_todos` requiring a plural-array `requirements` field that the empty schema hides. **D47** (`analyze_deep_context` actually returns churn analysis) and **D48** (`analyze_dag` actually returns lint-hotspot output) joined **D39** to form the "tool names lie" pattern, catalogued as **D52**. The unit test `simple_unified_server.rs:337-342` asserts the misnaming — the defect is codified in the test suite. **D49** showed the MCP path also recursing into 5 agent worktree copies of the same file (D18 regression). **D51** found that `refactor.nextIteration` / `refactor.stop` return `-32603` (internal error) when they should return `-32602` (invalid params); wrong JSON-RPC error class. **D54** re-ran `pmat comply check` on master: 52.06 s / 1.44 GB. D10 unchanged in 9 rounds of commits. **D55** re-confirmed the agent-daemon feature-gate footgun. **D57** re-confirmed exit-0-on-error across `pmat roadmap list`, `pmat cache inspect`, and `pmat score --quick`. Filed as a follow-up comment on issue [#339](https://github.com/paiml/paiml-mcp-agent-toolkit/issues/339).

## Lessons Learned

### Lesson 1 — Verify O(1) claims empirically, every build

An O(1) contract is only O(1) if a test harness runs the command and fails when the wall-clock exceeds the budget. D10 / D54 demonstrate the cost of trusting a prose contract: two rounds, nine commits, the same 51-second miss. The fix is not just to speed up `comply check` — it is to add a benchmark to CI that fails the build when `comply check` exceeds 100 ms. Without the gate, any optimisation is reversible, silently.

### Lesson 2 — MCP tool names, schemas, and handlers must be tested for agreement

D14, D32, D33, D39, D47, D48, and D52 all stem from one missing test class: *does the MCP tool named X actually invoke handler X, with the documented schema?* The fact that `simple_unified_server.rs:337-342` asserts the misnaming — `AnalyzeDagTool.type_name().contains("LintHotspotTool")` — is a cautionary tale. A test that encodes a defect perpetuates it. The correct test asserts the *intended* wiring and fails loudly when the wiring drifts.

CI should round-trip every MCP tool: `tools/list` → pick a tool → assert `inputSchema.properties` is non-empty → call the tool with a minimal valid payload → assert the response corresponds to the tool's documented purpose. Any tool that fails any of these steps is a defect on sight.

### Lesson 3 — Exit code 0 on user-facing error is a systemic bug

D16, D25, D26, D35, D57 are all the same bug viewed from five angles. A shared helper somewhere in `pmat`'s CLI returns `Ok(())` where it should return `Err`. The reason this is systemic rather than cosmetic: CI pipelines all over the world have `pmat quality-gate || exit 1`, `pmat spec validate $SPEC || exit 1`, `pmat score --quick || exit 1` in their shell scripts. Every one of those gates is currently a no-op against these five commands. The test is simple: `pmat <subcmd>` with no arg or with a deliberately invalid arg must exit non-zero. A regression suite that runs this check once per subcommand, once per release, would have caught the entire class.

### Lesson 4 — The Dogfood Paradox: the tool must pass its own rubric

D5, D17, D19, and D58 expose what we call the *dogfood paradox*. When `pmat spec score` graded a well-formed pmat specification at 47/100, there are exactly two possibilities: either the spec is bad (unlikely — it shipped and describes a feature in use) or the rubric is miscalibrated. The only wrong answer is to ignore the contradiction. The rule we adopted: if pmat's own source cannot pass pmat's own quality gates, then the gates do not ship to users. Either the source is fixed or the gates are recalibrated; there is no third option.

The rubric for `pmat rust-project-score` flagged 487 `unwrap()` calls as Cloudflare-class. The response is not to lower the threshold — it is to either fix the unwraps or document each one with `.expect("why this is safe")`. The tool teaches by example, or it teaches that the example does not apply to itself.

### Lesson 5 — Re-benchmark every round, never trust "already fixed"

R5 re-ran `pmat comply check` exactly as R2 had, and caught the regression that had silently survived 9 commits' worth of work between rounds. Any dogfood round that only tests new defects is flattering to the tool — it assumes the old ones stayed fixed. They do not, not automatically. Every round must re-run every headline regression. If the number moves, celebrate. If it does not, file again.

## How to Reproduce

You can run this entire dogfood against your own checkout of pmat:

```bash
# 1. Rebuild from source — no stale binaries
cd /path/to/paiml-mcp-agent-toolkit
cargo install --path .

# 2. Verify the binary you just built
pmat --version   # expect: pmat 3.14.0 (or your branch)

# 3. Headline regressions (R2 + R5 bench)
/usr/bin/time -v pmat comply check --format text 2>&1 | tail -5
#    expect per D10/D54: ~52s wall, ~1.4 GB RSS — FAIL vs <30ms O(1) budget

# 4. Exit-code probe (D16/D25/D26/D35/D57)
pmat split; echo "exit=$?"                # expect non-zero; observed: 0
pmat spec validate; echo "exit=$?"         # expect non-zero; observed: 0
pmat predict-quality; echo "exit=$?"       # expect non-zero; observed: 0

# 5. Help-leak probe (D11/D29/D30/D31/D53)
pmat hooks list; echo "exit=$?"            # expect scoped help; observed: main pmat help, exit 2
pmat roadmap; echo "exit=$?"               # same

# 6. MCP protocol probe (D14/D32/D33/D39/D47/D48/D52)
#    Note: `pmat --mode mcp` is broken (D12/D36) — use stdin-detect instead.
printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' \
  | timeout 5 pmat 2>/dev/null | tail -5
#    inspect returned inputSchema: expected non-empty properties; observed: {}

# 7. HTTP stub probe (D13)
pmat serve --transport http --port 9876 &
sleep 2; curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:9876/
#    expect 200; observed: 000 (port not bound)
kill %1 2>/dev/null

# 8. Self-validation paradox (D5/D17/D19)
pmat spec score docs/specifications/components/provable-contracts.md
#    expect >=95/100 (PASS); observed: 47/100 (FAIL)
pmat rust-project-score 2>&1 | grep -i unwrap
#    expect 0 critical unwraps; observed: 487 unwrap() calls flagged
```

If any of these commands misbehaves in the way described, the defect is open. If any has been fixed, file that fact — dogfooding is a two-way contract.

## Closing

Fifty-eight defects in one day against a released binary is not a disaster, it is the normal state of a quality tool that has never been systematically dogfooded. Toyota would say the tool is broken but honest: every defect has a D-number, an owner, and a trace to a commit. Jidoka does not stop the defect from happening; it stops the defect from being invisible. The value of a five-round dogfood is that every defect now has a place to live and a gate that will fail the next time it regresses.

The pmat team's rule, written on the whiteboard after R5:

> **If you cannot reproduce a defect, it is not a defect. If you cannot gate a defect, it will regress. If the tool cannot pass its own rubric, the rubric is the defect.**
