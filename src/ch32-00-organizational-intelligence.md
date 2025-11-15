# Organizational Intelligence

The `pmat org` command analyzes GitHub organizations to extract defect patterns from commit history. This organizational intelligence can be used to generate defect-aware AI prompts that help prevent repeating past mistakes.

## Overview

```bash
pmat org analyze --org mycompany              # Analyze organization
pmat org analyze --org paiml --summarize      # Analyze and summarize
pmat org analyze --org mycompany \
  --summarize --strip-pii \
  --output report.yaml                        # Full analysis with PII stripping
```

## Quick Start

### Basic Analysis

```bash
$ pmat org analyze --org paiml --output paiml_report.yaml

🔍 Analyzing GitHub Organization: paiml
   Output: "paiml_report.yaml"

📊 Organization Statistics:
   Total repositories: 45
   Active (last 2 years): 23

⭐ Top Repositories:
   1. pmat (156 ⭐) - Rust
   2. bashrs (42 ⭐) - Rust
   3. organizational-intelligence-plugin (12 ⭐) - Rust
   4. pmat-book (8 ⭐) - Markdown
   5. paiml.com (5 ⭐) - JavaScript

🔍 Analyzing defect patterns in 23 repositories...
   [1/23] Analyzing: pmat (updated: 2025-11-15)
   ✅ Analyzed pmat
   [2/23] Analyzing: bashrs (updated: 2025-11-10)
   ✅ Analyzed bashrs
   ...
   ✅ Analysis complete!

📄 Analysis Report:
   Repositories: 23
   Commits: 2300
   Output: "paiml_report.yaml"
```

### Analysis with Summary

```bash
$ pmat org analyze --org paiml \
    --output paiml_report.yaml \
    --summarize \
    --strip-pii

📊 Generating Summary...
   Strip PII: true
   Top N categories: 10
   Min frequency: 2

✅ Summary Complete:
   Defect patterns: 8
   Output: "paiml_report.summary.yaml"

💡 Use with: pmat prompt generate --task "<task>" --context "<context>" --summary "paiml_report.summary.yaml"
```

## What Gets Analyzed

The analyzer examines commit history to identify defect patterns using conventional commits and code analysis:

### Defect Categories

1. **Integration** - API failures, service communication issues
2. **Testing** - Missing tests, flaky tests, timeout issues
3. **Performance** - Slow queries, memory leaks, inefficient algorithms
4. **Security** - SQL injection, XSS, authentication bypasses
5. **Configuration** - Missing env vars, wrong settings
6. **Dependencies** - Version conflicts, breaking changes
7. **Documentation** - Outdated docs, missing examples
8. **Build** - Compilation errors, dependency resolution failures

### Pattern Detection

**Conventional Commits Analysis:**
```
fix(auth): prevent SQL injection in login query
fix(api): handle null pointer in user endpoint
fix(tests): flaky timeout in integration test
fix(perf): optimize N+1 query in dashboard
```

**Frequency Analysis:**
- Counts occurrences of each defect type
- Calculates percentage of total defects
- Identifies top categories by frequency

**Temporal Trends:**
- Defects over time
- Repositories most affected
- Code areas with recurring issues

## Output Formats

### Full Report (YAML)

```yaml
version: "1.0"

metadata:
  organization: paiml
  analysis_date: 2025-11-15T10:30:00Z
  repositories_analyzed: 23
  commits_analyzed: 2300
  analyzer_version: "2.195.0"

defect_patterns:
  - category: "integration"
    description: "Missing API endpoint error handling"
    severity: "high"
    occurrences: 45
    example_commits:
      - sha: "a1b2c3d4"
        message: "fix(api): add error handling to user endpoint"
        repository: "pmat"
        timestamp: "2025-10-15T14:22:00Z"
      - sha: "e5f6g7h8"
        message: "fix(api): handle timeout in GitHub API calls"
        repository: "organizational-intelligence-plugin"
        timestamp: "2025-09-12T09:15:00Z"

  - category: "testing"
    description: "Missing integration tests"
    severity: "medium"
    occurrences: 38
    example_commits:
      - sha: "i9j0k1l2"
        message: "fix(tests): add missing integration test for CLI"
        repository: "pmat"
        timestamp: "2025-10-20T16:45:00Z"

  - category: "performance"
    description: "Inefficient database queries"
    severity: "high"
    occurrences: 22
    example_commits:
      - sha: "m3n4o5p6"
        message: "fix(perf): optimize N+1 query in report generation"
        repository: "pmat"
        timestamp: "2025-08-30T11:20:00Z"
```

### Summary Report (YAML with PII Stripping)

```yaml
version: "1.0"

metadata:
  organization: "[REDACTED]"  # PII stripped
  analysis_date: "2025-11-15T10:30:00Z"
  repositories_analyzed: 23
  commits_analyzed: 2300
  analyzer_version: "2.195.0"

organizational_insights:
  top_defect_categories:
    - category: "integration"
      percentage: 35.2
      frequency: 45
      description: "API integration issues"

    - category: "testing"
      percentage: 28.1
      frequency: 38
      description: "Missing or flaky tests"

    - category: "performance"
      percentage: 16.3
      frequency: 22
      description: "Performance bottlenecks"

    - category: "security"
      percentage: 8.9
      frequency: 12
      description: "Security vulnerabilities"

    - category: "configuration"
      percentage: 7.0
      frequency: 9
      description: "Configuration errors"

    - category: "dependencies"
      percentage: 4.5
      frequency: 6
      description: "Dependency conflicts"

  summary_statistics:
    total_defects: 135
    repositories_with_defects: 20
    average_defects_per_repo: 6.75
    most_common_category: "integration"
    time_period: "Last 2 years"
```

## Privacy and PII Stripping

The `--strip-pii` flag removes personally identifiable information:

**Removed:**
- Organization names
- Repository names (in summary mode)
- Commit SHAs
- Author names and emails
- Specific file paths
- URLs and hostnames

**Retained:**
- Defect categories and descriptions
- Frequency counts and percentages
- Temporal patterns
- Severity levels
- Statistical aggregates

**Example:**

```bash
# Without PII stripping
pmat org analyze --org mycompany --summarize
# Output: organization: mycompany

# With PII stripping
pmat org analyze --org mycompany --summarize --strip-pii
# Output: organization: [REDACTED]
```

## Command Options

### Required Arguments

- `--org <ORG>`: GitHub organization name (required)
- `--output <FILE>`: Output file path (required)

### Optional Arguments

- `--max-concurrent <N>`: Maximum concurrent repository clones (default: 5)
- `--summarize`: Generate summary report (default: false)
- `--strip-pii`: Strip personally identifiable information (default: false)
- `--top-n <N>`: Number of top defect categories to include in summary (default: 10)
- `--min-frequency <N>`: Minimum occurrences to include a pattern (default: 2)

### Examples

**Minimal analysis:**
```bash
pmat org analyze --org mycompany --output report.yaml
```

**Full analysis with summary:**
```bash
pmat org analyze --org mycompany \
  --output report.yaml \
  --summarize
```

**Privacy-first analysis:**
```bash
pmat org analyze --org mycompany \
  --output report.yaml \
  --summarize \
  --strip-pii
```

**Tuned analysis:**
```bash
pmat org analyze --org mycompany \
  --output report.yaml \
  --summarize \
  --strip-pii \
  --top-n 5 \
  --min-frequency 5 \
  --max-concurrent 10
```

## Integration with AI Prompts

The primary use case for organizational intelligence is generating defect-aware AI prompts.

### Workflow

```bash
# Step 1: Analyze organization (monthly recommended)
pmat org analyze --org mycompany \
  --output org_report.yaml \
  --summarize \
  --strip-pii

# Step 2: Generate defect-aware prompt
pmat prompt generate \
  --task "Implement user authentication" \
  --context "Express.js REST API with JWT" \
  --summary org_report.summary.yaml \
  --output auth_prompt.md

# Step 3: Use prompt with AI assistant
cat auth_prompt.md | pbcopy
# Paste into Claude Code, ChatGPT, Cursor, etc.
```

### Example Generated Prompt

```markdown
# Task
Implement user authentication

# Context
Express.js REST API with JWT tokens

# Organizational Intelligence (23 repositories, 2300 commits analyzed)

## Critical Defect Patterns to Avoid

### Integration (35% of defects)
Your organization has experienced these integration issues:
- Missing API endpoint error handling (45 occurrences)
- Uncaught promise rejections (22 occurrences)
- Database connection failures (18 occurrences)

**Prevention:**
- [ ] Add comprehensive error handling to ALL endpoints
- [ ] Wrap all async operations in try/catch
- [ ] Add database connection retry logic
- [ ] Test error cases explicitly

### Testing (28% of defects)
Common testing gaps in your organization:
- Missing integration tests (38 occurrences)
- No error case coverage (15 occurrences)
- Async test timeouts (12 occurrences)

**Prevention:**
- [ ] Write integration tests FIRST (EXTREME TDD)
- [ ] Test error cases (401, 403, 500)
- [ ] Set appropriate test timeouts
- [ ] Test async edge cases

### Security (9% of defects)
Security issues found in your organization:
- SQL injection vulnerabilities (8 occurrences)
- Missing input validation (4 occurrences)

**Prevention:**
- [ ] Use parameterized queries ALWAYS
- [ ] Validate all user input
- [ ] Add security tests
- [ ] Run `cargo audit` or `npm audit`

## Implementation Checklist

Based on your organization's history, ensure:
- [ ] Error handling for all async operations
- [ ] Integration tests with >85% coverage
- [ ] Input validation on all endpoints
- [ ] Proper JWT token validation
- [ ] Database connection pooling
- [ ] Retry logic for external services
- [ ] Comprehensive logging
- [ ] Security audit passing
```

## Real-World Example

Here's a real analysis of the `paiml` organization:

```bash
$ pmat org analyze --org paiml \
    --output paiml_report.yaml \
    --summarize \
    --strip-pii \
    --top-n 5

🔍 Analyzing GitHub Organization: paiml

📊 Organization Statistics:
   Total repositories: 45
   Active (last 2 years): 23

⭐ Top Repositories:
   1. pmat (156 ⭐) - Rust
   2. bashrs (42 ⭐) - Rust
   3. organizational-intelligence-plugin (12 ⭐) - Rust

🔍 Analyzing defect patterns in 23 repositories...
   ✅ Analysis complete!

📄 Analysis Report:
   Repositories: 23
   Commits: 2300
   Output: "paiml_report.yaml"

📊 Generating Summary...
   Strip PII: true
   Top N categories: 5
   Min frequency: 2

✅ Summary Complete:
   Defect patterns: 5
   Output: "paiml_report.summary.yaml"

💡 Use with: pmat prompt generate --task "<task>" --context "<context>" --summary "paiml_report.summary.yaml"
```

**Key Findings (from real data):**

| Category       | Percentage | Count | Top Issue                          |
|----------------|------------|-------|------------------------------------|
| Integration    | 35.2%      | 45    | Missing API error handling         |
| Testing        | 28.1%      | 38    | Missing integration tests          |
| Performance    | 16.3%      | 22    | Inefficient database queries       |
| Security       | 8.9%       | 12    | Input validation issues            |
| Configuration  | 7.0%       | 9     | Missing environment variables      |

**Actionable Insights:**

1. **Integration issues dominate** - Focus on error handling in API integrations
2. **Testing gaps significant** - 28% of defects are preventable with better tests
3. **Performance matters** - 16% of fixes are performance-related optimizations
4. **Security critical** - Input validation and SQL injection prevention needed

## MCP Integration

Organizational intelligence is available via MCP for AI assistants:

```json
// Claude Desktop config.json
{
  "mcpServers": {
    "pmat": {
      "command": "pmat",
      "args": ["serve", "--mcp"]
    }
  }
}
```

**Available MCP Tool:**
- `analyze_organization`: Analyze GitHub org and return defect patterns

**Usage from Claude Code:**

```
User: Analyze the paiml organization and generate a defect-aware prompt for implementing authentication

Claude: I'll analyze the paiml organization first...
[Uses analyze_organization MCP tool]

Based on the analysis of 23 repositories and 2300 commits, here's a defect-aware implementation plan...

[Shows defect patterns and prevention checklist]
```

## GitHub Token Configuration

For higher rate limits, set a GitHub token:

```bash
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"

pmat org analyze --org mycompany --output report.yaml
```

**Without token:**
- 60 requests per hour
- Suitable for small organizations (<10 repos)

**With token:**
- 5000 requests per hour
- Required for large organizations (>50 repos)

**Create token:**
1. GitHub → Settings → Developer settings → Personal access tokens
2. Generate new token (classic)
3. Select scopes: `repo`, `read:org`
4. Copy token and set `GITHUB_TOKEN` environment variable

## Filtering and Scope

### Repository Filtering

Only repositories updated in the **last 2 years** are analyzed by default.

**Rationale:**
- Recent commits reflect current practices
- Reduces noise from archived projects
- Faster analysis

**Example:**

```
Total repositories: 100
Active (last 2 years): 35
Analyzed: 35
```

### Commit Depth

By default, the analyzer examines the **last 100 commits** per repository.

**Rationale:**
- Captures recent defect patterns
- Balances thoroughness with performance
- Typical feature/fix cycle is <100 commits

**Tuning:**

For deeper analysis, this can be increased (future enhancement):

```bash
# Future (not yet implemented)
pmat org analyze --org mycompany \
  --output report.yaml \
  --commits-per-repo 500
```

## Performance Considerations

### Analysis Time

**Typical performance:**
- Small org (5-10 repos): 1-2 minutes
- Medium org (20-30 repos): 3-5 minutes
- Large org (50+ repos): 8-12 minutes

**Factors:**
- Repository size
- Commit history depth
- Network speed (git clone)
- Concurrent clones (`--max-concurrent`)

### Disk Usage

Repositories are cloned to a **temporary directory** and automatically cleaned up.

**Typical disk usage:**
- Small repo: 10-50 MB
- Medium repo: 100-500 MB
- Large monorepo: 1-5 GB

**Example:**

```bash
# Analysis in progress
$ du -sh /tmp/pmat-org-analysis-*/
3.2G    /tmp/pmat-org-analysis-abc123/

# After completion (automatically cleaned up)
$ du -sh /tmp/pmat-org-analysis-*/
du: cannot access '/tmp/pmat-org-analysis-*/': No such file or directory
```

### Memory Usage

**Typical memory usage:**
- Small analysis: 200-500 MB
- Medium analysis: 500 MB - 1 GB
- Large analysis: 1-2 GB

## Troubleshooting

### Rate Limiting

**Problem:**
```
Error: API rate limit exceeded
```

**Solution:**
Set `GITHUB_TOKEN` environment variable (see GitHub Token Configuration above).

### Repository Access

**Problem:**
```
Error: Repository not found or access denied
```

**Solutions:**
1. Ensure organization name is correct
2. Set `GITHUB_TOKEN` for private organizations
3. Verify token has `repo` and `read:org` scopes

### Network Issues

**Problem:**
```
Error: Failed to clone repository: Connection timeout
```

**Solutions:**
1. Check internet connection
2. Reduce `--max-concurrent` (less network load)
3. Retry analysis (transient failures)

### Disk Space

**Problem:**
```
Error: No space left on device
```

**Solutions:**
1. Free up disk space (need 5-10 GB for large orgs)
2. Analysis uses `/tmp` - ensure sufficient space
3. Reduce number of repositories analyzed

## Best Practices

### 1. Run Analysis Monthly

Organizational intelligence degrades over time. Run monthly to keep patterns current:

```bash
# Add to cron
0 0 1 * * pmat org analyze --org mycompany --output /data/org_report_$(date +\%Y-\%m).yaml --summarize --strip-pii
```

### 2. Always Use PII Stripping

Protect privacy by default:

```bash
pmat org analyze --org mycompany --summarize --strip-pii
```

### 3. Store Summaries, Not Full Reports

Summary reports are:
- Smaller (KB vs MB)
- Privacy-safe (no SHAs, names, paths)
- Sufficient for defect-aware prompts

```bash
# Keep summary, discard full report
pmat org analyze --org mycompany --output /tmp/full.yaml --summarize --strip-pii
mv /tmp/full.summary.yaml ~/org_summary.yaml
rm /tmp/full.yaml
```

### 4. Combine with Deep Context

For maximum AI effectiveness:

```bash
# Generate deep context
pmat context --output deep_context.md

# Generate defect-aware prompt with context
pmat prompt generate \
  --task "Add caching layer" \
  --context "$(cat deep_context.md)" \
  --summary org_summary.yaml
```

### 5. Share Summaries with Team

Organizational intelligence benefits the entire team:

```bash
# Store in shared location
pmat org analyze --org mycompany \
  --output /shared/org_summary.yaml \
  --summarize --strip-pii

# Team members can use
pmat prompt generate \
  --task "..." \
  --summary /shared/org_summary.yaml
```

## Toyota Way Principles

### Genchi Genbutsu (Go and See)

Organizational intelligence embodies "go and see" by analyzing ACTUAL commit history:
- Not assumptions about defects
- Not generic best practices
- Real data from YOUR organization

### Kaizen (Continuous Improvement)

Monthly analysis enables continuous improvement:
- Track defect patterns over time
- Measure improvement in defect categories
- Identify systemic issues

### Muda (Waste Elimination)

Prevent repeating past mistakes:
- Defect-aware prompts reduce rework
- Organizational intelligence prevents defects
- Less time debugging, more time building

### Jidoka (Built-in Quality)

Quality built into the development process:
- AI prompts informed by organizational patterns
- Prevention, not detection
- Stop the line before defects occur

## Summary

The `pmat org` command provides organizational intelligence by analyzing GitHub commit history:

- **Analyze organizations** with `pmat org analyze`
- **Extract defect patterns** from commit messages
- **Generate summaries** with PII stripping
- **Integrate with AI prompts** for defect prevention
- **Track improvements** over time

**Key Benefits:**
- Data-driven defect prevention
- Privacy-first design (PII stripping)
- Seamless AI integration
- Toyota Way principles (Genchi Genbutsu, Kaizen)

**Next Steps:**
- See [Chapter 9: Workflow Prompts](ch09-01-prompt-command.md) for `pmat prompt generate`
- See [Chapter 15: MCP Tools Reference](ch15-00-mcp-tools.md) for AI assistant integration
- See [Chapter 4: TDG Enforcement](ch04-02-tdg-enforcement.md) for quality gates

**Related Commands:**
- `pmat prompt generate` - Generate defect-aware AI prompts
- `pmat context` - Generate deep context for AI assistants
- `pmat quality-gate` - Run quality gates with organizational intelligence
