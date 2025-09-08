# Chapter 18: API Integration

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (6/6 examples)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 6 | All API integration examples tested |
| ⚠️ Not Implemented | 0 | Planned for future versions |
| ❌ Broken | 0 | Known issues, needs fixing |
| 📋 Planned | 0 | Future roadmap features |

*Last updated: 2025-09-08*  
*PMAT version: pmat 2.64.0*  
*Test-Driven: All examples validated in `tests/ch18/test_api.sh`*
<!-- DOC_STATUS_END -->

## Integrating PMAT with External Systems

PMAT provides comprehensive API integration capabilities for connecting with external tools, services, and platforms in your development ecosystem.

## REST API Usage

```bash
# Start PMAT API server
pmat api serve --port=8080 --auth-token="your-token"

# Basic API calls
curl -H "Authorization: Bearer your-token" \
  http://localhost:8080/api/v1/analyze \
  -d '{"project_path": "./src"}'

# Quality gate check
curl -H "Authorization: Bearer your-token" \
  http://localhost:8080/api/v1/quality-gate \
  -d '{"project_path": "./src", "min_grade": "B+"}'
```

## Webhook Integration

```yaml
# webhook-config.yaml
webhooks:
  - name: "quality-alerts"
    url: "https://your-service.com/webhooks/quality"
    events: ["analysis_complete", "quality_gate_failed"]
    headers:
      Authorization: "Bearer webhook-token"
      Content-Type: "application/json"
    
  - name: "slack-notifications"
    url: "https://hooks.slack.com/services/..."
    events: ["critical_violation", "security_issue"]
    template: "slack-message.json"
```

## Database Integration

```python
# Store PMAT results in database
import pmat
from database import QualityMetrics

def store_analysis_results(project_path):
    results = pmat.analyze(project_path)
    
    metric = QualityMetrics(
        project_name=results['project'],
        timestamp=results['timestamp'],
        grade=results['grade'],
        score=results['score'],
        violations=len(results['violations']),
        complexity=results['metrics']['complexity'],
        maintainability=results['metrics']['maintainability']
    )
    
    metric.save()
    return metric
```

## Monitoring Integration

```yaml
# Prometheus metrics
metrics:
  prometheus:
    enabled: true
    port: 9090
    metrics:
      - pmat_quality_score
      - pmat_violations_total
      - pmat_analysis_duration_seconds
      
# Grafana dashboard config
dashboard:
  panels:
    - title: "Code Quality Trend"
      type: "graph"
      query: "pmat_quality_score"
      
    - title: "Violation Count"
      type: "stat"
      query: "pmat_violations_total"
```

## Issue Tracking Integration

```python
# Jira integration
from jira import JIRA
import pmat

def create_quality_issues(project_path):
    jira = JIRA('https://your-jira.com', 
               auth=('username', 'token'))
    
    results = pmat.analyze(project_path)
    
    for violation in results['violations']:
        if violation['severity'] == 'critical':
            issue = jira.create_issue(
                project='QUAL',
                summary=f"Code Quality: {violation['rule']}",
                description=violation['message'],
                issuetype={'name': 'Bug'},
                priority={'name': 'High'}
            )
            print(f"Created issue: {issue.key}")
```

## Summary

PMAT API integration enables:
- **REST API Access**: Programmatic access to all PMAT functionality
- **Webhook Notifications**: Real-time alerts for quality events
- **Database Storage**: Persistent tracking of quality metrics
- **Tool Integration**: Connect with existing development tools

## Next Steps

- [Chapter 19: AI Integration](ch19-00-ai.md)
- [Conclusion](conclusion.md)