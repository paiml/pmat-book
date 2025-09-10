# Chapter 2: Getting Started with PMAT

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (8/8 examples)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 8 | All context features tested |
| ⚠️ Not Implemented | 0 | Planned for future versions |
| ❌ Broken | 0 | Known issues, needs fixing |
| 📋 Planned | 0 | Future roadmap features |

*Last updated: 2025-09-09*  
*PMAT version: pmat 2.69.0*  
*Test-Driven: All examples validated in `tests/ch02/test_context.sh`*
<!-- DOC_STATUS_END -->

## Your First PMAT Analysis

After installing PMAT (Chapter 1), you're ready to start analyzing code. This chapter covers the essential commands you'll use daily with PMAT.

## The Context Command: Your Gateway to AI-Powered Analysis

The `pmat context` command is the foundation of PMAT's AI integration capabilities. It generates comprehensive repository context that can be consumed by AI agents, LLMs, and other analysis tools.

### Basic Context Generation

The simplest way to generate context is to run PMAT in your project directory:

```bash
# Generate context for current directory
pmat context

# Generate context for specific directory
pmat context /path/to/project

# Save context to file
pmat context > project_context.txt
```

### Example Output

When you run `pmat context` on a Python project, you'll see:

```
📁 Repository Context
=====================

Project: my-application
Files: 156
Total Lines: 8,432
Languages: Python (85%), JavaScript (10%), YAML (5%)

## Structure
```
.
├── README.md (127 lines)
├── src/
│   ├── main.py (245 lines)
│   ├── models/
│   │   ├── user.py (189 lines)
│   │   ├── product.py (234 lines)
│   │   └── order.py (301 lines)
│   ├── services/
│   │   ├── auth.py (156 lines)
│   │   ├── payment.py (423 lines)
│   │   └── notification.py (178 lines)
│   └── utils/
│       ├── config.py (89 lines)
│       └── helpers.py (112 lines)
├── tests/ (2,145 lines total)
└── docs/ (1,234 lines total)
```

## Key Files

### src/main.py
Main application entry point with FastAPI setup, route definitions, and middleware configuration.

### src/services/payment.py
Payment processing service handling Stripe integration, refund logic, and transaction logging.

### src/models/user.py
User model with SQLAlchemy ORM, authentication methods, and role-based permissions.
```

## Filtering Context

Not all files are relevant for every analysis. PMAT provides powerful filtering options:

### Include Specific Files

```bash
# Include only Python files
pmat context --include="*.py"

# Include multiple patterns
pmat context --include="*.py,*.js,*.ts"

# Include by directory
pmat context --include="src/**/*.py"
```

### Exclude Patterns

```bash
# Exclude test files
pmat context --exclude="tests/*,*_test.py"

# Exclude dependencies and build artifacts
pmat context --exclude="node_modules/,venv/,build/,dist/"

# Exclude by size (files over 1MB)
pmat context --exclude-large
```

### Combined Filtering

```bash
# Python source files only, no tests or vendors
pmat context \
    --include="*.py" \
    --exclude="tests/,vendor/,*_test.py" \
    --max-file-size=500kb
```

## Output Formats

PMAT supports multiple output formats for different use cases:

### JSON Format

Perfect for programmatic consumption:

```bash
pmat context --format json > context.json
```

Output structure:
```json
{
  "project": {
    "name": "my-application",
    "path": "/home/user/projects/my-application",
    "vcs": "git",
    "branch": "main"
  },
  "metrics": {
    "files": 156,
    "total_lines": 8432,
    "languages": {
      "Python": 7167,
      "JavaScript": 843,
      "YAML": 422
    }
  },
  "structure": {
    "src": {
      "type": "directory",
      "files": 12,
      "lines": 2354,
      "children": {
        "main.py": {
          "type": "file",
          "lines": 245,
          "language": "Python",
          "complexity": 8
        }
      }
    }
  },
  "dependencies": ["fastapi", "sqlalchemy", "pytest"],
  "quality_metrics": {
    "complexity_average": 6.2,
    "test_coverage": 82.5,
    "technical_debt_grade": "B+"
  }
}
```

### Markdown Format

Ideal for documentation and reports:

```bash
pmat context --format markdown > PROJECT_CONTEXT.md
```

### XML Format

For enterprise integrations:

```bash
pmat context --format xml > context.xml
```

### AI-Optimized Format

Specifically designed for LLM consumption:

```bash
pmat context --ai-format
```

This format includes:
- Structured tags for easy parsing
- Token-efficient representation
- Relevance scoring for files
- Semantic grouping of related code

## Context with Analysis

Combine context generation with code analysis for richer insights:

```bash
# Include quality metrics
pmat context --with-analysis
```

Enhanced output includes:
```
## Code Quality Analysis
- **Complexity**: Average 6.2, Max 15 (payment.py:process_transaction)
- **Duplication**: 3.2% (18 similar blocks detected)
- **Test Coverage**: 82.5% (2,145 test lines)
- **Technical Debt**: Grade B+ (Score: 1.8/5.0)

## Security Insights
- No hard-coded secrets detected
- 2 dependencies with known vulnerabilities (minor)
- Authentication properly implemented

## Architecture Patterns
- MVC-like structure detected
- Service layer pattern in use
- Repository pattern for data access
- Dependency injection configured

## Recommendations
1. Reduce complexity in payment.py:process_transaction (cyclomatic: 15)
2. Update vulnerable dependencies: requests==2.25.1, pyyaml==5.3.1
3. Add missing tests for error handling paths
4. Consider extracting business logic from models
```

## Size Management

For large repositories, manage context size effectively:

### Token Limits

For AI/LLM consumption, limit by tokens:

```bash
# Limit to 4000 tokens (GPT-3.5 context window)
pmat context --max-tokens 4000

# Limit to 8000 tokens (GPT-4 context window)
pmat context --max-tokens 8000

# Limit to 32000 tokens (Claude context window)
pmat context --max-tokens 32000
```

### File Limits

Control the number of files included:

```bash
# Include only top 10 most relevant files
pmat context --max-files 10

# Prioritize by complexity
pmat context --max-files 20 --sort-by complexity

# Prioritize by recent changes
pmat context --max-files 20 --sort-by recency
```

### Smart Truncation

PMAT intelligently truncates large files:

```bash
# Smart truncation (keeps important parts)
pmat context --smart-truncate

# Truncate at specific line count
pmat context --max-lines-per-file 500
```

## Caching for Performance

For large repositories, use caching to speed up repeated context generation:

```bash
# Enable caching
pmat context --cache

# Force cache refresh
pmat context --cache --refresh

# Clear cache
pmat context --clear-cache

# Set cache TTL (time to live)
pmat context --cache --ttl 3600  # 1 hour
```

## Integration Examples

### With Claude or ChatGPT

```bash
# Generate and copy to clipboard (macOS)
pmat context --ai-format | pbcopy

# Generate and copy to clipboard (Linux)
pmat context --ai-format | xclip -selection clipboard

# Generate with specific instructions
pmat context --ai-format --prepend "Analyze this codebase for security vulnerabilities:"
```

### With VS Code

```bash
# Generate context for current workspace
pmat context --format json > .vscode/pmat-context.json
```

### In CI/CD Pipelines

```yaml
# GitHub Actions example
- name: Generate PMAT Context
  run: |
    pmat context --format json > context.json
    pmat context --format markdown > context.md
    
- name: Upload Context Artifacts
  uses: actions/upload-artifact@v3
  with:
    name: pmat-context
    path: |
      context.json
      context.md
```

## Advanced Options

### Custom Templates

Use custom templates for context output:

```bash
# Use custom template
pmat context --template templates/context.hbs

# Built-in templates
pmat context --template minimal
pmat context --template detailed
pmat context --template security-focused
```

### Multiple Repositories

Analyze multiple repositories in one context:

```bash
# Multiple paths
pmat context repo1/ repo2/ repo3/

# From file list
pmat context --repos-file projects.txt

# Monorepo with specific packages
pmat context --monorepo --packages="api,web,shared"
```

### Incremental Context

For continuous analysis:

```bash
# Generate incremental context (changes since last run)
pmat context --incremental

# Changes since specific commit
pmat context --since HEAD~10

# Changes in last 24 hours
pmat context --since "24 hours ago"
```

## Troubleshooting

### Common Issues

#### Large Repository Timeout
```bash
# Increase timeout
pmat context --timeout 300

# Use parallel processing
pmat context --parallel

# Exclude large directories
pmat context --exclude="data/,logs/,artifacts/"
```

#### Memory Issues
```bash
# Use streaming mode for large repos
pmat context --stream

# Limit memory usage
pmat context --max-memory 2G
```

#### Permission Errors
```bash
# Skip files with permission errors
pmat context --skip-errors

# Run with specific permissions
sudo pmat context --user $(whoami)
```

## Best Practices

1. **Start Small**: Begin with filtered context before analyzing entire repositories
2. **Use Caching**: Enable caching for large repositories to improve performance
3. **Filter Noise**: Exclude test files, dependencies, and generated code for cleaner context
4. **Choose Right Format**: Use JSON for tools, Markdown for humans, AI-format for LLMs
5. **Size Appropriately**: Match context size to your consumption method's limits
6. **Regular Updates**: Refresh context regularly for evolving codebases
7. **Security First**: Never include sensitive files (.env, secrets, keys) in context

## Summary

The `pmat context` command is your starting point for AI-powered code analysis. It provides:

- **Flexible Generation**: Multiple formats and filtering options
- **Smart Analysis**: Optional quality metrics and insights
- **Performance**: Caching and incremental updates
- **Integration Ready**: Works with any AI tool or LLM
- **Size Management**: Token and file limits for optimal consumption

Master this command, and you'll unlock the full potential of AI-assisted development with PMAT.

## Next Steps

- [Chapter 3: MCP Protocol](ch03-00-mcp-protocol.md) - Integrate PMAT with AI agents
- [Chapter 4: Technical Debt Grading](ch04-01-tdg.md) - Analyze code quality
- [Appendix B: Command Reference](appendix-b-commands.md) - Complete CLI reference