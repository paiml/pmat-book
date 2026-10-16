# Chapter 8: Interactive Demo and Reporting

<!-- DOC_STATUS_START -->
**Chapter Status**: ⚠️ The command exists but cannot run in a `cargo install pmat` build

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 0 | — |
| ⚠️ Not Implemented | 6 | Every `pmat demo` invocation exits 1 in the default build |
| ❌ Broken | 0 | — |
| 📋 Planned | 0 | — |

*Last updated: 2026-08-25*
*PMAT version: pmat 3.32.0*
<!-- DOC_STATUS_END -->

> **⚠️ Historical, as of pmat 3.32.0 (2026-08-25). `pmat demo` does not run in
> the build you get from `cargo install pmat`.**
>
> This chapter described `pmat 2.213.1` and presented 55 working examples. All 55
> fail against 3.32.0, for two independent reasons:
>
> - **`pmat demo` takes no positional path.** Forty of the examples were written
>   as `pmat demo .`; clap rejects that with "unexpected argument found" and
>   exits 2. The path goes in `-p` / `--path`.
> - **The demo is behind a non-default Cargo feature.** Even with the path
>   corrected, every invocation — `--cli`, `--protocol mcp`, the web server, all
>   of them — exits 1 with `Error: Demo feature not enabled. Build with
>   --features demo`. `pmat demo --help` still prints, which is why this chapter
>   passes the book's command-existence gate while none of it works.
>
> **The dashboards, JSON payloads and tables the old chapter pasted cannot be
> reproduced from an installed pmat.** They have been removed rather than
> reprinted as if verified. What remains is the invocation form, the real error,
> and where to go instead.
>
> For code analysis with output you can actually get today, read
> [Chapter 5](ch05-00-analyze-suite.md) (`pmat analyze`) and
> [Chapter 9](ch09-00-report.md) (`pmat report`).

## What `pmat demo` Was For

`pmat demo` bundles pmat's analyses into a presentation: a CLI summary, an
interactive web dashboard, or a scripted walk through the MCP tool surface. It
exists to show what `pmat` can do without asking the viewer to learn the
subcommands first.

It is a demonstration harness, not an analysis command. Nothing it reports is
unavailable from `pmat analyze` and `pmat report`, which is why shipping it
behind a feature flag costs installed users nothing but this chapter.

## Verified: What Happens When You Run It

```bash
pmat demo -p . --cli
```

```
Error: Demo feature not enabled. Build with --features demo
```

Exit code 1. The same for every mode:

```bash
pmat demo -p . --cli -f json
pmat demo --repo gh:owner/repository
pmat demo --url https://github.com/owner/repository.git
```

```
Error: Demo feature not enabled. Build with --features demo
```

The help text is candid about it — `pmat demo --help` opens with:

> `cargo install pmat` produces a build in which every demo mode (including
> `--cli`) exits 1 with "Demo feature not enabled", so all the flags below are
> inert.

## Enabling It

The `demo` feature does exist in the published crate. `cargo add --dry-run pmat
--features demo` resolves cleanly against pmat 3.32.0 (76 activated features
rather than the default 69), so this is the supported route:

```bash
cargo install pmat --features demo
```

That build has not been exercised for this chapter, and no output from it is
reproduced here. If you build it and the behaviour differs from the flag
reference below, the flag reference is what `--help` printed, not what the demo
did.

## Flag Reference

These are the flags `pmat demo --help` lists in 3.32.0. They all parse; none of
them does anything in the default build. **The path is `-p`, never positional.**

| Flag | Meaning |
|------|---------|
| `-p, --path <PATH>` | Repository path (defaults to current directory) |
| `--repo <REPO>` | Repository to analyze — GitHub URL, local path, or `gh:owner/repo` |
| `--url <URL>` | Remote repository URL to clone and analyze |
| `-f, --format <FORMAT>` | `table` (default), `json`, `yaml`, `markdown`, `csv`, `summary`, `text`, `plain`, `junit` |
| `--protocol <PROTOCOL>` | `cli`, `http` (default), `mcp`, `all` |
| `--cli` | CLI output mode instead of the web dashboard |
| `--show-api` | Show API introspection information |
| `--port <PORT>` | Port for the demo server (default: random) |
| `--no-browser` | Skip opening a browser (web mode only) |
| `--target-nodes <N>` | Target node count for graph reduction (default: 15) |
| `--centrality-threshold <F>` | Minimum betweenness centrality for graph reduction (default: 0.1) |
| `--merge-threshold <N>` | Component size threshold for merging (default: 3) |
| `--skip-vendor` / `--no-skip-vendor` | Vendor file handling (skipping is the default) |
| `--max-line-length <N>` | Line length above which a file is treated as unparseable |
| `--debug` / `--debug-output <PATH>` | Detailed file classification logs, optionally to a JSON file |

Correct invocation forms, for when you have a build that supports them:

```bash
pmat demo -p . --cli
pmat demo -p . --cli -f json
pmat demo -p . --port 3000 --no-browser
pmat demo -p . --protocol mcp --show-api
pmat demo -p . --cli --target-nodes 20 --centrality-threshold 0.2
pmat demo --repo gh:rust-lang/rustlings --cli
```

Each of these exits 1 in the default build. They are printed as *forms*, not as
worked examples.

## What to Use Instead

Everything the demo displayed has a first-class command that works in the build
you already have:

| Demo feature | Use instead |
|--------------|-------------|
| CLI summary of a project | `pmat analyze complexity`, `pmat analyze satd`, `pmat context` — [Chapter 5](ch05-00-analyze-suite.md) |
| Consolidated report (JSON/CSV/Markdown) | `pmat report -p . --md` — [Chapter 9](ch09-00-report.md) |
| Dependency graph visualisation | `pmat analyze dag`, `pmat analyze graph-metrics --export-graphml` — [Chapter 26](ch26-00-graph-statistics.md) |
| MCP tool walkthrough | `pmat --mode mcp`, or `pmat serve --transport http` — [Chapter 3.4](ch03-04-mcp-transports.md) |
| Analysing a remote repository | `git clone` it, then point `-p` at the checkout |

`pmat serve` is a real, compiled-in HTTP server, but it serves the **MCP tool
surface**, not a dashboard. It is not a drop-in replacement for the demo's web
UI; there is no HTML dashboard in the default build.

## Summary

`pmat demo` is a feature-gated presentation tool. In `cargo install pmat` it
resolves, prints help, and refuses to run.

Key takeaways:
- **`-p`, not a positional path.** That alone broke 40 of this chapter's 55
  examples even before the feature gate.
- Every mode exits 1 with `Demo feature not enabled` in the default build.
- `cargo install pmat --features demo` is the documented route; the `demo`
  feature is real in the published 3.32.0 crate.
- No demo output is reproduced in this chapter, because none of it can be
  produced from an installed pmat.
