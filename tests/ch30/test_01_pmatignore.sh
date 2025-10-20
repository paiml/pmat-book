#!/bin/bash
# TDD Test: Chapter 30 - File Exclusions (.pmatignore/.paimlignore)
# Tests ACTUAL PMAT behavior with file exclusion patterns
# EXTREME TDD with NASA-style quality verification - VALIDATES REAL PMAT

# Note: Using manual error handling instead of set -e for better test output

echo "=== Testing Chapter 30: File Exclusion Examples (ACTUAL PMAT VALIDATION) ==="

PASS_COUNT=0
FAIL_COUNT=0

test_pass() {
    echo "✅ PASS: $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

test_fail() {
    echo "❌ FAIL: $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    # Continue running remaining tests to see full picture
}

# Verify pmat is available
if ! command -v pmat &> /dev/null; then
    echo "❌ FATAL: pmat binary not found in PATH"
    exit 1
fi

echo "Using pmat version: $(pmat --version)"

# Test 1: .pmatignore actually excludes files
echo "Test 1: .pmatignore excludes directories (ACTUAL PMAT VALIDATION)"
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Create project structure with files to exclude
mkdir -p src tests_disabled target
cat > src/main.rs << 'EOF'
fn main() {
    println!("Hello");
}
EOF

cat > tests_disabled/old_test.rs << 'EOF'
#[test]
fn old_test() {
    assert_eq!(1, 1);
}
EOF

cat > target/debug.rs << 'EOF'
// Build artifact
EOF

# Create .pmatignore
cat > .pmatignore << 'EOF'
tests_disabled/
target/
EOF

# Run pmat analyze and check output
OUTPUT=$(pmat analyze complexity --path . --format json 2>&1 | grep -A 10000 '^{')

# Verify only src/main.rs is analyzed (tests_disabled and target excluded)
if echo "$OUTPUT" | jq -e '.summary.files' &> /dev/null; then
    FILE_COUNT=$(echo "$OUTPUT" | jq '.summary.files | length')
    if [ "$FILE_COUNT" -eq 1 ]; then
        # Verify it's the right file
        FOUND_FILE=$(echo "$OUTPUT" | jq -r '.summary.files[0].path')
        if [[ "$FOUND_FILE" == *"src/main.rs" ]]; then
            test_pass ".pmatignore successfully excludes tests_disabled/ and target/"
        else
            test_fail "Expected src/main.rs, found: $FOUND_FILE"
        fi
    else
        test_fail "Expected 1 file, found $FILE_COUNT (exclusions not working)"
    fi
else
    test_fail "PMAT analysis failed or produced invalid JSON"
fi

cd /
rm -rf "$TEST_DIR"

# Test 2: .paimlignore legacy support (ACTUAL PMAT VALIDATION)
echo "Test 2: .paimlignore legacy format (ACTUAL PMAT VALIDATION)"
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

mkdir -p src build
cat > src/lib.rs << 'EOF'
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}
EOF

cat > build/generated.rs << 'EOF'
// Generated code
EOF

# Create .paimlignore (legacy format)
cat > .paimlignore << 'EOF'
build/
EOF

OUTPUT=$(pmat analyze complexity --path . --format json 2>&1 | grep -A 10000 '^{')

if echo "$OUTPUT" | jq -e '.summary.files' &> /dev/null; then
    FILE_COUNT=$(echo "$OUTPUT" | jq '.summary.files | length')
    if [ "$FILE_COUNT" -eq 1 ]; then
        FOUND_FILE=$(echo "$OUTPUT" | jq -r '.summary.files[0].path')
        if [[ "$FOUND_FILE" == *"src/lib.rs" ]]; then
            test_pass ".paimlignore legacy format works (build/ excluded)"
        else
            test_fail "Expected src/lib.rs, found: $FOUND_FILE"
        fi
    else
        test_fail "Expected 1 file, found $FILE_COUNT (.paimlignore not working)"
    fi
else
    test_fail "PMAT analysis failed with .paimlignore"
fi

cd /
rm -rf "$TEST_DIR"

# Test 3: Both .pmatignore and .paimlignore applied (union) (ACTUAL PMAT VALIDATION)
echo "Test 3: .pmatignore and .paimlignore both applied (ACTUAL PMAT VALIDATION)"
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

mkdir -p src tmp cache
cat > src/app.rs << 'EOF'
fn main() {}
EOF

cat > tmp/scratch.rs << 'EOF'
// Temp file
EOF

cat > cache/data.rs << 'EOF'
// Cache file
EOF

# Create BOTH files - both should be respected (union)
cat > .pmatignore << 'EOF'
tmp/
EOF

cat > .paimlignore << 'EOF'
cache/
EOF

OUTPUT=$(pmat analyze complexity --path . --format json 2>&1 | grep -A 10000 '^{')

if echo "$OUTPUT" | jq -e '.summary.files' &> /dev/null; then
    FILE_COUNT=$(echo "$OUTPUT" | jq '.summary.files | length')
    FILES=$(echo "$OUTPUT" | jq -r '.summary.files[].path' | sort)

    # Should exclude BOTH tmp/ and cache/ (union of both files)
    if [ "$FILE_COUNT" -eq 1 ] && [[ "$FILES" == *"src/app.rs" ]]; then
        if ! echo "$FILES" | grep -q "tmp/" && ! echo "$FILES" | grep -q "cache/"; then
            test_pass "Both .pmatignore and .paimlignore applied (union of exclusions)"
        else
            test_fail "Both tmp/ and cache/ should be excluded"
        fi
    else
        test_fail "Expected only src/app.rs, found $FILE_COUNT files"
    fi
else
    test_fail "PMAT analysis failed with both ignore files"
fi

cd /
rm -rf "$TEST_DIR"

# Test 4: Wildcard patterns (ACTUAL PMAT VALIDATION)
echo "Test 4: Wildcard patterns (ACTUAL PMAT VALIDATION)"
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

mkdir -p src cache/deep/nested
cat > src/main.rs << 'EOF'
fn main() {}
EOF

cat > cache/temp.rs << 'EOF'
// Cache file
EOF

cat > cache/deep/nested/data.rs << 'EOF'
// Deeply nested cache
EOF

cat > .pmatignore << 'EOF'
cache/**
EOF

OUTPUT=$(pmat analyze complexity --path . --format json 2>&1 | grep -A 10000 '^{')

if echo "$OUTPUT" | jq -e '.summary.files' &> /dev/null; then
    FILE_COUNT=$(echo "$OUTPUT" | jq '.summary.files | length')
    FILES=$(echo "$OUTPUT" | jq -r '.summary.files[].path')

    if [ "$FILE_COUNT" -eq 1 ] && [[ "$FILES" == *"src/main.rs" ]]; then
        if ! echo "$FILES" | grep -q "cache/"; then
            test_pass "Wildcard pattern cache/** excludes all cache subdirectories"
        else
            test_fail "cache/** should exclude all cache files"
        fi
    else
        test_fail "Expected only src/main.rs, found $FILE_COUNT files"
    fi
else
    test_fail "PMAT analysis failed with wildcard patterns"
fi

cd /
rm -rf "$TEST_DIR"

# Test 5: .gitignore integration (ACTUAL PMAT VALIDATION)
echo "Test 5: .gitignore integration (ACTUAL PMAT VALIDATION)"
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

mkdir -p src build dist
cat > src/lib.rs << 'EOF'
pub fn test() {}
EOF

cat > build/output.rs << 'EOF'
// Build artifact
EOF

cat > dist/bundle.rs << 'EOF'
// Distribution file
EOF

# Only .gitignore, no .pmatignore
cat > .gitignore << 'EOF'
build/
dist/
EOF

OUTPUT=$(pmat analyze complexity --path . --format json 2>&1 | grep -A 10000 '^{')

if echo "$OUTPUT" | jq -e '.summary.files' &> /dev/null; then
    FILE_COUNT=$(echo "$OUTPUT" | jq '.summary.files | length')
    FILES=$(echo "$OUTPUT" | jq -r '.summary.files[].path')

    if [ "$FILE_COUNT" -eq 1 ] && [[ "$FILES" == *"src/lib.rs" ]]; then
        if ! echo "$FILES" | grep -q "build/" && ! echo "$FILES" | grep -q "dist/"; then
            test_pass ".gitignore automatically respected (build/ and dist/ excluded)"
        else
            test_fail ".gitignore patterns should exclude build/ and dist/"
        fi
    else
        test_fail "Expected only src/lib.rs, found $FILE_COUNT files"
    fi
else
    test_fail "PMAT analysis failed with .gitignore"
fi

cd /
rm -rf "$TEST_DIR"

# Summary
echo ""
echo "=== Test Summary ==="
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"

if [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ All tests passed! Chapter 30 VALIDATED AGAINST ACTUAL PMAT BEHAVIOR"
    echo "🎯 EXTREME TDD: All exclusion patterns verified with real pmat analyze commands"
    echo "✅ Quality Gate: Genchi Genbutsu (go and see) - tested actual system behavior"
    exit 0
else
    echo "❌ Some tests failed - STOP THE LINE"
    exit 1
fi
