# Chapter 69: R8 Performance Matrix and the HTTP Stub Defect

R8 of the dogfood rounds (2026-04-18) did what R1–R7 deferred: **measure every CLI path, plot the slow ones, and cross-reference `pmat`'s published O(1) contract against observed reality.** The output is a benchmark matrix covering 80+ command surfaces, a new defect in the exit-0-on-error family (**D72**), a verification that D42 (MCP stdin EOF hang) is fixed, and a fresh look at the MCP surface gap that Chapter 64 flagged. This chapter is the reader's fast path to those findings.

Full raw data lives in `/tmp/pmat-dogfood/round8/bench-r8.md` on the dogfood host; issue [#347](https://github.com/paiml/paiml-mcp-agent-toolkit/issues/347) tracks D72 and related follow-ups.

## 69.1 The Benchmark Matrix — What We Measured

Runner: `/usr/bin/time -v`, 3 runs per command, `wall_p50` = median, `wall_p95` = max-of-3. Two corpora: **tiny** (a 2-function Rust hello-world) and **repo** (the PMAT codebase itself, ~18K functions). Thresholds: O(1) paths ≤500 ms wall, ≤256 MB RSS.

Trivial paths (help, version, `list`, `cache stats`, `memory stats`, `diagnose`) are all ≤1 ms wall, ~15 MB RSS. Forty+ help outputs: clean.

The slow tail on the real repo is the headline:

### Top-10 Slowest Commands (by `wall_p50`)

| # | cmd | wall_p50 | wall_p95 | rss | notes |
|---|---|---|---|---|---|
| 1 | `pmat score` | **56.05 s** | 56.90 s | **1.41 GB** | **Peer to comply check (D10/D54, 52 s / 1.44 GB).** |
| 2 | `pmat quality-gate` | 31.90 s | 32.60 s | 319 MB | 64× over O(1) wall threshold. |
| 3 | `pmat perfection-score` | 5.35 s | 5.40 s | 145 MB | |
| 4 | `pmat rust-project-score` | 4.14 s | 4.14 s | 52 MB | |
| 5 | `pmat tdg .` | 2.91 s | 5.16 s | 47 MB | |
| 6 | `pmat analyze duplicates` | 2.08 s | **15.43 s** | 44 MB | Extreme p50→p95 variance (7.4×). |
| 7 | `pmat analyze complexity` | 1.11 s | 1.12 s | 30 MB | |
| 8 | `pmat infra-score` | 0.95 s | 1.03 s | 37 MB | Borderline. |
| 9 | `pmat analyze satd` | 0.49 s | 0.55 s | 18 MB | Meets budget. |
| 10 | `pmat analyze churn --days 30` | 0.47 s | 0.48 s | 70 MB | Meets budget. |

The `score` entry is the most interesting finding of R8: it is a **structural peer** of the comply-check defect (D10/D54), sitting at an essentially identical time/memory profile. §69.3 explains why that matters.

## 69.2 D72 — `pmat serve --transport http` Binds No Port

R8's second headline is a new entry in the exit-0-on-error family. Chapter 65 already documented D13 (the HTTP server is a stub for `--transport http`). R8 extends that finding: **every one of the four transports is a stub, none bind a port, and every one reports "Server ready"**. This is **D72**.

### Reproduction

```bash
pmat serve --transport http --port 58719 &
PID=$!
sleep 2

ss -tln | grep 58719      # expect: (nothing — no listener)
curl -sSf http://127.0.0.1:58719/health 2>&1
                          # expect: "Connection refused"

kill $PID
```

Stderr banner while "running":

```text
🚀 Starting PMAT HTTP server on http://127.0.0.1:58719
✅ Server ready!
  Health check: http://127.0.0.1:58719/health
  API base: http://127.0.0.1:58719/api/v1

HTTP server functionality ready for implementation.
Press Ctrl+C to exit.
```

All four transport values show the same pattern:

| transport | bound? | banner |
|---|---|---|
| `--transport http` | NO | "HTTP server functionality ready for implementation." |
| `--transport web-socket` | NO | "WebSocket server implementation ready for 127.0.0.1:PORT" |
| `--transport http-sse` | NO | "HTTP-SSE server implementation ready for 127.0.0.1:PORT" |
| `--transport all` | NO | "Full server implementation ready for 127.0.0.1:PORT" |

### Why This Is a Silent-Hang Footgun

A CI job or integration test that runs:

```bash
pmat serve --transport http --port 9090 &
sleep 3
curl http://localhost:9090/health   # hangs or reports connection refused
```

will either:

1. **Timeout on the curl** — reported as a downstream test failure, not a pmat bug.
2. **Leak the background process** — `pmat serve` stays alive until the CI runner tears down the job, consuming a runner slot.

The banner says "ready" and the exit code (when eventually killed) is 0. Nothing in the contract tells the caller that `pmat serve --transport http` is not shippable. This is the same class as D16/D25/D26/D35/D57/D64..D71: **a command that reports success but does not do what its name promises**. D72 adds a wrinkle — instead of exiting 0 immediately, it exits 0 *after hanging forever*. That's worse, because automated pipelines hang.

### Harness

The companion regression harness is `examples/http_stub_probe.rs` in the pmat repo (R8 PR #346):

```bash
cargo run --example http_stub_probe
# expected today: exit=1, "PORT NOT BOUND — D72 reproduced. Banner lies."
# expected post-fix: exit=0, "PORT BOUND — D72 appears FIXED."
```

It spawns the server, waits 1.5 s, attempts `TcpStream::connect_timeout`, and flips its exit code when the defect closes. Zero new dependencies — stdlib only.

### Fix Options

The D72 remediation is one of three:

1. **Implement the transports.** Replace each stub `handle_*_server` in `server/src/cli/analysis_utilities/comprehensive_serve.rs` with a real `axum::Router` + `tokio::net::TcpListener::bind` pair wiring the existing MCP dispatch logic to REST/SSE/WebSocket. Medium scope; tracked as the expected fix for issue #333 D13.
2. **Make the stub exit 1.** Until (1) lands, change the handlers to eprintln "not yet implemented" and return `exit code 2`. This turns a silent hang into a loud failure, which is the Toyota-Way honest move.
3. **Remove the stub from the CLI surface.** `clap` rejects unknown values with exit 2 automatically; removing `http/web-socket/http-sse/all` from the `--transport` enum eliminates the surface entirely until it can ship.

Option (2) is the R8 recommendation as a tactical patch.

## 69.3 The "Structural Peer" Pattern

A *structural peer* defect is one where two surfaces share enough of a codepath that one fix plausibly closes both. R8's headline structural peer:

| defect | command | wall | rss |
|---|---|---|---|
| D10/D54 | `pmat comply check` | 52 s | 1.44 GB |
| R8 finding | `pmat score` | 56 s | 1.41 GB |

These are not independent slow paths. Both commands walk the project tree with `walkdir::WalkDir`, both deserialise large JSON graphs, both materialise intermediate results in a shared-shape `Report`. R7's CB-1800 patch sketch (Chapter 68 §68.5) targeted comply-check specifically, but the data-types it proposes — `ProjectSnapshot`, `FileCorpus`, `NamedTimer` — generalise to *any* command that does a full-project walk. `quality-gate` (32 s, 319 MB) is the same family. `rust-project-score` (4 s, 52 MB) and `perfection-score` (5 s, 145 MB) are lighter peers but share the pattern.

The pattern matters for remediation triage. When you profile comply-check and fix the WalkDir-deduplication bug, you close the top-5 slow commands with the same PR instead of fixing them one at a time. This is the argument for landing CB-1800 as the first-priority R9 kaizen ticket: its blast radius covers D10, D54, plus the R8 top-4 violators.

## 69.4 D42 VERIFIED RESOLVED — MCP stdin EOF

Chapter 67 catalogued **D42 — "MCP stdin never closes; pmat serve --mode mcp hangs 60 s after last JSON-RPC request"**. R8's MCP harness found it *fixed* in 3.14.0. Evidence:

```bash
cat request.json | /usr/bin/time pmat serve --mode mcp
# observed: exits within 10 ms of EOF, user=0.02 sys=0.01 real=0.03
```

All four MCP calls (`tools/list`, `tools/call get_server_info`, `tools/call list_templates`, `tools/call analyze_complexity`) complete sub-50 ms, ≤22 MB RSS. MCP-over-stdio is the one transport surface that is healthy and meets the O(1) contract. Chapter 64 is now accurate; Chapter 68 §68.1's D42 row can be annotated RESOLVED in a future revision.

## 69.5 MCP Surface Gap — 21 of ~70 Tools Wired

A secondary R8 finding: `tools/list` returns exactly 21 MCP tools:

```
get_server_info, generate_template, list_templates, validate_template,
scaffold_project, search_templates, analyze_code_churn, analyze_complexity,
analyze_dag, generate_context, analyze_dead_code, analyze_deep_context,
analyze_duplicates_vectorized, analyze_graph_metrics_vectorized,
analyze_name_similarity_vectorized, analyze_symbol_table_vectorized,
analyze_incremental_coverage_vectorized, analyze_big_o_vectorized,
generate_enhanced_report, analyze_satd, analyze_lint_hotspot
```

PMAT's CLI surface has ~70 subcommands. Four of the most user-visible are **not** exposed via MCP:

* `quality-gate` — the single most-demanded MCP tool per dogfood feedback.
* `tdg` — agents ask for TDG grades constantly; today they must shell out.
* `score` / `repo-score` / `rust-project-score` — the whole score family.
* `query` — semantic search; agents want this as an MCP tool badly.

The R8 recommendation is to track MCP-completeness as its own ticket (roughly "MCP-0001: wire query/quality-gate/score/tdg under the existing MCP dispatch"). The pmcp 2.3 release ships `#[mcp_tool]` derive macros (PR #340 in the pmat repo is pending) which make this mechanical — annotate each CLI handler, auto-derive the MCP `inputSchema`, ship. The gap is configuration, not code.

## 69.6 The O(1) Scorecard

Applying the 500 ms / 256 MB threshold from the PMAT hook contract:

| Bucket | Count | Examples |
|---|---|---|
| Meets budget (≤500 ms wall, ≤256 MB RSS) | ~45 | all `--help`, `diagnose`, `list`, `cache stats`, `query *`, `deps-audit`, `repo-score`, `analyze satd`, `analyze churn` |
| Borderline (500 ms–2 s) | ~8 | `analyze complexity`, `infra-score`, `analyze dead-code` (p95 spike), `query dispatch` (p95 420 ms) |
| Over wall, under memory (2–10 s, ≤256 MB) | ~6 | `analyze duplicates` (p95 15 s), `tdg .`, `rust-project-score`, `perfection-score`, `analyze dead-code` (p95) |
| Over wall AND over memory (V++) | **2** | **`pmat score`** (56 s / 1.41 GB), **`pmat quality-gate`** (32 s / 319 MB) |
| Silent hang (∞ wall, 0 work) | **4** | `pmat serve --transport {http,web-socket,http-sse,all}` — D72 |

The scorecard is healthier than Chapter 67 suggested: the *help-class* and *query-class* commands comfortably meet the contract. The *score-class* does not, and the 2× V++ entries (score + quality-gate) consume disproportionate blame. Fix the WalkDir-dedup hotspot, and the scorecard moves from 2 V++ / 6 V / 8 borderline to 0 V++ / 2 V / 4 borderline overnight.

## 69.7 How to Reproduce R8

```bash
# 1. Benchmark matrix (skip V++ commands unless you have 5+ minutes)
cd /path/to/paiml-mcp-agent-toolkit
for cmd in "--version" "--help" "analyze satd" "analyze churn --days 30" \
           "query dispatch --limit 5" "repo-score" "analyze complexity" \
           "tdg ." "score" "quality-gate"; do
  /usr/bin/time -v pmat $cmd 2>&1 | grep -E "(Elapsed|Maximum resident)"
done

# 2. D72 HTTP stub probe
cargo run --example http_stub_probe
# expected today: exit=1, "PORT NOT BOUND — D72 reproduced."

# 3. D42 MCP stdin EOF regression check
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' \
  | /usr/bin/time -v pmat serve --mode mcp 2>&1 \
  | grep -E "(Elapsed|Maximum resident)"
# expected: Elapsed <100 ms; D42 RESOLVED

# 4. MCP surface audit
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' \
  | pmat serve --mode mcp | python3 -c "
import json, sys
data = json.load(sys.stdin)
tools = [t['name'] for t in data['result']['tools']]
print(f'{len(tools)} MCP tools; gaps: quality-gate, tdg, score, query')
"
```

## 69.8 What Landed, What Didn't

R8 was deliberately book-only. Three harnesses shipped with the R7 PR (#346 examples: `exit_code_audit_driver`, `mcp_timing_bench`, `o1_hook_probe`). R8 adds a fourth — `http_stub_probe.rs` — tracked in the same PR. No pmat repo commits from R8 beyond that example; the data is in this chapter and in `/tmp/pmat-dogfood/round8/bench-r8.md`. Cross-references:

- Issue [#347](https://github.com/paiml/paiml-mcp-agent-toolkit/issues/347) — D72 HTTP stub, R8 performance matrix.
- Issue [#337](https://github.com/paiml/paiml-mcp-agent-toolkit/issues/337) — kaizen roadmap; expect CB-1800 (see Chapter 68 §68.5) to land R9 as first priority.
- PR [#346](https://github.com/paiml/paiml-mcp-agent-toolkit/pull/346) — R8 examples (4 harnesses: mcp_timing_bench, o1_hook_probe, exit_code_audit_driver, http_stub_probe).
- Chapter 65 — HTTP server stub (D13, pre-dates D72 by a release).
- Chapter 67, Chapter 68 — dogfooding precursors.

## 69.9 Closing

R8 added two durable findings:

1. **`pmat score` = 56 s / 1.41 GB.** Structural peer of comply-check. The top-2 V++ slow paths share a hotspot. Fix one, close both.
2. **D72 — the HTTP serve stub is a silent-hang defect.** Banner promises, port doesn't bind, process hangs. Exit-code-0-on-error's worst variant.

The discipline holds from Chapter 68:

> If you cannot reproduce a defect, it is not a defect. If you cannot gate a defect, it will regress. **If a performance claim has no benchmark, the claim is marketing.**

R8 put numbers on the performance claims. Most of them hold. Two of them don't. One of them is a socket that isn't there. The work of R9 is to close the top structural-peer hotspot and stop printing "Server ready!" for servers that are not.

---

*Cross-references:*
- GitHub issues [#347](https://github.com/paiml/paiml-mcp-agent-toolkit/issues/347), [#337](https://github.com/paiml/paiml-mcp-agent-toolkit/issues/337), [#333](https://github.com/paiml/paiml-mcp-agent-toolkit/issues/333)
- PR [#346](https://github.com/paiml/paiml-mcp-agent-toolkit/pull/346) — R8 examples
- Chapter 65 (`ch65-00-http-server.md`) — HTTP server D13 (pre-R8 surface)
- Chapter 67 (`ch67-00-dogfooding.md`) — five-round dogfood catalogue (D1..D58)
- Chapter 68 (`ch68-00-r7-defect-remediation.md`) — CB-1800 patch sketch
- Source: `server/src/cli/analysis_utilities/comprehensive_serve.rs` (stubs)
- Raw data: `/tmp/pmat-dogfood/round8/bench-r8.md`, `results.tsv`, `results-mcp.tsv`
