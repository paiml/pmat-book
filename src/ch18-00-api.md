# Chapter 18: API Server and Roadmap Management

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (16/16 examples)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 16 | Ready for production use |
| ⚠️ Not Implemented | 0 | Planned for future versions |
| ❌ Broken | 0 | Known issues, needs fixing |
| 📋 Planned | 0 | Future roadmap features |

*Last updated: 2025-09-12*  
*PMAT version: pmat 2.213.1*
<!-- DOC_STATUS_END -->

## The Problem

Modern development teams need programmatic access to PMAT's analysis capabilities and structured sprint management. The API server provides HTTP endpoints for integration with existing tools, while the roadmap features enable agile sprint planning with built-in quality gates.

## Core Concepts

### API Server Architecture

PMAT's API server provides:
- RESTful HTTP endpoints for all analysis features
- WebSocket support for real-time updates
- JSON request/response format
- Concurrent request handling
- Graceful shutdown capabilities

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

# Custom port and host
pmat serve --port 9090 --host 0.0.0.0

# With verbose logging
pmat serve --verbose
```

**Output:**
```
Starting PMAT API server...
Server listening on http://127.0.0.1:8080
WebSocket endpoint: ws://127.0.0.1:8080/ws
Press Ctrl+C to stop
```

## API Endpoints

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

### Initialize a Sprint

```bash
# Create new sprint
pmat roadmap init --sprint "v1.0.0" \
  --goal "Complete core features"
```

**Output:**
```
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
```
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
```
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
```
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

```bash
# Run performance test
ab -n 1000 -c 10 http://localhost:8080/health
```

**Results:**
```
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

```bash
# Monitor server resources
pmat serve --metrics
```

**Output:**
```
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

2. **WebSocket Connection Failed**
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

The API server and roadmap management features transform PMAT into a complete development operations platform. The HTTP API enables seamless integration with existing tools, while WebSocket support provides real-time feedback. The roadmap system brings agile sprint management directly into the quality analysis workflow, ensuring that every task meets quality standards before completion. This integration of quality gates with sprint management creates a powerful feedback loop that improves both code quality and team velocity.