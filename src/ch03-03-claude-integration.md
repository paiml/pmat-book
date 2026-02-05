# Claude Code Integration

**Chapter Status**: ✅ 100% Working

*Last updated: 2025-10-19*
*PMAT version: pmat 2.213.1*

## Overview

This chapter covers integrating PMAT MCP tools with Claude Desktop for AI-assisted code analysis and quality improvement.

## Claude Desktop Configuration

### Configuration File Location

**macOS:**
```bash
~/Library/Application Support/Claude/claude_desktop_config.json
```

**Linux:**
```bash
~/.config/Claude/claude_desktop_config.json
```

**Windows:**
```bash
%APPDATA%\Claude\claude_desktop_config.json
```

### Basic Configuration

```json
{
  "mcpServers": {
    "pmat": {
      "command": "pmat",
      "args": ["mcp-server"],
      "env": {
        "RUST_LOG": "info"
      }
    }
  }
}
```

### Advanced Configuration

```json
{
  "mcpServers": {
    "pmat": {
      "command": "pmat",
      "args": ["mcp-server", "--bind", "127.0.0.1:3000"],
      "env": {
        "RUST_LOG": "info",
        "PMAT_MCP_LOG_LEVEL": "info",
        "PMAT_MCP_CACHE_ENABLED": "true",
        "PMAT_MCP_MAX_CONCURRENT": "4"
      }
    },
    "pmat-semantic": {
      "command": "pmat",
      "args": ["mcp-server", "--bind", "127.0.0.1:3001"],
      "env": {
        "PMAT_SEMANTIC_ENABLED": "true",
        "PMAT_VECTOR_DB_PATH": "~/.pmat/embeddings.db",
        "RUST_LOG": "info"
      }
    }
  }
}
```

## Using PMAT Tools with Claude

### Documentation Validation

**Prompt:**
```
I need to validate my README.md against the actual codebase. Can you use PMAT
to check for hallucinations, broken references, and contradictions?
```

**Claude will:**
1. Generate deep context: `pmat context --output deep_context.md`
2. Call `validate_documentation` tool
3. Report validation results with specific issues

**Example Output:**
```
I've validated your README.md against the codebase. Here are the results:

✅ Pass: 42/45 claims verified (93.3%)

Issues Found:

1. Line 42: Contradiction
   Claim: "PMAT can compile Rust code"
   Evidence: PMAT analyzes but does not compile code
   Confidence: 88%

2. Line 67: Unverified
   Claim: "Supports analysis of 15+ languages"
   Status: Could not verify exact count
   Confidence: 65%

Recommendations:
- Update line 42 to accurately reflect PMAT's analysis capabilities
- Verify and document the exact language count
```

### Code Quality Analysis

**Prompt:**
```
Can you analyze the code quality of src/main.rs and give me recommendations
for improving it?
```

**Claude will:**
1. Call `analyze_technical_debt` for TDG grading
2. Call `get_quality_recommendations` for specific suggestions
3. Prioritize recommendations by impact

**Example Output:**
```
I've analyzed src/main.rs. Current quality grade: B+ (82.5/100)

High-Priority Recommendations:

1. Complexity Reduction (Impact: 8.5 points)
   Function: calculate_total (line 120)
   Issue: Cyclomatic complexity of 15
   Suggestion: Extract validation logic into separate function

2. Duplication Elimination (Impact: 6.2 points)
   Lines: 45-60 similar to lines 200-215
   Suggestion: Create shared utility function

3. Documentation (Impact: 4.1 points)
   Functions missing doc comments: 5
   Suggestion: Add comprehensive documentation

Would you like me to help implement these improvements?
```

### WASM Analysis

**Prompt:**
```
I have a WASM file at output.wasm. Can you analyze it for performance issues
and compare it with an optimized version at output_O3.wasm?
```

**Claude will:**
1. Call `deep_wasm_analyze` for bytecode analysis
2. Call `deep_wasm_compare_optimizations` for comparison
3. Call `deep_wasm_detect_issues` for issue detection

### Multi-Agent Workflow

**Prompt:**
```
Can you run a comprehensive quality check on my project at src/ and create
a quality gate report?
```

**Claude will:**
1. Call `orchestrate` to coordinate multiple agents
2. Run complexity, security, and maintainability analysis
3. Call `quality_gate` with thresholds
4. Generate comprehensive report

## Common Use Cases

### Use Case 1: Pre-Commit Documentation Check

**Prompt:**
```
I'm about to commit changes to README.md. Can you validate it against the
codebase to ensure there are no hallucinations or broken references?
```

**Result:** Claude validates documentation and prevents bad commits.

### Use Case 2: Code Review Assistance

**Prompt:**
```
I have a pull request with changes in src/auth.rs. Can you review it for
quality issues and security concerns?
```

**Result:** Claude performs automated code review with TDG analysis and security checks.

### Use Case 3: Refactoring Guidance

**Prompt:**
```
The quality of src/legacy_code.rs is poor. Can you analyze it and guide me
through refactoring to improve the grade to A-?
```

**Result:** Claude provides step-by-step refactoring recommendations with impact analysis.

### Use Case 4: Mutation Testing

**Prompt:**
```
I want to check the quality of my test suite for src/calculator.rs. Can you
run mutation testing and tell me how effective my tests are?
```

**Result:** Claude runs mutation testing and reports test effectiveness with specific gaps.

## Integration Patterns

### Pattern 1: Documentation Accuracy Enforcement

```
Setup:
1. Configure Claude with PMAT MCP server
2. Create pre-commit hook that asks Claude to validate docs

Workflow:
- Developer modifies README.md
- Pre-commit hook triggers
- Claude validates via PMAT
- Commit blocked if validation fails
```

### Pattern 2: AI-Assisted Code Review

```
Setup:
1. Configure Claude with PMAT MCP server
2. Configure GitHub Actions to post Claude reviews

Workflow:
- Developer opens pull request
- GitHub Action triggers
- Claude analyzes changes via PMAT
- Claude posts review comments with specific recommendations
```

### Pattern 3: Continuous Quality Monitoring

```
Setup:
1. Configure Claude with PMAT MCP server
2. Schedule daily quality reports

Workflow:
- Cron job triggers daily
- Claude analyzes entire codebase via PMAT
- Claude generates quality report
- Report sent to team via Slack/Email
```

## Troubleshooting

### Claude Can't Find PMAT Tools

**Symptoms:**
- Claude says "I don't have access to PMAT tools"
- Tools not showing in Claude's tool list

**Solutions:**
1. Verify `pmat` binary is in PATH:
   ```bash
   which pmat
   ```

2. Check Claude Desktop config:
   ```bash
   cat ~/Library/Application\ Support/Claude/claude_desktop_config.json
   ```

3. Restart Claude Desktop

4. Check PMAT server logs:
   ```bash
   RUST_LOG=debug pmat mcp-server
   ```

### Tools Timing Out

**Symptoms:**
- Claude reports "Tool call timed out"

**Solutions:**
1. Increase timeout in config:
   ```json
   {
     "mcpServers": {
       "pmat": {
         "command": "pmat",
         "args": ["mcp-server"],
         "timeout": 120000
       }
     }
   }
   ```

2. Reduce analysis scope:
   - Analyze specific files instead of entire project
   - Exclude large directories (node_modules, target, etc.)

### Semantic Search Not Working

**Symptoms:**
- Claude says semantic search tools unavailable

**Solutions:**
1. Enable semantic search via config:
   ```bash
   pmat config --set semantic.enabled=true
   ```

2. Or add to Claude config:
   ```json
   {
     "mcpServers": {
       "pmat": {
         "env": {
           "PMAT_SEMANTIC_ENABLED": "true"
         }
       }
     }
   }
   ```

**Note:** PMAT uses local TF-IDF embeddings via the aprender library. No external API keys are required.

## Best Practices

### 1. Be Specific in Prompts

**Good:**
```
Analyze src/auth.rs for security issues and high complexity functions.
Focus on functions with cyclomatic complexity > 10.
```

**Bad:**
```
Check my code.
```

### 2. Use Iterative Analysis

**Approach:**
1. Start with high-level analysis (TDG grading)
2. Dive deeper into specific issues
3. Request targeted recommendations
4. Implement and re-analyze

### 3. Combine Multiple Tools

**Example:**
```
Can you:
1. Validate README.md against the codebase
2. Analyze code quality of src/
3. Run mutation testing on src/calculator.rs
4. Generate a comprehensive quality report
```

### 4. Leverage Context

**Example:**
```
I'm working on improving code quality from B to A-. The previous analysis
showed high complexity in src/main.rs. Can you analyze it again and show
me if the refactoring improved the grade?
```

## Next Steps

- [**Chapter 15: Complete MCP Tools Reference**](ch15-00-mcp-tools.md) - Advanced workflows and detailed tool schemas
- Explore integration with other AI assistants (ChatGPT, Copilot)
- Set up automated quality gates in CI/CD pipelines
