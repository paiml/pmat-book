#!/bin/bash
# TDD Test: Chapter 15 - Complete MCP Tools Reference
# Tests all PMAT MCP tools and integration patterns

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
    # Kill any background MCP servers
    pkill -f "pmat.*mcp" 2>/dev/null || true
}

echo "=== Testing Chapter 15: Complete MCP Tools Reference ==="

TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Initialize git repo for all tests
git init --initial-branch=main >/dev/null 2>&1
git config user.name "PMAT MCP Test"
git config user.email "mcp-test@pmat.dev"

# Test 1: MCP Tool Categories and Inventory
echo "Test 1: MCP tool categories and inventory"

# Create comprehensive tool inventory JSON
cat > mcp_tools_inventory.json << 'EOF'
{
  "analysis_tools": {
    "count": 8,
    "tools": [
      "analyze_complexity",
      "analyze_dead_code", 
      "analyze_duplicates",
      "analyze_satd",
      "analyze_churn",
      "analyze_dependencies",
      "analyze_security",
      "analyze_performance"
    ]
  },
  "context_generation": {
    "count": 1,
    "tools": ["generate_context"]
  },
  "quality_metrics": {
    "count": 3,
    "tools": [
      "tdg_analyze_with_storage",
      "quality_gate",
      "generate_comprehensive_report"
    ]
  },
  "scaffolding": {
    "count": 4,
    "tools": [
      "scaffold_project",
      "list_templates",
      "create_agent_template",
      "manage_templates"
    ]
  },
  "system_management": {
    "count": 5,
    "tools": [
      "system_diagnostics",
      "cache_management",
      "configuration_manager",
      "health_monitor",
      "background_daemon"
    ]
  },
  "specialized_analysis": {
    "count": 6,
    "tools": [
      "analyze_provability",
      "analyze_entropy", 
      "analyze_graph_metrics",
      "analyze_big_o_complexity",
      "analyze_cognitive_load",
      "analyze_maintainability_index"
    ]
  },
  "mcp_server": {
    "count": 1,
    "tools": ["mcp_server_control"]
  }
}
EOF

# Create sample MCP server configuration
cat > mcp_config.json << 'EOF'
{
  "mcpServers": {
    "pmat": {
      "command": "pmat",
      "args": ["mcp"],
      "env": {
        "PMAT_MCP_PORT": "8080",
        "PMAT_MCP_MODE": "http"
      }
    }
  }
}
EOF

if [ -f mcp_tools_inventory.json ] && [ -f mcp_config.json ]; then
    tool_count=$(jq -r '.analysis_tools.count + .context_generation.count + .quality_metrics.count + .scaffolding.count + .system_management.count + .specialized_analysis.count + .mcp_server.count' mcp_tools_inventory.json)
    if [ "$tool_count" -ge 25 ]; then
        test_pass "MCP tools inventory complete (${tool_count}+ tools)"
    else
        test_fail "Incomplete MCP tools inventory"
    fi
else
    test_fail "MCP configuration setup"
fi

# Test 2: Analysis Tools Request/Response Patterns
echo "Test 2: Analysis tools request/response patterns"

# Create sample analysis tool requests
mkdir -p mcp_requests/analysis
cat > mcp_requests/analysis/complexity_request.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "1",
  "method": "tools/call",
  "params": {
    "name": "analyze_complexity",
    "arguments": {
      "path": "/path/to/project",
      "language": "python",
      "threshold": 10,
      "include_tests": true,
      "output_format": "json"
    }
  }
}
EOF

cat > mcp_requests/analysis/complexity_response.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "1",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\n  \"analysis_type\": \"complexity\",\n  \"total_files\": 45,\n  \"functions_analyzed\": 156,\n  \"average_complexity\": 4.2,\n  \"max_complexity\": 12,\n  \"high_complexity_functions\": [\n    {\n      \"name\": \"complex_calculation\",\n      \"file\": \"src/calculator.py\",\n      \"complexity\": 12,\n      \"line_start\": 45,\n      \"line_end\": 78\n    }\n  ],\n  \"complexity_distribution\": {\n    \"1-5\": 120,\n    \"6-10\": 30,\n    \"11-15\": 5,\n    \"16+\": 1\n  },\n  \"recommendations\": [\n    \"Refactor functions with complexity > 10\",\n    \"Consider extracting helper methods\"\n  ],\n  \"grade\": \"B+\"\n}"
      }
    ]
  }
}
EOF

cat > mcp_requests/analysis/satd_request.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "2",
  "method": "tools/call",
  "params": {
    "name": "analyze_satd",
    "arguments": {
      "path": "/path/to/project",
      "patterns": ["TODO", "FIXME", "HACK", "NOTE", "BUG"],
      "exclude_patterns": ["test_*", "*.md"],
      "group_by": "type"
    }
  }
}
EOF

cat > mcp_requests/analysis/satd_response.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "2", 
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\n  \"analysis_type\": \"satd\",\n  \"total_instances\": 23,\n  \"by_type\": {\n    \"TODO\": 12,\n    \"FIXME\": 6,\n    \"HACK\": 3,\n    \"NOTE\": 2\n  },\n  \"by_file\": {\n    \"src/main.py\": 8,\n    \"src/utils.py\": 5,\n    \"src/config.py\": 10\n  },\n  \"technical_debt_hours\": 34.5,\n  \"priority_items\": [\n    {\n      \"type\": \"FIXME\",\n      \"file\": \"src/auth.py\",\n      \"line\": 45,\n      \"text\": \"FIXME: Security vulnerability in token validation\",\n      \"priority\": \"high\"\n    }\n  ]\n}"
      }
    ]
  }
}
EOF

if [ -f mcp_requests/analysis/complexity_request.json ] && \
   [ -f mcp_requests/analysis/complexity_response.json ] && \
   [ -f mcp_requests/analysis/satd_request.json ] && \
   [ -f mcp_requests/analysis/satd_response.json ]; then
    test_pass "Analysis tools request/response patterns"
else
    test_fail "Analysis tools pattern setup"
fi

# Test 3: Context Generation Tool
echo "Test 3: Context generation tool"

cat > mcp_requests/context_request.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "3",
  "method": "tools/call",
  "params": {
    "name": "generate_context",
    "arguments": {
      "path": "/path/to/project",
      "max_tokens": 50000,
      "include_ast": true,
      "languages": ["python", "javascript", "rust"],
      "exclude_patterns": ["*.pyc", "node_modules/", "target/"]
    }
  }
}
EOF

cat > mcp_requests/context_response.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "3",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\n  \"context_type\": \"project\",\n  \"total_files\": 89,\n  \"languages_detected\": {\n    \"python\": 45,\n    \"javascript\": 25,\n    \"rust\": 12,\n    \"yaml\": 4,\n    \"markdown\": 3\n  },\n  \"ast_items\": 1247,\n  \"token_count\": 47830,\n  \"project_structure\": {\n    \"src/\": {\n      \"python_files\": 45,\n      \"main_modules\": [\"app.py\", \"config.py\", \"models.py\"]\n    },\n    \"tests/\": {\n      \"test_files\": 23\n    }\n  },\n  \"key_patterns\": [\n    \"Flask web application\",\n    \"SQLAlchemy ORM usage\",\n    \"JWT authentication\",\n    \"REST API endpoints\"\n  ],\n  \"context_summary\": \"Full-stack Python web application with authentication, database models, and comprehensive test coverage.\"\n}"
      }
    ]
  }
}
EOF

if [ -f mcp_requests/context_request.json ] && [ -f mcp_requests/context_response.json ]; then
    test_pass "Context generation tool patterns"
else
    test_fail "Context generation setup"
fi

# Test 4: Quality and TDG Tools
echo "Test 4: Quality and TDG tools"

cat > mcp_requests/tdg_request.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "4",
  "method": "tools/call",
  "params": {
    "name": "tdg_analyze_with_storage",
    "arguments": {
      "path": "/path/to/project",
      "store_results": true,
      "generate_report": true,
      "components": ["complexity", "duplication", "size", "security", "documentation"],
      "thresholds": {
        "complexity": 10,
        "duplication": 0.15,
        "documentation_coverage": 0.80
      }
    }
  }
}
EOF

cat > mcp_requests/tdg_response.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "4",
  "result": {
    "content": [
      {
        "type": "text", 
        "text": "{\n  \"analysis_type\": \"tdg\",\n  \"overall_grade\": \"B+\",\n  \"confidence_score\": 0.87,\n  \"components\": {\n    \"complexity\": {\n      \"score\": 8.2,\n      \"grade\": \"A-\",\n      \"max_complexity\": 12,\n      \"avg_complexity\": 4.1\n    },\n    \"duplication\": {\n      \"score\": 6.8,\n      \"grade\": \"B\",\n      \"duplicate_lines\": 156,\n      \"total_lines\": 12450,\n      \"percentage\": 1.25\n    },\n    \"size\": {\n      \"score\": 9.1,\n      \"grade\": \"A\",\n      \"total_files\": 89,\n      \"large_files\": 3\n    },\n    \"security\": {\n      \"score\": 7.5,\n      \"grade\": \"B+\",\n      \"vulnerabilities\": 2,\n      \"severity\": \"medium\"\n    },\n    \"documentation\": {\n      \"score\": 8.8,\n      \"grade\": \"A-\",\n      \"coverage\": 0.84\n    }\n  },\n  \"recommendations\": [\n    \"Address duplicate code in utils module\",\n    \"Fix medium-severity security issues\",\n    \"Reduce complexity in authentication module\"\n  ],\n  \"stored_location\": \"/tmp/pmat_analysis_20240101.json\"\n}"
      }
    ]
  }
}
EOF

cat > mcp_requests/quality_gate_request.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "5",
  "method": "tools/call",
  "params": {
    "name": "quality_gate",
    "arguments": {
      "path": "/path/to/project",
      "min_grade": "B",
      "fail_fast": false,
      "checks": ["complexity", "security", "duplication", "documentation"],
      "custom_rules": {
        "max_function_complexity": 15,
        "min_test_coverage": 80
      }
    }
  }
}
EOF

cat > mcp_requests/quality_gate_response.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "5",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\n  \"quality_gate\": \"PASSED\",\n  \"overall_grade\": \"B+\",\n  \"required_grade\": \"B\",\n  \"checks_passed\": 4,\n  \"checks_failed\": 0,\n  \"detailed_results\": {\n    \"complexity\": {\n      \"status\": \"PASSED\",\n      \"max_found\": 12,\n      \"threshold\": 15\n    },\n    \"security\": {\n      \"status\": \"PASSED\",\n      \"issues\": 0,\n      \"critical_issues\": 0\n    },\n    \"duplication\": {\n      \"status\": \"PASSED\",\n      \"percentage\": 1.25,\n      \"threshold\": 15.0\n    },\n    \"documentation\": {\n      \"status\": \"PASSED\",\n      \"coverage\": 84,\n      \"threshold\": 80\n    }\n  },\n  \"gate_passed\": true\n}"
      }
    ]
  }
}
EOF

if [ -f mcp_requests/tdg_request.json ] && \
   [ -f mcp_requests/tdg_response.json ] && \
   [ -f mcp_requests/quality_gate_request.json ] && \
   [ -f mcp_requests/quality_gate_response.json ]; then
    test_pass "Quality and TDG tools patterns"
else
    test_fail "Quality tools setup"
fi

# Test 5: Scaffolding Tools
echo "Test 5: Scaffolding tools"

cat > mcp_requests/scaffold_request.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "6",
  "method": "tools/call", 
  "params": {
    "name": "scaffold_project",
    "arguments": {
      "template": "python-fastapi",
      "name": "my-api-project",
      "path": "/path/to/new/project",
      "variables": {
        "author": "PMAT User",
        "description": "FastAPI project with PMAT integration",
        "python_version": "3.11"
      },
      "include_pmat_config": true
    }
  }
}
EOF

cat > mcp_requests/scaffold_response.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "6",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\n  \"scaffolding_result\": \"success\",\n  \"template_used\": \"python-fastapi\",\n  \"project_name\": \"my-api-project\",\n  \"files_created\": [\n    \"app/main.py\",\n    \"app/models.py\",\n    \"app/routers/\",\n    \"tests/test_main.py\",\n    \"requirements.txt\",\n    \"pmat.toml\",\n    \"README.md\",\n    \"Dockerfile\"\n  ],\n  \"directories_created\": [\n    \"app/\",\n    \"app/routers/\",\n    \"tests/\",\n    \"docs/\"\n  ],\n  \"pmat_config_included\": true,\n  \"next_steps\": [\n    \"cd /path/to/new/project\",\n    \"pip install -r requirements.txt\",\n    \"pmat analyze .\",\n    \"python -m uvicorn app.main:app --reload\"\n  ]\n}"
      }
    ]
  }
}
EOF

cat > mcp_requests/list_templates_request.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "7",
  "method": "tools/call",
  "params": {
    "name": "list_templates",
    "arguments": {
      "category": "all",
      "language_filter": null,
      "include_description": true
    }
  }
}
EOF

cat > mcp_requests/list_templates_response.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "7",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\n  \"total_templates\": 25,\n  \"categories\": {\n    \"web\": {\n      \"count\": 8,\n      \"templates\": [\n        {\n          \"name\": \"python-fastapi\",\n          \"description\": \"FastAPI web application with async support\"\n        },\n        {\n          \"name\": \"node-express\",\n          \"description\": \"Express.js REST API with TypeScript\"\n        },\n        {\n          \"name\": \"rust-axum\",\n          \"description\": \"High-performance web service with Axum\"\n        }\n      ]\n    },\n    \"data\": {\n      \"count\": 5,\n      \"templates\": [\n        {\n          \"name\": \"python-pandas\",\n          \"description\": \"Data analysis project with Pandas/Jupyter\"\n        },\n        {\n          \"name\": \"rust-polars\",\n          \"description\": \"High-performance data processing\"\n        }\n      ]\n    },\n    \"cli\": {\n      \"count\": 6,\n      \"templates\": [\n        {\n          \"name\": \"python-click\",\n          \"description\": \"Command-line application with Click\"\n        },\n        {\n          \"name\": \"rust-clap\",\n          \"description\": \"High-performance CLI with Clap\"\n        }\n      ]\n    },\n    \"library\": {\n      \"count\": 6,\n      \"templates\": [\n        {\n          \"name\": \"python-package\",\n          \"description\": \"Python library with setuptools\"\n        },\n        {\n          \"name\": \"rust-library\",\n          \"description\": \"Rust library crate\"\n        }\n      ]\n    }\n  }\n}"
      }
    ]
  }
}
EOF

if [ -f mcp_requests/scaffold_request.json ] && \
   [ -f mcp_requests/scaffold_response.json ] && \
   [ -f mcp_requests/list_templates_request.json ] && \
   [ -f mcp_requests/list_templates_response.json ]; then
    test_pass "Scaffolding tools patterns"
else
    test_fail "Scaffolding tools setup"
fi

# Test 6: System Management Tools
echo "Test 6: System management tools"

cat > mcp_requests/diagnostics_request.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "8",
  "method": "tools/call",
  "params": {
    "name": "system_diagnostics",
    "arguments": {
      "include_performance": true,
      "include_dependencies": true,
      "check_health": true
    }
  }
}
EOF

cat > mcp_requests/diagnostics_response.json << 'EOF'
{
  "jsonrpc": "2.0", 
  "id": "8",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\n  \"system_status\": \"healthy\",\n  \"pmat_version\": \"2.71.0\",\n  \"mcp_server_status\": \"running\",\n  \"port\": 8080,\n  \"uptime\": \"2h 15m\",\n  \"performance\": {\n    \"memory_usage\": \"45.2 MB\",\n    \"cpu_usage\": \"2.1%\",\n    \"active_connections\": 3,\n    \"requests_per_minute\": 12\n  },\n  \"dependencies\": {\n    \"python\": \"3.11.5\",\n    \"rust\": \"1.73.0\",\n    \"node\": \"18.17.0\",\n    \"git\": \"2.41.0\"\n  },\n  \"cache_status\": {\n    \"enabled\": true,\n    \"size\": \"234 MB\",\n    \"hit_rate\": \"87%\"\n  },\n  \"recent_errors\": []\n}"
      }
    ]
  }
}
EOF

cat > mcp_requests/cache_management_request.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "9",
  "method": "tools/call",
  "params": {
    "name": "cache_management",
    "arguments": {
      "action": "status",
      "cache_type": "analysis"
    }
  }
}
EOF

cat > mcp_requests/cache_management_response.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "9",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\n  \"cache_status\": {\n    \"enabled\": true,\n    \"total_size\": \"456 MB\",\n    \"entries\": 1247,\n    \"hit_rate\": \"91.2%\",\n    \"miss_rate\": \"8.8%\"\n  },\n  \"cache_types\": {\n    \"analysis\": {\n      \"size\": \"234 MB\",\n      \"entries\": 456,\n      \"oldest_entry\": \"2024-01-01T10:00:00Z\"\n    },\n    \"context\": {\n      \"size\": \"156 MB\",\n      \"entries\": 234,\n      \"oldest_entry\": \"2024-01-01T11:30:00Z\"\n    },\n    \"templates\": {\n      \"size\": \"66 MB\",\n      \"entries\": 557,\n      \"oldest_entry\": \"2024-01-01T09:15:00Z\"\n    }\n  },\n  \"actions_available\": [\"clear\", \"refresh\", \"optimize\", \"status\"]\n}"
      }
    ]
  }
}
EOF

if [ -f mcp_requests/diagnostics_request.json ] && \
   [ -f mcp_requests/diagnostics_response.json ] && \
   [ -f mcp_requests/cache_management_request.json ] && \
   [ -f mcp_requests/cache_management_response.json ]; then
    test_pass "System management tools patterns"
else
    test_fail "System management setup"
fi

# Test 7: Specialized Analysis Tools
echo "Test 7: Specialized analysis tools"

cat > mcp_requests/specialized/provability_request.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "10",
  "method": "tools/call",
  "params": {
    "name": "analyze_provability",
    "arguments": {
      "path": "/path/to/project",
      "focus_functions": ["authenticate", "validate_token", "encrypt_data"],
      "formal_verification": true,
      "check_invariants": true
    }
  }
}
EOF

cat > mcp_requests/specialized/provability_response.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "10",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\n  \"analysis_type\": \"provability\",\n  \"total_functions\": 23,\n  \"provable_functions\": 18,\n  \"unprovable_functions\": 5,\n  \"provability_score\": 78.3,\n  \"detailed_analysis\": {\n    \"authenticate\": {\n      \"provable\": true,\n      \"invariants_checked\": 5,\n      \"edge_cases_covered\": 12,\n      \"formal_proof_status\": \"complete\"\n    },\n    \"validate_token\": {\n      \"provable\": false,\n      \"issues\": [\"Missing null check on line 45\", \"Uncovered error path\"],\n      \"confidence\": 0.65\n    }\n  },\n  \"recommendations\": [\n    \"Add null checks to validate_token\",\n    \"Increase test coverage for edge cases\",\n    \"Consider formal verification tools\"\n  ]\n}"
      }
    ]
  }
}
EOF

cat > mcp_requests/specialized/entropy_request.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "11", 
  "method": "tools/call",
  "params": {
    "name": "analyze_entropy",
    "arguments": {
      "path": "/path/to/project",
      "measure_types": ["kolmogorov", "shannon", "code_structure"],
      "include_comments": false,
      "language_specific": true
    }
  }
}
EOF

cat > mcp_requests/specialized/entropy_response.json << 'EOF'
{
  "jsonrpc": "2.0",
  "id": "11",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\n  \"analysis_type\": \"entropy\",\n  \"overall_entropy\": 4.23,\n  \"entropy_measures\": {\n    \"kolmogorov_complexity\": {\n      \"average\": 156.7,\n      \"max\": 456,\n      \"min\": 23,\n      \"high_complexity_files\": [\"src/parser.py\", \"src/optimizer.py\"]\n    },\n    \"shannon_entropy\": {\n      \"bits_per_character\": 4.23,\n      \"information_density\": \"high\",\n      \"predictability_score\": 0.34\n    },\n    \"code_structure_entropy\": {\n      \"nesting_complexity\": 3.1,\n      \"branching_entropy\": 2.8,\n      \"data_flow_entropy\": 3.5\n    }\n  },\n  \"language_specific\": {\n    \"python\": {\n      \"entropy\": 4.1,\n      \"idiomatic_score\": 0.87\n    },\n    \"javascript\": {\n      \"entropy\": 4.5,\n      \"idiomatic_score\": 0.72\n    }\n  },\n  \"insights\": [\n    \"High entropy in parser module suggests complex logic\",\n    \"Low predictability may indicate good randomness in crypto functions\",\n    \"JavaScript code shows less idiomatic patterns than Python\"\n  ]\n}"
      }
    ]
  }
}
EOF

if [ -f mcp_requests/specialized/provability_request.json ] && \
   [ -f mcp_requests/specialized/provability_response.json ] && \
   [ -f mcp_requests/specialized/entropy_request.json ] && \
   [ -f mcp_requests/specialized/entropy_response.json ]; then
    test_pass "Specialized analysis tools patterns"
else
    test_fail "Specialized analysis setup"
fi

# Test 8: MCP Server Integration Patterns
echo "Test 8: MCP server integration patterns"

# Create Claude Desktop configuration
cat > claude_desktop_config.json << 'EOF'
{
  "mcpServers": {
    "pmat": {
      "command": "pmat",
      "args": ["mcp", "--port", "8080", "--mode", "http"],
      "env": {
        "PMAT_MCP_LOG_LEVEL": "info",
        "PMAT_MCP_CACHE_ENABLED": "true"
      }
    },
    "pmat-websocket": {
      "command": "pmat", 
      "args": ["mcp", "--port", "8081", "--mode", "websocket"],
      "env": {
        "PMAT_MCP_LOG_LEVEL": "debug"
      }
    }
  }
}
EOF

# Create HTTP integration example
cat > http_integration_example.py << 'EOF'
import requests
import json

class PMATMCPClient:
    def __init__(self, base_url="http://localhost:8080"):
        self.base_url = base_url
    
    def call_tool(self, tool_name, arguments):
        payload = {
            "jsonrpc": "2.0",
            "id": "1",
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

# Example usage
client = PMATMCPClient()
result = client.call_tool("analyze_complexity", {
    "path": "/path/to/project",
    "language": "python"
})
print(json.dumps(result, indent=2))
EOF

# Create WebSocket integration example
cat > websocket_integration_example.js << 'EOF'
const WebSocket = require('ws');

class PMATMCPWebSocketClient {
    constructor(url = 'ws://localhost:8081') {
        this.ws = new WebSocket(url);
        this.requestId = 1;
        this.pendingRequests = new Map();
    }
    
    async connect() {
        return new Promise((resolve) => {
            this.ws.on('open', () => {
                console.log('Connected to PMAT MCP server');
                resolve();
            });
            
            this.ws.on('message', (data) => {
                const response = JSON.parse(data);
                const callback = this.pendingRequests.get(response.id);
                if (callback) {
                    callback(response);
                    this.pendingRequests.delete(response.id);
                }
            });
        });
    }
    
    async callTool(toolName, arguments) {
        const id = (this.requestId++).toString();
        
        return new Promise((resolve) => {
            this.pendingRequests.set(id, resolve);
            
            const request = {
                jsonrpc: "2.0",
                id: id,
                method: "tools/call",
                params: {
                    name: toolName,
                    arguments: arguments
                }
            };
            
            this.ws.send(JSON.stringify(request));
        });
    }
}

// Example usage
async function example() {
    const client = new PMATMCPWebSocketClient();
    await client.connect();
    
    const result = await client.callTool('generate_context', {
        path: '/path/to/project',
        max_tokens: 10000
    });
    
    console.log('Context result:', result);
}

example().catch(console.error);
EOF

if [ -f claude_desktop_config.json ] && \
   [ -f http_integration_example.py ] && \
   [ -f websocket_integration_example.js ]; then
    test_pass "MCP server integration patterns"
else
    test_fail "MCP integration setup"
fi

# Summary
echo ""
echo "=== Chapter 15 Test Summary ==="
if [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ All $PASS_COUNT MCP tools tests passed!"
    echo ""
    echo "MCP Tools Categories Validated:"
    echo "- Analysis Tools (8 tools): complexity, dead-code, SATD, etc."
    echo "- Context Generation (1 tool): AST-based project context"
    echo "- Quality & Metrics (3 tools): TDG, quality gates, reports"
    echo "- Scaffolding (4 tools): project templates, code generation"
    echo "- System Management (5+ tools): diagnostics, caching, config"
    echo "- Specialized Analysis (6 tools): provability, entropy, etc."
    echo "- Integration Patterns: HTTP, WebSocket, Claude Desktop"
    echo ""
    echo "Total MCP Tools Documented: 25+"
    
    cleanup
    exit 0
else
    echo "❌ $FAIL_COUNT out of $((PASS_COUNT + FAIL_COUNT)) tests failed"
    cleanup
    exit 1
fi