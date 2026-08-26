# Chapter 10: Auto-clippy Integration

> **⚠️ Rewritten against pmat 3.32.0 (2026-08-25).**
>
> This chapter used to document a top-level `pmat clippy` command with
> `enable` / `run` / `fix` / `cache` subcommands, cross-language support for
> Python, JavaScript, TypeScript, Go and Java, a `[clippy]` section in
> `pmat.toml`, a `.pmat/clippy-rules.yaml` rule file and a set of
> `pmat config set clippy.*` keys. **None of that has ever existed.** Every one
> of the 19 commands the old chapter printed exited with
> `error: unrecognized subcommand`, and the config files it told you to write
> are read by nothing.
>
> The old status badge claiming "✅ 100% Working (8/8 examples)" has been
> removed: `tests/ch10/test_auto_clippy.sh` wrote three config files and
> asserted that they existed, never invoking `pmat`. It has been rewritten to
> exercise the real command.
>
> The real command is **`pmat analyze clippy`**, it is **Rust-only**, and its
> option set is small. This chapter documents that command, and only that
> command. Every example below was executed against `pmat 3.32.0` and the
> output pasted verbatim.
>
> One thing you need before you read further: **without `--dry-run` this
> command reports that it applied fixes and does not write to disk.** See
> [It does not actually fix anything](#it-does-not-actually-fix-anything).

*What `pmat analyze clippy` really is: a confidence filter in front of `cargo
clippy`'s JSON diagnostics.*

## What the Command Actually Does

`pmat analyze clippy` shells out to `cargo clippy`, parses the machine-readable
diagnostics, assigns each one a **confidence level**, drops everything below a
threshold you choose, and prints the survivors as JSON.

That is the whole feature. It is a triage filter, not a linter of its own and
not a fixer. In particular:

- It is **Rust-only.** It needs a `Cargo.toml`. There is no Python, JavaScript,
  TypeScript, Go or Java support, and never was.
- It adds **no lints.** Every diagnostic it reports comes from `cargo clippy`.
- It reads **no configuration file.** Not `pmat.toml`, not `.pmat/`, not
  `clippy.toml`. Everything is a command-line flag.
- It **does not modify your source.** See below.

## The Options

```bash
pmat analyze clippy --help
```

| Flag | Meaning | Default |
|------|---------|---------|
| `-p, --path <PATH>` | Directory to analyze (must contain a `Cargo.toml`) | `.` |
| `-c, --confidence <LEVEL>` | Minimum confidence to report: `high`, `medium`, `low` | `high` |
| `--dry-run` | Report what would be fixed instead of "applying" | off |
| `--fix-codes <CODES>` | Comma-separated clippy codes to keep | all |
| `-o, --output <FILE>` | Write the JSON report to a file as well as stdout | stdout only |
| `--perf` | Print the wall time of the run | off |

An unknown confidence level is rejected rather than silently defaulted:

```bash
pmat analyze clippy --dry-run --confidence bogus
```

```
Error: Invalid confidence level: bogus
```

## A Worked Example

Create a crate with two clippy findings:

```bash
mkdir -p demo2/src && cd demo2
cat > Cargo.toml << 'EOF'
[package]
name = "demo2"
version = "0.1.0"
edition = "2021"
EOF
cat > src/main.rs << 'EOF'
fn double(x: i32) -> i32 {
    return x * 2;
}

fn main() {
    let s = "hello".to_string();
    if s.len() > 0 {
        println!("{}", double(3));
    }
}
EOF
```

`cargo clippy` reports two things here: `clippy::needless_return` on line 2 and
`clippy::len_zero` on line 7. At the default confidence, `pmat` shows you one
of them.

```bash
pmat analyze clippy --dry-run
```

Verbatim output from `pmat 3.32.0`:

```json
{
  "action": "analyzed",
  "diagnostics_found": 2,
  "diagnostics_eligible": 1,
  "diagnostics_filtered_out": 1,
  "min_confidence": "High",
  "results": {
    "dry_run": true,
    "total_fixes": 1,
    "fixes": [
      {
        "file": "src/main.rs",
        "line": 2,
        "code": "clippy::needless_return",
        "message": "unneeded `return` statement",
        "confidence": "High",
        "would_fix": true
      }
    ]
  },
  "message": "🔧 clippy reported 2 diagnostic(s); 1 met confidence High and were analyzed, 1 left untouched"
}
```

The three counters are the useful part of the output, and they are honest about
what was hidden:

- `diagnostics_found` — everything `cargo clippy` reported.
- `diagnostics_eligible` — what survived the confidence filter.
- `diagnostics_filtered_out` — what was suppressed. **A run with
  `total_fixes: 0` is not a clean codebase** if this number is non-zero, and the
  `message` field says so out loud.

Lower the bar and the second finding appears:

```bash
pmat analyze clippy --dry-run --confidence low
```

Now `diagnostics_eligible` is 2 and `clippy::len_zero` joins the list.

On a crate whose *only* finding is a low-confidence one, the default is starker
still — it reports zero fixes on a codebase that is not clean, and says so:

```json
{
  "action": "analyzed",
  "diagnostics_found": 1,
  "diagnostics_eligible": 0,
  "diagnostics_filtered_out": 1,
  "min_confidence": "High",
  "results": {
    "dry_run": true,
    "total_fixes": 0,
    "fixes": []
  },
  "message": "⚠️ clippy reported 1 diagnostic(s), and none met the required confidence (High) — 1 left untouched. This is NOT a clean result; re-run with --confidence low to see them."
}
```

## Where Confidence Comes From

Confidence is **not** computed from your code. It is a seven-entry hardcoded
table (`src/services/clippy_fix/clippy_fix_engine.rs`, `init_confidence_rules`),
with a fallback for everything else:

| Clippy code | Confidence |
|-------------|-----------|
| `clippy::needless_return` | High |
| `clippy::redundant_clone` | High |
| `clippy::unnecessary_wraps` | High |
| `clippy::manual_map` | Medium |
| `clippy::single_match` | Medium |
| `clippy::needless_lifetimes` | Low |
| `clippy::complex_lifetime` | Low |

Any code not in that table falls back to **Medium** if the diagnostic carried a
machine-applicable suggestion, and **Low** if it did not.

Two consequences worth internalising before you build a workflow on this:

1. The default `--confidence high` shows you at most three lints out of the
   several hundred clippy has. On most real crates the default reports nothing
   while filtering out everything.
2. Confidence says nothing about severity. A `Low` finding is not a minor
   finding; it is one this table has no opinion about.

## Filtering by Code

`--fix-codes` keeps only the codes you name:

```bash
pmat analyze clippy --dry-run --confidence low --fix-codes clippy::needless_range_loop
```

Beware the reporting here: when `--fix-codes` excludes a diagnostic, the run
still counts it under `diagnostics_filtered_out` and still prints the message
"*none met the required confidence*", even though confidence was not the reason.
Read `diagnostics_eligible`, not the prose.

## Writing the Report to a File

```bash
pmat analyze clippy --dry-run --confidence low -o report.json
```

```
📁 Results written to report.json
```

The same JSON goes to both stdout and the file.

## Timing

```bash
pmat analyze clippy --dry-run --perf
```

appends one line after the JSON:

```
⏱️  perf: analyze clippy completed in 38.5 ms
```

That figure excludes nothing — the underlying `cargo clippy` invocation
dominates any real run, and this timer measures pmat's own pass over the
already-produced diagnostics.

## It Does Not Actually Fix Anything

The command's own description is "Automated clippy fixes with confidence-based
filtering", and dropping `--dry-run` produces output that reads like a
successful edit:

```bash
pmat analyze clippy
```

```json
{
  "action": "applied",
  "diagnostics_found": 2,
  "diagnostics_eligible": 1,
  "diagnostics_filtered_out": 1,
  "min_confidence": "High",
  "results": {
    "dry_run": false,
    "report": {
      "total_diagnostics": 1,
      "successful_fixes": 1,
      "failed_fixes": 0,
      "success_rate": 100.0,
      "total_duration_ms": 0,
      "fixed_files": [
        "src/main.rs"
      ]
    },
    "detailed_results": [
      {
        "file": "src/main.rs",
        "line": 2,
        "code": "clippy::needless_return",
        "success": true,
        "error": null,
        "duration_ms": 0
      }
    ]
  },
  "message": "🔧 clippy reported 2 diagnostic(s); 1 met confidence High and were applied, 1 left untouched"
}
```

`"action": "applied"`. `"successful_fixes": 1`. `"success_rate": 100.0`.
`"fixed_files": ["src/main.rs"]`.

**`src/main.rs` is byte-identical afterwards.** Re-running the analysis reports
the same two diagnostics. This was reproduced on two separate crates with two
different lints (`clippy::needless_return` and `clippy::needless_range_loop`)
against `pmat 3.32.0`.

The mechanism is visible in the source: `ClippyFixEngine::apply_fix` builds a
`modified_source` string in memory and returns it inside a `FixResult`, and
nothing in `src/services/clippy_fix/` ever writes that string back to disk —
there is no `fs::write` in the module. The rewrite itself is also a string
`replace` rather than a span-based edit, so even if it were persisted it would
be unsafe on anything but the simplest case.

**Treat `pmat analyze clippy` as read-only.** Use `--dry-run` always, so that
the output shape matches what the command actually does.

## If You Want Fixes Applied

Use cargo's own machinery, which does write to disk and is span-accurate:

```bash
cargo clippy --fix --allow-dirty --allow-staged
```

```
    Checking demo2 v0.1.0 (/tmp/demo2)
       Fixed src/main.rs (2 fixes)
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.05s
```

Both findings are gone from the file afterwards — `return x * 2;` became
`x * 2` and `s.len() > 0` became `!s.is_empty()`. `cargo fix` refuses to run
outside version control (`error: no VCS found for this package`); add
`--allow-no-vcs` if you really mean it.

A reasonable division of labour is to use `pmat analyze clippy --dry-run` for
triage — the confidence counters answer "how much am I not being shown?" in one
JSON object — and `cargo clippy --fix` to act.

## Where Rust Linting Is Actually Enforced in pmat

Nothing about `analyze clippy` fails a build. If you want clippy to gate a
commit or a CI job, `pmat` has two commands that really do exit non-zero:

- **`pmat quality-gates`** runs clippy (plus tests, coverage and complexity)
  according to `.pmat-gates.toml` and exits 1 on failure. See
  [Custom Quality Rules](ch11-00-custom-rules.md).
- **`pmat verify`** runs the CI-faithful gate set — format, complexity, SATD,
  clippy, tests — fail-fast, and is the intended pre-commit check.

```bash
pmat verify --format json
```

## Summary

| Claim in the old chapter | Reality in pmat 3.32.0 |
|--------------------------|------------------------|
| `pmat clippy enable` / `run` / `fix` / `cache` | No such command; the real one is `pmat analyze clippy` |
| Works on Python, JS, TS, Go, Java | Rust only; errors out without a `Cargo.toml` |
| `[clippy]` section in `pmat.toml` | Read by nothing |
| `.pmat/clippy-rules.yaml` | Read by nothing |
| `pmat config set clippy.*` | `pmat config` has no `set` subcommand |
| Auto-fixes safe suggestions | Reports success, writes no bytes |
| AI-powered semantic suggestions | Diagnostics come from `cargo clippy`, unmodified |

What is genuinely useful here is narrow but real: a one-command view of how many
clippy diagnostics exist, how many a confidence threshold is hiding from you,
and which ones survive — as JSON, in a form a script can consume.
