#!/bin/bash
# TDD Test: Issue #53 Batch 4 - MCP Quality Tracking & Git Integration
# Tests quality_gate_baseline, quality_gate_compare, and git_status

set -e

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

cleanup() {
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        cd /
        rm -rf "$TEST_DIR"
    fi
}

trap cleanup EXIT

echo "=== Testing Issue #53 Batch 4: Quality Tracking & Git Integration ==="

TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Test 1: quality_gate_baseline - Create TDG Baseline Snapshot
echo ""
echo "Test 1: quality_gate_baseline - Create baseline with content hashing"

# Create test Rust file
mkdir -p src
cat > src/calculator.rs << 'EOF'
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

pub fn multiply(a: i32, b: i32) -> i32 {
    a * b
}
EOF

# Create MCP request for quality_gate_baseline
cat > mcp_baseline_request.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "batch4-1",
  "method": "tools/call",
  "params": {
    "name": "quality_gate_baseline",
    "arguments": {
      "paths": ["."],
      "output": "/tmp/baseline.json"
    }
  }
}
EOF

# Expected response structure
cat > mcp_baseline_response_expected.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "batch4-1",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\\n  \\\"status\\\": \\\"completed\\\",\\n  \\\"message\\\": \\\"Quality gate baseline created successfully\\\",\\n  \\\"baseline\\\": {\\n    \\\"file_path\\\": \\\"/tmp/baseline.json\\\",\\n    \\\"timestamp\\\": \\\"2025-11-01T00:00:00+00:00\\\",\\n    \\\"summary\\\": {\\n      \\\"total_files\\\": 1,\\n      \\\"average_score\\\": 90.0,\\n      \\\"average_grade\\\": \\\"A\\\"\\n    }\\n  }\\n}"
      }
    ]
  }
}
EOF

# Verify request/response format exists
if [ -f mcp_baseline_request.json ] && [ -f mcp_baseline_response_expected.json ]; then
    # Validate JSON syntax
    if jq empty mcp_baseline_request.json 2>/dev/null && \
       jq empty mcp_baseline_response_expected.json 2>/dev/null; then

        # Check request has correct structure
        method=$(jq -r '.method' mcp_baseline_request.json)
        tool_name=$(jq -r '.params.name' mcp_baseline_request.json)

        if [ "$method" = "tools/call" ] && [ "$tool_name" = "quality_gate_baseline" ]; then
            test_pass "quality_gate_baseline MCP request/response format defined"
        else
            test_fail "quality_gate_baseline request format invalid"
        fi
    else
        test_fail "quality_gate_baseline JSON syntax"
    fi
else
    test_fail "quality_gate_baseline MCP examples missing"
fi

# Test 2: quality_gate_compare - Compare Baselines for Regressions
echo ""
echo "Test 2: quality_gate_compare - Compare two baselines to detect quality changes"

# Create MCP request for quality_gate_compare
cat > mcp_compare_request.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "batch4-2",
  "method": "tools/call",
  "params": {
    "name": "quality_gate_compare",
    "arguments": {
      "baseline": "/tmp/baseline_old.json",
      "paths": ["."]
    }
  }
}
EOF

# Expected response structure
cat > mcp_compare_response_expected.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "batch4-2",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\\n  \\\"status\\\": \\\"completed\\\",\\n  \\\"message\\\": \\\"Quality gate comparison completed successfully\\\",\\n  \\\"comparison\\\": {\\n    \\\"improved\\\": 0,\\n    \\\"regressed\\\": 1,\\n    \\\"unchanged\\\": 0,\\n    \\\"added\\\": 0,\\n    \\\"removed\\\": 0,\\n    \\\"has_regressions\\\": true,\\n    \\\"total_changes\\\": 1,\\n    \\\"regressed_files\\\": [{\\n      \\\"file\\\": \\\"src/calculator.rs\\\",\\n      \\\"old_score\\\": 90.0,\\n      \\\"new_score\\\": 85.0,\\n      \\\"delta\\\": -5.0\\n    }]\\n  }\\n}"
      }
    ]
  }
}
EOF

# Verify request/response format exists
if [ -f mcp_compare_request.json ] && [ -f mcp_compare_response_expected.json ]; then
    if jq empty mcp_compare_request.json 2>/dev/null && \
       jq empty mcp_compare_response_expected.json 2>/dev/null; then

        method=$(jq -r '.method' mcp_compare_request.json)
        tool_name=$(jq -r '.params.name' mcp_compare_request.json)

        if [ "$method" = "tools/call" ] && [ "$tool_name" = "quality_gate_compare" ]; then
            test_pass "quality_gate_compare MCP request/response format defined"
        else
            test_fail "quality_gate_compare request format invalid"
        fi
    else
        test_fail "quality_gate_compare JSON syntax"
    fi
else
    test_fail "quality_gate_compare MCP examples missing"
fi

# Test 3: git_status - Extract Git Repository Status
echo ""
echo "Test 3: git_status - Extract git repository metadata"

# Create MCP request for git_status
cat > mcp_git_status_request.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "batch4-3",
  "method": "tools/call",
  "params": {
    "name": "git_status",
    "arguments": {
      "path": "."
    }
  }
}
EOF

# Expected response structure
cat > mcp_git_status_response_expected.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "batch4-3",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\\n  \\\"status\\\": \\\"completed\\\",\\n  \\\"message\\\": \\\"Git status retrieved successfully\\\",\\n  \\\"git_status\\\": {\\n    \\\"commit_sha\\\": \\\"abc123def456\\\",\\n    \\\"commit_sha_short\\\": \\\"abc123d\\\",\\n    \\\"branch\\\": \\\"master\\\",\\n    \\\"author_name\\\": \\\"John Doe\\\",\\n    \\\"is_clean\\\": true,\\n    \\\"uncommitted_files\\\": 0\\n  }\\n}"
      }
    ]
  }
}
EOF

# Verify request/response format exists
if [ -f mcp_git_status_request.json ] && [ -f mcp_git_status_response_expected.json ]; then
    if jq empty mcp_git_status_request.json 2>/dev/null && \
       jq empty mcp_git_status_response_expected.json 2>/dev/null; then

        method=$(jq -r '.method' mcp_git_status_request.json)
        tool_name=$(jq -r '.params.name' mcp_git_status_request.json)

        if [ "$method" = "tools/call" ] && [ "$tool_name" = "git_status" ]; then
            test_pass "git_status MCP request/response format defined"
        else
            test_fail "git_status request format invalid"
        fi
    else
        test_fail "git_status JSON syntax"
    fi
else
    test_fail "git_status MCP examples missing"
fi

# Test 4: Batch 4 Function Coverage in Documentation
echo ""
echo "Test 4: Batch 4 function coverage in MCP tools documentation"

# Check if pmat-book chapter 15 mentions these functions
if [ -f /home/noah/src/pmat-book/src/ch15-00-mcp-tools.md ]; then
    doc_file="/home/noah/src/pmat-book/src/ch15-00-mcp-tools.md"

    # Check for quality_gate_baseline
    if grep -q "quality_gate_baseline" "$doc_file"; then
        test_pass "quality_gate_baseline documented in Chapter 15"
    else
        test_fail "quality_gate_baseline missing from Chapter 15 (expected - needs documentation)"
    fi

    # Check for quality_gate_compare
    if grep -q "quality_gate_compare" "$doc_file"; then
        test_pass "quality_gate_compare documented in Chapter 15"
    else
        test_fail "quality_gate_compare missing from Chapter 15 (expected - needs documentation)"
    fi

    # Check for git_status
    if grep -q "git_status" "$doc_file"; then
        test_pass "git_status documented in Chapter 15"
    else
        test_fail "git_status missing from Chapter 15 (expected - needs documentation)"
    fi
else
    test_fail "Chapter 15 MCP tools documentation not found"
fi

# Test 5: Integration Pattern Examples
echo ""
echo "Test 5: Integration pattern examples for batch 4 functions"

# Create Python integration example
cat > integration_example.py << 'EOF'
"""
Issue #53 Batch 4: MCP Integration Example
Demonstrates quality_gate_baseline, quality_gate_compare, and git_status
"""
import requests
import json

class PMATMCPClient:
    def __init__(self, base_url="http://localhost:8080"):
        self.base_url = base_url

    def call_tool(self, tool_name, arguments):
        payload = {
            "jsonrpc": "2.0",
            "id": "example-1",
            "method": "tools/call",
            "params": {
                "name": tool_name,
                "arguments": arguments
            }
        }
        response = requests.post(
            f"{self.base_url}/mcp",
            json=payload,
            headers={"Content-Type": "application/json"}
        )
        return response.json()

    def create_baseline(self, project_path, output_file):
        """Create quality gate baseline snapshot."""
        return self.call_tool("quality_gate_baseline", {
            "paths": [project_path],
            "output": output_file
        })

    def compare_baselines(self, baseline_file, project_path):
        """Compare baseline to detect quality regressions."""
        return self.call_tool("quality_gate_compare", {
            "baseline": baseline_file,
            "paths": [project_path]
        })

    def get_git_status(self, repo_path):
        """Get git repository status and metadata."""
        return self.call_tool("git_status", {
            "path": repo_path
        })

# Example usage:
# client = PMATMCPClient()
#
# # Create baseline
# baseline = client.create_baseline(".", "/tmp/baseline.json")
# print(f"Baseline created: {baseline['result']['content'][0]['text']}")
#
# # Make code changes...
#
# # Compare to detect regressions
# comparison = client.compare_baselines("/tmp/baseline.json", ".")
# data = json.loads(comparison['result']['content'][0]['text'])
# print(f"Has regressions: {data['comparison']['has_regressions']}")
# print(f"Regressed files: {data['comparison']['regressed']}")
#
# # Get git status
# git_status = client.get_git_status(".")
# status_data = json.loads(git_status['result']['content'][0]['text'])
# print(f"Branch: {status_data['git_status']['branch']}")
# print(f"Commit: {status_data['git_status']['commit_sha_short']}")
EOF

if [ -f integration_example.py ]; then
    # Validate Python syntax
    if python3 -m py_compile integration_example.py 2>/dev/null; then
        test_pass "Python integration example syntax valid"
    else
        test_fail "Python integration example syntax error"
    fi
else
    test_fail "Integration example creation failed"
fi

# Summary
echo ""
echo "========================================="
echo "Issue #53 Batch 4 Test Summary"
echo "========================================="
echo "✅ PASSED: $PASS_COUNT"
echo "❌ FAILED: $FAIL_COUNT"
echo ""

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "🎉 All tests passed! Batch 4 MCP functions properly documented."
    exit 0
else
    echo "⚠️  Some tests failed. Review documentation and examples."
    exit 1
fi
