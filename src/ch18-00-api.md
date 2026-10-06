# Chapter 18: API Server and Roadmap Management

<!-- DOC_STATUS_START -->
**Chapter Status**: ❌ Mostly broken (3 of 20 measured commands work)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 3 | `pmat serve`, `pmat serve --verbose`, `pmat serve --port 9090 --host 0.0.0.0` once `PMAT_MCP_HTTP_TOKEN` is set: they start an MCP server, not the REST API this chapter describes |
| ⚠️ Not Implemented | 7 | `/health`, `/analyze`, `/context`, `/quality-gate`, `/batch-analyze`, `/report`, `ws://…/ws`: every one is HTTP 404 |
| ❌ Broken | 10 | `pmat roadmap init --sprint`, `pmat roadmap complete --quality-check`, `pmat serve --metrics`, `pmat analyze .`, `pmat report --path`: exit 2 (unexpected argument); `pmat serve --port 9090 --host 0.0.0.0` as first written, with no token: exit 4 |
| 📋 Planned | 0 | |

*Not measured: `pmat roadmap todos`, `start` and `status`, which read `docs/execution/roadmap.md`; no step in this chapter creates it.*

*Last updated: 2026-10-06*
*PMAT version: pmat 3.42.0*
<!-- DOC_STATUS_END -->

> **Not implemented: the REST API and WebSocket.** `pmat serve` does not serve
> REST endpoints. It serves MCP JSON-RPC over streamable HTTP at the root path
> `/`, and needs a bearer token (`PMAT_MCP_HTTP_TOKEN`, 16 characters minimum)
> and an `Accept: application/json, text/event-stream` header on every call.
> Every endpoint this chapter documents, `/health`, `/analyze`, `/context`,
> `/quality-gate`, `/batch-analyze`, `/report` and `/ws`, returns 404, so the
> curl calls, the CI jobs, the benchmark and the WebSocket client below do
> nothing useful. `pmat mcp connect` prints how to connect a client.
> The roadmap half has its own problems, listed at the start of
> [Roadmap Sprint Management](#roadmap-sprint-management).

## The Problem

Modern development teams need programmatic access to PMAT's analysis capabilities and structured sprint management. The API server provides HTTP endpoints for integration with existing tools, while the roadmap features enable agile sprint planning with built-in quality gates.

## Core Concepts

### API Server Architecture

What `pmat serve` provides in pmat 3.42.0:
- MCP JSON-RPC over streamable HTTP, at the root path `/`
- The same tools as the stdio MCP server (`pmat --mode mcp`)
- Bearer-token authentication; on a loopback bind with no token set, pmat generates one and prints it
- No REST endpoints, no `/health` and no WebSocket

### Roadmap Management

The roadmap system integrates:
- Sprint initialization and tracking
- PDMT (Pragmatic Decision Making Tool) todo generation
- Task lifecycle management
- Quality gate enforcement
- Release validation

## Starting the API Server

### Basic Server Launch

```bash
# Start server on default port (8080)
pmat serve

# Custom port. A non-loopback --host such as 0.0.0.0 also needs
# PMAT_MCP_HTTP_TOKEN set, or pmat exits 4 instead of starting.
export PMAT_MCP_HTTP_TOKEN=$(pmat mcp token)
pmat serve --port 9090 --host 0.0.0.0

# With verbose logging
pmat serve --verbose
```

**Output** (`pmat serve`, pmat 3.42.0, no token set):
```text
pmat MCP (streamable HTTP) listening on http://127.0.0.1:8080/
  endpoint: the ROOT path — `/mcp` and `/health` are 404, there is no health endpoint
  auth: Bearer, from PMAT_MCP_HTTP_TOKEN; unauthenticated requests get 401
  tools: 20 (identical to the stdio surface)

PMAT_MCP_HTTP_TOKEN was unset, so pmat generated a token for this process:

  <generated token>
```

A working call to the server lists its tools:

```bash
curl -sS http://127.0.0.1:8080/ \
  -H "Authorization: Bearer $PMAT_MCP_HTTP_TOKEN" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
```

## API Endpoints

> **Not implemented.** None of the endpoints in this section exists. Each one
> returns HTTP 404 from `pmat serve` in pmat 3.42.0.

### Health Check

```bash
# Check server health
curl http://localhost:8080/health
```

**Response:**
```json
{
  "status": "healthy",
  "version": "2.69.0",
  "uptime": 120
}
```

### Repository Analysis

```bash
# Analyze a repository
curl -X POST http://localhost:8080/analyze \
  -H "Content-Type: application/json" \
  -d '{"path": "/path/to/repo"}'
```

**Response:**
```json
{
  "files": 250,
  "lines": 15000,
  "languages": ["rust", "python"],
  "complexity": {
    "average": 3.2,
    "max": 15
  },
  "issues": {
    "critical": 2,
    "warning": 8,
    "info": 15
  }
}
```

### Context Generation

```bash
# Generate context for AI tools
curl -X POST http://localhost:8080/context \
  -H "Content-Type: application/json" \
  -d '{"path": "/path/to/repo", "format": "markdown"}'
```

**Response:**
```json
{
  "context": "# Repository Context\n\n## Structure\n...",
  "tokens": 4500,
  "files_included": 45
}
```

### Quality Gate Check

```bash
# Run quality gate validation
curl -X POST http://localhost:8080/quality-gate \
  -H "Content-Type: application/json" \
  -d '{"path": "/path/to/repo", "threshold": "B+"}'
```

**Response:**
```json
{
  "passed": true,
  "grade": "A",
  "score": 92,
  "details": {
    "test_coverage": 85,
    "code_quality": 95,
    "documentation": 90
  }
}
```

## WebSocket Real-time Updates

> **Not implemented.** pmat has no WebSocket endpoint. `/ws` returns 404.

### JavaScript Client Example

```javascript
const ws = new WebSocket('ws://localhost:8080/ws');

ws.onopen = () => {
  console.log('Connected to PMAT WebSocket');
  
  // Subscribe to analysis updates
  ws.send(JSON.stringify({
    type: 'subscribe',
    channel: 'analysis'
  }));
};

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log('Analysis update:', data);
};

// Start analysis with real-time updates
ws.send(JSON.stringify({
  type: 'analyze',
  path: '/path/to/repo'
}));
```

## Roadmap Sprint Management

> **Broken in pmat 3.42.0.** These commands exit 2 with an unexpected-argument
> error: `pmat roadmap init --sprint` (and `--from-analysis`),
> `pmat roadmap complete --quality-check`, `pmat roadmap quality-check --project`
> and `pmat roadmap todos --format`. `pmat roadmap validate` with no arguments
> exits 2 because `--sprint` is required. `pmat roadmap todos`, `start` and
> `status` read `docs/execution/roadmap.md`, and exit 1 when it is missing.
> Check `pmat roadmap <command> --help` before using an example here.

### Initialize a Sprint

```bash
# Create new sprint
pmat roadmap init --sprint "v1.0.0" \
  --goal "Complete core features"
```

**Output:**
```text
Sprint v1.0.0 initialized
Goal: Complete core features
Duration: 2 weeks (default)
Quality threshold: B+
```

### Generate PDMT Todos

```bash
# Generate todos from roadmap tasks
pmat roadmap todos
```

**Output:**
```text
Generated 15 PDMT todos:
- [ ] PMAT-001: Implement user authentication (P0)
- [ ] PMAT-002: Add database migrations (P0)
- [ ] PMAT-003: Create API endpoints (P1)
- [ ] PMAT-004: Write integration tests (P1)
- [ ] PMAT-005: Update documentation (P2)
...
```

### Task Lifecycle Management

```bash
# Start working on a task
pmat roadmap start PMAT-001

# Output:
# Task PMAT-001 marked as IN_PROGRESS
# Quality check initiated...
# Current code grade: B
# Required grade for completion: B+
```

```bash
# Complete task with quality validation
pmat roadmap complete PMAT-001 --quality-check

# Output:
# Running quality validation...
# ✅ Test coverage: 85%
# ✅ Code quality: Grade A
# ✅ Documentation: Complete
# Task PMAT-001 completed successfully
```

### Sprint Status and Validation

```bash
# Check sprint progress
pmat roadmap status
```

**Output:**
```text
Sprint: v1.0.0
Progress: 60% (9/15 tasks)
Velocity: 4.5 tasks/day
Estimated completion: 3 days

Tasks by status:
- Completed: 9
- In Progress: 2
- Pending: 4

Quality metrics:
- Average grade: A-
- Test coverage: 82%
- All quality gates: PASSING
```

```bash
# Validate sprint for release
pmat roadmap validate
```

**Output:**
```text
Sprint Validation Report
========================
✅ All P0 tasks completed
✅ Quality gates passed (Grade: A)
✅ Test coverage above threshold (85% > 80%)
✅ No critical issues remaining
✅ Documentation updated

Sprint v1.0.0 is ready for release!
```

## Integration with CI/CD

> **Not implemented.** Both jobs POST to `/quality-gate`, which returns 404.
> Use `pmat quality-gate` from the CLI in CI instead.

### GitHub Actions Example

```yaml
name: PMAT Quality Gate

on: [push, pull_request]

jobs:
  quality-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Install PMAT
        run: cargo install pmat
      
      - name: Start PMAT API Server
        run: |
          pmat serve --port 8080 &
          sleep 2
      
      - name: Run Quality Gate Check
        run: |
          response=$(curl -X POST http://localhost:8080/quality-gate \
            -H "Content-Type: application/json" \
            -d '{"path": ".", "threshold": "B+"}')
          
          passed=$(echo $response | jq -r '.passed')
          grade=$(echo $response | jq -r '.grade')
          
          echo "Quality Grade: $grade"
          
          if [ "$passed" != "true" ]; then
            echo "Quality gate failed!"
            exit 1
          fi
```

### Jenkins Pipeline Example

```groovy
pipeline {
    agent any
    
    stages {
        stage('Quality Analysis') {
            steps {
                script {
                    // Start PMAT server
                    sh 'pmat serve --port 8080 &'
                    sleep 2
                    
                    // Run analysis via API
                    def response = sh(
                        script: '''
                            curl -X POST http://localhost:8080/analyze \
                              -H "Content-Type: application/json" \
                              -d '{"path": "."}'
                        ''',
                        returnStdout: true
                    )
                    
                    def analysis = readJSON text: response
                    
                    if (analysis.issues.critical > 0) {
                        error "Critical issues found: ${analysis.issues.critical}"
                    }
                }
            }
        }
    }
}
```

## Advanced API Features

> **Not implemented.** `/batch-analyze`, `/analyze` and `/report` return 404.

### Batch Analysis

```bash
# Analyze multiple repositories
curl -X POST http://localhost:8080/batch-analyze \
  -H "Content-Type: application/json" \
  -d '{
    "repositories": [
      "/path/to/repo1",
      "/path/to/repo2",
      "/path/to/repo3"
    ],
    "parallel": true
  }'
```

### Custom Analysis Rules

```bash
# Apply custom rules via API
curl -X POST http://localhost:8080/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "path": "/path/to/repo",
    "rules": {
      "max_complexity": 10,
      "min_coverage": 80,
      "forbidden_patterns": ["console.log", "TODO"]
    }
  }'
```

### Export Formats

```bash
# Generate HTML report
curl -X POST http://localhost:8080/report \
  -H "Content-Type: application/json" \
  -d '{
    "path": "/path/to/repo",
    "format": "html",
    "include_charts": true
  }' > report.html

# Generate CSV metrics
curl -X POST http://localhost:8080/report \
  -H "Content-Type: application/json" \
  -d '{
    "path": "/path/to/repo",
    "format": "csv"
  }' > metrics.csv
```

## Using PMAT to Document Itself

> **Broken.** `pmat analyze .` exits 2 (`unrecognized subcommand '.'`), and so do
> `pmat roadmap init --from-analysis`, `pmat roadmap todos --format` and
> `pmat report --path` (unexpected argument).

### Generate Book Roadmap

```bash
# Analyze the PMAT book repository
cd /path/to/pmat-book
pmat analyze . --output book-analysis.json

# Generate roadmap from analysis
pmat roadmap init --from-analysis book-analysis.json \
  --sprint "Book-v1.0"

# Create documentation todos
pmat roadmap todos --format markdown > BOOK_TODOS.md
```

**Generated BOOK_TODOS.md:**
```markdown
# PMAT Book Development Roadmap

## Sprint: Book-v1.0

### High Priority (P0)
- [ ] BOOK-001: Complete missing Chapter 13 (Performance Analysis)
- [ ] BOOK-002: Complete missing Chapter 14 (Large Codebases)
- [ ] BOOK-003: Fix SUMMARY.md link mismatches

### Medium Priority (P1)
- [ ] BOOK-004: Add TDD tests for Chapter 15
- [ ] BOOK-005: Create CI/CD examples for Chapter 16
- [ ] BOOK-006: Document plugin system (Chapter 17)

### Low Priority (P2)
- [ ] BOOK-007: Add advanced API examples
- [ ] BOOK-008: Create video tutorials
- [ ] BOOK-009: Translate to other languages

## Quality Gates
- Minimum test coverage: 80%
- All examples must be working
- Zero broken links
- Documentation grade: A-
```

### Monitor Book Quality

```bash
# Run quality analysis on the book
pmat roadmap quality-check --project book

# Generate quality report
pmat report --path . --format json | jq '.quality_metrics'
```

**Output:**
```json
{
  "documentation_score": 92,
  "example_coverage": 88,
  "test_pass_rate": 100,
  "broken_links": 0,
  "todo_items": 7,
  "overall_grade": "A"
}
```

## Performance Characteristics

### API Server Benchmarks

> **Not implemented.** `/health` returns 404, so this benchmarks 404 responses.

```bash
# Run performance test
ab -n 1000 -c 10 http://localhost:8080/health
```

**Results:**
```text
Requests per second:    2500.34 [#/sec]
Time per request:       4.00 [ms]
Transfer rate:          450.67 [Kbytes/sec]

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    1   0.5      1       3
Processing:     2    3   1.0      3       8
Total:          2    4   1.2      4      10
```

### Resource Usage

> **Broken.** `pmat serve --metrics` exits 2: `error: unexpected argument '--metrics' found`.

```bash
# Monitor server resources
pmat serve --metrics
```

**Output:**
```text
PMAT API Server Metrics
=======================
CPU Usage: 2.5%
Memory: 45 MB
Active Connections: 5
Request Queue: 0
Average Response Time: 3.2ms
Uptime: 2h 15m
```

## Troubleshooting

### Common Issues

1. **Port Already in Use**
```bash
# Find process using port
lsof -i :8080

# Use different port
pmat serve --port 9090
```

2. **WebSocket Connection Failed**: pmat has no WebSocket endpoint, so this always fails.
```bash
# Check WebSocket support
curl -I -H "Upgrade: websocket" \
     -H "Connection: Upgrade" \
     http://localhost:8080/ws
```

3. **API Timeout**
```bash
# Increase timeout for large repos
curl -X POST http://localhost:8080/analyze \
  -H "Content-Type: application/json" \
  -d '{"path": "/large/repo", "timeout": 300}'
```

## Summary

`pmat serve` exposes PMAT's tools to MCP clients over streamable HTTP; the REST API and WebSocket described in this chapter were never built. The roadmap system brings agile sprint management directly into the quality analysis workflow, ensuring that every task meets quality standards before completion. This integration of quality gates with sprint management creates a powerful feedback loop that improves both code quality and team velocity.
