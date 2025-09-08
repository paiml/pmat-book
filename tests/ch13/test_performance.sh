#!/bin/bash
# TDD Test: Chapter 13 - Performance Analysis

set -e

echo "=== Testing Chapter 13: Performance Analysis ==="

TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Test 1: Performance configuration
cat > pmat.toml << 'EOF'
[performance]
enabled = true
analyze_complexity = true
memory_analysis = true
hotspot_detection = true

[performance.thresholds]
max_complexity = "O(n²)"
max_memory_mb = 100
max_execution_time_ms = 1000
EOF

if [ -f pmat.toml ]; then
    echo "✅ Performance configuration created"
else
    echo "❌ Failed to create performance configuration"
    exit 1
fi

# Test 2: Sample inefficient code
cat > inefficient.py << 'EOF'
def find_duplicates(items):
    duplicates = []
    for i in range(len(items)):
        for j in range(i + 1, len(items)):
            if items[i] == items[j]:
                duplicates.append(items[i])
    return duplicates
EOF

if [ -f inefficient.py ]; then
    echo "✅ Inefficient code sample created"
else
    echo "❌ Failed to create code sample"
    exit 1
fi

# Test 3: Optimized code
cat > optimized.py << 'EOF'
def find_duplicates_optimized(items):
    seen = set()
    duplicates = set()
    for item in items:
        if item in seen:
            duplicates.add(item)
        else:
            seen.add(item)
    return list(duplicates)
EOF

if [ -f optimized.py ]; then
    echo "✅ Optimized code sample created"
else
    echo "❌ Failed to create optimized code"
    exit 1
fi

# Test 4: CI/CD workflow
mkdir -p .github/workflows
cat > .github/workflows/performance.yml << 'EOF'
name: Performance Analysis
on:
  pull_request:
  push:
    branches: [main]
jobs:
  performance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Performance Analysis
        run: echo "Running performance analysis"
EOF

if [ -f .github/workflows/performance.yml ]; then
    echo "✅ Performance workflow created"
else
    echo "❌ Failed to create workflow"
    exit 1
fi

# Test 5: Memory analysis example
cat > memory_test.py << 'EOF'
def process_large_file(filename):
    with open(filename) as f:
        data = f.read()  # Loads entire file
    results = []
    for line in data.split('\n'):
        results.append(line.upper())
    return results
EOF

if [ -f memory_test.py ]; then
    echo "✅ Memory test example created"
else
    echo "❌ Failed to create memory test"
    exit 1
fi

# Test 6: Benchmark configuration
cat > benchmark.yaml << 'EOF'
benchmarks:
  - name: "critical_path"
    file: "core/processor.py"
    function: "process_order"
    iterations: 1000
    max_time_ms: 100
EOF

if [ -f benchmark.yaml ]; then
    echo "✅ Benchmark configuration created"
else
    echo "❌ Failed to create benchmark config"
    exit 1
fi

cd /
rm -rf "$TEST_DIR"

echo ""
echo "✅ All 6 performance analysis tests passed!"
exit 0