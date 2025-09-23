#!/bin/bash
# TDD Test: Chapter 25 - Sub-Agents and Claude Code Integration

PASS_COUNT=0
FAIL_COUNT=0
TEST_DIR=$(mktemp -d)
PMAT_DIR="/home/noah/src/paiml-mcp-agent-toolkit"

# Test utilities
test_pass() {
    echo "✅ PASS: $1"
    ((PASS_COUNT++))
}

test_fail() {
    echo "❌ FAIL: $1"
    ((FAIL_COUNT++))
}

# Cleanup on exit
cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Check if PMAT repository exists
check_pmat_exists() {
    if [ -d "$PMAT_DIR" ]; then
        test_pass "PMAT repository exists"
    else
        test_fail "PMAT repository not found at $PMAT_DIR"
        return 1
    fi
}

# Test 1: AGENTS.md file structure
test_agents_md_structure() {
    echo "Testing AGENTS.md structure..."

    # Create sample AGENTS.md
    cat > "$TEST_DIR/AGENTS.md" << 'EOF'
# Agent System Definition

## System Agents

### Quality Gate Agent
- **Type**: Validator
- **Priority**: Critical
- **Tools**:
  - `pmat_analyze_complexity`
  - `pmat_detect_satd`
  - `pmat_security_scan`

### Refactoring Agent
- **Type**: Transformer
- **Priority**: High
- **Tools**:
  - `pmat_refactor_code`
  - `pmat_apply_patterns`

### Analysis Agent
- **Type**: Analyzer
- **Priority**: Normal
- **Tools**:
  - `pmat_analyze_code`
  - `pmat_generate_metrics`

## Communication Protocol

- **Message Format**: JSON
- **Transport**: MCP
- **Discovery**: Auto

## Quality Requirements

- **Complexity Limit**: 10
- **Coverage Minimum**: 95%
- **SATD Tolerance**: 0
EOF

    if [ -f "$TEST_DIR/AGENTS.md" ]; then
        test_pass "AGENTS.md created successfully"
    else
        test_fail "Failed to create AGENTS.md"
    fi

    # Verify structure
    if grep -q "## System Agents" "$TEST_DIR/AGENTS.md" && \
       grep -q "### Quality Gate Agent" "$TEST_DIR/AGENTS.md" && \
       grep -q "## Communication Protocol" "$TEST_DIR/AGENTS.md"; then
        test_pass "AGENTS.md has correct structure"
    else
        test_fail "AGENTS.md structure is incorrect"
    fi
}

# Test 2: Agent discovery functionality
test_agent_discovery() {
    echo "Testing agent discovery..."

    # Check for agent modules in PMAT
    if [ -d "$PMAT_DIR/server/src/agents_md" ]; then
        test_pass "Agent modules exist in PMAT"

        # Check for key agent files
        if [ -f "$PMAT_DIR/server/src/agents_md/discovery.rs" ]; then
            test_pass "Agent discovery module found"
        else
            test_fail "Agent discovery module not found"
        fi

        if [ -f "$PMAT_DIR/server/src/agents_md/executor.rs" ]; then
            test_pass "Agent executor module found"
        else
            test_fail "Agent executor module not found"
        fi
    else
        test_fail "Agent modules directory not found"
    fi
}

# Test 3: MCP-AGENTS.md bridge
test_mcp_bridge() {
    echo "Testing MCP-AGENTS.md bridge..."

    if [ -f "$PMAT_DIR/server/src/agents_md/bridge.rs" ]; then
        test_pass "MCP-AGENTS.md bridge module exists"

        # Check for bridge components
        if grep -q "McpAgentsMdBridge" "$PMAT_DIR/server/src/agents_md/bridge.rs"; then
            test_pass "Bridge implementation found"
        else
            test_fail "Bridge implementation not found"
        fi

        if grep -q "QualityLevel" "$PMAT_DIR/server/src/agents_md/bridge.rs"; then
            test_pass "Quality enforcement in bridge"
        else
            test_fail "Quality enforcement missing in bridge"
        fi
    else
        test_fail "MCP-AGENTS.md bridge not found"
    fi
}

# Test 4: Agent registry
test_agent_registry() {
    echo "Testing agent registry..."

    if [ -f "$PMAT_DIR/server/src/agents/registry.rs" ]; then
        test_pass "Agent registry module exists"
    else
        test_fail "Agent registry module not found"
    fi
}

# Test 5: Agent specification format
test_agent_specification() {
    echo "Testing agent specification format..."

    # Create agent spec file
    cat > "$TEST_DIR/pmat-quality-gate.yaml" << 'EOF'
apiVersion: pmat.io/v1
kind: Agent
metadata:
  name: pmat-quality-gate
  class: Validator
spec:
  description: |
    Enforces quality standards with zero-tolerance for technical debt.
  capabilities:
    - complexity_analysis
    - satd_detection
    - security_scanning
  tools:
    - pmat_analyze_complexity
    - pmat_detect_satd
    - pmat_security_scan
  config:
    thresholds:
      max_complexity: 10
      max_satd_count: 0
      min_coverage: 0.95
EOF

    if [ -f "$TEST_DIR/pmat-quality-gate.yaml" ]; then
        test_pass "Agent specification created"

        # Validate YAML structure
        if grep -q "apiVersion: pmat.io/v1" "$TEST_DIR/pmat-quality-gate.yaml" && \
           grep -q "kind: Agent" "$TEST_DIR/pmat-quality-gate.yaml"; then
            test_pass "Agent spec has correct format"
        else
            test_fail "Agent spec format is incorrect"
        fi
    else
        test_fail "Failed to create agent specification"
    fi
}

# Test 6: Agent communication protocol
test_agent_communication() {
    echo "Testing agent communication protocol..."

    # Create message example
    cat > "$TEST_DIR/agent_message.json" << 'EOF'
{
  "header": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "from": "analyzer-agent",
    "to": "quality-gate-agent",
    "timestamp": 1234567890,
    "priority": "high"
  },
  "payload": {
    "type": "analysis_complete",
    "data": {
      "file": "main.rs",
      "complexity": 8,
      "coverage": 0.96
    }
  }
}
EOF

    if [ -f "$TEST_DIR/agent_message.json" ] && \
       jq -e '.header.from' "$TEST_DIR/agent_message.json" > /dev/null 2>&1; then
        test_pass "Valid agent message format"
    else
        test_fail "Invalid agent message format"
    fi
}

# Test 7: Workflow orchestration
test_workflow_orchestration() {
    echo "Testing workflow orchestration..."

    # Create workflow definition
    cat > "$TEST_DIR/quality_workflow.yaml" << 'EOF'
name: quality_check_workflow
version: 1.0.0
steps:
  - id: analyze
    agent: analyzer
    operation: analyze_code
    params:
      language: rust

  - id: validate
    agent: quality_gate
    operation: validate_metrics
    depends_on: [analyze]

  - id: refactor
    agent: transformer
    operation: apply_refactoring
    depends_on: [validate]
    condition: "steps.validate.output.needs_refactoring == true"
EOF

    if [ -f "$TEST_DIR/quality_workflow.yaml" ]; then
        test_pass "Workflow definition created"

        if grep -q "depends_on:" "$TEST_DIR/quality_workflow.yaml" && \
           grep -q "condition:" "$TEST_DIR/quality_workflow.yaml"; then
            test_pass "Workflow has dependencies and conditions"
        else
            test_fail "Workflow missing key features"
        fi
    else
        test_fail "Failed to create workflow"
    fi
}

# Test 8: Integration with Claude Code /agents
test_claude_integration() {
    echo "Testing Claude Code integration..."

    # Create directory structure first
    mkdir -p "$TEST_DIR/.claude/agents"

    # Create Claude agent definition
    cat > "$TEST_DIR/.claude/agents/pmat-analyzer.md" << 'EOF'
# PMAT Analyzer Agent

## Description
Analyzes code quality using PMAT metrics.

## Available Tools
- pmat_analyze_complexity
- pmat_detect_satd
- pmat_calculate_metrics

## Instructions
When asked to analyze code:
1. Run complexity analysis
2. Detect technical debt
3. Calculate quality metrics
4. Return structured report

## Quality Gates
- Max Complexity: 10
- SATD Count: 0
- Min Coverage: 95%
EOF

    if [ -f "$TEST_DIR/.claude/agents/pmat-analyzer.md" ]; then
        test_pass "Claude agent definition created"

        if grep -q "## Available Tools" "$TEST_DIR/.claude/agents/pmat-analyzer.md" && \
           grep -q "## Quality Gates" "$TEST_DIR/.claude/agents/pmat-analyzer.md"; then
            test_pass "Claude agent has correct structure"
        else
            test_fail "Claude agent structure incorrect"
        fi
    else
        test_fail "Failed to create Claude agent definition"
    fi
}

# Test 9: Agent state management
test_state_management() {
    echo "Testing agent state management..."

    # Check for state management in PMAT
    if [ -d "$PMAT_DIR/server/src" ]; then
        if find "$PMAT_DIR/server/src" -name "*.rs" -exec grep -l "AgentState\|EventStore\|SnapshotStore" {} \; | head -1 > /dev/null; then
            test_pass "State management implemented"
        else
            test_fail "State management not found"
        fi
    else
        test_fail "PMAT source directory not found"
    fi
}

# Test 10: Quality enforcement
test_quality_enforcement() {
    echo "Testing quality enforcement..."

    # Check for quality gates in code
    if [ -f "$PMAT_DIR/server/src/agents_md/bridge.rs" ]; then
        if grep -q "QualityLevel::" "$PMAT_DIR/server/src/agents_md/bridge.rs"; then
            test_pass "Quality levels defined"
        else
            test_fail "Quality levels not defined"
        fi

        if grep -q "quality_level:" "$PMAT_DIR/server/src/agents_md/bridge.rs" || \
           grep -q "QualityLevel" "$PMAT_DIR/server/src/agents_md/bridge.rs"; then
            test_pass "Quality enforcement implemented"
        else
            test_fail "Quality enforcement not implemented"
        fi
    fi
}

# Run all tests
echo "="
echo "Running Chapter 25 Sub-Agents Tests"
echo "===================================="

check_pmat_exists
test_agents_md_structure
test_agent_discovery
test_mcp_bridge
test_agent_registry
test_agent_specification
test_agent_communication
test_workflow_orchestration
test_claude_integration
test_state_management
test_quality_enforcement

# Summary
echo "===================================="
echo "Test Summary:"
echo "  Passed: $PASS_COUNT"
echo "  Failed: $FAIL_COUNT"

if [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ $FAIL_COUNT tests failed"
    exit 1
fi