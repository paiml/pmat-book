#!/bin/bash
# TDD Test: Chapter 14 - Large Codebase Optimization

set -e

echo "=== Testing Chapter 14: Large Codebase Optimization ==="

PMAT_BIN="pmat"
if ! command -v pmat > /dev/null 2>&1; then
    if [ -x "../paiml-mcp-agent-toolkit/target/release/pmat" ]; then
        PMAT_BIN="../paiml-mcp-agent-toolkit/target/release/pmat"
    fi
fi
# Resolve to an absolute path before the `cd` below, or a relative PMAT_BIN
# silently stops resolving inside the temp dir.
if [ "$PMAT_BIN" != "pmat" ]; then
    PMAT_BIN="$(cd "$(dirname "$PMAT_BIN")" && pwd)/$(basename "$PMAT_BIN")"
fi

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

# Test 7: pmat actually analyses a multi-file tree
#
# TESTS 1-6 ABOVE INVOKE PMAT ZERO TIMES. Each writes a config file with a
# heredoc and then asserts the file exists, so all six pass whatever pmat does --
# including when pmat is absent, broken, or replaced by a shim that refuses every
# command. They test `cat`. paiml/pmat#1084's falsification control reports this
# script as one that cannot fail, which is how the gap was found.
#
# This test is the one that needs pmat to work: it builds a small multi-file tree
# and requires pmat to report every file it walked. A large-codebase chapter that
# never runs an analysis is not validating the thing it documents.
mkdir -p bigtree/src
for i in 1 2 3 4 5; do
    cat > "bigtree/src/mod_${i}.py" << EOF
def handler_${i}(data, config):
    if data is None:
        return None
    if config.get("double"):
        return [x * 2 for x in data]
    return list(data)
EOF
done

if ! command -v "$PMAT_BIN" > /dev/null 2>&1 && [ ! -x "$PMAT_BIN" ]; then
    echo "❌ pmat not available, so this test verified NOTHING about large-codebase analysis"
    exit 1
fi

if ! "$PMAT_BIN" analyze complexity --path bigtree > complexity_large.txt 2>&1; then
    echo "❌ pmat analyze complexity failed on the generated tree"
    cat complexity_large.txt
    exit 1
fi

# Assert on the MEASUREMENT, not on the exit code. A command that ran but walked
# nothing exits 0 too, and "analysed 0 files" is the failure this chapter is
# about.
if grep -qE "5 file|5 files" complexity_large.txt; then
    echo "✅ pmat analysed all 5 generated files"
else
    echo "❌ pmat did not report analysing the 5 generated files:"
    cat complexity_large.txt
    exit 1
fi

cd /
rm -rf "$TEST_DIR"

echo ""
echo "✅ All 7 large codebase tests passed!"
exit 0