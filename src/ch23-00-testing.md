# Chapter 23: Performance Testing Suite

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ Verified against pmat 3.32.0

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 12 | Executed against pmat 3.32.0; output pasted verbatim |
| ⚠️ Not Implemented | 0 | — |
| ❌ Broken | 0 | — |
| 📋 Planned | 0 | — |

*Last updated: 2026-08-25*
*PMAT version: pmat 3.32.0*
<!-- DOC_STATUS_END -->

> **What changed in this rewrite.** `pmat test` is real and its six suites are
> real, but the 2025 edition mistook what it tests and invented every option it
> passed. Two corrections, and they matter in that order:
>
> - **`pmat test` benchmarks `pmat` itself, not your project.** It generates a
>   synthetic source file under `/tmp`, runs pmat's own analyser over it, and
>   compares the result against the fixed targets in pmat's SPECIFICATION.md
>   Section 30 — 389,600 LOC/s single-threaded throughput, a 10,240 KB memory
>   budget for 20K LOC. It is a self-check on the binary you installed. Nothing
>   it reports is a measurement of your code, and it produces the same numbers
>   whatever directory you run it in.
> - **Twenty-one documented flags do not exist**: `--baseline`, `--name`,
>   `--compare-baseline`, `--seed`, `--cases`, `--track-allocations`,
>   `--max-heap`, `--detect-leaks`, `--valgrind`, `--rps`, `--duration`,
>   `--concurrent`, `--ramp-up`, `--sustained`, `--ramp-down`, `--threshold`,
>   `--history`, `--trend-report`, `--scenario`, `--full-stack`, `--profile`,
>   `--flame-graph`, `--cpu-profile`. Every one exits 2 with "unexpected
>   argument found". There is no baseline store, no seed control, no leak
>   detector, no load generator and no profiler in this command. Those sections
>   are gone.
>
> The real option list is nine flags, all documented below.

## What `pmat test` Is

`pmat test [SUITE]` runs one of six built-in self-tests against the installed
`pmat` binary:

| Suite | What it measures |
|-------|------------------|
| `performance` (default) | Analyser throughput against the spec target |
| `throughput` | Single-threaded LOC/s |
| `memory` | Peak RSS growth analysing 20K LOC |
| `regression` | Run-to-run consistency across `--iterations` runs |
| `property` | Property-based checks over pmat's own invariants |
| `integration` | Component interaction checks |
| `all` | Every suite |

Use it to answer "is this `pmat` build performing as specified on this machine?"
To test *your* project, use `cargo test`, and see the `--record` section below
for feeding those results back to pmat.

## Running a Suite

```bash
pmat test performance
```

The run prints the analyser's JSON output for the synthetic file it generated,
then the verdict. On the machine this chapter was written on:

```
Starting Performance Testing Suite (SPECIFICATION.md Section 30)
Suite: Performance, Iterations: 3, Timeout: 300s
🏃 Running PMAT Performance Test Suite (SPECIFICATION.md Section 30)
================================================================

📊 Throughput Tests:
⏰ Analysis timeout set to 60 seconds
🔍 Analyzing complexity of file: /tmp/.tmpglhwxz/test.rs
✅ Successfully analyzed 1 file(s)
...
❌ Single-threaded throughput: 42857 LOC/s (target: ≥389600 LOC/s)
Error: Single-threaded throughput: 42857 LOC/s is below the required 389600 LOC/s
```

**Exit code 1.** Note the `/tmp/.tmpglhwxz/test.rs` path in the middle: that is
the file `pmat` wrote for itself. The current working directory is not consulted.

This is a genuine failure, not a misconfiguration — the target is a fixed number
in pmat's specification, and a general-purpose development machine under load
will not hit 389,600 LOC/s. Expect `performance`, `throughput` and `memory` to
fail outside a dedicated benchmark environment, and read the reported number
rather than the pass/fail bit.

### The other suites

```bash
pmat test throughput
```

```
❌ Single-threaded throughput: 44817 LOC/s (target: ≥389600 LOC/s)
Error: Single-threaded throughput: 44817 LOC/s is below the required 389600 LOC/s
```

Exit 1. Two runs of the same measurement gave 42,857 and 44,817 LOC/s — about
4.5% apart, which is the run-to-run noise you should expect from this suite.

```bash
pmat test memory
```

```
❌ Memory usage: peak grew 186620 KB for 20K LOC (budget: ≤10240 KB)
Error: Peak resident memory grew 186620 KB for 20K LOC, over the 10240 KB budget
```

Exit 1, and by a factor of eighteen. The budget is aspirational for the current
analyser.

```bash
pmat test regression
```

```
✅ Performance consistency: avg=74ms, min=66ms, max=98ms
Regression tests passed!
```

Exit 0. This is the suite most likely to be useful in CI: it does not compare
against an absolute target, only against pmat's own variance across
`--iterations` runs, so it is portable across machines.

```bash
pmat test integration
```

```
Starting Performance Testing Suite (SPECIFICATION.md Section 30)
Suite: Integration, Iterations: 3, Timeout: 300s
Running integration test suite...
This validates component interactions and system behavior
No separate integration test file found
Integration tests are embedded in unit tests
```

Exit 0. Note that it passes by reporting that it found nothing to run. Do not
read a green `integration` as evidence that integration tests executed.

```bash
pmat test property
```

```
Starting Performance Testing Suite (SPECIFICATION.md Section 30)
Suite: Property, Iterations: 3, Timeout: 300s
Running property-based test suite...
This validates code properties with generated test cases
Error: Property tests failed
```

Exit 1, with no detail about which property failed. `--verbose` adds tracing
output but not a property name.

```bash
pmat test all
```

Runs every suite in turn.

## The Real Options

```bash
pmat test performance --verbose
pmat test performance --timeout 300
pmat test regression --iterations 10
```

| Flag | Meaning |
|------|---------|
| `[SUITE]` | positional; `performance` (default), `property`, `integration`, `regression`, `memory`, `throughput`, `all` |
| `--iterations <N>` | Iterations for regression detection (default 3) |
| `--timeout <SECONDS>` | Test timeout (default 300) |
| `-o, --output <FILE>` | Write results to a file |
| `--memory` | Enable memory usage testing |
| `--throughput` | Enable throughput testing |
| `--regression` | Enable regression testing |
| `--perf` | Show detailed performance metrics |
| `--record` | Record cargo test results to `.pmat-metrics/` |
| `--from-stdin` | Parse cargo test output from stdin instead of running cargo test |
| `--dry-run` | Show what would be recorded without writing files |

`-o` writes **plain text**, not JSON, whatever you name the file:

```bash
pmat test integration -o results.json
```

```
Results written to: results.json
```

```
Performance Test Results
======================
Suite: Integration
Execution time: 18.528µs
Iterations: 3
Status: PASSED
```

## Recording Your Project's Test Results

This is the part of `pmat test` that does concern your code. `--record` captures
a `cargo test` run into `.pmat-metrics/` for pmat's EvoScore tracking.

Preview first:

```bash
cargo test --no-fail-fast 2>&1 | pmat test --record --from-stdin --dry-run
```

```
Dry run — would record:
  File: .pmat-metrics/commit-90a234c-tests.json
  Commit: 90a234c
  Passed: 2
  Failed: 0
  Ignored: 0
  Total: 2
  Timestamp: 2026-08-25T20:51:48.695801270+00:00
```

Then record:

```bash
cargo test --no-fail-fast 2>&1 | pmat test --record --from-stdin
```

```
Recorded: 2/2 pass (commit 90a234c)
```

```json
{
  "commit": "90a234c",
  "pass": 2,
  "total": 2,
  "failed": 0,
  "ignored": 0,
  "timestamp": "2026-08-25T20:51:48.705778336+00:00"
}
```

Without `--from-stdin`, `pmat test --record` runs `cargo test --no-fail-fast`
itself.

### It requires a commit

The record is keyed on the git SHA, so a repository with no commits fails:

```
Error: Failed to get git commit SHA
```

`git init` alone is not enough — commit first. Note also that `pmat` writes
`.pmat-metrics/.gitignore` alongside the record, so the metrics directory does
not pollute your history.

## Using It in CI

The portable check is `regression`, because it has no absolute target:

```yaml
- name: PMAT self-check
  run: pmat test regression --iterations 10

- name: Record test results
  run: cargo test --no-fail-fast 2>&1 | pmat test --record --from-stdin
```

Do not gate CI on `performance`, `throughput` or `memory` unless your runner is
a dedicated benchmark host — they compare against fixed spec targets and will
fail on shared runners, as shown above.

## Troubleshooting

### `Error: ... is below the required 389600 LOC/s`

Expected on a general-purpose machine. The target is a constant from pmat's
specification, not a threshold derived from your hardware, and there is no flag
to relax it. Read the measured number instead.

### `Error: Failed to get git commit SHA`

`--record` needs a commit, not just a `.git` directory.

### `error: unexpected argument found`

You passed one of the twenty-one flags listed in the banner at the top of this
chapter. `pmat test --help` fits on one screen and is the authority.

### `pmat test` reports nothing about my project

Correct — it benchmarks pmat. Use `cargo test` for your project, and
`--record --from-stdin` to feed the result back.

### `integration` passed but ran nothing

It prints `No separate integration test file found` and exits 0. A green result
here is not evidence that anything executed.

## Summary

`pmat test` is a self-diagnostic for the `pmat` binary plus a recorder for your
`cargo test` results. It is not a load generator, a profiler, a leak detector or
a baseline store, whatever the previous edition of this chapter claimed.

Key takeaways:
- Six suites, nine flags. `pmat test --help` is short; trust it.
- `performance`, `throughput` and `memory` compare against fixed spec targets
  and will fail on ordinary hardware — 42,857 LOC/s against a 389,600 target
  here, and 186,620 KB against a 10,240 KB budget.
- `regression` is the portable one: it measures variance, not an absolute.
- `--record --from-stdin` is the only part that touches your project's tests,
  and it needs a git commit.
- `-o` writes plain text regardless of the file extension.
