# Chapter 19: Agent Management and Continuous Monitoring

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (12/12 examples)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 12 | Ready for production use |
| ⚠️ Not Implemented | 0 | Planned for future versions |
| ❌ Broken | 0 | Known issues, needs fixing |
| 📋 Planned | 0 | Future roadmap features |

*Last updated: 2025-09-12*  
*PMAT version: pmat 2.69.0*
<!-- DOC_STATUS_END -->

## The Problem

Development teams need continuous quality monitoring that works in the background without interrupting the development workflow. Manual quality checks are often forgotten, and by the time issues are discovered, they've accumulated significant technical debt. The PMAT agent system provides automated, continuous quality monitoring with intelligent alerting and self-healing capabilities.

## Core Concepts

### Agent Architecture

PMAT's agent system provides:
- **Background Daemon**: Runs continuously monitoring multiple projects
- **Intelligent Monitoring**: Adaptive analysis based on code changes
- **Quality Thresholds**: Configurable quality gates with alerts
- **Auto-healing**: Automatic issue detection and suggested fixes
- **Resource Management**: Memory limits and auto-restart capabilities
- **MCP Integration**: Direct integration with Claude Code and other tools

### Continuous Quality Loop

```mermaid
graph LR
    A[Code Change] --> B[Agent Detects]
    B --> C[Run Analysis]
    C --> D{Quality Gate}
    D -->|Pass| E[Continue]
    D -->|Fail| F[Alert Team]
    F --> G[Suggest Fix]
    G --> A
```

## Starting the Agent Daemon

### Basic Agent Startup

```bash
# Start agent daemon
pmat agent start

# Start with specific project
pmat agent start --project-path /path/to/project

# Start with custom configuration
pmat agent start --config agent-config.toml

# Run in foreground (for testing)
pmat agent start --foreground
```

**Output:**
```
🤖 PMAT Agent starting...
📁 Monitoring: /path/to/project
🔍 Initial analysis complete
⚡ Background monitoring active
🆔 Agent PID: 12345
```

### Agent Configuration

```toml
# agent-config.toml
[daemon]
working_dir = "/tmp/pmat-agent"
pid_file = "/tmp/pmat-agent.pid"
log_file = "/var/log/pmat-agent.log"
health_interval = 30
max_memory_mb = 500
auto_restart = true

[monitoring]
scan_interval = 300  # 5 minutes
deep_analysis_interval = 3600  # 1 hour
file_watch = true
git_hooks = true

[quality]
min_grade = "B+"
max_complexity = 15
min_test_coverage = 80
alert_on_degradation = true

[notifications]
slack_webhook = "https://hooks.slack.com/services/..."
email_smtp = "smtp.company.com"
email_recipients = ["team@company.com"]

[resources]
max_cpu_percent = 25
max_memory_mb = 500
cache_size_mb = 100
```

## Project Monitoring

### Single Project Monitoring

```bash
# Monitor current directory
pmat agent monitor --project-path .

# Monitor with custom ID
pmat agent monitor --project-path . --project-id "main-api"

# Monitor with quality thresholds
pmat agent monitor --project-path . \
  --thresholds quality-config.toml
```

**Output:**
```
📁 Project: main-api
📊 Baseline analysis complete
   - Files: 150
   - Functions: 500
   - Current grade: B+
   - Complexity hotspots: 3
🔍 Continuous monitoring started
```

### Multi-Project Monitoring

```bash
# Monitor multiple projects
pmat agent monitor --project-path /apps/frontend --project-id "frontend"
pmat agent monitor --project-path /apps/backend --project-id "backend"
pmat agent monitor --project-path /libs/shared --project-id "shared-lib"
```

**Monitoring Dashboard:**
```bash
# Check all monitored projects
pmat agent status

# Output:
# 🤖 PMAT Agent Status
# ==================
# Status: Running (PID: 12345)
# Uptime: 2h 15m
# Memory: 125MB / 500MB
# 
# Monitored Projects:
# - frontend    (Grade: A-)  Last check: 2m ago
# - backend     (Grade: B+)  Last check: 1m ago  
# - shared-lib  (Grade: A)   Last check: 5m ago
# 
# Recent Alerts: 1
# - backend: Complexity increased in auth.rs
```

## Quality Threshold Configuration

### Threshold Definition

```toml
# quality-thresholds.toml
[thresholds]
min_grade = "B+"
max_complexity_function = 10
max_complexity_file = 50
min_test_coverage = 80
max_satd_count = 5
max_dead_code_percent = 5

[alerts]
grade_degradation = true
complexity_spike = true
test_coverage_drop = true
new_technical_debt = true

[actions]
auto_comment_pr = true
block_merge = false
suggest_refactoring = true
create_jira_ticket = false
```

### Real-time Quality Monitoring

```bash
# Monitor with real-time feedback
pmat agent start --foreground --verbose
```

**Real-time Output:**
```
🔍 [14:30:15] Scanning project-frontend...
📊 [14:30:16] Analysis complete: Grade A- (no change)
⚡ [14:30:45] File changed: src/components/UserProfile.tsx
🔍 [14:30:46] Incremental analysis...
⚠️  [14:30:47] ALERT: Complexity increased from 8 to 12
📝 [14:30:47] Suggestion: Extract helper function from UserProfile.render()
🔔 [14:30:48] Notification sent to team Slack
```

## Advanced Agent Features

### Health Monitoring and Auto-restart

```bash
# Agent with health monitoring
pmat agent start \
  --health-interval 30 \
  --max-memory-mb 400 \
  --no-auto-restart false
```

**Health Check Output:**
```bash
pmat agent health

# Output:
# 🏥 Agent Health Check
# ====================
# Status: Healthy ✅
# CPU Usage: 2.5%
# Memory: 125MB / 400MB (31%)
# Disk I/O: Normal
# Network: Normal
# Last Analysis: 45s ago
# Cache Hit Rate: 87%
# 
# Monitored Projects: 3/3 responsive
# Recent Restarts: 0
# Uptime: 1d 3h 22m
```

### Git Integration

```bash
# Enable git hooks monitoring
pmat agent monitor --project-path . --git-hooks
```

The agent automatically installs git hooks:

```bash
# .git/hooks/pre-commit (installed by agent)
#!/bin/bash
echo "🤖 PMAT Agent: Running pre-commit analysis..."
pmat agent quality-gate --fast
if [ $? -ne 0 ]; then
    echo "❌ Quality gate failed - commit blocked"
    exit 1
fi
```

### MCP Server Integration

```bash
# Start MCP server through agent
pmat agent mcp-server --config mcp-config.json
```

**MCP Configuration:**
```json
{
  "mcpServers": {
    "pmat-agent": {
      "command": "pmat",
      "args": ["agent", "mcp-server"],
      "env": {
        "PMAT_AGENT_MODE": "mcp",
        "PMAT_CONFIG": "./agent-config.toml"
      }
    }
  }
}
```

## Integration Examples

### CI/CD Pipeline Integration

```yaml
# .github/workflows/continuous-quality.yml
name: Continuous Quality with PMAT Agent

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  quality-gate:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup PMAT
      run: cargo install pmat
    
    - name: Start Quality Agent
      run: |
        pmat agent start --foreground --project-path . &
        AGENT_PID=$!
        echo "AGENT_PID=$AGENT_PID" >> $GITHUB_ENV
        sleep 5  # Wait for initial analysis
    
    - name: Run Quality Gate
      run: |
        pmat agent quality-gate --strict
        echo "Quality gate passed ✅"
    
    - name: Generate Quality Report
      if: always()
      run: |
        pmat agent status --format json > quality-report.json
        echo "📊 Quality Report Generated"
    
    - name: Stop Agent
      if: always()
      run: |
        kill ${{ env.AGENT_PID }} || true
    
    - name: Upload Quality Report
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: quality-report
        path: quality-report.json
```

### Docker Integration

```dockerfile
# Dockerfile with PMAT Agent
FROM rust:1.75-slim as builder

# Install PMAT
RUN cargo install pmat

FROM debian:bookworm-slim

# Copy PMAT binary
COPY --from=builder /usr/local/cargo/bin/pmat /usr/local/bin/pmat

# Create agent workspace
RUN mkdir -p /app /var/log/pmat
WORKDIR /app

# Copy project and configuration
COPY . .
COPY agent-config.toml /etc/pmat/config.toml

# Start agent as service
CMD ["pmat", "agent", "start", \
     "--config", "/etc/pmat/config.toml", \
     "--project-path", "/app", \
     "--foreground"]
```

### Kubernetes Deployment

```yaml
# k8s/pmat-agent-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pmat-agent
  namespace: development
spec:
  replicas: 1
  selector:
    matchLabels:
      app: pmat-agent
  template:
    metadata:
      labels:
        app: pmat-agent
    spec:
      containers:
      - name: pmat-agent
        image: pmat-agent:latest
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        env:
        - name: RUST_LOG
          value: "info"
        - name: PMAT_CONFIG
          value: "/etc/pmat/config.toml"
        volumeMounts:
        - name: source-code
          mountPath: /app
          readOnly: true
        - name: agent-config
          mountPath: /etc/pmat
          readOnly: true
        livenessProbe:
          exec:
            command:
            - pmat
            - agent
            - health
          initialDelaySeconds: 30
          periodSeconds: 30
      volumes:
      - name: source-code
        persistentVolumeClaim:
          claimName: source-code-pvc
      - name: agent-config
        configMap:
          name: pmat-agent-config
```

## Notification Systems

### Slack Integration

```bash
# Configure Slack notifications
cat > slack-config.toml << 'EOF'
[notifications.slack]
webhook_url = "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"
channel = "#dev-quality"
username = "PMAT Agent"
icon_emoji = ":robot_face:"

[notifications.rules]
grade_drop = true
complexity_increase = true
new_vulnerabilities = true
test_failures = true
EOF

pmat agent start --config slack-config.toml
```

**Slack Message Example:**
```
🤖 PMAT Quality Alert

Project: frontend-app
Severity: ⚠️ Warning

📉 Quality grade dropped: A- → B+
📍 File: src/components/UserDashboard.tsx
🎯 Issue: Cyclomatic complexity increased from 8 to 15

💡 Suggested Actions:
• Extract helper methods from render()
• Consider using a state machine for complex logic
• Add unit tests for new functionality

🔗 View Details: http://pmat-dashboard.company.com/projects/frontend-app
```

### Email Alerts

```toml
[notifications.email]
smtp_host = "smtp.company.com"
smtp_port = 587
username = "pmat-agent@company.com"
password = "${SMTP_PASSWORD}"
from_address = "pmat-agent@company.com"
to_addresses = ["dev-team@company.com", "lead@company.com"]

[notifications.email.templates]
subject = "PMAT Quality Alert: {{project}} - {{severity}}"
body_template = "email-alert.html"
```

## Performance Optimization

### Resource Management

```bash
# Monitor agent resource usage
pmat agent start \
  --max-memory-mb 400 \
  --max-cpu-percent 20 \
  --cache-size-mb 50
```

**Resource Monitoring:**
```bash
# Check agent performance
pmat agent status --verbose

# Output:
# 📊 Performance Metrics
# =====================
# CPU Usage: 2.1% (limit: 20%)
# Memory: 156MB / 400MB (39%)
# Cache: 32MB / 50MB (64% hit rate)
# 
# Analysis Performance:
# - Average analysis time: 2.3s
# - Incremental updates: 0.8s
# - Full project scan: 45s
# 
# I/O Statistics:
# - Files watched: 1,247
# - Git hooks: 3 active
# - Network requests: 12/hour
```

### Caching Strategy

```toml
[cache]
enabled = true
size_mb = 100
ttl_hours = 24
strategy = "lru"

[cache.analysis]
complexity_cache = true
dependency_cache = true
test_results_cache = true

[cache.cleanup]
auto_cleanup = true
max_age_days = 7
```

## Troubleshooting

### Common Issues

1. **Agent Not Starting**
```bash
# Check for port conflicts
pmat agent status --debug

# Clean restart
pmat agent stop
pmat agent start --foreground
```

2. **High Memory Usage**
```bash
# Reduce cache size
pmat agent reload --config reduced-memory.toml

# Monitor memory patterns
pmat agent status --memory-profile
```

3. **Slow Analysis Performance**
```bash
# Enable performance profiling
pmat agent start --trace --trace-filter="pmat=debug"

# Optimize for speed
cat > fast-config.toml << 'EOF'
[performance]
analysis_threads = 4
fast_mode = true
skip_large_files = true
max_file_size_kb = 500
EOF
```

## Advanced Configuration

### Custom Quality Rules

```toml
[rules.complexity]
max_function_complexity = 10
max_file_complexity = 50
cognitive_complexity_weight = 0.7

[rules.testing]
min_coverage_percent = 80
require_integration_tests = true
max_test_execution_time_ms = 5000

[rules.security]
scan_for_secrets = true
check_dependencies = true
require_security_review = false

[rules.documentation]
require_function_docs = true
max_undocumented_percent = 20
check_readme_freshness = true
```

### Plugin System

```toml
[plugins]
enabled = ["eslint", "clippy", "pytest", "security-scanner"]

[plugins.eslint]
config_file = ".eslintrc.js"
severity_mapping = { "error" = "critical", "warn" = "medium" }

[plugins.clippy]
deny_warnings = true
pedantic = false

[plugins.pytest]
min_coverage = 85
fail_under = 80
```

## Summary

The PMAT agent system transforms quality assurance from a manual, error-prone process into an automated, intelligent monitoring system. By running continuously in the background, the agent catches quality issues early, provides actionable feedback, and integrates seamlessly with existing development workflows. 

Key benefits include:
- **Proactive Quality Monitoring**: Catch issues before they become technical debt
- **Intelligent Alerting**: Context-aware notifications that don't create noise
- **Seamless Integration**: Works with existing CI/CD, git workflows, and development tools
- **Resource Efficient**: Designed to run continuously without impacting development performance
- **Team Collaboration**: Shared quality dashboards and automated team notifications

The agent system represents the evolution from reactive quality checks to proactive quality assurance, making high-quality code the default rather than an exception.