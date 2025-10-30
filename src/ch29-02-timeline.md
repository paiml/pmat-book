# 29.2 Timeline Playback

The `pmat debug timeline` command provides interactive timeline playback for recorded executions. You can navigate through execution history, inspect variable states, and understand program flow.

## Basic Usage

```bash
# Play back a recording
pmat debug timeline fibonacci.pmat

# Jump to specific frame
pmat debug replay fibonacci.pmat --position 50
```

## Example Output

```
⏱️  Timeline Playback...
   Recording: fibonacci.pmat

📋 Recording Metadata:
   Program: fibonacci
   Snapshots: 127

🎮 Timeline Player created
   Frame 0/127

📊 Frame Info:
   Frame 0/127
   Location: fibonacci.rs:2
   Variables: 1
      n = 0

✅ Timeline playback ready
   [Interactive UI would appear here - Sprint 77 TIMELINE-002]
```

## TDD Example: Debugging Off-by-One Error

Let's use timeline playback to debug a classic off-by-one error.

### Step 1: Buggy Code

```rust
fn sum_array(arr: &[i32]) -> i32 {
    let mut sum = 0;
    // BUG: Should be `i < arr.len()`, not `i <= arr.len()`
    for i in 0..=arr.len() {
        sum += arr[i];  // Will panic on last iteration!
    }
    sum
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sum_array() {
        let arr = vec![1, 2, 3, 4, 5];
        assert_eq!(sum_array(&arr), 15);
    }
}
```

###  Step 2: Record Failing Test

```bash
# Start recording server
pmat debug serve --port 5678 --record-dir ./bug-recordings

# Run test with debugger (in VSCode, set breakpoint in sum_array)
# Test will panic on arr[5] (index out of bounds)
```

### Step 3: Play Back Timeline

```bash
$ pmat debug timeline bug-recordings/sum_array-panic.pmat

📊 Frame Info:
   Frame 0/8
   Variables: 3
      arr = [1, 2, 3, 4, 5]
      sum = 0
      i = 0

# Navigate forward: i=0 -> i=1 -> i=2 -> i=3 -> i=4 -> i=5
# Frame 5:
   Variables: 3
      arr = [1, 2, 3, 4, 5]
      sum = 15
      i = 5  # ⚠️ BUG: i should never equal arr.len()!

# Frame 6: PANIC
   Location: fibonacci.rs:5
   Error: index out of bounds: the len is 5 but the index is 5
```

### Step 4: Fix the Bug

```rust
fn sum_array(arr: &[i32]) -> i32 {
    let mut sum = 0;
    // FIX: Use `i < arr.len()` instead of `i <= arr.len()`
    for i in 0..arr.len() {
        sum += arr[i];
    }
    sum
}
```

## TimelinePlayer API

The timeline player provides programmatic access to recorded execution:

```rust
use pmat::services::dap::{Recording, TimelinePlayer};

// Load recording
let recording = Recording::load_from_file("trace.pmat")?;

// Create player
let mut player = TimelinePlayer::new(recording);

// Navigate
assert_eq!(player.current_frame(), 0);
player.next_frame();  // Advance to frame 1
player.jump_to(50);   // Jump to frame 50
player.prev_frame();  // Go back to frame 49

// Inspect state
let snapshot = player.current_snapshot();
println!("Variables: {:?}", snapshot.variables);
println!("Stack: {:?}", snapshot.stack_frames);
```

## TimelineUI Features

The TimelineUI provides terminal-based visualization:

```rust
use pmat::services::dap::{TimelinePlayer, TimelineUI};

let player = TimelinePlayer::new(recording);
let ui = TimelineUI::from_player(player);

// Display current state
println!("{}", ui.progress_text());  // "Frame 0/127"

// Access current variables
let vars = ui.current_variables();
for (name, value) in vars {
    println!("{} = {}", name, value);
}

// Get stack frames
let frames = ui.current_stack_frames();
for (i, frame) in frames.iter().enumerate() {
    println!("#{} {} @ {}:{}", i, frame.name,
        frame.file.as_ref().unwrap_or(&"?".to_string()),
        frame.line.unwrap_or(0));
}
```

## Keyboard Navigation (Sprint 77 TIMELINE-002)

Future interactive UI will support:

| Key | Action |
|-----|--------|
| `→` | Next frame |
| `←` | Previous frame |
| `Space` | Play/Pause auto-advance |
| `Home` | Jump to first frame |
| `End` | Jump to last frame |
| `g` | Go to specific frame |
| `q` | Quit |

## Performance Analysis

Timeline playback includes timing information:

```rust
let snapshot = player.current_snapshot();
let elapsed_ms = snapshot.timestamp_relative_ms;

println!("Elapsed time: {}ms", elapsed_ms);
```

Example output:

```
Frame 0: 0ms (start)
Frame 10: 5ms (+5ms)
Frame 50: 127ms (+122ms)  # Slow section identified
Frame 100: 150ms (+23ms)
```

## Use Cases

### 1. Understanding Recursion

```rust
fn factorial(n: u64) -> u64 {
    if n <= 1 {
        1
    } else {
        n * factorial(n - 1)
    }
}

// Record factorial(5)
// Timeline shows call stack growing:
// Frame 0: factorial(5)
// Frame 1: factorial(5) -> factorial(4)
// Frame 2: factorial(5) -> factorial(4) -> factorial(3)
// ...
```

### 2. Loop Iteration Analysis

```rust
for i in 0..100 {
    if condition(i) {
        do_work(i);  // How many times is this called?
    }
}

// Timeline shows: do_work() called 23 times out of 100 iterations
```

### 3. Performance Bottlenecks

```rust
// Which function takes the most time?
// Timeline timestamps reveal:
// parse_input(): 5ms
// process_data(): 450ms  # ⚠️ Bottleneck!
// write_output(): 2ms
```

## Next Steps

Learn how to [compare two execution traces](ch29-03-comparison.md) to find regression causes.
