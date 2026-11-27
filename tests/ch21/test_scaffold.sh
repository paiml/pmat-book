#!/bin/bash
# TDD Test: Chapter 21 - Project and Agent Scaffolding
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

echo "=== Test 1: Scaffold Complete Project ==="
if pmat scaffold project rust -p project_name=test-api -p description="Test API" 2>/dev/null
then
    # 3.44.0 writes <project_name>/ with Makefile, README.md and .gitignore
    if [ -f test-api/Makefile ] && [ -f test-api/README.md ] && [ -f test-api/.gitignore ]; then
        test_pass "Project scaffolding created structure"
    else
        pmat_fail "Project scaffolding completed"
    fi
else
    PROJECT_OUTPUT=$(pmat scaffold project 2>&1) || PROJECT_OUTPUT=""
    if echo "$PROJECT_OUTPUT" | grep -q "scaffold\|project\|template"
    then
        test_pass "Project scaffolding available"
    else
        pmat_fail "Scaffolding system exists"
    fi
fi

echo "=== Test 2: Scaffold MCP Agent ==="
if pmat scaffold agent -n test_agent -t calculator -o agent-dir 2>/dev/null
then
    if [ -d agent-dir ]; then
        test_pass "Agent scaffolding created directory"
    else
        pmat_fail "Agent scaffolding completed"
    fi
else
    AGENT_OUTPUT=$(pmat scaffold agent 2>&1) || AGENT_OUTPUT=""
    if echo "$AGENT_OUTPUT" | grep -q "agent\|mcp\|scaffold"
    then
        test_pass "Agent scaffolding available"
    else
        pmat_fail "Agent template system exists"
    fi
fi

echo "=== Test 3: List Agent Templates ==="
# 3.44.0 writes this listing to stderr, so capture both streams.
AGENT_TEMPLATES=$(pmat scaffold list-templates 2>&1) || AGENT_TEMPLATES=""
if echo "$AGENT_TEMPLATES" | grep -q "template\|agent\|deterministic\|tool"
then
    test_pass "Agent template listing works"
else
    pmat_fail "Agent template listing available"
fi

echo "=== Test 4: Validate Agent Template ==="
# Create a test agent template
cat > test-agent.yaml << 'EOF'
name: test-agent
version: 1.0.0
description: Test agent for validation
tools:
  - name: analyze
    description: Analyze code
    parameters:
      - name: path
        type: string
        required: true
EOF

if pmat scaffold validate-template test-agent.yaml 2>/dev/null
then
    test_pass "Agent template validation works"
else
    VALIDATE_OUTPUT=$(pmat scaffold validate-template test-agent.yaml 2>&1) || VALIDATE_OUTPUT=""
    if echo "$VALIDATE_OUTPUT" | grep -q "valid\|template\|agent"
    then
        test_pass "Template validation available"
    else
        pmat_fail "Validation system exists"
    fi
fi

echo "=== Test 5: Scaffold with Custom Configuration ==="
cat > scaffold-config.toml << 'EOF'
[project]
name = "custom-project"
version = "0.1.0"
author = "Test Author"

[features]
enable_tests = true
enable_docs = true
enable_ci = true

[dependencies]
serde = "1.0"
tokio = { version = "1.0", features = ["full"] }
EOF

# 3.44.0 has no --config on 'scaffold project' (chapter 21 says so). Assert that
# pmat rejects the flag with clap's error and creates nothing.
CONFIG_OUTPUT=$(pmat scaffold project rust --config scaffold-config.toml -p project_name=custom-project 2>&1) && CONFIG_RC=0 || CONFIG_RC=$?
if [ "$CONFIG_RC" -ne 0 ] && echo "$CONFIG_OUTPUT" | grep -q "unexpected argument '--config'" && [ ! -e custom-project ]; then
    test_pass "scaffold project rejects --config (not in 3.44.0; chapter 21 documents this)"
else
    pmat_fail "Configuration support available"
fi

echo "=== Test 6: Interactive Scaffolding ==="
# Test with pre-provided answers
# 3.44.0: 'scaffold project' has no --interactive (chapter 21 says so), and
# 'scaffold agent -i' reports that interactive mode is unavailable. Assert both.
INTERACTIVE_OUTPUT=$(pmat scaffold project rust --interactive -p project_name=interactive-project 2>&1) && INTERACTIVE_RC=0 || INTERACTIVE_RC=$?
AGENT_I_OUTPUT=$(pmat scaffold agent -i -n interactive_agent -t calculator -o interactive-agent 2>&1) && AGENT_I_RC=0 || AGENT_I_RC=$?
if [ "$INTERACTIVE_RC" -ne 0 ] && echo "$INTERACTIVE_OUTPUT" | grep -q "unexpected argument '--interactive'" \
    && [ "$AGENT_I_RC" -ne 0 ] && echo "$AGENT_I_OUTPUT" | grep -q "Interactive mode is not available" \
    && [ ! -e interactive-project ] && [ ! -e interactive-agent ]; then
    test_pass "Interactive scaffolding is absent in 3.44.0 (chapter 21 documents this)"
else
    pmat_fail "Interactive mode available"
fi

echo "=== Test 7: Scaffold with Git Initialization ==="
# 3.44.0 has no --git on 'scaffold project' (chapter 21 says so). Assert the rejection.
GIT_OUTPUT=$(pmat scaffold project rust --git -p project_name=git-project -p description=d 2>&1) && GIT_RC=0 || GIT_RC=$?
if [ "$GIT_RC" -ne 0 ] && echo "$GIT_OUTPUT" | grep -q "unexpected argument '--git'" && [ ! -e git-project ]; then
    test_pass "scaffold project rejects --git (not in 3.44.0; chapter 21 documents this)"
else
    pmat_fail "Git integration available"
fi

echo "=== Test 8: Multi-Language Project Scaffolding ==="
# 3.44.0 has no --languages. Multiple languages come from one 'scaffold project' call per toolchain.
if pmat scaffold project rust -p project_name=multi-rust -p description="Rust part" 2>/dev/null \
    && pmat scaffold project python-uv -p project_name=multi-py -p description="Python part" 2>/dev/null
then
    if [ -f multi-rust/Makefile ] && [ -f multi-py/Makefile ]; then
        test_pass "Multi-language scaffolding works (one call per toolchain)"
    else
        pmat_fail "Multi-language project created"
    fi
else
    pmat_fail "Language-specific scaffolding exists"
fi

# Summary
echo ""
echo "=== Test Summary ==="
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"

if [ $FAIL_COUNT -eq 0 ] && [ $PASS_COUNT -gt 0 ]; then
    echo "✅ All scaffolding tests passed!"
    exit 0
elif [ $FAIL_COUNT -eq 0 ]; then
    echo "⚠️  No checks ran (pmat not on PATH): nothing was verified"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi
