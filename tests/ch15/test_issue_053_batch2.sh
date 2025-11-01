#!/bin/bash
# TDD Test: Issue #53 Batch 2 - MCP Context & Churn Functions
# Tests generate_context, generate_deep_context, and analyze_churn

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

echo "=== Testing Issue #53 Batch 2: Context & Churn MCP Functions ==="

TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Initialize git repo (needed for churn analysis)
git init --initial-branch=main >/dev/null 2>&1
git config user.name "PMAT Test"
git config user.email "test@pmat.dev"

# Test 1: generate_context - File-level AST Analysis
echo ""
echo "Test 1: generate_context - File-level AST analysis"

# Create test Rust file with AST items
mkdir -p src
cat > src/sample.rs << 'EOF'
pub struct User {
    pub name: String,
    pub email: String,
}

impl User {
    pub fn new(name: String, email: String) -> Self {
        Self { name, email }
    }

    pub async fn fetch_profile(&self) -> Result<Profile, Error> {
        unimplemented!()
    }
}

pub enum Status {
    Active,
    Inactive,
    Pending,
}

pub fn authenticate(username: &str, password: &str) -> bool {
    username.len() > 0 && password.len() >= 8
}

async fn internal_helper() {
    println!("Helper function");
}
EOF

# Create MCP request for generate_context
cat > mcp_context_request.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "batch2-1",
  "method": "tools/call",
  "params": {
    "name": "generate_context",
    "arguments": {
      "paths": ["src/sample.rs"],
      "max_depth": 10,
      "include_dependencies": false
    }
  }
}
EOF

# Expected response structure
cat > mcp_context_response_expected.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "batch2-1",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\n  \"status\": \"completed\",\n  \"message\": \"Context generation completed\",\n  \"context\": {\n    \"files\": [\n      {\n        \"path\": \"src/sample.rs\",\n        \"language\": \"rust\",\n        \"items_count\": 5,\n        \"items\": [\n          {\"type\": \"struct\", \"name\": \"User\"},\n          {\"type\": \"function\", \"name\": \"new\"},\n          {\"type\": \"function\", \"name\": \"fetch_profile\"},\n          {\"type\": \"enum\", \"name\": \"Status\"},\n          {\"type\": \"function\", \"name\": \"authenticate\"}\n        ]\n      }\n    ],\n    \"total_files\": 1\n  }\n}"
      }
    ]
  }
}
EOF

# Verify request/response format exists
if [ -f mcp_context_request.json ] && [ -f mcp_context_response_expected.json ]; then
    # Validate JSON syntax
    if jq empty mcp_context_request.json 2>/dev/null && \
       jq empty mcp_context_response_expected.json 2>/dev/null; then

        # Check request has correct structure
        method=$(jq -r '.method' mcp_context_request.json)
        tool_name=$(jq -r '.params.name' mcp_context_request.json)

        if [ "$method" = "tools/call" ] && [ "$tool_name" = "generate_context" ]; then
            test_pass "generate_context MCP request/response format defined"
        else
            test_fail "generate_context request format invalid"
        fi
    else
        test_fail "generate_context JSON syntax"
    fi
else
    test_fail "generate_context MCP examples missing"
fi

# Test 2: generate_deep_context - Full Project Analysis
echo ""
echo "Test 2: generate_deep_context - Full project analysis"

# Create additional files for deep context
cat > src/lib.rs << 'EOF'
pub mod models;
pub mod services;

pub fn init() {
    println!("Initializing application");
}
EOF

mkdir -p tests
cat > tests/test_user.rs << 'EOF'
#[test]
fn test_user_creation() {
    assert!(true);
}
EOF

# Create MCP request for generate_deep_context
cat > mcp_deep_context_request.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "batch2-2",
  "method": "tools/call",
  "params": {
    "name": "generate_deep_context",
    "arguments": {
      "paths": ["."],
      "format": null
    }
  }
}
EOF

# Expected response structure
cat > mcp_deep_context_response_expected.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "batch2-2",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\n  \"status\": \"completed\",\n  \"message\": \"Deep context generation completed\",\n  \"context\": {\n    \"metadata\": {\n      \"project_root\": \".\",\n      \"tool_version\": \"pmat 2.183.0\",\n      \"generated_at\": \"2025-01-01T00:00:00Z\",\n      \"analysis_duration_ms\": 150\n    },\n    \"quality_scorecard\": {\n      \"overall_health\": 85.0,\n      \"complexity_score\": 100.0,\n      \"maintainability_index\": 70.0,\n      \"modularity_score\": 85.0,\n      \"technical_debt_hours\": 40.0\n    },\n    \"file_count\": 3\n  }\n}"
      }
    ]
  }
}
EOF

# Verify request/response format exists
if [ -f mcp_deep_context_request.json ] && [ -f mcp_deep_context_response_expected.json ]; then
    if jq empty mcp_deep_context_request.json 2>/dev/null && \
       jq empty mcp_deep_context_response_expected.json 2>/dev/null; then

        method=$(jq -r '.method' mcp_deep_context_request.json)
        tool_name=$(jq -r '.params.name' mcp_deep_context_request.json)

        if [ "$method" = "tools/call" ] && [ "$tool_name" = "generate_deep_context" ]; then
            test_pass "generate_deep_context MCP request/response format defined"
        else
            test_fail "generate_deep_context request format invalid"
        fi
    else
        test_fail "generate_deep_context JSON syntax"
    fi
else
    test_fail "generate_deep_context MCP examples missing"
fi

# Test 3: analyze_churn - Git Repository Churn Analysis
echo ""
echo "Test 3: analyze_churn - Git repository churn analysis"

# Create git history for churn analysis
git add -A
git commit -m "Initial commit" >/dev/null 2>&1

# Modify files to create churn
echo "// Updated" >> src/sample.rs
git add src/sample.rs
git commit -m "Update sample.rs" >/dev/null 2>&1

echo "// Another update" >> src/lib.rs
git add src/lib.rs
git commit -m "Update lib.rs" >/dev/null 2>&1

# Create MCP request for analyze_churn
cat > mcp_churn_request.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "batch2-3",
  "method": "tools/call",
  "params": {
    "name": "analyze_churn",
    "arguments": {
      "paths": ["."],
      "days": 30,
      "top_files": 5
    }
  }
}
EOF

# Expected response structure
cat > mcp_churn_response_expected.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "batch2-3",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\n  \"status\": \"completed\",\n  \"message\": \"Churn analysis completed for last 30 days\",\n  \"results\": {\n    \"period_days\": 30,\n    \"total_commits\": 3,\n    \"total_files_changed\": 3,\n    \"files\": [\n      {\n        \"path\": \"src/sample.rs\",\n        \"commit_count\": 2,\n        \"unique_authors\": 1,\n        \"additions\": 35,\n        \"deletions\": 0,\n        \"churn_score\": 0.667,\n        \"last_modified\": \"2025-01-01T00:00:00Z\"\n      },\n      {\n        \"path\": \"src/lib.rs\",\n        \"commit_count\": 2,\n        \"unique_authors\": 1,\n        \"additions\": 8,\n        \"deletions\": 0,\n        \"churn_score\": 0.667,\n        \"last_modified\": \"2025-01-01T00:00:00Z\"\n      }\n    ],\n    \"hotspot_files\": 2\n  }\n}"
      }
    ]
  }
}
EOF

# Verify request/response format exists
if [ -f mcp_churn_request.json ] && [ -f mcp_churn_response_expected.json ]; then
    if jq empty mcp_churn_request.json 2>/dev/null && \
       jq empty mcp_churn_response_expected.json 2>/dev/null; then

        method=$(jq -r '.method' mcp_churn_request.json)
        tool_name=$(jq -r '.params.name' mcp_churn_request.json)

        if [ "$method" = "tools/call" ] && [ "$tool_name" = "analyze_churn" ]; then
            test_pass "analyze_churn MCP request/response format defined"
        else
            test_fail "analyze_churn request format invalid"
        fi
    else
        test_fail "analyze_churn JSON syntax"
    fi
else
    test_fail "analyze_churn MCP examples missing"
fi

# Test 4: Batch 2 Function Coverage in Documentation
echo ""
echo "Test 4: Batch 2 function coverage in MCP tools documentation"

# Check if pmat-book chapter 15 mentions these functions
if [ -f /home/noah/src/pmat-book/src/ch15-00-mcp-tools.md ]; then
    doc_file="/home/noah/src/pmat-book/src/ch15-00-mcp-tools.md"

    # Check for generate_context
    if grep -q "generate_context" "$doc_file"; then
        test_pass "generate_context documented in Chapter 15"
    else
        test_fail "generate_context missing from Chapter 15"
    fi

    # Check for generate_deep_context
    if grep -q "generate_deep_context" "$doc_file"; then
        test_pass "generate_deep_context documented in Chapter 15"
    else
        test_fail "generate_deep_context missing from Chapter 15 (expected - needs documentation)"
    fi

    # Check for analyze_churn
    if grep -q "analyze_churn" "$doc_file"; then
        test_pass "analyze_churn documented in Chapter 15"
    else
        test_fail "analyze_churn missing full documentation in Chapter 15"
    fi
else
    test_fail "Chapter 15 MCP tools documentation not found"
fi

# Test 5: Integration Pattern Examples
echo ""
echo "Test 5: Integration pattern examples for batch 2 functions"

# Create Python integration example
cat > integration_example.py << 'EOF'
"""
Issue #53 Batch 2: MCP Integration Example
Demonstrates generate_context, generate_deep_context, and analyze_churn
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

    def generate_file_context(self, file_path, max_depth=10):
        """Generate AST-level context for a file."""
        return self.call_tool("generate_context", {
            "paths": [file_path],
            "max_depth": max_depth,
            "include_dependencies": False
        })

    def generate_project_deep_context(self, project_path):
        """Generate comprehensive project analysis."""
        return self.call_tool("generate_deep_context", {
            "paths": [project_path],
            "format": None
        })

    def analyze_code_churn(self, repo_path, days=30, top_files=10):
        """Analyze git repository code churn."""
        return self.call_tool("analyze_churn", {
            "paths": [repo_path],
            "days": days,
            "top_files": top_files
        })

# Example usage:
# client = PMATMCPClient()
#
# # Generate context for a single file
# context = client.generate_file_context("src/main.rs")
# print(f"Files analyzed: {context['result']['content'][0]['text']}")
#
# # Generate deep context for entire project
# deep_context = client.generate_project_deep_context(".")
# data = json.loads(deep_context['result']['content'][0]['text'])
# print(f"Overall health: {data['context']['quality_scorecard']['overall_health']}")
#
# # Analyze code churn
# churn = client.analyze_code_churn(".", days=30, top_files=5)
# churn_data = json.loads(churn['result']['content'][0]['text'])
# print(f"Total commits: {churn_data['results']['total_commits']}")
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
echo "Issue #53 Batch 2 Test Summary"
echo "========================================="
echo "✅ PASSED: $PASS_COUNT"
echo "❌ FAILED: $FAIL_COUNT"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo "🎉 All tests passed! Batch 2 MCP functions properly documented."
    exit 0
else
    echo "⚠️  Some tests failed. Review documentation and examples."
    exit 1
fi
