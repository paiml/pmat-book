# Chapter 23: Performance Testing Suite

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (16/16 examples)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 16 | Ready for production use |
| ⚠️ Not Implemented | 0 | Planned for future versions |
| ❌ Broken | 0 | Known issues, needs fixing |
| 📋 Planned | 0 | Future roadmap features |

*Last updated: 2025-09-12*  
*PMAT version: pmat 2.213.1*
<!-- DOC_STATUS_END -->

## The Problem

Performance regressions often go unnoticed until they impact production systems. Developers need comprehensive testing that validates not just correctness but also performance characteristics, memory usage, and throughput. Traditional testing frameworks focus on functional correctness, leaving performance validation as an afterthought.

## Core Concepts

### Performance Testing Architecture

PMAT's testing suite provides:
- **Performance Benchmarking**: Baseline establishment and comparison
- **Property-Based Testing**: Automated test case generation
- **Memory Validation**: Heap usage and leak detection
- **Throughput Testing**: Load and capacity validation
- **Regression Detection**: Automatic performance regression identification
- **Integration Testing**: End-to-end performance validation

### Test Suite Categories

```
Test Suites
├── Performance
│   ├── Latency benchmarks
│   ├── CPU utilization
│   └── Response time analysis
├── Property
│   ├── Invariant checking
│   ├── Fuzzing
│   └── Randomized testing
├── Memory
│   ├── Allocation patterns
│   ├── Leak detection
│   └── Peak usage tracking
├── Throughput
│   ├── Request handling
│   ├── Data processing
│   └── Concurrent operations
├── Regression
│   ├── Performance comparison
│   ├── Threshold validation
│   └── Trend analysis
└── Integration
    ├── End-to-end scenarios
    ├── System boundaries
    └── Component interaction
```

## Running Performance Tests

### Basic Performance Testing

```bash
# Run default performance tests
pmat test performance

# Run with verbose output
pmat test performance --verbose

# Set custom timeout
pmat test performance --timeout 300
```

**Performance Test Output:**
```
🏃 PMAT Performance Testing Suite
=================================
Project: /path/to/project
Profile: Release (optimized)
Platform: Linux x86_64, 8 cores

📊 Running Performance Tests...
────────────────────────────────

Test: String Processing
  ✅ Baseline: 1.23ms ± 0.05ms
  ✅ Current:  1.21ms ± 0.04ms
  ✅ Delta:    -1.6% (improvement)
  ✅ Status:   PASS

Test: Data Serialization
  ✅ Baseline: 4.56ms ± 0.12ms
  ✅ Current:  4.58ms ± 0.13ms
  ⚠️  Delta:    +0.4% (within tolerance)
  ✅ Status:   PASS

Test: Complex Algorithm
  ✅ Baseline: 23.4ms ± 1.2ms
  ❌ Current:  28.7ms ± 1.5ms
  ❌ Delta:    +22.6% (regression)
  ❌ Status:   FAIL

📈 Performance Summary
─────────────────────
Total Tests: 12
Passed: 10
Failed: 2
Regressions: 2
Improvements: 3

⚠️  Performance regression detected!
   Complex Algorithm: +22.6% slower
   Database Query: +15.3% slower
```

### Establishing Baselines

```bash
# Create performance baseline
pmat test performance --baseline

# Save baseline with name
pmat test performance --baseline --name v1.0.0

# Compare against baseline
pmat test performance --compare-baseline v1.0.0
```

**Baseline Creation Output:**
```
📊 Creating Performance Baseline
================================

Running 50 iterations for statistical significance...

Benchmark Results:
┌─────────────────────┬──────────┬──────────┬──────────┬──────────┐
│ Test                │ Mean     │ Median   │ Std Dev  │ P95      │
├─────────────────────┼──────────┼──────────┼──────────┼──────────┤
│ JSON Parsing        │ 2.34ms   │ 2.31ms   │ 0.08ms   │ 2.48ms   │
│ HTTP Request        │ 12.5ms   │ 12.1ms   │ 1.2ms    │ 14.8ms   │
│ Database Query      │ 5.67ms   │ 5.55ms   │ 0.34ms   │ 6.23ms   │
│ File I/O            │ 8.92ms   │ 8.88ms   │ 0.42ms   │ 9.56ms   │
│ Compression         │ 15.3ms   │ 15.1ms   │ 0.89ms   │ 16.8ms   │
└─────────────────────┴──────────┴──────────┴──────────┴──────────┘

✅ Baseline saved: .pmat/baselines/performance_20250912_143000.json
```

## Property-Based Testing

### Running Property Tests

```bash
# Run property-based tests
pmat test property

# With custom seed for reproducibility
pmat test property --seed 42

# Increase test cases
pmat test property --cases 10000
```

**Property Test Example:**
```
🎲 Property-Based Testing
========================

Testing: Data Processing Function
Strategy: Random input generation
Cases: 1000

Property: Idempotence
  ∀ x: f(f(x)) = f(x)
  ✅ 1000/1000 cases passed

Property: Associativity
  ∀ a,b,c: f(a, f(b, c)) = f(f(a, b), c)
  ✅ 1000/1000 cases passed

Property: Boundary Conditions
  Testing edge cases and limits
  ✅ 1000/1000 cases passed
  
  Edge cases found:
  - Empty input handled correctly
  - Maximum size (2^32-1) processed
  - Unicode boundaries respected

Property: Error Handling
  Invalid inputs properly rejected
  ✅ 1000/1000 cases passed
  
  Failure modes tested:
  - Null pointers: Properly handled
  - Buffer overflow: Protected
  - Integer overflow: Checked

Summary: All properties satisfied ✅
```

### Custom Property Definitions

```rust
// Define custom properties in tests/properties.rs
use proptest::prelude::*;

proptest! {
    #[test]
    fn test_sort_idempotent(mut vec: Vec<i32>) {
        let sorted_once = sort_data(vec.clone());
        let sorted_twice = sort_data(sorted_once.clone());
        prop_assert_eq!(sorted_once, sorted_twice);
    }
    
    #[test]
    fn test_compression_reversible(data: Vec<u8>) {
        let compressed = compress(&data);
        let decompressed = decompress(&compressed);
        prop_assert_eq!(data, decompressed);
    }
}
```

## Memory Testing

### Memory Usage Validation

```bash
# Run memory tests
pmat test memory

# With detailed allocation tracking
pmat test memory --track-allocations

# Set memory limits
pmat test memory --max-heap 100MB
```

**Memory Test Output:**
```
💾 Memory Usage Testing
======================

Test Configuration:
- Max Heap: 100 MB
- Track Allocations: Yes
- Leak Detection: Enabled

Running: Large Data Processing
  Initial: 12.3 MB
  Peak:    67.8 MB ✅ (limit: 100 MB)
  Final:   12.5 MB
  Leaked:  0.2 MB ⚠️  (minor leak detected)
  
  Allocation Pattern:
  ┌─────────────────────────────────────┐
  │     ▁▃▅▇█▇▅▃▁                       │ 70 MB
  │    ▁        ▁                       │
  │   ▁          ▁                      │
  │  ▁            ▁                     │ 35 MB
  │ ▁              ▁▁▁▁▁▁▁▁▁▁▁▁▁▁      │
  └─────────────────────────────────────┘
    0s          5s          10s
  
Running: Concurrent Operations
  Initial: 12.5 MB
  Peak:    89.2 MB ✅ (limit: 100 MB)
  Final:   12.5 MB
  Leaked:  0 MB ✅
  
  Thread Memory Distribution:
  - Main thread:    23.4 MB
  - Worker 1:       16.8 MB
  - Worker 2:       17.1 MB
  - Worker 3:       16.5 MB
  - Worker 4:       15.4 MB

Memory Test Summary:
✅ 8/10 tests passed
⚠️  2 tests with minor leaks (<1 MB)
❌ 0 tests exceeded memory limit
```

### Leak Detection

```bash
# Run with leak detection
pmat test memory --detect-leaks

# Valgrind integration (if available)
pmat test memory --valgrind
```

## Throughput Testing

### Load Testing

```bash
# Run throughput tests
pmat test throughput

# Specify request rate
pmat test throughput --rps 1000

# Set duration
pmat test throughput --duration 60
```

**Throughput Test Output:**
```
🚀 Throughput Testing
====================

Target: HTTP API Server
Duration: 60 seconds
Target RPS: 1000

Warmup Phase (10s):
  Ramping up to 1000 RPS...
  ✅ Target rate achieved

Test Phase (60s):
  
  Request Statistics:
  ┌──────────────┬────────────┬────────────┐
  │ Metric       │ Value      │ Status     │
  ├──────────────┼────────────┼────────────┤
  │ Total Reqs   │ 59,847     │ ✅         │
  │ Success      │ 59,523     │ 99.46%     │
  │ Failed       │ 324        │ 0.54%      │
  │ Actual RPS   │ 997.45     │ ✅         │
  └──────────────┴────────────┴────────────┘
  
  Latency Distribution:
  ┌──────────────┬────────────┐
  │ Percentile   │ Latency    │
  ├──────────────┼────────────┤
  │ P50          │ 4.2ms      │
  │ P90          │ 8.7ms      │
  │ P95          │ 12.3ms     │
  │ P99          │ 24.5ms     │
  │ P99.9        │ 67.8ms     │
  │ Max          │ 234ms      │
  └──────────────┴────────────┘
  
  Throughput Graph:
  1200 │      ▂▄▆█████████▇▅▃▂
  1000 │   ▂▄█                 █▄▂
   800 │  ▄                       ▄
   600 │ ▂                         ▂
   400 │▄                           ▄
   200 │                             
     0 └─────────────────────────────
       0s    20s    40s    60s
  
✅ Throughput test passed
   Target: 1000 RPS, Achieved: 997.45 RPS
```

### Concurrent Load Testing

```bash
# Test with concurrent connections
pmat test throughput --concurrent 100

# Ramp-up pattern
pmat test throughput --ramp-up 30 --sustained 60 --ramp-down 10
```

## Regression Detection

### Automatic Regression Testing

```bash
# Run regression tests
pmat test regression

# Set regression threshold (percentage)
pmat test regression --threshold 5

# Multiple iterations for stability
pmat test regression --iterations 10
```

**Regression Detection Output:**
```
🔍 Regression Detection
======================

Comparing: Current vs Previous (commit: abc123)
Threshold: 5% performance degradation
Iterations: 10 (for statistical significance)

Test Results:
┌─────────────────┬──────────┬──────────┬─────────┬──────────┐
│ Test            │ Previous │ Current  │ Change  │ Status   │
├─────────────────┼──────────┼──────────┼─────────┼──────────┤
│ API Response    │ 12.3ms   │ 12.5ms   │ +1.6%   │ ✅ PASS  │
│ Data Process    │ 45.6ms   │ 48.2ms   │ +5.7%   │ ⚠️  WARN  │
│ Search Query    │ 8.9ms    │ 11.2ms   │ +25.8%  │ ❌ FAIL  │
│ Cache Lookup    │ 0.8ms    │ 0.7ms    │ -12.5%  │ ✅ IMPROV │
│ DB Transaction  │ 23.4ms   │ 24.1ms   │ +3.0%   │ ✅ PASS  │
└─────────────────┴──────────┴──────────┴─────────┴──────────┘

Regression Analysis:
❌ 1 significant regression found
   Search Query: 25.8% slower (exceeds 5% threshold)
   
   Likely cause: Recent changes to search algorithm
   Affected files:
   - src/search/index.rs (modified)
   - src/search/query.rs (modified)
   
⚠️  1 warning (approaching threshold)
   Data Process: 5.7% slower (at threshold limit)

✅ 1 performance improvement
   Cache Lookup: 12.5% faster

Action Required: Fix regression in Search Query before merge
```

### Historical Trend Analysis

```bash
# Analyze performance trends
pmat test regression --history 30

# Generate trend report
pmat test regression --trend-report
```

**Trend Analysis Output:**
```
📈 Performance Trend Analysis
============================

Period: Last 30 days
Commits analyzed: 127

Performance Trends:
                     
API Response Time    │     ▄▆▇█▇▆▄▃▂▁▂▃▄▅▆▇▆▅▄▃▂
  15ms ┤            │    ▂
  12ms ┤            │   ▄ 
   9ms ┤            │  ▆
   6ms └────────────┴──────────────────
       30d ago      15d ago      Today

Memory Usage         │     ▂▃▄▅▆▇████▇▆▅▄▃▂▁▁▂▃▄
  150MB┤            │           ▂▄▆█
  100MB┤            │      ▂▄▆█
   50MB┤            │ ▂▄▆█
     0 └────────────┴──────────────────
       30d ago      15d ago      Today

Key Events:
- Day 23: Memory optimization merged (-30% usage)
- Day 15: New caching layer (+10% speed)
- Day 8: Database query optimization (+25% speed)
- Day 3: Memory leak introduced (fixed day 2)
```

## Integration Testing

### End-to-End Performance

```bash
# Run integration tests
pmat test integration

# With specific scenarios
pmat test integration --scenario user-flow

# Full system test
pmat test integration --full-stack
```

**Integration Test Output:**
```
🔗 Integration Testing
=====================

Scenario: Complete User Flow
Components: Frontend → API → Database → Cache

Step 1: User Authentication
  ✅ Login request: 125ms
  ✅ Token generation: 15ms
  ✅ Session creation: 8ms
  Total: 148ms ✅ (target: <200ms)

Step 2: Data Retrieval
  ✅ API request: 12ms
  ✅ Cache check: 0.8ms (HIT)
  ✅ Response formatting: 3ms
  Total: 15.8ms ✅ (target: <50ms)

Step 3: Data Processing
  ✅ Validation: 5ms
  ✅ Business logic: 34ms
  ✅ Database write: 28ms
  ✅ Cache update: 2ms
  Total: 69ms ✅ (target: <100ms)

Step 4: Notification
  ✅ Event generation: 3ms
  ✅ Queue publish: 8ms
  ✅ Email dispatch: 45ms
  Total: 56ms ✅ (target: <100ms)

End-to-End Metrics:
- Total time: 288.8ms ✅ (target: <500ms)
- Database queries: 3
- Cache hits: 2/3 (66.7%)
- Memory peak: 45MB
- CPU peak: 23%

✅ All integration tests passed
```

## CI/CD Integration

### GitHub Actions Performance Testing

```yaml
# .github/workflows/performance-tests.yml
name: Performance Testing

on:
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM

jobs:
  performance-tests:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Rust
      uses: actions-rs/toolchain@v1
      with:
        toolchain: stable
        override: true
    
    - name: Install PMAT
      run: cargo install pmat
    
    - name: Download Baseline
      uses: actions/download-artifact@v3
      with:
        name: performance-baseline
        path: .pmat/baselines/
      continue-on-error: true
    
    - name: Run Performance Tests
      run: |
        pmat test all --output results.json
        
        # Check for regressions
        if pmat test regression --threshold 5; then
          echo "✅ No performance regressions"
        else
          echo "❌ Performance regression detected"
          exit 1
        fi
    
    - name: Update Baseline (if main)
      if: github.ref == 'refs/heads/main'
      run: pmat test performance --baseline
    
    - name: Upload Results
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: performance-results
        path: |
          results.json
          .pmat/baselines/
    
    - name: Comment PR
      if: github.event_name == 'pull_request'
      uses: actions/github-script@v6
      with:
        script: |
          const fs = require('fs');
          const results = JSON.parse(fs.readFileSync('results.json'));
          
          let comment = '## 📊 Performance Test Results\n\n';
          
          if (results.regressions.length > 0) {
            comment += '❌ **Performance Regressions Detected**\n\n';
            results.regressions.forEach(r => {
              comment += `- ${r.test}: ${r.change}% slower\n`;
            });
          } else {
            comment += '✅ **No Performance Regressions**\n\n';
          }
          
          comment += '\n### Summary\n';
          comment += `- Tests Run: ${results.total}\n`;
          comment += `- Passed: ${results.passed}\n`;
          comment += `- Failed: ${results.failed}\n`;
          
          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: comment
          });
```

## Custom Test Configurations

### Test Configuration File

```toml
# .pmat/test-config.toml
[performance]
baseline_dir = ".pmat/baselines"
iterations = 50
warmup_iterations = 10
statistical_significance = 0.95

[regression]
threshold_percent = 5
minimum_iterations = 10
compare_against = "main"

[memory]
max_heap_mb = 500
track_allocations = true
detect_leaks = true
valgrind = false

[throughput]
target_rps = 1000
duration_seconds = 60
concurrent_connections = 100
ramp_up_seconds = 10

[property]
test_cases = 1000
seed = 42
shrink_attempts = 100
```

## Performance Optimization Workflow

### Performance Investigation

```bash
# Profile specific test
pmat test performance --profile slow-test

# Generate flame graph
pmat test performance --flame-graph

# CPU profiling
pmat test performance --cpu-profile
```

**Profiling Output:**
```
🔥 Performance Profile: slow-test
=================================

Flame Graph: profile_flame.svg generated

Hot Spots:
┌────────────────────────┬─────────┬───────────┐
│ Function               │ Time %  │ Samples   │
├────────────────────────┼─────────┼───────────┤
│ process_data          │ 34.2%   │ 1,234     │
│ ├─ validate_input     │ 12.3%   │ 444       │
│ ├─ transform_data     │ 15.6%   │ 563       │
│ └─ serialize_output   │ 6.3%    │ 227       │
│ database_query        │ 28.7%   │ 1,035     │
│ network_io            │ 18.4%   │ 664       │
│ json_parsing          │ 8.9%    │ 321       │
│ other                 │ 9.8%    │ 354       │
└────────────────────────┴─────────┴───────────┘

Optimization Suggestions:
1. process_data: Consider caching validation results
2. database_query: Add index on frequently queried columns
3. network_io: Enable connection pooling
```

## Summary

PMAT's performance testing suite provides comprehensive validation of code performance, memory usage, and system behavior. By integrating multiple testing methodologies—from micro-benchmarks to full system tests—it ensures applications meet performance requirements and catch regressions early.

Key benefits include:
- **Comprehensive Coverage**: Performance, memory, throughput, and integration testing
- **Regression Detection**: Automatic identification of performance degradation
- **Property-Based Testing**: Automated test case generation for edge cases
- **CI/CD Integration**: Seamless pipeline integration with automated reporting
- **Historical Analysis**: Trend tracking and performance evolution
- **Actionable Insights**: Clear identification of bottlenecks and optimization opportunities

The testing suite transforms performance validation from an afterthought to an integral part of the development process, ensuring consistent application performance.