#!/bin/bash
# TDD Test: Chapter 2 - pmat context Command
# Tests comprehensive context generation features

set -e

# pmat shim: when pmat is absent, fail silently (no "command not found" text
# for greps to match); every caller then takes its SKIPPED arm.
pmat() {
    type -P pmat >/dev/null 2>&1 || return 127
    command pmat "$@"
}


echo "=== Testing Chapter 2: pmat context Command ==="

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

# A flag that pmat 3.44.0 does not have must be rejected by the argument
# parser: exit 2 and clap's "unexpected argument '<flag>'" message.
# Usage: test_absent_flag "<label>" "<flag>" <command...>
test_absent_flag() {
    local label="$1" flag="$2" rc=0
    shift 2
    "$@" > absent_flag.txt 2>&1 || rc=$?
    if [ "$rc" -eq 2 ] && grep -q "unexpected argument '$flag'" absent_flag.txt; then
        test_pass "$label: $flag is not in pmat 3.44.0 (rejected, exit 2)"
    else
        test_fail "$label: expected $flag rejected with exit 2, got rc=$rc"
    fi
}

# Test 1: Create test project structure
echo ""
echo "Test 1: Creating test project for context generation"

mkdir -p src/models src/utils tests docs
cat > src/main.py << 'EOF'
#!/usr/bin/env python3
"""Main application entry point."""

import sys
from models.user import User
from utils.config import load_config

def main():
    """Main function."""
    config = load_config()
    user = User("Alice", "alice@example.com")
    print(f"Hello, {user.name}!")
    return 0

if __name__ == "__main__":
    sys.exit(main())
EOF

cat > src/models/user.py << 'EOF'
"""User model."""

class User:
    """Represents a user."""
    
    def __init__(self, name: str, email: str):
        self.name = name
        self.email = email
    
    def __repr__(self):
        return f"User(name={self.name}, email={self.email})"
EOF

cat > src/utils/config.py << 'EOF'
"""Configuration utilities."""

import json
import os

def load_config():
    """Load configuration from file or environment."""
    config_file = os.getenv("CONFIG_FILE", "config.json")
    if os.path.exists(config_file):
        with open(config_file) as f:
            return json.load(f)
    return {"debug": False, "version": "1.0.0"}
EOF

cat > README.md << 'EOF'
# Test Project

This is a test project for PMAT context generation.

## Features
- User management
- Configuration loading
- Clean architecture

## Installation
```bash
pip install -r requirements.txt
```
EOF

cat > .gitignore << 'EOF'
__pycache__/
*.pyc
.env
venv/
EOF

echo "fixture: Test project structure created"

# Test 2: Basic context generation
echo ""
echo "Test 2: Basic context generation"

if [ "$MOCK_MODE" = false ]; then
    if $PMAT_BIN context > context_output.txt 2>&1; then
        test_pass "Context generation completed"
        
        # Check for expected elements
        if grep -q "src/main.py\|main.py\|File:" context_output.txt; then
            test_pass "Context includes source files"
        else
            test_fail "Context missing source files"
        fi
        
        # 3.44.0 context is an AST inventory of source files: it has no
        # documentation section (README.md is not listed). Assert the real
        # report header instead.
        if grep -q "^# Project Context" context_output.txt && grep -q "Project Structure" context_output.txt; then
            test_pass "Context includes project summary"
        else
            test_fail "Context missing project summary"
        fi
    else
        test_fail "Context generation failed"
    fi
else
    # Mock output
    cat > context_output.txt << 'EOF'
📁 Repository Context
=====================

Project: test-project
Files: 5
Total Lines: 47
Languages: Python, Markdown

## Structure
```
.
├── README.md (8 lines)
├── src/
│   ├── main.py (16 lines)
│   ├── models/
│   │   └── user.py (10 lines)
│   └── utils/
│       └── config.py (11 lines)
└── .gitignore (4 lines)
```

## Key Files

### src/main.py
Entry point with main function, imports User and config

### src/models/user.py
User class with name and email attributes

### src/utils/config.py
Configuration loading from JSON or environment

### README.md
Project documentation with features and installation
EOF
    test_skip "Mock context generation completed"
fi

# Test 3: Context with filters
echo ""
echo "Test 3: Context generation with filters"

if [ "$MOCK_MODE" = false ]; then
    # Python-only: 3.44.0 narrows by language (--language), not by glob
    if $PMAT_BIN context --language python > context_python.txt 2>&1; then
        if grep -q "^\*\*Language\*\*: python" context_python.txt; then
            test_pass "Python-only context generated"
        else
            test_fail "Python-only context missing Language: python"
        fi
    else
        test_fail "Python-only context failed"
    fi

    # Exclude tests: 3.44.0 has no --exclude glob, so assert the real rejection
    test_absent_flag "Context without tests" "--exclude" $PMAT_BIN context --exclude="tests/*"
else
    test_skip "Mock filtered context completed"
fi

# Test 4: Context output formats
echo ""
echo "Test 4: Context output formats"

if [ "$MOCK_MODE" = false ]; then
    # JSON format
    # Progress lines go to stderr in 3.44.0; keep them out of the JSON document
    if $PMAT_BIN context --format json > context.json 2>context_json.err; then
        test_pass "JSON context generated"
        if jq empty context.json 2>/dev/null; then
            test_pass "JSON context is valid"
        else
            test_fail "JSON context is invalid"
        fi
    else
        test_fail "JSON context generation failed"
    fi
    
    # Markdown format
    if $PMAT_BIN context --format markdown > context.md 2>&1; then
        test_pass "Markdown context generated"
    else
        test_fail "Markdown context generation failed"
    fi
else
    # Mock JSON output
    cat > context.json << 'EOF'
{
  "project": "test-project",
  "files": 5,
  "total_lines": 47,
  "languages": ["Python", "Markdown"],
  "structure": {
    "src": {
      "main.py": {"lines": 16, "language": "Python"},
      "models": {
        "user.py": {"lines": 10, "language": "Python"}
      },
      "utils": {
        "config.py": {"lines": 11, "language": "Python"}
      }
    },
    "README.md": {"lines": 8, "language": "Markdown"}
  }
}
EOF
    test_skip "Mock JSON context generated"
    if jq empty context.json 2>/dev/null; then
        test_skip "Mock JSON is valid"
    fi
fi

# Test 5: Context with analysis
echo ""
echo "Test 5: Context with embedded analysis"

if [ "$MOCK_MODE" = false ]; then
    # 3.44.0 has no --with-analysis: complexity, SATD and churn are in the
    # default report. Assert the flag is rejected and the default report has them.
    test_absent_flag "Context with analysis" "--with-analysis" $PMAT_BIN context --with-analysis
    if $PMAT_BIN context > context_analyzed.txt 2>/dev/null && grep -q "\[complexity: " context_analyzed.txt; then
        test_pass "Default context includes complexity metrics"
    else
        test_fail "Default context missing complexity metrics"
    fi
else
    cat > context_analyzed.txt << 'EOF'
📁 Repository Context with Analysis
=====================================

## Code Metrics
- Cyclomatic Complexity: 3 (Low)
- Lines of Code: 47
- Comment Ratio: 15%
- Test Coverage: 0% (No tests found)

## Quality Score
- Grade: B+
- Technical Debt: Low
- Maintainability: Good

## Dependencies
- Python standard library only
- No external dependencies detected

## Suggestions
1. Add unit tests for User class
2. Add error handling in main()
3. Consider type hints throughout
EOF
    test_skip "Mock context with analysis completed"
fi

# Test 6: Context size limits
echo ""
echo "Test 6: Context size management"

if [ "$MOCK_MODE" = false ]; then
    # 3.44.0 has no token or file caps; the levers are -p and --language.
    test_absent_flag "Token-limited context" "--max-tokens" $PMAT_BIN context --max-tokens 1000
    test_absent_flag "File-limited context" "--max-files" $PMAT_BIN context --max-files 3
else
    test_skip "Mock size-limited context completed"
fi

# Test 7: Context for AI/LLM
echo ""
echo "Test 7: AI-optimized context generation"

if [ "$MOCK_MODE" = false ]; then
    # 3.44.0 has no --ai-format; its LLM output is --format llm-optimized
    test_absent_flag "AI-optimized context" "--ai-format" $PMAT_BIN context --ai-format
    if $PMAT_BIN context --format llm-optimized > context_ai.txt 2>&1; then
        test_pass "LLM-optimized context generated (--format llm-optimized)"
    else
        test_fail "LLM-optimized context failed"
    fi
else
    cat > context_ai.txt << 'EOF'
<repository>
<summary>Python project with user management and configuration</summary>
<structure>
src/main.py - Entry point
src/models/user.py - User model class
src/utils/config.py - Configuration loader
README.md - Documentation
</structure>
<key_patterns>
- MVC-like structure with models and utils
- JSON configuration support
- Clean imports and dependencies
</key_patterns>
<code_style>
- Python 3.x
- Class-based models
- Function-based utilities
</code_style>
</repository>
EOF
    test_skip "Mock AI-optimized context completed"
fi

# Test 8: Context caching
echo ""
echo "Test 8: Context caching behavior"

if [ "$MOCK_MODE" = false ]; then
    # 3.44.0 has no context cache flags (pmat cache stats is a different
    # command), so both the cache write and the cache clear are rejected.
    test_absent_flag "First context generation (cache miss)" "--cache" $PMAT_BIN context --cache
    test_absent_flag "Second context generation (cache hit)" "--cache" $PMAT_BIN context --cache
    test_absent_flag "Context cache cleared" "--clear-cache" $PMAT_BIN context --clear-cache
else
    test_skip "Mock context caching completed"
fi

# Cleanup
cd /
rm -rf "$TEST_DIR"

echo ""
echo "=== Chapter 2 Context Test Summary ==="
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
    echo "✅ All context tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi
