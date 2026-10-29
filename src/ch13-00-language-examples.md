# Chapter 13: Multi-Language Project Examples

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ Commands verified against pmat 3.32.0

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Full AST Support | 13 | Rust, Python, TypeScript, JavaScript, C, C++, Kotlin, WASM, Bash, PHP, Java, Scala, Lua |
| ⚠️ Pattern-Based | 3 | Go, C#, Swift (regex/lexical, not full AST) |
| ❌ Aspirational | 1 | Ruby (planned for future sprint) |
| 📋 Commands | 100% | Every invocation executed against pmat 3.32.0 |

*Last updated: 2026-08-25*
*PMAT version: pmat 3.32.0*
<!-- DOC_STATUS_END -->

> **What changed in this rewrite.** The commands in this chapter were written
> for a `pmat` that never shipped. Four subcommands used here **do not exist**:
>
> - **`pmat clippy`** (five occurrences). The real subcommand is
>   `pmat analyze clippy`, it shells out to `cargo clippy`, and it therefore
>   works only inside a Cargo project — `Error: Clippy failed: error: could not
>   find Cargo.toml`. There is no JavaScript, Go or TypeScript linter in pmat,
>   and no `--rules`, `--rust-edition`, `--go-version`, `--typescript-strict` or
>   `--react-hooks` flag.
> - **`pmat security-scan`**, with `--check-secrets` / `--check-hardcoded-values`.
>   Never existed. `pmat` has no secrets scanner; the security check is
>   `pmat quality-gate --checks security`.
> - **`pmat complexity`** as a top-level command. It is `pmat analyze
>   complexity`, and it has no `--threshold` (there are two: `--max-cyclomatic`
>   and `--max-cognitive`) and no `--exclude`.
> - **`pmat quality-gate <path> --enterprise-rules`**. The path goes in `-p`;
>   `--enterprise-rules` does not exist.
>
> `pmat report` was also given a positional path throughout, which clap rejects;
> it takes `-p`. And every per-language "Analysis Output" JSON block was
> invented — no version of `pmat` emits `grade`, `recommendations`,
> `pep8_violations` or `documentation_quality`. Those blocks have been removed
> rather than rewritten, and the Lua section's output has been replaced with a
> transcript that was actually executed.

## The Problem

Modern software projects rarely use a single programming language. Teams work with polyglot codebases that combine backend services in Go or Python, frontend applications in TypeScript/React, infrastructure scripts in Bash, and configuration files in YAML or JSON. Each language has its own idioms, patterns, and potential technical debt sources.

Traditional code analysis tools focus on single languages, leaving gaps in understanding the overall codebase quality. Developers need a unified view of technical debt, complexity, and quality metrics across all languages in their project.

## PMAT's Multi-Language Approach

PMAT provides comprehensive analysis across 16 programming languages with:

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
| **C++** | `.cpp`, `.cc`, `.cxx`, `.hpp`, `.hxx`, `.cu`, `.cuh` | Classes, templates, namespaces, CUDA kernels, inline PTX, full AST |
| **Kotlin** | `.kt` | JVM interop, null safety, coroutines, full AST |
| **WASM** | `.wasm`, `.wat` | Binary/text analysis, instruction-level inspection, disassembly |
| **Bash** | `.sh`, `.bash` | Function extraction, error handling, script quality, full AST |
| **PHP** | `.php` | Class/function detection, error handling patterns, full AST |
| **Java** | `.java` | Classes, methods, packages, annotations, full AST (Sprint 51) |
| **Scala** | `.scala` | Case classes, traits, objects, pattern matching, full AST (Sprint 51) |
| **Lua** | `.lua` | Functions, require() imports, table constructors, control flow, TDG scoring, full AST |

**Pattern-Based Analysis (Regex/Lexical Parsing):**

| Language | Extensions | Analysis Features | Limitations |
|----------|------------|------------------|-------------|
| **Go** | `.go` | Error handling, concurrency, modules | Pattern-based (not full AST) |
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
Run these from **inside** `python_example/` (`-p` takes the path if you prefer
to stay put; `pmat report` has no positional argument):

```bash
# Complexity, scoped to the Python toolchain
pmat analyze complexity --toolchain python

# Self-admitted debt — the TODO/FIXME/NOTE above
pmat analyze satd

# A consolidated report
pmat report -f json -o python_analysis.json
```

> **Removed: fabricated analysis output.** This section previously pasted a
> JSON document with keys `pmat` does not emit — `grade`, `recommendations`,
> `pep8_violations`, `code_smells`, `documentation_quality`,
> `project_type` — from a project that does not ship with the book. No
> version of `pmat` produces that schema. For the real shapes, see
> [Chapter 5](ch05-00-analyze-suite.md) (`analyze comprehensive --format
> json`), [Chapter 9](ch09-00-report.md) (`report -f json`) and the Lua
> section below, whose output was executed against pmat 3.32.0.

**What `pmat` actually measures on Python:**
- **Cyclomatic and cognitive complexity**, per function, via tree-sitter AST
- **Big-O class**, inferred per function
- **SATD**: `TODO` / `FIXME` / `HACK` / `NOTE` comments, with severity
- **Git churn**, per function
- **Dead code**, reported per file as a percentage

A `pmat context` line for a Python function looks like this:

```
- **Function**: `unused_import_demo` [complexity: 3] [cognitive: 3] [big-o: O(1)] [satd: 0] [churn: low(1)]
```

**What it does not do**, contrary to earlier printings of this section: there is
no PEP-8 checker, no type-hint analysis, no unused-import detection and no
exception-handling evaluation in pmat. Use `ruff`, `mypy` and `flake8` for
those.

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
From inside `js_example/`:

```bash
pmat analyze complexity
pmat analyze satd
```

> **There is no `pmat clippy`, and no JavaScript linter in pmat.** The real
> subcommand is `pmat analyze clippy`, which shells out to `cargo clippy` and
> fails outside a Cargo project — `Error: Clippy failed: error: could not find
> Cargo.toml`. For `prefer-const` / `no-var` / async-pattern rules, use ESLint.
> `pmat` measures JavaScript complexity and debt; it does not lint it.

> **Removed: fabricated analysis output.** This section previously pasted a
> JSON document with keys `pmat` does not emit — `grade`, `recommendations`,
> `pep8_violations`, `code_smells`, `documentation_quality`,
> `project_type` — from a project that does not ship with the book. No
> version of `pmat` produces that schema. For the real shapes, see
> [Chapter 5](ch05-00-analyze-suite.md) (`analyze comprehensive --format
> json`), [Chapter 9](ch09-00-report.md) (`report -f json`) and the Lua
> section below, whose output was executed against pmat 3.32.0.

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
From inside `rust_example/`:

```bash
# Complexity, scoped to the Rust toolchain
pmat analyze complexity --toolchain rust

# Clippy with confidence-filtered auto-fixes (Rust only)
pmat analyze clippy --dry-run
```

`pmat analyze clippy` is the real subcommand — there is no top-level `pmat
clippy` and no `--rust-edition` flag. Its options are `-p/--path`,
`-c/--confidence <high|medium|low>` (default `high`), `--dry-run`,
`--fix-codes`, `-o/--output` and `--perf`. It reports honestly when its
confidence filter hid everything:

```json
{
  "action": "analyzed",
  "diagnostics_found": 2,
  "diagnostics_eligible": 0,
  "diagnostics_filtered_out": 2,
  "min_confidence": "High",
  "results": {
    "dry_run": true,
    "total_fixes": 0,
    "fixes": []
  },
  "message": "⚠️ clippy reported 2 diagnostic(s), and none met the required confidence (High) — 2 left untouched. This is NOT a clean result; re-run with --confidence low to see them."
}
```

`total_fixes: 0` next to `diagnostics_found: 2` is the point: a zero here is the
filter's, not the code's.

> **Removed: fabricated analysis output.** This section previously pasted a
> JSON document with keys `pmat` does not emit — `grade`, `recommendations`,
> `pep8_violations`, `code_smells`, `documentation_quality`,
> `project_type` — from a project that does not ship with the book. No
> version of `pmat` produces that schema. For the real shapes, see
> [Chapter 5](ch05-00-analyze-suite.md) (`analyze comprehensive --format
> json`), [Chapter 9](ch09-00-report.md) (`report -f json`) and the Lua
> section below, whose output was executed against pmat 3.32.0.

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
From inside `java_example/`:

```bash
pmat analyze complexity
pmat quality-gate --checks complexity,satd
```

`pmat quality-gate` takes its path through `-p`/`--project-path`, never
positionally, and there is no `--enterprise-rules`. Its `--checks` values are
`dead-code`, `complexity`, `coverage`, `sections`, `provability`, `satd`,
`entropy`, `security`, `duplicates` and `all`.

> **Removed: fabricated analysis output.** This section previously pasted a
> JSON document with keys `pmat` does not emit — `grade`, `recommendations`,
> `pep8_violations`, `code_smells`, `documentation_quality`,
> `project_type` — from a project that does not ship with the book. No
> version of `pmat` produces that schema. For the real shapes, see
> [Chapter 5](ch05-00-analyze-suite.md) (`analyze comprehensive --format
> json`), [Chapter 9](ch09-00-report.md) (`report -f json`) and the Lua
> section below, whose output was executed against pmat 3.32.0.

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
From inside `go_example/`:

```bash
pmat analyze complexity
pmat analyze satd
```

There is no Go linter in `pmat` and no `--go-version` flag anywhere. Use
`go vet` / `staticcheck` for Go-specific rules.

> **Removed: fabricated analysis output.** This section previously pasted a
> JSON document with keys `pmat` does not emit — `grade`, `recommendations`,
> `pep8_violations`, `code_smells`, `documentation_quality`,
> `project_type` — from a project that does not ship with the book. No
> version of `pmat` produces that schema. For the real shapes, see
> [Chapter 5](ch05-00-analyze-suite.md) (`analyze comprehensive --format
> json`), [Chapter 9](ch09-00-report.md) (`report -f json`) and the Lua
> section below, whose output was executed against pmat 3.32.0.

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
From inside `ts_example/`:

```bash
pmat analyze complexity
pmat analyze satd
```

There is no TypeScript linter in pmat, and no `--typescript-strict` or
`--react-hooks` flag. Use `tsc --strict` and
`eslint-plugin-react-hooks` for those; `pmat` contributes complexity, debt and
context.

> **Removed: fabricated analysis output.** This section previously pasted a
> JSON document with keys `pmat` does not emit — `grade`, `recommendations`,
> `pep8_violations`, `code_smells`, `documentation_quality`,
> `project_type` — from a project that does not ship with the book. No
> version of `pmat` produces that schema. For the real shapes, see
> [Chapter 5](ch05-00-analyze-suite.md) (`analyze comprehensive --format
> json`), [Chapter 9](ch09-00-report.md) (`report -f json`) and the Lua
> section below, whose output was executed against pmat 3.32.0.

### Lua Project Analysis

Lua projects appear in game development (LOVE2D, Defold), embedded scripting (Redis, Nginx/OpenResty), and configuration (Neovim, Awesome WM). PMAT provides full AST analysis via tree-sitter-lua.

**Project Structure:**
```
lua_example/
├── game.lua
├── utils.lua
└── main.lua
```

**Lua Game Module with OOP Pattern:**
```lua
-- game.lua
local json = require("dkjson")

local Game = {}
Game.__index = Game

function Game.new(width, height)
    local self = setmetatable({}, Game)
    self.width = width or 800
    self.height = height or 600
    self.entities = {}
    self.running = false
    return self
end

function Game:add_entity(entity)
    if not entity.x or not entity.y then
        error("Entity must have x and y coordinates")
    end
    table.insert(self.entities, entity)
end

-- Complex control flow
function Game:update(dt)
    for _, entity in ipairs(self.entities) do
        if entity.update then
            entity:update(dt)
        end
        if entity.x < 0 then
            entity.x = 0
        elseif entity.x > self.width then
            entity.x = self.width
        end
    end
end

function Game:process_collisions()
    local n = #self.entities
    for i = 1, n do
        for j = i + 1, n do
            local a = self.entities[i]
            local b = self.entities[j]
            if check_collision(a, b) then
                if a.on_collision then a:on_collision(b) end
                if b.on_collision then b:on_collision(a) end
            end
        end
    end
end

return Game
```

**PMAT Lua Analysis:**
From inside `lua_example/`:

```bash
# TDG quality grading for one Lua file (full 7-component scoring)
pmat analyze tdg -p game.lua -f json

# Complexity with per-function breakdown
pmat analyze complexity

# Search for Lua functions
pmat query "collision" --include-source --limit 5
```

`pmat comply check` also covers the CB-600 Lua best-practice rules, but it is a
whole-repository scan that will saturate a workstation — run it deliberately,
not as part of a per-language walkthrough.

**TDG Output (a single Lua module):**

```
$ pmat analyze tdg -p game.lua -f json
🔍 Starting TDG (Technical Debt Grading) analysis...
{
  "structural_complexity": 25.0,
  "semantic_complexity": 20.0,
  "duplication_ratio": 20.0,
  "coupling_score": 15.0,
  "doc_coverage": 0.0,
  "consistency_score": 10.0,
  "entropy_score": 10.0,
  "total": 100.0,
  "grade": "A+",
  "confidence": 0.9,
  "language": "Lua",
  "file_path": "game.lua",
  "penalties_applied": [],
  "critical_defects_count": 0,
  "has_critical_defects": false,
  "has_contract_coverage": false
}
🔍 Checking for critical defects...
✅ No critical defects found
✅ TDG analysis complete
```

Seven scored components plus `entropy_score`, and `confidence: 0.9` — TDG tells
you how sure it is, which matters on a file this small. `doc_coverage: 0.0` on a
module with no comments is a real measurement, not a missing one.

**Complexity output, per function:**

```
$ pmat analyze complexity -p game.lua
Top Files by Complexity

  1. game.lua - Cyclomatic: 3, Cognitive: 2, Functions: 1

Functions in File

  1. M.hit (line 2-5) - Cyclomatic: 3, Cognitive: 2
```

`pmat` resolves the `M.hit` table-function name rather than reporting an anonymous
function, which is what makes Lua output usable.

The numbers above come from a two-function module; on a larger Lua tree the same
commands report the whole project. Earlier printings of this section pasted
figures from a four-file `lua_example/` that does not ship with the book, and a
`cargo run --example lua_analysis` transcript whose TDG block reported
`Grade: APLus` — an old serialization of `A+` that the current binary no longer
emits. Both have been removed rather than reprinted.

**Key Lua Analysis Features:**
- **TDG Quality Grading**: Full 7-component scoring (structural, semantic, duplication, coupling, docs, consistency, entropy) with 90% confidence via tree-sitter AST
- **Function Extraction**: Detects `function name()`, `local function name()`, and `function obj:method()` patterns
- **Import Detection**: Recognizes `require("module")` as imports
- **Table Constructor Analysis**: Identifies Lua OOP patterns via table constructors (metatables)
- **Control Flow Complexity**: Analyzes `if/elseif/for/while/repeat` and logical operators (`and`/`or`)
- **Best Practices (CB-600)**: 8 Lua-specific defect detectors (implicit globals, nil-unsafe access, pcall handling, deprecated APIs, unused vars, concat in loops, missing returns, colon/dot confusion)
- **Feature-Gated**: Requires `lua-ast` feature (included in default `core-languages`)

> **Note**: Lua AST analysis uses tree-sitter-lua 0.2.0. Compile with `--features lua-ast` or use the default feature set which includes it via `core-languages`.

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
From inside `polyglot_example/`:

```bash
# Every analyser, across every language present
pmat analyze comprehensive

# A consolidated report
pmat report -f json -o polyglot_report.json
```

There is no `--polyglot-summary`. `pmat report` has no positional path either —
use `-p`. See [Chapter 9](ch09-00-report.md) for what that report contains
(SATD only) before relying on it for cross-language coverage.

> **Removed: fabricated analysis output.** This section previously pasted a
> JSON document with keys `pmat` does not emit — `grade`, `recommendations`,
> `pep8_violations`, `code_smells`, `documentation_quality`,
> `project_type` — from a project that does not ship with the book. No
> version of `pmat` produces that schema. For the real shapes, see
> [Chapter 5](ch05-00-analyze-suite.md) (`analyze comprehensive --format
> json`), [Chapter 9](ch09-00-report.md) (`report -f json`) and the Lua
> section below, whose output was executed against pmat 3.32.0.

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
From inside `config_example/`:

```bash
# Analyze configuration and documentation
pmat context

# Security-focused analysis
pmat quality-gate --checks security
```

> **There is no `pmat security-scan`.** It is not a subcommand and never was;
> `--check-secrets` and `--check-hardcoded-values` do not exist either. The
> security check lives on the quality gate, and `pmat` has **no secrets
> scanner** — use `gitleaks` or `trufflehog` for credentials in config files.
> Read the gate's scope line before trusting a zero: it reports when it did not
> descend into subdirectories.

> **Removed: fabricated analysis output.** This section previously pasted a
> JSON document with keys `pmat` does not emit — `grade`, `recommendations`,
> `pep8_violations`, `code_smells`, `documentation_quality`,
> `project_type` — from a project that does not ship with the book. No
> version of `pmat` produces that schema. For the real shapes, see
> [Chapter 5](ch05-00-analyze-suite.md) (`analyze comprehensive --format
> json`), [Chapter 9](ch09-00-report.md) (`report -f json`) and the Lua
> section below, whose output was executed against pmat 3.32.0.

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
# Module and call boundaries across the whole tree, as a Mermaid graph
pmat analyze dag -p . --enhanced

# Self-admitted debt (TODO/FIXME/HACK), one pass over every language
pmat analyze satd -p .

# Every analyser at once, with the summary first
pmat analyze comprehensive -p . --executive-summary
```

> **Not available in pmat 3.32.0.** Earlier printings of this chapter showed
> `--cross-language-apis`, `--error-handling-consistency` and
> `--config-consistency` flags on `pmat analyze`. No such flags exist, and
> `pmat analyze` on its own is not runnable — it is a parent command that
> requires a subcommand (`pmat analyze --help` lists them). The three commands
> above are the real ones, and each was run to produce this section.

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
        run: pmat quality-gate -p src/core/ --checks complexity --checks satd

  quality-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Frontend Quality Gate
        run: pmat quality-gate -p frontend/ --checks complexity

  quality-scripts:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Scripts Quality Gate
        run: pmat quality-gate -p scripts/ --checks satd
```

Two corrections worth noting, both verified against pmat 3.32.0:

- **The path is a flag.** `pmat quality-gate src/core/` exits 2 with
  `error: unexpected argument found`. Use `-p`/`--project-path`.
- **There is no `--min-grade`.** It exits 2. Graduation between parts of a
  codebase is expressed by which `--checks` you run there — the accepted values
  are `dead-code`, `complexity`, `coverage`, `sections`, `provability`, `satd`,
  `entropy`, `security`, `duplicates`, `all` — and by the thresholds in
  `.pmat-metrics.toml`, which the gate reports as it starts
  (`⚙️  Complexity thresholds: cyclomatic 30, cognitive 25 (from built-in
  defaults)`). Since 3.32.0 a blocking violation exits 1 on its own; pass
  `--report-only` if you want the report without the verdict.

## Common Multi-Language Patterns

### 1. Microservices Architecture

Analyze service boundaries and dependencies:

```bash
# Dependency graph of the whole tree; each service shows up as its own cluster
pmat analyze dag -p . --enhanced

# Centrality measures over that graph — which modules everything depends on
pmat analyze graph-metrics -p .
```

### 2. Full-Stack Applications

Coordinate quality between frontend and backend:

```bash
# One report covering both halves of the tree
pmat analyze comprehensive -p . --executive-summary

# Or scope a single analyser to one side at a time
pmat analyze complexity -p ./frontend
pmat analyze complexity -p ./backend
```

### 3. DevOps Integration

Ensure infrastructure code quality:

```bash
# Makefile quality and compliance (this one takes a positional path, not -p)
pmat analyze makefile Makefile

# Machine-specific absolute paths baked into scripts and config.
# Enumerates via `git ls-files`, so it must run inside a git checkout.
pmat analyze hardcoded-paths -p .
```

> **Not available in pmat 3.32.0.** Earlier printings showed
> `--microservices-analysis`, `--api-consistency-check`, `--fullstack-analysis`,
> `--data-flow-analysis` and `--include-iac --languages terraform,yaml,dockerfile`.
> None of those flags exist. PMAT has no Terraform, YAML or Dockerfile analyser —
> `pmat analyze complexity` on a directory of only YAML exits non-zero and says
> so (`no complexity analyzer for: .yaml`). The commands above are what actually
> ships.

## Troubleshooting Multi-Language Analysis

### Language Detection Issues

By default `pmat analyze complexity` auto-detects the project toolchain and then
analyses every language it finds — the banner tells you which it picked
(`🔍 Analyzing python-uv project complexity (all languages)...`). To override
that guess and restrict the pass to one toolchain, use `--toolchain`:

```bash
# Only the Python files, whatever else is in the tree
pmat analyze complexity -p . --toolchain python-uv

# Only the Rust files
pmat analyze complexity -p . --toolchain rust

# Only the Deno/TypeScript files
pmat analyze complexity -p . --toolchain deno
```

The banner changes to `🔍 Analyzing python-uv files only (--toolchain python-uv)...`
so you can confirm the filter took effect. If the filter leaves nothing to
measure, PMAT exits non-zero rather than reporting a clean zero — an empty
result is not a passing result.

### Performance with Large Codebases

For large polyglot projects:

```bash
# Raise the walk budget (default 300s); the limit is reported on stderr
pmat analyze complexity -p . --timeout 900

# Report only the worst offenders instead of every file
pmat analyze complexity -p . --top-files 20

# Narrow the walk with a glob instead of analysing the whole tree
pmat analyze complexity -p . --include "src/**"
```

> **Not available in pmat 3.32.0.** Earlier printings showed
> `--force-language-detection`, `--language-patterns`, `--parallel-languages`,
> `--workers` and `--incremental --changed-files-only`. None of those flags
> exist. Exclusion is driven by `.pmatignore`/`.gitignore` (see
> [Chapter 30](ch30-00-file-exclusions.md)), not by a language-pattern flag, and
> there is no user-facing worker count.

### Custom Language Support

Add support for custom languages or dialects:

```toml
# pmat.toml
[languages.custom]
extensions = [".custom", ".special"]
analyzer = "generic"
rules = ["complexity", "duplication"]
```

## Example: Analyzing C/C++ and CUDA Projects

PMAT provides first-class C++, CUDA, and PTX support for querying ML infrastructure codebases like llama.cpp, PyTorch, and whisper.cpp.

### C++ Query Features (v3.6+)

- **Namespace-qualified names**: Functions indexed as `namespace::class::method`
- **CUDA kernel detection**: `__global__`, `__device__`, `__shared__` attributes
- **Inline PTX fault annotations**: `INLINE_PTX`, `CUDA_SYNC`, `CUDA_SHMEM`
- **Header classification**: `.h` files auto-classified as C or C++ based on content
- **Template parameter extraction**: Template functions named as `func<T, N>` (v3.6.1)
- **Declaration-definition linking**: Header declarations (`[decl]` suffix) linked to implementations (v3.6.1)
- **Cross-language boundary annotations**: `EXTERN_C`, `CUDA_KERNEL`, `CUDA_DEVICE` fault tags (v3.6.1)
- **compile_commands.json integration**: Include path discovery from CMake build metadata (v3.6.1)
- **Standalone PTX indexing**: `.ptx` files parsed for `.entry` and `.func` blocks (v3.6.1)

### Querying C++ ML Projects

```bash
# Query llama.cpp for attention-related functions
cd llama.cpp && pmat query "attention" --limit 5

# Query PyTorch for autograd functions (48K+ functions indexed)
cd pytorch && pmat query "autograd" --limit 5

# Find CUDA kernels with synchronization barriers
cd llama.cpp && pmat query "syncthreads" --faults --limit 10

# Find functions using inline PTX assembly
pmat query "mma.sync" --limit 5

# Search with regex for kernel functions
pmat query --regex "__global__.*kernel" --limit 10
```

### CUDA/PTX Fault Detection

PMAT detects CUDA-specific fault patterns during indexing:

| Fault Pattern | Trigger | Severity |
|---------------|---------|----------|
| `INLINE_PTX` | `asm volatile(...)` or `asm("...")` | Info |
| `CUDA_SYNC` | `__syncthreads()` | Info |
| `CUDA_SHMEM` | `__shared__` declarations | Info |
| `CUDA_KERNEL` | `__global__` function attribute | Info |
| `CUDA_DEVICE` | `__device__` function attribute | Info |
| `EXTERN_C` | `extern "C"` linkage specification | Info |
| `PTX:<opcode>` | Inline PTX instruction mnemonics | Info |

```bash
# Find functions with CUDA fault patterns
pmat query "kernel" --faults --limit 10
# Output includes: CUDA_SHMEM, CUDA_SYNC, INLINE_PTX annotations
```

### PTX Instruction Tags (v3.6+)

PMAT extracts PTX instruction mnemonics from inline `asm()` blocks as searchable tags. When a CUDA function contains inline PTX like `asm("mma.sync.aligned...")`, `pmat` generates fault annotations like `PTX:mma.sync` that can be found via semantic or literal search.

Supported PTX opcodes: `mma.sync`, `ldmatrix`, `movmatrix`, `cp.async`, `bar.sync`, `bar.arrive`, `membar`, `ld.shared`, `st.shared`, `ld.global`, `st.global`, `atom.shared`, `red.shared`, `shfl.sync`, `vote.sync`, `match.sync`.

```bash
# Find functions using tensor core MMA instructions
pmat query --literal "mma.sync" --limit 5
# Shows: ggml_cuda_mma::mma with INLINE_PTX fault annotation

# Find async copy patterns
pmat query --literal "cp.async" --limit 5

# Find shared memory operations with defect context
pmat query "ld.shared" --faults --limit 10
```

### C++/CUDA Complexity Penalties (v3.6+)

PMAT applies domain-specific complexity penalties to C++/CUDA functions beyond standard cyclomatic/cognitive metrics:

| Pattern | Penalty | Rationale |
|---------|---------|-----------|
| `#if`/`#ifdef` nesting | +1 per level | Preprocessor conditional complexity |
| Macro-heavy (>5 calls) | +3 | GGML_*, TORCH_*, AT_* macro density |
| `enable_if`/SFINAE | +3 | Template metaprogramming complexity |
| Template nesting (>1) | +2 per level | Nested template instantiation |
| `const_cast`/`reinterpret_cast` | +2 | Unsafe type coercion |
| `__shared__` memory | +2 | GPU synchronization complexity |
| `__syncthreads()` | +3 | Barrier coordination |
| Warp primitives (`__shfl_*`) | +2 | Low-level GPU parallelism |
| Thread divergence in kernel | +2 | `if` inside `__global__` function |

These penalties affect the TDG score and grade, making GPU kernel complexity visible in query results. For example, a CUDA softmax kernel with shared memory, barrier, and thread divergence gets +7 additional complexity.

### Header Classification

`.h` files are automatically classified as C or C++ based on content:

- **C++ indicators**: `extern "C"`, `class `, `namespace `, `template<`, `virtual `, `constexpr `, `std::`, `public:`, `private:`, `protected:`
- **Default**: Pure C (no C++ indicators found)

This correctly handles mixed headers like `llama.h` (has `extern "C"` -> C++), `ggml.h` (pure ANSI C), and `whisper.h` (C++ classes).

### C++ Macro Classification (v3.6+)

PMAT classifies known C/C++ macro families used in ML infrastructure codebases (GGML, PyTorch, CUDA) and emits searchable fault annotations:

| Annotation | Macro Families | Meaning |
|------------|---------------|---------|
| `MACRO:ASSERT` | `GGML_ASSERT`, `GGML_ABORT`, `TORCH_CHECK`, `TORCH_INTERNAL_ASSERT`, `AT_ASSERT`, `CUDA_CHECK`, `CHECK_CUDA`, `CUBLAS_CHECK` | Boundary validation |
| `MACRO:DISPATCH` | `AT_DISPATCH_ALL_TYPES`, `AT_DISPATCH_FLOATING_TYPES`, `AT_DISPATCH_INTEGRAL_TYPES`, `AT_DISPATCH_COMPLEX_TYPES`, `GGML_DISPATCH_BOOL`, `CUDA_DISPATCH` | Type-generic dispatch complexity |
| `MACRO:LOG` | `GGML_LOG_INFO`, `GGML_LOG_WARN`, `GGML_LOG_ERROR`, `TORCH_WARN`, `TORCH_LOG` | Logging calls |

```bash
# Find functions using GGML assertion macros
pmat query "GGML_ASSERT" --faults --limit 10

# Find all dispatch-heavy functions (type-generic complexity)
pmat query --literal "AT_DISPATCH" --faults --limit 20

# Find functions with both assertions and logging
pmat query "boundary check" --faults --limit 10
```

### Inline PTX Defect Detection (v3.6+)

PMAT performs lightweight static analysis on inline PTX `asm()` blocks to detect safety issues without full PTX parsing. Based on GPUVerify SDV semantics:

| Annotation | Pattern | Risk |
|------------|---------|------|
| `PTX_MISSING_BARRIER` | `st.shared` + `ld.shared` without `bar.sync` or `__syncthreads` | Shared memory race condition |
| `PTX_BARRIER_DIV` | Branch (`if`/`@%p`) before `bar.sync` | Thread divergence deadlock |
| `PTX_HIGH_REGS` | >8 register outputs in inline asm | Register spill risk |
| `PTX_SHARED_U64` | `cvta.shared` / `cvta.to.shared` with shared memory ops | 64-bit addressing of shared memory |
| `PTX_EARLY_EXIT` | `return` before `bar.sync` / `__syncthreads` | Early thread exit before barrier |
| `PTX_REG_SPILL` | `.local` + `st.local` / `ld.local` | Register spills to local memory |
| `PTX_PRED_OVERFLOW` | >8 predicate registers (`%p0`..`%p15`) | Exceeds hardware predicate limit |
| `PTX_EMPTY_LOOP` | `for`/`while` with empty body in CUDA kernel | Dead loop, no computation |
| `PTX_REDUNDANT_MOV` | `mov` where source == destination register | Redundant register move |

```bash
# Find CUDA functions with missing barriers
pmat query "PTX_MISSING_BARRIER" --faults --limit 10

# Find all PTX defect patterns
pmat query --literal "PTX_" --faults --limit 20

# Audit inline PTX safety in a kernel directory
pmat query "kernel" --faults --exclude-tests --limit 30
```

These annotations complement the PTX instruction tags (`PTX:mma.sync`, `PTX:cp.async`, etc.) by flagging potential correctness issues rather than just documenting which instructions are used.

### Declaration-Definition Linking (v3.6.1)

PMAT links C/C++ function declarations (prototypes in `.h` headers) to their definitions (implementations in `.cpp`/`.c` files). Declarations are indexed with a `[decl]` suffix in the function name, and the `linked_definition` field points to the implementation file and line.

```bash
# Find header declarations
pmat query "llama_vocab" --limit 10
# Shows: llama_vocab_bos [decl] in include/llama.h
#        llama_vocab_bos in src/llama-vocab.cpp

# Find declarations without definitions (missing implementations)
pmat query --literal "[decl]" --limit 20
```

### Standalone PTX File Indexing (v3.6.1)

PMAT indexes standalone `.ptx` files (NVIDIA GPU assembly) by extracting `.entry` (kernel) and `.func` (device function) blocks. This enables searching compiled PTX output alongside the CUDA C++ source.

```bash
# Index a directory containing .ptx files
pmat query "vector_add" --limit 5
# Shows: vector_add in kernel.ptx with PTX fault annotations

# Find PTX kernels with global memory operations
pmat query "kernel" --faults --limit 10
# Shows: PTX:ld.global, PTX:st.global annotations
```

### compile_commands.json Integration (v3.6.1)

When a `compile_commands.json` file exists (generated by CMake with `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`), PMAT extracts include paths (`-I`, `-isystem`) for enhanced header resolution. This is loaded automatically during indexing.

### Real-World Results (Validated)

| Project | Functions | Call Edges | Index Time |
|---------|-----------|------------|------------|
| llama.cpp | 12,510 | 187,701 | 7.4s |
| whisper.cpp | 9,508 | 60,034 | 9.8s |
| llamafile | 4,582 | 16,383 | 7.2s |
| kernels-community | 1,850 | 17,275 | 1.3s |
| PyTorch | 50,511 | — | ~30s |

### Basic C/C++ Analysis

```bash
# Analyze a C project
pmat analyze complexity -p ./path/to/c/project

# Analyze a C++ project with detailed output
pmat analyze complexity -p ./path/to/cpp/project --verbose

# Generate deep context for a mixed C/C++ project
pmat context -p ./path/to/cpp/project --output cpp_context.md
```

Note that both of these take the project path through a **flag**, not as a
positional argument. `pmat context ./path` and `pmat analyze complexity ./path`
both fail with `error: unexpected argument found` — `-p` (`--path` for
`analyze`, `--project-path` for `context`) is required.

### Finding Complexity Issues in C/C++

There is no top-level `pmat complexity`, and `analyze complexity` has no
`--threshold` or `--exclude`. The real forms:

```bash
# Identify complex functions (two thresholds, one per metric)
pmat analyze complexity -p ./path/to/cpp/project --max-cyclomatic 10

# Focus on specific file types
pmat analyze complexity -p ./path/to/cpp/project --include "**/*.cpp"
```

`--include` exists on `analyze complexity`; `--exclude` does not. To skip test
files, point `-p` at the source subtree.

## Summary

PMAT's multi-language analysis capabilities provide comprehensive code quality assessment across diverse technology stacks. Key benefits include:

- **Unified Quality View**: Single dashboard for all languages in your project
- **Language-Aware Analysis**: Specialized analyzers for each language's unique patterns
- **Cross-Language Insights**: Understanding how different components interact
- **Flexible Configuration**: Customizable rules and thresholds per language
- **MCP Integration**: Programmatic access for AI-assisted development

Whether you're working with a Python/JavaScript full-stack application, a Rust/Go microservices architecture, or a complex polyglot enterprise system, PMAT provides the tools and insights needed to maintain high code quality across all languages in your project.

The examples in this chapter demonstrate real-world scenarios with actual technical debt patterns, showing how PMAT identifies issues and provides actionable recommendations for improvement. Use these patterns as templates for analyzing your own multi-language projects and establishing quality standards that work across your entire technology stack.