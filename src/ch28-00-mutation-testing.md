# Chapter 28: Mutation Testing

> **⚠️ Superseded, as of pmat 3.32.0 (2026-08-25). The `mutate` subcommand is
> not in the binary `cargo install pmat` builds.**
>
> Unlike some other chapters in this part of the book, this one documented
> something that was genuinely real. `pmat mutate` shipped in **2.174.0**
> (2025-10-27), gained colour-coded output and `--failures-only` in **2.175.0**,
> and gained a `--use-cargo-mutants` backend in **2.181.0**. The flags this
> chapter listed were correct.
>
> What happened is a build change, not a deletion:
>
> - **2.200.0** — the subcommand was put behind a Cargo feature
>   (`#[cfg(feature = "mutation-testing")]`), which at that point was still on
>   by default.
> - **2.205.0** — "Phase 2 Build Performance — 50% faster with minimal
>   defaults" cut the default feature set down to `core-languages`, and
>   `mutation-testing` was not in it. From that release onward, the binary a
>   normal install produces has no `mutate` subcommand at all. It is not listed
>   in `pmat --help`, and invoking it prints `error: unrecognized subcommand`.
>   In 3.32.0 the default set is
>   `["core-languages", "viz", "http-client", "standard-deps", "mcp-http"]`.
>
> The source is still there and still gated, so the flags below remain accurate
> *for a build that enables the feature*. This book cannot verify such a build
> and does not present one as working.
>
> There is a second reason not to reach for it even if you build it. pmat's own
> CHANGELOG for 3.32.0 records that `pmat mutate` and the `mutants` CI job
> **have never reported a caught-or-missed count** — the `min_mutation_score_pct
> = 80.0` in its `.pmat-metrics.toml` "names a quantity nobody has ever
> measured", and both `continue-on-error` flags are still set. A mutation score
> that has never been observed is not a gate.
>
> **If you want mutation testing today, use `cargo mutants`**, which is the tool
> pmat's own `--use-cargo-mutants` flag delegated to. It is documented below,
> with output captured from a real run. Everything else in this chapter is
> historical record.

## What Mutation Testing Answers

Mutation testing answers "**who tests the tests?**".

Coverage tells you which lines executed. It cannot tell you whether anything
*checked* the result. A test that calls a function and asserts nothing gives
you 100% line coverage of that function and catches no bug in it, ever.

Mutation testing closes that gap by deliberately breaking the code and seeing
whether the suite notices:

1. **Create mutants** — small, deliberate bugs (`+` becomes `-`, a return value
   becomes `0`).
2. **Run the tests** against each mutant.
3. **Score**: a mutant the tests failed on is **caught**; one they passed on is
   **missed**, and is a hole in the suite.

## Doing It Today: `cargo mutants`

```bash
cargo install cargo-mutants
```

### A Fixture With a Hole In It

```bash
mkdir -p mut2/src && cd mut2
cat > Cargo.toml << 'EOF'
[package]
name = "mut2"
version = "0.1.0"
edition = "2021"
EOF
cat > src/lib.rs << 'EOF'
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_add_runs() {
        add(1, 2);
    }
}
EOF
git init -q . && git add -A && git commit -qm init
```

`cargo llvm-cov` would report this crate as fully covered. `cargo mutants`
disagrees:

```bash
cargo mutants --no-times
```

```
Found 5 mutants to test
ok       Unmutated baseline
MISSED   src/lib.rs:2:5: replace add -> i32 with 0
MISSED   src/lib.rs:2:5: replace add -> i32 with 1
MISSED   src/lib.rs:2:5: replace add -> i32 with -1
MISSED   src/lib.rs:2:7: replace + with - in add
MISSED   src/lib.rs:2:7: replace + with * in add
5 mutants tested: 5 missed
```

Every mutant survived. The exit code is **2**.

Add one real assertion —

```rust
#[test]
fn test_add_correct() {
    assert_eq!(add(1, 2), 3);
}
```

— and the same command reports:

```
Found 5 mutants to test
ok       Unmutated baseline
5 mutants tested: 5 caught
```

with exit code **0**. That difference is the whole value of the technique, and
it is invisible to coverage: both versions of the crate execute the same lines.

### Flags Worth Knowing

| Flag | Effect |
|------|--------|
| `-f, --file <GLOB>` | restrict mutation to matching files |
| `-D, --in-diff <FILE>` | mutate only lines in a diff — the practical CI mode |
| `-j, --jobs <N>` | parallel workers |
| `-t, --timeout <SECS>` | per-mutant timeout |
| `--shard <K/N>` | split the run across CI machines |
| `--json` | machine-readable output |
| `--no-times` | omit timings, for reproducible output |

On any real codebase a full run is slow — it recompiles and re-tests once per
mutant. `--in-diff` against the merge base is what makes it affordable in CI.

## What pmat Itself Can Tell You in a Stock Install

pmat 3.32.0 cannot mutate your code, but it *can* find the class of test that
mutation testing exists to expose — and it does so in milliseconds rather than
hours.

### `pmat analyze vacuous-tests`

This finds `#[test]` functions that cannot fail: no assertion, no `?`, no
`panic!`, no expected-failure path.

On the fixture above, before the real assertion was added:

```bash
pmat analyze vacuous-tests -p .
```

```
1 of 1 #[test] fns cannot fail (100.0%) across 1 parsed file(s); 0 more skip silently when a fixture is missing
  [no-failure-mode] src/lib.rs:10  test_add_runs
```

and after:

```
1 of 2 #[test] fns cannot fail (50.0%) across 1 parsed file(s); 0 more skip silently when a fixture is missing
  [no-failure-mode] src/lib.rs:10  test_add_runs
```

Two things to note in that line. The **denominator** ("across 1 parsed
file(s)") is reported, so a scan that parsed nothing cannot masquerade as a
clean result. And the trailing clause counts tests that *silently skip* when a
fixture is missing, which is the second-commonest way a test stops being able
to fail.

This command requires a git repository — it enumerates tracked files, and says
so rather than guessing:

```
Error: git ls-files failed in . — cannot enumerate tracked files, so the scan would have no denominator
```

JSON, for a script (shown for the two-test version — note
`tests_examined: 2`):

```bash
pmat analyze vacuous-tests -p . -f json
```

```json
{
  "vacuous": [
    {
      "file": "src/lib.rs",
      "line": 10,
      "name": "test_add_runs",
      "kind": "no-failure-mode"
    }
  ],
  "conditional_skips": [],
  "tests_examined": 2,
  "files_parsed": 1,
  "skipped": {
    "unreadable": [],
    "unparseable": [],
    "unmeasured_tests": 0
  }
}
```

And as a gate, with two thresholds that both exit 1 when breached:

```bash
pmat analyze vacuous-tests -p . --fail-on-any     # exit 1 if any test cannot fail
pmat analyze vacuous-tests -p . --max-rate 10     # exit 1 above 10%
```

Verified on the two-test fixture (50% vacuous): `--fail-on-any` exits 1,
`--max-rate 60` exits 0, `--max-rate 10` exits 1.

### `pmat analyze unrun-tests`

A test that no CI leg executes is worse than a vacuous one — it cannot fail
*and* nobody is looking. This command keys on the full module path and reports
which tests no `cargo test` invocation in `.github/workflows` reaches.

```bash
pmat analyze unrun-tests -p . --executed default
```

```
2 of 2 lib tests are executed by at least one of 1 CI test leg(s); 0 are compiled by none
  leg: --executed 'default'
```

Without either a workflow to read or an explicit `--executed`, it refuses to
produce a number rather than reporting everything as unrun:

```
Error: no `cargo test` invocation was resolved from .github/workflows and none
was supplied with --executed; with zero legs every test would be a finding
```

`--write-ledger` and `--check-ledger` persist and then enforce the result, so a
newly orphaned test shows up as a diff rather than as silence.

### A Sensible Ladder

These three tools are cheap-to-expensive and catch overlapping-but-different
things. Run them in that order:

| Cost | Command | Catches |
|------|---------|---------|
| milliseconds | `pmat analyze unrun-tests` | tests nothing executes |
| milliseconds | `pmat analyze vacuous-tests` | tests that cannot fail |
| minutes–hours | `cargo mutants --in-diff` | tests that run and assert, but assert too little |

The first two are free enough to run on every commit; reach for the third on
changed code only.

## Historical Record: the `mutate` Subcommand

For readers who bookmarked this chapter, this is what the command was, as it
stood in 2.175.0–2.204.0. **It is not available in a default 3.32.0 build.**

The invocation was `pmat mutate --target <PATH>`, and its arguments — still
present in the gated source as `MutateArgs` — were:

| Flag | Meaning |
|------|---------|
| `-t, --target <PATH>` | file or directory to mutate (required) |
| `-l, --language <LANG>` | `rust`, `python`, `typescript`, `go`, `cpp` |
| `--timeout <SECS>` | per-mutant timeout (default 30) |
| `-j, --jobs <N>` | parallel workers |
| `-f, --output-format <FMT>` | `text` (default), `json`, `markdown` |
| `-o, --output <FILE>` | write to a file instead of stdout |
| `--threshold <SCORE>` | fail if the mutation score is below this |
| `--failures-only` | show only survived mutants, compile errors and timeouts |
| `--use-cargo-mutants` | delegate to `cargo-mutants` for Rust |

Its distinguishing claim was AST-based mutation without recompiling per mutant,
across five languages — which is why it is worth recording rather than
forgetting. But see the caveat in the banner: no run of it, in pmat's own CI or
anywhere else, has ever produced a published caught/missed count, so the
mutation scores this chapter used to print as example output were illustrative,
not measured.

To get a binary that contains it you would have to build with the feature
enabled rather than installing the published default:

```
cargo install pmat --features mutation-testing
```

That command is recorded for completeness. This book has not verified that such
a build succeeds against 3.32.0, and the feature is not exercised by pmat's
default CI.

## Summary

| The old chapter said | pmat 3.32.0 |
|----------------------|-------------|
| `pmat mutate --target src/` | Not in the default binary since 2.205.0 |
| AST mutation across 5 languages | Source still exists, gated behind `mutation-testing` |
| Example mutation scores (83.3% killed, …) | Illustrative; never a measured run |
| `--threshold 80.0` fails the build | Behind the same gate; pmat's own threshold has never been measured |
| Mutation testing is the gold standard | Still true — use `cargo mutants` |

## Related Chapters

- [Quality Gates](ch07-00-quality-gate.md)
- [Custom Quality Rules](ch11-00-custom-rules.md) — gates that really exit non-zero
- [Performance Testing Suite](ch23-00-testing.md)
