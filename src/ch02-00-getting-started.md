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
*PMAT version: pmat 2.213.1*  
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

# Generate context for a specific directory (-p / --project-path; it is not a positional)
pmat context -p ../my-other-project

# Save context to a file
pmat context -o project_context.md
pmat context > project_context.md
```

### Example Output

Run on a small project with one Python and one JavaScript file, `pmat context`
prints (pmat 3.42.0, trimmed). `**Language**` names one language, the one pmat
detects as the project's primary language; with several present, measured runs
have named either one:

```markdown
# Project Context

**Language**: python
**Project Path**: .

## Project Structure

- **Total Files**: 2
- **Total Functions**: 3
- **Median Cyclomatic**: 2.00
- **Median Cognitive**: 2.00

## Quality Scorecard

- **Overall Health**: 100.0%
- **Maintainability Index**: not measured
- **Complexity Score**: 100.0
- **Test Coverage**: N/A

## Files

### ./src/app.py

**File Complexity**: 2 | **Functions**: 1

- **Function**: `add` [complexity: 2] [cognitive: 2] [big-o: O(1)] [satd: 0] [churn: low(1)]
```

## Choosing What Goes In

`pmat context` has no `--include` or `--exclude` glob options, and no
`--max-file-size`. To choose what it analyzes:

```bash
# Scope to one directory
pmat context -p src/

# Only one language, or a few
pmat context --language python
pmat context --languages python,javascript

# Files over 500KB are skipped by default; this brings them back
pmat context --include-large-files
```

In a measured run on pmat 3.42.0, the files under `tests/` and `build/` did
not appear in the output, with or without a `.gitignore` naming them.

## Output Formats

PMAT supports multiple output formats for different use cases:

### JSON Format

Perfect for programmatic consumption — structured project overview with per-function complexity:

```bash
pmat context --format json > context.json
```

Output structure:
```json
{
  "version": "1.0",
  "project": {
    "language": "rust",
    "path": "/home/user/projects/my-app",
    "total_files": 45,
    "total_functions": 312,
    "overall_health": 85.0,
    "maintainability_index": 70.0
  },
  "files": [
    {
      "path": "src/main.rs",
      "items": [
        {
          "name": "main",
          "type": "function",
          "line": 15,
          "complexity": 3,
          "cognitive_complexity": 2
        },
        {
          "name": "Config",
          "type": "struct",
          "line": 5,
          "fields_count": 4
        },
        {
          "name": "AppError",
          "type": "enum",
          "line": 22,
          "variants_count": 3
        }
      ]
    }
  ]
}
```

Each item includes `name`, `type` (function/struct/enum/trait/impl), and `line`. Functions are enriched with `complexity` and `cognitive_complexity` from the analysis. Structs include `fields_count`, enums include `variants_count`.

### SARIF Format

For CI/CD static analysis integration (SARIF v2.1):

```bash
pmat context --format sarif > context.sarif
```

### Markdown Format

Ideal for documentation and reports:

```bash
pmat context --format markdown > PROJECT_CONTEXT.md
```

### LLM-Optimized Format

```bash
pmat context --format llm-optimized
```

As of pmat 3.42.0 this prints the same bytes as `--format markdown`.

## Context with Analysis

Quality metrics are part of the context by default: the output above carries
per-function cyclomatic and cognitive complexity, Big-O, SATD and churn, plus a
quality scorecard. There is no `--with-analysis` flag. To trade those metrics
for speed:

```bash
# Skip TDG and complexity analysis for a faster run
pmat context --skip-expensive-metrics
```

## Size Management

`pmat context` has no token, file-count or line limits (`--max-tokens`,
`--max-files`, `--sort-by`, `--smart-truncate`, `--max-lines-per-file` do not
exist). To make the context smaller, narrow what it reads:

```bash
# One directory instead of the whole repository
pmat context -p src/

# One language
pmat context --language rust

# Leave out the expensive metrics
pmat context --skip-expensive-metrics
```

## Caching

`pmat context` has no cache options (`--cache`, `--refresh`, `--clear-cache`,
`--ttl` do not exist).

## Integration Examples

### With Claude or ChatGPT

```bash
# Generate and copy to clipboard (macOS)
pmat context | pbcopy

# Generate and copy to clipboard (Linux)
pmat context | xclip -selection clipboard

# Put your own instructions first
{ echo "Analyze this codebase for security vulnerabilities:"; pmat context; } > prompt.md
```

### With VS Code

```bash
# Generate context for current workspace
pmat context --format json -o .vscode/pmat-context.json
```

### In CI/CD Pipelines

```yaml
# GitHub Actions example
- name: Generate PMAT Context
  run: |
    pmat context --format json -o context.json
    pmat context --format markdown -o context.md

- name: Upload Context Artifacts
  uses: actions/upload-artifact@v4
  with:
    name: pmat-context
    path: |
      context.json
      context.md
```

## Advanced Options

### Templates

There is no template option (`--template` does not exist). Pick an output with
`--format` (markdown, json, sarif, llm-optimized), or transform the JSON
yourself.

### Multiple Repositories

`pmat context` reads one project per run; there is no `--repos-file`,
`--monorepo` or `--packages`. Run it once per path:

```bash
pmat context -p repo1 -o repo1-context.md
pmat context -p repo2 -o repo2-context.md
```

### Incremental Context

There is no incremental mode (`--incremental` and `--since` do not exist);
every run analyzes the project as it is now.

## Troubleshooting

### Common Issues

#### Large Repository Is Slow

There are no `--timeout`, `--parallel`, `--stream` or `--max-memory` options.

```bash
# Skip the expensive metrics
pmat context --skip-expensive-metrics

# Analyze one directory at a time
pmat context -p src/

# Enable verbose output (info level)
pmat context --verbose
```

#### Permission Errors

There is no `--skip-errors` or `--user` option. Run `pmat context` as the user
who can read the project. To enable debug output (debug level):

```bash
pmat context --debug
```

## Best Practices

1. **Start Small**: Scope with `-p` to the directory you care about before analyzing an entire repository
2. **Filter by Language**: `--language` / `--languages` keep the context to the code you are asking about
3. **Choose Right Format**: Use JSON for tools, SARIF for code-scanning, Markdown for humans and LLMs
4. **Go Faster When You Need To**: `--skip-expensive-metrics` drops TDG and complexity analysis
5. **Regular Updates**: Regenerate context as the codebase changes
6. **Security First**: Never include sensitive files (.env, secrets, keys) in context

## Summary

The `pmat context` command is your starting point for AI-powered code analysis. It provides:

- **Multiple Formats**: Markdown, JSON, SARIF
- **Built-in Analysis**: Complexity, Big-O, SATD and churn per function
- **Scoping**: By directory (`-p`) and by language (`--language`, `--languages`)
- **Integration Ready**: Works with any AI tool or LLM

Master this command, and you'll unlock the full potential of AI-assisted development with PMAT.

## Next Steps

- [Chapter 3: MCP Protocol](ch03-00-mcp-protocol.md) - Integrate PMAT with AI agents
- [Chapter 4: Technical Debt Grading](ch04-01-tdg.md) - Analyze code quality
- [Appendix B: Command Reference](appendix-b-commands.md) - Complete CLI reference