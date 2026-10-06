# 29.1 Recording Execution

> **Not implemented.** No command on this page works in pmat 3.42.0.
> `pmat debug serve` and `pmat debug replay` exit 2 with
> `error: pmat debug serve is not implemented (DEBUG-002)` and
> `error: pmat debug replay is not implemented (DEBUG-003)`;
> `pmat debug timeline` and `pmat debug compare` do not exist
> (`error: unrecognized subcommand 'timeline'` or `'compare'`, exit 2). The
> page is a design sketch; see the [chapter status](ch29-00-time-travel-debugging.md).

## Starting a DAP Server with Recording

The `pmat debug serve` command starts a Debug Adapter Protocol (DAP) server that debuggers can connect to. When you enable recording, all execution traces are saved to `.pmat` files.

### Basic Usage

```bash
# Start DAP server without recording
pmat debug serve --port 5678

# Start DAP server WITH recording
pmat debug serve --port 5678 --record-dir ./recordings
```

### Example Output

```
🔍 Starting DAP server...
   Host: 127.0.0.1
   Port: 5678
   Recording: enabled
   Record directory: ./recordings

Connect your debugger to: 127.0.0.1:5678
Press Ctrl+C to stop the server
```

## Recording Structure

When recording is enabled, PMAT saves execution traces in the specified directory:

```
recordings/
├── program-2025-10-30T14-23-45.pmat     # Timestamped recording
├── program-2025-10-30T14-24-12.pmat
└── bugfix-test-2025-10-30T15-00-00.pmat
```

## TDD Example: Recording a Simple Program

Let's record execution of a Rust program that calculates Fibonacci numbers.

### Step 1: Write the Program

Create `fibonacci.rs`:

```rust
fn fibonacci(n: u32) -> u64 {
    match n {
        0 => 0,
        1 => 1,
        _ => fibonacci(n - 1) + fibonacci(n - 2),
    }
}

fn main() {
    println!("Fibonacci sequence:");
    for i in 0..10 {
        println!("F({}) = {}", i, fibonacci(i));
    }
}
```

### Step 2: Start Recording Server

```bash
# Terminal 1: Start PMAT DAP server with recording
pmat debug serve --port 5678 --record-dir ./fib-recordings
```

### Step 3: Debug with VSCode

Add `.vscode/launch.json`:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "type": "lldb",
            "request": "launch",
            "name": "Debug Fibonacci",
            "program": "${workspaceFolder}/target/debug/fibonacci",
            "args": [],
            "cwd": "${workspaceFolder}",
            "debugServer": 5678
        }
    ]
}
```

### Step 4: Run Debugger

1. Set breakpoints in `fibonacci()` function
2. Start debugging (F5 in VSCode)
3. Step through execution
4. PMAT records every state transition

### Step 5: Verify Recording

```bash
$ ls -lh fib-recordings/
-rw-r--r-- 1 user user 45K Oct 30 14:23 fibonacci-2025-10-30T14-23-45.pmat
```

## What Gets Recorded?

Each `.pmat` file contains:

1. **Metadata**
   - Program name
   - Command-line arguments
   - Timestamp
   - Environment variables

2. **Snapshots** (one per execution step)
   - Variable values (locals and globals)
   - Stack frames with source location
   - Instruction pointer
   - Relative timestamp

3. **Optional**
   - Memory snapshots (configurable)
   - Register states
   - Heap allocations

## Compression

`.pmat` files use MessagePack binary format with optional compression:

```bash
# Check recording size
$ ls -lh fibonacci.pmat
-rw-r--r-- 1 user user 45K Oct 30 14:23 fibonacci.pmat

# Extract metadata
$ pmat debug replay fibonacci.pmat --metadata-only
📋 Recording Metadata:
   Program: fibonacci
   Arguments: []
   Recorded: 2025-10-30T14:23:45Z
   Snapshots: 127
```

## Best Practices

### ✅ DO:
- Use descriptive `--record-dir` names (`./bug-123-recordings`)
- Record short, focused debugging sessions
- Clean up old recordings regularly

### ❌ DON'T:
- Record long-running applications (large .pmat files)
- Record in production environments (performance impact)
- Share recordings with sensitive data (contains variable values)

## Performance Impact

Recording has minimal overhead:

| Metric | Without Recording | With Recording |
|--------|------------------|----------------|
| Execution Time | 1.0x | 1.05x - 1.15x |
| Memory Usage | 1.0x | 1.2x - 1.5x |
| Disk I/O | None | 1-5 MB/min |

## Next Steps

Now that you have recordings, learn how to:
- [Play back execution timelines](ch29-02-timeline.md)
- [Compare different executions](ch29-03-comparison.md)
