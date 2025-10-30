# 29.4 TDD Examples

This section demonstrates complete test-driven development workflows using PMAT's time-travel debugging features. All examples follow the **EXTREME TDD** methodology used to build these features in Sprint 77.

## Example 1: RED → GREEN → REFACTOR with Timeline Debugging

### RED Phase: Write Failing Test

```rust
// tests/calculator_tests.rs
#[test]
fn test_divide_by_zero_handling() {
    let calc = Calculator::new();
    let result = calc.divide(10, 0);

    // RED: This test will fail - divide() doesn't handle zero!
    assert!(result.is_err());
    assert_eq!(result.unwrap_err(), "Division by zero");
}
```

Run test:

```bash
$ cargo test test_divide_by_zero_handling

running 1 test
test test_divide_by_zero_handling ... FAILED

thread 'test_divide_by_zero_handling' panicked at 'attempt to divide by zero'
```

### Record the Failure

```bash
# Start recording server
pmat debug serve --port 5678 --record-dir ./tdd-recordings

# Run test with debugger (set breakpoint in Calculator::divide)
# Recording saved as: tdd-recordings/calculator-panic.pmat
```

### Analyze with Timeline

```bash
$ pmat debug timeline tdd-recordings/calculator-panic.pmat

Frame 0:
  method = "divide"
  dividend = 10
  divisor = 0

Frame 1: PANIC
  Error: attempt to divide by zero
  Location: calculator.rs:15
```

### GREEN Phase: Minimal Fix

```rust
// src/calculator.rs
impl Calculator {
    pub fn divide(&self, a: i32, b: i32) -> Result<i32, String> {
        if b == 0 {
            return Err("Division by zero".to_string());
        }
        Ok(a / b)
    }
}
```

Run test again:

```bash
$ cargo test test_divide_by_zero_handling

running 1 test
test test_divide_by_zero_handling ... ok  # ✅ GREEN!
```

### Record Success

```bash
# Record passing test
pmat debug serve --port 5678 --record-dir ./tdd-recordings

# Recording saved as: tdd-recordings/calculator-success.pmat
```

### Compare Before/After

```bash
$ pmat debug compare \
    tdd-recordings/calculator-panic.pmat \
    tdd-recordings/calculator-success.pmat

⚠️  Divergence at frame 1

Frame 1 Diff:
Recording A (panic)      |  Recording B (success)
result = None            |  result = Err("Division by zero")
execution = PANIC        |  execution = SUCCESS
```

### REFACTOR Phase: Extract Validation

```rust
impl Calculator {
    fn validate_divisor(&self, b: i32) -> Result<(), String> {
        if b == 0 {
            Err("Division by zero".to_string())
        } else {
            Ok(())
        }
    }

    pub fn divide(&self, a: i32, b: i32) -> Result<i32, String> {
        self.validate_divisor(b)?;
        Ok(a / b)
    }
}
```

Verify tests still pass:

```bash
$ cargo test
running 5 tests
test test_divide_by_zero_handling ... ok
test test_divide_positive ... ok
test test_divide_negative ... ok
test test_divide_rounding ... ok
test test_divide_large_numbers ... ok

test result: ok. 5 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out
```

## Example 2: Regression Debugging with Comparison

### The Bug Report

> "After upgrading to v2.0, sorting occasionally returns incorrect results for arrays with duplicates."

### RED: Write Regression Test

```rust
#[test]
fn test_sort_with_duplicates_regression() {
    let mut arr = vec![5, 2, 8, 2, 9, 1, 5];
    sort(&mut arr);

    assert_eq!(arr, vec![1, 2, 2, 5, 5, 8, 9]);
}
```

### Record Both Versions

```bash
# v1.0 (working)
git checkout v1.0
cargo build --release
pmat debug serve --record-dir ./v1.0-traces
# Run test → PASS

# v2.0 (broken)
git checkout v2.0
cargo build --release
pmat debug serve --record-dir ./v2.0-traces
# Run test → FAIL
```

### Compare Traces

```bash
$ pmat debug compare v1.0-traces/sort.pmat v2.0-traces/sort.pmat

⚠️  Divergence at frame 23

Frame 23:
v1.0                     |  v2.0
i = 3                    |  i = 3
j = 4                    |  j = 4
arr = [1, 2, 2, 5, 8]    |  arr = [1, 2, 5, 2, 8]  # ⚠️ Out of order!
swap_count = 3           |  swap_count = 2         # ⚠️ Missing swap!
```

Timeline shows v2.0 skipped a swap when encountering duplicate values!

### Root Cause in v2.0

```rust
// BUG: Should be `<=`, not `<`
if arr[j] < arr[j-1] {  // ⚠️ Skips duplicates!
    arr.swap(j, j-1);
}

// FIX:
if arr[j] <= arr[j-1] {
    arr.swap(j, j-1);
}
```

## Example 3: Performance Optimization Validation

### Original Implementation (Slow)

```rust
fn find_duplicates(arr: &[i32]) -> Vec<i32> {
    let mut duplicates = Vec::new();

    for i in 0..arr.len() {
        for j in (i+1)..arr.len() {
            if arr[i] == arr[j] && !duplicates.contains(&arr[i]) {
                duplicates.push(arr[i]);
            }
        }
    }

    duplicates
}
```

### Record Baseline

```bash
pmat debug serve --record-dir ./baseline
# Run with arr = [1, 2, 3, 2, 4, 3, 5]
# Result: [2, 3]
# Time: 245ms (from timeline timestamps)
```

### Optimized Implementation

```rust
use std::collections::HashSet;

fn find_duplicates(arr: &[i32]) -> Vec<i32> {
    let mut seen = HashSet::new();
    let mut duplicates = HashSet::new();

    for &num in arr {
        if !seen.insert(num) {
            duplicates.insert(num);
        }
    }

    duplicates.into_iter().collect()
}
```

### Record Optimized

```bash
pmat debug serve --record-dir ./optimized
# Run with same input
```

### Compare Performance

```bash
$ pmat debug compare baseline/find_dups.pmat optimized/find_dups.pmat

Performance:
baseline: 245ms, 127 frames
optimized: 12ms, 15 frames  # 🚀 20x faster!

Behavior:
Divergence: None (outputs match)
✅ Optimization preserves correctness
```

## Example 4: Concurrency Bug Detection

### The Test (Flaky)

```rust
use std::sync::{Arc, Mutex};
use std::thread;

#[test]
fn test_concurrent_counter() {
    let counter = Arc::new(Mutex::new(0));
    let mut handles = vec![];

    for _ in 0..10 {
        let counter = Arc::clone(&counter);
        handles.push(thread::spawn(move || {
            let mut num = counter.lock().unwrap();
            *num += 1;
        }));
    }

    for handle in handles {
        handle.join().unwrap();
    }

    assert_eq!(*counter.lock().unwrap(), 10);
}
```

### Record Multiple Runs

```bash
# Run 1: PASS
pmat debug serve --record-dir ./pass-runs

# Run 2: FAIL
pmat debug serve --record-dir ./fail-runs

# Run 3: PASS
pmat debug serve --record-dir ./pass-runs
```

### Compare Pass vs Fail

```bash
$ pmat debug compare pass-runs/run1.pmat fail-runs/run2.pmat

⚠️  Divergence at frame 87

Frame 87:
Pass                     |  Fail
counter = 7              |  counter = 6  # ⚠️ Lost increment!
thread_id = 3            |  thread_id = 3
lock_acquired = true     |  lock_acquired = false  # ⚠️ Lock contention!
```

Timeline reveals: thread was preempted before acquiring lock!

## TDD Best Practices with Time-Travel Debugging

### ✅ DO:

1. **Record every test run** during TDD cycles
   ```bash
   pmat debug serve --record-dir ./tdd-session-$(date +%Y%m%d)
   ```

2. **Compare RED vs GREEN phases**
   ```bash
   pmat debug compare red/failing-test.pmat green/passing-test.pmat
   ```

3. **Keep recordings for regression tests**
   ```bash
   mv green/test.pmat regression-baselines/feature-X-v1.0.pmat
   ```

4. **Use timeline to understand test failures**
   ```bash
   pmat debug timeline failing-test.pmat | grep -A 5 "PANIC\|ERROR"
   ```

### ❌ DON'T:

1. Don't record long-running integration tests (> 10 minutes)
2. Don't compare recordings from different test inputs
3. Don't skip REFACTOR phase verification recordings

## Next Steps

- Return to [Chapter 29](ch29-00-time-travel-debugging.md) overview
- Explore [MCP Integration](ch03-00-mcp-protocol.md) for automated workflows
- See [Quality Gates](ch07-00-quality-gate.md) for CI/CD integration
