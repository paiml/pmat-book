# Chapter 15: Team Workflows

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (5/5 examples)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 5 | All team workflow configurations tested |
| ⚠️ Not Implemented | 0 | Planned for future versions |
| ❌ Broken | 0 | Known issues, needs fixing |
| 📋 Planned | 0 | Future roadmap features |

*Last updated: 2025-09-08*  
*PMAT version: pmat 2.64.0*  
*Test-Driven: All examples validated in `tests/ch15/test_team_workflows.sh`*
<!-- DOC_STATUS_END -->

## Collaborative Code Quality with PMAT

PMAT transforms code quality from individual responsibility to team-wide practice. Learn how to implement quality gates, coordinate team standards, and maintain consistency across large development teams.

## Team Quality Standards

### Establishing Team Rules

```yaml
# .pmat/team-standards.yaml
team:
  name: "Backend Engineering"
  quality_baseline: "B+"
  
standards:
  complexity:
    max_cyclomatic: 8
    max_cognitive: 12
    
  documentation:
    min_coverage: 80
    require_api_docs: true
    
  security:
    scan_dependencies: true
    check_secrets: true
    
  testing:
    min_coverage: 85
    require_integration_tests: true

workflow:
  pre_commit:
    - "quality_gate"
    - "security_scan"
    - "format_check"
    
  pre_merge:
    - "comprehensive_analysis"
    - "regression_check"
    - "team_review"
```

### Code Review Integration

```bash
# Automated code review preparation
pmat review prepare --pr-number=123

# Generate review checklist
pmat review checklist --focus="security,performance"

# Post-review quality report
pmat review report --compare-baseline
```

## Multi-Team Coordination

```yaml
# .pmat/multi-team.yaml
organization:
  teams:
    - name: "frontend"
      standards: "web-quality-standards.yaml"
      components: ["ui", "mobile"]
      
    - name: "backend" 
      standards: "api-quality-standards.yaml"
      components: ["services", "database"]
      
    - name: "platform"
      standards: "infrastructure-standards.yaml"
      components: ["devops", "monitoring"]

shared_standards:
  security: "mandatory"
  documentation: "required"
  testing: "minimum_80_percent"
  
escalation:
  critical_violations: "platform_team"
  security_issues: "security_team"
  performance_regressions: "architecture_team"
```

## Quality Dashboards

```bash
# Generate team dashboard
pmat dashboard generate \
  --team="backend-engineering" \
  --metrics="quality,velocity,debt" \
  --period="last-30-days"

# Real-time quality monitoring
pmat dashboard serve \
  --port=8080 \
  --auto-refresh=5min
```

## Knowledge Sharing

```bash
# Quality retrospectives
pmat retrospective generate \
  --period="sprint-23" \
  --focus="lessons-learned"

# Best practices extraction
pmat knowledge extract \
  --from-commits="last-quarter" \
  --output="team-best-practices.md"
```

## Summary

Team workflows with PMAT enable:
- **Consistent Standards**: Unified quality expectations across teams
- **Collaborative Reviews**: Enhanced code review processes
- **Knowledge Sharing**: Capture and distribute quality insights
- **Progress Tracking**: Monitor team quality metrics over time

## Next Steps

- [Chapter 16: CI/CD Integration](ch16-00-cicd.md)
- [Chapter 17: Plugin Development](ch17-00-plugins.md)