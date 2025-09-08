# Chapter 16: CI/CD Integration

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (8/8 examples)

| Status | Count | Examples |
|--------|-------|----------|
| ✅ Working | 8 | All CI/CD integration configurations tested |
| ⚠️ Not Implemented | 0 | Planned for future versions |
| ❌ Broken | 0 | Known issues, needs fixing |
| 📋 Planned | 0 | Future roadmap features |

*Last updated: 2025-09-08*  
*PMAT version: pmat 2.64.0*  
*Test-Driven: All examples validated in `tests/ch16/test_cicd.sh`*
<!-- DOC_STATUS_END -->

## Integrating PMAT with CI/CD Pipelines

PMAT seamlessly integrates with all major CI/CD platforms to provide automated quality gates, regression detection, and comprehensive reporting in your deployment pipeline.

## GitHub Actions Integration

```yaml
# .github/workflows/pmat-quality.yml
name: PMAT Quality Analysis

on:
  push:
    branches: [main, develop]
  pull_request:
    types: [opened, synchronize]

jobs:
  quality-analysis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        
      - name: Install PMAT
        run: |
          cargo install pmat
          pmat --version
          
      - name: Run Quality Analysis
        run: |
          pmat analyze . --format=json > quality-report.json
          pmat quality-gate --strict --min-grade=B+
          
      - name: Upload Quality Report
        uses: actions/upload-artifact@v3
        with:
          name: quality-report
          path: quality-report.json
```

## GitLab CI Integration

```yaml
# .gitlab-ci.yml
stages:
  - quality
  - build
  - test
  - deploy

pmat-analysis:
  stage: quality
  image: rust:latest
  before_script:
    - cargo install pmat
  script:
    - pmat analyze . --comprehensive
    - pmat quality-gate --fail-below=B
  artifacts:
    reports:
      junit: pmat-results.xml
    paths:
      - quality-report.*
  only:
    - merge_requests
    - main
```

## Jenkins Pipeline

```groovy
// Jenkinsfile
pipeline {
    agent any
    
    stages {
        stage('Quality Analysis') {
            steps {
                sh 'cargo install pmat'
                sh 'pmat analyze . --format=json > quality-report.json'
                sh 'pmat quality-gate --strict || exit 1'
            }
            post {
                always {
                    archiveArtifacts 'quality-report.json'
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: '.',
                        reportFiles: 'quality-report.html',
                        reportName: 'PMAT Quality Report'
                    ])
                }
            }
        }
    }
}
```

## Azure DevOps

```yaml
# azure-pipelines.yml
trigger:
- main
- develop

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: Bash@3
  displayName: 'Install PMAT'
  inputs:
    targetType: 'inline'
    script: 'cargo install pmat'

- task: Bash@3
  displayName: 'Run Quality Analysis'
  inputs:
    targetType: 'inline'
    script: |
      pmat analyze . --comprehensive
      pmat quality-gate --min-grade B+

- task: PublishTestResults@2
  inputs:
    testResultsFormat: 'JUnit'
    testResultsFiles: 'pmat-results.xml'
```

## Quality Gates Configuration

```toml
# pmat.toml - CI/CD specific settings
[cicd]
enabled = true
fail_on_regression = true
generate_reports = true

[quality_gates]
strict_mode = true
min_grade = "B+"
fail_on_critical = true
allow_warnings = 10

[reporting]
formats = ["json", "junit", "html"]
include_trends = true
compare_with_baseline = true

[notifications]
slack_webhook = "${SLACK_WEBHOOK_URL}"
email_reports = true
jira_integration = true
```

## Advanced Pipeline Features

### Parallel Analysis

```yaml
# Parallel analysis for large codebases
strategy:
  matrix:
    component: [frontend, backend, mobile, shared]
steps:
  - name: Analyze Component
    run: |
      pmat analyze ${{ matrix.component }}/ \
        --component-mode \
        --output=${{ matrix.component }}-report.json
        
  - name: Merge Reports
    run: pmat reports merge *-report.json --output=final-report.json
```

### Conditional Analysis

```yaml
# Only analyze changed components
- name: Detect Changes
  id: changes
  run: |
    echo "frontend=$(git diff --name-only HEAD~1 | grep '^frontend/' | wc -l)" >> $GITHUB_OUTPUT
    echo "backend=$(git diff --name-only HEAD~1 | grep '^backend/' | wc -l)" >> $GITHUB_OUTPUT
    
- name: Analyze Frontend
  if: steps.changes.outputs.frontend != '0'
  run: pmat analyze frontend/ --detailed
  
- name: Analyze Backend  
  if: steps.changes.outputs.backend != '0'
  run: pmat analyze backend/ --detailed
```

### Security Scanning Integration

```yaml
- name: Security Analysis
  run: |
    pmat security scan . --severity=critical
    pmat security dependencies --check-vulnerabilities
    pmat security secrets --scan-history
```

## Deployment Quality Gates

```yaml
# Quality gates for different environments
- name: Development Quality Gate
  if: github.ref == 'refs/heads/develop'
  run: pmat quality-gate --min-grade=C+ --allow-warnings
  
- name: Staging Quality Gate
  if: github.ref == 'refs/heads/staging'
  run: pmat quality-gate --min-grade=B --max-warnings=5
  
- name: Production Quality Gate
  if: github.ref == 'refs/heads/main'
  run: pmat quality-gate --min-grade=A- --zero-critical --comprehensive
```

## Performance Regression Testing

```yaml
- name: Performance Regression Check
  run: |
    pmat performance benchmark . --baseline=main
    pmat performance compare \
      --current=HEAD \
      --baseline=main \
      --fail-on-regression=10%
```

## Multi-Environment Support

```yaml
# Environment-specific configurations
env:
  PMAT_CONFIG_DEV: ".pmat/dev-config.toml"
  PMAT_CONFIG_STAGING: ".pmat/staging-config.toml"
  PMAT_CONFIG_PROD: ".pmat/prod-config.toml"
  
steps:
  - name: Set Environment Config
    run: |
      if [ "${{ github.ref }}" == "refs/heads/develop" ]; then
        export PMAT_CONFIG="$PMAT_CONFIG_DEV"
      elif [ "${{ github.ref }}" == "refs/heads/staging" ]; then
        export PMAT_CONFIG="$PMAT_CONFIG_STAGING"  
      else
        export PMAT_CONFIG="$PMAT_CONFIG_PROD"
      fi
      pmat analyze . --config="$PMAT_CONFIG"
```

## Reporting and Notifications

### Slack Integration

```yaml
- name: Notify Slack on Quality Issues
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    channel: '#quality-alerts'
    text: |
      🚨 Quality gate failed for ${{ github.repository }}
      Branch: ${{ github.ref }}
      Commit: ${{ github.sha }}
      See details: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

### Email Reports

```yaml
- name: Generate and Email Report
  run: |
    pmat report generate --format=html --output=quality-report.html
    pmat notify email \
      --to="${{ secrets.TEAM_EMAIL }}" \
      --subject="Quality Report - ${{ github.ref }}" \
      --attachment=quality-report.html
```

## Container Integration

### Docker Analysis

```dockerfile
# Dockerfile.pmat
FROM rust:latest

RUN cargo install pmat

WORKDIR /app
COPY . .

RUN pmat analyze . --comprehensive --output=/reports/

CMD ["pmat", "serve-reports", "--port=8080"]
```

### Kubernetes Quality Checks

```yaml
# k8s-quality-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: pmat-quality-check
spec:
  template:
    spec:
      containers:
      - name: pmat
        image: pmat:latest
        command: ["pmat"]
        args: ["analyze", ".", "--k8s-mode"]
        volumeMounts:
        - name: source-code
          mountPath: /app
        - name: reports
          mountPath: /reports
      restartPolicy: Never
      volumes:
      - name: source-code
        configMap:
          name: source-code
      - name: reports
        persistentVolumeClaim:
          claimName: pmat-reports
```

## Summary

PMAT CI/CD integration provides:
- **Automated Quality Gates**: Prevent poor quality code from reaching production
- **Multi-Platform Support**: Works with all major CI/CD systems
- **Flexible Configuration**: Environment-specific quality standards
- **Comprehensive Reporting**: Detailed analysis reports and notifications
- **Performance Monitoring**: Track quality trends over time

## Next Steps

- [Chapter 17: Plugin Development](ch17-00-plugins.md)
- [Chapter 18: API Integration](ch18-00-api.md)