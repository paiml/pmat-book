# Chapter 39: Unified CLI/MCP Help Integration

This chapter covers the unified help architecture that prevents documentation drift and provides intelligent command discovery through semantic search and NLP-powered help.

## The Problem: Documentation Drift

Before the unified architecture, PMAT suffered from a common issue: documentation and implementation diverging over time. A real support ticket highlighted this problem:

```
User: I'm trying to connect PMAT as an MCP tool using `pmat mcp` but it doesn't work.
       The README says to use this command.
Support: There is no `pmat mcp` command. The README was outdated.
```

This type of documentation drift causes:
- User frustration and wasted time
- Support overhead
- Loss of trust in documentation
- Difficulty onboarding new users

## The Solution: Single Source of Truth

PMAT now uses a **Single Source of Truth** architecture where all command metadata is defined once in code and all outputs (help text, MCP schemas, documentation) are generated from that source.

```
                    ┌─────────────────────┐
                    │  CommandRegistry    │
                    │  (Single Source)    │
                    └──────────┬──────────┘
                               │
         ┌─────────────────────┼─────────────────────┐
         │                     │                     │
         ▼                     ▼                     ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  --help Output  │  │  MCP Schemas    │  │  Documentation  │
│  (HelpGenerator)│  │  (McpSchemaGen) │  │  (DriftDetector)│
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

## Components

### CommandRegistry

The `CommandRegistry` stores all command metadata:

```rust
use pmat::cli::{CommandRegistry, CommandMetadata};

let mut registry = CommandRegistry::new("2.211.0");

registry.register(
    CommandMetadata::builder("analyze")
        .short_description("Run code analysis")
        .long_description("Comprehensive suite of code analysis tools")
        .subcommand(
            CommandMetadata::builder("complexity")
                .short_description("Analyze code complexity")
                .category("analysis")
                .tags(["metrics", "quality"])
                .build()
        )
        .category("analysis")
        .build()
);
```

### HelpGenerator

Generates dynamic `--help` output from the registry:

```rust
use pmat::cli::HelpGenerator;

let help_gen = HelpGenerator::new(registry.clone());

// Generate overview
println!("{}", help_gen.generate_overview());

// Generate specific command help
println!("{}", help_gen.generate("analyze complexity"));

// Typo suggestions
println!("{}", help_gen.generate("analize")); // Suggests "analyze"
```

### McpSchemaGenerator

Auto-generates MCP tool schemas from CLI definitions:

```rust
use pmat::cli::McpSchemaGenerator;

let mcp_gen = McpSchemaGenerator::new(registry.clone());
let tools = mcp_gen.generate_tools_list();

// Produces JSON Schema for MCP tools/list response
println!("{}", serde_json::to_string_pretty(&tools)?);
```

### UnifiedHelpService

Provides RAG-powered semantic help search:

```rust
use pmat::cli::UnifiedHelpService;

let help = UnifiedHelpService::new(registry);

// Semantic search
let results = help.search("how to find complex functions", 5);
for result in results {
    println!("{}: {}", result.command, result.snippet);
}

// Intelligent lookup
match help.lookup("ctx") {
    HelpResponse::Exact(cmd) => println!("Found: {}", cmd.name),
    HelpResponse::DidYouMean { suggestion, .. } => {
        println!("Did you mean: {}", suggestion);
    }
    HelpResponse::SearchResults { results, .. } => {
        for r in results {
            println!("Suggestion: {}", r.command);
        }
    }
}
```

## Semantic Search Features

The unified help system uses NLP and graph algorithms for intelligent search:

### BM25 Text Ranking

Commands are ranked by relevance using BM25 (Best Matching 25), which considers:
- Term frequency in the document
- Inverse document frequency across all commands
- Document length normalization

### PageRank Importance

Commands are also scored by "importance" using PageRank on the command graph:
- Commands that are referenced by many other commands rank higher
- Core commands like `analyze` and `context` have higher importance
- Helps surface the most useful commands first

### Combined Scoring

Results combine relevance and importance:

```
final_score = 0.7 * relevance_score + 0.3 * importance_score
```

## Drift Detection

The `DriftDetector` validates documentation against actual commands:

```bash
# In a pre-commit hook or CI pipeline
pmat validate-docs README.md CLAUDE.md
```

The detector:
1. Scans markdown files for `pmat <command>` references
2. Checks each reference against the CommandRegistry
3. Reports errors for non-existent commands
4. Suggests similar commands for typos

Example output:
```
Drift Detection Report
======================

Commands: 45 total, 42 documented (93.3% coverage)

Errors detected:
  - README.md:42: command 'mcp' doesn't exist (did you mean 'context'?)
  - CLAUDE.md:156: deprecated command 'old-analyze' documented without notice

Undocumented commands:
  - internal-debug
  - test-helper
```

## Running the Demo

```bash
cargo run --example unified_help_demo
```

This demonstrates:
1. Creating a CommandRegistry
2. Dynamic help generation
3. MCP schema generation
4. Semantic search
5. Intelligent lookup with fuzzy matching

## Toyota Way Principles

This architecture embodies Toyota Way quality principles:

### Jidoka (Built-in Quality)
Quality is built into the process, not inspected afterward. Documentation accuracy is guaranteed by design.

### Poka-yoke (Error Prevention)
The system makes errors impossible. You cannot document a command that doesn't exist.

### Genchi Genbutsu (Go and See)
The drift detector goes to the actual code to verify documentation claims.

## Best Practices

1. **Always use the builder pattern** for command metadata
2. **Include examples** that can be validated
3. **Tag commands** for better semantic search
4. **Run drift detection** in CI/CD pipelines
5. **Use aliases** for common abbreviations (e.g., `ctx` for `context`)

## API Reference

### CommandMetadata Builder

```rust
CommandMetadata::builder("name")
    .short_description("Brief description")
    .long_description("Detailed description...")
    .aliases(["alias1", "alias2"])
    .argument(ArgumentMetadata { ... })
    .example(ExampleMetadata { ... })
    .category("analysis")
    .tags(["tag1", "tag2"])
    .mcp(McpToolMetadata { ... })  // Optional MCP exposure
    .build()
```

### HelpResponse Variants

- `Exact(CommandMetadata)` - Found exact match
- `DidYouMean { suggestion, confidence }` - Fuzzy match suggestion
- `SearchResults { query, results }` - Semantic search results

## References

- Specification: `docs/specifications/unified-cli-mcp-help-integration.md`
- GitHub Issue: #118
- Example: `examples/unified_help_demo.rs`

### Academic Citations

1. Lewis et al. (2020) - RAG: Retrieval-Augmented Generation
2. Robertson & Zaragoza (2009) - BM25 Probabilistic Relevance Framework
3. Page et al. (1999) - PageRank Citation Ranking
