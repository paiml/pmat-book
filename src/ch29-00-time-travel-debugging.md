# Chapter 29: Time-Travel Debugging and Execution Tracing

<!-- DOC_STATUS_START -->
**Chapter Status**: ⚠️ Not Implemented (0/4 commands work)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 0 | |
| ⚠️ Not Implemented | 2 | `pmat debug serve`, `pmat debug replay`: both exit 2 |
| ❌ Broken | 2 | `pmat debug timeline`, `pmat debug compare`: no such subcommand |
| 📋 Planned | 0 | |

*Last updated: 2026-10-06*
*PMAT version: pmat 3.42.0*
<!-- DOC_STATUS_END -->

> **Not implemented.** No command in this chapter works in pmat 3.42.0.
> `pmat debug` has two subcommands, `serve` and `replay`, and both say
> `[NOT IMPLEMENTED]` in their own `--help` and exit 2 (`DEBUG-002`,
> `DEBUG-003`). `pmat debug timeline` and `pmat debug compare` do not exist:
> `error: unrecognized subcommand 'timeline'` (or `'compare'`), exit 2. Because
> every worked example starts by recording a trace with `pmat debug serve`, no
> reader can produce a `.pmat` file to feed the later steps. Read this chapter and its four sections as a
> design sketch of a feature that has not shipped, not as instructions.

PMAT's time-travel debugging capabilities allow you to record program execution, play back execution timelines, and compare different execution traces side-by-side. This powerful feature enables post-mortem debugging, regression analysis, and understanding complex execution flows.

## What is Time-Travel Debugging?

Time-travel debugging records a complete execution trace of your program, capturing:
- Variable states at each execution point
- Stack frames and call hierarchy
- Instruction pointers and memory snapshots
- Timestamps for performance analysis

Once recorded, you can:
- **Replay** execution forward and backward
- **Compare** two execution traces to find divergence points
- **Analyze** execution flow without re-running the program
- **Share** execution recordings for collaborative debugging

## Sprint 77 Features

PMAT's time-travel debugging was developed through **EXTREME TDD** in Sprint 77:

- **TIMELINE-001**: TimelinePlayer - Playback control for recordings
- **TIMELINE-002**: TimelineUI - Terminal-based visualization
- **TIMELINE-003**: ComparisonView - Side-by-side trace comparison
- **TIMELINE-004**: CLI Integration - User-facing commands

## Recording Format (.pmat)

Execution recordings are stored in `.pmat` files using MessagePack binary serialization:

```rust
struct Recording {
    metadata: RecordingMetadata,
    snapshots: Vec<Snapshot>,
}

struct Snapshot {
    frame_id: u64,
    timestamp_relative_ms: u32,
    variables: HashMap<String, serde_json::Value>,
    stack_frames: Vec<StackFrame>,
    instruction_pointer: u64,
    memory_snapshot: Option<Vec<u8>>,
}
```

## Commands Overview

| Command | Purpose | Usage | pmat 3.42.0 |
|---------|---------|-------|-------------|
| `pmat debug serve` | Start DAP server with recording | `pmat debug serve --record-dir ./recordings` | not implemented: `error: pmat debug serve is not implemented (DEBUG-002)`, exit 2 |
| `pmat debug replay` | Replay a recording | `pmat debug replay recording.pmat` | not implemented: `error: pmat debug replay is not implemented (DEBUG-003)`, exit 2 |
| `pmat debug timeline` | Interactive timeline playback | `pmat debug timeline recording.pmat` | does not exist: `error: unrecognized subcommand 'timeline'`, exit 2 |
| `pmat debug compare` | Compare two recordings | `pmat debug compare trace1.pmat trace2.pmat` | does not exist: `error: unrecognized subcommand 'compare'`, exit 2 |

## Sections

- [29.1 Recording Execution](ch29-01-recording.md)
- [29.2 Timeline Playback](ch29-02-timeline.md)
- [29.3 Comparing Executions](ch29-03-comparison.md)
- [29.4 TDD Examples](ch29-04-tdd-examples.md)
