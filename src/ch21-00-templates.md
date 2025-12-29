# Chapter 21: Template Generation and Project Scaffolding

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (16/16 examples)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 16 | Ready for production use |
| ⚠️ Not Implemented | 0 | Planned for future versions |
| ❌ Broken | 0 | Known issues, needs fixing |
| 📋 Planned | 0 | Future roadmap features |

*Last updated: 2025-09-12*  
*PMAT version: pmat 2.213.1*
<!-- DOC_STATUS_END -->

## The Problem

Starting new projects involves repetitive boilerplate setup, configuration files, directory structures, and dependency management. Teams often copy existing projects and manually modify them, leading to inconsistency, outdated patterns, and missed best practices. Developers need a standardized, efficient way to generate projects with quality standards built-in from the start.

## Core Concepts

### Template System Architecture

PMAT's template generation provides:
- **Curated Templates**: Production-ready templates for various project types
- **Parameter Validation**: Type-safe template parameters with validation
- **Multi-Language Support**: Templates for Rust, Python, TypeScript, Go, and more
- **Agent Scaffolding**: MCP agent templates with deterministic behavior
- **Quality Standards**: Built-in best practices and quality gates
- **Customization**: Flexible configuration and parameter overrides

### Template Categories

```
Templates
├── Languages
│   ├── Rust (cli, web, lib, agent)
│   ├── Python (api, ml, cli, package)
│   ├── TypeScript (react, node, deno, lib)
│   ├── Go (api, cli, grpc, lambda)
│   └── Java (spring, quarkus, lib)
├── Frameworks
│   ├── Web (actix, fastapi, express, gin)
│   ├── ML (pytorch, tensorflow, sklearn)
│   └── Mobile (flutter, react-native)
└── Specialized
    ├── MCP Agents (tool, analyzer, converter)
    ├── Microservices (rest, grpc, graphql)
    └── Data (etl, streaming, batch)
```

## Listing and Searching Templates

### List All Available Templates

```bash
# List all templates in table format
pmat list

# List with detailed information
pmat list --verbose

# JSON format for automation
pmat list --format json

# YAML format
pmat list --format yaml
```

**Example Output:**
```
📚 Available Templates
=====================

Rust Templates:
┌─────────────┬──────────────┬─────────────────────────────────┐
│ Template    │ Category     │ Description                     │
├─────────────┼──────────────┼─────────────────────────────────┤
│ rust/cli    │ Application  │ CLI app with clap and tokio    │
│ rust/web    │ Web          │ Actix-web REST API server      │
│ rust/lib    │ Library      │ Rust library with tests        │
│ rust/agent  │ MCP          │ Deterministic MCP agent        │
│ rust/wasm   │ WebAssembly  │ WASM module with bindings      │
└─────────────┴──────────────┴─────────────────────────────────┘

Python Templates:
┌─────────────┬──────────────┬─────────────────────────────────┐
│ Template    │ Category     │ Description                     │
├─────────────┼──────────────┼─────────────────────────────────┤
│ python/api  │ Web          │ FastAPI with async support     │
│ python/ml   │ ML           │ ML project with PyTorch        │
│ python/cli  │ Application  │ Click CLI with rich output     │
│ python/pkg  │ Library      │ Python package with Poetry     │
└─────────────┴──────────────┴─────────────────────────────────┘

Total: 25 templates available
```

### Search Templates

```bash
# Search for web-related templates
pmat search "web"

# Search with result limit
pmat search "api" --limit 10

# Search within specific toolchain
pmat search "server" --toolchain rust
```

**Search Results Example:**
```
🔍 Search Results for "web"
==========================

Found 8 matching templates:

1. rust/web - Actix-web REST API server
   Tags: [rust, web, api, async, actix]
   
2. python/api - FastAPI with async support
   Tags: [python, web, api, fastapi, async]
   
3. typescript/react - React SPA with TypeScript
   Tags: [typescript, web, frontend, react]
   
4. go/gin - Gin web framework API
   Tags: [go, web, api, gin, middleware]

Use 'pmat generate <category> <template>' to create project
```

### Filter by Category

```bash
# List only Rust templates
pmat list --category rust

# List only web frameworks
pmat list --category web

# Filter by toolchain
pmat list --toolchain python
```

## Generating Single Templates

### Basic Template Generation

```bash
# Generate a Rust CLI application
pmat generate rust cli --param name=my-cli --output main.rs

# Short form with aliases
pmat gen rust cli -p name=my-cli -o main.rs

# Generate with multiple parameters
pmat generate python api \
  --param name=my-api \
  --param port=8000 \
  --param database=postgres \
  --output app.py
```

**Generated Template Example (Rust CLI):**
```rust
use clap::{Parser, Subcommand};
use anyhow::Result;

#[derive(Parser)]
#[command(name = "my-cli")]
#[command(about = "A CLI application generated by PMAT", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
    
    /// Enable verbose output
    #[arg(short, long)]
    verbose: bool,
}

#[derive(Subcommand)]
enum Commands {
    /// Process data with specified options
    Process {
        /// Input file path
        #[arg(short, long)]
        input: String,
        
        /// Output file path
        #[arg(short, long)]
        output: Option<String>,
    },
    
    /// Analyze and report metrics
    Analyze {
        /// Target directory
        #[arg(short, long, default_value = ".")]
        path: String,
    },
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    
    if cli.verbose {
        env_logger::Builder::from_env(env_logger::Env::default()
            .default_filter_or("debug"))
            .init();
    }
    
    match cli.command {
        Commands::Process { input, output } => {
            process_data(&input, output.as_deref())?;
        }
        Commands::Analyze { path } => {
            analyze_directory(&path)?;
        }
    }
    
    Ok(())
}

fn process_data(input: &str, output: Option<&str>) -> Result<()> {
    println!("Processing: {}", input);
    // Implementation here
    Ok(())
}

fn analyze_directory(path: &str) -> Result<()> {
    println!("Analyzing: {}", path);
    // Implementation here
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_process_data() {
        assert!(process_data("test.txt", None).is_ok());
    }
    
    #[test]
    fn test_analyze_directory() {
        assert!(analyze_directory(".").is_ok());
    }
}
```

### Parameter Validation

```bash
# Validate parameters before generation
pmat validate rust cli --param name=my-cli

# Check required parameters
pmat validate python api

# Output:
# ❌ Missing required parameters:
# - name: Project name (string, required)
# - port: Server port (integer, default: 8000)
# - database: Database type (enum: postgres|mysql|sqlite)
```

### Advanced Generation Options

```bash
# Create parent directories if needed
pmat generate rust web \
  --param name=api-server \
  --output src/servers/api/main.rs \
  --create-dirs

# Generate from custom template path
pmat generate custom my-template \
  --template-path ./templates/custom.hbs \
  --param version=1.0.0
```

## Scaffolding Complete Projects

### Project Scaffolding

```bash
# Scaffold a complete Rust web API project
pmat scaffold project rust-api \
  --name my-api \
  --path ./my-api-project

# Scaffold with Git initialization
pmat scaffold project python-ml \
  --name ml-pipeline \
  --path ./ml-project \
  --git

# Interactive scaffolding
pmat scaffold project rust-cli --interactive
```

**Scaffolded Project Structure:**
```
my-api-project/
├── Cargo.toml
├── README.md
├── .gitignore
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── release.yml
├── src/
│   ├── main.rs
│   ├── config.rs
│   ├── handlers/
│   │   ├── mod.rs
│   │   ├── health.rs
│   │   └── api.rs
│   ├── models/
│   │   └── mod.rs
│   └── utils/
│       └── mod.rs
├── tests/
│   └── integration_test.rs
├── migrations/
│   └── .gitkeep
├── docker/
│   ├── Dockerfile
│   └── docker-compose.yml
└── docs/
    ├── API.md
    └── CONTRIBUTING.md
```

### Configuration-Driven Scaffolding

```toml
# scaffold-config.toml
[project]
name = "enterprise-api"
version = "1.0.0"
author = "Engineering Team"
license = "MIT"

[features]
enable_tests = true
enable_benchmarks = true
enable_docs = true
enable_ci = true
enable_docker = true

[dependencies]
actix-web = "4.0"
tokio = { version = "1", features = ["full"] }
serde = { version = "1.0", features = ["derive"] }
sqlx = { version = "0.7", features = ["postgres", "runtime-tokio"] }

[dev-dependencies]
criterion = "0.5"
proptest = "1.0"

[quality]
min_test_coverage = 80
max_complexity = 10
enforce_clippy = true
```

```bash
# Use configuration file
pmat scaffold project rust-api \
  --config scaffold-config.toml \
  --path ./enterprise-api
```

### Multi-Language Projects

```bash
# Scaffold polyglot microservice project
pmat scaffold project polyglot \
  --languages "rust,python,typescript" \
  --name microservices \
  --path ./microservices-project
```

**Polyglot Project Structure:**
```
microservices-project/
├── services/
│   ├── rust-api/
│   │   ├── Cargo.toml
│   │   └── src/
│   ├── python-ml/
│   │   ├── pyproject.toml
│   │   └── src/
│   └── typescript-frontend/
│       ├── package.json
│       └── src/
├── shared/
│   ├── protos/
│   ├── schemas/
│   └── configs/
├── docker-compose.yml
├── Makefile
└── README.md
```

## MCP Agent Scaffolding

### Deterministic Agent Creation

```bash
# Scaffold deterministic MCP agent
pmat scaffold agent deterministic \
  --name code-analyzer \
  --path ./analyzer-agent

# List available agent templates
pmat scaffold list-templates

# Validate agent template
pmat scaffold validate-template agent-template.yaml
```

**Agent Template Structure:**
```yaml
# agent-template.yaml
name: code-analyzer
version: 1.0.0
description: Deterministic code analysis agent
author: PMAT Team

capabilities:
  - code_analysis
  - complexity_detection
  - quality_reporting

tools:
  - name: analyze_file
    description: Analyze a single file
    parameters:
      - name: file_path
        type: string
        required: true
        description: Path to file to analyze
      
  - name: analyze_directory
    description: Analyze entire directory
    parameters:
      - name: directory
        type: string
        required: true
      - name: recursive
        type: boolean
        default: true
        
  - name: generate_report
    description: Generate analysis report
    parameters:
      - name: format
        type: enum
        values: [json, html, markdown]
        default: json

configuration:
  max_file_size_mb: 10
  timeout_seconds: 30
  cache_enabled: true
  
quality_standards:
  min_test_coverage: 80
  max_complexity: 10
  enforce_documentation: true
```

**Generated Agent Code:**
```rust
// src/main.rs - Generated MCP Agent
use serde::{Deserialize, Serialize};
use async_trait::async_trait;

#[derive(Debug, Clone)]
pub struct CodeAnalyzerAgent {
    config: AgentConfig,
    state: AgentState,
}

#[derive(Debug, Clone, Deserialize)]
pub struct AgentConfig {
    max_file_size_mb: usize,
    timeout_seconds: u64,
    cache_enabled: bool,
}

#[derive(Debug, Clone, Default)]
pub struct AgentState {
    files_analyzed: usize,
    total_complexity: usize,
    cache: HashMap<String, AnalysisResult>,
}

#[async_trait]
impl MCPAgent for CodeAnalyzerAgent {
    async fn initialize(&mut self, config: Value) -> Result<()> {
        self.config = serde_json::from_value(config)?;
        self.state = AgentState::default();
        Ok(())
    }
    
    async fn execute_tool(&mut self, tool: &str, params: Value) -> Result<Value> {
        match tool {
            "analyze_file" => self.analyze_file(params).await,
            "analyze_directory" => self.analyze_directory(params).await,
            "generate_report" => self.generate_report(params).await,
            _ => Err(Error::UnknownTool(tool.to_string())),
        }
    }
    
    async fn get_state(&self) -> Value {
        json!({
            "files_analyzed": self.state.files_analyzed,
            "total_complexity": self.state.total_complexity,
            "cache_size": self.state.cache.len(),
        })
    }
}

impl CodeAnalyzerAgent {
    async fn analyze_file(&mut self, params: Value) -> Result<Value> {
        let file_path: String = params["file_path"]
            .as_str()
            .ok_or(Error::InvalidParameter("file_path"))?
            .to_string();
        
        // Check cache
        if self.config.cache_enabled {
            if let Some(cached) = self.state.cache.get(&file_path) {
                return Ok(serde_json::to_value(cached)?);
            }
        }
        
        // Perform analysis
        let result = self.perform_analysis(&file_path).await?;
        
        // Update state
        self.state.files_analyzed += 1;
        self.state.total_complexity += result.complexity;
        
        // Cache result
        if self.config.cache_enabled {
            self.state.cache.insert(file_path.clone(), result.clone());
        }
        
        Ok(serde_json::to_value(result)?)
    }
    
    // Additional implementation...
}
```

## Enterprise Integration Patterns

### Template Registry

```toml
# .pmat/templates.toml - Custom template registry
[registry]
url = "https://templates.company.com"
auth_token = "${TEMPLATE_REGISTRY_TOKEN}"

[custom_templates]
"company/microservice" = {
    path = "templates/microservice",
    version = "2.0.0",
    requires_approval = true
}

"company/lambda" = {
    path = "templates/lambda", 
    version = "1.5.0",
    tags = ["serverless", "aws"]
}

[validation]
enforce_naming = true
naming_pattern = "^[a-z][a-z0-9-]*$"
max_name_length = 50

[quality_gates]
min_test_coverage = 80
require_documentation = true
enforce_security_scan = true
```

### CI/CD Template Pipeline

```yaml
# .github/workflows/template-validation.yml
name: Template Validation

on:
  push:
    paths:
      - 'templates/**'
      - '.pmat/templates.toml'

jobs:
  validate-templates:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Install PMAT
      run: cargo install pmat
    
    - name: Validate All Templates
      run: |
        for template in templates/*; do
          echo "Validating $template..."
          pmat scaffold validate-template "$template/template.yaml"
        done
    
    - name: Test Template Generation
      run: |
        # Test each template generates successfully
        pmat generate rust cli --param name=test --dry-run
        pmat generate python api --param name=test --dry-run
        
    - name: Quality Check Generated Code
      run: |
        # Generate and analyze
        pmat generate rust web --param name=quality-test --output test-project
        cd test-project
        pmat analyze complexity --path .
        pmat quality-gate --strict
```

### Team Template Workflow

```bash
# Create team-specific template
pmat scaffold create-template \
  --name "team/service" \
  --base rust-api \
  --customizations team-config.yaml

# Share template with team
pmat scaffold publish-template \
  --template "team/service" \
  --registry internal

# Team members use shared template
pmat scaffold project team/service \
  --name new-service \
  --author "Developer Name"
```

## Template Customization

### Custom Template Variables

```handlebars
{{!-- custom-template.hbs --}}
# {{project_name}}

{{#if description}}
{{description}}
{{/if}}

## Configuration

```toml
[package]
name = "{{name}}"
version = "{{version}}"
authors = ["{{author}}"]
edition = "{{edition}}"

{{#if features}}
[features]
{{#each features}}
{{this.name}} = {{this.deps}}
{{/each}}
{{/if}}

[dependencies]
{{#each dependencies}}
{{@key}} = "{{this}}"
{{/each}}
```

{{#if enable_tests}}
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_{{name}}() {
        // Test implementation
    }
}
{{/if}}
```

### Template Composition

```bash
# Compose multiple templates
pmat scaffold compose \
  --templates "rust-api,monitoring,security" \
  --name composite-service \
  --merge-strategy overlay
```

## Performance and Optimization

### Template Caching

```bash
# Warm template cache
pmat scaffold cache-warm

# Clear template cache
pmat scaffold cache-clear

# Show cache statistics
pmat scaffold cache-stats
```

**Cache Statistics Output:**
```
📊 Template Cache Statistics
===========================
Cache Size: 45.2 MB
Templates Cached: 127
Average Load Time: 0.3ms
Cache Hit Rate: 94.5%
Last Updated: 2025-09-12 14:30:00

Most Used Templates:
1. rust/cli - 342 uses
2. python/api - 298 uses
3. typescript/react - 156 uses
```

## Troubleshooting

### Common Issues

1. **Missing Required Parameters**
```bash
# Check what parameters are needed
pmat validate rust web

# Use defaults where available
pmat generate rust web --use-defaults
```

2. **Template Not Found**
```bash
# Update template registry
pmat scaffold update-registry

# List available templates
pmat list --refresh
```

3. **Generation Conflicts**
```bash
# Force overwrite existing files
pmat scaffold project rust-api --force

# Backup before overwriting
pmat scaffold project rust-api --backup
```

## Summary

PMAT's template generation and scaffolding system eliminates the friction of starting new projects by providing production-ready, quality-assured templates. The system supports everything from single file generation to complete multi-language project scaffolding, with built-in quality standards and customization options.

Key benefits include:
- **Rapid Project Creation**: From idea to running code in seconds
- **Consistency**: Standardized structure across all projects
- **Quality Built-in**: Best practices and standards from the start
- **MCP Agent Support**: Deterministic agent scaffolding for AI tools
- **Enterprise Ready**: Custom registries, validation, and team workflows
- **Multi-Language**: Support for polyglot architectures

The template system ensures every new project starts with a solid foundation, incorporating lessons learned and best practices automatically.