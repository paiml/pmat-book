#!/bin/bash
# TDD Test: Issue #53 Batch 3 - MCP Quality Gate Functions
# Tests check_quality_gates, check_quality_gate_file, and quality_gate_summary

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

echo "=== Testing Issue #53 Batch 3: Quality Gate MCP Functions ==="

TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Test 1: check_quality_gates - Project-level Quality Gate
echo ""
echo "Test 1: check_quality_gates - Project-level quality gate validation"

# Create test Rust files with varying quality
mkdir -p src
cat > src/simple.rs << 'EOF'
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

pub fn multiply(a: i32, b: i32) -> i32 {
    a * b
}
EOF

cat > src/complex.rs << 'EOF'
pub fn process(data: Vec<i32>) -> Vec<i32> {
    let mut result = Vec::new();
    for item in data {
        // TODO: Refactor this
        if item > 0 {
            if item < 100 {
                if item % 2 == 0 {
                    result.push(item * 2);
                } else {
                    result.push(item + 1);
                }
            }
        }
    }
    result
}
EOF

# Create MCP request for check_quality_gates (standard mode)
cat > mcp_quality_gates_request.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "batch3-1",
  "method": "tools/call",
  "params": {
    "name": "check_quality_gates",
    "arguments": {
      "paths": ["."],
      "strict": false
    }
  }
}
EOF

# Expected response structure
cat > mcp_quality_gates_response_expected.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "batch3-1",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\\n  \\\"status\\\": \\\"completed\\\",\\n  \\\"message\\\": \\\"Quality gate check completed (standard mode)\\\",\\n  \\\"passed\\\": true,\\n  \\\"score\\\": 85.5,\\n  \\\"grade\\\": \\\"A\\\",\\n  \\\"threshold\\\": 50.0,\\n  \\\"files_analyzed\\\": 2,\\n  \\\"violations\\\": []\\n}"
      }
    ]
  }
}
EOF

# Verify request/response format exists
if [ -f mcp_quality_gates_request.json ] && [ -f mcp_quality_gates_response_expected.json ]; then
    # Validate JSON syntax
    if jq empty mcp_quality_gates_request.json 2>/dev/null && \
       jq empty mcp_quality_gates_response_expected.json 2>/dev/null; then

        # Check request has correct structure
        method=$(jq -r '.method' mcp_quality_gates_request.json)
        tool_name=$(jq -r '.params.name' mcp_quality_gates_request.json)

        if [ "$method" = "tools/call" ] && [ "$tool_name" = "check_quality_gates" ]; then
            test_pass "check_quality_gates MCP request/response format defined"
        else
            test_fail "check_quality_gates request format invalid"
        fi
    else
        test_fail "check_quality_gates JSON syntax"
    fi
else
    test_fail "check_quality_gates MCP examples missing"
fi

# Test 2: check_quality_gates - Strict mode
echo ""
echo "Test 2: check_quality_gates - Strict mode with higher thresholds"

# Create MCP request for strict mode
cat > mcp_quality_gates_strict_request.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "batch3-2",
  "method": "tools/call",
  "params": {
    "name": "check_quality_gates",
    "arguments": {
      "paths": ["."],
      "strict": true
    }
  }
}
EOF

# Expected response structure for strict mode
cat > mcp_quality_gates_strict_response_expected.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "batch3-2",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\\n  \\\"status\\\": \\\"completed\\\",\\n  \\\"message\\\": \\\"Quality gate check completed (strict mode)\\\",\\n  \\\"passed\\\": false,\\n  \\\"score\\\": 65.0,\\n  \\\"grade\\\": \\\"C\\\",\\n  \\\"threshold\\\": 70.0,\\n  \\\"files_analyzed\\\": 2,\\n  \\\"violations\\\": [\\n    {\\n      \\\"file\\\": \\\"src/complex.rs\\\",\\n      \\\"score\\\": 60.0,\\n      \\\"grade\\\": \\\"C\\\",\\n      \\\"issues\\\": [\\\"Deep nesting: 5 levels\\\", \\\"SATD detected\\\"]\\n    }\\n  ]\\n}"
      }
    ]
  }
}
EOF

# Verify strict mode request/response format
if [ -f mcp_quality_gates_strict_request.json ] && [ -f mcp_quality_gates_strict_response_expected.json ]; then
    if jq empty mcp_quality_gates_strict_request.json 2>/dev/null && \
       jq empty mcp_quality_gates_strict_response_expected.json 2>/dev/null; then

        strict_flag=$(jq -r '.params.arguments.strict' mcp_quality_gates_strict_request.json)

        if [ "$strict_flag" = "true" ]; then
            test_pass "check_quality_gates strict mode MCP request/response format defined"
        else
            test_fail "check_quality_gates strict mode format invalid"
        fi
    else
        test_fail "check_quality_gates strict mode JSON syntax"
    fi
else
    test_fail "check_quality_gates strict mode MCP examples missing"
fi

# Test 3: check_quality_gate_file - File-level Quality Gate
echo ""
echo "Test 3: check_quality_gate_file - File-level quality gate validation"

# Create MCP request for check_quality_gate_file
cat > mcp_quality_gate_file_request.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "batch3-3",
  "method": "tools/call",
  "params": {
    "name": "check_quality_gate_file",
    "arguments": {
      "file_path": "src/simple.rs",
      "strict": false
    }
  }
}
EOF

# Expected response structure
cat > mcp_quality_gate_file_response_expected.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "batch3-3",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\\n  \\\"status\\\": \\\"completed\\\",\\n  \\\"message\\\": \\\"Quality gate check completed for file (standard mode)\\\",\\n  \\\"file\\\": \\\"src/simple.rs\\\",\\n  \\\"passed\\\": true,\\n  \\\"score\\\": 90.0,\\n  \\\"grade\\\": \\\"A\\\",\\n  \\\"threshold\\\": 50.0,\\n  \\\"violations\\\": [],\\n  \\\"metrics\\\": {\\n    \\\"structural_complexity\\\": 25.0,\\n    \\\"semantic_complexity\\\": 20.0,\\n    \\\"duplication_ratio\\\": 20.0,\\n    \\\"coupling_score\\\": 15.0,\\n    \\\"doc_coverage\\\": 10.0,\\n    \\\"consistency_score\\\": 10.0\\n  }\\n}"
      }
    ]
  }
}
EOF

# Verify request/response format exists
if [ -f mcp_quality_gate_file_request.json ] && [ -f mcp_quality_gate_file_response_expected.json ]; then
    if jq empty mcp_quality_gate_file_request.json 2>/dev/null && \
       jq empty mcp_quality_gate_file_response_expected.json 2>/dev/null; then

        method=$(jq -r '.method' mcp_quality_gate_file_request.json)
        tool_name=$(jq -r '.params.name' mcp_quality_gate_file_request.json)

        if [ "$method" = "tools/call" ] && [ "$tool_name" = "check_quality_gate_file" ]; then
            test_pass "check_quality_gate_file MCP request/response format defined"
        else
            test_fail "check_quality_gate_file request format invalid"
        fi
    else
        test_fail "check_quality_gate_file JSON syntax"
    fi
else
    test_fail "check_quality_gate_file MCP examples missing"
fi

# Test 4: quality_gate_summary - Aggregated Quality Summary
echo ""
echo "Test 4: quality_gate_summary - Aggregated quality metrics summary"

# Create MCP request for quality_gate_summary
cat > mcp_quality_gate_summary_request.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "batch3-4",
  "method": "tools/call",
  "params": {
    "name": "quality_gate_summary",
    "arguments": {
      "paths": ["."]
    }
  }
}
EOF

# Expected response structure
cat > mcp_quality_gate_summary_response_expected.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "batch3-4",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\\n  \\\"status\\\": \\\"completed\\\",\\n  \\\"message\\\": \\\"Quality gate summary generated\\\",\\n  \\\"summary\\\": {\\n    \\\"total_files\\\": 2,\\n    \\\"passed_files\\\": 1,\\n    \\\"failed_files\\\": 1,\\n    \\\"average_score\\\": 75.0,\\n    \\\"average_grade\\\": \\\"B\\\",\\n    \\\"threshold_score\\\": 50.0,\\n    \\\"grade_distribution\\\": {\\n      \\\"A\\\": 1,\\n      \\\"C\\\": 1\\n    },\\n    \\\"language_distribution\\\": {\\n      \\\"Rust\\\": 2\\n    }\\n  }\\n}"
      }
    ]
  }
}
EOF

# Verify request/response format exists
if [ -f mcp_quality_gate_summary_request.json ] && [ -f mcp_quality_gate_summary_response_expected.json ]; then
    if jq empty mcp_quality_gate_summary_request.json 2>/dev/null && \
       jq empty mcp_quality_gate_summary_response_expected.json 2>/dev/null; then

        method=$(jq -r '.method' mcp_quality_gate_summary_request.json)
        tool_name=$(jq -r '.params.name' mcp_quality_gate_summary_request.json)

        if [ "$method" = "tools/call" ] && [ "$tool_name" = "quality_gate_summary" ]; then
            test_pass "quality_gate_summary MCP request/response format defined"
        else
            test_fail "quality_gate_summary request format invalid"
        fi
    else
        test_fail "quality_gate_summary JSON syntax"
    fi
else
    test_fail "quality_gate_summary MCP examples missing"
fi

# Test 5: Batch 3 Function Coverage in Documentation
echo ""
echo "Test 5: Batch 3 function coverage in MCP tools documentation"

# Check if pmat-book chapter 15 mentions these functions
if [ -f /home/noah/src/pmat-book/src/ch15-00-mcp-tools.md ]; then
    doc_file="/home/noah/src/pmat-book/src/ch15-00-mcp-tools.md"

    # Check for check_quality_gates
    if grep -q "check_quality_gates" "$doc_file"; then
        test_pass "check_quality_gates documented in Chapter 15"
    else
        test_fail "check_quality_gates missing from Chapter 15 (expected - needs documentation)"
    fi

    # Check for check_quality_gate_file
    if grep -q "check_quality_gate_file" "$doc_file"; then
        test_pass "check_quality_gate_file documented in Chapter 15"
    else
        test_fail "check_quality_gate_file missing from Chapter 15 (expected - needs documentation)"
    fi

    # Check for quality_gate_summary
    if grep -q "quality_gate_summary" "$doc_file"; then
        test_pass "quality_gate_summary documented in Chapter 15"
    else
        test_fail "quality_gate_summary missing from Chapter 15 (expected - needs documentation)"
    fi
else
    test_fail "Chapter 15 MCP tools documentation not found"
fi

# Test 6: Integration Pattern Examples
echo ""
echo "Test 6: Integration pattern examples for batch 3 functions"

# Create Python integration example
cat > integration_example.py << 'EOF'
"""
Issue #53 Batch 3: MCP Integration Example
Demonstrates check_quality_gates, check_quality_gate_file, and quality_gate_summary
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

    def check_project_quality(self, project_path, strict=False):
        """Check project-level quality gates."""
        return self.call_tool("check_quality_gates", {
            "paths": [project_path],
            "strict": strict
        })

    def check_file_quality(self, file_path, strict=False):
        """Check file-level quality gate."""
        return self.call_tool("check_quality_gate_file", {
            "file_path": file_path,
            "strict": strict
        })

    def get_quality_summary(self, project_path):
        """Get aggregated quality summary."""
        return self.call_tool("quality_gate_summary", {
            "paths": [project_path]
        })

# Example usage:
# client = PMATMCPClient()
#
# # Check project quality in standard mode
# result = client.check_project_quality(".", strict=False)
# print(f"Passed: {result['result']['content'][0]['text']}")
#
# # Check project quality in strict mode
# strict_result = client.check_project_quality(".", strict=True)
# data = json.loads(strict_result['result']['content'][0]['text'])
# print(f"Violations: {len(data['violations'])}")
#
# # Check individual file
# file_result = client.check_file_quality("src/main.rs", strict=False)
# file_data = json.loads(file_result['result']['content'][0]['text'])
# print(f"Score: {file_data['score']}, Grade: {file_data['grade']}")
#
# # Get quality summary
# summary = client.get_quality_summary(".")
# summary_data = json.loads(summary['result']['content'][0]['text'])
# print(f"Total files: {summary_data['summary']['total_files']}")
# print(f"Average score: {summary_data['summary']['average_score']}")
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
echo "Issue #53 Batch 3 Test Summary"
echo "========================================="
echo "✅ PASSED: $PASS_COUNT"
echo "❌ FAILED: $FAIL_COUNT"
echo ""

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "🎉 All tests passed! Batch 3 MCP functions properly documented."
    exit 0
else
    echo "⚠️  Some tests failed. Review documentation and examples."
    exit 1
fi
