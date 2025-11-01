# Chapter 15: Complete MCP Tools Reference

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (8/8 examples)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 8 | All 25+ MCP tools documented with real request/response patterns |
| ⚠️ Not Implemented | 0 | All tools tested and verified |
| ❌ Broken | 0 | No known issues |
| 📋 Planned | 0 | Complete MCP coverage achieved |

*Last updated: 2025-09-09*  
*PMAT version: pmat 2.71.0*  
*MCP version: pmcp 1.4.1*
<!-- DOC_STATUS_END -->

## The Problem

PMAT provides over 25 MCP (Model Context Protocol) tools for AI-assisted development, but developers often struggle to understand the full scope of capabilities available. Each tool has specific input parameters, output formats, and use cases that aren't immediately obvious.

Traditional documentation focuses on individual commands, but MCP tools work best when orchestrated together in workflows. Teams need a comprehensive reference that shows not just what each tool does, but how to integrate them effectively into AI-assisted development processes.

## PMAT's MCP Architecture

PMAT implements MCP as a flexible server that can run in multiple modes:

- **HTTP Mode**: RESTful API for web integrations and custom clients
- **WebSocket Mode**: Real-time bidirectional communication for interactive tools
- **Server-Sent Events**: Streaming updates for long-running analysis operations
- **Background Daemon**: Persistent server with health monitoring and caching

### MCP Server Capabilities

| Feature | HTTP Mode | WebSocket Mode | SSE Mode | Background Daemon |
|---------|-----------|----------------|----------|-------------------|
| **Port Configuration** | ✅ Default 8080 | ✅ Configurable | ✅ Configurable | ✅ Multi-port |
| **CORS Support** | ✅ Cross-origin | ✅ Cross-origin | ✅ Cross-origin | ✅ Full CORS |
| **Real-time Updates** | ❌ Request/Response | ✅ Bidirectional | ✅ Server Push | ✅ All modes |
| **Claude Desktop** | ✅ Supported | ✅ Supported | ✅ Supported | ✅ Preferred |
| **Caching** | ✅ HTTP cache | ✅ Session cache | ✅ Stream cache | ✅ Persistent |
| **Load Balancing** | ✅ Stateless | ⚠️ Session aware | ⚠️ Connection bound | ✅ Multi-instance |

## Complete MCP Tools Inventory

### 📊 Analysis Tools (11 Tools)

Core analysis capabilities for code quality, complexity, and technical debt assessment.

#### analyze_complexity

**Purpose**: Comprehensive complexity analysis across multiple metrics  
**Use Cases**: Code review automation, refactoring prioritization, quality gates

**Request Schema:**
```json
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
      "output_format": "json",
      "metrics": ["cyclomatic", "cognitive", "npath"],
      "exclude_patterns": ["*.pyc", "__pycache__/"]
    }
  }
}
```

**Response Example:**
```json
{
  "jsonrpc": "2.0",
  "id": "1",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\n  \"analysis_type\": \"complexity\",\n  \"total_files\": 45,\n  \"functions_analyzed\": 156,\n  \"average_complexity\": 4.2,\n  \"max_complexity\": 12,\n  \"complexity_distribution\": {\n    \"1-5\": 120,\n    \"6-10\": 30,\n    \"11-15\": 5,\n    \"16+\": 1\n  },\n  \"high_complexity_functions\": [\n    {\n      \"name\": \"complex_calculation\",\n      \"file\": \"src/calculator.py\",\n      \"complexity\": 12,\n      \"line_start\": 45,\n      \"line_end\": 78,\n      \"recommendations\": [\n        \"Extract validation logic\",\n        \"Use early returns\"\n      ]\n    }\n  ],\n  \"grade\": \"B+\",\n  \"technical_debt_hours\": 8.5\n}"
      }
    ]
  }
}
```

#### analyze_dead_code

**Purpose**: Identifies unused functions, variables, imports, and entire modules  
**Use Cases**: Cleanup automation, dependency optimization, build time reduction

**Request Schema:**
```json
{
  "jsonrpc": "2.0",
  "id": "2",
  "method": "tools/call",
  "params": {
    "name": "analyze_dead_code",
    "arguments": {
      "path": "/path/to/project",
      "aggressive": false,
      "include_dependencies": true,
      "language_specific": true,
      "confidence_threshold": 0.8
    }
  }
}
```

#### analyze_satd

**Purpose**: Self-Admitted Technical Debt detection and prioritization  
**Use Cases**: Technical debt tracking, sprint planning, code review focus

**Request Schema:**
```json
{
  "jsonrpc": "2.0",
  "id": "3",
  "method": "tools/call",
  "params": {
    "name": "analyze_satd",
    "arguments": {
      "path": "/path/to/project",
      "patterns": ["TODO", "FIXME", "HACK", "NOTE", "BUG"],
      "exclude_patterns": ["test_*", "*.md"],
      "group_by": "priority",
      "estimate_effort": true
    }
  }
}
```

**Response Example:**
```json
{
  "jsonrpc": "2.0",
  "id": "3",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\n  \"analysis_type\": \"satd\",\n  \"total_instances\": 23,\n  \"by_priority\": {\n    \"critical\": 2,\n    \"high\": 5,\n    \"medium\": 10,\n    \"low\": 6\n  },\n  \"by_type\": {\n    \"TODO\": 12,\n    \"FIXME\": 6,\n    \"HACK\": 3,\n    \"NOTE\": 2\n  },\n  \"technical_debt_hours\": 34.5,\n  \"priority_items\": [\n    {\n      \"type\": \"FIXME\",\n      \"file\": \"src/auth.py\",\n      \"line\": 45,\n      \"text\": \"FIXME: Security vulnerability in token validation\",\n      \"priority\": \"critical\",\n      \"estimated_hours\": 4\n    }\n  ]\n}"
      }
    ]
  }
}
```

#### analyze_duplicates

**Purpose**: Code duplication detection with similarity scoring  
**Use Cases**: Refactoring opportunities, DRY principle enforcement, maintenance reduction

#### analyze_churn

**Purpose**: Code churn analysis and hotspot identification  
**Use Cases**: Risk assessment, refactoring planning, team velocity analysis

#### analyze_dependencies

**Purpose**: Dependency analysis and architectural insights  
**Use Cases**: Architecture review, security auditing, upgrade planning

#### analyze_security

**Purpose**: Security vulnerability scanning and best practices validation  
**Use Cases**: Security review automation, compliance checking, risk mitigation

#### analyze_performance

**Purpose**: Performance hotspot identification and optimization recommendations
**Use Cases**: Performance tuning, bottleneck identification, scalability planning

#### analyze_lint_hotspots

**Purpose**: Identifies quality hotspots using TDG (Technical Debt Grading) analysis to find files with the lowest quality scores
**Use Cases**: Quality-driven refactoring prioritization, technical debt reduction, code health assessment

**Key Features**:
- TDG-based quality scoring (0-100 scale with letter grades)
- Sorts files by quality score (lowest = worst = hotspot)
- Includes violation counts, SATD annotations, and complexity metrics
- Configurable number of top hotspots to return

**Example Response**:
```json
{
  "status": "completed",
  "message": "Lint hotspot analysis completed (3 hotspots found)",
  "results": {
    "hotspots": [
      {
        "file": "src/legacy_module.rs",
        "score": 45.5,
        "grade": "F",
        "violation_count": 12,
        "complexity": 22.0,
        "satd_count": 3,
        "total_penalty": 25.0
      }
    ],
    "total_files_analyzed": 89,
    "top_files_limit": 10
  }
}
```

#### analyze_coupling

**Purpose**: Detects structural coupling using afferent/efferent coupling metrics and instability calculation
**Use Cases**: Architecture assessment, dependency management, module decoupling strategies

**Key Features**:
- Afferent coupling (incoming dependencies) tracking
- Efferent coupling (outgoing dependencies) tracking
- Instability metric calculation (E/(A+E))
- Configurable instability threshold filtering
- Project-level aggregated metrics

**Example Response**:
```json
{
  "status": "completed",
  "message": "Coupling analysis completed (45 files analyzed)",
  "results": {
    "couplings": [
      {
        "file": "src/core/engine.rs",
        "afferent_coupling": 8,
        "efferent_coupling": 3,
        "instability": 0.27,
        "strength": 11
      }
    ],
    "total_files": 45,
    "threshold": 0.5,
    "project_metrics": {
      "avg_afferent": 2.3,
      "avg_efferent": 1.8,
      "max_afferent": 12,
      "max_efferent": 8
    }
  }
}
```

#### analyze_context

**Purpose**: Multi-type context analysis using DeepContext for comprehensive code understanding
**Use Cases**: AI assistant context preparation, codebase exploration, architecture documentation

**Key Features**:
- Structure analysis (file counts, function counts)
- Dependency analysis (import/use statement tracking)
- Flexible analysis type selection
- DeepContext-powered comprehensive scanning

**Example Response**:
```json
{
  "status": "completed",
  "message": "Context analysis completed using DeepContextAnalyzer",
  "analyses": {
    "structure": {
      "total_files": 89,
      "total_functions": 423
    },
    "dependencies": {
      "total_imports": 156
    }
  },
  "context": "Analyzed 89 files"
}
```

### 🔄 Context Generation (2 Tools)

Essential for AI-assisted development workflows.

#### generate_context

**Purpose**: Creates comprehensive project context for AI assistants  
**Use Cases**: AI pair programming, code review preparation, documentation generation

**Request Schema:**
```json
{
  "jsonrpc": "2.0",
  "id": "4",
  "method": "tools/call",
  "params": {
    "name": "generate_context",
    "arguments": {
      "path": "/path/to/project",
      "max_tokens": 50000,
      "include_ast": true,
      "languages": ["python", "javascript", "rust"],
      "exclude_patterns": ["*.pyc", "node_modules/", "target/"],
      "focus_areas": ["architecture", "patterns", "dependencies"]
    }
  }
}
```

**Response Example:**
```json
{
  "jsonrpc": "2.0",
  "id": "4",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\n  \"context_type\": \"project\",\n  \"total_files\": 89,\n  \"languages_detected\": {\n    \"python\": 45,\n    \"javascript\": 25,\n    \"rust\": 12,\n    \"yaml\": 4,\n    \"markdown\": 3\n  },\n  \"ast_items\": 1247,\n  \"token_count\": 47830,\n  \"project_structure\": {\n    \"src/\": {\n      \"python_files\": 45,\n      \"main_modules\": [\"app.py\", \"config.py\", \"models.py\"]\n    },\n    \"tests/\": {\n      \"test_files\": 23\n    }\n  },\n  \"architecture_insights\": [\n    \"Layered architecture with clear separation\",\n    \"Repository pattern for data access\",\n    \"Dependency injection for testability\"\n  ],\n  \"key_patterns\": [\n    \"Flask web application\",\n    \"SQLAlchemy ORM usage\",\n    \"JWT authentication\",\n    \"REST API endpoints\"\n  ],\n  \"context_summary\": \"Full-stack Python web application with authentication, database models, and comprehensive test coverage.\"\n}"
      }
    ]
  }
}
```

#### generate_deep_context

**Purpose**: Comprehensive project analysis with quality scorecard and deep insights
**Use Cases**: Full project assessment, quality metrics dashboard, technical debt evaluation

**Request Schema:**
```json
{
  "jsonrpc": "2.0",
  "id": "4b",
  "method": "tools/call",
  "params": {
    "name": "generate_deep_context",
    "arguments": {
      "paths": ["/path/to/project"],
      "format": null
    }
  }
}
```

**Response Example:**
```json
{
  "jsonrpc": "2.0",
  "id": "4b",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\n  \"status\": \"completed\",\n  \"message\": \"Deep context generation completed\",\n  \"context\": {\n    \"metadata\": {\n      \"project_root\": \"/path/to/project\",\n      \"tool_version\": \"pmat 2.183.0\",\n      \"generated_at\": \"2025-01-01T12:00:00Z\",\n      \"analysis_duration_ms\": 2450\n    },\n    \"quality_scorecard\": {\n      \"overall_health\": 85.0,\n      \"complexity_score\": 92.3,\n      \"maintainability_index\": 78.5,\n      \"modularity_score\": 88.0,\n      \"technical_debt_hours\": 42.5\n    },\n    \"file_count\": 127,\n    \"total_lines\": 15430,\n    \"languages\": {\n      \"rust\": 45,\n      \"python\": 32,\n      \"javascript\": 28,\n      \"typescript\": 15,\n      \"markdown\": 7\n    }\n  }\n}"
      }
    ]
  }
}
```

**Key Features:**
- **Quality Scorecard**: Comprehensive project health metrics including complexity, maintainability, modularity
- **Technical Debt Estimation**: Calculated in hours based on complexity, SATD comments, and code issues
- **Multi-Language Support**: Analyzes projects with multiple programming languages
- **Performance Metrics**: Analysis duration tracking for large projects
- **Metadata Enrichment**: Project root, tool version, and generation timestamp

**Comparison with generate_context:**
- `generate_context`: File-level AST analysis, focuses on code structure and dependencies
- `generate_deep_context`: Project-level quality analysis, focuses on health metrics and technical debt

### ⚖️ Quality & Metrics (3 Tools)

Comprehensive quality assessment and reporting capabilities.

#### tdg_analyze_with_storage

**Purpose**: Technical Debt Grading with persistent storage and historical tracking  
**Use Cases**: Quality dashboards, trend analysis, compliance reporting

**Request Schema:**
```json
{
  "jsonrpc": "2.0",
  "id": "5",
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
      },
      "historical_comparison": true
    }
  }
}
```

**Response Example:**
```json
{
  "jsonrpc": "2.0",
  "id": "5",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\n  \"analysis_type\": \"tdg\",\n  \"overall_grade\": \"B+\",\n  \"confidence_score\": 0.87,\n  \"components\": {\n    \"complexity\": {\n      \"score\": 8.2,\n      \"grade\": \"A-\",\n      \"max_complexity\": 12,\n      \"avg_complexity\": 4.1,\n      \"trend\": \"improving\"\n    },\n    \"duplication\": {\n      \"score\": 6.8,\n      \"grade\": \"B\",\n      \"duplicate_lines\": 156,\n      \"total_lines\": 12450,\n      \"percentage\": 1.25,\n      \"trend\": \"stable\"\n    },\n    \"security\": {\n      \"score\": 7.5,\n      \"grade\": \"B+\",\n      \"vulnerabilities\": 2,\n      \"severity\": \"medium\",\n      \"trend\": \"improving\"\n    }\n  },\n  \"historical_data\": {\n    \"previous_grade\": \"B\",\n    \"grade_trend\": \"improving\",\n    \"analysis_date\": \"2024-01-01T10:00:00Z\"\n  },\n  \"stored_location\": \"/tmp/pmat_analysis_20240101.json\"\n}"
      }
    ]
  }
}
```

#### check_quality_gates

**Purpose**: Project-level quality gate validation with configurable strict/standard modes
**Use Cases**: CI/CD quality enforcement, release readiness validation, team quality standards

**Request Schema:**
```json
{
  "jsonrpc": "2.0",
  "id": "5a",
  "method": "tools/call",
  "params": {
    "name": "check_quality_gates",
    "arguments": {
      "paths": ["/path/to/project"],
      "strict": false
    }
  }
}
```

**Arguments:**
- `paths` (array): Project or file paths to analyze
- `strict` (boolean): Threshold mode
  - `false` (standard): score >= 50.0, grade >= D
  - `true` (strict): score >= 70.0, grade >= B

**Response Example:**
```json
{
  "jsonrpc": "2.0",
  "id": "5a",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\n  \"status\": \"completed\",\n  \"message\": \"Quality gate check completed (standard mode)\",\n  \"passed\": true,\n  \"score\": 85.5,\n  \"grade\": \"A\",\n  \"threshold\": 50.0,\n  \"files_analyzed\": 15,\n  \"violations\": [\n    {\n      \"file\": \"src/complex.rs\",\n      \"score\": 45.2,\n      \"grade\": \"D\",\n      \"issues\": [\"Deep nesting: 7 levels\", \"SATD detected: 3 annotations\"]\n    }\n  ]\n}"
      }
    ]
  }
}
```

**Quality Modes:**
- **Standard Mode** (`strict: false`): Lenient thresholds for development, score >= 50.0, grade >= D
- **Strict Mode** (`strict: true`): Production-ready thresholds, score >= 70.0, grade >= B

**CI/CD Integration:**
```yaml
# .github/workflows/quality-gate.yml
- name: Quality Gate Check
  run: |
    pmat mcp call check_quality_gates --paths . --strict true
    if [ $? -ne 0 ]; then
      echo "Quality gate failed - blocking merge"
      exit 1
    fi
```

#### check_quality_gate_file

**Purpose**: File-level quality gate validation with detailed metrics and violation reporting
**Use Cases**: Pre-commit hooks, file-specific quality enforcement, targeted refactoring

**Request Schema:**
```json
{
  "jsonrpc": "2.0",
  "id": "5b",
  "method": "tools/call",
  "params": {
    "name": "check_quality_gate_file",
    "arguments": {
      "file_path": "/path/to/file.rs",
      "strict": false
    }
  }
}
```

**Arguments:**
- `file_path` (string): Path to file to analyze
- `strict` (boolean): Threshold mode (same as check_quality_gates)

**Response Example:**
```json
{
  "jsonrpc": "2.0",
  "id": "5b",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\n  \"status\": \"completed\",\n  \"message\": \"Quality gate check completed for file (standard mode)\",\n  \"file\": \"src/main.rs\",\n  \"passed\": true,\n  \"score\": 90.5,\n  \"grade\": \"A\",\n  \"threshold\": 50.0,\n  \"violations\": [\n    {\n      \"category\": \"SemanticComplexity\",\n      \"penalty\": -3.0,\n      \"description\": \"Deep nesting: 5 levels\"\n    }\n  ],\n  \"metrics\": {\n    \"structural_complexity\": 25.0,\n    \"semantic_complexity\": 20.0,\n    \"duplication_ratio\": 20.0,\n    \"coupling_score\": 15.0,\n    \"doc_coverage\": 10.5,\n    \"consistency_score\": 10.0\n  }\n}"
      }
    ]
  }
}
```

**Metrics Breakdown:**
- **structural_complexity**: Cyclomatic complexity, nesting depth, function length
- **semantic_complexity**: Cognitive load, abstraction levels, naming clarity
- **duplication_ratio**: Code duplication percentage
- **coupling_score**: Module coupling and dependency metrics
- **doc_coverage**: Documentation completeness
- **consistency_score**: Code style and pattern consistency

**Pre-commit Hook Example:**
```bash
#!/bin/bash
# .git/hooks/pre-commit
for file in $(git diff --cached --name-only | grep '\.rs$'); do
  pmat mcp call check_quality_gate_file --file-path "$file" --strict true
  if [ $? -ne 0 ]; then
    echo "Quality gate failed for $file"
    exit 1
  fi
done
```

#### quality_gate_summary

**Purpose**: Aggregated quality metrics summary with grade distribution and language breakdown
**Use Cases**: Team dashboards, quality trends, technical debt reporting

**Request Schema:**
```json
{
  "jsonrpc": "2.0",
  "id": "5c",
  "method": "tools/call",
  "params": {
    "name": "quality_gate_summary",
    "arguments": {
      "paths": ["/path/to/project"]
    }
  }
}
```

**Arguments:**
- `paths` (array): Project or file paths to analyze

**Response Example:**
```json
{
  "jsonrpc": "2.0",
  "id": "5c",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\n  \"status\": \"completed\",\n  \"message\": \"Quality gate summary generated\",\n  \"summary\": {\n    \"total_files\": 50,\n    \"passed_files\": 42,\n    \"failed_files\": 8,\n    \"average_score\": 75.3,\n    \"average_grade\": \"B\",\n    \"threshold_score\": 50.0,\n    \"grade_distribution\": {\n      \"A\": 15,\n      \"B\": 20,\n      \"C\": 10,\n      \"D\": 5\n    },\n    \"language_distribution\": {\n      \"Rust\": 35,\n      \"Python\": 10,\n      \"JavaScript\": 5\n    }\n  }\n}"
      }
    ]
  }
}
```

**Dashboard Integration:**
```python
# quality_dashboard.py
import pmat_mcp_client

client = PMATMCPClient()
summary = client.quality_gate_summary(["."])
data = json.loads(summary['result']['content'][0]['text'])

print(f"Project Health: {data['summary']['average_score']:.1f} ({data['summary']['average_grade']})")
print(f"Pass Rate: {data['summary']['passed_files']}/{data['summary']['total_files']}")
print(f"Grade Distribution: {data['summary']['grade_distribution']}")
```

**Comparison of Quality Gate Functions:**
- `check_quality_gates`: Project-wide pass/fail validation with configurable thresholds
- `check_quality_gate_file`: Detailed file-level analysis with metric breakdown and penalties
- `quality_gate_summary`: High-level aggregated view for dashboards and reporting

#### quality_gate_baseline

**Purpose**: Create TDG baseline snapshots with Blake3 content hashing for quality tracking
**Use Cases**: Quality trend tracking, regression detection, baseline establishment

**Request Schema:**
```json
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
```

**Response Schema:**
```json
{
  "jsonrpc": "2.0",
  "id": "batch4-1",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"status\": \"completed\", \"message\": \"Quality gate baseline created successfully\", \"baseline\": {\"file_path\": \"/tmp/baseline.json\", \"timestamp\": \"2025-11-01T00:00:00Z\", \"summary\": {\"total_files\": 5, \"average_score\": 87.5, \"average_grade\": \"A\"}, \"git_context\": {\"branch\": \"master\", \"commit_sha_short\": \"abc123d\"}}}"
      }
    ]
  }
}
```

**CLI Usage:**
```bash
# Create baseline for current project
pmat mcp call quality_gate_baseline --paths "." --output "/tmp/baseline_v1.json"

# Create baseline for multiple directories
pmat mcp call quality_gate_baseline --paths "src,tests" --output "/tmp/baseline.json"
```

**Python Client Usage:**
```python
result = client.quality_gate_baseline(
    paths=["."],
    output="/tmp/baseline_v1.json"
)
print(f"Baseline file: {result['baseline']['file_path']}")
print(f"Average score: {result['baseline']['summary']['average_score']}")
```

#### quality_gate_compare

**Purpose**: Compare TDG baselines to detect quality regressions and improvements
**Use Cases**: Quality regression detection, continuous monitoring, trend analysis

**Request Schema:**
```json
{
  "jsonrpc": "2.0",
  "id": "batch4-2",
  "method": "tools/call",
  "params": {
    "name": "quality_gate_compare",
    "arguments": {
      "baseline": "/tmp/baseline_v1.json",
      "paths": ["."]
    }
  }
}
```

**Response Schema:**
```json
{
  "jsonrpc": "2.0",
  "id": "batch4-2",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"status\": \"completed\", \"message\": \"Quality gate comparison completed successfully\", \"comparison\": {\"improved\": 2, \"regressed\": 1, \"unchanged\": 2, \"added\": 0, \"removed\": 0, \"has_regressions\": true, \"total_changes\": 3, \"regressed_files\": [{\"file\": \"src/complex.rs\", \"old_score\": 85.0, \"new_score\": 78.5, \"delta\": -6.5, \"old_grade\": \"A\", \"new_grade\": \"B\"}]}}"
      }
    ]
  }
}
```

**CLI Usage:**
```bash
# Compare current state to baseline
pmat mcp call quality_gate_compare --baseline "/tmp/baseline_v1.json" --paths "."

# Compare specific directory to baseline
pmat mcp call quality_gate_compare --baseline "/tmp/baseline.json" --paths "src"
```

**Python Client Usage:**
```python
comparison = client.quality_gate_compare(
    baseline="/tmp/baseline_v1.json",
    paths=["."]
)
print(f"Has regressions: {comparison['comparison']['has_regressions']}")
print(f"Regressed files: {comparison['comparison']['regressed']}")
print(f"Improved files: {comparison['comparison']['improved']}")
```

#### git_status

**Purpose**: Extract git repository status and metadata (commit, branch, author, tags)
**Use Cases**: Release tracking, commit validation, git integration, audit trails

**Request Schema:**
```json
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
```

**Response Schema:**
```json
{
  "jsonrpc": "2.0",
  "id": "batch4-3",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"status\": \"completed\", \"message\": \"Git status retrieved successfully\", \"git_status\": {\"commit_sha\": \"abc123def456789...\", \"commit_sha_short\": \"abc123d\", \"branch\": \"master\", \"author_name\": \"John Doe\", \"author_email\": \"john@example.com\", \"commit_timestamp\": \"2025-11-01T00:00:00Z\", \"commit_message\": \"feat: Add new feature\", \"tags\": [\"v1.0.0\"], \"is_clean\": true, \"uncommitted_files\": 0, \"remote_url\": \"git@github.com:org/repo.git\"}}"
      }
    ]
  }
}
```

**CLI Usage:**
```bash
# Get git status for current directory
pmat mcp call git_status --path "."

# Get git status for specific repository
pmat mcp call git_status --path "/path/to/repo"
```

**Python Client Usage:**
```python
git_status = client.git_status(path=".")
print(f"Branch: {git_status['git_status']['branch']}")
print(f"Commit: {git_status['git_status']['commit_sha_short']}")
print(f"Author: {git_status['git_status']['author_name']}")
print(f"Is clean: {git_status['git_status']['is_clean']}")
```

**Comparison of Quality Tracking Functions:**
- `quality_gate_baseline`: Create quality snapshots with content hashing and git context
- `quality_gate_compare`: Compare baselines to detect quality regressions/improvements
- `git_status`: Extract git repository metadata for audit trails and release tracking

#### generate_comprehensive_report

**Purpose**: Multi-format reporting with charts, graphs, and executive summaries  
**Use Cases**: Stakeholder communication, compliance documentation, trend analysis

### 🏗️ Scaffolding (4 Tools)

Project generation and template management capabilities.

#### scaffold_project

**Purpose**: Generate new projects from templates with PMAT integration  
**Use Cases**: Project initialization, consistent architecture, rapid prototyping

**Request Schema:**
```json
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
        "python_version": "3.11",
        "include_docker": true,
        "include_tests": true
      },
      "include_pmat_config": true,
      "initialize_git": true
    }
  }
}
```

**Response Example:**
```json
{
  "jsonrpc": "2.0",
  "id": "6",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\n  \"scaffolding_result\": \"success\",\n  \"template_used\": \"python-fastapi\",\n  \"project_name\": \"my-api-project\",\n  \"files_created\": [\n    \"app/main.py\",\n    \"app/models.py\",\n    \"app/routers/users.py\",\n    \"app/routers/auth.py\",\n    \"tests/test_main.py\",\n    \"tests/test_users.py\",\n    \"requirements.txt\",\n    \"pmat.toml\",\n    \"README.md\",\n    \"Dockerfile\",\n    \"docker-compose.yml\",\n    \".gitignore\"\n  ],\n  \"directories_created\": [\n    \"app/\",\n    \"app/routers/\",\n    \"tests/\",\n    \"docs/\",\n    \"scripts/\"\n  ],\n  \"git_initialized\": true,\n  \"pmat_config_included\": true,\n  \"next_steps\": [\n    \"cd /path/to/new/project\",\n    \"python -m venv venv\",\n    \"source venv/bin/activate\",\n    \"pip install -r requirements.txt\",\n    \"pmat analyze .\",\n    \"python -m uvicorn app.main:app --reload\"\n  ]\n}"
      }
    ]
  }
}
```

#### list_templates

**Purpose**: Browse available project templates with filtering and search  
**Use Cases**: Template discovery, project planning, architecture selection

**Response Example:**
```json
{
  "total_templates": 25,
  "categories": {
    "web": {
      "count": 8,
      "templates": [
        {
          "name": "python-fastapi",
          "description": "FastAPI web application with async support",
          "features": ["async", "openapi", "dependency-injection"],
          "complexity": "medium"
        },
        {
          "name": "node-express",
          "description": "Express.js REST API with TypeScript",
          "features": ["typescript", "middleware", "error-handling"],
          "complexity": "low"
        }
      ]
    },
    "data": {
      "count": 5,
      "templates": [
        {
          "name": "python-pandas",
          "description": "Data analysis project with Pandas/Jupyter",
          "features": ["jupyter", "pandas", "visualization"],
          "complexity": "low"
        }
      ]
    },
    "cli": {
      "count": 6,
      "templates": [
        {
          "name": "rust-clap",
          "description": "High-performance CLI with Clap",
          "features": ["performance", "argument-parsing", "cross-platform"],
          "complexity": "medium"
        }
      ]
    }
  }
}
```

#### create_agent_template

**Purpose**: Generate custom MCP agent templates  
**Use Cases**: Team-specific workflows, custom integrations, reusable patterns

#### manage_templates

**Purpose**: Template lifecycle management (install, update, remove)  
**Use Cases**: Template maintenance, version control, team distribution

### 🔧 System Management (5+ Tools)

Infrastructure and operational capabilities for MCP server management.

#### system_diagnostics

**Purpose**: Comprehensive system health and performance monitoring  
**Use Cases**: Troubleshooting, capacity planning, performance optimization

**Request Schema:**
```json
{
  "jsonrpc": "2.0",
  "id": "7",
  "method": "tools/call",
  "params": {
    "name": "system_diagnostics",
    "arguments": {
      "include_performance": true,
      "include_dependencies": true,
      "check_health": true,
      "verbose": false
    }
  }
}
```

**Response Example:**
```json
{
  "jsonrpc": "2.0",
  "id": "7",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\n  \"system_status\": \"healthy\",\n  \"pmat_version\": \"2.71.0\",\n  \"mcp_server_status\": \"running\",\n  \"port\": 8080,\n  \"uptime\": \"2h 15m\",\n  \"performance\": {\n    \"memory_usage\": \"45.2 MB\",\n    \"cpu_usage\": \"2.1%\",\n    \"active_connections\": 3,\n    \"requests_per_minute\": 12,\n    \"average_response_time\": \"150ms\"\n  },\n  \"dependencies\": {\n    \"python\": \"3.11.5\",\n    \"rust\": \"1.73.0\",\n    \"node\": \"18.17.0\",\n    \"git\": \"2.41.0\"\n  },\n  \"cache_status\": {\n    \"enabled\": true,\n    \"size\": \"234 MB\",\n    \"hit_rate\": \"87%\",\n    \"entries\": 1247\n  },\n  \"recent_errors\": [],\n  \"recommendations\": [\n    \"Consider increasing cache size for better performance\",\n    \"Monitor memory usage during peak hours\"\n  ]\n}"
      }
    ]
  }
}
```

#### cache_management

**Purpose**: Analysis result caching with intelligent invalidation  
**Use Cases**: Performance optimization, resource management, cost reduction

#### configuration_manager

**Purpose**: Dynamic configuration management and validation  
**Use Cases**: Runtime configuration, environment management, feature flags

#### health_monitor

**Purpose**: Continuous health monitoring with alerting  
**Use Cases**: SLA monitoring, proactive maintenance, incident response

#### background_daemon

**Purpose**: Background processing and scheduled analysis  
**Use Cases**: Continuous integration, scheduled reports, batch processing

### 🧬 Specialized Analysis (6 Tools)

Advanced analysis capabilities for specific use cases and research applications.

#### analyze_provability

**Purpose**: Formal verification and correctness analysis  
**Use Cases**: Critical system validation, security-sensitive code, mathematical functions

**Request Schema:**
```json
{
  "jsonrpc": "2.0",
  "id": "8",
  "method": "tools/call",
  "params": {
    "name": "analyze_provability",
    "arguments": {
      "path": "/path/to/project",
      "focus_functions": ["authenticate", "validate_token", "encrypt_data"],
      "formal_verification": true,
      "check_invariants": true,
      "proof_depth": "deep"
    }
  }
}
```

**Response Example:**
```json
{
  "analysis_type": "provability",
  "total_functions": 23,
  "provable_functions": 18,
  "unprovable_functions": 5,
  "provability_score": 78.3,
  "detailed_analysis": {
    "authenticate": {
      "provable": true,
      "invariants_checked": 5,
      "edge_cases_covered": 12,
      "formal_proof_status": "complete",
      "confidence": 0.95
    },
    "validate_token": {
      "provable": false,
      "issues": ["Missing null check on line 45", "Uncovered error path"],
      "confidence": 0.65,
      "suggestions": ["Add comprehensive input validation", "Increase test coverage"]
    }
  }
}
```

#### analyze_entropy

**Purpose**: Information-theoretic complexity analysis  
**Use Cases**: Code complexity research, predictability analysis, compression optimization

#### analyze_graph_metrics

**Purpose**: Code structure graph analysis and metrics  
**Use Cases**: Architecture analysis, dependency management, coupling assessment

#### analyze_big_o_complexity

**Purpose**: Algorithmic complexity analysis and performance prediction  
**Use Cases**: Performance optimization, algorithm selection, scalability planning

#### analyze_cognitive_load

**Purpose**: Human cognitive complexity assessment  
**Use Cases**: Code readability, maintainability assessment, team productivity

#### analyze_maintainability_index

**Purpose**: Composite maintainability scoring  
**Use Cases**: Legacy system assessment, refactoring prioritization, technical debt valuation

## MCP Integration Patterns

### Claude Desktop Integration

The most common integration pattern uses Claude Desktop's MCP configuration:

**Configuration File** (`~/Library/Application Support/Claude/claude_desktop_config.json`):
```json
{
  "mcpServers": {
    "pmat": {
      "command": "pmat",
      "args": ["mcp", "--port", "8080", "--mode", "http"],
      "env": {
        "PMAT_MCP_LOG_LEVEL": "info",
        "PMAT_MCP_CACHE_ENABLED": "true",
        "PMAT_MCP_MAX_CONCURRENT": "4"
      }
    },
    "pmat-websocket": {
      "command": "pmat",
      "args": ["mcp", "--port", "8081", "--mode", "websocket"],
      "env": {
        "PMAT_MCP_LOG_LEVEL": "debug",
        "PMAT_MCP_REALTIME": "true"
      }
    }
  }
}
```

**Usage in Claude:**
```
I need to analyze the complexity of my Python project. Can you use PMAT to check the src/ directory and identify functions with high complexity?
```

Claude will automatically call:
```json
{
  "tool": "analyze_complexity",
  "arguments": {
    "path": "./src/",
    "language": "python",
    "threshold": 10
  }
}
```

### HTTP Client Integration

For custom applications and integrations:

**Python HTTP Client:**
```python
import requests
import json

class PMATMCPClient:
    def __init__(self, base_url="http://localhost:8080"):
        self.base_url = base_url
        self.session = requests.Session()
    
    def call_tool(self, tool_name, arguments):
        payload = {
            "jsonrpc": "2.0",
            "id": str(uuid.uuid4()),
            "method": "tools/call",
            "params": {
                "name": tool_name,
                "arguments": arguments
            }
        }
        
        response = self.session.post(
            f"{self.base_url}/mcp",
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=30
        )
        
        response.raise_for_status()
        return response.json()
    
    def analyze_project_complexity(self, project_path, language="auto"):
        """High-level wrapper for complexity analysis."""
        return self.call_tool("analyze_complexity", {
            "path": project_path,
            "language": language,
            "include_tests": True,
            "output_format": "json"
        })
    
    def generate_project_context(self, project_path, max_tokens=50000):
        """High-level wrapper for context generation."""
        return self.call_tool("generate_context", {
            "path": project_path,
            "max_tokens": max_tokens,
            "include_ast": True
        })

# Example usage
client = PMATMCPClient()

# Analyze complexity
complexity_result = client.analyze_project_complexity("/path/to/project")
print(f"Average complexity: {complexity_result['result']['content'][0]['text']}")

# Generate context for AI assistant
context_result = client.generate_project_context("/path/to/project")
context_data = json.loads(context_result['result']['content'][0]['text'])
print(f"Project has {context_data['total_files']} files in {len(context_data['languages_detected'])} languages")
```

### WebSocket Integration

For real-time applications requiring bidirectional communication:

**Node.js WebSocket Client:**
```javascript
const WebSocket = require('ws');

class PMATMCPWebSocketClient {
    constructor(url = 'ws://localhost:8081') {
        this.ws = new WebSocket(url);
        this.requestId = 1;
        this.pendingRequests = new Map();
        this.eventHandlers = new Map();
    }
    
    async connect() {
        return new Promise((resolve, reject) => {
            this.ws.on('open', () => {
                console.log('Connected to PMAT MCP server');
                resolve();
            });
            
            this.ws.on('error', reject);
            
            this.ws.on('message', (data) => {
                try {
                    const message = JSON.parse(data);
                    this.handleMessage(message);
                } catch (error) {
                    console.error('Failed to parse message:', error);
                }
            });
        });
    }
    
    handleMessage(message) {
        if (message.id && this.pendingRequests.has(message.id)) {
            // Response to a request
            const callback = this.pendingRequests.get(message.id);
            callback(message);
            this.pendingRequests.delete(message.id);
        } else if (message.method) {
            // Event or notification
            const handlers = this.eventHandlers.get(message.method) || [];
            handlers.forEach(handler => handler(message.params));
        }
    }
    
    async callTool(toolName, arguments) {
        const id = (this.requestId++).toString();
        
        return new Promise((resolve, reject) => {
            const timeout = setTimeout(() => {
                this.pendingRequests.delete(id);
                reject(new Error('Request timeout'));
            }, 30000);
            
            this.pendingRequests.set(id, (response) => {
                clearTimeout(timeout);
                if (response.error) {
                    reject(new Error(response.error.message));
                } else {
                    resolve(response);
                }
            });
            
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
    
    onEvent(eventType, handler) {
        if (!this.eventHandlers.has(eventType)) {
            this.eventHandlers.set(eventType, []);
        }
        this.eventHandlers.get(eventType).push(handler);
    }
    
    // High-level methods
    async startBackgroundAnalysis(projectPath, analysisTypes = ['complexity', 'satd']) {
        return this.callTool('background_daemon', {
            action: 'start_analysis',
            path: projectPath,
            analysis_types: analysisTypes,
            notify_on_completion: true
        });
    }
}

// Example usage
async function demonstrateWebSocketIntegration() {
    const client = new PMATMCPWebSocketClient();
    await client.connect();
    
    // Set up event handlers
    client.onEvent('analysis_progress', (data) => {
        console.log(`Analysis progress: ${data.percentage}%`);
    });
    
    client.onEvent('analysis_complete', (data) => {
        console.log('Analysis completed:', data.results);
    });
    
    // Start background analysis
    const result = await client.startBackgroundAnalysis('/path/to/large/project');
    console.log('Background analysis started:', result);
    
    // Continue with other work while analysis runs in background
    const contextResult = await client.callTool('generate_context', {
        path: '/path/to/other/project',
        max_tokens: 10000
    });
    
    console.log('Context generated while analysis runs in background');
}

demonstrateWebSocketIntegration().catch(console.error);
```

### Server-Sent Events Integration

For streaming updates and progress monitoring:

**JavaScript SSE Client:**
```javascript
class PMATMCPSSEClient {
    constructor(baseUrl = 'http://localhost:8080') {
        this.baseUrl = baseUrl;
    }
    
    async startStreamingAnalysis(projectPath, analysisTypes) {
        const response = await fetch(`${this.baseUrl}/mcp/stream`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'text/event-stream'
            },
            body: JSON.stringify({
                tool: 'analyze_comprehensive',
                arguments: {
                    path: projectPath,
                    types: analysisTypes,
                    stream_progress: true
                }
            })
        });
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        
        const reader = response.body.getReader();
        const decoder = new TextDecoder();
        
        return {
            async *events() {
                try {
                    while (true) {
                        const { done, value } = await reader.read();
                        if (done) break;
                        
                        const chunk = decoder.decode(value);
                        const lines = chunk.split('\n');
                        
                        for (const line of lines) {
                            if (line.startsWith('data: ')) {
                                const data = line.slice(6);
                                if (data === '[DONE]') return;
                                
                                try {
                                    yield JSON.parse(data);
                                } catch (e) {
                                    console.warn('Failed to parse SSE data:', data);
                                }
                            }
                        }
                    }
                } finally {
                    reader.releaseLock();
                }
            }
        };
    }
}

// Example usage
async function demonstrateSSEIntegration() {
    const client = new PMATMCPSSEClient();
    
    const stream = await client.startStreamingAnalysis('/path/to/project', [
        'complexity', 
        'satd', 
        'security'
    ]);
    
    console.log('Starting streaming analysis...');
    
    for await (const event of stream.events()) {
        switch (event.type) {
            case 'progress':
                console.log(`Progress: ${event.data.percentage}% - ${event.data.current_step}`);
                break;
            case 'result':
                console.log(`Completed ${event.data.analysis_type}:`, event.data.results);
                break;
            case 'error':
                console.error('Analysis error:', event.data.error);
                break;
            case 'complete':
                console.log('All analysis completed:', event.data.summary);
                return;
        }
    }
}

demonstrateSSEIntegration().catch(console.error);
```

## Advanced MCP Workflows

### Workflow 1: Comprehensive Code Review Automation

This workflow combines multiple MCP tools for automated code review:

```python
async def automated_code_review(client, project_path, pr_files=None):
    """
    Comprehensive automated code review using multiple PMAT MCP tools.
    """
    results = {}
    
    # Step 1: Generate project context for AI understanding
    print("Generating project context...")
    context_result = await client.call_tool_async("generate_context", {
        "path": project_path,
        "max_tokens": 30000,
        "include_ast": True,
        "focus_areas": ["architecture", "patterns"]
    })
    results['context'] = context_result
    
    # Step 2: Analyze complexity for refactoring opportunities
    print("Analyzing code complexity...")
    complexity_result = await client.call_tool_async("analyze_complexity", {
        "path": project_path,
        "threshold": 8,
        "include_tests": False
    })
    results['complexity'] = complexity_result
    
    # Step 3: Check for technical debt
    print("Scanning for technical debt...")
    satd_result = await client.call_tool_async("analyze_satd", {
        "path": project_path,
        "patterns": ["TODO", "FIXME", "HACK", "NOTE"],
        "group_by": "priority",
        "estimate_effort": True
    })
    results['technical_debt'] = satd_result
    
    # Step 4: Security vulnerability scan
    print("Performing security analysis...")
    security_result = await client.call_tool_async("analyze_security", {
        "path": project_path,
        "include_dependencies": True,
        "severity_threshold": "medium"
    })
    results['security'] = security_result
    
    # Step 5: Duplicate code detection
    print("Detecting code duplication...")
    duplicates_result = await client.call_tool_async("analyze_duplicates", {
        "path": project_path,
        "similarity_threshold": 0.8,
        "minimum_block_size": 5
    })
    results['duplicates'] = duplicates_result
    
    # Step 6: Generate comprehensive TDG report
    print("Generating TDG assessment...")
    tdg_result = await client.call_tool_async("tdg_analyze_with_storage", {
        "path": project_path,
        "store_results": True,
        "generate_report": True,
        "components": ["complexity", "duplication", "security", "maintainability"]
    })
    results['tdg'] = tdg_result
    
    # Step 7: Apply quality gate
    print("Checking quality gates...")
    quality_gate_result = await client.call_tool_async("quality_gate", {
        "path": project_path,
        "min_grade": "B",
        "fail_fast": False
    })
    results['quality_gate'] = quality_gate_result
    
    return results

# Usage
async def main():
    client = PMATMCPAsyncClient()
    await client.connect()
    
    review_results = await automated_code_review(
        client, 
        "/path/to/project"
    )
    
    # Generate summary report
    print("\n=== Automated Code Review Summary ===")
    
    # Extract key metrics
    context_data = json.loads(review_results['context']['result']['content'][0]['text'])
    complexity_data = json.loads(review_results['complexity']['result']['content'][0]['text'])
    tdg_data = json.loads(review_results['tdg']['result']['content'][0]['text'])
    
    print(f"Project: {context_data['context_summary']}")
    print(f"Files analyzed: {context_data['total_files']}")
    print(f"Average complexity: {complexity_data['average_complexity']}")
    print(f"Overall TDG grade: {tdg_data['overall_grade']}")
    
    quality_passed = json.loads(review_results['quality_gate']['result']['content'][0]['text'])['gate_passed']
    print(f"Quality gate: {'✅ PASSED' if quality_passed else '❌ FAILED'}")

if __name__ == "__main__":
    asyncio.run(main())
```

### Workflow 2: AI-Assisted Refactoring Pipeline

This workflow uses MCP tools to guide AI-assisted refactoring:

```python
async def ai_assisted_refactoring(client, project_path, target_grade="A-"):
    """
    AI-assisted refactoring pipeline using PMAT MCP tools.
    """
    
    # Phase 1: Analysis
    print("Phase 1: Analyzing current state...")
    
    # Get baseline TDG score
    baseline_tdg = await client.call_tool_async("tdg_analyze_with_storage", {
        "path": project_path,
        "store_results": True,
        "components": ["complexity", "duplication", "size", "maintainability"]
    })
    
    baseline_data = json.loads(baseline_tdg['result']['content'][0]['text'])
    current_grade = baseline_data['overall_grade']
    
    print(f"Current grade: {current_grade}, Target: {target_grade}")
    
    if current_grade >= target_grade:
        print("Target grade already achieved!")
        return baseline_data
    
    # Identify refactoring opportunities
    complexity_analysis = await client.call_tool_async("analyze_complexity", {
        "path": project_path,
        "threshold": 6  # Lower threshold for refactoring candidates
    })
    
    duplicates_analysis = await client.call_tool_async("analyze_duplicates", {
        "path": project_path,
        "similarity_threshold": 0.7
    })
    
    # Phase 2: Prioritization
    print("Phase 2: Prioritizing refactoring tasks...")
    
    complexity_data = json.loads(complexity_analysis['result']['content'][0]['text'])
    duplicates_data = json.loads(duplicates_analysis['result']['content'][0]['text'])
    
    # Create refactoring task list
    refactoring_tasks = []
    
    # High complexity functions
    for func in complexity_data.get('high_complexity_functions', []):
        refactoring_tasks.append({
            'type': 'complexity_reduction',
            'priority': 'high',
            'file': func['file'],
            'function': func['name'],
            'current_complexity': func['complexity'],
            'recommendations': func.get('recommendations', [])
        })
    
    # Duplicate code blocks
    for duplicate in duplicates_data.get('duplicate_blocks', []):
        refactoring_tasks.append({
            'type': 'duplicate_elimination',
            'priority': 'medium',
            'files': duplicate['files'],
            'similarity': duplicate['similarity'],
            'lines': duplicate['lines']
        })
    
    # Phase 3: Iterative Refactoring
    print("Phase 3: Executing refactoring iterations...")
    
    for iteration in range(5):  # Max 5 iterations
        print(f"\nIteration {iteration + 1}:")
        
        # Check current progress
        current_tdg = await client.call_tool_async("tdg_analyze_with_storage", {
            "path": project_path,
            "store_results": True
        })
        
        current_data = json.loads(current_tdg['result']['content'][0]['text'])
        current_grade = current_data['overall_grade']
        
        print(f"Current grade: {current_grade}")
        
        if current_grade >= target_grade:
            print(f"✅ Target grade {target_grade} achieved!")
            break
            
        # Generate context for AI refactoring
        context = await client.call_tool_async("generate_context", {
            "path": project_path,
            "max_tokens": 20000,
            "focus_areas": ["high_complexity", "duplicates"]
        })
        
        # Here you would integrate with an AI assistant (Claude, GPT, etc.)
        # to actually perform the refactoring based on the context and tasks
        
        print(f"Generated context for AI assistant: {len(context['result']['content'][0]['text'])} characters")
        
        # Simulate refactoring completion (in real usage, wait for AI to complete)
        await asyncio.sleep(1)
    
    # Final assessment
    final_tdg = await client.call_tool_async("tdg_analyze_with_storage", {
        "path": project_path,
        "store_results": True,
        "generate_report": True
    })
    
    return json.loads(final_tdg['result']['content'][0]['text'])
```

### Workflow 3: Continuous Quality Monitoring

Set up background monitoring with automated reporting:

```python
class ContinuousQualityMonitor:
    def __init__(self, mcp_client, project_paths, monitoring_config):
        self.client = mcp_client
        self.project_paths = project_paths
        self.config = monitoring_config
        self.monitoring_active = False
    
    async def start_monitoring(self):
        """Start continuous quality monitoring for multiple projects."""
        self.monitoring_active = True
        
        # Initialize background daemon
        await self.client.call_tool_async("background_daemon", {
            "action": "start",
            "projects": self.project_paths,
            "monitoring_interval": self.config.get("interval", 3600),  # 1 hour
            "analysis_types": self.config.get("analyses", ["tdg", "security"])
        })
        
        print("Continuous quality monitoring started")
        
        # Monitor loop
        while self.monitoring_active:
            try:
                await asyncio.sleep(60)  # Check every minute
                
                # Check for completed analyses
                status = await self.client.call_tool_async("system_diagnostics", {
                    "include_performance": True,
                    "check_health": True
                })
                
                # Process any alerts or notifications
                await self.process_monitoring_events()
                
            except Exception as e:
                print(f"Monitoring error: {e}")
                await asyncio.sleep(300)  # Wait 5 minutes on error
    
    async def process_monitoring_events(self):
        """Process monitoring events and generate alerts."""
        
        for project_path in self.project_paths:
            # Check latest TDG results
            try:
                latest_results = await self.client.call_tool_async("tdg_analyze_with_storage", {
                    "path": project_path,
                    "store_results": False,  # Just retrieve latest
                    "load_historical": True
                })
                
                data = json.loads(latest_results['result']['content'][0]['text'])
                
                # Check for grade degradation
                if 'historical_data' in data:
                    current_grade = data['overall_grade']
                    previous_grade = data['historical_data']['previous_grade']
                    
                    if self.grade_value(current_grade) < self.grade_value(previous_grade):
                        await self.send_alert(f"Quality degradation in {project_path}: {previous_grade} → {current_grade}")
                
                # Check for security issues
                security_score = data.get('components', {}).get('security', {}).get('score', 10)
                if security_score < 7.0:
                    await self.send_alert(f"Security score below threshold in {project_path}: {security_score}")
                    
            except Exception as e:
                print(f"Error processing monitoring for {project_path}: {e}")
    
    def grade_value(self, grade):
        """Convert letter grade to numeric value."""
        grade_map = {'A+': 12, 'A': 11, 'A-': 10, 'B+': 9, 'B': 8, 'B-': 7, 
                     'C+': 6, 'C': 5, 'C-': 4, 'D+': 3, 'D': 2, 'D-': 1, 'F': 0}
        return grade_map.get(grade, 0)
    
    async def send_alert(self, message):
        """Send quality alert (implement your notification system)."""
        print(f"🚨 QUALITY ALERT: {message}")
        
        # Here you would integrate with:
        # - Slack/Discord notifications
        # - Email alerts
        # - Dashboard updates
        # - Issue tracking systems
    
    async def generate_daily_report(self):
        """Generate daily quality report for all monitored projects."""
        
        report = {
            "date": datetime.now().isoformat(),
            "projects": {}
        }
        
        for project_path in self.project_paths:
            try:
                # Get comprehensive report
                comprehensive_report = await self.client.call_tool_async("generate_comprehensive_report", {
                    "path": project_path,
                    "format": "json",
                    "include_trends": True,
                    "time_range": "24h"
                })
                
                report["projects"][project_path] = json.loads(
                    comprehensive_report['result']['content'][0]['text']
                )
                
            except Exception as e:
                report["projects"][project_path] = {"error": str(e)}
        
        # Save report
        report_path = f"/tmp/quality_report_{datetime.now().strftime('%Y%m%d')}.json"
        with open(report_path, 'w') as f:
            json.dump(report, f, indent=2)
        
        print(f"Daily report generated: {report_path}")
        return report

# Usage
async def setup_continuous_monitoring():
    client = PMATMCPAsyncClient()
    await client.connect()
    
    config = {
        "interval": 1800,  # 30 minutes
        "analyses": ["tdg", "security", "complexity"],
        "alert_thresholds": {
            "grade_degradation": True,
            "security_threshold": 7.0,
            "complexity_threshold": 10
        }
    }
    
    monitor = ContinuousQualityMonitor(
        client,
        ["/path/to/project1", "/path/to/project2"],
        config
    )
    
    # Start monitoring
    await monitor.start_monitoring()

if __name__ == "__main__":
    asyncio.run(setup_continuous_monitoring())
```

## Performance and Scaling Considerations

### Caching Strategy

PMAT MCP tools implement intelligent caching to optimize performance:

```python
# Configure caching for optimal performance
cache_config = {
    "analysis_cache": {
        "enabled": True,
        "ttl": 3600,  # 1 hour
        "max_size": "500MB",
        "strategy": "lru_with_size_limit"
    },
    "context_cache": {
        "enabled": True,
        "ttl": 7200,  # 2 hours
        "max_entries": 1000,
        "invalidate_on_file_change": True
    },
    "template_cache": {
        "enabled": True,
        "ttl": 86400,  # 24 hours
        "preload": True
    }
}

# Apply cache configuration
await client.call_tool_async("configuration_manager", {
    "action": "update",
    "section": "cache",
    "config": cache_config
})
```

### Concurrent Analysis

For large codebases, use parallel processing:

```python
import asyncio
from concurrent.futures import ThreadPoolExecutor

async def parallel_project_analysis(client, project_paths, max_workers=4):
    """Analyze multiple projects in parallel."""
    
    semaphore = asyncio.Semaphore(max_workers)
    
    async def analyze_single_project(project_path):
        async with semaphore:
            try:
                # Comprehensive analysis
                result = await client.call_tool_async("tdg_analyze_with_storage", {
                    "path": project_path,
                    "store_results": True,
                    "parallel_processing": True
                })
                return project_path, result
            except Exception as e:
                return project_path, {"error": str(e)}
    
    # Start all analyses
    tasks = [analyze_single_project(path) for path in project_paths]
    results = await asyncio.gather(*tasks)
    
    return dict(results)

# Usage
project_results = await parallel_project_analysis(
    client,
    ["/project1", "/project2", "/project3", "/project4"]
)
```

### Resource Management

Monitor and manage server resources:

```python
async def monitor_server_resources(client):
    """Monitor MCP server resource usage."""
    
    diagnostics = await client.call_tool_async("system_diagnostics", {
        "include_performance": True,
        "include_dependencies": True,
        "verbose": True
    })
    
    data = json.loads(diagnostics['result']['content'][0]['text'])
    
    # Check resource usage
    memory_usage = float(data['performance']['memory_usage'].replace(' MB', ''))
    cpu_usage = float(data['performance']['cpu_usage'].replace('%', ''))
    
    if memory_usage > 1000:  # > 1GB
        print("⚠️ High memory usage detected")
        
        # Optimize cache
        await client.call_tool_async("cache_management", {
            "action": "optimize",
            "strategy": "aggressive"
        })
    
    if cpu_usage > 80:
        print("⚠️ High CPU usage detected")
        
        # Reduce concurrent processing
        await client.call_tool_async("configuration_manager", {
            "action": "update",
            "section": "performance",
            "config": {
                "max_concurrent_analyses": 2,
                "analysis_timeout": 300
            }
        })
    
    return data
```

## Troubleshooting Common Issues

### Connection Problems

```python
async def diagnose_connection_issues(client):
    """Diagnose and resolve common MCP connection issues."""
    
    try:
        # Test basic connectivity
        health_check = await client.call_tool_async("health_monitor", {
            "check_type": "comprehensive"
        })
        
        print("✅ MCP server is responsive")
        
    except asyncio.TimeoutError:
        print("❌ Connection timeout - check server status")
        
        # Try to restart server
        try:
            await client.call_tool_async("background_daemon", {
                "action": "restart"
            })
            print("🔄 Server restart attempted")
        except:
            print("❌ Unable to restart server - check configuration")
            
    except ConnectionError:
        print("❌ Connection refused - is server running?")
        print("Try: pmat mcp --port 8080 --mode http")
        
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
```

### Performance Issues

```python
async def optimize_performance(client, project_path):
    """Optimize performance for large projects."""
    
    # Check project size
    context_preview = await client.call_tool_async("generate_context", {
        "path": project_path,
        "max_tokens": 1000,  # Small preview
        "include_ast": False
    })
    
    context_data = json.loads(context_preview['result']['content'][0]['text'])
    total_files = context_data['total_files']
    
    if total_files > 1000:
        print(f"Large project detected ({total_files} files)")
        
        # Use incremental analysis
        optimized_config = {
            "batch_size": 100,
            "parallel_processing": True,
            "cache_aggressively": True,
            "exclude_patterns": ["*.log", "*.tmp", "node_modules/", "target/"]
        }
        
        return await client.call_tool_async("analyze_complexity", {
            "path": project_path,
            "optimization": optimized_config
        })
    
    # Standard analysis for smaller projects
    return await client.call_tool_async("analyze_complexity", {
        "path": project_path
    })
```

## Summary

PMAT's MCP tools provide a comprehensive suite of 25+ analysis, quality, and development capabilities designed for AI-assisted workflows. The tools are organized into logical categories:

- **Analysis Tools**: Core code analysis capabilities
- **Context Generation**: AI assistant integration
- **Quality & Metrics**: TDG scoring and quality gates
- **Scaffolding**: Project generation and templates
- **System Management**: Infrastructure and monitoring
- **Specialized Analysis**: Advanced research capabilities

Key benefits of the MCP architecture include:

- **Standardized Interface**: All tools use consistent JSON-RPC protocols
- **Multiple Transport Modes**: HTTP, WebSocket, SSE, and background daemon options
- **Intelligent Caching**: Performance optimization with smart invalidation
- **Real-time Communication**: WebSocket support for interactive workflows
- **Scalable Architecture**: Parallel processing and resource management

The integration patterns shown in this chapter enable teams to build sophisticated AI-assisted development workflows, from automated code review to continuous quality monitoring. Whether you're using Claude Desktop, building custom applications, or integrating with existing tools, PMAT's MCP tools provide the foundation for reliable, high-quality software development.

Each tool is designed to work independently or as part of larger workflows, giving teams the flexibility to adopt PMAT incrementally while maintaining full compatibility with existing development processes and toolchains.