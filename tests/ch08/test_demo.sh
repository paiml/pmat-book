#!/bin/bash
# TDD Test: Chapter 8 - pmat demo Command
# Tests interactive demo and reporting features

set -e

# pmat shim: when pmat is absent, fail silently (no "command not found" text
# for greps to match); every caller then takes its SKIPPED arm.
pmat() {
    type -P pmat >/dev/null 2>&1 || return 127
    command pmat "$@"
}


echo "=== Testing Chapter 8: pmat demo Command ==="

# Check if pmat is available
PMAT_BIN=""
if type -P pmat &> /dev/null; then
    PMAT_BIN="pmat"
    MOCK_MODE=false
    echo "✅ PMAT detected in PATH"
elif [ -x "../paiml-mcp-agent-toolkit/target/release/pmat" ]; then
    PMAT_BIN="../paiml-mcp-agent-toolkit/target/release/pmat"
    echo "✅ PMAT detected in target/release"
elif [ -x "../paiml-mcp-agent-toolkit/target/debug/pmat" ]; then
    PMAT_BIN="../paiml-mcp-agent-toolkit/target/debug/pmat"
    echo "✅ PMAT detected in target/debug"
else
    echo "⚠️  PMAT not found, using mock tests"
    MOCK_MODE=true
    PMAT_BIN="pmat"
fi

if [ "$PMAT_BIN" != "pmat" ] && [ -x "$PMAT_BIN" ]; then
    MOCK_MODE=false
    echo "Using PMAT binary: $PMAT_BIN"
fi

TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

test_pass() {
    echo "✅ PASS: $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

test_fail() {
    echo "❌ FAIL: $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

# A check that did not run is SKIPPED and counts zero passes.
test_skip() {
    echo "⚠️  SKIPPED: $1"
    SKIP_COUNT=$((SKIP_COUNT + 1))
}

# pmat demo is behind the non-default `demo` Cargo feature. In the default
# pmat 3.44.0 build every demo mode exits 1 with DEMO_GATE_MSG (the documented
# feature-gate message; ch08 says the same). A check passes only when both hold:
# a non-zero exit AND that exact message. Run with the flags the chapter lists
# (`-p`, not a positional path).
DEMO_GATE_MSG="Demo feature not enabled"

demo_gate_check() {
    local label="$1"
    shift
    local out rc
    out=$($PMAT_BIN demo "$@" 2>&1 </dev/null) && rc=0 || rc=$?
    if [ "$rc" -ne 0 ] && echo "$out" | grep -qF "$DEMO_GATE_MSG"; then
        test_pass "$label"
    else
        test_fail "$label (exit $rc, feature-gate message expected)"
    fi
}

# Test 1: Create test project for demo
echo ""
echo "Test 1: Creating test project for demo"

mkdir -p src tests docs
cat > src/main.rs << 'EOF'
//! Demo project for PMAT testing

use std::collections::HashMap;

/// Calculate fibonacci numbers with memoization
fn fibonacci(n: u32, memo: &mut HashMap<u32, u64>) -> u64 {
    if n <= 1 {
        return n as u64;
    }
    
    if let Some(&value) = memo.get(&n) {
        return value;
    }
    
    let result = fibonacci(n - 1, memo) + fibonacci(n - 2, memo);
    memo.insert(n, result);
    result
}

/// Process a list of numbers and apply various transformations
fn process_numbers(numbers: Vec<i32>) -> Vec<i32> {
    let mut result = Vec::new();
    
    for num in numbers {
        if num > 0 {
            if num % 2 == 0 {
                result.push(num * 2);
            } else {
                result.push(num + 1);
            }
        } else if num < 0 {
            result.push(num.abs());
        } else {
            result.push(1);
        }
    }
    
    result
}

// TODO: Add error handling to this function
fn divide(a: f64, b: f64) -> f64 {
    a / b  // FIXME: Handle division by zero
}

fn main() {
    let mut memo = HashMap::new();
    println!("Fibonacci(10): {}", fibonacci(10, &mut memo));
    
    let numbers = vec![1, -2, 0, 4, -5, 6];
    let processed = process_numbers(numbers);
    println!("Processed: {:?}", processed);
    
    let result = divide(10.0, 2.0);
    println!("Division result: {}", result);
}
EOF

cat > src/lib.rs << 'EOF'
//! Library module for demo project

/// A simple calculator with basic operations
pub struct Calculator {
    history: Vec<f64>,
}

impl Calculator {
    pub fn new() -> Self {
        Self {
            history: Vec::new(),
        }
    }
    
    pub fn add(&mut self, a: f64, b: f64) -> f64 {
        let result = a + b;
        self.history.push(result);
        result
    }
    
    pub fn multiply(&mut self, a: f64, b: f64) -> f64 {
        let result = a * b;
        self.history.push(result);
        result
    }
    
    pub fn get_history(&self) -> &Vec<f64> {
        &self.history
    }
}

// Dead code - unused function
fn unused_helper() -> String {
    "This function is never used".to_string()
}
EOF

cat > tests/integration_test.rs << 'EOF'
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test] 
    fn test_calculator_add() {
        let mut calc = Calculator::new();
        assert_eq!(calc.add(2.0, 3.0), 5.0);
    }
    
    #[test]
    fn test_calculator_multiply() {
        let mut calc = Calculator::new();
        assert_eq!(calc.multiply(2.0, 3.0), 6.0);
    }
}
EOF

cat > README.md << 'EOF'
# Demo Project

A demonstration project for PMAT testing and analysis.

## Features

- Fibonacci calculation with memoization
- Number processing functions
- Basic calculator implementation
- Integration tests

## Usage

```bash
cargo run
cargo test
```
EOF

echo "fixture: Demo test project created"

# Test 2: Basic demo command (CLI mode)
echo ""
echo "Test 2: Basic demo command (CLI mode)"

if [ "$MOCK_MODE" = false ]; then
    demo_gate_check "CLI demo reports the feature gate (default build)" -p . --cli

else
    cat > demo_cli.txt << 'EOF'
🎯 PMAT Interactive Demo
========================

Project: /tmp/demo-project
Files Analyzed: 4
Lines of Code: 87
Languages: Rust (100%)

📊 Analysis Summary:
   Complexity Analysis: ✅ Complete
   Dead Code Detection: ✅ Complete  
   Technical Debt: ✅ Complete
   Architecture Analysis: ✅ Complete

🔍 Key Findings:
   • Average Complexity: 4.2
   • Dead Code Found: 1 function (unused_helper)
   • Technical Debt: 2 markers (TODO, FIXME)
   • Test Coverage: 67%

📈 Quality Metrics:
   • Maintainability Index: B+
   • Technical Debt Ratio: 2.3%
   • Code Duplication: 0%
   • Cyclomatic Complexity: Low

🎨 Architecture Insights:
   • Pattern: Library + Binary
   • Dependencies: Standard library only
   • Modularity: Good separation

✅ Demo Complete - Project analyzed successfully!
EOF
    test_skip "Mock CLI demo completed"
fi

# Test 3: Demo with JSON output format
echo ""
echo "Test 3: Demo with JSON output format"

if [ "$MOCK_MODE" = false ]; then
    demo_gate_check "JSON demo reports the feature gate (default build)" -p . --cli --format=json

else
    cat > demo.json << 'EOF'
{
  "demo_type": "comprehensive_analysis",
  "timestamp": "2025-09-09T10:30:00Z",
  "project": {
    "path": "/tmp/demo-project",
    "name": "demo-project",
    "files_analyzed": 4,
    "total_lines": 87,
    "languages": {
      "Rust": 87
    }
  },
  "analysis_results": {
    "complexity": {
      "average": 4.2,
      "maximum": 8,
      "functions_analyzed": 6,
      "high_complexity_functions": []
    },
    "dead_code": {
      "unused_functions": 1,
      "unused_variables": 0,
      "dead_code_percentage": 5.7,
      "findings": [
        {
          "file": "src/lib.rs",
          "function": "unused_helper", 
          "line": 33,
          "type": "unused_function"
        }
      ]
    },
    "technical_debt": {
      "total_markers": 2,
      "todo_count": 1,
      "fixme_count": 1,
      "hack_count": 0,
      "markers": [
        {
          "file": "src/main.rs",
          "line": 35,
          "type": "TODO",
          "message": "Add error handling to this function"
        },
        {
          "file": "src/main.rs", 
          "line": 37,
          "type": "FIXME",
          "message": "Handle division by zero"
        }
      ]
    },
    "architecture": {
      "pattern": "library_with_binary",
      "modularity_score": 0.85,
      "dependency_count": 1,
      "coupling": "low"
    }
  },
  "quality_metrics": {
    "maintainability_index": 78,
    "technical_debt_ratio": 2.3,
    "duplication_percentage": 0.0,
    "test_coverage": 67
  },
  "recommendations": [
    "Remove unused_helper function",
    "Add error handling to divide function", 
    "Increase test coverage for main.rs"
  ]
}
EOF
    test_skip "Mock JSON demo completed"
    
    if command -v jq &> /dev/null && jq empty demo.json 2>/dev/null; then
        test_skip "Mock JSON is valid"
    fi
fi

# Test 4: Demo with debug mode
echo ""
echo "Test 4: Demo with debug mode"

if [ "$MOCK_MODE" = false ]; then
    demo_gate_check "Debug demo reports the feature gate (default build)" -p . --cli --debug --debug-output=debug-report.json

else
    cat > demo_debug.txt << 'EOF'
🐛 PMAT Demo (Debug Mode)
=========================

[DEBUG] File classification started...
[DEBUG] src/main.rs: Rust source file (87 lines)
[DEBUG] src/lib.rs: Rust library file (45 lines)
[DEBUG] tests/integration_test.rs: Test file (23 lines)
[DEBUG] README.md: Documentation (12 lines)

[DEBUG] Analysis pipeline started...
[DEBUG] Complexity analysis: 234ms
[DEBUG] Dead code detection: 156ms
[DEBUG] SATD analysis: 89ms
[DEBUG] Architecture analysis: 312ms

[DEBUG] Report generation: 45ms
[DEBUG] Total analysis time: 836ms

✅ Debug analysis complete
📄 Debug report saved to: debug-report.json
EOF

    cat > debug-report.json << 'EOF'
{
  "debug_info": {
    "analysis_time_ms": 836,
    "files_processed": 4,
    "pipeline_stages": [
      {"stage": "file_classification", "time_ms": 45},
      {"stage": "complexity_analysis", "time_ms": 234},
      {"stage": "dead_code_detection", "time_ms": 156},
      {"stage": "satd_analysis", "time_ms": 89},
      {"stage": "architecture_analysis", "time_ms": 312}
    ]
  }
}
EOF
    test_skip "Mock debug demo completed"
    test_skip "Mock debug report file created"
fi

# Test 5: Demo with HTTP protocol (simulated)
echo ""
echo "Test 5: Demo with HTTP protocol (web mode)"

if [ "$MOCK_MODE" = false ]; then
    demo_gate_check "Web demo reports the feature gate (default build)" -p . --no-browser --port=0

else
    cat > web_demo.txt << 'EOF'
🌐 PMAT Web Demo Server
=======================

Starting analysis of: /tmp/demo-project
Port: 3847 (auto-selected)
URL: http://localhost:3847

📊 Analysis Progress:
   [████████████████████] 100% Complete

🎯 Demo Features Available:
   • Interactive code analysis
   • Visual complexity graphs
   • Architecture diagrams
   • Quality metrics dashboard
   • Technical debt tracking

Server running at: http://localhost:3847
Press Ctrl+C to stop server

📈 Real-time Analysis:
   Files: 4 | Lines: 87 | Quality: B+
   
✅ Demo server ready - Open browser to explore!
EOF
    test_skip "Mock web demo server started"
fi

# Test 6: Demo with repository URL (GitHub)
echo ""
echo "Test 6: Demo with repository URL analysis"

if [ "$MOCK_MODE" = false ]; then
    demo_gate_check "Repository demo reports the feature gate (default build)" --repo=gh:rust-lang/rustlings --cli

else
    cat > repo_demo.txt << 'EOF'
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
EOF
    test_skip "Mock repository demo completed"
fi

# Test 7: Demo with MCP protocol
echo ""
echo "Test 7: Demo with MCP protocol"

if [ "$MOCK_MODE" = false ]; then
    demo_gate_check "MCP protocol demo reports the feature gate (default build)" -p . --protocol=mcp --cli

else
    cat > mcp_demo.txt << 'EOF'
🔌 PMAT MCP Protocol Demo
=========================

MCP Server: pmat-analysis-server
Protocol Version: 2024-11-05
Transport: stdio

🛠️  Available Tools:
   • analyze_repository
   • generate_context  
   • quality_gate_check
   • tdg_analysis
   • scaffold_project

📋 Available Prompts:
   • code_review_prompt
   • refactoring_suggestions
   • architecture_analysis
   • quality_improvement

🎯 Demo Analysis (via MCP):
   Repository: /tmp/demo-project
   
   Tool Call: analyze_repository
   Parameters: {"path": "/tmp/demo-project", "include_tests": true}
   
   Result: {
     "files": 4,
     "complexity": {"average": 4.2, "max": 8},
     "quality_score": 78,
     "recommendations": ["Remove unused code", "Add error handling"]
   }

✅ MCP Demo Complete - Tools working correctly!
EOF
    test_skip "Mock MCP protocol demo completed"
fi

# Test 8: Demo with performance metrics and visualization
echo ""
echo "Test 8: Demo with performance metrics"

if [ "$MOCK_MODE" = false ]; then
    demo_gate_check "Performance demo reports the feature gate (default build)" -p . --cli --format=table --target-nodes=10

else
    cat > perf_demo.txt << 'EOF'
⚡ PMAT Performance Demo
========================

Project: /tmp/demo-project
Target Nodes: 10 (complexity reduction enabled)

⏱️  Analysis Performance:
   File Discovery: 12ms
   Parsing: 156ms
   Complexity Analysis: 234ms
   Dead Code Detection: 89ms
   Architecture Analysis: 145ms
   Report Generation: 67ms
   
   Total Time: 703ms
   Lines/sec: 124
   Files/sec: 5.7

📊 Analysis Results (Table Format):

┌─────────────────┬───────────┬────────────┬──────────────┐
│ File            │ Lines     │ Complexity │ Issues       │
├─────────────────┼───────────┼────────────┼──────────────┤
│ src/main.rs     │ 42        │ 6.2        │ 2 SATD       │
│ src/lib.rs      │ 45        │ 3.8        │ 1 dead code  │
│ tests/*.rs      │ 23        │ 2.1        │ 0            │
│ README.md       │ 12        │ N/A        │ 0            │
└─────────────────┴───────────┴────────────┴──────────────┘

🎯 Performance Insights:
   • Efficient analysis pipeline
   • Graph reduction successful (10 nodes)
   • Memory usage: 4.2MB peak
   • CPU utilization: 23%

✅ Performance demo complete - System optimized!
EOF
    test_skip "Mock performance demo completed"
    test_skip "Performance metrics included"
fi

# Cleanup
cd /
rm -rf "$TEST_DIR"

echo ""
echo "=== Chapter 8 Demo Test Summary ==="
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"
echo "Skipped: $SKIP_COUNT"

# pmat on PATH but nothing verified: that is a failure, not a skip.
if [ $FAIL_COUNT -eq 0 ] && [ $PASS_COUNT -eq 0 ] && type -P pmat >/dev/null 2>&1; then
    echo "❌ pmat is on PATH but no check passed: nothing verified"
    exit 1
fi
if [ $FAIL_COUNT -eq 0 ] && [ $PASS_COUNT -eq 0 ]; then
    echo "⚠️  SKIPPED: this run verified NOTHING"
    exit 0
fi
if [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ All demo tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi
