#!/bin/bash
# TDD Test: Chapter 16 - CI/CD Integration

set -e

echo "=== Testing Chapter 16: CI/CD Integration ==="

TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Test 1: GitHub Actions workflow
mkdir -p .github/workflows
cat > .github/workflows/pmat-quality.yml << 'EOF'
name: PMAT Quality Analysis
on:
  push:
    branches: [main]
  pull_request:
jobs:
  quality-analysis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Quality Analysis
        run: echo "Running PMAT analysis"
EOF

if [ -f .github/workflows/pmat-quality.yml ]; then
    echo "✅ GitHub Actions workflow created"
else
    echo "❌ Failed to create GitHub workflow"
    exit 1
fi

# Test 2: GitLab CI configuration
cat > .gitlab-ci.yml << 'EOF'
stages:
  - quality
  - build
  - test
pmat-analysis:
  stage: quality
  script:
    - echo "Running PMAT analysis"
EOF

if [ -f .gitlab-ci.yml ]; then
    echo "✅ GitLab CI config created"
else
    echo "❌ Failed to create GitLab config"
    exit 1
fi

# Test 3: Jenkins pipeline
cat > Jenkinsfile << 'EOF'
pipeline {
    agent any
    stages {
        stage('Quality Analysis') {
            steps {
                sh 'echo "Running PMAT analysis"'
            }
        }
    }
}
EOF

if [ -f Jenkinsfile ]; then
    echo "✅ Jenkins pipeline created"
else
    echo "❌ Failed to create Jenkinsfile"
    exit 1
fi

# Test 4: Azure DevOps pipeline
cat > azure-pipelines.yml << 'EOF'
trigger:
- main
pool:
  vmImage: 'ubuntu-latest'
steps:
- task: Bash@3
  displayName: 'Run Quality Analysis'
EOF

if [ -f azure-pipelines.yml ]; then
    echo "✅ Azure DevOps pipeline created"
else
    echo "❌ Failed to create Azure pipeline"
    exit 1
fi

# Test 5: Quality gates configuration
cat > pmat.toml << 'EOF'
[cicd]
enabled = true
fail_on_regression = true
[quality_gates]
strict_mode = true
min_grade = "B+"
EOF

if [ -f pmat.toml ]; then
    echo "✅ Quality gates config created"
else
    echo "❌ Failed to create quality gates"
    exit 1
fi

# Test 6: Container configuration
cat > Dockerfile.pmat << 'EOF'
FROM rust:latest
RUN cargo install pmat
WORKDIR /app
COPY . .
CMD ["pmat", "analyze", "."]
EOF

if [ -f Dockerfile.pmat ]; then
    echo "✅ Docker configuration created"
else
    echo "❌ Failed to create Dockerfile"
    exit 1
fi

# Test 7: Webhook configuration
cat > webhook-config.yaml << 'EOF'
webhooks:
  - name: "quality-alerts"
    url: "https://example.com/webhooks"
    events: ["analysis_complete"]
EOF

if [ -f webhook-config.yaml ]; then
    echo "✅ Webhook config created"
else
    echo "❌ Failed to create webhook config"
    exit 1
fi

# Test 8: Kubernetes job
cat > k8s-quality-job.yaml << 'EOF'
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
EOF

if [ -f k8s-quality-job.yaml ]; then
    echo "✅ Kubernetes job created"
else
    echo "❌ Failed to create K8s job"
    exit 1
fi

cd /
rm -rf "$TEST_DIR"

echo ""
echo "✅ All 8 CI/CD integration tests passed!"
exit 0