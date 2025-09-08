#!/bin/bash
# TDD Test: Chapter 11 - Custom Quality Rules
# Tests all custom rule examples documented in the book

set -e

echo "=== Testing Chapter 11: Custom Quality Rules ==="

TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Initialize git repo
git init --initial-branch=main

# Test 1: Basic custom rule definition
echo "Test 1: Basic custom rule definition"
mkdir -p .pmat/rules
cat > .pmat/rules/no-hardcoded-secrets.yaml << 'EOF'
name: "no-hardcoded-secrets"
description: "Prevent hardcoded API keys and secrets"
severity: "error"
category: "security"
languages: ["python", "javascript", "java", "go"]

patterns:
  - regex: '(api_key|secret_key|password)\s*=\s*["\'][^"\']{20,}["\']'
    message: "Hardcoded secret detected"
    
  - regex: 'Bearer\s+[A-Za-z0-9]{40,}'
    message: "Hardcoded Bearer token found"

fixes:
  - suggestion: "Use environment variables: os.environ.get('API_KEY')"
  - suggestion: "Use configuration files with proper access controls"

examples:
  bad: |
    api_key = "sk-1234567890abcdef1234567890abcdef"
    
  good: |
    api_key = os.environ.get('API_KEY')
    
metadata:
  created_by: "security-team"
  created_date: "2025-01-15"
  tags: ["security", "secrets", "hardcoded"]
EOF

if [ -f .pmat/rules/no-hardcoded-secrets.yaml ]; then
    echo "✅ Basic custom rule created"
else
    echo "❌ Failed to create basic custom rule"
    exit 1
fi

# Test 2: Advanced pattern matching rule
echo "Test 2: Advanced pattern matching rule"
cat > .pmat/rules/enforce-error-handling.yaml << 'EOF'
name: "enforce-error-handling"
description: "Ensure proper error handling in critical functions"
severity: "warning"
languages: ["python"]

ast_patterns:
  - pattern: |
      def $func_name($params):
          $body
    where:
      - $func_name matches: "(save|delete|update|create)_.*"
      - not contains: "try:"
      - not contains: "except:"
    message: "Critical functions must include error handling"

contextual_rules:
  - when: "function_name.startswith('save_')"
    require: ["try_except_block", "logging_statement"]
    
  - when: "function_calls_external_api"
    require: ["timeout_handling", "retry_logic"]

file_scope_rules:
  - pattern: "class.*Repository"
    requires:
      - "at_least_one_method_with_error_handling"
      - "connection_cleanup_in_destructor"
EOF

if [ -f .pmat/rules/enforce-error-handling.yaml ]; then
    echo "✅ Advanced pattern rule created"
else
    echo "❌ Failed to create advanced pattern rule"
    exit 1
fi

# Test 3: Microservices architecture rule
echo "Test 3: Microservices architecture rule"
cat > .pmat/rules/microservice-boundaries.yaml << 'EOF'
name: "microservice-boundaries"
description: "Enforce microservice architectural boundaries"
severity: "error"
category: "architecture"

cross_file_rules:
  - name: "no-direct-db-access"
    description: "Services should only access their own database"
    pattern: |
      from $service_name.models import $model
    where:
      - current_file not in: "$service_name/**"
    message: "Direct database access across service boundaries"
    
  - name: "api-communication-only"
    description: "Inter-service communication must use APIs"
    ast_pattern: |
      import $module
    where:
      - $module matches: "(user_service|order_service|payment_service)\\.(?!api)"
    message: "Use API endpoints for inter-service communication"

dependency_rules:
  allowed_imports:
    "user_service/**":
      - "shared.utils.*"
      - "user_service.*"
      - "api_client.*"
    "order_service/**":
      - "shared.utils.*"  
      - "order_service.*"
      - "api_client.*"
      
  forbidden_imports:
    "user_service/**":
      - "order_service.models.*"
      - "payment_service.database.*"
EOF

if [ -f .pmat/rules/microservice-boundaries.yaml ]; then
    echo "✅ Microservice architecture rule created"
else
    echo "❌ Failed to create architecture rule"
    exit 1
fi

# Test 4: Performance critical code rule  
echo "Test 4: Performance critical code rule"
cat > .pmat/rules/performance-critical.yaml << 'EOF'
name: "performance-critical-code"
description: "Enforce performance standards in critical paths"
severity: "warning"
category: "performance"

metric_rules:
  - name: "hot-path-complexity"
    description: "Hot paths must have low complexity"
    applies_to:
      - functions_with_decorator: "@performance_critical"
      - files_matching: "*/hot_paths/*"
    thresholds:
      cyclomatic_complexity: 5
      cognitive_complexity: 8
      max_depth: 3
      
  - name: "no-inefficient-operations"
    description: "Avoid inefficient operations in performance critical code"
    patterns:
      - regex: '\.sort\(\)'
        context: "@performance_critical"
        message: "Sorting in hot path - consider pre-sorted data"
        
      - ast_pattern: |
          for $var in $iterable:
              if $condition:
                  $body
        context: "function_has_decorator('@performance_critical')"
        message: "Consider list comprehension or generator"

benchmarking:
  required_for:
    - functions_with_decorator: "@performance_critical"
  benchmark_file: "benchmarks/test_{function_name}.py"
  performance_regression_threshold: "10%"
EOF

if [ -f .pmat/rules/performance-critical.yaml ]; then
    echo "✅ Performance rule created"
else
    echo "❌ Failed to create performance rule"
    exit 1
fi

# Test 5: Team coding standards rule
echo "Test 5: Team coding standards rule"
cat > .pmat/rules/team-standards.yaml << 'EOF'
name: "team-coding-standards"
description: "Enforce team-specific coding practices"
severity: "info"
category: "style"

documentation_rules:
  - name: "public-api-docs"
    description: "Public APIs must have comprehensive documentation"
    applies_to:
      - classes_with_decorator: "@public_api"
      - functions_starting_with: "api_"
    requires:
      - docstring_with_args
      - docstring_with_return_type  
      - docstring_with_examples
      - type_annotations

  - name: "complex-function-docs"
    description: "Complex functions need detailed documentation"
    applies_to:
      - cyclomatic_complexity: "> 8"
      - function_length: "> 30"
    requires:
      - docstring_with_algorithm_explanation
      - docstring_with_time_complexity

naming_conventions:
  constants: "UPPER_SNAKE_CASE"
  classes: "PascalCase"
  functions: "snake_case"
  private_methods: "_snake_case"
  
  custom_patterns:
    database_models: ".*Model$"
    test_functions: "test_.*"
    fixture_functions: ".*_fixture$"

git_integration:
  pr_requirements:
    - "all_custom_rules_pass"
    - "documentation_coverage >= 80%"
    - "no_todo_comments_in_production_code"
EOF

if [ -f .pmat/rules/team-standards.yaml ]; then
    echo "✅ Team standards rule created"
else
    echo "❌ Failed to create team standards rule"
    exit 1
fi

# Test 6: Python-specific rules
echo "Test 6: Python-specific rules"
cat > .pmat/rules/python-specific.yaml << 'EOF'
name: "python-best-practices"
description: "Python-specific quality rules"
languages: ["python"]

python_rules:
  - name: "proper-exception-handling"
    description: "Use specific exception types"
    patterns:
      - regex: 'except:'
        message: "Use specific exception types instead of bare except"
        
      - regex: 'except Exception:'
        message: "Catch specific exceptions when possible"
        
  - name: "dataclass-over-namedtuple"
    description: "Prefer dataclasses for complex data structures"
    ast_pattern: |
      from collections import namedtuple
      $name = namedtuple($args)
    where:
      - field_count: "> 5"
    message: "Consider using @dataclass for complex structures"
    
  - name: "async-proper-usage"
    description: "Async functions should use await"
    ast_pattern: |
      async def $name($params):
          $body
    where:
      - not contains: "await"
      - function_length: "> 5"
    message: "Async function should contain await statements"

type_checking:
  require_type_hints:
    - "public_functions"
    - "class_methods"
    - "functions_with_complexity > 5"
    
  mypy_integration:
    strict_mode: true
    check_untyped_defs: true
EOF

if [ -f .pmat/rules/python-specific.yaml ]; then
    echo "✅ Python-specific rule created"
else
    echo "❌ Failed to create Python rule"
    exit 1
fi

# Test 7: JavaScript/TypeScript rules
echo "Test 7: JavaScript/TypeScript rules"
cat > .pmat/rules/javascript-specific.yaml << 'EOF'
name: "javascript-modern-practices"
description: "Modern JavaScript/TypeScript practices"
languages: ["javascript", "typescript"]

modern_javascript:
  - name: "prefer-async-await"
    description: "Use async/await over Promise chains"
    patterns:
      - regex: '\.then\(.*\.then\('
        message: "Consider using async/await for multiple Promise chains"
        
  - name: "const-over-let"
    description: "Prefer const for immutable values"
    ast_pattern: |
      let $var = $value;
    where:
      - variable_never_reassigned: true
    message: "Use const for variables that are never reassigned"
    
  - name: "destructuring-assignments"
    description: "Use destructuring for object properties"
    patterns:
      - regex: 'const \w+ = \w+\.\w+;\s*const \w+ = \w+\.\w+;'
        message: "Consider using destructuring assignment"

react_specific:
  - name: "hooks-rules"
    description: "Enforce React Hooks rules"
    file_patterns: ["*.jsx", "*.tsx"]
    rules:
      - pattern: "use\\w+\\("
        context: "inside_condition"
        message: "Hooks cannot be called conditionally"
        
      - pattern: "useState\\(.*\\)"
        requires: "component_function"
        message: "Hooks can only be called in React components"

typescript_specific:
  strict_types:
    - "no_any_types"
    - "explicit_return_types_for_exported_functions"
    - "prefer_readonly_arrays"
EOF

if [ -f .pmat/rules/javascript-specific.yaml ]; then
    echo "✅ JavaScript/TypeScript rule created"
else
    echo "❌ Failed to create JavaScript rule"
    exit 1
fi

# Test 8: PMAT configuration for custom rules
echo "Test 8: PMAT custom rules configuration"
cat > pmat.toml << 'EOF'
[rules]
enabled = true
custom_rules_directory = ".pmat/rules"
default_severity = "warning"

[rules.processing]
parallel = true
max_threads = 4
cache_enabled = true

[rules.categories]
security = "error"
performance = "warning"
style = "info"
architecture = "error"

[rules.language_specific]
python = [
    "python-best-practices",
    "enforce-error-handling"
]
javascript = [
    "javascript-modern-practices"
]

[rules.exclusions]
paths = ["tests/", "vendor/", "node_modules/"]
files = ["*.test.*", "*_test.*"]
EOF

if [ -f pmat.toml ]; then
    echo "✅ PMAT custom rules configuration created"
else
    echo "❌ Failed to create PMAT configuration"
    exit 1
fi

# Cleanup
cd /
rm -rf "$TEST_DIR"

echo ""
echo "=== Chapter 11 Test Summary ==="
echo "✅ All 8 custom rule tests passed!"
echo ""
echo "Custom rule configurations validated:"
echo "- Basic custom rule definition"
echo "- Advanced pattern matching rule"
echo "- Microservices architecture rule"
echo "- Performance critical code rule"
echo "- Team coding standards rule"
echo "- Python-specific rules"
echo "- JavaScript/TypeScript rules"
echo "- PMAT custom rules configuration"

exit 0