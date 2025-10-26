# Chapter 3: MCP Protocol

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working

| Status | Count | Description |
|--------|-------|-------------|
| ✅ Working | 19 | All MCP tools documented and tested |
| ⚠️ Not Implemented | 0 | Complete MCP integration |
| ❌ Broken | 0 | No known issues |
| 📋 Planned | 0 | Core MCP features complete |

*Last updated: 2025-10-19*
*PMAT version: pmat 2.164.0*
*MCP version: v2024-11-05*
<!-- DOC_STATUS_END -->

## Overview

The Model Context Protocol (MCP) enables seamless integration between PMAT and AI agents like Claude, ChatGPT, and custom AI assistants. PMAT provides 19 MCP tools across 6 categories for comprehensive code analysis, quality assessment, and AI-assisted development.

**Protocol Version**: MCP v2024-11-05
**Total Tools**: 19
**Transport**: HTTP/1.1 (JSON-RPC 2.0)

## What is MCP?

Model Context Protocol (MCP) is a standardized protocol for AI agents to interact with tools and services. PMAT exposes its code analysis capabilities via MCP, enabling:

- **AI-powered code review** - Automated quality analysis with actionable recommendations
- **Automated documentation validation** - Zero hallucinations via semantic entropy detection
- **Quality gate integration** - Technical Debt Grading (TDG) for CI/CD pipelines
- **Technical debt analysis** - Comprehensive code quality metrics with A+ to F grades
- **WebAssembly deep analysis** - Bytecode-level optimization and issue detection

## Quick Start

### 1. Start the MCP Server

```bash
# Start with default configuration (localhost:3000)
pmat mcp-server

# Start with custom bind address
pmat mcp-server --bind 127.0.0.1:8080
```

### 2. Connect a Client

#### TypeScript/JavaScript Client

```javascript
import { McpClient } from '@modelcontextprotocol/sdk';

const client = new McpClient({
  endpoint: 'http://localhost:3000',
  protocolVersion: '2024-11-05'
});

await client.connect();
await client.initialize({
  clientInfo: {
    name: "my-ai-agent",
    version: "1.0.0"
  }
});
```

#### Python Client

```python
from mcp import Client

client = Client(
    endpoint="http://localhost:3000",
    protocol_version="2024-11-05"
)

await client.connect()
```

### 3. Call a Tool

```javascript
// Validate documentation against codebase
const result = await client.callTool('validate_documentation', {
  documentation_path: 'README.md',
  deep_context_path: 'deep_context.md',
  similarity_threshold: 0.7,
  fail_on_error: true
});

// Analyze technical debt
const analysis = await client.callTool('analyze_technical_debt', {
  path: 'src/main.rs',
  include_penalties: true
});

// Get quality recommendations
const recommendations = await client.callTool('get_quality_recommendations', {
  path: 'src/complex_module.rs',
  max_recommendations: 10,
  min_severity: 'high'
});
```

## MCP Tools Overview (19 Total)

### Documentation Quality (2 tools)
- **`validate_documentation`** - Validate docs against codebase (zero hallucinations)
- **`check_claim`** - Verify individual documentation claims

### Code Quality (2 tools)
- **`analyze_technical_debt`** - TDG quality analysis (A+ to F grades)
- **`get_quality_recommendations`** - Actionable refactoring suggestions

### Agent-Based Analysis (5 tools)
- **`analyze`** - Comprehensive code analysis
- **`transform`** - Code transformation and refactoring
- **`validate`** - Code validation and verification
- **`orchestrate`** - Multi-agent workflow coordination
- **`quality_gate`** - Comprehensive quality checks

### Deep WASM Analysis (5 tools)
- **`deep_wasm_analyze`** - Bytecode-level analysis
- **`deep_wasm_query_mapping`** - Source-to-bytecode mappings
- **`deep_wasm_trace_execution`** - Execution path tracing
- **`deep_wasm_compare_optimizations`** - Optimization comparison
- **`deep_wasm_detect_issues`** - Issue detection and diagnostics

### Semantic Search (4 tools)
- **`semantic_search`** - Semantic code search (requires OpenAI API key)
- **`find_similar_code`** - Find similar code patterns
- **`cluster_code`** - Cluster code by similarity
- **`analyze_topics`** - Topic analysis and extraction

### Testing (1 tool)
- **`mutation_test`** - Mutation testing for test suite quality

## Architecture

```
┌─────────────┐
│  AI Agent   │
└──────┬──────┘
       │ MCP Protocol
       │ (JSON-RPC over HTTP)
       ▼
┌─────────────┐
│ MCP Server  │ ← server/src/mcp_integration/server.rs
├─────────────┤
│   Tools     │
├─────────────┤
│ - validate_ │ ← hallucination_detection_tools.rs
│   documenta │
│   tion      │
│ - check_    │
│   claim     │
├─────────────┤
│ - analyze_  │ ← tdg_tools.rs
│   technical │
│   _debt     │
│ - get_      │
│   quality_  │
│   recommend │
│   ations    │
├─────────────┤
│ - analyze   │ ← tools.rs
│ - transform │
│ - validate  │
│ - orchestr  │
│   ate       │
├─────────────┤
│ - deep_wasm │ ← deep_wasm_tools.rs
│   _*        │
├─────────────┤
│ - semantic_ │ ← tools.rs (adapters)
│   search    │
├─────────────┤
│ - mutation_ │ ← mutation_tools.rs
│   test      │
└─────────────┘
       │
       ▼
┌─────────────┐
│  Services   │
├─────────────┤
│ - Hallucin  │
│   ation     │
│   Detector  │
│ - TDG       │
│   Analyzer  │
│ - Agent     │
│   Registry  │
│ - Deep WASM │
│ - Semantic  │
│   Search    │
└─────────────┘
```

## Topics Covered

- [**MCP Server Setup**](ch03-01-mcp-setup.md) - Configure PMAT as MCP server
- [**Available Tools**](ch03-02-mcp-tools.md) - MCP tools reference and usage
- [**Claude Code Integration**](ch03-03-claude-integration.md) - Connect with Claude Desktop

## Common Use Cases

### Pre-Commit Hook: Validate Documentation

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Generate deep context
pmat context --output deep_context.md

# Validate documentation via MCP
node scripts/validate-docs.js || exit 1
```

### CI/CD: Quality Gate

```yaml
# .github/workflows/quality.yml
- name: Quality Gate
  run: |
    pmat mcp-server &
    sleep 2
    node scripts/quality-gate.js
```

### AI Code Review Bot

```javascript
// Automatically review pull requests
const files = await getChangedFiles(pr);
const reviews = await aiCodeReview(client, files);
await postReviewComments(pr, reviews);
```

## Protocol Compliance

- **Version**: MCP v2024-11-05
- **Transport**: HTTP/1.1 (JSON-RPC 2.0)
- **Capabilities**:
  - ✅ Tools (19 tools)
  - ✅ Resources (planned)
  - ✅ Prompts (planned)
  - ✅ Logging
  - ❌ Sampling (not applicable)

## Error Handling

All tools follow consistent error patterns:

```json
{
  "code": -32602,
  "message": "Path does not exist: /invalid/path",
  "data": {
    "path": "/invalid/path",
    "suggestion": "Please provide a valid file or directory path"
  }
}
```

**Error Codes:**
- `-32700`: Parse error
- `-32600`: Invalid request
- `-32601`: Method not found
- `-32602`: Invalid parameters
- `-32603`: Internal error

## Next Steps

- [**MCP Server Setup**](ch03-01-mcp-setup.md) - Learn how to configure and run the MCP server
- [**Available Tools**](ch03-02-mcp-tools.md) - Explore the complete catalog of 19 MCP tools
- [**Claude Integration**](ch03-03-claude-integration.md) - Integrate with Claude Desktop and AI agents
- [**Chapter 15: Complete MCP Tools Reference**](ch15-00-mcp-tools.md) - Advanced workflows and integration patterns
