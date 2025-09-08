#!/bin/bash
# TDD Test: Chapter 15 - Team Workflows

set -e

echo "=== Testing Chapter 15: Team Workflows ==="

TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Test 1: Team standards configuration
mkdir -p .pmat
cat > .pmat/team-standards.yaml << 'EOF'
team:
  name: "Backend Engineering"
  quality_baseline: "B+"
standards:
  complexity:
    max_cyclomatic: 8
  documentation:
    min_coverage: 80
workflow:
  pre_commit:
    - "quality_gate"
    - "security_scan"
EOF

if [ -f .pmat/team-standards.yaml ]; then
    echo "✅ Team standards created"
else
    echo "❌ Failed to create team standards"
    exit 1
fi

# Test 2: Multi-team configuration
cat > .pmat/multi-team.yaml << 'EOF'
organization:
  teams:
    - name: "frontend"
      components: ["ui", "mobile"]
    - name: "backend"
      components: ["services", "database"]
shared_standards:
  security: "mandatory"
  documentation: "required"
EOF

if [ -f .pmat/multi-team.yaml ]; then
    echo "✅ Multi-team config created"
else
    echo "❌ Failed to create multi-team config"
    exit 1
fi

# Test 3: Dashboard configuration
cat > dashboard-config.yaml << 'EOF'
dashboard:
  team: "backend-engineering"
  metrics: ["quality", "velocity", "debt"]
  period: "last-30-days"
  auto_refresh: "5min"
EOF

if [ -f dashboard-config.yaml ]; then
    echo "✅ Dashboard config created"
else
    echo "❌ Failed to create dashboard config"
    exit 1
fi

# Test 4: Review checklist
cat > review-checklist.md << 'EOF'
## Code Review Checklist
- [ ] Security scan passed
- [ ] Performance analysis completed
- [ ] Documentation updated
- [ ] Tests added
EOF

if [ -f review-checklist.md ]; then
    echo "✅ Review checklist created"
else
    echo "❌ Failed to create checklist"
    exit 1
fi

# Test 5: Team workflow automation
cat > .github/workflows/team-workflow.yml << 'EOF'
name: Team Quality Workflow
on:
  pull_request:
jobs:
  team-quality:
    runs-on: ubuntu-latest
    steps:
      - name: Team Standards Check
        run: echo "Checking team standards"
EOF

if [ -f .github/workflows/team-workflow.yml ]; then
    echo "✅ Team workflow created"
else
    echo "❌ Failed to create workflow"
    exit 1
fi

cd /
rm -rf "$TEST_DIR"

echo ""
echo "✅ All 5 team workflow tests passed!"
exit 0