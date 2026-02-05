# MCP Tools

**Chapter Status**: Working (25/25 tools documented)

*Last updated: 2026-02-04*
*PMAT version: pmat 2.215.0*

## Overview

PMAT provides 25 MCP tools across 8 categories for comprehensive code analysis, quality assessment, and AI-assisted development. All tools use standardized JSON-RPC 2.0 protocol.

## Tool Categories

### Documentation Quality (2 tools)

Tools for validating documentation accuracy and preventing hallucinations.

#### `validate_documentation`

Validate documentation against codebase to prevent hallucinations, broken references, and 404 errors.

**Input Schema:**
```json
{
  "documentation_path": "README.md",
  "deep_context_path": "deep_context.md",
  "similarity_threshold": 0.7,
  "fail_on_error": true
}
```

**Output:**
```json
{
  "summary": {
    "pass": true,
    "total_claims": 45,
    "verified": 42,
    "unverified": 2,
    "contradictions": 1,
    "broken_references": 0,
    "http_errors": 0
  },
  "issues": [
    {
      "line": 42,
      "claim": "PMAT can compile Rust code",
      "status": "Contradiction",
      "confidence": 0.12,
      "evidence": "PMAT analyzes but does not compile"
    }
  ]
}
```

**Use Cases:**
- Pre-commit hooks for documentation validation
- CI/CD gates for preventing bad docs
- Automated documentation quality checks

#### `check_claim`

Verify a single documentation claim against the codebase.

**Input Schema:**
```json
{
  "claim": "PMAT can analyze TypeScript complexity",
  "deep_context_path": "deep_context.md",
  "similarity_threshold": 0.7
}
```

**Output:**
```json
{
  "status": "Verified",
  "confidence": 0.94,
  "evidence": "server/src/cli/language_analyzer.rs:150"
}
```

### Code Quality (2 tools)

Technical Debt Grading (TDG) analysis and actionable recommendations.

#### `analyze_technical_debt`

Comprehensive TDG quality analysis with A+ to F grading.

**Input Schema:**
```json
{
  "path": "src/main.rs",
  "include_penalties": true
}
```

**Output:**
```json
{
  "score": {
    "total": 82.5,
    "grade": "B+",
    "complexity": 88.0,
    "duplication": 75.0,
    "size": 85.0
  },
  "penalties": [
    {
      "type": "high_complexity",
      "function": "process_data",
      "file": "src/main.rs",
      "line": 45,
      "impact": -5.0
    }
  ]
}
```

#### `get_quality_recommendations`

Get actionable refactoring suggestions prioritized by impact.

**Input Schema:**
```json
{
  "path": "src/complex_module.rs",
  "max_recommendations": 10,
  "min_severity": "high"
}
```

**Output:**
```json
{
  "recommendations": [
    {
      "severity": "high",
      "category": "complexity",
      "issue": "Function 'calculate' has cyclomatic complexity of 15",
      "suggestion": "Extract validation logic into separate function",
      "impact": 8.5,
      "file": "src/complex_module.rs",
      "line": 120
    }
  ]
}
```

### Agent-Based Analysis (5 tools)

Multi-agent workflows for comprehensive code analysis and transformation.

#### `analyze`

Comprehensive code analysis using specialized agents.

**Input Schema:**
```json
{
  "path": "src/",
  "agent_type": "complexity_analyzer",
  "config": {
    "threshold": 10,
    "include_tests": false
  }
}
```

#### `transform`

Code transformation and refactoring using AI agents.

**Input Schema:**
```json
{
  "path": "src/legacy_code.rs",
  "transformation_type": "modernize",
  "preserve_behavior": true
}
```

#### `validate`

Code validation and verification using formal methods.

**Input Schema:**
```json
{
  "path": "src/auth.rs",
  "validation_type": "security",
  "strict": true
}
```

#### `orchestrate`

Multi-agent workflow orchestration.

**Input Schema:**
```json
{
  "workflow": "full_analysis",
  "path": "src/",
  "agents": ["complexity", "security", "maintainability"]
}
```

#### `quality_gate`

Comprehensive quality checks for CI/CD integration.

**Input Schema:**
```json
{
  "path": "src/",
  "min_grade": "B",
  "checks": ["complexity", "security", "duplication"]
}
```

### Deep WASM Analysis (5 tools)

Bytecode-level WebAssembly analysis and optimization.

#### `deep_wasm_analyze`

Bytecode-level WASM analysis.

**Input Schema:**
```json
{
  "wasm_file": "output.wasm",
  "analysis_level": "deep"
}
```

#### `deep_wasm_query_mapping`

Source-to-bytecode mapping queries.

**Input Schema:**
```json
{
  "wasm_file": "output.wasm",
  "source_line": 45
}
```

#### `deep_wasm_trace_execution`

Execution path tracing through bytecode.

**Input Schema:**
```json
{
  "wasm_file": "output.wasm",
  "function": "calculate",
  "max_depth": 100
}
```

#### `deep_wasm_compare_optimizations`

Compare optimization levels.

**Input Schema:**
```json
{
  "wasm_file_1": "output_O0.wasm",
  "wasm_file_2": "output_O3.wasm"
}
```

#### `deep_wasm_detect_issues`

Detect performance and security issues.

**Input Schema:**
```json
{
  "wasm_file": "output.wasm",
  "check_security": true,
  "check_performance": true
}
```

### Agent Context (4 tools)

RAG-powered semantic code search with quality annotations. No API keys required - works completely offline.

#### `pmat_query_code`

Semantic search for code by intent. Returns quality-ranked results with TDG scores, complexity, and Big-O estimates.

**Input Schema:**
```json
{
  "query": "error handling in API layer",
  "limit": 5,
  "min_grade": "B",
  "max_complexity": 15,
  "path": "src/"
}
```

**Output:**
```json
{
  "results": [
    {
      "id": "src/api/error.rs::handle_api_error",
      "name": "handle_api_error",
      "file": "src/api/error.rs",
      "line": 42,
      "signature": "pub fn handle_api_error(err: ApiError) -> Response",
      "tdg_grade": "A",
      "complexity": 8,
      "big_o": "O(1)",
      "relevance": 0.92
    }
  ]
}
```

**Use Cases:**
- Replace grep for AI agents (Claude Code, Cline, Cursor)
- Quality-filtered code discovery
- Pre-refactoring analysis

#### `pmat_get_function`

Get full function source with quality metrics by file and function name.

**Input Schema:**
```json
{
  "file": "src/api/error.rs",
  "function": "handle_api_error",
  "include_callers": false,
  "include_callees": false
}
```

#### `pmat_find_similar`

Find functions similar to a given one for refactoring and deduplication.

**Input Schema:**
```json
{
  "file": "src/api/error.rs",
  "function": "handle_api_error",
  "limit": 5,
  "min_similarity": 0.7
}
```

#### `pmat_index_stats`

Check agent context index health and statistics.

**Input Schema:**
```json
{}
```

**Output:**
```json
{
  "total_functions": 42001,
  "total_files": 1816,
  "avg_tdg_score": 0.3,
  "languages": ["Rust", "TypeScript", "Python"]
}
```

### Semantic Search (4 tools)

Local semantic code search using TF-IDF embeddings (no API key required).

#### `semantic_search`

Semantic code search using embeddings.

**Input Schema:**
```json
{
  "query": "authentication logic with JWT validation",
  "path": "src/",
  "max_results": 10
}
```

#### `find_similar_code`

Find similar code patterns.

**Input Schema:**
```json
{
  "reference_file": "src/auth.rs",
  "reference_function": "validate_token",
  "similarity_threshold": 0.8
}
```

#### `cluster_code`

Cluster code by semantic similarity.

**Input Schema:**
```json
{
  "path": "src/",
  "num_clusters": 5
}
```

#### `analyze_topics`

Topic analysis and extraction.

**Input Schema:**
```json
{
  "path": "src/",
  "num_topics": 10
}
```

### JVM Language Analysis (2 tools)

Full AST-based analysis for Java and Scala (Sprint 51).

#### `analyze_java`

Analyze Java source code with full AST parsing for complexity, structure, and quality metrics.

**Input Schema:**
```json
{
  "path": "src/main/java/",
  "max_depth": 3,
  "include_metrics": true,
  "include_ast": false
}
```

**Output:**
```json
{
  "summary": {
    "total_files": 45,
    "total_classes": 38,
    "total_methods": 287,
    "avg_complexity": 3.2,
    "max_complexity": 15
  },
  "files": [
    {
      "path": "src/main/java/com/example/Service.java",
      "classes": 2,
      "methods": 18,
      "lines": 342,
      "complexity": {
        "cyclomatic": 5.2,
        "cognitive": 4.1
      }
    }
  ]
}
```

**Use Cases:**
- Analyze Java enterprise applications
- Track complexity trends in Spring/Jakarta EE projects
- Identify refactoring opportunities in JVM codebases
- Generate quality reports for Java microservices

#### `analyze_scala`

Analyze Scala source code with full AST parsing for complexity, structure, and quality metrics.

**Input Schema:**
```json
{
  "path": "src/main/scala/",
  "max_depth": 3,
  "include_metrics": true,
  "include_ast": false
}
```

**Output:**
```json
{
  "summary": {
    "total_files": 28,
    "total_classes": 15,
    "total_case_classes": 22,
    "total_objects": 12,
    "total_traits": 8,
    "total_methods": 156,
    "avg_complexity": 2.8,
    "max_complexity": 12
  },
  "files": [
    {
      "path": "src/main/scala/com/example/Service.scala",
      "case_classes": 3,
      "objects": 1,
      "methods": 14,
      "lines": 287,
      "complexity": {
        "cyclomatic": 3.8,
        "cognitive": 3.2
      }
    }
  ]
}
```

**Use Cases:**
- Analyze Scala functional codebases
- Track quality in Akka/Play Framework applications
- Identify complex pattern matching expressions
- Generate reports for Scala microservices

### Testing (1 tool)

Mutation testing for test suite quality assessment.

#### `mutation_test`

Run mutation testing to measure test effectiveness.

**Input Schema:**
```json
{
  "path": "src/",
  "target_file": "src/main.rs",
  "timeout": 60
}
```

**Output:**
```json
{
  "total_mutants": 45,
  "caught": 40,
  "missed": 5,
  "timeout": 0,
  "score": 88.9
}
```

## Common Workflows

### Workflow 1: Documentation Validation

```javascript
// Step 1: Generate deep context
await runCommand('pmat context --output deep_context.md');

// Step 2: Validate documentation
const result = await client.callTool('validate_documentation', {
  documentation_path: 'README.md',
  deep_context_path: 'deep_context.md',
  similarity_threshold: 0.7,
  fail_on_error: true
});

if (!result.summary.pass) {
  console.error('Documentation validation failed!');
  process.exit(1);
}
```

### Workflow 2: Code Quality Check

```javascript
// Analyze technical debt
const analysis = await client.callTool('analyze_technical_debt', {
  path: 'src/',
  include_penalties: true
});

// Get recommendations if score is low
if (analysis.score.total < 70) {
  const recommendations = await client.callTool('get_quality_recommendations', {
    path: 'src/',
    max_recommendations: 10,
    min_severity: 'high'
  });

  console.log('Quality issues found:', recommendations.recommendations);
}
```

### Workflow 3: WASM Optimization Analysis

```javascript
// Analyze WASM bytecode
const analysis = await client.callTool('deep_wasm_analyze', {
  wasm_file: 'output.wasm',
  analysis_level: 'deep'
});

// Compare optimizations
const comparison = await client.callTool('deep_wasm_compare_optimizations', {
  wasm_file_1: 'output_O0.wasm',
  wasm_file_2: 'output_O3.wasm'
});

// Detect issues
const issues = await client.callTool('deep_wasm_detect_issues', {
  wasm_file: 'output.wasm',
  check_security: true,
  check_performance: true
});
```

### Workflow 4: Agent Context Search

```javascript
// Step 1: Search for relevant code by intent
const results = await client.callTool('pmat_query_code', {
  query: 'error handling in API layer',
  min_grade: 'B',
  limit: 5
});

// Step 2: Get full function details
for (const result of results) {
  const details = await client.callTool('pmat_get_function', {
    file: result.file,
    function: result.name
  });
  console.log(`${result.name}: TDG ${result.tdg_grade}, Complexity ${result.complexity}`);
}

// Step 3: Find similar functions for refactoring
const similar = await client.callTool('pmat_find_similar', {
  file: results[0].file,
  function: results[0].name,
  limit: 3
});
```

## Error Handling

All tools return consistent error formats:

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

- [**Claude Integration**](ch03-03-claude-integration.md) - Connect with Claude Desktop
- [**Chapter 15: Complete MCP Tools Reference**](ch15-00-mcp-tools.md) - Advanced workflows and detailed schemas
