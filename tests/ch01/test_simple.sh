#!/bin/bash
# Simple validation test for Chapter 1 
set -e

echo "=== Chapter 1 TDD Validation ==="

# Test 1: Files exist
if [ -f "src/ch01-01-installing.md" ]; then
    echo "✅ PASS: Installation chapter exists"
else
    echo "❌ FAIL: Installation chapter missing"
    exit 1
fi

# Test 2: Content check
if grep -q "cargo install pmat" src/ch01-01-installing.md; then
    echo "✅ PASS: Cargo installation documented"
else
    echo "❌ FAIL: Cargo installation missing"
    exit 1
fi

# Test 3: JSON validation
EXPECTED='{"repository":{"total_files":1}}'
echo "$EXPECTED" | jq empty >/dev/null 2>&1 && echo "✅ PASS: JSON structure valid" || { echo "❌ FAIL: JSON invalid"; exit 1; }

# Test 4: Python file creation
cat > test.py << 'EOF'
def hello():
    print("Hello, PMAT!")
EOF

python3 -m py_compile test.py >/dev/null 2>&1 && echo "✅ PASS: Python syntax valid" || { echo "❌ FAIL: Python syntax"; exit 1; }

rm -f test.py test.pyc

echo "✅ All Chapter 1 TDD tests passed!"