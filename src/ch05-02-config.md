# Chapter 5.2: Configuration in Depth

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (All configuration options documented)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 30+ | All configuration options documented |
| ⚠️ Not Implemented | 0 | Planned for future versions |
| ❌ Broken | 0 | Known issues, needs fixing |
| 📋 Planned | 0 | Future roadmap features |

*Last updated: 2025-09-08*  
*PMAT version: pmat 2.64.0*
<!-- DOC_STATUS_END -->

## Configuration Overview

PMAT uses a hierarchical configuration system with multiple levels of precedence:

1. **Command-line arguments** (highest priority)
2. **Environment variables**
3. **Project configuration** (`pmat.toml` in project root)
4. **User configuration** (`~/.config/pmat/config.toml`)
5. **System configuration** (`/etc/pmat/config.toml`)
6. **Default values** (lowest priority)

## Configuration File Format

PMAT uses TOML format for configuration files:

```toml
# pmat.toml - Complete configuration example
[project]
name = "my-project"
version = "1.0.0"
description = "Enterprise application"
languages = ["python", "javascript", "typescript"]

[analysis]
enabled = true
parallel = true
max_threads = 8
incremental = true
cache_enabled = true

[quality]
min_grade = "B+"
fail_on_regression = true
allow_warnings = 10
strict_mode = false

[security]
scan_enabled = true
check_secrets = true
check_dependencies = true
severity_threshold = "high"

[performance]
analyze_complexity = true
memory_analysis = true
hotspot_detection = true
benchmark_enabled = false

[reporting]
formats = ["json", "html", "pdf"]
include_trends = true
compare_baseline = true
output_dir = "reports/"

[cache]
enabled = true
location = ".pmat/cache"
max_size_gb = 5
ttl_hours = 168

[logging]
level = "info"
file = ".pmat/pmat.log"
rotate = true
max_size_mb = 100
```

## Configuration Commands

### Viewing Configuration

```bash
# Show all configuration
pmat config show

# Show specific section
pmat config show analysis

# Get specific value
pmat config get analysis.parallel

# List all available options
pmat config list --available

# Show configuration with sources
pmat config show --with-sources
```

### Setting Configuration

```bash
# Set single value
pmat config set analysis.parallel true
pmat config set quality.min_grade "A-"

# Set nested values
pmat config set security.scan_enabled true
pmat config set cache.max_size_gb 10

# Set array values
pmat config set reporting.formats "json,html,pdf"
pmat config set project.languages "python,go,rust"
```

### Configuration Profiles

```bash
# List profiles
pmat config profiles list

# Create new profile
pmat config profiles create production
pmat config profiles create development
pmat config profiles create ci

# Switch profile
pmat config profiles switch production

# Edit profile
pmat config profiles edit production

# Delete profile
pmat config profiles delete old-profile

# Export profile
pmat config profiles export production > prod-config.toml

# Import profile
pmat config profiles import prod-config.toml --name=production-v2
```

## Configuration Sections

### Project Configuration

```toml
[project]
# Basic project information
name = "my-project"
version = "1.0.0"
description = "Project description"
authors = ["team@company.com"]
license = "MIT"

# Language settings
languages = ["python", "javascript", "typescript", "go"]
primary_language = "python"

# Project structure
source_dirs = ["src", "lib"]
test_dirs = ["tests", "test"]
exclude_dirs = ["vendor", "node_modules", ".venv"]

# Project type
project_type = "application"  # or "library", "framework"
architecture = "microservices"  # or "monolith", "serverless"
```

### Analysis Configuration

```toml
[analysis]
# Core analysis settings
enabled = true
mode = "comprehensive"  # or "standard", "quick", "minimal"
depth = 5  # Analysis depth level

# Performance settings
parallel = true
max_threads = 16
batch_size = 100
timeout_seconds = 3600

# Incremental analysis
incremental = true
track_changes = true
baseline_branch = "main"

# Memory management
streaming_mode = false
max_memory_gb = 8
gc_frequency = 100

# File handling
max_file_size_mb = 10
skip_binary_files = true
follow_symlinks = false
```

### Quality Configuration

```toml
[quality]
# Quality gates
min_grade = "B+"
fail_on_regression = true
regression_threshold = 5  # Percentage

# Violation thresholds
max_critical = 0
max_errors = 5
max_warnings = 20
max_info = 100

# Strictness settings
strict_mode = false
enforce_standards = true
require_documentation = true
require_tests = true

# Complexity thresholds
max_cyclomatic_complexity = 10
max_cognitive_complexity = 15
max_function_length = 50
max_file_length = 500
```

### Security Configuration

```toml
[security]
# Security scanning
scan_enabled = true
scan_depth = "comprehensive"
fail_on_vulnerabilities = true

# Severity settings
severity_threshold = "high"  # or "critical", "medium", "low"
ignore_info_vulnerabilities = true

# Specific checks
check_secrets = true
check_dependencies = true
check_licenses = true
check_owasp = true

# Secret detection
secret_patterns = [
    "api_key",
    "secret_key",
    "password",
    "token",
    "private_key"
]

# CVE database
cve_database_url = "https://nvd.nist.gov/feeds"
update_cve_database = true
cve_update_frequency_hours = 24
```

### Performance Configuration

```toml
[performance]
# Analysis features
analyze_complexity = true
memory_analysis = true
hotspot_detection = true
profile_execution = false

# Thresholds
max_execution_time_ms = 1000
max_memory_usage_mb = 100
max_cpu_usage_percent = 80

# Benchmarking
benchmark_enabled = false
benchmark_iterations = 100
benchmark_warmup = 10
compare_with_baseline = true

# Optimization
suggest_optimizations = true
auto_optimize = false
optimization_level = "moderate"  # or "aggressive", "conservative"
```

### Architecture Configuration

```toml
[architecture]
# Analysis settings
analyze_dependencies = true
detect_patterns = true
validate_layers = true
check_boundaries = true

# Metrics
max_coupling = 0.7
min_cohesion = 0.6
max_depth = 5
circular_dependencies = "error"  # or "warning", "info"

# Pattern detection
patterns_to_detect = [
    "singleton",
    "factory",
    "repository",
    "observer"
]

# Layer validation
layers_config_file = ".pmat/architecture.yaml"
strict_layer_validation = true
```

### Reporting Configuration

```toml
[reporting]
# Output formats
formats = ["json", "html", "pdf", "markdown"]
default_format = "html"

# Report content
include_summary = true
include_details = true
include_trends = true
include_recommendations = true
include_visualizations = true

# Comparison
compare_baseline = true
baseline_file = "baseline-report.json"
show_improvements = true
show_regressions = true

# Output settings
output_dir = "reports/"
timestamp_reports = true
compress_reports = false
```

### Cache Configuration

```toml
[cache]
# Cache settings
enabled = true
location = ".pmat/cache"
fallback_location = "/tmp/pmat-cache"

# Size limits
max_size_gb = 10
max_entries = 10000
max_file_size_mb = 50

# Expiration
ttl_hours = 168  # 1 week
clean_on_startup = false
auto_clean = true
clean_threshold_percent = 90

# Performance
compression = true
compression_level = 6
parallel_reads = true
```

### Integration Configuration

```toml
[integration]
# API server
api_enabled = false
api_port = 8080
api_host = "localhost"
api_auth_required = true

# Webhooks
webhooks_enabled = false
webhook_timeout_seconds = 30
webhook_retry_count = 3

# Notifications
notifications_enabled = false
notification_channels = ["email", "slack"]

[integration.slack]
webhook_url = "${SLACK_WEBHOOK_URL}"
channel = "#code-quality"
mention_on_critical = true

[integration.email]
smtp_server = "smtp.company.com"
smtp_port = 587
from_address = "pmat@company.com"
to_addresses = ["team@company.com"]
```

### AI Configuration

```toml
[ai]
# AI features
enabled = false
provider = "anthropic"  # or "openai", "local"
model = "claude-3-sonnet"
api_key_env = "ANTHROPIC_API_KEY"

# Features
explain_violations = true
suggest_fixes = true
code_review = true
refactoring_suggestions = true

# Settings
confidence_threshold = 0.8
max_suggestions = 5
include_reasoning = true
local_processing = false
```

### Team Configuration

```toml
[team]
# Team settings
name = "backend-team"
standards_file = ".pmat/team-standards.yaml"

# Quality requirements
min_team_grade = "B"
require_review = true
review_threshold = "medium"

# Workflow
auto_assign_reviewers = true
notify_on_violations = true
block_on_critical = true

[team.members]
lead = "lead@company.com"
members = [
    "dev1@company.com",
    "dev2@company.com"
]
```

## Environment Variables

All configuration options can be set via environment variables:

```bash
# Format: PMAT_<SECTION>_<KEY>
export PMAT_ANALYSIS_PARALLEL=true
export PMAT_QUALITY_MIN_GRADE="B+"
export PMAT_SECURITY_SCAN_ENABLED=true
export PMAT_CACHE_MAX_SIZE_GB=10

# Special environment variables
export PMAT_CONFIG_PATH=/custom/path/config.toml
export PMAT_PROFILE=production
export PMAT_LOG_LEVEL=debug
export PMAT_NO_COLOR=1
```

## Profile Examples

### Development Profile

```toml
# ~/.config/pmat/profiles/development.toml
[analysis]
mode = "quick"
parallel = false
incremental = true

[quality]
min_grade = "C"
strict_mode = false

[cache]
enabled = true
location = ".pmat/dev-cache"

[logging]
level = "debug"
```

### CI/CD Profile

```toml
# ~/.config/pmat/profiles/ci.toml
[analysis]
mode = "comprehensive"
parallel = true
max_threads = 8

[quality]
min_grade = "B+"
fail_on_regression = true
strict_mode = true

[reporting]
formats = ["json", "junit"]
output_dir = "ci-reports/"

[cache]
enabled = false  # Fresh analysis each time
```

### Production Profile

```toml
# ~/.config/pmat/profiles/production.toml
[analysis]
mode = "comprehensive"
parallel = true
max_threads = 16

[quality]
min_grade = "A-"
fail_on_regression = true
max_critical = 0

[security]
scan_enabled = true
severity_threshold = "high"
fail_on_vulnerabilities = true

[performance]
benchmark_enabled = true
max_execution_time_ms = 500
```

## Configuration Validation

```bash
# Validate current configuration
pmat config validate

# Validate specific file
pmat config validate --file=custom-config.toml

# Check for deprecated options
pmat config check-deprecated

# Migrate old configuration
pmat config migrate --from=v1 --to=v2
```

## Best Practices

### 1. Use Profiles for Different Environments

```bash
# Development
pmat config profiles switch development
pmat analyze .

# CI/CD
pmat --profile=ci analyze .

# Production audit
pmat --profile=production analyze . --comprehensive
```

### 2. Version Control Configuration

```bash
# Track project configuration
git add pmat.toml
git commit -m "Add PMAT configuration"

# Ignore local overrides
echo ".pmat/local-config.toml" >> .gitignore
```

### 3. Secure Sensitive Values

```toml
# Use environment variables for sensitive data
[integration.slack]
webhook_url = "${SLACK_WEBHOOK_URL}"

[ai]
api_key_env = "ANTHROPIC_API_KEY"  # Reference env var name
```

### 4. Progressive Configuration

Start simple and add complexity as needed:

```toml
# Start with basics
[quality]
min_grade = "C"

# Add more as team matures
[quality]
min_grade = "B+"
fail_on_regression = true
max_critical = 0
```

## Troubleshooting

### Configuration Not Loading

```bash
# Check which config files are loaded
pmat config show --with-sources

# Verify file syntax
pmat config validate --file=pmat.toml

# Debug configuration loading
PMAT_LOG_LEVEL=debug pmat config show
```

### Conflicting Settings

```bash
# See effective configuration
pmat config show --effective

# Check precedence
pmat config get analysis.parallel --show-source
```

### Performance Issues

```bash
# Disable features for faster analysis
pmat config set analysis.mode "quick"
pmat config set cache.enabled true
pmat config set analysis.incremental true
```

## Next Steps

- [Chapter 5.3: Advanced Workflows](ch05-03-workflows.md)
- [Appendix B: Quick Command Reference](appendix-b-commands.md)
- [Appendix C: Configuration Options](appendix-c-config.md)