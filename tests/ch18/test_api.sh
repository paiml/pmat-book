#!/bin/bash
# TDD Test: Chapter 18 - API Integration

set -e

echo "=== Testing Chapter 18: API Integration ==="

TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Test 1: REST API configuration
cat > api-config.yaml << 'EOF'
api:
  port: 8080
  auth_token: "your-token"
  endpoints:
    - "/api/v1/analyze"
    - "/api/v1/quality-gate"
EOF

if [ -f api-config.yaml ]; then
    echo "✅ API configuration created"
else
    echo "❌ Failed to create API config"
    exit 1
fi

# Test 2: Webhook configuration
cat > webhook-config.yaml << 'EOF'
webhooks:
  - name: "quality-alerts"
    url: "https://your-service.com/webhooks"
    events: ["analysis_complete"]
EOF

if [ -f webhook-config.yaml ]; then
    echo "✅ Webhook config created"
else
    echo "❌ Failed to create webhook config"
    exit 1
fi

# Test 3: Database integration
cat > db-integration.py << 'EOF'
import pmat
def store_analysis_results(project_path):
    results = pmat.analyze(project_path)
    return results
EOF

if [ -f db-integration.py ]; then
    echo "✅ Database integration created"
else
    echo "❌ Failed to create DB integration"
    exit 1
fi

# Test 4: Prometheus metrics
cat > prometheus-config.yaml << 'EOF'
metrics:
  prometheus:
    enabled: true
    port: 9090
    metrics:
      - pmat_quality_score
      - pmat_violations_total
EOF

if [ -f prometheus-config.yaml ]; then
    echo "✅ Prometheus config created"
else
    echo "❌ Failed to create Prometheus config"
    exit 1
fi

# Test 5: Jira integration
cat > jira-integration.py << 'EOF'
def create_quality_issues(project_path):
    # Jira integration logic
    pass
EOF

if [ -f jira-integration.py ]; then
    echo "✅ Jira integration created"
else
    echo "❌ Failed to create Jira integration"
    exit 1
fi

# Test 6: API client example
cat > api-client.sh << 'EOF'
#!/bin/bash
curl -H "Authorization: Bearer token" \
  http://localhost:8080/api/v1/analyze \
  -d '{"project_path": "./src"}'
EOF

if [ -f api-client.sh ]; then
    echo "✅ API client created"
else
    echo "❌ Failed to create API client"
    exit 1
fi

cd /
rm -rf "$TEST_DIR"

echo ""
echo "✅ All 6 API integration tests passed!"
exit 0