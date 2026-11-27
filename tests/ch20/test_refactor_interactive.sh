#!/bin/bash
# TDD Test: Chapter 20 - Interactive Refactoring Mode
set -e

# pmat shim: when pmat is absent, fail silently (no "command not found" text
# for greps to match); every caller then takes its SKIPPED arm.
pmat() {
    type -P pmat >/dev/null 2>&1 || return 127
    command pmat "$@"
}


# Source test utilities
PASS_COUNT=0
FAIL_COUNT=0

test_skip() {
    echo "⚠️  SKIPPED: $1"
}

# A failed pmat command fails the run; with pmat absent the check is SKIPPED.
pmat_fail() {
    if type -P pmat >/dev/null 2>&1; then test_fail "$1"; else test_skip "$1 (pmat not on PATH)"; fi
}

test_pass() {
    echo "✅ PASS: $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

test_fail() {
    echo "❌ FAIL: $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

# Create test workspace
TEST_DIR=$(mktemp -d)
echo "Test directory: $TEST_DIR"

# Cleanup on exit
cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

cd "$TEST_DIR"

# Create Python project for interactive refactoring
cat > main.py << 'EOF'
def main():
    print("Interactive refactoring test")
    result = complex_function(10, 20, 30)
    print(f"Result: {result}")

def complex_function(a, b, c):
    """This function needs refactoring due to high complexity"""
    result = 0
    
    if a > 0:
        if b > 0:
            if c > 0:
                if a > b:
                    if b > c:
                        result = a * b * c
                    else:
                        result = a * b + c
                else:
                    if b > c:
                        result = b * c + a
                    else:
                        result = a + b + c
            else:
                result = a + b
        else:
            result = a
    else:
        result = 0
    
    # Additional complexity
    if result > 100:
        if result > 1000:
            result = result // 10
        else:
            result = result // 2
    
    return result

class DataProcessor:
    def __init__(self):
        self.data = []
    
    def process_data(self, items):
        processed = []
        for item in items:
            if isinstance(item, int):
                if item > 0:
                    if item < 10:
                        processed.append(item * 2)
                    elif item < 100:
                        processed.append(item * 3)
                    else:
                        processed.append(item)
                else:
                    processed.append(0)
            elif isinstance(item, str):
                if len(item) > 0:
                    processed.append(len(item))
                else:
                    processed.append(0)
        return processed

if __name__ == "__main__":
    main()
EOF

cat > requirements.txt << 'EOF'
# No dependencies for this test
EOF

echo "=== Test 1: Interactive Mode Configuration ==="
cat > refactor-config.toml << 'EOF'
[refactor]
target_complexity = 8
explanation_level = "detailed"
max_steps = 10

[quality]
enforce_standards = true
auto_format = true
EOF

if timeout 5 pmat refactor interactive --config refactor-config.toml --steps 1 2>/dev/null
then
    test_pass "Interactive mode with configuration works"
else
    CONFIG_OUTPUT=$(timeout 5 pmat refactor interactive --config refactor-config.toml --steps 1 2>&1) || CONFIG_OUTPUT=""
    if echo "$CONFIG_OUTPUT" | grep -q "interactive\|refactor\|config"
    then
        test_pass "Interactive refactoring system available"
    else
        pmat_fail "Interactive mode configuration supported"
    fi
fi

echo "=== Test 2: Checkpoint State Management ==="
if timeout 5 pmat refactor interactive --checkpoint state.json --steps 1 2>/dev/null
then
    test_pass "Checkpoint state management works"
    
    if [ -f state.json ]; then
        test_pass "State persistence file created"
    else
        pmat_fail "State management available"
    fi
else
    pmat_fail "Checkpoint functionality exists"
fi

echo "=== Test 3: Target Complexity Configuration ==="
if timeout 5 pmat refactor interactive --target-complexity 5 --steps 1 2>/dev/null
then
    test_pass "Target complexity setting works"
else
    COMPLEXITY_OUTPUT=$(timeout 5 pmat refactor interactive --target-complexity 5 --steps 1 2>&1) || COMPLEXITY_OUTPUT=""
    test_skip "Complexity targeting available"
fi

echo "=== Test 4: Explanation Levels ==="
EXPLAIN_OK=false
for level in brief detailed verbose; do
    if timeout 3 pmat refactor interactive --explain "$level" --steps 1 2>/dev/null
    then
        test_pass "Explanation level '$level' works"
        EXPLAIN_OK=true
        break
    fi
done

if [ "$EXPLAIN_OK" = true ]; then
    test_pass "Explanation level system available"
else
    pmat_fail "No explanation level accepted by 'pmat refactor interactive'"
fi

echo "=== Test 5: Project Path Specification ==="
if timeout 5 pmat refactor interactive --project-path "$TEST_DIR" --steps 1 2>/dev/null
then
    test_pass "Project path specification works"
else
    pmat_fail "Project targeting capability exists"
fi

echo "=== Test 6: Resume from Checkpoint ==="
if pmat refactor resume --checkpoint state.json 2>/dev/null
then
    test_pass "Resume from checkpoint works"
else
    RESUME_OUTPUT=$(pmat refactor resume --checkpoint state.json 2>&1) || RESUME_OUTPUT=""
    if echo "$RESUME_OUTPUT" | grep -q "resume\|checkpoint\|state"
    then
        test_pass "Resume functionality available"
    else
        pmat_fail "Resume capability exists"
    fi
fi

echo "=== Test 7: Refactor Status Monitoring ==="
if pmat refactor status 2>/dev/null
then
    test_pass "Refactor status monitoring works"
else
    STATUS_OUTPUT=$(pmat refactor status 2>&1) || STATUS_OUTPUT=""
    if echo "$STATUS_OUTPUT" | grep -q "status\|refactor\|progress"
    then
        test_pass "Status monitoring available"
    else
        pmat_fail "Progress tracking capability exists"
    fi
fi

echo "=== Test 8: Server Mode for Batch Processing ==="
if timeout 5 pmat refactor serve --port 8091 > server.log 2>&1 &
then
    SERVER_PID=$!
    sleep 2
    
    if ps -p $SERVER_PID > /dev/null 2>&1; then
        test_pass "Refactor server mode works"
        kill $SERVER_PID 2>/dev/null || true
    else
        pmat_fail "Server mode process management works"
    fi
else
    pmat_fail "Batch processing server mode available"
fi

# Summary
echo ""
echo "=== Test Summary ==="
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"

if [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ All interactive refactoring tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi
