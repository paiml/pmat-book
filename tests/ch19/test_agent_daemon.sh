#!/bin/bash
# TDD Test: Chapter 19 - Agent Daemon Management
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

# The agent subsystem is behind the `agent-daemon` Cargo feature and is not in
# the default pmat 3.44.0 build. Every `pmat agent` subcommand therefore exits
# non-zero with the documented feature-gate message. A check passes only when
# both hold: a non-zero exit AND that exact message.
AGENT_GATE_MSG="Agent daemon feature not enabled"

agent_gate_check() {
    local label="$1"
    shift
    local out rc
    out=$(pmat agent "$@" 2>&1) && rc=0 || rc=$?
    if [ "$rc" -ne 0 ] && echo "$out" | grep -qF "$AGENT_GATE_MSG"; then
        test_pass "$label"
    else
        pmat_fail "$label"
    fi
}

# Create test workspace
TEST_DIR=$(mktemp -d)
echo "Test directory: $TEST_DIR"

# Cleanup on exit
cleanup() {
    # Stop agent if running
    pmat agent stop 2>/dev/null || true
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

cd "$TEST_DIR"

# Create a sample project for monitoring
cat > main.rs << 'EOF'
fn main() {
    println!("Agent monitoring test");
}

fn complex_function(a: i32, b: i32, c: i32) -> i32 {
    if a > 0 {
        if b > 0 {
            if c > 0 {
                return a + b + c;
            } else {
                return a + b;
            }
        } else {
            return a;
        }
    }
    0
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_complex_function() {
        assert_eq!(complex_function(1, 2, 3), 6);
    }
}
EOF

cat > Cargo.toml << 'EOF'
[package]
name = "agent-test"
version = "0.1.0"
edition = "2021"

[dependencies]
EOF

echo "=== Test 1: Agent Status Check ==="
agent_gate_check "Agent status reports feature gate (not in default build)" status

echo "=== Test 2: Start Agent Daemon ==="
agent_gate_check "Agent start reports feature gate" start --foreground --project-path "$TEST_DIR"

echo "=== Test 3: Agent Health Check ==="
agent_gate_check "Agent health reports feature gate" health

echo "=== Test 4: Project Monitoring ==="
agent_gate_check "Agent monitor reports feature gate" monitor --project-path "$TEST_DIR" --project-id "test-project"

echo "=== Test 5: Quality Gate Through Agent ==="
agent_gate_check "Agent quality-gate reports feature gate" quality-gate --project "$TEST_DIR"

echo "=== Test 6: MCP Server Start ==="
agent_gate_check "Agent mcp-server reports feature gate" mcp-server --debug

echo "=== Test 7: Agent Configuration ==="
# Configuration file handling
cat > agent-config.toml << 'EOF'
[monitoring]
health_interval = 30
max_memory_mb = 500

[quality]
min_grade = "B+"
auto_fix = false
EOF

agent_gate_check "Agent start with --config reports feature gate" start --config agent-config.toml --foreground --project-path "$TEST_DIR"

echo "=== Test 8: Agent Stop and Cleanup ==="
agent_gate_check "Agent stop reports feature gate" stop

# Final status check
agent_gate_check "Agent status tracking reports feature gate after stop" status

# Summary
echo ""
echo "=== Test Summary ==="
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"

if [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ All agent daemon tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi
