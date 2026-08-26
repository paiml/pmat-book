# Chapter 24: Memory and Cache Management

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ Verified against pmat 3.32.0

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 17 | Executed against pmat 3.32.0; output pasted verbatim |
| ⚠️ Not Implemented | 0 | — |
| ❌ Broken | 0 | — |
| 📋 Planned | 0 | — |

*Last updated: 2026-08-25*
*PMAT version: pmat 3.32.0*
<!-- DOC_STATUS_END -->

> **What changed in this rewrite, and read the first bullet before you use these
> commands for anything.**
>
> - **`pmat memory` measures the process you just started, which has done no
>   work.** Every counter reads 0 B, always. `pmat` itself says so in the output:
>   *"No allocations were recorded in this process: `pmat memory` reads the
>   in-process pool manager, which starts empty, so these counters measure
>   nothing."* It cannot observe a previous `pmat analyze` run, and it is not a
>   profiler for your application. The one part of this chapter that reports a
>   real number is `pmat cache stats`'s on-disk section.
> - **`pmat cache` has exactly one subcommand: `stats`.** The 2025 edition
>   documented `optimize`, `analyze`, `recommend`, `clear`, `warmup` and
>   `configure`; none is a subcommand and each exits 2 with "unrecognized
>   subcommand". There is no cache-clearing command — delete `.pmat/` by hand.
> - **Six `pmat memory` subcommands never existed**: `profile`, `dump`,
>   `monitor`, `analyze`, `track`, plus the `memory analyze --check-leaks` /
>   `--leaks` forms. There is no leak detector and no heap dump.
> - **Sixteen flags never existed** on the subcommands that do: `--force-gc`,
>   `--max-heap`, `--string-pool`, `--object-pool`, `--gc-threshold`,
>   `--detailed` (on `pools`), `--fragmentation`, `--monitor`, `--warning`,
>   `--critical`, `--perf`, `--top-consumers`, `--aggressive`, `--reduce-pools`,
>   `--type`, `--patterns`.
>
> The "Sprint 56 clippy optimization" section, with its per-project-size
> performance tables, has been removed: it documented numbers no command in this
> chapter can produce.

## What These Commands Actually Report

pmat's CLI is one process per invocation. `pmat memory stats` starts a process,
initialises an empty pool manager, prints its counters, and exits. There is no
daemon, no shared memory, and no persisted allocation log, so the counters
describe a process that has allocated nothing.

`pmat` is candid about this rather than printing a confident zero, and that
candour is the useful part: a `0 B` here means "not measured", not "your
analysis used no memory".

## Memory Statistics

```bash
pmat memory stats
```

```
PMAT Memory Statistics

Overall Memory Usage:
  Total Allocated: 0 B
  Peak Usage: 0 B
  Pressure: 0.0%
  String Intern: 0 B

Recommendations:
  No allocations were recorded in this process: `pmat memory` reads the in-process pool manager, which starts empty, so these counters measure nothing.
```

`--verbose` adds tracing but not data:

```bash
pmat memory stats --verbose
```

```
2026-08-25T20:53:09.203296Z  INFO Starting PAIML MCP Agent Toolkit v3.32.0
2026-08-25T20:53:09.203437Z  INFO Running in CLI mode
2026-08-25T20:53:09.205430Z  INFO Initializing global memory manager
PMAT Memory Statistics

Overall Memory Usage:
  Total Allocated: 0 B
  Peak Usage: 0 B
  Pressure: 0.0%
  String Intern: 0 B
```

The `Initializing global memory manager` line is the whole story: the manager is
created by this command, for this command.

### To actually measure pmat's memory

Use the operating system, or `pmat test memory` (see
[Chapter 23](ch23-00-testing.md)), which forks a real workload and measures peak
RSS:

```bash
/usr/bin/time -v pmat analyze complexity 2>&1 | grep "Maximum resident"
pmat test memory
```

`pmat test memory` reports a real figure — 186,620 KB for 20K LOC on the machine
used for this book.

## Memory Pools

```bash
pmat memory pools
```

```
Memory Pool Statistics

No allocations were recorded in this process: `pmat memory` reads the in-process pool manager, which starts empty, so these counters measure nothing.

AstParsing:
  Buffers: 0
  Total Size: 0 B
  Allocations: 0
  Reuses: 0

FileContent:
  Buffers: 0
  Total Size: 0 B
  Allocations: 0
  Reuses: 0

StringIntern:
  Buffers: 0
  Total Size: 0 B
  Allocations: 0
```

The pool names — `AstParsing`, `FileContent`, `StringIntern` — are the useful
output here: they tell you how `pmat` partitions its allocations, even though the
counts are all zero.

`--pool <POOL>` focuses on one, and `--efficiency` adds derived ratios:

```bash
pmat memory pools --efficiency
```

```
  Buffers: 0
  Total Size: 0 B
  Allocations: 0
  Reuses: 0
  Reuse Ratio: 0.0%
  Avg Buffer: 0 B
  Efficiency: Poor
```

`Efficiency: Poor` is computed from a zero reuse ratio over zero allocations.
Do not report it as a finding.

## Memory Pressure

```bash
pmat memory pressure
```

```
Current memory pressure: not measured
No allocations were recorded in this process: `pmat memory` reads the in-process pool manager, which starts empty, so these counters measure nothing.
```

Note that it prints **`not measured`**, not `0.0%`. That is the right answer,
and it is the distinction the rest of this chapter turns on.

`--threshold <0.0-1.0>` (default 0.8) sets the warning level and `--watch
<SECONDS>` polls continuously:

```bash
pmat memory pressure --threshold 0.5
```

```
Current memory pressure: not measured
No allocations were recorded in this process: `pmat memory` reads the in-process pool manager, which starts empty, so these counters measure nothing.
```

## Memory Cleanup

```bash
pmat memory cleanup
```

```
Cleaned 0 B of memory
```

`--target-pressure <0.0-1.0>` and `--verbose` are the only options:

```bash
pmat memory cleanup --target-pressure 0.5
```

```
Cleaned 0 B of memory
```

There is no `--force-gc` and no `--aggressive`; Rust has no runtime GC to force.

## Memory Configuration

`pmat memory configure` accepts three options — `--max-memory-mb`,
`--pool-limits <pool:size_mb>` and `--enable-tracking <true|false>` — and tells
you plainly that two of them do not take effect:

```bash
pmat memory configure --max-memory-mb 500
```

```
Memory configuration:
  Maximum memory: 500 MB
  Note: Runtime reconfiguration not yet supported
```

```bash
pmat memory configure --pool-limits "AstParsing:64"
```

```
Memory configuration:
  Pool limits:
    AstParsing:64
  Note: Runtime pool reconfiguration not yet supported
```

```bash
pmat memory configure --enable-tracking true
```

```
Memory configuration:
  Memory tracking: enabled
```

Only the third produces no "not yet supported" note, and since the setting dies
with the process it has no effect on a later invocation either.

## Cache Statistics

`pmat cache stats` is the one command in this chapter that reports something
real — in its second section.

```bash
pmat cache stats
```

In a project `pmat` has never analysed:

```
PMAT Cache Statistics
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Orchestrator (this process):
   Strategy Switches: 0
   Evaluations: 0
   Overall Effectiveness: not measured (no cache evaluations in this process)

On-disk caches under /path/to/project:
   none found
```

In a project with caches on disk:

```
PMAT Cache Statistics
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Orchestrator (this process):
   Strategy Switches: 0
   Evaluations: 0
   Overall Effectiveness: not measured (no cache evaluations in this process)

On-disk caches under /home/noah/src/paiml-mcp-agent-toolkit:
   /home/noah/src/paiml-mcp-agent-toolkit/.pmat: 36 file(s), 725.6 MB
   /home/noah/src/paiml-mcp-agent-toolkit/.pmat-cache: 1 file(s), 0.0 MB
```

**That is a real measurement**, and a useful one — 725.6 MB of cache is worth
knowing about. The "Orchestrator (this process)" section above it is the same
in-process illusion as `pmat memory`, and says so.

### Options

`--format json` for tooling:

```bash
pmat cache stats --format json
```

```json
{
  "orchestrator_stats": {
    "strategy_switches": 0,
    "evaluations_performed": 0,
    "recommendations_generated": 0,
    "performance_improvements": 0,
    "overall_effectiveness": null
  },
  "on_disk_caches": []
}
```

`overall_effectiveness` is `null` rather than `0.0` — again, "not measured", not
"zero".

`--detailed` adds one line, which is another honest refusal:

```bash
pmat cache stats --detailed
```

```
Detailed Analysis:
   Per-tier hit rates require a live cache session; the CLI process has none.
```

`--history` includes historical data. The full option list is `--detailed`,
`--format <json|table>` and `--history`. There is no `--perf`.

## Clearing the Cache

There is no `pmat cache clear`. To reclaim the 725.6 MB above:

```bash
rm -rf .pmat .pmat-cache
pmat cache stats     # confirm: "none found"
```

`pmat` rebuilds what it needs on the next analysis.

## Complete Command Reference

| Command | Options | Reports real data? |
|---------|---------|--------------------|
| `pmat memory stats` | `--verbose` | No — always 0 B |
| `pmat memory pools` | `--pool`, `--efficiency` | No — pool *names* only |
| `pmat memory pressure` | `--threshold`, `--watch` | No — "not measured" |
| `pmat memory cleanup` | `--target-pressure`, `--verbose` | No — always 0 B |
| `pmat memory configure` | `--max-memory-mb`, `--pool-limits`, `--enable-tracking` | Echoes input; two are no-ops |
| `pmat cache stats` | `--detailed`, `--format`, `--history` | **Yes** — the on-disk section |

## Integration and Monitoring

The only figure worth putting in CI is cache size:

```bash
pmat cache stats --format json > cache-stats.json
```

Before-and-after captures work for the on-disk section:

```bash
pmat cache stats --verbose > cache-before.txt
pmat cache stats --verbose > cache-after.txt
diff cache-before.txt cache-after.txt
```

For pmat's own memory behaviour, gate on `pmat test memory`
([Chapter 23](ch23-00-testing.md)) or on `/usr/bin/time -v`, not on
`pmat memory stats`.

## Troubleshooting

### Every memory number is 0 B

Working as designed. `pmat memory` reads the in-process pool manager of the
command you just ran. Use `pmat test memory` or `/usr/bin/time -v`.

### `error: unrecognized subcommand` from `pmat cache clear`

`stats` is the only `cache` subcommand. Delete `.pmat/` and `.pmat-cache/`
directly.

### `Efficiency: Poor` from `memory pools --efficiency`

Derived from a zero reuse ratio over zero allocations. It is not a finding.

### `pmat memory configure` says "not yet supported"

`--max-memory-mb` and `--pool-limits` are echoed and discarded. Nothing in this
command persists past the process.

## Summary

`pmat memory` is a window onto an empty room, and it tells you so on every line.
`pmat cache stats` is half useful: its on-disk section reports genuine cache
sizes on disk, while its orchestrator section is the same in-process nothing.

Key takeaways:
- `pmat memory` cannot measure a previous run, your application, or anything
  else. Reach for `pmat test memory` or `/usr/bin/time -v`.
- `pmat cache stats`'s on-disk section is the one real measurement here.
- `cache` has one subcommand; `memory` has five. Everything else the previous
  edition documented exits 2.
- `pmat` distinguishes "not measured" from "zero" throughout this surface. Preserve
  that distinction when you report these numbers onward.
