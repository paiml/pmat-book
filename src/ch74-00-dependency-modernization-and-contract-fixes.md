# Chapter 74: Dependency Modernization & Contract-Backed Dogfood Fixes (v3.18.3 → v3.19.2)

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ Case study — released as pmat v3.18.3 through v3.19.2

*Released: 2026-06-12 → 2026-06-13 (a 24-hour release train)*
*PMAT version: 3.19.2*
*MSRV: Rust 1.95.0 (raised from 1.80 to match the modernized tree)*
<!-- DOC_STATUS_END -->

## Why This Chapter Exists

Five releases shipped to crates.io and GitHub inside a single day. Looked at
individually, each is small. Looked at as an arc, they tell a story that
recurs in every long-lived Rust project: routine dependency maintenance turns
into a whole-tree modernization, the modernization forces an API-breakage
fixup and an MSRV bump, the MSRV bump unlocks new lints, and the act of
re-running the tool on its own repo surfaces two real defects that get fixed
*at the root cause and pinned with provable contracts*.

The arc:

| Version | Theme | Binary behavior |
|---------|-------|-----------------|
| v3.18.3 | Routine dependency maintenance | Unchanged |
| v3.18.4 | CI/tooling hygiene | Identical to 3.18.3 |
| v3.19.0 | Whole-tree dependency modernization | Changed (breakage fixed) |
| v3.19.1 | MSRV correction + lint cleanup | Unchanged |
| v3.19.2 | Two self-dogfood defects, root-caused | Changed (fixes) |
| PR #599 | Post-release CI fix | n/a (CI only) |

The teachable lessons are scattered across those rows: *derive, don't
duplicate*; *a raw directory walk lies about scope*; *a major dep bump is
mostly about the API breakage, not the version number*; *root-cause fixes
carry contracts so the invariant can't quietly regress*.

## v3.18.3 — Routine Dependency Maintenance

The first release is the boring one, and that is the point. `Cargo.lock` was
refreshed to the latest semver-compatible transitive dependencies. The
refresh pulled in a new terminal-render cluster (`wezterm` / `termwiz` /
`vtparse`). No source changed; the shipped binary behaves identically to its
predecessor.

The lesson here is preventative: a lockfile that drifts for months turns the
next refresh into an archaeology project. Refreshing little and often keeps
each diff readable and each regression bisectable.

## v3.18.4 — CI/Tooling Hygiene (Binary Identical to 3.18.3)

This release changed *nothing* a user runs — the binary is identical to
3.18.3 — but it fixed several quiet tooling failures that had been silently
eroding the project's automation.

- **`make dogfood` was running invalid analyze flags.** The recipe used
  `analyze dag --top-files`, but the flag is `--target-nodes`; and it passed
  `--format table` to `complexity` and `churn`, where that value no longer
  exists. The dogfood recipe was failing on flags, not on findings.
- **Dependabot was watching a directory that no longer existed.** After the
  earlier `server/ → root` flattening, the Dependabot config still pointed at
  a `/server` cargo directory. The result was the worst kind of failure —
  *silent*: cargo-update PRs had simply stopped arriving, and nobody had
  noticed.
- **A never-installed npm test fixture** was excluded from Dependabot so it
  stopped generating noise.
- **All four open Dependabot security alerts** were triaged and dismissed,
  each with a documented non-shipping rationale.

The recurring shape: tooling that fails *silently* is worse than tooling that
fails loudly. A red `make dogfood` gets fixed in minutes; a Dependabot
watcher pointed at a deleted path produces nothing, and "nothing" looks
exactly like "no updates available."

## v3.19.0 — Whole-Tree Dependency Modernization

This is the load-bearing release. The entire dependency tree moved forward at
once, and the version numbers are the least interesting part of it.

The sovereign stack — the in-family `aprender-*` crates — moved to **0.41**:

```toml
aprender            = "0.41"   # ML, stats, text similarity
aprender-graph      = "0.41"   # CSR graph DB: PageRank, Louvain
aprender-db         = "0.41"   # columnar analytics (lib name: trueno_db)
aprender-rag        = "0.41"   # RAG pipeline, VectorStore
aprender-viz        = "0.41"   # terminal graph visualization
aprender-compute    = "0.41"   # SIMD/GPU compute (lib name: trueno)
aprender-zram-core  = "0.41"   # SIMD LZ4/ZSTD compression
aprender-contracts  = "0.49"   # provable contracts
aprender-contracts-macros = "0.49"
pmcp                = "2.9"     # MCP protocol SDK
```

External deps moved in lockstep: `swc 41`, `tree-sitter 0.26`, `wgpu 29`,
`gimli 0.33`, `wasmparser 0.252`, `git2 0.21`, `sha2 0.11`, with `arrow 57`
and `rusqlite 0.32` capped to match `aprender-db`. And `bincode` was
**removed entirely**, replaced by `rmp-serde` (MessagePack) for the `.pmat`
recording format.

### A major bump is mostly about the API breakage

Bumping the numbers takes one line each. Making the code compile and behave
correctly afterward took the rest of the release. The breakage that mattered:

- **swc 41 panicked on *every* JS/TS file.** The parser was constructed with
  a misconfigured input. The fix routes the source through
  `StringInput::from(&*source_file)`. This is the kind of regression that a
  version-only diff hides: it compiles, ships, and then falls over on the
  first real input.
- **sha2 0.11 dropped `LowerHex` on the `finalize()` output.** Roughly twelve
  files plus `build.rs` formatted digests with `{:x}` and stopped compiling.
  Each had to switch to explicit hex encoding of the finalized bytes.
- **git2 0.21 changed `Remote::url`** from returning an `Option` to returning
  a `Result`. Every caller had to adapt its error handling.
- **wgpu 29 reworked the device/poll API**, and `wasmparser` / `gimli` /
  `tree-sitter` / `swc` all migrated their interned-atom types — a mechanical
  but wide sweep.

### When an upstream drops an API, fail *actionably*

`aprender-orchestrate 0.41` dropped the OIP API that backed `pmat org
analyze`. Rather than leave a confusing compile error or a silent no-op, the
subcommand now returns a **clear, actionable error** explaining the upstream
removal. The sibling `pmat org localize` was preserved. The principle: when a
capability genuinely goes away upstream, say so at the boundary the user
touches — don't paper over it.

### Smaller wins

The docs.rs feature set was leaned out to fix a failing docs.rs build (with a
build-limit increase requested upstream, `rust-lang/docs.rs#3370`), and a
`/dogfood` Claude Code skill was added — the same skill that, two releases
later, grows the protocols that catch v3.19.2's bugs.

## v3.19.1 — The MSRV Correction the Modernization Implied

A modernized tree quietly raises the floor. Several of the bumped crates
require newer Rust than pmat's declared `rust-version = "1.80"`, so the
manifest was corrected to **1.95.0** to tell the truth about what the code now
needs.

Two things rode along:

- **A libsql storage race** was fixed: `create_storage_backend` now allocates
  a per-call unique DB path, so parallel MCP / coverage runs no longer flake
  on a shared file.
- **Bumping the MSRV unlocks new lints.** Thirty clippy sites gated behind
  newer Rust became visible — for example `map_or(true, ..)` rewritten to the
  cleaner `is_none_or(..)`. All thirty were cleaned with no behavior change.

That second point is the lesson: an MSRV bump is not just a number in
`Cargo.toml`. It hands you a batch of lints that were waiting for the floor to
rise. Clearing them as part of the bump keeps the cleanup atomic instead of
trickling red CI for weeks.

## v3.19.2 — Two Dogfood Defects, Each Root-Caused

Running pmat on pmat — the `/dogfood` skill from v3.19.0 — surfaced two
defects. Both were fixed at the root cause, not patched at the symptom, and
both gained provable contracts so they can't silently come back.

### Defect 1: a raw walk that lies about scope

`analyze dead-code` walked the tree with a raw `walkdir` that skipped only
`target/`. That single exclusion is a trap: it descends into anything else,
including the hidden `.claude/worktrees/` git-worktree copies — full
duplicate checkouts of the repo. The damage showed up as a number that made
no sense:

```text
total_files_analyzed: 263,890   # before — descended into .claude/worktrees/
total_files_analyzed:   4,224   # after  — the real count of .rs files
```

A ~60× inflation, with worktree duplicates surfacing as "dead code." The
root-cause fix is to stop hand-rolling the walk. Both walks now use
`ignore::WalkBuilder`, which is hidden-file aware and `.gitignore`-aware by
default:

```rust
// before: descends into hidden git-worktree copies
for entry in WalkDir::new(root) {
    if entry.path().starts_with("target") { continue; }
    // ...
}

// after: respects hidden + .gitignore, like ripgrep does
for entry in ignore::WalkBuilder::new(root).build() {
    // hidden dirs (.claude/worktrees/) and gitignored paths are skipped
}
```

And `total_files` is now the **real count of `.rs` files actually walked**,
not the previous `total_lines / 100` estimate. The lesson generalizes well
beyond pmat: *a hand-rolled directory walk that excludes one path is a
denylist, and denylists silently include everything you forgot.* Tools like
ripgrep get scope right because `ignore::WalkBuilder` is an allowlist shaped
by the repository's own ignore rules. Reach for it instead of `walkdir`
whenever "the files the project actually cares about" is the intended scope.

### Defect 2: `--exclude-tests` that leaked test code

`pmat query --exclude-tests` was letting test code through in all three query
paths — semantic, raw (`--literal` / `--regex`), and coverage-gaps. The
leaks were the test artifacts that don't live in obvious places:

- `include!()`-ed test fragments (`*_tests_*.rs`, `*_test_helpers.rs`)
- helper functions (`setup_test*`, `create_test*`)
- `*fixtures*` support files

Test detection now matches all of these patterns across all three paths.

One limitation is documented honestly rather than hidden: functions inside
`#[cfg(test)] mod` blocks in otherwise-production files, when they carry
non-test names, still slip through. Catching those requires AST-level
detection, which is noted as future work. Saying so in the open is part of the
fix — the next person debugging an unexpected test result reads the
limitation instead of rediscovering it.

### The contracts that keep both fixes honest

Six touched functions gained `#[provable_contracts_macros::contract(...)]`
annotations. This is the difference between fixing a bug and fixing it
*durably*: the invariant — "the dead-code walk does not descend into hidden
worktrees," "`--exclude-tests` excludes test helpers" — is now a checked
contract, not a comment and a hope. A future refactor that reintroduces the
old behavior fails the contract instead of silently shipping the regression.

The `/dogfood` skill grew to match:

- **P7** — dead-code count sanity: the analyzed-file count must be plausible
  and must not descend into `.claude/worktrees/`.
- **P8** — `--exclude-tests` must exclude test *files and helpers*, not just
  obvious `#[test]` functions.
- **Gate 6** — a provable-contract coverage policy, so root-cause fixes are
  expected to ship with contracts.

## The Tail: A Stale Hardcoded Toolchain (PR #599)

The MSRV bump had one more victim. The Post-Release **"MSRV verification"**
CI job hardcoded `Rust 1.80.0`. The moment the manifest declared 1.95, that
job started red-lighting **every** release after the bump — verifying against
a floor the project no longer claimed.

The fix is the single most transferable lesson in this whole chapter:

> A value duplicated from `Cargo.toml` will go stale. Derive it instead.

The CI job now reads the toolchain from `Cargo.toml`'s declared
`rust-version` rather than carrying its own copy:

```yaml
# before: a second source of truth that drifts
- run: rustup toolchain install 1.80.0

# after: derive the MSRV from the manifest — one source of truth
- run: |
    MSRV="$(cargo metadata --no-deps --format-version 1 \
      | jq -r '.packages[] | select(.name=="pmat") | .rust_version')"
    rustup toolchain install "$MSRV"
```

The same shape that broke the MSRV job — a hardcoded number copied out of the
manifest — is the shape that, in v3.18.2, divided RPS by a stale `134.0`
scale. Two different files, two different releases, one bug: *a second source
of truth drifts away from the first.* Whenever you find yourself copying a
value that already lives in a manifest, a baseline, or another tool's output,
derive it instead.

## What This Means for You

- **Refresh dependencies little and often.** A `Cargo.lock` left to drift for
  months turns the next bump (v3.19.0) into a multi-file API-breakage sweep.
  v3.18.3's boring refresh is the cheap insurance.
- **Watch for tooling that fails silently.** A `make dogfood` failing on bad
  flags is loud and gets fixed fast; a Dependabot watcher pointed at a deleted
  `/server` directory produces *nothing*, and nothing looks like "all caught
  up." Audit your automation's *inputs*, not just its outputs.
- **A major dep bump is mostly the API fixup.** swc 41 panicking on every
  JS/TS file, sha2 0.11 dropping `LowerHex`, git2 0.21's `Option → Result` —
  none of these show up in a version-number diff. Budget the time for the
  breakage, not the bump.
- **An MSRV bump unlocks lints.** Raising the floor to 1.95 surfaced 30 clippy
  sites (`map_or(true, ..)` → `is_none_or(..)`). Clear them atomically with
  the bump.
- **Don't hand-roll directory walks.** A walk that skips only `target/` is a
  denylist that silently descends into `.claude/worktrees/` and inflates your
  counts ~60× (263,890 vs the real 4,224). Use `ignore::WalkBuilder` so the
  repository's own ignore rules define scope.
- **Derive, don't duplicate.** A hardcoded `1.80.0` copied from `Cargo.toml`
  red-lit every release after the 1.95 bump. Read the value from its single
  source of truth.
- **Pin root-cause fixes with contracts.** Six functions gained provable
  contracts so the dead-code-scope and `--exclude-tests` invariants can't
  quietly regress — and the `/dogfood` skill grew P7, P8, and Gate 6 to keep
  checking them on every future pass.

As of this release train, pmat is **v3.19.2**, builds on **Rust 1.95.0**,
installs with `cargo install pmat` (or `cargo install --path .` from source),
and exposes **20 MCP tools** (16 core + 4 agent_context) over its documented
stdio server.
