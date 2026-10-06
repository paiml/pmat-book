# Chapter 3: MCP Protocol

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working

| Status | Count | Description |
|--------|-------|-------------|
| ✅ Working | tools/list | Every tool name matches `pmat --mode mcp` tools/list (tests/ch03/test_05_ch03_00_tool_names.sh) |
| ⚠️ Not Implemented | 0 | Complete MCP integration |
| ❌ Broken | 0 | No known issues |
| 📋 Planned | 0 | Core MCP features complete |

*Last updated: 2026-10-06*
*PMAT version: pmat 3.42.0*
*MCP version: v2024-11-05*
<!-- DOC_STATUS_END -->

## Overview

The Model Context Protocol (MCP) enables seamless integration between PMAT and AI agents like Claude, ChatGPT, and custom AI assistants. PMAT serves its MCP tools in five groups: code search, analysis, quality gating, project context and planning. The list below is what `tools/list` returns; ask the binary rather than trusting a number, because the count moves between builds of one release line.

**Protocol Version**: MCP v2024-11-05
**Tools**: whatever `tools/list` returns (20 in pmat 3.42.0)
**Transport**: JSON-RPC 2.0 over stdio (`pmat --mode mcp`), or streamable HTTP (`pmat serve --transport http`, bearer token required)

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
// Cyclomatic and cognitive complexity, functions above the threshold
const complexity = await client.callTool('analyze_complexity', {
  paths: ['src/'],
  threshold: 20
});

// The full quality-gate suite (complexity, dead code, SATD, entropy, ...)
const gate = await client.callTool('quality_gate', {
  paths: ['.'],
  strict: true
});

// Natural-language code search, filtered by TDG grade
const hits = await client.callTool('pmat_query_code', {
  query: 'error handling',
  min_grade: 'B',
  limit: 10
});
```

A name that `tools/list` does not return is refused with `-32602`
(`Tool '<name>' not found`), so take names from the list below or from
the server itself.

## MCP Tools Overview

The groups below hold every tool `pmat --mode mcp` returns from `tools/list`
(pmat 3.42.0). [Available Tools](ch03-02-mcp-tools.md) has each tool's
parameters.

### Code Search (4 tools)
- **`pmat_query_code`** - Natural-language code search with TDG quality filters
- **`pmat_get_function`** - One function's metadata, optionally with source
- **`pmat_find_similar`** - Functions similar to a reference function
- **`pmat_index_stats`** - Function counts and grade distribution of the code index

### Analysis (9 tools)
- **`analyze_complexity`** - Cyclomatic and cognitive complexity
- **`analyze_big_o`** - Big-O time complexity of functions
- **`analyze_dag`** - Call, import or inheritance graph
- **`analyze_dead_code`** - Unreachable or unused functions, types and modules
- **`analyze_deep_context`** - The full deep-context pipeline (AST, complexity, churn, dead code)
- **`analyze_satd`** - Self-admitted technical debt (TODO, FIXME, HACK)
- **`analyze_hardcoded_paths`** - Machine-specific absolute paths baked into source
- **`analyze_reachability`** - Tracked `.rs` files no compilation unit reaches
- **`analyze_vacuous_tests`** - `#[test]` functions that cannot fail

### Quality Gating (3 tools)
- **`quality_gate`** - The `pmat quality-gate --checks all` suite
- **`quality_check_content`** - Grade proposed file content against the project's gate
- **`quality_proxy`** - The same grading; it serves the same description and parameters as `quality_check_content`

### Project Context (3 tools)
- **`generate_context`** - File tree and optional dependency graph for an agent
- **`scaffold_project`** - High-level project summary
- **`git_operation`** - Working-tree status of a repository

### Planning (1 tool)
- **`pdmt_deterministic_todos`** - Deterministic todo lists from a list of requirements


## Architecture

```
┌──────────────────┐
│     AI Agent     │
└────────┬─────────┘
         │ MCP (JSON-RPC 2.0)
         │ stdio: pmat --mode mcp
         │ HTTP:  pmat serve --transport http
         ▼
┌──────────────────┐
│    MCP Server    │
├──────────────────┤
│ tools/list       │
│ - code search    │ pmat_query_code, pmat_get_function, ...
│ - analysis       │ analyze_complexity, analyze_satd, ...
│ - quality gating │ quality_gate, quality_check_content, ...
│ - project context│ generate_context, scaffold_project, ...
│ - planning       │ pdmt_deterministic_todos
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  pmat analyzers  │ the same code the CLI subcommands run
└──────────────────┘
```


## Topics Covered

- [**MCP Server Setup**](ch03-01-mcp-setup.md) - Configure PMAT as MCP server
- [**Available Tools**](ch03-02-mcp-tools.md) - MCP tools reference and usage
- [**Claude Code Integration**](ch03-03-claude-integration.md) - Connect with Claude Desktop

## Common Use Cases

### Pre-Commit Hook: Grade Staged Files

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Calls quality_check_content once per staged file and exits non-zero on a failing verdict
node scripts/check-staged.js $(git diff --cached --name-only) || exit 1
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
- **Transport**: JSON-RPC 2.0 over stdio, or streamable HTTP
- **Capabilities** (as `initialize` reports them in pmat 3.42.0):
  - ✅ Tools (`listChanged: true`)
  - ❌ Resources, Prompts, Logging, Sampling (not advertised)

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
- [**Available Tools**](ch03-02-mcp-tools.md) - Every tool the server serves, with its parameters
- [**Claude Integration**](ch03-03-claude-integration.md) - Integrate with Claude Desktop and AI agents
- [**Chapter 15: Complete MCP Tools Reference**](ch15-00-mcp-tools.md) - Advanced workflows and integration patterns
