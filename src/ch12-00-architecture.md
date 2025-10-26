# Chapter 12: Architecture Analysis

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (8/8 examples)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 8 | All architecture analysis configurations tested |
| ⚠️ Not Implemented | 0 | Planned for future versions |
| ❌ Broken | 0 | Known issues, needs fixing |
| 📋 Planned | 0 | Future roadmap features |

*Last updated: 2025-10-26*  
*PMAT version: pmat 2.64.0*  
*Test-Driven: All examples validated in `tests/ch12/test_architecture.sh`*
<!-- DOC_STATUS_END -->

## Understanding Your Codebase Architecture

PMAT's architecture analysis goes beyond individual files to understand the overall structure, patterns, and design quality of your entire codebase. It provides insights into architectural debt, design patterns, dependency relationships, and structural evolution.

## What is Architecture Analysis?

Architecture analysis examines:
- **Structural Patterns**: How components are organized and interact
- **Dependency Management**: Import relationships and coupling analysis
- **Design Patterns**: Identification of common architectural patterns
- **Architectural Debt**: Deviations from intended design
- **Evolution Tracking**: How architecture changes over time
- **Modularity Metrics**: Cohesion and coupling measurements

## Why Architecture Analysis Matters

Poor architecture leads to:
- **Increased Maintenance Cost**: Harder to modify and extend
- **Reduced Developer Productivity**: More time understanding code
- **Higher Bug Rates**: Complex interactions create failure points
- **Technical Debt Accumulation**: Shortcuts compound over time
- **Team Bottlenecks**: Knowledge concentration in complex areas

## Quick Start

Analyze your architecture in minutes:

```bash
# Basic architecture analysis
pmat architecture analyze .

# Generate architecture report
pmat architecture report --format=html --output=arch-report.html

# Check architectural violations
pmat architecture validate --rules=strict

# Visualize dependencies
pmat architecture graph --output=dependencies.svg
```

## Core Analysis Features

### 1. Dependency Analysis

PMAT analyzes import and dependency relationships across your codebase:

```bash
# Analyze all dependencies
pmat architecture deps --project-path .

# Check for circular dependencies
pmat architecture deps --circular --fail-on-cycles

# Analyze dependency depth
pmat architecture deps --depth --max-depth 5

# Generate dependency matrix
pmat architecture deps --matrix --output deps-matrix.json
```

**Example Output:**
```json
{
  "dependencies": {
    "user_service": {
      "imports": ["shared.utils", "database.models", "api_client"],
      "imported_by": ["main", "tests.test_user"],
      "circular_deps": [],
      "dependency_depth": 3,
      "coupling_score": 0.65
    }
  },
  "violations": [
    {
      "type": "circular_dependency",
      "modules": ["auth.service", "user.models"],
      "severity": "error"
    }
  ],
  "metrics": {
    "total_modules": 45,
    "avg_coupling": 0.42,
    "max_depth": 6,
    "circular_count": 1
  }
}
```

### 2. Layer Architecture Validation

Define and validate architectural layers:

```yaml
# .pmat/architecture.yaml
layers:
  - name: "presentation"
    path_patterns: ["*/controllers/*", "*/views/*", "*/templates/*"]
    can_import: ["business", "shared"]
    cannot_import: ["persistence", "infrastructure"]
    
  - name: "business" 
    path_patterns: ["*/services/*", "*/domain/*", "*/use_cases/*"]
    can_import: ["shared", "persistence_interfaces"]
    cannot_import: ["presentation", "infrastructure"]
    
  - name: "persistence"
    path_patterns: ["*/repositories/*", "*/dao/*", "*/models/*"]
    can_import: ["shared"]
    cannot_import: ["presentation", "business"]
    
  - name: "infrastructure"
    path_patterns: ["*/external/*", "*/adapters/*", "*/config/*"]
    can_import: ["shared"]
    cannot_import: ["presentation", "business", "persistence"]

validation_rules:
  - "presentation_layer_only_calls_business"
  - "no_direct_database_access_from_controllers"
  - "business_logic_independent_of_frameworks"
  - "shared_modules_have_no_dependencies"
```

**Validation Command:**
```bash
pmat architecture validate-layers --config .pmat/architecture.yaml
```

### 3. Design Pattern Detection

Automatically identify common design patterns:

```bash
# Detect all patterns
pmat architecture patterns --detect-all

# Look for specific patterns
pmat architecture patterns --detect singleton,factory,observer

# Analyze pattern quality
pmat architecture patterns --quality-check
```

**Detected Patterns:**

**Singleton Pattern:**
```python
# src/config/settings.py - Detected: Singleton Pattern (Score: 95%)
class Settings:
    _instance = None
    _initialized = False
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
    
    def __init__(self):
        if not self._initialized:
            self.load_config()
            Settings._initialized = True
```

**Repository Pattern:**
```python
# src/repositories/user_repository.py - Detected: Repository Pattern (Score: 88%)
from abc import ABC, abstractmethod

class UserRepository(ABC):
    @abstractmethod
    def find_by_id(self, user_id: str) -> Optional[User]:
        pass
    
    @abstractmethod
    def save(self, user: User) -> User:
        pass

class SQLUserRepository(UserRepository):
    def find_by_id(self, user_id: str) -> Optional[User]:
        # Implementation
        pass
```

### 4. Component Coupling Analysis

Measure how tightly coupled your components are:

```bash
# Analyze coupling metrics
pmat architecture coupling --detailed

# Identify highly coupled modules  
pmat architecture coupling --threshold 0.8 --list-violations

# Generate coupling heatmap
pmat architecture coupling --heatmap --output coupling-heatmap.png
```

**Coupling Metrics:**
```
📊 Coupling Analysis Results

🔗 Highly Coupled Modules (Coupling > 0.8):
  - user_service.py (0.92) - Imports from 12 different modules
  - order_processor.py (0.87) - Complex dependency web detected
  - legacy_api.py (0.95) - Monolithic structure identified

📈 Coupling Distribution:
  Low (0.0-0.3):    15 modules (33%)
  Medium (0.3-0.7):  22 modules (49%) 
  High (0.7-1.0):    8 modules (18%)

⚠️  Architectural Debt Indicators:
  - 3 modules exceed recommended coupling (0.7)
  - 1 circular dependency detected
  - Average coupling increased 12% since last month
```

### 5. Module Cohesion Analysis

Measure how focused your modules are:

```bash
# Analyze module cohesion
pmat architecture cohesion --all-modules

# Identify low-cohesion modules
pmat architecture cohesion --threshold 0.6 --list-low-cohesion

# Suggest refactoring opportunities  
pmat architecture cohesion --suggest-refactoring
```

## Advanced Architecture Features

### 1. Microservices Architecture Analysis

For microservices architectures, PMAT provides specialized analysis:

```yaml
# .pmat/microservices.yaml
architecture_type: "microservices"

services:
  - name: "user-service"
    path: "services/user"
    boundaries: ["users", "authentication", "profiles"]
    databases: ["user_db"]
    apis: ["users_api_v1", "auth_api_v1"]
    
  - name: "order-service"  
    path: "services/order"
    boundaries: ["orders", "shopping_cart", "checkout"]
    databases: ["order_db"]
    apis: ["orders_api_v1"]

  - name: "payment-service"
    path: "services/payment" 
    boundaries: ["payments", "billing", "invoices"]
    databases: ["payment_db"]
    apis: ["payments_api_v1"]

constraints:
  database_per_service: true
  no_shared_databases: true
  api_communication_only: true
  async_messaging: "preferred"

integration_patterns:
  event_sourcing: ["order-service", "payment-service"]
  cqrs: ["user-service"]
  saga_orchestration: true
```

**Analysis Commands:**
```bash
# Validate microservices boundaries
pmat architecture microservices --validate-boundaries

# Check service coupling
pmat architecture microservices --coupling-analysis

# Analyze API dependencies
pmat architecture microservices --api-dependencies

# Generate service map
pmat architecture microservices --service-map --output services.png
```

### 2. Domain-Driven Design Analysis

Analyze DDD patterns and bounded contexts:

```bash
# Detect bounded contexts
pmat architecture ddd --detect-contexts

# Validate domain models
pmat architecture ddd --validate-models

# Check aggregate consistency
pmat architecture ddd --check-aggregates

# Analyze domain events
pmat architecture ddd --analyze-events
```

**DDD Analysis Output:**
```
🏗️  Domain-Driven Design Analysis

📦 Bounded Contexts Detected:
  1. User Management Context
     - Entities: User, Profile, Preferences
     - Value Objects: Email, Address, PhoneNumber
     - Aggregates: UserAggregate (root: User)
     - Services: UserService, AuthenticationService

  2. Order Management Context
     - Entities: Order, OrderItem, ShoppingCart
     - Value Objects: Money, Quantity, ProductId
     - Aggregates: OrderAggregate (root: Order)
     - Services: OrderService, PricingService

  3. Payment Context
     - Entities: Payment, Invoice, Transaction
     - Value Objects: PaymentMethod, Amount
     - Aggregates: PaymentAggregate (root: Payment)
     - Services: PaymentProcessor, BillingService

⚠️  DDD Violations Found:
  - UserService directly accessing OrderItem (cross-context boundary)
  - Payment entity being modified outside its aggregate
  - Missing domain events for order state changes
```

### 3. Architecture Evolution Tracking

Track how your architecture changes over time:

```bash
# Initialize architecture tracking
pmat architecture track --init

# Compare with previous version
pmat architecture compare --baseline=main --current=feature-branch

# Generate evolution report
pmat architecture evolution --period=6months --format=html
```

**Evolution Report:**
```
📈 Architecture Evolution Report (Last 6 Months)

🔄 Structural Changes:
  - New modules: 15 (+25%)
  - Deleted modules: 3 (-5%)
  - Refactored modules: 8 (major changes)

📊 Coupling Trends:
  - Average coupling: 0.45 → 0.38 (📉 -15% improvement)
  - High-coupling modules: 12 → 6 (📉 -50% reduction)

🏗️  Pattern Adoption:
  - Repository pattern: 3 → 8 implementations
  - Factory pattern: 1 → 4 implementations
  - Observer pattern: 0 → 2 implementations

⚠️  Architecture Debt:
  - Circular dependencies: 2 → 1 (📉 -50%)
  - Layer violations: 5 → 2 (📉 -60%)
  - God classes: 1 → 0 (📉 -100%)
```

## Configuration and Customization

### Advanced Architecture Configuration

```toml
# pmat.toml
[architecture]
enabled = true
analyze_dependencies = true
detect_patterns = true
validate_layers = true
track_evolution = true

[architecture.analysis]
max_coupling_threshold = 0.7
min_cohesion_threshold = 0.6
max_dependency_depth = 5
circular_dependencies = "error"

[architecture.patterns]
detect_all = true
confidence_threshold = 0.8
custom_patterns = [
    "mvc_pattern",
    "hexagonal_architecture",
    "event_sourcing"
]

[architecture.layers]
config_file = ".pmat/architecture.yaml"
strict_validation = true
allow_test_violations = true

[architecture.metrics]
calculate_maintainability_index = true
track_technical_debt = true
complexity_analysis = true

[architecture.visualization]
generate_graphs = true
output_format = "svg"
include_metrics = true
color_by_coupling = true

[architecture.reporting]
include_recommendations = true
explain_violations = true
suggest_refactoring = true
benchmark_against_industry = true
```

### Custom Pattern Detection

Define custom architectural patterns:

```yaml
# .pmat/patterns/custom-patterns.yaml
patterns:
  - name: "hexagonal_architecture"
    description: "Ports and Adapters pattern"
    confidence_threshold: 0.85
    
    structure:
      core_domain:
        path_patterns: ["*/domain/*", "*/core/*"]
        must_not_depend_on: ["adapters", "infrastructure"]
        
      ports:
        path_patterns: ["*/ports/*", "*/interfaces/*"]
        must_be: "abstract_classes_or_protocols"
        
      adapters:
        path_patterns: ["*/adapters/*", "*/infrastructure/*"]
        must_implement: "ports"
        can_depend_on: ["external_libraries"]
        
    validation_rules:
      - "core_domain_independent_of_frameworks"
      - "all_external_access_through_ports"
      - "adapters_implement_specific_ports"

  - name: "event_sourcing"
    description: "Event Sourcing pattern implementation"
    
    required_components:
      - name: "event_store"
        must_exist: true
        patterns: ["*EventStore*", "*event_store*"]
        
      - name: "aggregates"
        must_exist: true
        patterns: ["*Aggregate*", "*aggregate*"]
        methods: ["apply_event", "get_uncommitted_events"]
        
      - name: "events"
        must_exist: true
        patterns: ["*Event*", "*event*"]
        inherits_from: ["DomainEvent", "Event"]
        
      - name: "event_handlers"
        patterns: ["*Handler*", "*handler*"]
        methods: ["handle"]
        
    validation_rules:
      - "events_are_immutable"
      - "aggregates_raise_events"
      - "event_store_persists_events"
      - "handlers_are_idempotent"
```

## Real-World Analysis Examples

### Example 1: E-commerce Platform Analysis

```bash
# Comprehensive architecture analysis of e-commerce platform
pmat architecture analyze ./ecommerce-platform \
  --include-patterns \
  --validate-layers \
  --check-coupling \
  --generate-report
```

**Analysis Results:**
```
🛒 E-commerce Platform Architecture Analysis

📁 Project Structure:
  ├── presentation/         (Web API, Controllers)
  ├── business/            (Domain Logic, Services)
  ├── infrastructure/      (Database, External APIs)
  └── shared/             (Common Utilities)

🏗️  Detected Patterns:
  ✅ Repository Pattern (8 implementations, avg quality: 87%)
  ✅ Factory Pattern (3 implementations, avg quality: 92%)
  ✅ Strategy Pattern (2 implementations, avg quality: 83%)
  ⚠️  Singleton Pattern (1 implementation, potential bottleneck)

📊 Architecture Metrics:
  - Overall coupling: 0.43 (Good)
  - Average cohesion: 0.78 (Excellent)
  - Dependency depth: 4 (Acceptable)
  - Cyclic complexity: Low

⚠️  Issues Detected:
  - OrderController directly accessing PaymentRepository (layer violation)
  - User and Order modules circularly dependent
  - ShoppingCart class has too many responsibilities (SRP violation)

💡 Recommendations:
  1. Introduce PaymentService to decouple controller from repository
  2. Extract common interfaces to break circular dependency
  3. Split ShoppingCart into Cart and CartCalculator
  4. Consider introducing Domain Events for order processing
```

### Example 2: Microservices Boundary Analysis

```bash
# Analyze microservices for boundary violations
pmat architecture microservices \
  --config .pmat/microservices.yaml \
  --boundary-analysis \
  --cross-service-calls
```

**Boundary Violations Report:**
```
🚫 Service Boundary Violations Detected

1. User Service → Order Database
   File: user_service/analytics.py:45
   Issue: Direct database access across service boundary
   Fix: Use Order Service API instead

2. Payment Service → User Service Internal
   File: payment_service/billing.py:123
   Issue: Importing internal user service modules
   Fix: Use user service public API

3. Shared Database Access
   Issue: user_db accessed by both User and Notification services
   Fix: Extract shared data to separate service or use events

📈 Cross-Service Communication Analysis:
   - Synchronous calls: 15 (67%)
   - Asynchronous events: 7 (33%)
   - Recommendation: Increase async communication to 60%

🔄 Data Flow Issues:
   - Circular data dependencies between User and Order services
   - Recommendation: Implement eventual consistency with domain events
```

### Example 3: Legacy Code Architecture Assessment

```bash
# Assess legacy codebase for modernization opportunities
pmat architecture legacy-assessment \
  --detect-anti-patterns \
  --modernization-suggestions \
  --refactoring-priorities
```

**Legacy Assessment:**
```
🕰️  Legacy Code Architecture Assessment

🚨 Anti-Patterns Detected:
  1. God Class: SystemManager (847 lines, 23 responsibilities)
     Priority: High - Split into domain-specific managers
     
  2. Spaghetti Code: ReportGenerator (circular imports, no clear structure)
     Priority: High - Refactor using Strategy pattern
     
  3. Magic Numbers: 47 hardcoded values across 12 files
     Priority: Medium - Extract to configuration
     
  4. Shotgun Surgery: User model changes require 15 file modifications
     Priority: High - Implement proper encapsulation

📊 Modernization Opportunities:
  - Extract 5 microservices from monolithic structure
  - Implement event-driven architecture for order processing
  - Introduce API gateway for external communication
  - Add domain-driven design patterns

🎯 Refactoring Priority Matrix:
  High Impact, Low Effort:
    - Extract configuration constants
    - Add logging facades
    - Implement repository pattern for data access
    
  High Impact, High Effort:
    - Decompose God classes
    - Extract microservices
    - Implement domain events
    
  Low Impact, Low Effort:
    - Rename misleading variables
    - Add type hints
    - Remove dead code
```

## CI/CD Integration

### GitHub Actions Workflow

```yaml
# .github/workflows/architecture-analysis.yml
name: Architecture Analysis

on:
  pull_request:
    paths: ['src/**', 'services/**']
  push:
    branches: [main, develop]

jobs:
  architecture-analysis:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Need full history for evolution analysis
          
      - name: Install PMAT
        run: cargo install pmat
          
      - name: Run Architecture Analysis
        run: |
          # Full architecture analysis
          pmat architecture analyze . \
            --format json \
            --output architecture-report.json
            
          # Validate architectural constraints
          pmat architecture validate-layers \
            --config .pmat/architecture.yaml \
            --fail-on-violations
            
          # Check for architecture debt
          pmat architecture debt-analysis \
            --threshold-increase 10% \
            --fail-on-regression
            
      - name: Generate Architecture Visualization
        run: |
          pmat architecture graph \
            --output dependency-graph.svg \
            --include-metrics \
            --highlight-violations
            
      - name: Compare with Baseline
        if: github.event_name == 'pull_request'
        run: |
          # Compare architecture with main branch
          pmat architecture compare \
            --baseline origin/main \
            --current HEAD \
            --output comparison-report.md
            
      - name: Comment PR with Results
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const report = JSON.parse(fs.readFileSync('architecture-report.json', 'utf8'));
            const comparison = fs.readFileSync('comparison-report.md', 'utf8');
            
            const summary = {
              coupling: report.metrics.average_coupling,
              cohesion: report.metrics.average_cohesion,
              violations: report.violations.length,
              patterns: report.detected_patterns.length
            };
            
            const comment = `## 🏗️ Architecture Analysis Results
            
            **Metrics Summary:**
            - Average Coupling: ${summary.coupling.toFixed(2)}
            - Average Cohesion: ${summary.cohesion.toFixed(2)}
            - Violations: ${summary.violations}
            - Detected Patterns: ${summary.patterns}
            
            **Architecture Changes:**
            ${comparison}
            
            <details>
            <summary>📊 Full Report</summary>
            
            \`\`\`json
            ${JSON.stringify(report, null, 2)}
            \`\`\`
            </details>`;
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: comment
            });
            
      - name: Upload Reports
        uses: actions/upload-artifact@v3
        with:
          name: architecture-reports
          path: |
            architecture-report.json
            dependency-graph.svg
            comparison-report.md
```

## Troubleshooting

### Performance Issues

```bash
# For large codebases, optimize analysis
pmat architecture analyze . \
  --parallel \
  --max-threads 8 \
  --skip-generated-files \
  --cache-enabled

# Focus analysis on specific areas
pmat architecture analyze src/core \
  --exclude "tests/" \
  --exclude "vendor/" \
  --shallow-analysis
```

### Complex Dependency Graphs

```bash
# Simplify visualization for complex projects
pmat architecture graph \
  --max-depth 3 \
  --group-by-package \
  --hide-low-coupling \
  --output simplified-graph.svg
```

### False Architecture Violations

```yaml
# .pmat/architecture-exceptions.yaml
exceptions:
  layer_violations:
    - file: "controllers/legacy_controller.py"
      reason: "Legacy code - planned for refactoring"
      expires: "2025-12-31"
      
    - pattern: "*/migrations/*"
      reason: "Database migrations need direct model access"
      
  circular_dependencies:
    - modules: ["user.models", "auth.models"]
      reason: "Historical coupling - breaking in v2.0"
      tracking_issue: "ARCH-123"
      
  pattern_violations:
    - file: "utils/singleton_config.py"
      pattern: "singleton"
      reason: "Configuration requires global state"
```

## Best Practices

### 1. Architecture Monitoring

```bash
# Set up continuous architecture monitoring
cat > .github/workflows/architecture-monitor.yml << 'EOF'
# Monitor architecture metrics daily
- cron: '0 6 * * *'  # 6 AM daily
  run: |
    pmat architecture analyze . --track-evolution
    pmat architecture debt-check --alert-threshold 15%
EOF
```

### 2. Architecture Decision Records

```bash
# Generate ADR from architecture analysis
pmat architecture adr-suggest \
  --based-on-violations \
  --output docs/architecture/adr/
```

### 3. Team Architecture Reviews

```bash
# Prepare architecture review materials
pmat architecture review-package \
  --include-metrics \
  --include-suggestions \
  --include-visualization \
  --output architecture-review-$(date +%Y%m%d).zip
```

## Summary

PMAT's architecture analysis provides:
- **Comprehensive Structure Analysis**: Understand your entire codebase architecture
- **Design Pattern Detection**: Automatically identify and validate architectural patterns
- **Dependency Management**: Track and optimize component relationships
- **Evolution Tracking**: Monitor how your architecture changes over time
- **Violation Detection**: Catch architectural debt before it becomes technical debt
- **Automated Recommendations**: Get specific suggestions for architectural improvements

With architecture analysis, you can maintain clean, maintainable codebases that scale with your team and requirements.

## Next Steps

- [Chapter 13: Performance Analysis](ch13-00-performance.md)
- [Chapter 14: Large Codebase Optimization](ch14-00-large-codebases.md)
- [Appendix I: Architecture Patterns Reference](appendix-i-architecture-patterns.md)