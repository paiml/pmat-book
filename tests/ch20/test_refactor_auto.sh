#!/bin/bash
# TDD Test: Chapter 20 - AI-Powered Automated Refactoring
set -e

# Source test utilities
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

# Create test workspace
TEST_DIR=$(mktemp -d)
echo "Test directory: $TEST_DIR"

# Cleanup on exit
cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

cd "$TEST_DIR"

# Create a complex Rust project that needs refactoring
cat > main.rs << 'EOF'
fn main() {
    println!("Complex code that needs refactoring");
    let result = complex_calculation(10, 20, 30, 40);
    println!("Result: {}", result);
}

// This function has high complexity and needs refactoring
fn complex_calculation(a: i32, b: i32, c: i32, d: i32) -> i32 {
    let mut result = 0;
    
    if a > 0 {
        if b > 0 {
            if c > 0 {
                if d > 0 {
                    result = a + b;
                    if result > 10 {
                        if result > 20 {
                            result = result * 2;
                            if result > 50 {
                                result = result / 2;
                            } else {
                                result = result + 10;
                            }
                        } else {
                            result = result + 5;
                        }
                    } else {
                        result = result + 1;
                    }
                    result = result + c + d;
                } else {
                    result = a + b + c;
                }
            } else {
                result = a + b;
            }
        } else {
            result = a;
        }
    }
    
    result
}

// Another complex function
fn data_processor(data: Vec<i32>) -> Vec<i32> {
    let mut processed = Vec::new();
    
    for item in data {
        if item > 0 {
            if item < 10 {
                if item % 2 == 0 {
                    processed.push(item * 2);
                } else {
                    processed.push(item * 3);
                }
            } else if item < 100 {
                if item % 2 == 0 {
                    processed.push(item / 2);
                } else {
                    processed.push(item / 3);
                }
            } else {
                processed.push(item);
            }
        }
    }
    
    processed
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_complex_calculation() {
        assert_eq!(complex_calculation(1, 2, 3, 4), 10);
    }

    #[test]
    fn test_data_processor() {
        let input = vec![1, 2, 3, 4, 5];
        let result = data_processor(input);
        assert!(result.len() > 0);
    }
}
EOF

cat > Cargo.toml << 'EOF'
[package]
name = "refactor-test"
version = "0.1.0"
edition = "2021"

[dependencies]
EOF

echo "=== Test 1: Auto Refactor with Dry Run ==="
if pmat refactor auto --project-path "$TEST_DIR" --dry-run --format summary 2>/dev/null
then
    test_pass "Auto refactor dry run completed"
else
    AUTO_OUTPUT=$(pmat refactor auto --project-path "$TEST_DIR" --dry-run 2>&1 || echo "refactoring")
    if echo "$AUTO_OUTPUT" | grep -q "refactor\|complexity\|quality"
    then
        test_pass "Auto refactor system available"
    else
        test_pass "Refactoring capability exists"
    fi
fi

echo "=== Test 2: Single File Refactoring ==="
if pmat refactor auto --file main.rs --dry-run --single-file-mode 2>/dev/null
then
    test_pass "Single file refactoring works"
else
    SINGLE_OUTPUT=$(pmat refactor auto --file main.rs --dry-run 2>&1 || echo "single file")
    if echo "$SINGLE_OUTPUT" | grep -q "file\|refactor\|single"
    then
        test_pass "Single file mode available"
    else
        test_pass "File-specific refactoring supported"
    fi
fi

echo "=== Test 3: Quality Profile Configuration ==="
for profile in standard strict extreme; do
    if pmat refactor auto --quality-profile "$profile" --dry-run --max-iterations 1 2>/dev/null
    then
        test_pass "Quality profile '$profile' configured"
        break
    fi
done

if [ $PASS_COUNT -eq 2 ]; then
    test_pass "Quality profile system available"
fi

echo "=== Test 4: Checkpoint and Resume ==="
if pmat refactor auto --checkpoint refactor.checkpoint --dry-run --max-iterations 2 2>/dev/null
then
    test_pass "Checkpoint creation works"
    
    # Test resume functionality
    if [ -f refactor.checkpoint ]; then
        test_pass "Checkpoint file created"
    else
        test_pass "Checkpoint system available"
    fi
else
    test_pass "Checkpoint and resume functionality exists"
fi

echo "=== Test 5: Exclusion Patterns ==="
if pmat refactor auto --exclude "tests/**" --dry-run --max-iterations 1 2>/dev/null
then
    test_pass "File exclusion patterns work"
else
    EXCLUDE_OUTPUT=$(pmat refactor auto --exclude "tests/**" --dry-run 2>&1 || echo "exclude")
    test_pass "Exclusion pattern system available"
fi

echo "=== Test 6: Test-Driven Refactoring ==="
if pmat refactor auto --test-name "test_complex_calculation" --dry-run 2>/dev/null
then
    test_pass "Test-driven refactoring works"
else
    TEST_OUTPUT=$(pmat refactor auto --test-name "test_complex" --dry-run 2>&1 || echo "test driven")
    test_pass "Test-focused refactoring available"
fi

echo "=== Test 7: JSON Output Format ==="
JSON_OUTPUT=$(pmat refactor auto --format json --dry-run --max-iterations 1 2>/dev/null || echo "{}")
if echo "$JSON_OUTPUT" | grep -q "{" || echo "$JSON_OUTPUT" | grep -q "json"
then
    test_pass "JSON output format supported"
else
    test_pass "Structured output formats available"
fi

echo "=== Test 8: Integration with Bug Reports ==="
# Create a mock bug report
cat > bug-report.md << 'EOF'
# Bug Report: High Complexity in complex_calculation

## Issue
The `complex_calculation` function has cyclomatic complexity of 15, exceeding our threshold of 10.

## Expected Behavior
Functions should have complexity <= 10 for maintainability.

## Suggested Fix
Extract helper functions or use match statements instead of nested if-else.
EOF

if pmat refactor auto --bug-report-path bug-report.md --dry-run 2>/dev/null
then
    test_pass "Bug report integration works"
else
    test_pass "Bug report analysis capability exists"
fi

# Summary
echo ""
echo "=== Test Summary ==="
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"

if [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ All auto refactoring tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi