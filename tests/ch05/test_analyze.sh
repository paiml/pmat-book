#!/bin/bash
# TDD Test: Chapter 5 - pmat analyze Command Suite
# Tests comprehensive analysis features

set -e

echo "=== Testing Chapter 5: pmat analyze Command Suite ==="

# Check if pmat is available.
#
# MOCK_MODE IS INITIALISED HERE, AND THAT IS THE WHOLE POINT. This block used to
# leave it UNSET on the success path: `MOCK_MODE=true` was assigned only in the
# not-found branch, and `MOCK_MODE=false` only inside
# `if [ "$PMAT_BIN" != "pmat" ] && ...`, which is false precisely when pmat WAS
# found on PATH. Every guard below reads `[ "$MOCK_MODE" = false ]`, and with the
# variable unset that test is FALSE — so a working, installed pmat selected the
# MOCK branch in all eight tests and the script never invoked pmat once.
#
# Measured against pmat 3.33.0 on PATH before this fix: 8 "Mock ..." passes,
# 0 real invocations, and a final "All tests passed!". That is what
# paiml/pmat#1084's falsification control caught -- the chapter passed against a
# deliberately BROKEN pmat, because it was never calling pmat either way.
MOCK_MODE=false
PMAT_BIN=""
if command -v pmat &> /dev/null; then
    PMAT_BIN="pmat"
    echo "✅ PMAT detected in PATH"
elif [ -x "../paiml-mcp-agent-toolkit/target/release/pmat" ]; then
    PMAT_BIN="../paiml-mcp-agent-toolkit/target/release/pmat"
    echo "✅ PMAT detected in target/release"
elif [ -x "../paiml-mcp-agent-toolkit/target/debug/pmat" ]; then
    PMAT_BIN="../paiml-mcp-agent-toolkit/target/debug/pmat"
    echo "✅ PMAT detected in target/debug"
else
    echo "⚠️  PMAT not found, using mock tests"
    MOCK_MODE=true
    PMAT_BIN="pmat"
fi

if [ "$MOCK_MODE" = false ]; then
    echo "Using PMAT binary: $PMAT_BIN"
fi

TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

PASS_COUNT=0
FAIL_COUNT=0

test_pass() {
    echo "✅ PASS: $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

test_fail() {
    echo "❌ FAIL: $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

# Test 1: Create test project for analysis
echo ""
echo "Test 1: Creating test project for analysis"

mkdir -p src tests
cat > src/complex.py << 'EOF'
def complex_function(data, config):
    """Complex function for testing."""
    if data is None:
        return None
    
    result = []
    for item in data:
        if item > 0:
            if config.get('double'):
                result.append(item * 2)
            else:
                result.append(item)
        else:
            if config.get('abs'):
                result.append(-item)
    
    # Duplicate code
    for item in data:
        if item > 0:
            if config.get('double'):
                result.append(item * 2)
            else:
                result.append(item)
    
    return result

def dead_function():
    """This function is never called."""
    return "dead code"

# TODO: Fix this hack
# FIXME: Temporary workaround
def technical_debt():
    """Function with technical debt."""
    # HACK: This needs refactoring
    pass
EOF

cat > src/simple.py << 'EOF'
def add(a, b):
    """Simple addition."""
    return a + b

def multiply(a, b):
    """Simple multiplication."""
    return a * b
EOF

test_pass "Test project created"

# Test 2: Basic analyze command
echo ""
echo "Test 2: Basic analysis"

if [ "$MOCK_MODE" = false ]; then
    # `pmat analyze` has no bare form -- it requires a subcommand. `deep-context`
    # is the closest thing to "analyse this project": it is the one that reports
    # files, lines and complexity together.
    if $PMAT_BIN analyze deep-context --project-path . > analysis_output.txt 2>&1; then
        test_pass "Basic analysis completed"
        
        if grep -q "Analysis\|Files\|Lines\|Complexity" analysis_output.txt; then
            test_pass "Analysis output contains expected elements"
        else
            test_fail "Analysis output missing expected elements"
        fi
    else
        test_fail "Basic analysis failed"
    fi
else
    cat > analysis_output.txt << 'EOF'
📊 Repository Analysis
======================

Files Analyzed: 2
Total Lines: 45
Languages: Python (100%)

## Metrics Summary
- Cyclomatic Complexity: 8 (average: 4)
- Technical Debt: 3 issues found
- Code Duplication: 15% 
- Dead Code: 1 function detected

## Quality Grade: C+
EOF
    test_pass "Mock analysis completed"
fi

# Test 3: Complexity analysis
echo ""
echo "Test 3: Complexity analysis"

if [ "$MOCK_MODE" = false ]; then
    if $PMAT_BIN analyze complexity --path . > complexity.txt 2>&1; then
        test_pass "Complexity analysis completed"
    else
        test_fail "Complexity analysis failed"
    fi
else
    cat > complexity.txt << 'EOF'
🔧 Complexity Analysis
=======================

src/complex.py:
  complex_function: 12 (High)
  dead_function: 1 (Low)
  technical_debt: 1 (Low)

src/simple.py:
  add: 1 (Low)
  multiply: 1 (Low)

Average Complexity: 3.2
Maximum Complexity: 12 (complex_function)
Files Over Threshold (10): 1
EOF
    test_pass "Mock complexity analysis completed"
fi

# Test 4: Dead code detection
echo ""
echo "Test 4: Dead code analysis"

if [ "$MOCK_MODE" = false ]; then
    if $PMAT_BIN analyze dead-code --path . > deadcode.txt 2>&1; then
        test_pass "Dead code analysis completed"
    else
        test_fail "Dead code analysis failed"
    fi
else
    cat > deadcode.txt << 'EOF'
💀 Dead Code Detection
=======================

Found 1 unused function:
- src/complex.py:27 dead_function() - Never referenced

Suggested Action: Safe to remove
EOF
    test_pass "Mock dead code analysis completed"
fi

# Test 5: SATD (Self-Admitted Technical Debt) analysis
echo ""
echo "Test 5: SATD analysis"

if [ "$MOCK_MODE" = false ]; then
    if $PMAT_BIN analyze satd --path . > satd.txt 2>&1; then
        test_pass "SATD analysis completed"
    else
        test_fail "SATD analysis failed"
    fi
else
    cat > satd.txt << 'EOF'
🏗️ Self-Admitted Technical Debt
==================================

Found 3 SATD markers:

src/complex.py:30 TODO: Fix this hack
src/complex.py:31 FIXME: Temporary workaround  
src/complex.py:34 HACK: This needs refactoring

Categories:
- TODO: 1
- FIXME: 1
- HACK: 1

Priority: Medium
Estimated Effort: 2-4 hours
EOF
    test_pass "Mock SATD analysis completed"
fi

# Test 6: Similarity/duplication detection
echo ""
echo "Test 6: Code similarity analysis"

if [ "$MOCK_MODE" = false ]; then
    # `analyze similarity` does not exist. Duplicate/clone detection is
    # `analyze duplicates`; `analyze name-similarity` is a different thing
    # (identifier names), and this test is about duplicated CODE.
    if $PMAT_BIN analyze duplicates --path . > similarity.txt 2>&1; then
        test_pass "Similarity analysis completed"
    else
        test_fail "Similarity analysis failed"
    fi
else
    cat > similarity.txt << 'EOF'
🔄 Code Duplication Analysis
==============================

Type-1 Clones (Exact):
- src/complex.py:17-24 ↔ src/complex.py:7-14
  8 lines duplicated (100% match)

Total Duplication: 15%
Duplicate Blocks: 1
Lines Saved if Refactored: 8
EOF
    test_pass "Mock similarity analysis completed"
fi

# Test 7: Output formats
echo ""
echo "Test 7: Analysis output formats"

if [ "$MOCK_MODE" = false ]; then
    # JSON output
    # NOT `2>&1`. pmat writes JSON to stdout and progress to stderr, on purpose
    # (its own json-stdout-purity tests pin this). Merging the two put
    # "Analyzing project complexity..." at byte 0 and made `jq empty` fail on
    # output that was correct.
    if $PMAT_BIN analyze complexity --path . --format json > analysis.json 2>/dev/null; then
        test_pass "JSON analysis completed"
        if jq empty analysis.json 2>/dev/null; then
            test_pass "JSON output is valid"
        else
            test_fail "JSON output is invalid"
        fi
    else
        test_fail "JSON analysis failed"
    fi
else
    cat > analysis.json << 'EOF'
{
  "files": 2,
  "total_lines": 45,
  "metrics": {
    "complexity": {
      "average": 3.2,
      "max": 12
    },
    "duplication": 0.15,
    "satd_count": 3,
    "dead_code": 1
  },
  "grade": "C+"
}
EOF
    test_pass "Mock JSON analysis completed"
    if jq empty analysis.json 2>/dev/null; then
        test_pass "Mock JSON is valid"
    fi
fi

# Test 8: Dependency analysis
echo ""
echo "Test 8: Dependency analysis"

if [ "$MOCK_MODE" = false ]; then
    # `analyze dependencies` does not exist; the dependency graph is `analyze dag`.
    if $PMAT_BIN analyze dag --project-path . > dependencies.txt 2>&1; then
        test_pass "Dependency analysis completed"
    else
        test_fail "Dependency analysis failed"
    fi
else
    cat > dependencies.txt << 'EOF'
📦 Dependency Analysis
========================

Internal Dependencies:
- src/complex.py → (standalone)
- src/simple.py → (standalone)

External Dependencies:
- Python stdlib only

Circular Dependencies: None detected
Coupling Score: Low (Good)
EOF
    test_pass "Mock dependency analysis completed"
fi

# Cleanup
cd /
rm -rf "$TEST_DIR"

echo ""
echo "=== Chapter 5 Analyze Test Summary ==="
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"

if [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ All analyze tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi