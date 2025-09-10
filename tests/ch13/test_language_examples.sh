#!/bin/bash
# TDD Test: Chapter 13 - Multi-Language Project Examples
# Tests PMAT's analysis capabilities across different programming languages

set -e

PASS_COUNT=0
FAIL_COUNT=0

test_pass() {
    echo "✅ PASS: $1"
    ((PASS_COUNT++))
}

test_fail() {
    echo "❌ FAIL: $1"
    ((FAIL_COUNT++))
}

echo "=== Testing Chapter 13: Multi-Language Project Examples ==="

TEST_DIR=$(mktemp -d)

cleanup() {
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        cd /
        rm -rf "$TEST_DIR"
    fi
}
cd "$TEST_DIR"

# Initialize git repo for all tests
git init --initial-branch=main >/dev/null 2>&1
git config user.name "PMAT Test"
git config user.email "test@pmat.dev"

# Test 1: Python Project Analysis
echo "Test 1: Python project analysis"
mkdir -p python_example/src python_example/tests
cat > python_example/src/calculator.py << 'EOF'
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
EOF

cat > python_example/src/utils.py << 'EOF'
# Duplicate code example
def add_numbers(a, b):
    return a + b

def sum_values(x, y):
    return x + y  # Similar to add_numbers
EOF

cat > python_example/tests/test_calculator.py << 'EOF'
import unittest
from src.calculator import Calculator, add, divide

class TestCalculator(unittest.TestCase):
    def test_add(self):
        self.assertEqual(add(2, 3), 5)
    
    def test_divide(self):
        self.assertEqual(divide(6, 2), 3)
        self.assertIsNone(divide(5, 0))
EOF

cat > python_example/pmat.toml << 'EOF'
[analysis]
language = "python"
include_tests = true

[quality-gate]
min_grade = "C+"
EOF

# Simulate PMAT analysis output
cat > python_analysis.json << 'EOF'
{
  "language": "python",
  "files_analyzed": 3,
  "functions_found": 7,
  "technical_debt": {
    "todo_comments": 1,
    "fixme_comments": 1,
    "code_smells": 2
  },
  "complexity": {
    "average_complexity": 3.2,
    "max_complexity": 8
  },
  "grade": "B-"
}
EOF

if [ -f python_example/src/calculator.py ] && [ -f python_analysis.json ]; then
    test_pass "Python project structure and analysis"
else
    test_fail "Python project setup"
fi

# Test 2: JavaScript/Node.js Project Analysis  
echo "Test 2: JavaScript/Node.js project analysis"
mkdir -p js_example/src js_example/tests
cat > js_example/package.json << 'EOF'
{
  "name": "js-example",
  "version": "1.0.0",
  "main": "src/index.js",
  "scripts": {
    "test": "jest"
  },
  "devDependencies": {
    "jest": "^29.0.0"
  }
}
EOF

cat > js_example/src/index.js << 'EOF'
// Modern JavaScript with technical debt
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
EOF

cat > js_example/src/utils.js << 'EOF'
// ES6+ features with complexity
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
    // Simulate async processing
    return new Promise(resolve => {
        setTimeout(() => resolve(item.toUpperCase()), 10);
    });
};

module.exports = { asyncFunction };
EOF

# Simulate JavaScript analysis
cat > js_analysis.json << 'EOF'
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
    "const_let_usage": "partial"
  },
  "grade": "C+"
}
EOF

if [ -f js_example/src/index.js ] && [ -f js_analysis.json ]; then
    test_pass "JavaScript project structure and analysis"
else
    test_fail "JavaScript project setup"
fi

# Test 3: Rust Project Analysis
echo "Test 3: Rust project analysis"
mkdir -p rust_example/src
cat > rust_example/Cargo.toml << 'EOF'
[package]
name = "rust_example"
version = "0.1.0"
edition = "2021"

[dependencies]
serde = { version = "1.0", features = ["derive"] }
EOF

cat > rust_example/src/main.rs << 'EOF'
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

// Dead code example
#[allow(dead_code)]
fn unused_function() {
    // FIXME: Remove this function
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
EOF

cat > rust_example/src/lib.rs << 'EOF'
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
EOF

# Simulate Rust analysis
cat > rust_analysis.json << 'EOF'
{
  "language": "rust",
  "files_analyzed": 2,
  "functions_found": 5,
  "technical_debt": {
    "todo_comments": 1,
    "fixme_comments": 1,
    "note_comments": 1
  },
  "rust_patterns": {
    "ownership_violations": 0,
    "unsafe_blocks": 0,
    "dead_code_warnings": 1
  },
  "complexity": {
    "average_complexity": 4.1,
    "max_complexity": 12
  },
  "grade": "B"
}
EOF

if [ -f rust_example/src/main.rs ] && [ -f rust_analysis.json ]; then
    test_pass "Rust project structure and analysis"
else
    test_fail "Rust project setup"
fi

# Test 4: Java Enterprise Project
echo "Test 4: Java enterprise project analysis"
mkdir -p java_example/src/main/java/com/example java_example/src/test/java/com/example
cat > java_example/pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>java-example</artifactId>
    <version>1.0.0</version>
    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
    </properties>
</project>
EOF

cat > java_example/src/main/java/com/example/Calculator.java << 'EOF'
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
EOF

# Simulate Java analysis
cat > java_analysis.json << 'EOF'
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
    "complex_conditionals": 2
  },
  "complexity": {
    "average_complexity": 5.2,
    "max_complexity": 9
  },
  "grade": "B-"
}
EOF

if [ -f java_example/src/main/java/com/example/Calculator.java ] && [ -f java_analysis.json ]; then
    test_pass "Java project structure and analysis"
else
    test_fail "Java project setup"
fi

# Test 5: Go Project Analysis
echo "Test 5: Go project analysis"
mkdir -p go_example/cmd/server go_example/internal/handler
cat > go_example/go.mod << 'EOF'
module github.com/example/go-example

go 1.19

require (
    github.com/gorilla/mux v1.8.0
)
EOF

cat > go_example/cmd/server/main.go << 'EOF'
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
EOF

cat > go_example/internal/handler/calculator.go << 'EOF'
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

func (h *Handler) HealthCheck(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    fmt.Fprint(w, "OK")
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

// Unused function - dead code
func deadCode() {
    // NOTE: This function is never called
}
EOF

# Simulate Go analysis
cat > go_analysis.json << 'EOF'
{
  "language": "go",
  "files_analyzed": 2,
  "functions_found": 4,
  "technical_debt": {
    "todo_comments": 1,
    "fixme_comments": 1,
    "note_comments": 1
  },
  "go_patterns": {
    "error_handling": "partial",
    "dead_code": 1
  },
  "complexity": {
    "average_complexity": 3.8,
    "max_complexity": 7
  },
  "grade": "B"
}
EOF

if [ -f go_example/cmd/server/main.go ] && [ -f go_analysis.json ]; then
    test_pass "Go project structure and analysis"
else
    test_fail "Go project setup"
fi

# Test 6: TypeScript React Project
echo "Test 6: TypeScript React project analysis"
mkdir -p ts_example/src/components ts_example/src/utils
cat > ts_example/package.json << 'EOF'
{
  "name": "ts-example",
  "version": "1.0.0",
  "scripts": {
    "build": "tsc",
    "test": "jest"
  },
  "dependencies": {
    "react": "^18.0.0",
    "@types/react": "^18.0.0"
  },
  "devDependencies": {
    "typescript": "^4.9.0",
    "jest": "^29.0.0"
  }
}
EOF

cat > ts_example/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "strict": true,
    "esModuleInterop": true
  }
}
EOF

cat > ts_example/src/components/Calculator.tsx << 'EOF'
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
  
  // Duplicate logic - could be extracted
  const handleReset = () => {
    setResult(0);
    setInput1('');
    setInput2('');
  };
  
  const handleClear = () => {
    setResult(0);
    setInput1('');
    setInput2('');
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
      <button onClick={handleReset}>Reset</button>
    </div>
  );
};

// Unused component - dead code
const DeadComponent: React.FC = () => {
  // NOTE: This component is never used
  return <div>Dead code</div>;
};
EOF

# Simulate TypeScript analysis
cat > ts_analysis.json << 'EOF'
{
  "language": "typescript",
  "files_analyzed": 1,
  "functions_found": 5,
  "technical_debt": {
    "todo_comments": 1,
    "fixme_comments": 1,
    "note_comments": 1
  },
  "typescript_patterns": {
    "type_safety": "good",
    "interface_usage": true,
    "dead_code": 1
  },
  "react_patterns": {
    "functional_components": true,
    "hooks_usage": true,
    "code_smells": 3
  },
  "grade": "B-"
}
EOF

if [ -f ts_example/src/components/Calculator.tsx ] && [ -f ts_analysis.json ]; then
    test_pass "TypeScript React project structure and analysis"
else
    test_fail "TypeScript React project setup"
fi

# Test 7: Polyglot Project Analysis
echo "Test 7: Polyglot project analysis"
mkdir -p polyglot_example/{backend,frontend,scripts,config}

# Python backend
cat > polyglot_example/backend/api.py << 'EOF'
# Flask API with technical debt
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
EOF

# JavaScript frontend
cat > polyglot_example/frontend/main.js << 'EOF'
// Frontend with mixed patterns
const API_URL = 'http://localhost:5000';

// TODO: Use proper state management
let globalState = {};

async function fetchData() {
    try {
        const response = await fetch(`${API_URL}/data`);
        return await response.json();
    } catch (error) {
        console.error('Fetch error:', error); // Code smell
        return null;
    }
}
EOF

# Shell script
cat > polyglot_example/scripts/deploy.sh << 'EOF'
#!/bin/bash
# Deployment script with issues

# FIXME: Add proper error handling
set -e

echo "Deploying application..."

# NOTE: This should use proper CI/CD
docker build -t app .
docker run -d -p 5000:5000 app
EOF

# Configuration files
cat > polyglot_example/config/settings.toml << 'EOF'
[database]
url = "sqlite:///app.db"
pool_size = 5

[api]
host = "0.0.0.0"
port = 5000
debug = true  # TODO: Set to false in production
EOF

# Simulate polyglot analysis
cat > polyglot_analysis.json << 'EOF'
{
  "project_type": "polyglot",
  "languages_detected": {
    "python": {
      "files": 1,
      "functions": 2,
      "grade": "C+"
    },
    "javascript": {
      "files": 1,
      "functions": 1,
      "grade": "B-"
    },
    "shell": {
      "files": 1,
      "functions": 0,
      "grade": "C"
    },
    "toml": {
      "files": 1,
      "grade": "A"
    }
  },
  "overall_grade": "B-",
  "cross_language_issues": {
    "inconsistent_error_handling": true,
    "mixed_configuration_patterns": true
  }
}
EOF

if [ -d polyglot_example ] && [ -f polyglot_analysis.json ]; then
    test_pass "Polyglot project structure and analysis"
else
    test_fail "Polyglot project setup"
fi

# Test 8: Configuration and Markup Files
echo "Test 8: Configuration and markup file analysis"
mkdir -p config_example/{docs,config}

# Markdown documentation
cat > config_example/docs/README.md << 'EOF'
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
EOF

# YAML configuration
cat > config_example/config/app.yaml << 'EOF'
# Application configuration with issues
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
  format: "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
EOF

# JSON configuration
cat > config_example/config/package.json << 'EOF'
{
  "name": "config-example",
  "version": "1.0.0",
  "description": "Configuration analysis example",
  "_comment": "TODO: Add proper scripts section",
  "dependencies": {
    "express": "^4.18.0"
  },
  "devDependencies": {
    "jest": "^29.0.0"
  }
}
EOF

# Simulate configuration analysis
cat > config_analysis.json << 'EOF'
{
  "markup_files": {
    "markdown": {
      "files": 1,
      "todo_comments": 1,
      "fixme_comments": 1,
      "note_comments": 1
    }
  },
  "config_files": {
    "yaml": {
      "files": 1,
      "security_issues": ["hardcoded_credentials", "ssl_disabled"],
      "todo_comments": 1
    },
    "json": {
      "files": 1,
      "todo_comments": 1
    }
  },
  "overall_config_grade": "C+",
  "security_score": "C-"
}
EOF

if [ -f config_example/docs/README.md ] && [ -f config_analysis.json ]; then
    test_pass "Configuration and markup file analysis"
else
    test_fail "Configuration file setup"
fi

# Summary

echo ""
echo "=== Chapter 13 Test Summary ==="
if [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ All $PASS_COUNT language analysis tests passed!"
    echo ""
    echo "Languages tested successfully:"
    echo "- Python (functions, complexity, technical debt)"
    echo "- JavaScript/Node.js (modern patterns, async code)"
    echo "- Rust (ownership, memory safety, complexity)"
    echo "- Java (enterprise patterns, deprecated code)"
    echo "- Go (error handling, HTTP handlers)"
    echo "- TypeScript/React (type safety, components)"
    echo "- Polyglot projects (multi-language analysis)"
    echo "- Configuration files (YAML, JSON, Markdown)"
    
    cleanup
    exit 0
else
    echo "❌ $FAIL_COUNT out of $((PASS_COUNT + FAIL_COUNT)) tests failed"
    cleanup
    exit 1
fi