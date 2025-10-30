# Chapter 29: Time-Travel Debugging and Execution Tracing

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

| Command | Purpose | Usage |
|---------|---------|-------|
| `pmat debug serve` | Start DAP server with recording | `pmat debug serve --record-dir ./recordings` |
| `pmat debug replay` | Replay a recording | `pmat debug replay recording.pmat` |
| `pmat debug timeline` | Interactive timeline playback | `pmat debug timeline recording.pmat` |
| `pmat debug compare` | Compare two recordings | `pmat debug compare trace1.pmat trace2.pmat` |

## Sections

- [29.1 Recording Execution](ch29-01-recording.md)
- [29.2 Timeline Playback](ch29-02-timeline.md)
- [29.3 Comparing Executions](ch29-03-comparison.md)
- [29.4 TDD Examples](ch29-04-tdd-examples.md)
