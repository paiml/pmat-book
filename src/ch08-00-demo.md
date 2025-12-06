# Chapter 8: Interactive Demo and Reporting

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (9/9 examples)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 9 | All demo features tested + Pure WASM Dashboard |
| ⚠️ Not Implemented | 0 | Planned for future versions |
| ❌ Broken | 0 | Known issues, needs fixing |
| 📋 Planned | 0 | Future roadmap features |

*Last updated: 2025-12-06*
*PMAT version: pmat 2.208.0*
*Test-Driven: All examples validated in `tests/ch08/test_demo.sh`*
<!-- DOC_STATUS_END -->

## Interactive Code Analysis Demonstrations

The `pmat demo` command provides comprehensive, interactive demonstrations of PMAT's analysis capabilities. It offers multiple protocols (CLI, HTTP, MCP) and output formats to showcase code quality metrics, architectural insights, and technical debt analysis in an engaging, visual manner.

## Demo Modes and Protocols

### CLI Mode - Command Line Output

Perfect for terminal-based workflows and CI/CD integration:

```bash
# Basic CLI demo
pmat demo . --cli

# CLI demo with specific format
pmat demo . --cli --format=json
pmat demo . --cli --format=table
```

### HTTP Mode - Interactive Web Interface

Launch a local web server with interactive visualizations:

```bash
# Start web server (opens browser automatically)
pmat demo .

# Specify custom port
pmat demo . --port=8080

# Start server without opening browser
pmat demo . --no-browser
```

### MCP Mode - Model Context Protocol

Demonstrate MCP integration for AI agents:

```bash
# MCP protocol demo
pmat demo . --protocol=mcp --cli

# Show available MCP tools and prompts
pmat demo . --protocol=mcp --show-api
```

## Basic Demo Usage

### Analyze Current Directory

Start with a comprehensive analysis of your project:

```bash
pmat demo .
```

**Example Output (CLI Mode):**
```
🎯 PMAT Interactive Demo
========================

Project: my-application
Files Analyzed: 156
Lines of Code: 12,450
Languages: Rust (85%), JavaScript (10%), YAML (5%)

📊 Analysis Summary:
   Complexity Analysis: ✅ Complete
   Dead Code Detection: ✅ Complete  
   Technical Debt: ✅ Complete
   Architecture Analysis: ✅ Complete

🔍 Key Findings:
   • Average Complexity: 6.2
   • Dead Code Found: 3 functions
   • Technical Debt: 47 markers (TODO: 23, FIXME: 15, HACK: 9)
   • Test Coverage: 82%

📈 Quality Metrics:
   • Maintainability Index: B+
   • Technical Debt Ratio: 3.8%
   • Code Duplication: 5.2%
   • Cyclomatic Complexity: Moderate

🎨 Architecture Insights:
   • Pattern: MVC with Service Layer
   • Dependencies: 15 external, 3 dev
   • Modularity: Good separation of concerns
   • API Design: RESTful with proper versioning

✅ Demo Complete - Project analyzed successfully!
```

### Analyze Remote Repositories

Demonstrate analysis on public repositories:

```bash
# Analyze GitHub repository
pmat demo --repo=gh:rust-lang/rustlings --cli

# Analyze with shorthand GitHub syntax
pmat demo --repo=microsoft/vscode --cli

# Clone and analyze from URL
pmat demo --url=https://github.com/tokio-rs/tokio.git --cli
```

**Example Repository Analysis:**
```
🔄 PMAT Repository Demo
=======================

Repository: gh:rust-lang/rustlings
Cloning to temporary directory...

✅ Clone complete: 142 files
🔍 Analysis starting...

Project Structure:
├── exercises/ (98 files)
├── src/ (12 files)  
├── tests/ (23 files)
└── docs/ (9 files)

📊 Analysis Results:
   • Language: Rust (94%), Markdown (6%)
   • Total Lines: 5,234
   • Functions: 156
   • Complexity: Average 3.2, Max 12
   • Technical Debt: 45 markers
   • Test Coverage: 89%

🎯 Learning Project Analysis:
   • Educational structure detected
   • Progressive complexity design
   • Excellent test coverage
   • Clear documentation
   
Quality Grade: A- (Excellent for learning)

🔗 Repository: https://github.com/rust-lang/rustlings
📦 License: MIT
👥 Contributors: 340+
⭐ Stars: 45,000+
```

## Output Formats

### JSON Format

Machine-readable output for integration and processing:

```bash
pmat demo . --cli --format=json
```

**JSON Structure:**
```json
{
  "demo_type": "comprehensive_analysis",
  "timestamp": "2025-09-09T10:30:00Z",
  "project": {
    "path": "/path/to/project",
    "name": "my-application",
    "files_analyzed": 156,
    "total_lines": 12450,
    "languages": {
      "Rust": 10582,
      "JavaScript": 1245,
      "YAML": 623
    }
  },
  "analysis_results": {
    "complexity": {
      "average": 6.2,
      "maximum": 15,
      "functions_analyzed": 234,
      "high_complexity_functions": [
        {
          "file": "src/payment.rs",
          "function": "process_payment",
          "complexity": 15,
          "line": 45
        }
      ]
    },
    "dead_code": {
      "unused_functions": 3,
      "unused_variables": 12,
      "dead_code_percentage": 2.1,
      "findings": [
        {
          "file": "src/utils.rs",
          "function": "deprecated_helper",
          "line": 234,
          "type": "unused_function"
        }
      ]
    },
    "technical_debt": {
      "total_markers": 47,
      "todo_count": 23,
      "fixme_count": 15,
      "hack_count": 9,
      "markers": [
        {
          "file": "src/auth.rs",
          "line": 67,
          "type": "TODO",
          "message": "Implement OAuth2 flow"
        },
        {
          "file": "src/payment.rs",
          "line": 123,
          "type": "FIXME",
          "message": "Handle edge case for zero amounts"
        }
      ]
    },
    "architecture": {
      "pattern": "mvc_with_service_layer",
      "modularity_score": 0.78,
      "dependency_count": 15,
      "coupling": "moderate",
      "cohesion": "high"
    }
  },
  "quality_metrics": {
    "maintainability_index": 72,
    "technical_debt_ratio": 3.8,
    "duplication_percentage": 5.2,
    "test_coverage": 82
  },
  "recommendations": [
    "Refactor process_payment function (complexity: 15)",
    "Remove 3 unused functions to reduce dead code",
    "Address 15 FIXME items for stability improvements",
    "Extract common validation logic to reduce duplication"
  ]
}
```

### Table Format

Structured tabular output for clear data presentation:

```bash
pmat demo . --cli --format=table
```

**Table Output:**
```
📊 PMAT Analysis Results (Table Format)

┌─────────────────┬───────────┬────────────┬──────────────┬────────────┐
│ File            │ Lines     │ Complexity │ Issues       │ Quality    │
├─────────────────┼───────────┼────────────┼──────────────┼────────────┤
│ src/main.rs     │ 245       │ 4.2        │ 1 TODO       │ B+         │
│ src/payment.rs  │ 423       │ 8.7        │ 3 FIXME      │ C+         │
│ src/auth.rs     │ 189       │ 6.1        │ 2 TODO       │ B          │
│ src/utils.rs    │ 156       │ 3.4        │ 1 dead code  │ A-         │
│ tests/*.rs      │ 2145      │ 2.8        │ 0            │ A+         │
└─────────────────┴───────────┴────────────┴──────────────┴────────────┘

Quality Summary:
┌─────────────────┬───────────┐
│ Metric          │ Value     │
├─────────────────┼───────────┤
│ Overall Grade   │ B+        │
│ Maintainability │ 72/100    │
│ Tech Debt Ratio │ 3.8%      │
│ Test Coverage   │ 82%       │
│ Dead Code       │ 2.1%      │
└─────────────────┴───────────┘
```

## Advanced Demo Features

### Performance Monitoring

Track analysis performance and optimization:

```bash
pmat demo . --cli --target-nodes=15 --centrality-threshold=0.1
```

**Performance Output:**
```
⚡ PMAT Performance Demo
========================

Project: my-application
Target Nodes: 15 (complexity reduction enabled)

⏱️  Analysis Performance:
   File Discovery: 45ms (156 files)
   Parsing: 1,234ms
   Complexity Analysis: 456ms
   Dead Code Detection: 234ms
   Architecture Analysis: 567ms
   Report Generation: 123ms
   
   Total Time: 2,659ms
   Lines/sec: 4,682
   Files/sec: 58.6

📈 Optimization Results:
   • Graph reduction: 234 → 15 nodes (93.6% reduction)
   • Memory usage: 34.7MB peak
   • CPU utilization: 67% average
   • Cache hit rate: 89%

🎯 Performance Insights:
   • Efficient parallel processing
   • Smart caching enabled
   • Graph algorithms optimized
   • Memory footprint controlled

✅ Performance demo complete - System optimized!
```

### Debug Mode

Detailed analysis with debugging information:

```bash
pmat demo . --cli --debug --debug-output=debug-report.json
```

**Debug Output:**
```
🐛 PMAT Demo (Debug Mode)
=========================

[DEBUG] File classification started...
[DEBUG] src/main.rs: Rust source file (245 lines)
[DEBUG] src/payment.rs: Rust module (423 lines) 
[DEBUG] tests/: Test directory (2145 lines total)
[DEBUG] Cargo.toml: Package manifest (45 lines)

[DEBUG] Analysis pipeline started...
[DEBUG] Complexity analysis: 456ms
[DEBUG] Dead code detection: 234ms
[DEBUG] SATD analysis: 189ms
[DEBUG] Architecture analysis: 567ms

[DEBUG] Pattern recognition...
[DEBUG] MVC pattern detected (confidence: 0.87)
[DEBUG] Service layer identified (12 services)
[DEBUG] Repository pattern found (confidence: 0.92)

[DEBUG] Report generation: 123ms
[DEBUG] Total analysis time: 2,659ms

✅ Debug analysis complete
📄 Debug report saved to: debug-report.json
```

## Web Interface Features

### Pure WASM Dashboard (v2.208.0+)

Starting with v2.208.0, PMAT includes a **pure WebAssembly dashboard** built with the Presentar framework. This eliminates all JavaScript dependencies (3.1 MB of Mermaid.js, Grid.js, D3.js removed) and provides:

- **60fps GPU-accelerated rendering** via WebGPU
- **Type-safe Rust widgets** - no runtime JavaScript errors
- **WCAG 2.1 AA accessibility** - built-in contrast validation
- **~574 KB bundle size** (81% reduction from JavaScript version)

**Architecture:**
```
┌─────────────────────────────────────────────┐
│         pmat-dashboard.wasm (~574 KB)       │
│  ┌───────────────┐  ┌───────────────────┐  │
│  │ HotspotTable  │  │   MetricsChart    │  │
│  │ (Grid.js →)   │  │   (D3.js →)       │  │
│  └───────────────┘  └───────────────────┘  │
│  ┌───────────────┐  ┌───────────────────┐  │
│  │  DagDiagram   │  │  DashboardButton  │  │
│  │ (Mermaid →)   │  │   (Accessible)    │  │
│  └───────────────┘  └───────────────────┘  │
│            Presentar Core + trueno-viz      │
└─────────────────────────────────────────────┘
```

### Interactive Dashboard

When running in HTTP mode, PMAT provides a rich web interface:

```bash
pmat demo . --port=3000
```

**Web Features:**
- **Real-time Analysis**: Live updates via WebSocket (binary protocol)
- **Interactive Graphs**: Clickable complexity and dependency visualizations
- **Code Navigation**: Jump directly to problematic code sections
- **Quality Trends**: Historical quality metrics and trends
- **Export Options**: Download reports in multiple formats

**Dashboard Sections:**
1. **Overview**: High-level project metrics and grades
2. **Complexity**: Visual complexity analysis with heatmaps
3. **Technical Debt**: Interactive SATD tracking and prioritization
4. **Architecture**: Dependency graphs and pattern analysis
5. **Quality Gates**: Pass/fail status with detailed breakdowns

### API Endpoints

The demo web server exposes REST endpoints:

```bash
# Project overview
curl http://localhost:3000/api/overview

# Complexity analysis
curl http://localhost:3000/api/complexity

# Technical debt details
curl http://localhost:3000/api/technical-debt

# Quality metrics
curl http://localhost:3000/api/quality-metrics
```

## MCP Integration Demonstration

### Available Tools

When running in MCP mode, demonstrate available tools:

```bash
pmat demo . --protocol=mcp --show-api
```

**MCP Tools Demonstrated:**
```
🔌 PMAT MCP Protocol Demo
=========================

MCP Server: pmat-analysis-server
Protocol Version: 2024-11-05
Transport: stdio

🛠️  Available Tools:
   • analyze_repository - Complete repository analysis
   • generate_context - Project context for AI agents  
   • quality_gate_check - Automated quality enforcement
   • tdg_analysis - Technical debt grading
   • scaffold_project - Project scaffolding
   • refactor_suggestions - AI-powered refactoring hints

📋 Available Prompts:
   • code_review_prompt - Generate code review guidelines
   • refactoring_suggestions - Suggest improvements
   • architecture_analysis - Analyze system architecture
   • quality_improvement - Quality enhancement strategies

🎯 Tool Demonstration:
   Repository: /path/to/project
   
   Tool Call: analyze_repository
   Parameters: {
     "path": "/path/to/project",
     "include_tests": true,
     "analysis_depth": "comprehensive"
   }
   
   Result: {
     "files": 156,
     "complexity": {"average": 6.2, "max": 15},
     "quality_score": 72,
     "grade": "B+",
     "recommendations": [
       "Refactor high complexity functions",
       "Address technical debt markers",
       "Improve test coverage"
     ]
   }

✅ MCP Demo Complete - All tools working correctly!
```

### Integration Examples

Demonstrate MCP integration with AI agents:

```bash
# Claude Code integration
pmat demo . --protocol=mcp --cli

# Show how AI agents can use PMAT tools
pmat demo . --protocol=mcp --show-api --format=json
```

## Configuration and Customization

### Demo Configuration

Customize demo behavior with various options:

```bash
# Skip vendor files for cleaner analysis
pmat demo . --skip-vendor

# Include all files (even vendor)
pmat demo . --no-skip-vendor

# Set maximum line length for file processing
pmat demo . --max-line-length=5000

# Control graph complexity reduction
pmat demo . --target-nodes=20 --centrality-threshold=0.2
```

### Repository Selection

Multiple ways to specify target repositories:

```bash
# Local directory
pmat demo /path/to/project

# Current directory (default)
pmat demo .

# GitHub repository (shorthand)
pmat demo --repo=gh:owner/repository

# Full GitHub URL
pmat demo --repo=https://github.com/owner/repository

# Clone from URL
pmat demo --url=https://github.com/owner/repository.git
```

## Use Cases and Examples

### Educational Demonstrations

Perfect for teaching code quality and analysis:

```bash
# Show students complexity analysis
pmat demo . --cli --format=table

# Demonstrate technical debt impact
pmat demo . --cli | grep -A 10 "Technical Debt"

# Visual architecture analysis
pmat demo . --no-browser  # Web interface for visual learning
```

### Code Reviews

Use demos during code review sessions:

```bash
# Generate review-focused analysis
pmat demo . --cli --format=json > code-review.json

# Show quality trends over time
pmat demo . --debug --debug-output=quality-trends.json

# Focus on specific quality aspects
pmat demo . --cli | grep -E "Complexity|Dead Code|Technical Debt"
```

### Client Presentations

Professional demonstrations for stakeholders:

```bash
# Clean, professional output
pmat demo . --cli --format=table

# Web dashboard for interactive presentation
pmat demo . --port=8080 --no-browser

# Export comprehensive report
pmat demo . --cli --format=json > presentation-data.json
```

### CI/CD Integration

Automated demo reports in build pipelines:

```bash
# Generate CI report
pmat demo . --cli --format=json > ci-demo-report.json

# Performance tracking
pmat demo . --cli --debug --debug-output=build-performance.json

# Quality gate demonstration
pmat demo . --cli | grep "Quality Grade"
```

## Integration with Development Workflows

### Git Hooks

Pre-commit demo analysis:

```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "Running PMAT demo analysis..."
pmat demo . --cli --format=table

# Show quality impact of changes
git diff --cached --name-only | xargs pmat demo --cli
```

### IDE Integration

VS Code task configuration:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "PMAT Demo",
      "type": "shell",
      "command": "pmat",
      "args": ["demo", ".", "--cli", "--format=table"],
      "group": "build",
      "presentation": {
        "panel": "dedicated",
        "showReuseMessage": true,
        "clear": false
      }
    }
  ]
}
```

### Makefile Integration

```makefile
.PHONY: demo demo-web demo-json

demo:
	@echo "Running PMAT demonstration..."
	@pmat demo . --cli

demo-web:
	@echo "Starting PMAT web demo..."
	@pmat demo . --port=3000

demo-json:
	@echo "Generating JSON demo report..."
	@pmat demo . --cli --format=json > demo-report.json
	@echo "Report saved to demo-report.json"
```

## Troubleshooting

### Common Issues

#### Demo Server Won't Start
```bash
# Check port availability
pmat demo . --port=8080

# Use random port
pmat demo . --port=0

# Check for conflicts
netstat -tulpn | grep :3000
```

#### Large Repository Performance
```bash
# Reduce complexity for large repos
pmat demo . --target-nodes=10

# Skip vendor directories
pmat demo . --skip-vendor

# Use CLI mode for better performance
pmat demo . --cli
```

#### Memory Issues
```bash
# Enable debug mode to monitor memory
pmat demo . --cli --debug

# Increase system limits if needed
ulimit -m 2048000  # 2GB memory limit

# Process in smaller chunks
pmat demo src/ --cli  # Analyze subdirectory
```

### Performance Optimization

#### Faster Analysis
```bash
# Skip expensive operations
pmat demo . --cli --target-nodes=5

# Use table format (faster than JSON)
pmat demo . --cli --format=table

# Reduce graph complexity
pmat demo . --centrality-threshold=0.2
```

#### Better Visualizations
```bash
# Optimize for web display
pmat demo . --target-nodes=15 --merge-threshold=3

# Better graph layouts
pmat demo . --centrality-threshold=0.1

# Include debug info for tuning
pmat demo . --debug --debug-output=optimization.json
```

## Best Practices

### Demo Preparation

1. **Clean Repository**: Ensure the demo repository is well-structured
2. **Representative Code**: Use projects that showcase various analysis features
3. **Clear Objectives**: Define what aspects of PMAT you want to demonstrate
4. **Test Beforehand**: Run demos before presentations to ensure they work

### Presentation Tips

1. **Start Simple**: Begin with basic CLI demo, progress to web interface
2. **Explain Output**: Walk through analysis results and their significance
3. **Show Comparisons**: Compare before/after refactoring results
4. **Interactive Elements**: Use web interface for audience engagement

### Educational Use

1. **Progressive Complexity**: Start with simple projects, move to complex ones
2. **Focus Areas**: Highlight specific analysis aspects per session
3. **Hands-on Practice**: Let students run their own demos
4. **Real Examples**: Use actual projects rather than contrived examples

## Summary

The `pmat demo` command provides comprehensive demonstrations of PMAT's capabilities:

- **Multiple Protocols**: CLI, HTTP, and MCP integration modes
- **Rich Output Formats**: JSON, table, and interactive web interfaces
- **Repository Flexibility**: Local projects or remote repositories
- **Performance Monitoring**: Built-in profiling and optimization metrics
- **Educational Value**: Perfect for teaching code quality concepts
- **Integration Ready**: Seamless workflow integration possibilities

Use demos to:
1. **Showcase Capabilities**: Demonstrate PMAT's full analysis power
2. **Educational Presentations**: Teach code quality and analysis concepts
3. **Client Demonstrations**: Professional quality assessment presentations
4. **Development Workflows**: Integrate quality analysis into daily practices
5. **Performance Monitoring**: Track and optimize analysis performance

## Next Steps

- [Chapter 9: Pre-commit Hooks](ch09-00-precommit-hooks.md) - Automated quality enforcement
- [Chapter 5: Analyze Suite](ch05-00-analyze-suite.md) - Detailed analysis commands  
- [Chapter 7: Quality Gates](ch07-00-quality-gate.md) - Quality enforcement systems