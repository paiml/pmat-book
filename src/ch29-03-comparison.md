# 29.3 Comparing Executions

The `pmat debug compare` command performs side-by-side comparison of two execution traces, highlighting differences to find regression causes, behavior changes, or divergence points.

## Basic Usage

```bash
# Compare two recordings
pmat debug compare working.pmat broken.pmat

# Compare before and after a code change
pmat debug compare v1.0-trace.pmat v1.1-trace.pmat
```

## Example Output

```
🔀 Comparing Recordings...
   Recording A: working.pmat
   Recording B: broken.pmat

📋 Recording Metadata:
   Recording A: fibonacci (127 snapshots)
   Recording B: fibonacci (127 snapshots)

🎮 ComparisonView created

📊 Split View:
Recording A: fibonacci    |    Recording B: fibonacci
Frame 0/127          |    Frame 0/127

🔍 Variable Differences:
   ✓ n
   ✓ result
   ~ accumulator  # Modified

⚠️  Divergence detected at frame 23

✅ Comparison complete
```

## TDD Example: Finding a Regression

Let's use comparison to find a regression introduced by a performance optimization.

### Step 1: Original Working Code

```rust
// v1.0: Working but slow
fn calculate_primes(max: u32) -> Vec<u32> {
    let mut primes = Vec::new();
    for n in 2..=max {
        if is_prime(n) {
            primes.push(n);
        }
    }
    primes
}

fn is_prime(n: u32) -> bool {
    if n < 2 {
        return false;
    }
    for i in 2..n {
        if n % i == 0 {
            return false;
        }
    }
    true
}
```

### Step 2: "Optimized" Code with Bug

```rust
// v1.1: Optimized but broken
fn calculate_primes(max: u32) -> Vec<u32> {
    let mut primes = Vec::new();
    for n in 2..=max {
        if is_prime_optimized(n) {
            primes.push(n);
        }
    }
    primes
}

fn is_prime_optimized(n: u32) -> bool {
    if n < 2 {
        return false;
    }
    // BUG: Should check up to sqrt(n), not n/2
    for i in 2..=(n / 2) {
        if n % i == 0 {
            return false;
        }
    }
    true
}
```

### Step 3: Record Both Versions

```bash
# Record v1.0
pmat debug serve --port 5678 --record-dir ./v1.0-recordings
# Run tests, stop server

# Record v1.1
pmat debug serve --port 5678 --record-dir ./v1.1-recordings
# Run same tests, stop server
```

### Step 4: Compare Traces

```bash
$ pmat debug compare v1.0-recordings/primes.pmat v1.1-recordings/primes.pmat

⚠️  Divergence detected at frame 15

Frame 15 Variable Diff:
Recording A                |    Recording B
n = 9                      |    n = 9
is_prime_result = false    |    is_prime_result = true  # ⚠️ WRONG!
primes = [2, 3, 5, 7]      |    primes = [2, 3, 5, 7, 9]  # BUG: 9 is not prime!
```

The comparison reveals that v1.1 incorrectly identifies 9 as prime, causing the divergence!

## ComparisonView API

```rust
use pmat::services::dap::ComparisonView;

// Load both recordings
let recording_a = Recording::load_from_file("v1.0.pmat")?;
let recording_b = Recording::load_from_file("v1.1.pmat")?;

// Create comparison
let mut comparison = ComparisonView::new(recording_a, recording_b);

// Navigate (synchronized by default)
comparison.next_frame()?;    // Both advance to frame 1
comparison.jump_to(50)?;     // Both jump to frame 50

// Get current frames
assert_eq!(comparison.current_frame_a(), 50);
assert_eq!(comparison.current_frame_b(), 50);
```

## Variable Diff Analysis

The comparison view highlights variable differences:

```rust
use pmat::services::dap::DiffStatus;

let diff = comparison.variable_diff();

for (name, status) in &diff {
    match status {
        DiffStatus::Same => println!("✓ {} (identical)", name),
        DiffStatus::Modified => println!("~ {} (changed)", name),
        DiffStatus::Added => println!("+ {} (only in B)", name),
        DiffStatus::Removed => println!("- {} (only in A)", name),
    }
}
```

Example output:

```
✓ n (identical)
✓ max (identical)
~ primes (changed)
  A: [2, 3, 5, 7, 11]
  B: [2, 3, 5, 7, 9, 11]
+ optimization_flag (only in B)
```

## Synchronization Modes

ComparisonView supports different sync strategies:

```rust
use pmat::services::dap::SyncMode;

// Sync by frame number (default)
comparison.set_sync_mode(SyncMode::ByFrame);
// Frame 0 in A matches Frame 0 in B

// Sync by timestamp
comparison.set_sync_mode(SyncMode::ByTimestamp);
// Match frames by elapsed time (handles different execution speeds)

// Sync by source location
comparison.set_sync_mode(SyncMode::ByLocation);
// Match frames by file:line position (handles reorderings)
```

### Example: Different Execution Speeds

```rust
// Recording A: Debug build (slow)
// Frame 0: 0ms, Frame 10: 100ms, Frame 20: 200ms

// Recording B: Release build (fast)
// Frame 0: 0ms, Frame 10: 30ms, Frame 20: 60ms

// ByFrame sync:
//   Frame 10A (100ms) <-> Frame 10B (30ms)
//   Compares different timestamps

// ByTimestamp sync:
//   Frame 10A (100ms) <-> Frame 33B (~100ms)
//   Compares similar execution points
```

## Split View Rendering

```rust
let output = comparison.render_split();
println!("{}", output);
```

Output:

```
Recording A: v1.0    |    Recording B: v1.1
Frame 0/127          |    Frame 0/127

Variables:
n = 2                |    n = 2
max = 100            |    max = 100
primes = []          |    primes = []
```

## Finding Divergence Points

```rust
// Automatically find first difference
if let Some(frame) = comparison.find_divergence_point() {
    println!("⚠️  Divergence at frame {}", frame);
    comparison.jump_to(frame)?;

    // Inspect the diff
    let diff = comparison.variable_diff();
    for (name, status) in &diff {
        if *status != DiffStatus::Same {
            println!("Variable '{}' differs: {:?}", name, status);
        }
    }
} else {
    println!("✅ Recordings are identical");
}
```

## Export Diff Report

```rust
// Generate JSON diff report
let json_report = comparison.export_diff_json()?;
std::fs::write("diff-report.json", json_report)?;
```

Report structure:

```json
{
  "metadata": {
    "recording_a_name": "v1.0",
    "recording_b_name": "v1.1",
    "recording_a_frames": 127,
    "recording_b_frames": 127,
    "sync_mode": "ByFrame",
    "divergence_point": 15
  },
  "frame_diffs": [
    {
      "frame": 0,
      "variable_diff": {
        "n": "Same",
        "max": "Same"
      }
    },
    {
      "frame": 15,
      "variable_diff": {
        "n": "Same",
        "is_prime_result": "Modified",
        "primes": "Modified"
      }
    }
  ]
}
```

## Use Cases

### 1. Performance Regression Analysis

```bash
# Compare before/after optimization
pmat debug compare baseline.pmat optimized.pmat

# Check if behavior changed
# Timestamps reveal: optimized version is 3x faster
# Variable diffs show: same output
# ✅ Optimization successful!
```

### 2. Flaky Test Investigation

```bash
# Record passing run
pmat debug serve --record-dir ./pass

# Record failing run
pmat debug serve --record-dir ./fail

# Compare
pmat debug compare pass/test.pmat fail/test.pmat

# Find divergence: timing-dependent race condition revealed
```

### 3. Cross-Platform Behavior

```bash
# Record on Linux
pmat debug serve --record-dir ./linux-trace

# Record on macOS
pmat debug serve --record-dir ./macos-trace

# Compare
pmat debug compare linux-trace/app.pmat macos-trace/app.pmat

# Identify platform-specific differences
```

## Next Steps

See [TDD Examples](ch29-04-tdd-examples.md) for complete test-driven debugging workflows.
