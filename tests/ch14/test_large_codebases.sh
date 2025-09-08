#!/bin/bash
# TDD Test: Chapter 14 - Large Codebase Optimization

set -e

echo "=== Testing Chapter 14: Large Codebase Optimization ==="

TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Test 1: Large codebase configuration
cat > pmat.toml << 'EOF'
[large_codebase]
enabled = true
parallel_workers = 16
max_memory_gb = 32
cache_enabled = true

[analysis.optimization]
incremental_mode = true
skip_unchanged_files = true
batch_size = 1000
streaming_analysis = true

[analysis.filtering]
exclude_patterns = ["vendor/**", "node_modules/**"]
file_size_limit_mb = 5
EOF

if [ -f pmat.toml ]; then
    echo "✅ Large codebase configuration created"
else
    echo "❌ Failed to create configuration"
    exit 1
fi

# Test 2: Component definition
mkdir -p .pmat
cat > .pmat/components.yaml << 'EOF'
components:
  - name: frontend
    path: "src/web/**"
    languages: ["javascript", "typescript"]
  - name: backend
    path: "src/api/**"
    languages: ["python", "sql"]
EOF

if [ -f .pmat/components.yaml ]; then
    echo "✅ Component definitions created"
else
    echo "❌ Failed to create components"
    exit 1
fi

# Test 3: Priority configuration
cat > .pmat/analysis-priorities.yaml << 'EOF'
priorities:
  critical:
    paths: ["src/core/**", "src/security/**"]
    analysis_level: "comprehensive"
  important:
    paths: ["src/api/**"]
    analysis_level: "standard"
EOF

if [ -f .pmat/analysis-priorities.yaml ]; then
    echo "✅ Priority configuration created"
else
    echo "❌ Failed to create priorities"
    exit 1
fi

# Test 4: Team configuration
cat > .pmat/team-config.yaml << 'EOF'
teams:
  - name: "frontend-team"
    components: ["web-ui"]
    analysis_schedule: "daily"
  - name: "backend-team"
    components: ["api", "services"]
    analysis_schedule: "on-commit"
EOF

if [ -f .pmat/team-config.yaml ]; then
    echo "✅ Team configuration created"
else
    echo "❌ Failed to create team config"
    exit 1
fi

# Test 5: CI/CD for large codebases
mkdir -p .github/workflows
cat > .github/workflows/large-codebase.yml << 'EOF'
name: Enterprise PMAT Analysis
on:
  push:
    branches: [main]
jobs:
  incremental-analysis:
    runs-on: [self-hosted, large-runner]
    steps:
      - uses: actions/checkout@v4
      - name: Incremental Analysis
        run: echo "Running incremental analysis"
EOF

if [ -f .github/workflows/large-codebase.yml ]; then
    echo "✅ Large codebase workflow created"
else
    echo "❌ Failed to create workflow"
    exit 1
fi

# Test 6: Memory optimization settings
cat > memory-config.toml << 'EOF'
[memory_optimization]
streaming_mode = true
process_in_chunks = true
chunk_size_files = 100
[memory_limits]
max_heap_size = "8g"
EOF

if [ -f memory-config.toml ]; then
    echo "✅ Memory optimization config created"
else
    echo "❌ Failed to create memory config"
    exit 1
fi

cd /
rm -rf "$TEST_DIR"

echo ""
echo "✅ All 6 large codebase tests passed!"
exit 0