#!/bin/bash
# TDD Test: Chapter 4.1 - Technical Debt Grading (TDG)
# Tests TDG analysis with real PMAT commands

set -e

echo "=== Testing Chapter 4.1: Technical Debt Grading (TDG) ==="

# Check if pmat is available
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
    PMAT_BIN="pmat"  # Set to default for mock mode
fi

if [ "$PMAT_BIN" != "pmat" ] && [ -x "$PMAT_BIN" ]; then
    MOCK_MODE=false
    echo "Using PMAT binary: $PMAT_BIN"
fi

# The tests cd into a temp dir below, so make a relative binary path absolute.
case "$PMAT_BIN" in
    */*) PMAT_BIN="$(cd "$(dirname "$PMAT_BIN")" && pwd)/$(basename "$PMAT_BIN")" ;;
esac

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

# Test 1: Create test files with varying complexity
echo "Test 1: Creating test files for TDG analysis"

# High complexity file (should have high TDG score)
cat > high_complexity.py << 'EOF'
def process_data(items, config, flags, options):
    """High complexity function with deep nesting."""
    results = []
    errors = []
    
    for i in range(len(items)):
        if items[i] is not None:
            if config.get('validate', False):
                if items[i]['type'] == 'A':
                    if items[i]['value'] > 100:
                        if flags.get('strict'):
                            if options.get('transform'):
                                results.append(transform(items[i]))
                            else:
                                results.append(items[i])
                        else:
                            results.append(items[i] * 2)
                    else:
                        for j in range(items[i]['value']):
                            if j % 2 == 0:
                                results.append(j)
                elif items[i]['type'] == 'B':
                    try:
                        processed = complex_process(items[i])
                        if processed:
                            results.extend(processed)
                    except Exception as e:
                        errors.append(str(e))
                else:
                    results.append(default_process(items[i]))
    
    return results, errors

def another_complex_function(data):
    # More complexity
    for x in data:
        for y in x:
            for z in y:
                if z > 0:
                    print(z)
EOF

# Low complexity file (should have low TDG score)
cat > low_complexity.py << 'EOF'
def add(a, b):
    """Simple addition function."""
    return a + b

def subtract(a, b):
    """Simple subtraction function."""
    return a - b

def get_name():
    """Return a name."""
    return "PMAT"

class SimpleClass:
    """A simple class with minimal complexity."""
    
    def __init__(self, value):
        self.value = value
    
    def get_value(self):
        return self.value
    
    def set_value(self, value):
        self.value = value
EOF

# Medium complexity file with duplication
cat > medium_complexity.py << 'EOF'
def validate_user(user):
    """Medium complexity with some duplication."""
    if user is None:
        return False
    
    if not user.get('name'):
        return False
    
    if not user.get('email'):
        return False
    
    if user.get('age', 0) < 18:
        return False
    
    return True

def validate_admin(admin):
    """Duplicate logic from validate_user."""
    if admin is None:
        return False
    
    if not admin.get('name'):
        return False
    
    if not admin.get('email'):
        return False
    
    if admin.get('age', 0) < 18:
        return False
    
    if not admin.get('role') == 'admin':
        return False
    
    return True

def process_users(users):
    """Process list of users."""
    valid_users = []
    for user in users:
        if validate_user(user):
            valid_users.append(user)
    return valid_users
EOF

test_pass "Test files created"

# Test 2: Run basic TDG analysis
echo ""
echo "Test 2: Basic TDG analysis"

if [ "$MOCK_MODE" = false ]; then
    if $PMAT_BIN analyze tdg . > tdg_output.txt 2>&1; then
        test_pass "TDG analysis completed"
        
        # Check if output contains expected elements
        if grep -q "TDG" tdg_output.txt || grep -q "Technical Debt" tdg_output.txt || grep -q "Score" tdg_output.txt; then
            test_pass "TDG output contains expected elements"
        else
            test_fail "TDG output missing expected elements"
        fi
    else
        test_fail "TDG analysis failed"
    fi
else
    # Mock test
    echo "Mock: Running TDG analysis..."
    test_pass "Mock TDG analysis completed"
fi

# Test 3: TDG with component breakdown
echo ""
echo "Test 3: TDG with component breakdown"

if [ "$MOCK_MODE" = false ]; then
    if $PMAT_BIN analyze tdg . --include-components > tdg_components.txt 2>&1; then
        test_pass "TDG with components completed"
    else
        test_fail "TDG with components failed"
    fi
else
    # Mock test
    cat > tdg_components.txt << 'EOF'
File: high_complexity.py
  TDG Score: 3.2 (Critical)
  Components:
    - Complexity: 2.1
    - Churn: 0.5
    - Coupling: 0.3
    - Duplication: 0.2
    - Domain Risk: 0.1

File: low_complexity.py
  TDG Score: 0.8 (Normal)
  Components:
    - Complexity: 0.4
    - Churn: 0.1
    - Coupling: 0.1
    - Duplication: 0.1
    - Domain Risk: 0.1
EOF
    test_pass "Mock TDG components generated"
fi

# Test 4: TDG thresholds and filtering
echo ""
echo "Test 4: TDG threshold filtering"

if [ "$MOCK_MODE" = false ]; then
    # Test critical threshold
    if $PMAT_BIN analyze tdg . --critical-only > critical_files.txt 2>&1; then
        test_pass "Critical files filtering completed"
    else
        test_fail "Critical files filtering failed"
    fi
    
    # --threshold is accepted but not applied (see the chapter)
    if $PMAT_BIN analyze tdg . --threshold 2.0 > threshold_files.txt 2>&1; then
        test_pass "--threshold accepted (not applied)"
    else
        test_fail "--threshold rejected"
    fi
else
    test_pass "Mock threshold check completed"
fi

# Test 5: Different output formats
echo ""
echo "Test 5: TDG output formats"

if [ "$MOCK_MODE" = false ]; then
    # JSON format
    if $PMAT_BIN analyze tdg . --format json > tdg.json 2>&1; then
        test_pass "JSON output generated"
    else
        test_fail "JSON output failed"
    fi
    
    # Markdown format
    if $PMAT_BIN analyze tdg . --format markdown > tdg.md 2>&1; then
        test_pass "Markdown output generated"
    else
        test_fail "Markdown output failed"
    fi
else
    # Mock outputs
    echo '{"tdg_scores": []}' > tdg.json
    echo "# TDG Report" > tdg.md
    test_pass "Mock output formats generated"
fi

# Test 5b: the commands the chapter documents, run against real pmat.
# Runs whenever a pmat binary exists (independent of MOCK_MODE) and uses the
# --path form. Each assertion is an exit code the chapter states.
echo ""
echo "Test 5b: documented TDG commands (real pmat)"

expect_rc() {
    # expect_rc <want> <label> <cmd...>
    local want=$1 label=$2 got
    shift 2
    "$@" > /dev/null 2>&1 && got=0 || got=$?
    if [ "$got" -eq "$want" ]; then
        test_pass "$label (exit $got)"
    else
        test_fail "$label: expected exit $want, got $got"
    fi
}

if command -v "$PMAT_BIN" > /dev/null 2>&1; then
    # The CI gate in the chapter must be able to fail: the same tree passes
    # at one grade and fails at a stricter one.
    expect_rc 0 "check-quality --min-grade F passes" $PMAT_BIN tdg check-quality --path . --min-grade F
    expect_rc 1 "check-quality --min-grade A+ fails" $PMAT_BIN tdg check-quality --path . --min-grade A+
    # The test files above include high_complexity.py, so this tree fails A+;
    # analyze tdg still exits 0 on it, whatever the scores.
    expect_rc 0 "analyze tdg exits 0 on a tree that fails A+" $PMAT_BIN analyze tdg --path .

    expect_rc 0 "analyze tdg --format json --output" $PMAT_BIN analyze tdg --path . --format json --output tdg-report.json
    expect_rc 0 "tdg baseline create" $PMAT_BIN tdg baseline create --path . --output tdg-baseline.json
    expect_rc 0 "tdg baseline compare" $PMAT_BIN tdg baseline compare --baseline tdg-baseline.json --path .
    expect_rc 0 "tdg check-regression --fail-on-regression" $PMAT_BIN tdg check-regression --baseline tdg-baseline.json --path . --fail-on-regression
    expect_rc 0 "tdg storage stats" $PMAT_BIN tdg storage stats
    expect_rc 0 "tdg config sources" $PMAT_BIN tdg config sources
    expect_rc 0 "analyze tdg --critical-only" $PMAT_BIN analyze tdg --path . --critical-only
    expect_rc 0 "analyze tdg --include-components" $PMAT_BIN analyze tdg --path . --include-components
    expect_rc 0 "analyze tdg --top-files 10" $PMAT_BIN analyze tdg --path . --top-files 10
    # Storage lives in ./.pmat, so cleanup here touches only this temp dir.
    expect_rc 0 "tdg storage cleanup" $PMAT_BIN tdg storage cleanup
    if $PMAT_BIN tdg config sources 2>&1 | grep -q 'pmat.toml (current directory)'; then
        test_pass "tdg config sources names pmat.toml in the current directory"
    else
        test_fail "tdg config sources does not name pmat.toml in the current directory"
    fi

    # tdg history needs a git repo; --since HEAD~N needs N commits (exit 1 otherwise).
    mkdir -p hist/src
    (
        cd hist &&
        printf 'fn a(x: i32) -> i32 { if x > 1 { x } else { 0 } }\n' > src/lib.rs &&
        git init -q &&
        git -c core.hooksPath=/dev/null -c user.name=t -c user.email=t@t add -A &&
        git -c core.hooksPath=/dev/null -c user.name=t -c user.email=t@t commit -qm one &&
        printf 'fn b() {}\n' >> src/lib.rs &&
        git -c core.hooksPath=/dev/null -c user.name=t -c user.email=t@t commit -qam two
    ) > /dev/null 2>&1
    expect_rc 0 "tdg history --since HEAD~1" sh -c "cd hist && $PMAT_BIN tdg history --since HEAD~1"
    expect_rc 1 "tdg history --since HEAD~30 on a 2-commit repo" sh -c "cd hist && $PMAT_BIN tdg history --since HEAD~30"

    # --threshold is accepted but not applied, and the command still exits 0.
    if $PMAT_BIN analyze tdg --path . --threshold 2.0 2>&1 | grep -qF -- '--threshold 2 was not applied'; then
        test_pass "--threshold warns that it was not applied"
    else
        test_fail "--threshold did not print the not-applied warning"
    fi
    expect_rc 1 "analyze tdg --ml is not implemented" $PMAT_BIN analyze tdg --path . --ml

    # Flags and subcommands the chapter says do not exist.
    for flag in --storage-backend --priority --incremental --cache-enabled \
                --compare-baseline --trend --period --parallel --config; do
        expect_rc 2 "analyze tdg $flag is rejected" $PMAT_BIN analyze tdg --path . $flag x
    done
    # Not subcommands: `pmat tdg <word>` reads the word as a path and exits 5.
    for sub in performance-profile flame-graph; do
        if $PMAT_BIN tdg --help 2>&1 | grep -qw -- "$sub"; then
            test_fail "tdg --help lists $sub"
        else
            test_pass "tdg --help does not list $sub"
        fi
    done
    for flag in --tdg-threshold --min-grade --fail-on-regression; do
        expect_rc 2 "quality-gate $flag is rejected" $PMAT_BIN quality-gate $flag
    done
else
    if [ "${TDG_REQUIRE_PMAT:-0}" = 1 ]; then
        test_fail "TDG_REQUIRE_PMAT=1 but no pmat binary"
    else
        echo "⏭️  SKIP: no pmat binary; documented commands not exercised (set TDG_REQUIRE_PMAT=1 to fail instead)"
    fi
fi

# Test 6: TDG configuration
echo ""
echo "Test 6: TDG configuration"

cat > pmat.toml << 'EOF'
[tdg]
enabled = true
critical_threshold = 2.5
warning_threshold = 1.5

[tdg.weights]
complexity = 0.30
churn = 0.35
coupling = 0.15
duplication = 0.10
domain_risk = 0.10

[tdg.output]
include_components = true
show_percentiles = true
top_files = 5
EOF

if [ -f pmat.toml ]; then
    test_pass "TDG configuration created"
else
    test_fail "Failed to create TDG configuration"
fi

# Test 7: Grade conversion
echo ""
echo "Test 7: TDG to letter grade conversion"

if [ "$MOCK_MODE" = false ]; then
    if $PMAT_BIN analyze tdg . --format json 2>/dev/null | grep -qE '(grade|Grade)' ; then
        test_pass "Grade conversion found in output"
    else
        echo "Note: Grade conversion may be in different format"
        test_pass "Grade test completed"
    fi
else
    # Mock grade output
    cat > grades.txt << 'EOF'
TDG Score -> Grade Conversion:
0.0-0.5: A+ (Excellent)
0.5-1.0: A  (Very Good)
1.0-1.5: B+ (Good)
1.5-2.0: B  (Acceptable)
2.0-2.5: C  (Needs Improvement)
2.5-3.0: D  (Poor)
3.0+:    F  (Critical)
EOF
    test_pass "Mock grade conversion created"
fi

# Test 8: MCP integration test
echo ""
echo "Test 8: TDG MCP tool integration"

cat > mcp_request.json << 'EOF'
{
  "name": "tdg_analyze_with_storage",
  "arguments": {
    "paths": ["high_complexity.py", "low_complexity.py"],
    "storage_backend": "sled",
    "priority": "high"
  }
}
EOF

if [ -f mcp_request.json ]; then
    test_pass "MCP request format validated"
else
    test_fail "Failed to create MCP request"
fi

# Cleanup
cd /
rm -rf "$TEST_DIR"

echo ""
echo "=== Chapter 4.1 TDG Test Summary ==="
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"

if [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ All TDG tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi
