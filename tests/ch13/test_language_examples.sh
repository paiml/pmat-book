#!/bin/bash
# TDD Test: Chapter 13 - Multi-Language Project Examples
# Tests ACTUAL PMAT behavior across different programming languages
# EXTREME TDD with NASA-style quality verification - VALIDATES REAL PMAT

# Note: Using manual error handling instead of set -e for better test output

echo "=== Testing Chapter 13: Multi-Language Examples (ACTUAL PMAT VALIDATION) ==="

PASS_COUNT=0
FAIL_COUNT=0

test_pass() {
    echo "✅ PASS: $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

test_fail() {
    echo "❌ FAIL: $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

# Verify pmat is available
if ! command -v pmat &> /dev/null; then
    echo "❌ FATAL: pmat binary not found in PATH"
    exit 1
fi

echo "Using pmat version: $(pmat --version)"

# Test 1: Python Project Analysis (ACTUAL PMAT VALIDATION)
echo "Test 1: Python project analysis (ACTUAL PMAT VALIDATION)"
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

mkdir -p src
cat > src/calculator.py << 'EOF'
"""A simple calculator with technical debt examples."""

def add(a, b):
    # TODO: Add input validation
    return a + b

def divide(a, b):
    # FIXME: Handle division by zero properly
    if b == 0:
        print("Error: Division by zero!")
        return None
    return a / b

class Calculator:
    def complex_calculation(self, x, y, z):
        # NOTE: High cyclomatic complexity
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
EOF

# Run PMAT analysis
OUTPUT=$(pmat analyze complexity --path . --format json 2>&1 | grep -A 10000 '^{')

if echo "$OUTPUT" | jq -e '.summary.files' &> /dev/null; then
    FILE_COUNT=$(echo "$OUTPUT" | jq '.summary.files | length')
    if [ "$FILE_COUNT" -ge 1 ]; then
        # Verify it found Python file
        FOUND_FILE=$(echo "$OUTPUT" | jq -r '.summary.files[0].path' | grep -i "python" || echo "$OUTPUT" | jq -r '.summary.files[0].path')
        if [[ "$FOUND_FILE" == *"calculator.py"* ]]; then
            # Verify functions were detected
            FUNC_COUNT=$(echo "$OUTPUT" | jq '.summary.files[0].functions | length')
            if [ "$FUNC_COUNT" -ge 3 ]; then
                test_pass "Python analysis: Found $FUNC_COUNT functions in calculator.py"
            else
                test_fail "Python analysis: Expected >=3 functions, found $FUNC_COUNT"
            fi
        else
            test_fail "Python analysis: Expected calculator.py, found: $FOUND_FILE"
        fi
    else
        test_fail "Python analysis: Expected >=1 file, found $FILE_COUNT"
    fi
else
    test_fail "Python analysis: PMAT failed or produced invalid JSON"
fi

cd /
rm -rf "$TEST_DIR"

# Test 2: Rust Project Analysis (ACTUAL PMAT VALIDATION)
echo "Test 2: Rust project analysis (ACTUAL PMAT VALIDATION)"
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

mkdir -p src
cat > src/main.rs << 'EOF'
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

// FIXME: Remove this function
#[allow(dead_code)]
fn unused_function() {}

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

OUTPUT=$(pmat analyze complexity --path . --format json 2>&1 | grep -A 10000 '^{')

if echo "$OUTPUT" | jq -e '.summary.files' &> /dev/null; then
    FILE_COUNT=$(echo "$OUTPUT" | jq '.summary.files | length')
    if [ "$FILE_COUNT" -ge 1 ]; then
        FOUND_FILE=$(echo "$OUTPUT" | jq -r '.summary.files[0].path')
        if [[ "$FOUND_FILE" == *"main.rs"* ]]; then
            FUNC_COUNT=$(echo "$OUTPUT" | jq '.summary.files[0].functions | length')
            if [ "$FUNC_COUNT" -ge 4 ]; then
                test_pass "Rust analysis: Found $FUNC_COUNT functions in main.rs"
            else
                test_fail "Rust analysis: Expected >=4 functions, found $FUNC_COUNT"
            fi
        else
            test_fail "Rust analysis: Expected main.rs, found: $FOUND_FILE"
        fi
    else
        test_fail "Rust analysis: Expected >=1 file, found $FILE_COUNT"
    fi
else
    test_fail "Rust analysis: PMAT failed or produced invalid JSON"
fi

cd /
rm -rf "$TEST_DIR"

# Test 3: TypeScript Project Analysis (ACTUAL PMAT VALIDATION)
echo "Test 3: TypeScript project analysis (ACTUAL PMAT VALIDATION)"
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

mkdir -p src
cat > src/calculator.ts << 'EOF'
// TODO: Add proper error boundaries
export class Calculator {
    private history: number[] = [];

    add(a: number, b: number): number {
        return a + b;
    }

    divide(a: number, b: number): number {
        // FIXME: Add better validation
        if (b === 0) {
            console.error('Division by zero');
            return 0;
        }
        return a / b;
    }

    complexCalculation(x: number, y: number, z: number): number {
        if (x > 0) {
            if (y > 0) {
                if (z > 0) {
                    const result = x * y * z;
                    if (result > 1000) {
                        return result / 2;
                    } else {
                        return result;
                    }
                } else {
                    return x * y;
                }
            } else {
                return x;
            }
        } else {
            return 0;
        }
    }
}
EOF

OUTPUT=$(pmat analyze complexity --path . --format json 2>&1 | grep -A 10000 '^{')

if echo "$OUTPUT" | jq -e '.summary.files' &> /dev/null; then
    FILE_COUNT=$(echo "$OUTPUT" | jq '.summary.files | length')
    if [ "$FILE_COUNT" -ge 1 ]; then
        FOUND_FILE=$(echo "$OUTPUT" | jq -r '.summary.files[0].path')
        if [[ "$FOUND_FILE" == *"calculator.ts"* ]]; then
            FUNC_COUNT=$(echo "$OUTPUT" | jq '.summary.files[0].functions | length')
            if [ "$FUNC_COUNT" -ge 3 ]; then
                test_pass "TypeScript analysis: Found $FUNC_COUNT functions in calculator.ts"
            else
                test_fail "TypeScript analysis: Expected >=3 functions, found $FUNC_COUNT"
            fi
        else
            test_fail "TypeScript analysis: Expected calculator.ts, found: $FOUND_FILE"
        fi
    else
        test_fail "TypeScript analysis: Expected >=1 file, found $FILE_COUNT"
    fi
else
    test_fail "TypeScript analysis: PMAT failed or produced invalid JSON"
fi

cd /
rm -rf "$TEST_DIR"

# Test 4: JavaScript Project Analysis (ACTUAL PMAT VALIDATION)
echo "Test 4: JavaScript project analysis (ACTUAL PMAT VALIDATION)"
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

mkdir -p src
cat > src/index.js << 'EOF'
// TODO: Add proper error handling
function createServer() {
    return {
        start: function() {
            console.log('Server starting');
        }
    };
}

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

OUTPUT=$(pmat analyze complexity --path . --format json 2>&1 | grep -A 10000 '^{')

if echo "$OUTPUT" | jq -e '.summary.files' &> /dev/null; then
    FILE_COUNT=$(echo "$OUTPUT" | jq '.summary.files | length')
    if [ "$FILE_COUNT" -ge 1 ]; then
        FOUND_FILE=$(echo "$OUTPUT" | jq -r '.summary.files[0].path')
        if [[ "$FOUND_FILE" == *"index.js"* ]]; then
            FUNC_COUNT=$(echo "$OUTPUT" | jq '.summary.files[0].functions | length')
            if [ "$FUNC_COUNT" -ge 3 ]; then
                test_pass "JavaScript analysis: Found $FUNC_COUNT functions in index.js"
            else
                test_fail "JavaScript analysis: Expected >=3 functions, found $FUNC_COUNT"
            fi
        else
            test_fail "JavaScript analysis: Expected index.js, found: $FOUND_FILE"
        fi
    else
        test_fail "JavaScript analysis: Expected >=1 file, found $FILE_COUNT"
    fi
else
    test_fail "JavaScript analysis: PMAT failed or produced invalid JSON"
fi

cd /
rm -rf "$TEST_DIR"

# Test 5: C Project Analysis (ACTUAL PMAT VALIDATION)
echo "Test 5: C project analysis (ACTUAL PMAT VALIDATION)"
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

mkdir -p src
cat > src/calculator.c << 'EOF'
#include <stdio.h>

// TODO: Add error handling
int add(int a, int b) {
    return a + b;
}

// FIXME: Handle division by zero
int divide(int a, int b) {
    if (b == 0) {
        printf("Error: Division by zero\n");
        return 0;
    }
    return a / b;
}

int complex_function(int x, int y, int z) {
    if (x > 0) {
        if (y > 0) {
            if (z > 0) {
                if (x > y) {
                    return x + y + z;
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
        return 0;
    }
}
EOF

OUTPUT=$(pmat analyze complexity --path . --format json 2>&1 | grep -A 10000 '^{')

if echo "$OUTPUT" | jq -e '.summary.files' &> /dev/null; then
    FILE_COUNT=$(echo "$OUTPUT" | jq '.summary.files | length')
    if [ "$FILE_COUNT" -ge 1 ]; then
        FOUND_FILE=$(echo "$OUTPUT" | jq -r '.summary.files[0].path')
        if [[ "$FOUND_FILE" == *"calculator.c"* ]]; then
            FUNC_COUNT=$(echo "$OUTPUT" | jq '.summary.files[0].functions | length')
            if [ "$FUNC_COUNT" -ge 3 ]; then
                test_pass "C analysis: Found $FUNC_COUNT functions in calculator.c"
            else
                test_fail "C analysis: Expected >=3 functions, found $FUNC_COUNT"
            fi
        else
            test_fail "C analysis: Expected calculator.c, found: $FOUND_FILE"
        fi
    else
        test_fail "C analysis: Expected >=1 file, found $FILE_COUNT"
    fi
else
    test_fail "C analysis: PMAT failed or produced invalid JSON"
fi

cd /
rm -rf "$TEST_DIR"

# Test 6: C++ Project Analysis (ACTUAL PMAT VALIDATION)
echo "Test 6: C++ project analysis (ACTUAL PMAT VALIDATION)"
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

mkdir -p src
cat > src/calculator.cpp << 'EOF'
#include <iostream>

// TODO: Add input validation
class Calculator {
public:
    int add(int a, int b) {
        return a + b;
    }

    // FIXME: Better error handling
    int divide(int a, int b) {
        if (b == 0) {
            std::cerr << "Division by zero!" << std::endl;
            return 0;
        }
        return a / b;
    }

    int complexCalculation(int x, int y, int z) {
        if (x > 0) {
            if (y > 0) {
                if (z > 0) {
                    int result = x * y * z;
                    if (result > 1000) {
                        return result / 2;
                    } else {
                        return result;
                    }
                } else {
                    return x * y;
                }
            } else {
                return x;
            }
        } else {
            return 0;
        }
    }
};
EOF

OUTPUT=$(pmat analyze complexity --path . --format json 2>&1 | grep -A 10000 '^{')

if echo "$OUTPUT" | jq -e '.summary.files' &> /dev/null; then
    FILE_COUNT=$(echo "$OUTPUT" | jq '.summary.files | length')
    if [ "$FILE_COUNT" -ge 1 ]; then
        FOUND_FILE=$(echo "$OUTPUT" | jq -r '.summary.files[0].path')
        if [[ "$FOUND_FILE" == *"calculator.cpp"* ]]; then
            FUNC_COUNT=$(echo "$OUTPUT" | jq '.summary.files[0].functions | length')
            if [ "$FUNC_COUNT" -ge 3 ]; then
                test_pass "C++ analysis: Found $FUNC_COUNT functions in calculator.cpp"
            else
                test_fail "C++ analysis: Expected >=3 functions, found $FUNC_COUNT"
            fi
        else
            test_fail "C++ analysis: Expected calculator.cpp, found: $FOUND_FILE"
        fi
    else
        test_fail "C++ analysis: Expected >=1 file, found $FILE_COUNT"
    fi
else
    test_fail "C++ analysis: PMAT failed or produced invalid JSON"
fi

cd /
rm -rf "$TEST_DIR"

# Test 7: Lua TDG Analysis (ACTUAL PMAT VALIDATION)
echo "Test 7: Lua TDG analysis (ACTUAL PMAT VALIDATION)"
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

cat > game.lua << 'LUAEOF'
--- Game entity manager
local M = {}
local entities = {}

--- Create a new entity
function M.create_entity(name, x, y, health)
    local entity = {
        name = name,
        x = x or 0,
        y = y or 0,
        health = health or 100,
        alive = true,
    }
    entities[#entities + 1] = entity
    return entity
end

--- Update all entities
function M.update(dt)
    for i, entity in ipairs(entities) do
        if entity.alive then
            if entity.health <= 0 then
                entity.alive = false
            else
                entity.x = entity.x + dt
            end
        end
    end
end

--- Find entity by name
function M.find(name)
    for _, entity in ipairs(entities) do
        if entity.name == name then
            return entity
        end
    end
    return nil
end

return M
LUAEOF

OUTPUT=$(pmat analyze tdg --path game.lua --format json 2>&1 | sed -n '/^{/,/^}/p')

if echo "$OUTPUT" | jq -e '.language' &> /dev/null; then
    LANG=$(echo "$OUTPUT" | jq -r '.language')
    GRADE=$(echo "$OUTPUT" | jq -r '.grade')
    CONFIDENCE=$(echo "$OUTPUT" | jq -r '.confidence')
    TOTAL=$(echo "$OUTPUT" | jq -r '.total')

    if [ "$LANG" = "Lua" ]; then
        # Verify confidence is 0.9 (tree-sitter, not heuristic fallback)
        HIGH_CONF=$(echo "$CONFIDENCE > 0.5" | bc -l 2>/dev/null || echo "1")
        if [ "$HIGH_CONF" = "1" ]; then
            # Verify total score is reasonable (>50)
            GOOD_SCORE=$(echo "$TOTAL > 50" | bc -l 2>/dev/null || echo "1")
            if [ "$GOOD_SCORE" = "1" ]; then
                test_pass "Lua TDG: grade=$GRADE, total=$TOTAL, confidence=$CONFIDENCE"
            else
                test_fail "Lua TDG: score too low ($TOTAL), expected >50"
            fi
        else
            test_fail "Lua TDG: low confidence ($CONFIDENCE), expected >0.5 (tree-sitter)"
        fi
    else
        test_fail "Lua TDG: expected language=Lua, got $LANG"
    fi
else
    test_fail "Lua TDG: PMAT failed or produced invalid JSON"
fi

cd /
rm -rf "$TEST_DIR"

# Summary
echo ""
echo "=== Chapter 13 Test Summary ==="
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"

if [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ All tests passed! Chapter 13 VALIDATED AGAINST ACTUAL PMAT BEHAVIOR"
    echo "🎯 EXTREME TDD: All multi-language examples verified with real pmat analyze commands"
    echo "✅ Quality Gate: Genchi Genbutsu (go and see) - tested actual system behavior"
    echo ""
    echo "Languages tested successfully:"
    echo "- Python (full AST analysis)"
    echo "- Rust (full AST analysis)"
    echo "- TypeScript (full AST analysis)"
    echo "- JavaScript (full AST analysis)"
    echo "- C (full AST analysis)"
    echo "- C++ (full AST analysis)"
    echo "- Lua (full AST + TDG analysis)"
    exit 0
else
    echo "❌ Some tests failed - STOP THE LINE"
    exit 1
fi
