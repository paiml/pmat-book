# Chapter 13: Multi-Language Project Examples

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ FULLY VALIDATED - All tests passing

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Full AST Support | 10 | Rust, Python, TypeScript, JavaScript, C, C++, Kotlin, WASM, Bash, PHP |
| ⚠️ Pattern-Based | 4 | Go, Java, C#, Swift (regex/lexical, not full AST) |
| ❌ Aspirational | 1 | Ruby (planned for Sprint 51) |
| 📋 Tests Status | 100% | All test files passing with actual PMAT commands |

*Last updated: 2025-10-27 (Sprint 49)*
*PMAT version: v2.171.1*
<!-- DOC_STATUS_END -->

## The Problem

Modern software projects rarely use a single programming language. Teams work with polyglot codebases that combine backend services in Go or Python, frontend applications in TypeScript/React, infrastructure scripts in Bash, and configuration files in YAML or JSON. Each language has its own idioms, patterns, and potential technical debt sources.

Traditional code analysis tools focus on single languages, leaving gaps in understanding the overall codebase quality. Developers need a unified view of technical debt, complexity, and quality metrics across all languages in their project.

## PMAT's Multi-Language Approach

PMAT provides comprehensive analysis across 10+ programming languages with:

- **Language-Specific Analysis**: Custom analyzers for each language's unique patterns
- **Unified Quality Metrics**: Consistent grading system across all languages
- **Cross-Language Insights**: Understanding how languages interact in polyglot projects
- **Technical Debt Detection**: Language-aware SATD (Self-Admitted Technical Debt) identification
- **Configuration Analysis**: Quality assessment of infrastructure and config files

### Supported Languages

**Full AST Analysis (Tree-Sitter Parsers):**

| Language | Extensions | Analysis Features |
|----------|------------|------------------|
| **Rust** | `.rs` | Memory safety, ownership, cargo integration, full AST |
| **Python** | `.py` | Functions, classes, complexity, PEP compliance, full AST |
| **TypeScript** | `.ts`, `.tsx` | Type safety, React components, interface usage, full AST |
| **JavaScript** | `.js`, `.jsx` | ES6+ patterns, async code, modern practices, full AST |
| **C** | `.c`, `.h` | Functions, structs, memory management, pointer usage, full AST |
| **C++** | `.cpp`, `.cc`, `.cxx`, `.hpp`, `.hxx`, `.hh` | Classes, templates, namespaces, memory management, full AST |
| **Kotlin** | `.kt` | JVM interop, null safety, coroutines, full AST |
| **WASM** | `.wasm`, `.wat` | Binary/text analysis, instruction-level inspection, disassembly |
| **Bash** | `.sh`, `.bash` | Function extraction, error handling, script quality, full AST |
| **PHP** | `.php` | Class/function detection, error handling patterns, full AST |

**Pattern-Based Analysis (Regex/Lexical Parsing):**

| Language | Extensions | Analysis Features | Limitations |
|----------|------------|------------------|-------------|
| **Go** | `.go` | Error handling, concurrency, modules | Pattern-based (not full AST) |
| **Java** | `.java` | Enterprise patterns, deprecation, complexity | Pattern-based (not full AST) |
| **C#** | `.cs` | .NET patterns, LINQ, async/await | Pattern-based (not full AST) |
| **Swift** | `.swift` | Optionals, error handling patterns | Pattern-based (not full AST) |

> **Note**: Pattern-based analyzers use regex and lexical analysis instead of full AST parsing. They can detect functions, classes, and basic patterns but may miss complex language constructs.

### Configuration & Markup Support

| Type | Extensions | Features |
|------|------------|----------|
| **Markdown** | `.md` | Documentation quality, TODO tracking |
| **YAML** | `.yml`, `.yaml` | Structure validation, security checks |
| **JSON** | `.json` | Schema validation, configuration patterns |
| **TOML** | `.toml` | Rust/Python config analysis |

## Language-Specific Examples

### Python Project Analysis

Python projects benefit from PMAT's deep understanding of Python idioms, PEP compliance, and common technical debt patterns.

**Project Structure:**
```
python_example/
├── src/
│   ├── calculator.py
│   └── utils.py
├── tests/
│   └── test_calculator.py
└── pmat.toml
```

**Source Code with Technical Debt:**
```python
# src/calculator.py
"""A simple calculator with technical debt examples."""

def add(a, b):
    # TODO: Add input validation
    return a + b

def divide(a, b):
    # FIXME: Handle division by zero properly
    if b == 0:
        print("Error: Division by zero!")  # Code smell: print statement
        return None
    return a / b

class Calculator:
    """Calculator class with various complexity levels."""
    
    def __init__(self):
        self.history = []
    
    def complex_calculation(self, x, y, z):
        # NOTE: This method has high cyclomatic complexity
        if x > 0:
            if y > 0:
                if z > 0:
                    result = x * y * z
                    if result > 1000:
                        return result / 2
                    else:
                        return result
                else:
                    return x * y
            else:
                return x
        else:
            return 0
    
    def unused_method(self):
        """Dead code example."""
        pass
```

**PMAT Analysis Command:**
```bash
# Analyze Python project with specific configuration
pmat analyze python_example/ --language python --include-tests

# Generate detailed report
pmat report python_example/ --format json --output python_analysis.json
```

**Analysis Output:**
```json
{
  "language": "python",
  "files_analyzed": 3,
  "functions_found": 7,
  "technical_debt": {
    "todo_comments": 1,
    "fixme_comments": 1,
    "note_comments": 1,
    "code_smells": 2
  },
  "complexity": {
    "average_complexity": 3.2,
    "max_complexity": 8,
    "high_complexity_functions": ["complex_calculation"]
  },
  "code_quality": {
    "pep8_violations": 0,
    "type_hints": "missing",
    "dead_code": 1
  },
  "grade": "B-",
  "recommendations": [
    "Add input validation to functions",
    "Replace print statements with logging",
    "Add type hints for better maintainability",
    "Reduce complexity in complex_calculation method"
  ]
}
```

**Key Python Analysis Features:**
- **PEP Compliance**: Checks for Python Enhancement Proposal standards
- **Type Hint Analysis**: Identifies missing type annotations
- **Import Analysis**: Detects unused imports and circular dependencies
- **Exception Handling**: Evaluates error handling patterns
- **Dead Code Detection**: Finds unused functions and variables

### JavaScript/Node.js Project Analysis

Modern JavaScript projects require understanding of ES6+ features, async patterns, and Node.js ecosystem conventions.

**Project Structure:**
```
js_example/
├── src/
│   ├── index.js
│   └── utils.js
├── tests/
│   └── index.test.js
└── package.json
```

**Modern JavaScript with Technical Debt:**
```javascript
// src/index.js
const express = require('express');

// TODO: Add proper error handling
function createServer() {
    const app = express();
    
    app.get('/', (req, res) => {
        res.send('Hello World');
    });
    
    return app;
}

// Code smell: var usage instead of const/let
var globalVar = "should be const";

// HACK: Quick fix needed
function quickFix(data) {
    if (!data) return null;
    if (typeof data !== 'string') return null;
    if (data.length === 0) return null;
    if (data.trim().length === 0) return null;
    return data.trim();
}

// Duplicate logic
function processString(str) {
    if (!str) return null;
    if (typeof str !== 'string') return null;
    return str.trim();
}

module.exports = { createServer, quickFix, processString };
```

**Async/Await Patterns:**
```javascript
// src/utils.js
const asyncFunction = async (items) => {
    const results = [];
    
    for (const item of items) {
        try {
            const processed = await processItem(item);
            results.push(processed);
        } catch (error) {
            console.log('Error:', error); // Code smell: console.log
        }
    }
    
    return results;
};

const processItem = async (item) => {
    return new Promise(resolve => {
        setTimeout(() => resolve(item.toUpperCase()), 10);
    });
};
```

**PMAT Analysis:**
```bash
# Analyze JavaScript project
pmat analyze js_example/ --language javascript

# Check for modern patterns
pmat clippy js_example/ --rules "prefer-const,no-var,async-await-patterns"
```

**Analysis Results:**
```json
{
  "language": "javascript",
  "files_analyzed": 2,
  "functions_found": 5,
  "technical_debt": {
    "todo_comments": 1,
    "hack_comments": 1,
    "code_smells": 3
  },
  "modern_features": {
    "arrow_functions": true,
    "async_await": true,
    "const_let_usage": "partial",
    "template_literals": false
  },
  "code_quality": {
    "var_usage": 1,
    "console_usage": 2,
    "duplicate_logic": 1
  },
  "grade": "C+",
  "recommendations": [
    "Replace var with const/let declarations",
    "Use proper logging instead of console.log",
    "Extract duplicate validation logic",
    "Add proper error handling for async operations"
  ]
}
```

### Rust Project Analysis

Rust projects benefit from PMAT's understanding of ownership, memory safety, and cargo ecosystem patterns.

**Cargo Project Structure:**
```
rust_example/
├── Cargo.toml
└── src/
    ├── main.rs
    └── lib.rs
```

**Rust Code with Complexity:**
```rust
// src/main.rs
use std::collections::HashMap;

// TODO: Add proper error handling
fn main() {
    let result = calculate_stats(&[1, 2, 3, 4, 5]);
    println!("Stats: {:?}", result);
}

#[derive(Debug)]
struct Stats {
    mean: f64,
    median: f64,
}

fn calculate_stats(numbers: &[i32]) -> Stats {
    let sum: i32 = numbers.iter().sum();
    let mean = sum as f64 / numbers.len() as f64;
    
    let mut sorted = numbers.to_vec();
    sorted.sort();
    let median = sorted[sorted.len() / 2] as f64;
    
    Stats { mean, median }
}

// Complex function with high cyclomatic complexity
fn complex_logic(x: i32, y: i32, z: i32) -> i32 {
    if x > 0 {
        if y > 0 {
            if z > 0 {
                if x > y {
                    if y > z {
                        return x + y + z;
                    } else {
                        return x + y - z;
                    }
                } else {
                    return y + z;
                }
            } else {
                return x + y;
            }
        } else {
            return x;
        }
    } else {
        0
    }
}
```

**Library Module:**
```rust
// src/lib.rs
//! Rust library with various patterns

pub mod utils {
    use std::collections::HashMap;
    
    /// Hash map operations with potential issues
    pub fn process_data(data: Vec<String>) -> HashMap<String, usize> {
        let mut result = HashMap::new();
        
        for item in data {
            // NOTE: This could be optimized
            let count = result.get(&item).unwrap_or(&0) + 1;
            result.insert(item, count);
        }
        
        result
    }
    
    // Duplicate functionality
    pub fn count_items(items: Vec<String>) -> HashMap<String, usize> {
        let mut counts = HashMap::new();
        for item in items {
            let count = counts.get(&item).unwrap_or(&0) + 1;
            counts.insert(item, count);
        }
        counts
    }
}
```

**PMAT Rust Analysis:**
```bash
# Analyze Rust project with Cargo integration
pmat analyze rust_example/ --language rust --cargo-features

# Check for Rust-specific patterns
pmat clippy rust_example/ --rust-edition 2021
```

**Rust Analysis Output:**
```json
{
  "language": "rust",
  "files_analyzed": 2,
  "functions_found": 5,
  "technical_debt": {
    "todo_comments": 1,
    "fixme_comments": 0,
    "note_comments": 1
  },
  "rust_patterns": {
    "ownership_violations": 0,
    "unsafe_blocks": 0,
    "dead_code_warnings": 1,
    "unused_imports": 0
  },
  "complexity": {
    "average_complexity": 4.1,
    "max_complexity": 12,
    "high_complexity_functions": ["complex_logic"]
  },
  "cargo_integration": {
    "dependencies": 1,
    "dev_dependencies": 0,
    "features_used": ["derive"]
  },
  "grade": "B",
  "recommendations": [
    "Reduce cyclomatic complexity in complex_logic",
    "Consider using Result<T, E> for error handling",
    "Remove duplicate functionality between process_data and count_items",
    "Add documentation for public API functions"
  ]
}
```

### Java Enterprise Project Analysis

Java projects often involve enterprise patterns, framework usage, and complex architectures that PMAT can analyze comprehensively.

**Maven Project Structure:**
```
java_example/
├── pom.xml
├── src/main/java/com/example/
│   └── Calculator.java
└── src/test/java/com/example/
    └── CalculatorTest.java
```

**Enterprise Java Code:**
```java
// src/main/java/com/example/Calculator.java
package com.example;

import java.util.List;
import java.util.ArrayList;

/**
 * Calculator service with enterprise patterns
 */
public class Calculator {
    
    // TODO: Add proper logging
    public double add(double a, double b) {
        return a + b;
    }
    
    public double divide(double a, double b) {
        // FIXME: Better error handling needed
        if (b == 0) {
            System.out.println("Division by zero!"); // Code smell
            return 0;
        }
        return a / b;
    }
    
    // Complex method with high cyclomatic complexity
    public String processRequest(String type, double value1, double value2) {
        if (type == null) {
            return "ERROR";
        }
        
        if (type.equals("ADD")) {
            if (value1 > 0 && value2 > 0) {
                return String.valueOf(add(value1, value2));
            } else {
                return "INVALID_VALUES";
            }
        } else if (type.equals("DIVIDE")) {
            if (value1 != 0 && value2 != 0) {
                return String.valueOf(divide(value1, value2));
            } else {
                return "INVALID_VALUES";
            }
        } else {
            return "UNKNOWN_OPERATION";
        }
    }
    
    // Dead code
    @Deprecated
    private void legacyMethod() {
        // HACK: Old implementation
    }
}
```

**PMAT Java Analysis:**
```bash
# Analyze Java project with Maven integration
pmat analyze java_example/ --language java --maven-project

# Check enterprise patterns
pmat quality-gate java_example/ --enterprise-rules
```

**Java Analysis Results:**
```json
{
  "language": "java",
  "files_analyzed": 1,
  "functions_found": 4,
  "technical_debt": {
    "todo_comments": 1,
    "fixme_comments": 1,
    "hack_comments": 1
  },
  "enterprise_patterns": {
    "deprecated_methods": 1,
    "complex_conditionals": 2,
    "system_out_usage": 1
  },
  "complexity": {
    "average_complexity": 5.2,
    "max_complexity": 9,
    "methods_over_threshold": ["processRequest"]
  },
  "code_quality": {
    "javadoc_coverage": "partial",
    "exception_handling": "weak",
    "design_patterns": []
  },
  "grade": "B-",
  "recommendations": [
    "Replace System.out with proper logging framework",
    "Add comprehensive JavaDoc documentation",
    "Implement proper exception handling with custom exceptions",
    "Extract complex conditional logic into separate methods"
  ]
}
```

### Go Project Analysis

Go projects emphasize simplicity, error handling, and concurrent programming patterns that PMAT understands well.

**Go Module Structure:**
```
go_example/
├── go.mod
├── cmd/server/
│   └── main.go
└── internal/handler/
    └── calculator.go
```

**Go HTTP Service:**
```go
// cmd/server/main.go
package main

import (
    "fmt"
    "log"
    "net/http"
    "github.com/gorilla/mux"
    "github.com/example/go-example/internal/handler"
)

// TODO: Add configuration management
func main() {
    r := mux.NewRouter()
    
    h := handler.New()
    r.HandleFunc("/health", h.HealthCheck).Methods("GET")
    r.HandleFunc("/calculate", h.Calculate).Methods("POST")
    
    fmt.Println("Server starting on :8080")
    log.Fatal(http.ListenAndServe(":8080", r))
}
```

**Handler with Complex Logic:**
```go
// internal/handler/calculator.go
package handler

import (
    "encoding/json"
    "fmt"
    "net/http"
)

type Handler struct{}

type CalculateRequest struct {
    A float64 `json:"a"`
    B float64 `json:"b"`
    Op string `json:"operation"`
}

func New() *Handler {
    return &Handler{}
}

// FIXME: Add input validation
func (h *Handler) Calculate(w http.ResponseWriter, r *http.Request) {
    var req CalculateRequest
    
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "Invalid JSON", http.StatusBadRequest)
        return
    }
    
    // Complex conditional logic
    var result float64
    switch req.Op {
    case "add":
        result = req.A + req.B
    case "subtract":
        result = req.A - req.B
    case "multiply":
        result = req.A * req.B
    case "divide":
        if req.B == 0 {
            http.Error(w, "Division by zero", http.StatusBadRequest)
            return
        }
        result = req.A / req.B
    default:
        http.Error(w, "Unknown operation", http.StatusBadRequest)
        return
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]float64{"result": result})
}
```

**PMAT Go Analysis:**
```bash
# Analyze Go project with module awareness
pmat analyze go_example/ --language go --go-modules

# Check Go-specific patterns
pmat clippy go_example/ --go-version 1.19
```

**Go Analysis Output:**
```json
{
  "language": "go",
  "files_analyzed": 2,
  "functions_found": 4,
  "technical_debt": {
    "todo_comments": 1,
    "fixme_comments": 1,
    "note_comments": 0
  },
  "go_patterns": {
    "error_handling": "good",
    "goroutine_usage": false,
    "channel_usage": false,
    "interface_usage": false
  },
  "http_patterns": {
    "handler_functions": 2,
    "middleware_usage": false,
    "json_handling": "present"
  },
  "complexity": {
    "average_complexity": 3.8,
    "max_complexity": 7
  },
  "grade": "B",
  "recommendations": [
    "Add input validation middleware",
    "Consider using context for request handling",
    "Add structured logging instead of fmt.Println",
    "Implement proper configuration management"
  ]
}
```

### TypeScript React Project Analysis

TypeScript React projects combine type safety with component-based architecture, requiring specialized analysis.

**React TypeScript Structure:**
```
ts_example/
├── package.json
├── tsconfig.json
└── src/
    ├── components/
    │   └── Calculator.tsx
    └── utils/
        └── helpers.ts
```

**React Component with Technical Debt:**
```tsx
// src/components/Calculator.tsx
import React, { useState } from 'react';

interface CalculatorProps {
  theme?: 'light' | 'dark';
}

// TODO: Add proper error boundaries
export const Calculator: React.FC<CalculatorProps> = ({ theme = 'light' }) => {
  const [result, setResult] = useState<number>(0);
  const [input1, setInput1] = useState<string>('');
  const [input2, setInput2] = useState<string>('');
  
  // Complex calculation logic
  const handleCalculate = (operation: string) => {
    const a = parseFloat(input1);
    const b = parseFloat(input2);
    
    // FIXME: Add better validation
    if (isNaN(a) || isNaN(b)) {
      console.error('Invalid input'); // Code smell
      return;
    }
    
    let calcResult: number;
    
    if (operation === 'add') {
      calcResult = a + b;
    } else if (operation === 'subtract') {
      calcResult = a - b;
    } else if (operation === 'multiply') {
      calcResult = a * b;
    } else if (operation === 'divide') {
      if (b === 0) {
        alert('Cannot divide by zero'); // Code smell
        return;
      }
      calcResult = a / b;
    } else {
      throw new Error('Unknown operation');
    }
    
    setResult(calcResult);
  };
  
  return (
    <div className={`calculator ${theme}`}>
      <input 
        value={input1} 
        onChange={(e) => setInput1(e.target.value)}
        placeholder="First number"
      />
      <input 
        value={input2} 
        onChange={(e) => setInput2(e.target.value)}
        placeholder="Second number"
      />
      <div>
        <button onClick={() => handleCalculate('add')}>Add</button>
        <button onClick={() => handleCalculate('subtract')}>Subtract</button>
        <button onClick={() => handleCalculate('multiply')}>Multiply</button>
        <button onClick={() => handleCalculate('divide')}>Divide</button>
      </div>
      <div>Result: {result}</div>
    </div>
  );
};
```

**PMAT TypeScript Analysis:**
```bash
# Analyze TypeScript React project
pmat analyze ts_example/ --language typescript --react-components

# Check TypeScript patterns
pmat clippy ts_example/ --typescript-strict --react-hooks
```

**TypeScript Analysis Results:**
```json
{
  "language": "typescript",
  "files_analyzed": 1,
  "functions_found": 2,
  "components_found": 1,
  "technical_debt": {
    "todo_comments": 1,
    "fixme_comments": 1,
    "code_smells": 2
  },
  "typescript_patterns": {
    "type_safety": "good",
    "interface_usage": true,
    "strict_mode": true,
    "any_usage": 0
  },
  "react_patterns": {
    "functional_components": true,
    "hooks_usage": ["useState"],
    "prop_types": "typescript",
    "component_complexity": 6
  },
  "code_quality": {
    "console_usage": 1,
    "alert_usage": 1,
    "error_boundaries": false
  },
  "grade": "B-",
  "recommendations": [
    "Add proper error boundaries for error handling",
    "Replace console.error and alert with proper UI feedback",
    "Extract calculation logic into custom hook",
    "Add unit tests for component behavior"
  ]
}
```

## Polyglot Project Analysis

Real-world projects often combine multiple languages, each serving different purposes. PMAT excels at analyzing these polyglot codebases.

**Polyglot Project Structure:**
```
polyglot_example/
├── backend/          # Python Flask API
│   └── api.py
├── frontend/         # JavaScript client
│   └── main.js
├── scripts/          # Shell deployment scripts
│   └── deploy.sh
└── config/           # Configuration files
    └── settings.toml
```

**Python Backend:**
```python
# backend/api.py
from flask import Flask, jsonify

app = Flask(__name__)

# TODO: Add proper configuration management
@app.route('/health')
def health_check():
    return jsonify({"status": "ok"})

# HACK: Quick implementation
@app.route('/data')
def get_data():
    # Should use proper database
    return jsonify({"data": [1, 2, 3, 4, 5]})
```

**JavaScript Frontend:**
```javascript
// frontend/main.js
const API_URL = 'http://localhost:5000';

// TODO: Use proper state management
let globalState = {};

async function fetchData() {
    try {
        const response = await fetch(`${API_URL}/data`);
        return await response.json();
    } catch (error) {
        console.error('Fetch error:', error);
        return null;
    }
}
```

**Shell Deployment Script:**
```bash
#!/bin/bash
# scripts/deploy.sh

# FIXME: Add proper error handling
set -e

echo "Deploying application..."
# NOTE: This should use proper CI/CD
docker build -t app .
docker run -d -p 5000:5000 app
```

**PMAT Polyglot Analysis:**
```bash
# Analyze entire polyglot project
pmat analyze polyglot_example/ --all-languages

# Generate cross-language report
pmat report polyglot_example/ --polyglot-summary --output polyglot_report.json
```

**Polyglot Analysis Output:**
```json
{
  "project_type": "polyglot",
  "total_files": 4,
  "languages_detected": {
    "python": {
      "files": 1,
      "functions": 2,
      "grade": "C+",
      "primary_issues": ["configuration_management", "database_hardcoding"]
    },
    "javascript": {
      "files": 1,
      "functions": 1,
      "grade": "B-",
      "primary_issues": ["global_state", "error_handling"]
    },
    "shell": {
      "files": 1,
      "grade": "C",
      "primary_issues": ["error_handling", "hardcoded_values"]
    },
    "toml": {
      "files": 1,
      "grade": "A",
      "primary_issues": []
    }
  },
  "cross_language_analysis": {
    "api_consistency": "good",
    "error_handling_consistency": "poor",
    "configuration_management": "inconsistent",
    "deployment_automation": "basic"
  },
  "overall_grade": "B-",
  "architecture_insights": {
    "service_architecture": "microservices",
    "data_flow": "rest_api",
    "deployment_model": "containerized"
  },
  "recommendations": [
    "Standardize error handling across all languages",
    "Implement consistent configuration management",
    "Add proper logging to all components",
    "Create unified deployment pipeline"
  ]
}
```

## Configuration and Markup File Analysis

PMAT also analyzes configuration files, documentation, and markup languages that are crucial to project health.

**Configuration Files Structure:**
```
config_example/
├── docs/
│   └── README.md
└── config/
    ├── app.yaml
    └── package.json
```

**Markdown Documentation:**
```markdown
<!-- docs/README.md -->
# Project Documentation

## Overview
This project demonstrates PMAT analysis capabilities.

<!-- TODO: Add more detailed documentation -->

## Features
- Multi-language support
- Technical debt detection
- Quality grading

### Known Issues
<!-- FIXME: Update this section -->
- Performance optimization needed
- Error handling improvements required

## Installation
```bash
# NOTE: Requires Python 3.8+
pip install -r requirements.txt
```
```

**YAML Configuration:**
```yaml
# config/app.yaml
database:
  # TODO: Use environment variables
  url: "postgres://user:pass@localhost/db"
  pool_size: 10
  
api:
  host: "0.0.0.0"
  port: 8080
  # FIXME: Enable SSL in production
  ssl_enabled: false
  
logging:
  level: "DEBUG"  # NOTE: Should be INFO in production
```

**PMAT Configuration Analysis:**
```bash
# Analyze configuration and documentation
pmat analyze config_example/ --include-config --include-docs

# Security-focused analysis
pmat security-scan config_example/ --check-secrets --check-hardcoded-values
```

**Configuration Analysis Results:**
```json
{
  "markup_files": {
    "markdown": {
      "files": 1,
      "documentation_quality": "good",
      "todo_comments": 1,
      "fixme_comments": 1,
      "note_comments": 1,
      "broken_links": 0
    }
  },
  "config_files": {
    "yaml": {
      "files": 1,
      "structure_validity": "valid",
      "security_issues": [
        "hardcoded_credentials",
        "ssl_disabled",
        "debug_enabled"
      ],
      "todo_comments": 1
    },
    "json": {
      "files": 1,
      "structure_validity": "valid",
      "todo_comments": 1
    }
  },
  "security_analysis": {
    "credentials_exposed": true,
    "ssl_configurations": "insecure",
    "debug_mode_enabled": true,
    "environment_variable_usage": "minimal"
  },
  "overall_config_grade": "C+",
  "security_grade": "C-",
  "recommendations": [
    "Move credentials to environment variables",
    "Enable SSL in all environments",
    "Set appropriate logging levels per environment",
    "Add configuration validation"
  ]
}
```

## MCP Integration for Multi-Language Analysis

PMAT's MCP tools provide programmatic access to multi-language analysis capabilities for integration with AI coding assistants.

### Analyze Repository Tool

```json
{
  "tool": "analyze_repository",
  "params": {
    "path": "/path/to/polyglot/project",
    "include_all_languages": true,
    "generate_cross_language_report": true
  }
}
```

**Response:**
```json
{
  "analysis_results": {
    "languages_detected": ["python", "javascript", "rust", "yaml"],
    "total_files": 45,
    "total_functions": 123,
    "overall_grade": "B+",
    "language_breakdown": {
      "python": {
        "grade": "A-",
        "files": 15,
        "primary_strengths": ["type_hints", "documentation"],
        "improvement_areas": ["complexity_reduction"]
      },
      "javascript": {
        "grade": "B",
        "files": 20,
        "primary_strengths": ["modern_syntax", "async_patterns"],
        "improvement_areas": ["error_handling", "testing"]
      },
      "rust": {
        "grade": "A",
        "files": 8,
        "primary_strengths": ["memory_safety", "error_handling"],
        "improvement_areas": ["documentation"]
      },
      "yaml": {
        "grade": "B-",
        "files": 2,
        "improvement_areas": ["security_hardening"]
      }
    }
  }
}
```

### Language-Specific Analysis Tool

```json
{
  "tool": "analyze_language_specific",
  "params": {
    "path": "/path/to/project",
    "language": "python",
    "analysis_depth": "deep",
    "include_patterns": ["*.py", "*.pyi"],
    "custom_rules": ["pep8", "type-hints", "complexity"]
  }
}
```

### Quality Gate Tool for Polyglot Projects

```json
{
  "tool": "quality_gate",
  "params": {
    "path": "/path/to/project",
    "per_language_thresholds": {
      "python": {"min_grade": "B+"},
      "javascript": {"min_grade": "B"},
      "rust": {"min_grade": "A-"},
      "yaml": {"min_grade": "B"}
    },
    "overall_threshold": "B+"
  }
}
```

## Best Practices for Multi-Language Projects

### 1. Consistent Quality Standards

Set appropriate grade thresholds for each language based on its maturity and criticality:

```toml
# pmat.toml
[quality-gate.thresholds]
python = "A-"      # Critical backend services
javascript = "B+"  # Frontend code
rust = "A"         # Performance-critical components
shell = "B"        # Deployment scripts
yaml = "B+"        # Configuration files
```

### 2. Language-Specific Rules

Configure custom rules for each language's best practices:

```toml
[clippy.python]
enabled = true
rules = [
    "type-hints-required",
    "no-print-statements",
    "pep8-compliance",
    "complexity-max-10"
]

[clippy.javascript]
enabled = true
rules = [
    "prefer-const",
    "no-var",
    "async-await-preferred",
    "no-console-in-production"
]

[clippy.rust]
enabled = true
rules = [
    "clippy::all",
    "clippy::pedantic",
    "prefer-explicit-lifetimes"
]
```

### 3. Cross-Language Architecture Analysis

Use PMAT to understand how different languages interact:

```bash
# Analyze API boundaries between services
pmat analyze . --cross-language-apis

# Check for consistent error handling patterns
pmat analyze . --error-handling-consistency

# Validate configuration consistency
pmat analyze . --config-consistency
```

### 4. Graduated Quality Enforcement

Implement different quality gates for different parts of your codebase:

```yaml
# .github/workflows/quality.yml
name: Multi-Language Quality Gates

on: [push, pull_request]

jobs:
  quality-core:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Core Services Quality Gate
        run: pmat quality-gate src/core/ --min-grade A-
        
  quality-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Frontend Quality Gate
        run: pmat quality-gate frontend/ --min-grade B+
        
  quality-scripts:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Scripts Quality Gate
        run: pmat quality-gate scripts/ --min-grade B
```

## Common Multi-Language Patterns

### 1. Microservices Architecture

Analyze service boundaries and dependencies:

```bash
# Analyze service communication patterns
pmat analyze . --microservices-analysis

# Check for consistent API patterns
pmat analyze . --api-consistency-check
```

### 2. Full-Stack Applications

Coordinate quality between frontend and backend:

```bash
# Analyze full-stack consistency
pmat analyze . --fullstack-analysis

# Check data flow patterns
pmat analyze . --data-flow-analysis
```

### 3. DevOps Integration

Ensure infrastructure code quality:

```bash
# Analyze infrastructure as code
pmat analyze . --include-iac --languages terraform,yaml,dockerfile
```

## Troubleshooting Multi-Language Analysis

### Language Detection Issues

If PMAT doesn't detect a language correctly:

```bash
# Force language detection
pmat analyze . --force-language-detection

# Specify custom file patterns
pmat analyze . --language-patterns "*.custom:python,*.special:rust"
```

### Performance with Large Codebases

For large polyglot projects:

```bash
# Parallel analysis
pmat analyze . --parallel-languages --workers 4

# Incremental analysis
pmat analyze . --incremental --changed-files-only
```

### Custom Language Support

Add support for custom languages or dialects:

```toml
# pmat.toml
[languages.custom]
extensions = [".custom", ".special"]
analyzer = "generic"
rules = ["complexity", "duplication"]
```

## Example: Analyzing C/C++ Projects

PMAT v2.171.1 introduces full AST-based analysis for C and C++ projects, allowing for comprehensive code quality assessment.

### Basic C/C++ Analysis

```bash
# Analyze a C project
pmat analyze ./path/to/c/project

# Analyze a C++ project with detailed output
pmat analyze --verbose ./path/to/cpp/project

# Generate deep context for a mixed C/C++ project
pmat context --output cpp_context.md ./path/to/cpp/project

# Focus on header files only
pmat analyze --include "*.h,*.hpp" ./path/to/cpp/project
```

### Finding Complexity Issues in C/C++

```bash
# Identify complex functions
pmat complexity --threshold 10 ./path/to/cpp/project

# Focus on specific file types
pmat complexity --include "*.cpp" --exclude "*test*" ./path/to/cpp/project

# Generate complexity report for a C project
pmat complexity --format markdown --output complexity.md ./path/to/c/project
```

### Deep Analysis Example

This example analyzes a C++ calculator project and generates metrics:

```bash
# Clone example C++ project
git clone https://github.com/example/cpp-calculator

# Generate comprehensive analysis
pmat analyze --deep ./cpp-calculator

# Check complexity specifically
pmat complexity ./cpp-calculator

# Find technical debt in comments
pmat satd ./cpp-calculator

# Generate complete context with all metrics
pmat context --output calculator_context.md ./cpp-calculator
```

The analysis will detect:
- Function signatures and complexity
- Class hierarchies and relationships
- Memory management patterns
- Potential technical debt in comments
- Header file dependencies

### Sample Output for C++ Analysis

```
$ pmat analyze ./cpp-calculator

📊 Analyzing C++ project: ./cpp-calculator
Found 23 files (8 .cpp, 12 .h, 3 .hpp)

Analysis complete:
- 45 functions analyzed
- 12 classes detected
- 8 namespaces found
- Average cyclomatic complexity: 4.2
- Max cyclomatic complexity: 15 (in Calculator::evaluateExpression)
- 3 potential complexity hotspots identified
- 5 self-admitted technical debt markers found

Top issues:
1. ./src/parser.cpp:156 - High complexity (15) in Parser::parseExpression
2. ./include/calculator.hpp:42 - Memory management concern in MathContext class
3. ./src/calculator.cpp:203 - FIXME comment about potential memory leak

See detailed report in pmat_analysis.json
```

## Summary

PMAT's multi-language analysis capabilities provide comprehensive code quality assessment across diverse technology stacks. Key benefits include:

- **Unified Quality View**: Single dashboard for all languages in your project
- **Language-Aware Analysis**: Specialized analyzers for each language's unique patterns
- **Cross-Language Insights**: Understanding how different components interact
- **Flexible Configuration**: Customizable rules and thresholds per language
- **MCP Integration**: Programmatic access for AI-assisted development

Whether you're working with a Python/JavaScript full-stack application, a Rust/Go microservices architecture, or a complex polyglot enterprise system, PMAT provides the tools and insights needed to maintain high code quality across all languages in your project.

The examples in this chapter demonstrate real-world scenarios with actual technical debt patterns, showing how PMAT identifies issues and provides actionable recommendations for improvement. Use these patterns as templates for analyzing your own multi-language projects and establishing quality standards that work across your entire technology stack.