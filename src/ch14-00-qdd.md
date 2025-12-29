# Chapter 14: Quality-Driven Development (QDD)

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (18/18 examples)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 18 | All QDD features tested |
| ⚠️ Not Implemented | 0 | Planned for future versions |
| ❌ Broken | 0 | Known issues, needs fixing |
| 📋 Planned | 0 | Future roadmap features |

*Last updated: 2025-10-26*  
*PMAT version: pmat 2.213.1*  
*Test-Driven: All examples validated in `tests/ch14/test_qdd.sh`*
<!-- DOC_STATUS_END -->

## Introduction to Quality-Driven Development

Quality-Driven Development (QDD) is PMAT's revolutionary approach to code generation and refactoring that embeds quality standards directly into the development process. Introduced in version 2.69.0, QDD transforms the traditional "write first, fix later" mentality into a "quality-first, always" philosophy.

## What is QDD?

QDD is a unified tool for creating, refactoring, and maintaining code with **guaranteed quality standards**. Unlike traditional development approaches that treat quality as an afterthought, QDD makes quality the primary driver of every code operation.

### Core Principles

QDD is built on the **Toyota Way** manufacturing principles adapted for software development:

1. **Quality First**: Every line of code meets predefined quality standards before creation
2. **Continuous Improvement (Kaizen)**: Iterative refinement toward perfection
3. **Standardized Work**: Consistent patterns and practices across all code
4. **Built-in Quality (Jidoka)**: Automatic quality checks at every step
5. **Single Responsibility**: Each tool, function, and module has one clear purpose

### The Four QDD Operations

QDD provides four fundamental operations for quality-driven development:

1. **Create**: Generate new code with quality built-in from day one
2. **Refactor**: Transform existing code to meet quality standards
3. **Enhance**: Add features while maintaining or improving quality
4. **Migrate**: Transform code between patterns and architectures

## QDD Quality Profiles

QDD uses quality profiles to define standards for different development contexts. Each profile specifies thresholds for complexity, coverage, technical debt, and design principles.

### Built-in Profiles

#### Extreme Profile
For mission-critical systems requiring highest quality:

```toml
[profile.extreme]
max_complexity = 5
max_cognitive = 5
min_coverage = 90
max_tdg = 3
zero_satd = true
zero_dead_code = true
require_doctests = true
require_property_tests = true

[patterns]
enforce_solid = true
enforce_dry = true
enforce_kiss = true
enforce_yagni = true
```

#### Standard Profile
Balanced quality for production systems:

```toml
[profile.standard]
max_complexity = 10
max_cognitive = 10
min_coverage = 80
max_tdg = 5
zero_satd = true
zero_dead_code = false
require_doctests = true
require_property_tests = false
```

#### Enterprise Profile
Strict but realistic for large teams:

```toml
[profile.enterprise]
max_complexity = 15
max_cognitive = 15
min_coverage = 85
max_tdg = 5
zero_satd = true
zero_dead_code = true
require_doctests = true
require_property_tests = false
```

#### Startup Profile
Flexible for rapid development:

```toml
[profile.startup]
max_complexity = 12
max_cognitive = 12
min_coverage = 75
max_tdg = 8
zero_satd = false
zero_dead_code = false
require_doctests = false
require_property_tests = false
```

#### Legacy Profile
Pragmatic approach for existing codebases:

```toml
[profile.legacy]
max_complexity = 25
max_cognitive = 25
min_coverage = 50
max_tdg = 15
zero_satd = false
zero_dead_code = false
require_doctests = false
require_property_tests = false
```

#### Relaxed Profile
Minimal constraints for prototyping:

```toml
[profile.relaxed]
max_complexity = 20
max_cognitive = 20
min_coverage = 60
max_tdg = 10
zero_satd = false
zero_dead_code = false
require_doctests = false
require_property_tests = false
```

## QDD Create: Quality-First Code Generation

The `qdd create` command generates new code with quality standards built-in from the start.

### Basic Usage

```bash
# Create a simple function
pmat qdd create function add_numbers "Add two numbers" \
  --profile standard \
  --input int a \
  --input int b \
  --output int

# Create a service class
pmat qdd create service UserValidator "Validate user data" \
  --profile enterprise \
  --input dict user_data \
  --output ValidationResult
```

### Example Output

```bash
🎯 QDD Code Creation Successful!
✅ Quality Profile: Standard
📊 Quality Score: 92.5
🔧 Complexity: 3
📈 Coverage: 85.0%
🏗️  TDG Score: 2

📝 Generated Code:
def add_numbers(a: int, b: int) -> int:
    """Add two numbers together.
    
    Args:
        a: First number to add
        b: Second number to add
        
    Returns:
        Sum of a and b
        
    Examples:
        >>> add_numbers(2, 3)
        5
        >>> add_numbers(-1, 5)
        4
        
    Raises:
        TypeError: If arguments are not integers
    """
    if not isinstance(a, int):
        raise TypeError(f"Expected int for 'a', got {type(a).__name__}")
    if not isinstance(b, int):
        raise TypeError(f"Expected int for 'b', got {type(b).__name__}")
    
    return a + b

🧪 Generated Tests:
import pytest
from your_module import add_numbers

def test_add_numbers_positive():
    """Test adding positive numbers."""
    assert add_numbers(2, 3) == 5
    assert add_numbers(10, 20) == 30

def test_add_numbers_negative():
    """Test adding negative numbers.""" 
    assert add_numbers(-1, 5) == 4
    assert add_numbers(-10, -5) == -15

def test_add_numbers_zero():
    """Test adding with zero."""
    assert add_numbers(0, 5) == 5
    assert add_numbers(10, 0) == 10

def test_add_numbers_type_validation():
    """Test type validation."""
    with pytest.raises(TypeError):
        add_numbers("2", 3)
    with pytest.raises(TypeError):
        add_numbers(2, 3.5)

def test_add_numbers_doctests():
    """Test doctest examples."""
    import doctest
    import your_module
    assert doctest.testmod(your_module).failed == 0

📚 Generated Documentation:
# add_numbers Function

Adds two integers with comprehensive type checking and error handling.

## Quality Metrics
- **Complexity**: 3 (Excellent - below threshold of 10)
- **Coverage**: 85% (Good - meets threshold)
- **TDG Score**: 2 (Acceptable)
- **SATD Count**: 0 (Excellent - zero technical debt)

## Design Principles Applied
- **Single Responsibility**: Function has one clear purpose
- **Type Safety**: Comprehensive input validation
- **Error Handling**: Clear, descriptive error messages
- **Documentation**: Doctests provide executable examples
- **Testing**: 100% path coverage with edge cases
```

### Advanced Create Options

```bash
# Save to specific file
pmat qdd create function calculate_tax "Calculate tax amount" \
  --profile extreme \
  --input float amount \
  --input float rate \
  --output float \
  --output-file src/tax_calculator.py

# Create with custom quality thresholds
pmat qdd create module PaymentProcessor "Handle payment processing" \
  --profile custom \
  --max-complexity 8 \
  --min-coverage 90 \
  --zero-satd
```

## QDD Refactor: Quality-Driven Code Improvement

The `qdd refactor` command transforms existing code to meet quality standards while preserving functionality.

### Basic Usage

```bash
# Refactor specific file
pmat qdd refactor src/complex_module.py --profile standard

# Refactor specific function
pmat qdd refactor src/utils.py --function complex_calculation --profile extreme

# Dry run to preview changes
pmat qdd refactor src/legacy.py --profile enterprise --dry-run
```

### Example: Refactoring Complex Code

**Before (Complex Code):**
```python
def complex_payment_processor(user_data, payment_info, config):
    if user_data is None:
        return None
    if not user_data.get('id'):
        raise ValueError("User ID required")
    if payment_info is None:
        raise ValueError("Payment info required")
    if config.get('validation_level') == 'strict':
        if not payment_info.get('card_number'):
            raise ValueError("Card number required")
        if len(payment_info.get('card_number', '')) < 16:
            raise ValueError("Invalid card number")
        # ... more nested validation logic
        if payment_info.get('amount', 0) > config.get('max_amount', 1000):
            if not user_data.get('verified'):
                if not user_data.get('kyc_completed'):
                    raise ValueError("KYC required")
                if user_data.get('risk_score', 0) > 50:
                    raise ValueError("High risk user")
    # ... complex processing logic
    return {'user_id': user_data['id'], 'status': 'pending'}
```

**QDD Refactoring Command:**
```bash
pmat qdd refactor payment_processor.py --profile standard --max-complexity 10
```

**After (QDD Refactored):**
```python
def process_payment(user_data: UserData, payment_info: PaymentInfo, 
                   config: ProcessorConfig) -> PaymentResult:
    """Process payment with comprehensive validation.
    
    Args:
        user_data: User information
        payment_info: Payment details
        config: Processing configuration
        
    Returns:
        PaymentResult with status and details
        
    Raises:
        ValidationError: If validation fails
        ProcessingError: If payment processing fails
    """
    _validate_required_data(user_data, payment_info)
    
    if config.validation_level == ValidationLevel.STRICT:
        _validate_strict_requirements(payment_info)
        _validate_user_limits(user_data, payment_info, config)
    
    return _execute_payment(user_data, payment_info)

def _validate_required_data(user_data: UserData, payment_info: PaymentInfo) -> None:
    """Validate required data is present."""
    if not user_data or not user_data.id:
        raise ValidationError("User ID required")
    if not payment_info:
        raise ValidationError("Payment info required")

def _validate_strict_requirements(payment_info: PaymentInfo) -> None:
    """Validate strict payment requirements."""
    if not payment_info.card_number:
        raise ValidationError("Card number required")
    if len(payment_info.card_number) < 16:
        raise ValidationError("Invalid card number")
    if not payment_info.cvv:
        raise ValidationError("CVV required")

def _validate_user_limits(user_data: UserData, payment_info: PaymentInfo, 
                         config: ProcessorConfig) -> None:
    """Validate user-specific limits and requirements."""
    if payment_info.amount > config.max_amount:
        if not user_data.verified:
            _validate_unverified_user(user_data)
        elif payment_info.amount > config.verified_max:
            raise ValidationError("Amount exceeds verified limit")

def _validate_unverified_user(user_data: UserData) -> None:
    """Validate requirements for unverified users."""
    if not user_data.kyc_completed:
        raise ValidationError("KYC required for large transactions")
    if user_data.risk_score > 50:
        raise ValidationError("High risk user")

def _execute_payment(user_data: UserData, payment_info: PaymentInfo) -> PaymentResult:
    """Execute the actual payment processing."""
    return PaymentResult(
        user_id=user_data.id,
        amount=payment_info.amount,
        status=PaymentStatus.PENDING
    )
```

**Refactoring Results:**
```bash
🎯 QDD Refactoring Successful!
📁 File: payment_processor.py
✅ Quality Profile: Standard
📊 Quality Score: 89.2 (improved from 45.8)
🔧 Complexity: 8 (reduced from 18)
📈 Coverage: 85.0% (increased from 45%)
🏗️  TDG Score: 3 (improved from 12)

🔄 3 rollback checkpoints available

Quality Improvements:
- Extracted 4 helper functions (Single Responsibility)
- Reduced cyclomatic complexity from 18 to 8
- Added comprehensive type hints
- Improved error handling with custom exceptions
- Generated 95% test coverage
- Zero SATD (technical debt) remaining
```

## QDD Validate: Quality Assessment

The `qdd validate` command assesses code quality against specified profiles without making changes.

### Basic Usage

```bash
# Validate current directory with standard profile
pmat qdd validate . --profile standard

# Validate with detailed output
pmat qdd validate src/ --profile enterprise --format detailed

# Strict mode (fail on quality violations)
pmat qdd validate . --profile extreme --strict
```

### Output Formats

#### Summary Format
```bash
pmat qdd validate . --format summary

🔍 QDD Quality Validation
📁 Path: .
✅ Quality Profile: Standard
📊 Thresholds:
  🔧 Max Complexity: 10
  📈 Min Coverage: 80%
  🏗️  Max TDG: 5
  🚫 Zero SATD: true

📋 Validation Summary:
Status: ✅ PASSED
```

#### Detailed Format
```bash
pmat qdd validate . --format detailed

📋 Detailed Validation Results:
✅ Complexity check: PASSED (avg: 7.2, max: 10)
✅ Coverage check: PASSED (85.6% ≥ 80%)
✅ Technical debt: PASSED (TDG: 3.2 ≤ 5)
✅ SATD check: PASSED (0 instances)
⚠️  Dead code: WARNING (2.1% found)

Files requiring attention:
- src/legacy_utils.py: Complexity 12 (exceeds 10)
- src/old_parser.py: Coverage 65% (below 80%)

Recommendations:
1. Refactor src/legacy_utils.py to reduce complexity
2. Add tests for src/old_parser.py to improve coverage
3. Remove dead code in src/unused_helpers.py
```

#### JSON Format
```bash
pmat qdd validate . --format json
```

```json
{
  "status": "passed",
  "profile": "standard",
  "path": ".",
  "validation_time": "2025-10-26T12:00:00Z",
  "thresholds": {
    "max_complexity": 10,
    "min_coverage": 80,
    "max_tdg": 5,
    "zero_satd": true
  },
  "results": {
    "complexity": {
      "status": "passed",
      "average": 7.2,
      "maximum": 9,
      "violations": []
    },
    "coverage": {
      "status": "passed",
      "percentage": 85.6,
      "violations": []
    },
    "technical_debt": {
      "status": "passed",
      "average_tdg": 3.2,
      "violations": []
    },
    "satd": {
      "status": "passed",
      "count": 0,
      "violations": []
    }
  },
  "recommendations": [
    "Maintain current quality levels",
    "Consider upgrading to enterprise profile"
  ]
}
```

#### Markdown Format
```bash
pmat qdd validate . --format markdown
```

```markdown
# QDD Validation Report

**Status:** ✅ PASSED  
**Profile:** Standard  
**Path:** .  
**Date:** 2025-10-26 12:00:00 UTC

## Quality Metrics

| Metric | Status | Value | Threshold | 
|--------|--------|-------|-----------|
| Complexity | ✅ PASSED | 7.2 avg | ≤ 10 |
| Coverage | ✅ PASSED | 85.6% | ≥ 80% |
| Technical Debt | ✅ PASSED | 3.2 TDG | ≤ 5 |
| SATD Count | ✅ PASSED | 0 | = 0 |

## Summary

All quality thresholds met. Code base demonstrates excellent quality practices with room for improvement toward enterprise-grade standards.

### Next Steps
- Consider upgrading to enterprise profile
- Maintain current testing practices
- Monitor for quality regression
```

## Profile Management and Customization

### Choosing the Right Profile

QDD includes a profile recommendation system to help select appropriate quality standards:

```bash
# Get profile recommendation based on codebase
pmat qdd validate . --recommend-profile

📊 Profile Recommendation Analysis
Current codebase metrics:
- Average complexity: 12.5
- Test coverage: 65%
- TDG score: 8.2
- SATD instances: 15

🎯 Recommended Profile: startup
Rationale:
- Current complexity exceeds standard profile limits
- Coverage below enterprise requirements
- Moderate technical debt present
- Startup profile provides realistic improvement path

Migration Path:
1. Start with startup profile (achievable now)
2. Improve coverage to 75% over 2 sprints  
3. Refactor high-complexity modules
4. Graduate to standard profile in 3-4 sprints
```

### Custom Profile Creation

Create project-specific quality profiles:

```toml
# .pmat/qdd-custom.toml
[profile.our_api]
name = "Our API Standards"
max_complexity = 8
max_cognitive = 8
min_coverage = 85
max_tdg = 4
zero_satd = true
zero_dead_code = true
require_doctests = true

[profile.our_api.patterns]
enforce_solid = true
enforce_dry = true
enforce_kiss = true
enforce_yagni = false

[[profile.our_api.rules]]
name = "no_print_statements"
description = "Use logging instead of print"
severity = "error"
pattern = "print\\("

[[profile.our_api.rules]]
name = "proper_exception_handling"
description = "Always handle specific exceptions"
severity = "warning"
pattern = "except:"
```

### Profile Validation

Validate if your codebase is ready for a specific profile:

```bash
# Check if codebase meets enterprise standards
pmat qdd validate . --profile enterprise --preview

🔍 Enterprise Profile Compatibility Check
📁 Codebase: .
🎯 Target Profile: Enterprise (max_complexity=15, min_coverage=85%)

Results:
❌ INCOMPATIBLE - 3 issues found

Issues:
1. src/parser.py: Complexity 18 (exceeds 15)
2. src/utils.py: Coverage 72% (below 85%)
3. src/legacy.py: 5 SATD instances (profile requires 0)

🛠️  Remediation Plan:
1. Refactor src/parser.py (estimated 2 hours)
2. Add tests to src/utils.py (estimated 1 hour)
3. Implement TODO items in src/legacy.py (estimated 4 hours)

Estimated effort: 7 hours
Success probability: 95%

💡 Alternative: Consider 'standard' profile as intermediate step
```

## CI/CD Integration

### GitHub Actions Integration

```yaml
name: QDD Quality Validation

on:
  pull_request:
  push:
    branches: [main, develop]

jobs:
  qdd-validation:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install PMAT
        run: cargo install pmat
        
      - name: QDD Quality Gate
        run: |
          # Validate code meets quality standards
          pmat qdd validate . \
            --profile standard \
            --format json \
            --output qdd-report.json \
            --strict
            
      - name: Generate Quality Report
        if: always()
        run: |
          pmat qdd validate . \
            --profile standard \
            --format markdown > qdd-report.md
            
      - name: Comment PR with QDD Results
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const report = fs.readFileSync('qdd-report.md', 'utf8');
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## 🎯 QDD Quality Validation Results\n\n${report}`
            });
            
      - name: Upload QDD Artifacts
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: qdd-quality-report
          path: |
            qdd-report.json
            qdd-report.md
```

### Quality Gates

Implement progressive quality gates:

```bash
# Different quality standards for different branches
if [[ "$GITHUB_REF" == "refs/heads/main" ]]; then
    # Production branch requires enterprise standards
    pmat qdd validate . --profile enterprise --strict
elif [[ "$GITHUB_REF" == "refs/heads/develop" ]]; then
    # Development branch requires standard
    pmat qdd validate . --profile standard --strict  
else
    # Feature branches use startup profile
    pmat qdd validate . --profile startup
fi
```

### Pre-commit Hooks

```bash
#!/bin/bash
# .git/hooks/pre-commit
set -e

echo "🎯 Running QDD pre-commit validation..."

# Check if changes meet quality standards
pmat qdd validate . --profile standard --strict

# Auto-fix simple quality issues if possible
pmat qdd refactor $(git diff --cached --name-only --diff-filter=M | grep '\.py$') \
    --profile standard \
    --auto-fix \
    --dry-run

echo "✅ QDD validation passed"
```

## MCP Integration

QDD is fully integrated with the Model Context Protocol for AI-driven development:

### MCP Tool Usage

```json
{
  "name": "quality_driven_development",
  "arguments": {
    "operation": "create",
    "spec": {
      "code_type": "function",
      "name": "validate_email",
      "purpose": "Validate email address with comprehensive checks",
      "inputs": [
        {"name": "email", "type": "str", "description": "Email to validate"}
      ],
      "outputs": {"name": "is_valid", "type": "bool", "description": "True if valid"}
    },
    "quality_profile": "enterprise"
  }
}
```

### MCP Response

```json
{
  "result": {
    "code": "def validate_email(email: str) -> bool:\n    \"\"\"Validate email address...",
    "tests": "import pytest\nfrom email_validator import validate_email...",
    "documentation": "# Email Validation Function\n\nComprehensive email validation...",
    "quality_score": {
      "overall": 94.5,
      "complexity": 4,
      "coverage": 92.0,
      "tdg": 2
    },
    "metrics": {
      "complexity": 4,
      "cognitive_complexity": 4,
      "coverage": 92,
      "tdg": 2,
      "satd_count": 0,
      "has_doctests": true
    }
  }
}
```

## Advanced QDD Features

### Code Enhancement

Add features to existing code while maintaining quality:

```bash
# Enhance existing function with new capabilities
pmat qdd enhance src/calculator.py \
    --features "logging,input_validation,error_recovery" \
    --profile standard \
    --maintain-api
```

### Pattern Migration

Transform code between architectural patterns:

```bash
# Migrate from procedural to object-oriented
pmat qdd migrate src/legacy_functions.py \
    --from-pattern procedural \
    --to-pattern object_oriented \
    --profile enterprise

# Migrate to microservices architecture
pmat qdd migrate src/monolith/ \
    --from-pattern monolith \
    --to-pattern microservices \
    --profile enterprise
```

### Rollback and Recovery

QDD maintains rollback points for safe operations:

```bash
# View available rollback points
pmat qdd rollback --list src/refactored_module.py

Rollback Points for src/refactored_module.py:
1. 2025-10-26T10:15:00Z - Before complexity reduction
2. 2025-10-26T10:20:00Z - After function extraction  
3. 2025-10-26T10:25:00Z - After type annotation addition

# Rollback to specific checkpoint
pmat qdd rollback src/refactored_module.py --to-checkpoint 2

# Rollback to original
pmat qdd rollback src/refactored_module.py --to-original
```

## Toyota Way Implementation in QDD

QDD embodies Toyota's manufacturing excellence principles:

### 1. Built-in Quality (Jidoka)
- Quality checks at every step prevent defects from propagating
- Automatic stopping when quality thresholds are violated
- Red-Green-Refactor cycles ensure continuous quality

### 2. Continuous Improvement (Kaizen)
- Incremental quality improvements in every operation
- Learning from each refactoring to improve future operations
- Profile recommendations based on codebase evolution

### 3. Standardized Work
- Consistent code patterns across all generated code
- Reproducible quality outcomes through profiles
- Elimination of quality variation through automation

### 4. Root Cause Analysis
- Deep analysis of quality issues to prevent recurrence
- Systematic improvement of patterns and profiles
- Data-driven quality decision making

## Real-World Examples

### Example 1: Startup to Enterprise Migration

A startup outgrowing their initial codebase:

```bash
# Phase 1: Assess current state
pmat qdd validate . --profile startup

Status: ✅ PASSED (barely)
- Complexity: 11.8 (threshold: 12)
- Coverage: 76% (threshold: 75%)  
- TDG: 7.5 (threshold: 8)

# Phase 2: Identify improvement opportunities
pmat qdd validate . --profile standard --preview

Status: ❌ FAILED - 15 violations
Estimated effort: 40 hours
Success probability: 85%

# Phase 3: Systematic improvement
pmat qdd refactor src/ --profile standard --max-files 5
pmat qdd validate . --profile standard

Status: ✅ PASSED
Ready for production deployment!
```

### Example 2: Legacy System Modernization

Modernizing a 10-year-old Python codebase:

```bash
# Step 1: Establish baseline
pmat qdd validate legacy_system/ --profile legacy

Status: ✅ PASSED
- Complexity: 22.5 (threshold: 25)
- Coverage: 45% (threshold: 50%)
- TDG: 12.8 (threshold: 15)

# Step 2: Progressive improvement
# Focus on critical modules first
pmat qdd refactor legacy_system/payment/ --profile startup
pmat qdd refactor legacy_system/auth/ --profile startup  
pmat qdd refactor legacy_system/api/ --profile startup

# Step 3: Gradual profile advancement
# 3 months later:
pmat qdd validate legacy_system/ --profile standard
Status: ✅ PASSED

# 6 months later:
pmat qdd validate legacy_system/ --profile enterprise  
Status: ✅ PASSED
```

### Example 3: Team Standardization

Establishing quality standards across development teams:

```bash
# Create team-specific profile
cat > .pmat/team-profile.toml << 'EOF'
[profile.team_standard]
max_complexity = 12
min_coverage = 80
max_tdg = 5
zero_satd = true

[patterns]
enforce_solid = true
enforce_dry = true
EOF

# Validate all team repositories
for repo in api-service data-processor frontend-app; do
    echo "Validating $repo..."
    cd $repo
    pmat qdd validate . --profile team_standard
    cd ..
done

# Generate team quality dashboard
pmat qdd validate . --format json --output team-quality.json
pmat qdd dashboard --input team-quality.json --output team-dashboard.html
```

## Best Practices

### 1. Profile Selection Strategy

```bash
# Start with realistic profile
pmat qdd validate . --recommend-profile

# Implement gradual improvements  
sprint_1: pmat qdd refactor critical_modules/ --profile startup
sprint_2: pmat qdd refactor remaining_modules/ --profile startup  
sprint_3: pmat qdd validate . --profile standard --preview
sprint_4: pmat qdd refactor violations/ --profile standard
```

### 2. Incremental Quality Improvement

```bash
# Focus on high-impact files first
pmat qdd validate . --format json | jq '.files | sort_by(.tdg_score) | reverse | .[0:5]'

# Refactor systematically
for file in high_tdg_files; do
    pmat qdd refactor $file --profile standard --dry-run
    # Review changes, then apply
    pmat qdd refactor $file --profile standard
done
```

### 3. Quality Monitoring

```bash
# Continuous quality monitoring
pmat qdd validate . --format json > quality_baseline.json

# After changes
pmat qdd validate . --format json > quality_current.json
pmat qdd compare quality_baseline.json quality_current.json

Quality Regression Detected:
- src/new_feature.py: Complexity increased from 8 to 15
- Overall TDG: 3.2 → 4.8 (degraded)
- Coverage: 85% → 78% (degraded)

Recommendation: Refactor src/new_feature.py before merging
```

## Configuration Reference

### Complete QDD Configuration

```toml
# .pmat/qdd.toml - Complete QDD configuration
[qdd]
default_profile = "standard"
auto_generate_tests = true
auto_generate_docs = true
enable_rollback = true
max_rollback_points = 5

[qdd.output]
include_metrics = true
show_recommendations = true
verbose_logging = false

[qdd.patterns]
# Architectural patterns to enforce
enforce_solid = true      # Single Responsibility, Open/Closed, etc.
enforce_dry = true        # Don't Repeat Yourself
enforce_kiss = true       # Keep It Simple, Stupid
enforce_yagni = true      # You Ain't Gonna Need It

[qdd.profiles.custom]
name = "Our Standards"
max_complexity = 10
max_cognitive = 10
min_coverage = 85
max_tdg = 4
zero_satd = true
zero_dead_code = true
require_doctests = true
require_property_tests = false

[[qdd.profiles.custom.rules]]
name = "no_print_debugging"
description = "Use logging instead of print statements"
severity = "error"
pattern = "print\\("

[[qdd.profiles.custom.rules]]
name = "proper_type_hints"
description = "All public functions must have type hints"
severity = "warning"
pattern = "^def [a-zA-Z_][a-zA-Z0-9_]*\\([^)]*\\)\\s*:"

[qdd.integrations]
enable_pre_commit = true
enable_ci_cd = true
generate_reports = true

[qdd.ai_integration]
# MCP tool configuration
enable_mcp = true
model_context_size = 8192
include_quality_context = true
```

## Troubleshooting

### Common Issues

#### QDD Command Not Found
```bash
error: command 'qdd' not recognized

Solution:
1. Verify PMAT version: pmat --version (requires 2.69.0+)
2. Update PMAT: cargo install pmat --force
3. Check feature flags: pmat --help | grep qdd
```

#### Quality Profile Errors
```bash
error: Profile 'extreme' too restrictive for current codebase

Solutions:
1. Use profile recommendation: pmat qdd validate . --recommend-profile
2. Create custom profile with realistic thresholds
3. Refactor incrementally with relaxed profile first
```

#### Refactoring Failures
```bash
error: Refactoring would break existing functionality

Solutions:
1. Ensure comprehensive test coverage first
2. Use --dry-run to preview changes
3. Refactor smaller code sections incrementally
4. Check rollback options: pmat qdd rollback --list
```

### Performance Optimization

```bash
# For large codebases
pmat qdd validate . --profile standard --parallel --cache-enabled

# Incremental processing
pmat qdd refactor src/ --profile standard --incremental --max-files 10

# Profile validation performance
pmat qdd validate . --profile standard --profile-performance
```

## Summary

Quality-Driven Development (QDD) revolutionizes code creation and maintenance by:

- **Quality-First Approach**: Every line of code meets predefined standards
- **Profile-Driven Development**: Flexible quality standards for different contexts
- **Toyota Way Integration**: Manufacturing excellence principles applied to software
- **Comprehensive Operations**: Create, refactor, enhance, and migrate with quality guarantees
- **CI/CD Integration**: Automated quality gates and validation
- **MCP Compatibility**: AI-driven development with quality constraints

QDD transforms quality from an afterthought into the driving force of development, ensuring maintainable, reliable, and excellent code from day one.

## Next Steps

- [Chapter 15: Advanced TDG Storage and Persistence](ch15-00-tdg-storage.md)
- [Chapter 16: Pre-commit Hooks Management](ch16-00-hooks.md)
- [Chapter 17: Enhanced Auto-Clippy Integration](ch17-00-auto-clippy.md)