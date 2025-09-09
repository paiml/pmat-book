# Chapter 6: The Scaffold Command - Project and Agent Generation

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (8/8 examples)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 8 | All scaffold features tested |
| ⚠️ Not Implemented | 0 | Planned for future versions |
| ❌ Broken | 0 | Known issues, needs fixing |
| 📋 Planned | 0 | Future roadmap features |

*Last updated: 2025-09-09*  
*PMAT version: pmat 2.69.0*  
*Test-Driven: All examples validated in `tests/ch06/test_scaffold.sh`*
<!-- DOC_STATUS_END -->

## Automated Project and Agent Generation

The `pmat scaffold` command provides powerful scaffolding capabilities for creating complete projects and sophisticated MCP agents. It automates the tedious setup process while ensuring best practices, proper structure, and production-ready code.

## Project Scaffolding

### Basic Project Setup

Generate complete project structures with toolchain-specific templates:

```bash
# Scaffold a Rust project
pmat scaffold project rust

# Scaffold with specific templates
pmat scaffold project rust --templates=makefile,readme,gitignore

# Scaffold with parameters
pmat scaffold project rust \
    --templates=cli,lib \
    --param name=my-tool \
    --param author="Your Name"
```

### Supported Toolchains

PMAT supports multiple development toolchains:

```bash
# Rust projects
pmat scaffold project rust --templates=cli,lib,makefile

# Deno/TypeScript projects  
pmat scaffold project deno --templates=api,frontend,makefile

# Python with uv package manager
pmat scaffold project python-uv --templates=cli,lib,requirements
```

### Available Templates

Each toolchain provides specialized templates:

**Rust Templates:**
- `cli` - Command-line application with clap
- `lib` - Library crate with proper structure
- `makefile` - Comprehensive build automation
- `readme` - Documentation with examples
- `gitignore` - Rust-specific ignore patterns

**Deno Templates:**
- `api` - RESTful API server
- `frontend` - Web frontend application
- `makefile` - Deno-specific build tasks
- `readme` - TypeScript project documentation

**Python Templates:**
- `cli` - Click-based command-line tool
- `lib` - Package with proper structure
- `requirements` - Dependency management
- `makefile` - Python development tasks

### Example: Full Rust Project

```bash
pmat scaffold project rust \
    --templates=cli,makefile,readme,gitignore \
    --param name=code-analyzer \
    --param author="Development Team" \
    --param description="Static code analysis tool"
```

**Generated Structure:**
```
code-analyzer/
├── Cargo.toml
├── src/
│   └── main.rs
├── Makefile
├── README.md
├── .gitignore
└── tests/
    └── cli_tests.rs
```

**Generated Cargo.toml:**
```toml
[package]
name = "code-analyzer"
version = "0.1.0"
edition = "2021"
authors = ["Development Team"]
description = "Static code analysis tool"

[dependencies]
clap = { version = "4.0", features = ["derive"] }
anyhow = "1.0"
tokio = { version = "1.0", features = ["full"] }
```

### Parallel Generation

For large projects, use parallel processing:

```bash
# Use all CPU cores
pmat scaffold project rust --templates=cli,lib,api,frontend --parallel 8

# Automatic detection
pmat scaffold project rust --templates=cli,lib,api,frontend
# Automatically uses available CPU cores
```

## Agent Scaffolding

### MCP Agent Types

PMAT can generate sophisticated MCP agents with different architectures:

```bash
# List available agent templates
pmat scaffold list-templates
```

**Output:**
```
📦 Available Agent Templates:

  • mcp-server - Basic MCP server with tools and prompts
  • state-machine - Deterministic state machine agent
  • hybrid - Hybrid agent with deterministic core  
  • calculator - Example calculator agent
  • custom - Custom template from path

Total: 5 templates available
```

### Basic MCP Agent

Generate a standard MCP server agent:

```bash
# Basic MCP agent
pmat scaffold agent \
    --name payment-processor \
    --template mcp-server \
    --features logging,monitoring

# With specific output directory
pmat scaffold agent \
    --name payment-processor \
    --template mcp-server \
    --output ./agents/payment \
    --force
```

**Generated Structure:**
```
payment-processor/
├── Cargo.toml
├── src/
│   ├── main.rs
│   ├── tools/
│   │   ├── mod.rs
│   │   ├── validate.rs
│   │   └── process.rs
│   ├── prompts/
│   │   ├── mod.rs
│   │   └── payment.rs
│   └── lib.rs
├── tests/
│   ├── integration.rs
│   └── tools/
├── README.md
└── .gitignore
```

### State Machine Agent

For deterministic behavior, use state machine agents:

```bash
pmat scaffold agent \
    --name order-processor \
    --template state-machine \
    --features logging,persistence,monitoring \
    --quality extreme
```

**Key Features:**
- Deterministic state transitions
- Formal verification support
- Property-based testing
- Comprehensive error handling
- Event sourcing capabilities

**Generated State Machine:**
```rust
#[derive(Debug, Clone, PartialEq)]
pub enum OrderState {
    Pending,
    Validated,
    Processing,
    Fulfilled,
    Failed,
}

#[derive(Debug, Clone)]
pub enum OrderEvent {
    Validate(OrderData),
    Process,
    Fulfill,
    Fail(String),
}

impl StateMachine for OrderProcessor {
    type State = OrderState;
    type Event = OrderEvent;
    type Error = ProcessingError;

    fn transition(&self, state: &Self::State, event: Self::Event) 
        -> Result<Self::State, Self::Error> {
        match (state, event) {
            (OrderState::Pending, OrderEvent::Validate(_)) => {
                Ok(OrderState::Validated)
            }
            (OrderState::Validated, OrderEvent::Process) => {
                Ok(OrderState::Processing)
            }
            // ... more transitions
        }
    }
}
```

### Hybrid Agents

Combine deterministic cores with AI capabilities:

```bash
pmat scaffold agent \
    --name smart-assistant \
    --template hybrid \
    --deterministic-core state-machine \
    --quality extreme \
    --features logging,monitoring,ai-integration
```

**Architecture:**
```
Smart Assistant (Hybrid Agent)
├── Deterministic Core (State Machine)
│   ├── Input validation
│   ├── State management
│   ├── Error handling
│   └── Safety guarantees
└── AI Wrapper (LLM Integration)
    ├── Natural language processing
    ├── Context understanding
    ├── Response generation
    └── Learning adaptation
```

### Agent Features

Customize agents with specific features:

**Available Features:**
- `logging` - Structured logging with tracing
- `monitoring` - Metrics and health checks
- `persistence` - State persistence layer
- `ai-integration` - LLM integration capabilities
- `testing` - Property-based test generation
- `documentation` - Auto-generated docs

```bash
# Full-featured agent
pmat scaffold agent \
    --name production-agent \
    --template hybrid \
    --features logging,monitoring,persistence,testing \
    --quality extreme
```

### Quality Levels

Set quality standards for generated code:

```bash
# Quality levels: standard, strict, extreme
pmat scaffold agent \
    --name critical-system \
    --template state-machine \
    --quality extreme
```

**Quality Level Comparison:**

| Aspect | Standard | Strict | Extreme |
|--------|----------|---------|---------|
| Error Handling | Basic | Comprehensive | Exhaustive |
| Testing | Unit tests | Property-based | Formal verification |
| Documentation | Minimal | Detailed | Complete |
| Performance | Good | Optimized | Maximum |
| Safety | Safe | Paranoid | Provably correct |

### Dry Run Mode

Preview generated code without creating files:

```bash
pmat scaffold agent \
    --name preview-agent \
    --template mcp-server \
    --features logging,monitoring \
    --dry-run
```

**Output:**
```
🔍 Dry Run: Would generate MCP agent 'preview-agent'

Template: mcp-server
Features: logging, monitoring  
Quality Level: strict

Files that would be generated:
  📄 src/main.rs (325 lines)
  📄 Cargo.toml (45 lines)
  📄 src/tools/mod.rs (125 lines)
  📄 src/prompts/mod.rs (89 lines)
  📄 tests/integration.rs (156 lines)
  📄 README.md (234 lines)
  📄 .gitignore (23 lines)

Total: 7 files, 997 lines

Quality Checks:
  ✅ Error handling: Comprehensive
  ✅ Testing: Property-based
  ✅ Documentation: Complete
  ✅ Performance: Optimized
```

## Interactive Mode

### Guided Agent Creation

Use interactive mode for step-by-step guidance:

```bash
pmat scaffold agent --interactive
```

**Interactive Flow:**
```
🎯 Interactive Agent Scaffolding

? Agent name: payment-processor
? Template type: 
  ❯ mcp-server
    state-machine  
    hybrid
    calculator
    custom

? Features (multi-select):
  ✅ logging
  ✅ monitoring
  ❯ persistence
    ai-integration
    testing

? Quality level:
    standard
  ❯ strict
    extreme

? Output directory: ./payment-processor

Preview:
- Template: mcp-server
- Features: logging, monitoring, persistence
- Quality: strict
- Files: 12 files, 1,456 lines

? Continue? (Y/n) y

✅ Agent 'payment-processor' generated successfully!
```

### Custom Templates

Use your own templates:

```bash
# From local path
pmat scaffold agent \
    --name custom-agent \
    --template custom:/path/to/template

# From URL (future feature)
pmat scaffold agent \
    --name custom-agent \
    --template custom:https://github.com/user/agent-template
```

## Template Validation

### Validate Existing Templates

Ensure template quality before using:

```bash
# Validate a template file
pmat scaffold validate-template path/to/template.json

# Validate all templates in directory
pmat scaffold validate-template templates/
```

**Validation Output:**
```
✅ Template Validation Report

Template: advanced-mcp-server
Format: Valid JSON
Schema: Compliant with v2.0 spec

Structure Checks:
  ✅ Required fields present
  ✅ File templates valid
  ✅ Dependencies resolvable
  ✅ Feature compatibility

Quality Checks:
  ✅ Code patterns follow best practices
  ✅ Error handling comprehensive
  ✅ Tests included
  ✅ Documentation complete

Warnings: 0
Errors: 0

Rating: A+ (Production Ready)
```

## Advanced Scaffolding

### Multi-Agent Systems

Generate multiple coordinated agents:

```bash
# Generate coordinator
pmat scaffold agent \
    --name system-coordinator \
    --template state-machine \
    --features coordination,monitoring

# Generate worker agents
pmat scaffold agent \
    --name data-processor \
    --template mcp-server \
    --features processing,persistence

pmat scaffold agent \
    --name notification-sender \
    --template mcp-server \
    --features messaging,logging
```

### Configuration-Driven Scaffolding

Use configuration files for complex setups:

```yaml
# scaffold-config.yaml
project:
  name: "enterprise-system"
  toolchain: "rust"
  
agents:
  - name: "api-gateway"
    template: "hybrid"
    features: ["logging", "monitoring", "rate-limiting"]
    quality: "extreme"
    
  - name: "data-processor" 
    template: "state-machine"
    features: ["persistence", "monitoring"]
    quality: "strict"
    
templates:
  - "makefile"
  - "readme"
  - "docker"
  - "ci-cd"
```

```bash
pmat scaffold --config scaffold-config.yaml
```

## Integration with Development Workflow

### Git Integration

Scaffolded projects include proper Git setup:

```bash
# Projects include .gitignore
pmat scaffold project rust --templates=gitignore

# Automatic git initialization
pmat scaffold project rust --git-init

# Initial commit
pmat scaffold project rust --git-init --initial-commit
```

### CI/CD Integration

Generated projects include workflow files:

```bash
# Include GitHub Actions
pmat scaffold project rust --templates=github-actions

# Include GitLab CI
pmat scaffold project rust --templates=gitlab-ci

# Include Jenkins pipeline
pmat scaffold project rust --templates=jenkins
```

**Generated GitHub Actions:**
```yaml
name: CI/CD Pipeline

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Rust
        uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
      - name: Run tests
        run: cargo test
      - name: Check formatting
        run: cargo fmt -- --check
      - name: Run clippy
        run: cargo clippy -- -D warnings
```

### IDE Configuration

Include IDE-specific configurations:

```bash
# VS Code configuration
pmat scaffold project rust --templates=vscode

# IntelliJ/CLion configuration  
pmat scaffold project rust --templates=intellij
```

## Best Practices

### Project Structure

1. **Consistent Layout**: Use standard directory structures
2. **Clear Separation**: Separate concerns (lib vs binary, tests vs src)
3. **Documentation**: Always include README and inline docs
4. **Testing**: Include test framework and example tests

### Agent Development

1. **Start Simple**: Begin with basic MCP server template
2. **Add Features Gradually**: Enable features as needed
3. **Test Early**: Use property-based testing for reliability
4. **Monitor Always**: Include logging and monitoring from start

### Template Management

1. **Validate Templates**: Always validate before using
2. **Version Control**: Keep templates in version control
3. **Test Generation**: Test generated code regularly
4. **Document Changes**: Track template modifications

## Troubleshooting

### Common Issues

#### Permission Errors
```bash
# Fix permissions
pmat scaffold agent --name test --template mcp-server --force

# Use different output directory
pmat scaffold agent --name test --template mcp-server --output ~/agents/test
```

#### Template Not Found
```bash
# List available templates
pmat scaffold list-templates

# Update template registry
pmat scaffold --update-templates

# Use absolute path for custom templates
pmat scaffold agent --template custom:/absolute/path/to/template
```

#### Generation Failures
```bash
# Use dry-run to debug
pmat scaffold agent --name debug --template mcp-server --dry-run

# Check template validation
pmat scaffold validate-template path/to/template

# Enable verbose output
pmat --verbose scaffold agent --name debug --template mcp-server
```

## Configuration

### Global Configuration

```toml
# ~/.pmat/scaffold.toml

[defaults]
quality_level = "strict"
author = "Your Name"
email = "your.email@domain.com"

[templates]
registry_path = "~/.pmat/templates"
auto_update = true
custom_paths = [
    "~/my-templates",
    "/company/shared-templates"
]

[generation]
parallel_jobs = 8
backup_existing = true
format_generated = true
```

### Project Configuration

```toml
# .pmat/scaffold.toml (in project root)

[project]
name = "my-project"
toolchain = "rust"
default_templates = ["makefile", "readme", "gitignore"]

[agents]
default_features = ["logging", "monitoring"]
default_quality = "strict"
output_directory = "./agents"
```

## Summary

The `pmat scaffold` command transforms development workflow by automating:

- **Project Setup**: Complete project structures with best practices
- **Agent Generation**: Sophisticated MCP agents with various architectures
- **Template Management**: Validation and customization of generation templates
- **Quality Assurance**: Built-in quality levels and testing frameworks
- **Integration**: Seamless CI/CD and IDE configuration

Use scaffolding to:
1. **Accelerate Development**: Skip repetitive setup tasks
2. **Ensure Consistency**: Standardize project structures
3. **Improve Quality**: Include testing and monitoring from start
4. **Enable Innovation**: Focus on business logic, not boilerplate

## Next Steps

- [Chapter 7: Quality Gates](ch07-00-quality-gate.md) - Automate quality enforcement
- [Chapter 4: Technical Debt Grading](ch04-01-tdg.md) - Quality measurement
- [Chapter 5: Analyze Suite](ch05-00-analyze-suite.md) - Code analysis tools