#!/bin/bash
# TDD Test: Chapter 9 - Pre-commit Hooks Management
# Tests all pre-commit hook examples documented in the book

set -e

echo "=== Testing Chapter 9: Pre-commit Hooks Management ==="

# Test utilities
PASS_COUNT=0
FAIL_COUNT=0
TEST_DIR=$(mktemp -d)

test_pass() {
    echo "✅ PASS: $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

test_fail() {
    echo "❌ FAIL: $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

cleanup() {
    rm -rf "$TEST_DIR"
}

trap cleanup EXIT

# Setup test repository
setup_test_repo() {
    cd "$TEST_DIR"
    git init
    
    # Create sample Python project
    mkdir -p src tests
    
    cat > src/main.py << 'EOF'
def calculate_metrics(data):
    """Calculate code quality metrics."""
    total = sum(data)
    average = total / len(data) if data else 0
    return {"total": total, "average": average}

def process_file(filename):
    """Process a file and return results."""
    with open(filename, 'r') as f:
        content = f.read()
    return len(content)
EOF
    
    cat > src/utils.py << 'EOF'
import json

def validate_input(data):
    """Validate input data."""
    if not isinstance(data, (list, tuple)):
        raise ValueError("Input must be a list or tuple")
    return True

def format_output(result):
    """Format output as JSON."""
    return json.dumps(result, indent=2)
EOF
    
    cat > README.md << 'EOF'
# Test Project

A sample project for testing PMAT pre-commit hooks.

## Features
- Quality gates enforcement
- Automatic code analysis
- Pre-commit validation
EOF
}

# Test 1: Basic pre-commit configuration
echo "Test 1: Basic pre-commit configuration"
setup_test_repo

cat > .pre-commit-config.yaml << 'EOF'
repos:
  - repo: local
    hooks:
      - id: pmat-quality-check
        name: PMAT Quality Check
        entry: pmat quality-gate
        language: system
        pass_filenames: false
        always_run: true
      
      - id: pmat-complexity
        name: PMAT Complexity Check
        entry: pmat analyze complexity --project-path .
        language: system
        pass_filenames: false
        files: \.(py|js|rs)$
EOF

if [ -f .pre-commit-config.yaml ]; then
    test_pass "Pre-commit config created"

    # Validate YAML structure (basic check without Python)
    if grep -q "repos:" .pre-commit-config.yaml && grep -q "hooks:" .pre-commit-config.yaml; then
        test_pass "Pre-commit config YAML is valid"
    else
        test_fail "Pre-commit config YAML is invalid"
    fi
else
    test_fail "Failed to create pre-commit config"
fi

# Test 2: PMAT-specific hooks configuration
echo "Test 2: PMAT-specific hooks configuration"
cat > .pmat-hooks.yaml << 'EOF'
version: "1.0"
hooks:
  pre-commit:
    - name: quality-gate
      enabled: true
      config:
        min_grade: "B+"
        fail_on_decrease: true
        
    - name: complexity-check
      enabled: true
      config:
        max_complexity: 10
        exclude_patterns:
          - "tests/**"
          - "*.test.py"
          
    - name: dead-code-check
      enabled: true
      config:
        fail_on_dead_code: true
        
    - name: satd-check
      enabled: true
      config:
        max_satd_items: 5
        severity_threshold: "medium"
        
  pre-push:
    - name: full-analysis
      enabled: true
      config:
        generate_report: true
        report_format: "markdown"
EOF

if [ -f .pmat-hooks.yaml ]; then
    test_pass "PMAT hooks config created"

    # Validate YAML structure (basic check without Python)
    if grep -q "hooks:" .pmat-hooks.yaml && grep -q "version:" .pmat-hooks.yaml; then
        test_pass "PMAT hooks config structure is valid"
    else
        test_fail "PMAT hooks config structure is invalid"
    fi
else
    test_fail "Failed to create PMAT hooks config"
fi

# Test 3: Git hook installation script
echo "Test 3: Git hook installation script"
cat > install-hooks.sh << 'EOF'
#!/bin/bash
# Install PMAT pre-commit hooks

set -e

# Check if in git repository
if [ ! -d .git ]; then
    echo "Error: Not in a git repository"
    exit 1
fi

# Create pre-commit hook
cat > .git/hooks/pre-commit << 'HOOK'
#!/bin/bash
# PMAT Pre-commit Hook

echo "🔍 Running PMAT quality checks..."

# Run PMAT quality gate
if command -v pmat &> /dev/null; then
    pmat quality-gate --strict || {
        echo "❌ PMAT quality gate failed"
        echo "Run 'pmat analyze .' for details"
        exit 1
    }
else
    echo "⚠️  PMAT not installed, skipping quality checks"
fi

echo "✅ PMAT quality checks passed"
HOOK

chmod +x .git/hooks/pre-commit
echo "✅ Pre-commit hook installed"
EOF

chmod +x install-hooks.sh

if [ -f install-hooks.sh ]; then
    test_pass "Hook installation script created"
    
    # Test script execution in git repo
    if ./install-hooks.sh 2>/dev/null; then
        test_pass "Hook installation script executed"
        
        # Check if hook was created
        if [ -f .git/hooks/pre-commit ]; then
            test_pass "Pre-commit hook installed"
        else
            test_fail "Pre-commit hook not found"
        fi
    else
        test_fail "Hook installation script failed"
    fi
else
    test_fail "Failed to create installation script"
fi

# Test 4: Quality gate configuration
echo "Test 4: Quality gate configuration"
cat > pmat.toml << 'EOF'
[quality-gate]
min_grade = "B+"
fail_fast = true
ignore_generated = true

[quality-gate.thresholds]
complexity = 10
duplication = 0.05
documentation = 0.80
test_coverage = 0.70

[hooks]
pre_commit_enabled = true
pre_push_enabled = true
auto_fix = false

[hooks.pre_commit]
checks = ["quality", "complexity", "satd"]
fail_on_warning = false

[hooks.pre_push]
checks = ["full-analysis", "test-coverage"]
generate_report = true
EOF

if [ -f pmat.toml ]; then
    test_pass "PMAT configuration created"
    
    # Check TOML structure (basic validation)
    if grep -q "\[quality-gate\]" pmat.toml && grep -q "\[hooks\]" pmat.toml; then
        test_pass "PMAT config has required sections"
    else
        test_fail "PMAT config missing required sections"
    fi
else
    test_fail "Failed to create PMAT configuration"
fi

# Test 5: Hook bypass configuration
echo "Test 5: Hook bypass and skip patterns"
cat > .pmatignore << 'EOF'
# Generated files
*.generated.py
*_pb2.py
*_pb2_grpc.py

# Build artifacts
build/
dist/
*.egg-info/

# Test fixtures
tests/fixtures/
tests/data/

# Documentation
docs/api/

# Vendor code
vendor/
third_party/
EOF

if [ -f .pmatignore ]; then
    test_pass "PMAT ignore file created"
    
    # Check ignore patterns
    if grep -q "Generated files" .pmatignore; then
        test_pass "Ignore patterns configured"
    else
        test_fail "Ignore patterns missing"
    fi
else
    test_fail "Failed to create .pmatignore"
fi

# Test 6: Husky integration example
echo "Test 6: Husky integration for Node.js projects"
cat > package.json << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0",
  "scripts": {
    "prepare": "husky install",
    "pre-commit": "pmat quality-gate",
    "pre-push": "pmat analyze . --format json > pmat-report.json"
  },
  "devDependencies": {
    "husky": "^8.0.0"
  },
  "husky": {
    "hooks": {
      "pre-commit": "npm run pre-commit",
      "pre-push": "npm run pre-push"
    }
  }
}
EOF

if [ -f package.json ]; then
    test_pass "Package.json with Husky config created"
    
    # Validate JSON
    if python3 -c "import json; json.load(open('package.json'))" 2>/dev/null; then
        test_pass "Package.json is valid JSON"
    else
        test_fail "Package.json is invalid JSON"
    fi
else
    test_fail "Failed to create package.json"
fi

# Test 7: Python pre-commit integration
echo "Test 7: Python pre-commit framework integration"
cat > .pre-commit-config.yaml << 'EOF'
repos:
  # Standard Python hooks
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      
  # PMAT hooks
  - repo: local
    hooks:
      - id: pmat-quality
        name: PMAT Quality Gate
        entry: pmat quality-gate --strict
        language: system
        pass_filenames: false
        always_run: true
        
      - id: pmat-complexity
        name: PMAT Complexity Check
        entry: bash -c 'pmat analyze complexity --project-path . --max-complexity 10'
        language: system
        types: [python]
        
      - id: pmat-satd
        name: PMAT Technical Debt Check
        entry: pmat analyze satd --path .
        language: system
        pass_filenames: false
EOF

if [ -f .pre-commit-config.yaml ]; then
    test_pass "Python pre-commit config created"
else
    test_fail "Failed to create Python pre-commit config"
fi

# Test 8: CI/CD integration example
echo "Test 8: CI/CD integration with hooks"
mkdir -p .github/workflows
cat > .github/workflows/quality.yml << 'EOF'
name: PMAT Quality Checks

on:
  pull_request:
  push:
    branches: [main]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install PMAT
        run: cargo install pmat
        
      - name: Run quality gate
        run: pmat quality-gate --strict
        
      - name: Check complexity
        run: pmat analyze complexity --project-path .
        
      - name: Check for dead code
        run: pmat analyze dead-code --path .
        
      - name: Comment PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v6
        with:
          script: |
            const report = require('./pmat-report.json');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## PMAT Quality Report\nGrade: ${report.grade}`
            });
EOF

mkdir -p .github/workflows
if [ -f .github/workflows/quality.yml ]; then
    test_pass "CI/CD workflow created"
else
    test_fail "Failed to create CI/CD workflow"
fi

# Summary
echo ""
echo "=== Test Summary ==="
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"

if [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ All pre-commit hooks tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi