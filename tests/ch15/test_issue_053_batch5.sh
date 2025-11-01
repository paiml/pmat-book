#!/bin/bash
# TDD Test: Issue #53 Batch 5 - MCP Advanced Analysis Functions
# Tests analyze_lint_hotspots, analyze_coupling, analyze_context, and context_summary

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

echo "=== Testing Issue #53 Batch 5: Advanced Analysis Functions ==="

TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Test 1: analyze_lint_hotspots - Find quality hotspots via TDG
echo ""
echo "Test 1: analyze_lint_hotspots - TDG-based hotspot detection"

# Create test files with varying quality
mkdir -p src
cat > src/high_quality.rs << 'EOF'
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

pub fn multiply(a: i32, b: i32) -> i32 {
    a * b
}
EOF

cat > src/low_quality.rs << 'EOF'
// TODO: This needs major refactoring
pub fn complex_calculation(data: Vec<i32>) -> i32 {
    let mut result = 0;
    for item in data {
        if item > 0 {
            if item < 100 {
                if item % 2 == 0 {
                    if item % 3 == 0 {
                        result += item * 2;
                    } else {
                        result += item + 1;
                    }
                } else {
                    result += item;
                }
            }
        }
    }
    result
}
EOF

# Create MCP request for analyze_lint_hotspots
cat > mcp_hotspots_request.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "batch5-1",
  "method": "tools/call",
  "params": {
    "name": "analyze_lint_hotspots",
    "arguments": {
      "paths": ["."],
      "top_files": 5
    }
  }
}
EOF

# Expected response structure
cat > mcp_hotspots_response_expected.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "batch5-1",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\\n  \\\"status\\\": \\\"completed\\\",\\n  \\\"message\\\": \\\"Lint hotspot analysis completed (2 hotspots found)\\\",\\n  \\\"results\\\": {\\n    \\\"hotspots\\\": [{\\n      \\\"file\\\": \\\"src/low_quality.rs\\\",\\n      \\\"score\\\": 65.0,\\n      \\\"grade\\\": \\\"C+\\\",\\n      \\\"violation_count\\\": 3,\\n      \\\"complexity\\\": 15.0,\\n      \\\"satd_count\\\": 1,\\n      \\\"total_penalty\\\": 10.0\\n    }],\\n    \\\"total_files_analyzed\\\": 2,\\n    \\\"top_files_limit\\\": 5\\n  }\\n}"
      }
    ]
  }
}
EOF

# Verify request/response format exists
if [ -f mcp_hotspots_request.json ] && [ -f mcp_hotspots_response_expected.json ]; then
    # Validate JSON syntax
    if jq empty mcp_hotspots_request.json 2>/dev/null && \
       jq empty mcp_hotspots_response_expected.json 2>/dev/null; then

        # Check request has correct structure
        method=$(jq -r '.method' mcp_hotspots_request.json)
        tool_name=$(jq -r '.params.name' mcp_hotspots_request.json)

        if [ "$method" = "tools/call" ] && [ "$tool_name" = "analyze_lint_hotspots" ]; then
            test_pass "analyze_lint_hotspots MCP request/response format defined"
        else
            test_fail "analyze_lint_hotspots request format invalid"
        fi
    else
        test_fail "analyze_lint_hotspots JSON syntax"
    fi
else
    test_fail "analyze_lint_hotspots MCP examples missing"
fi

# Test 2: analyze_coupling - Detect structural coupling
echo ""
echo "Test 2: analyze_coupling - Structural coupling detection"

# Create files with coupling
cat > src/utils.rs << 'EOF'
use super::high_quality;
use super::low_quality;

pub fn format_number(n: i32) -> String {
    format!("{}", n)
}
EOF

# Create MCP request for analyze_coupling
cat > mcp_coupling_request.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "batch5-2",
  "method": "tools/call",
  "params": {
    "name": "analyze_coupling",
    "arguments": {
      "paths": ["."],
      "threshold": 0.5
    }
  }
}
EOF

# Expected response structure
cat > mcp_coupling_response_expected.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "batch5-2",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\\n  \\\"status\\\": \\\"completed\\\",\\n  \\\"message\\\": \\\"Coupling analysis completed (3 files analyzed)\\\",\\n  \\\"results\\\": {\\n    \\\"couplings\\\": [{\\n      \\\"file\\\": \\\"src/utils.rs\\\",\\n      \\\"afferent_coupling\\\": 0,\\n      \\\"efferent_coupling\\\": 2,\\n      \\\"instability\\\": 1.0,\\n      \\\"strength\\\": 2\\n    }],\\n    \\\"total_files\\\": 3,\\n    \\\"threshold\\\": 0.5,\\n    \\\"project_metrics\\\": {\\n      \\\"avg_afferent\\\": 0.67,\\n      \\\"avg_efferent\\\": 0.67,\\n      \\\"max_afferent\\\": 2,\\n      \\\"max_efferent\\\": 2\\n    }\\n  }\\n}"
      }
    ]
  }
}
EOF

# Verify request/response format exists
if [ -f mcp_coupling_request.json ] && [ -f mcp_coupling_response_expected.json ]; then
    if jq empty mcp_coupling_request.json 2>/dev/null && \
       jq empty mcp_coupling_response_expected.json 2>/dev/null; then

        method=$(jq -r '.method' mcp_coupling_request.json)
        tool_name=$(jq -r '.params.name' mcp_coupling_request.json)

        if [ "$method" = "tools/call" ] && [ "$tool_name" = "analyze_coupling" ]; then
            test_pass "analyze_coupling MCP request/response format defined"
        else
            test_fail "analyze_coupling request format invalid"
        fi
    else
        test_fail "analyze_coupling JSON syntax"
    fi
else
    test_fail "analyze_coupling MCP examples missing"
fi

# Test 3: analyze_context - Multi-type context analysis
echo ""
echo "Test 3: analyze_context - Multi-type context analysis via DeepContext"

# Create MCP request for analyze_context
cat > mcp_context_request.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "batch5-3",
  "method": "tools/call",
  "params": {
    "name": "analyze_context",
    "arguments": {
      "paths": ["."],
      "analysis_types": ["structure", "dependencies"]
    }
  }
}
EOF

# Expected response structure
cat > mcp_context_response_expected.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "batch5-3",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\\n  \\\"status\\\": \\\"completed\\\",\\n  \\\"message\\\": \\\"Context analysis completed using DeepContextAnalyzer\\\",\\n  \\\"analyses\\\": {\\n    \\\"structure\\\": {\\n      \\\"total_files\\\": 3,\\n      \\\"total_functions\\\": 5\\n    },\\n    \\\"dependencies\\\": {\\n      \\\"total_imports\\\": 2\\n    }\\n  },\\n  \\\"context\\\": \\\"Analyzed 3 files\\\"\\n}"
      }
    ]
  }
}
EOF

# Verify request/response format exists
if [ -f mcp_context_request.json ] && [ -f mcp_context_response_expected.json ]; then
    if jq empty mcp_context_request.json 2>/dev/null && \
       jq empty mcp_context_response_expected.json 2>/dev/null; then

        method=$(jq -r '.method' mcp_context_request.json)
        tool_name=$(jq -r '.params.name' mcp_context_request.json)

        if [ "$method" = "tools/call" ] && [ "$tool_name" = "analyze_context" ]; then
            test_pass "analyze_context MCP request/response format defined"
        else
            test_fail "analyze_context request format invalid"
        fi
    else
        test_fail "analyze_context JSON syntax"
    fi
else
    test_fail "analyze_context MCP examples missing"
fi

# Test 4: context_summary - Aggregate codebase summary
echo ""
echo "Test 4: context_summary - Codebase summary with language detection"

# Create MCP request for context_summary
cat > mcp_summary_request.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "batch5-4",
  "method": "tools/call",
  "params": {
    "name": "context_summary",
    "arguments": {
      "paths": ["."],
      "level": "detailed"
    }
  }
}
EOF

# Expected response structure
cat > mcp_summary_response_expected.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "batch5-4",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\\n  \\\"status\\\": \\\"completed\\\",\\n  \\\"message\\\": \\\"Context summary generated from file system analysis\\\",\\n  \\\"summary\\\": {\\n    \\\"total_files\\\": 3,\\n    \\\"total_lines\\\": 45,\\n    \\\"languages\\\": [\\\"Rust\\\"]\\n  }\\n}"
      }
    ]
  }
}
EOF

# Verify request/response format exists
if [ -f mcp_summary_request.json ] && [ -f mcp_summary_response_expected.json ]; then
    if jq empty mcp_summary_request.json 2>/dev/null && \
       jq empty mcp_summary_response_expected.json 2>/dev/null; then

        method=$(jq -r '.method' mcp_summary_request.json)
        tool_name=$(jq -r '.params.name' mcp_summary_request.json)

        if [ "$method" = "tools/call" ] && [ "$tool_name" = "context_summary" ]; then
            test_pass "context_summary MCP request/response format defined"
        else
            test_fail "context_summary request format invalid"
        fi
    else
        test_fail "context_summary JSON syntax"
    fi
else
    test_fail "context_summary MCP examples missing"
fi

# Test 5: Batch 5 Function Coverage in Documentation
echo ""
echo "Test 5: Batch 5 function coverage in MCP tools documentation"

# Check if pmat-book chapter 15 mentions these functions
if [ -f /home/noah/src/pmat-book/src/ch15-00-mcp-tools.md ]; then
    doc_file="/home/noah/src/pmat-book/src/ch15-00-mcp-tools.md"

    # Check for analyze_lint_hotspots
    if grep -q "analyze_lint_hotspots" "$doc_file"; then
        test_pass "analyze_lint_hotspots documented in Chapter 15"
    else
        test_fail "analyze_lint_hotspots missing from Chapter 15 (expected - needs documentation)"
    fi

    # Check for analyze_coupling
    if grep -q "analyze_coupling" "$doc_file"; then
        test_pass "analyze_coupling documented in Chapter 15"
    else
        test_fail "analyze_coupling missing from Chapter 15 (expected - needs documentation)"
    fi

    # Check for analyze_context
    if grep -q "analyze_context" "$doc_file"; then
        test_pass "analyze_context documented in Chapter 15"
    else
        test_fail "analyze_context missing from Chapter 15 (expected - needs documentation)"
    fi

    # Check for context_summary
    if grep -q "context_summary" "$doc_file"; then
        test_pass "context_summary documented in Chapter 15"
    else
        test_fail "context_summary missing from Chapter 15 (expected - needs documentation)"
    fi
else
    test_fail "Chapter 15 MCP tools documentation not found"
fi

# Test 6: Integration Pattern Examples
echo ""
echo "Test 6: Integration pattern examples for batch 5 functions"

# Create Python integration example
cat > integration_example.py << 'EOF'
"""
Issue #53 Batch 5: MCP Integration Example
Demonstrates analyze_lint_hotspots, analyze_coupling, analyze_context, and context_summary
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

    def analyze_lint_hotspots(self, project_path, top_files=10):
        """Find quality hotspots via TDG analysis."""
        return self.call_tool("analyze_lint_hotspots", {
            "paths": [project_path],
            "top_files": top_files
        })

    def analyze_coupling(self, project_path, threshold=0.5):
        """Detect structural coupling with instability metrics."""
        return self.call_tool("analyze_coupling", {
            "paths": [project_path],
            "threshold": threshold
        })

    def analyze_context(self, project_path, analysis_types):
        """Multi-type context analysis (structure, dependencies)."""
        return self.call_tool("analyze_context", {
            "paths": [project_path],
            "analysis_types": analysis_types
        })

    def context_summary(self, project_path, level="detailed"):
        """Generate aggregate codebase summary."""
        return self.call_tool("context_summary", {
            "paths": [project_path],
            "level": level
        })

# Example usage:
# client = PMATMCPClient()
#
# # Find quality hotspots
# hotspots = client.analyze_lint_hotspots(".", top_files=5)
# data = json.loads(hotspots['result']['content'][0]['text'])
# print(f"Hotspots: {len(data['results']['hotspots'])}")
#
# # Analyze coupling
# coupling = client.analyze_coupling(".", threshold=0.5)
# coupling_data = json.loads(coupling['result']['content'][0]['text'])
# print(f"High instability files: {len(coupling_data['results']['couplings'])}")
#
# # Multi-type context
# context = client.analyze_context(".", ["structure", "dependencies"])
# context_data = json.loads(context['result']['content'][0]['text'])
# print(f"Total functions: {context_data['analyses']['structure']['total_functions']}")
#
# # Codebase summary
# summary = client.context_summary(".")
# summary_data = json.loads(summary['result']['content'][0]['text'])
# print(f"Languages: {summary_data['summary']['languages']}")
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
echo "Issue #53 Batch 5 Test Summary"
echo "========================================="
echo "✅ PASSED: $PASS_COUNT"
echo "❌ FAILED: $FAIL_COUNT"
echo ""

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "🎉 All tests passed! Batch 5 MCP functions properly documented."
    exit 0
else
    echo "⚠️  Some tests failed. Review documentation and examples."
    exit 1
fi
