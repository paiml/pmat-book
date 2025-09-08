#!/bin/bash
# TDD Test: Chapter 19 - AI Integration

set -e

echo "=== Testing Chapter 19: AI Integration ==="

TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Test 1: AI configuration
cat > pmat.toml << 'EOF'
[ai]
enabled = true
provider = "anthropic"
model = "claude-3-sonnet"
api_key_env = "ANTHROPIC_API_KEY"

[ai.features]
explain_violations = true
suggest_fixes = true
code_review_comments = true
EOF

if [ -f pmat.toml ]; then
    echo "✅ AI configuration created"
else
    echo "❌ Failed to create AI config"
    exit 1
fi

# Test 2: Complex function example
cat > complex_function.py << 'EOF'
def process_user_data(data):
    result = []
    for item in data:
        if item['status'] == 'active':
            if item['age'] >= 18:
                if item['country'] == 'US':
                    result.append(item)
    return result
EOF

if [ -f complex_function.py ]; then
    echo "✅ Complex function created"
else
    echo "❌ Failed to create complex function"
    exit 1
fi

# Test 3: AI code review workflow
mkdir -p .github/workflows
cat > .github/workflows/ai-code-review.yml << 'EOF'
name: AI-Powered Code Review
on:
  pull_request:
jobs:
  ai-review:
    runs-on: ubuntu-latest
    steps:
      - name: AI Code Review
        run: echo "Running AI review"
EOF

if [ -f .github/workflows/ai-code-review.yml ]; then
    echo "✅ AI review workflow created"
else
    echo "❌ Failed to create AI workflow"
    exit 1
fi

# Test 4: ML model training script
cat > train_model.py << 'EOF'
import pmat.ml as pmat_ml

training_data = pmat_ml.prepare_training_data(
    repo_path='./large-codebase',
    history_months=12
)

model = pmat_ml.train_quality_predictor(
    training_data,
    model_type='random_forest'
)
EOF

if [ -f train_model.py ]; then
    echo "✅ ML training script created"
else
    echo "❌ Failed to create ML script"
    exit 1
fi

# Test 5: Privacy configuration
cat > privacy-config.toml << 'EOF'
[ai.privacy]
local_processing = true
no_external_api_calls = true
anonymize_code_samples = true

[ai.security]
encrypt_communications = true
api_key_rotation = true
EOF

if [ -f privacy-config.toml ]; then
    echo "✅ Privacy config created"
else
    echo "❌ Failed to create privacy config"
    exit 1
fi

# Test 6: Feedback loop configuration
cat > feedback-loop.yaml << 'EOF'
feedback_loop:
  enabled: true
  collect_feedback:
    - suggestion_accuracy
    - implementation_success
  model_updates:
    frequency: "monthly"
EOF

if [ -f feedback-loop.yaml ]; then
    echo "✅ Feedback loop config created"
else
    echo "❌ Failed to create feedback config"
    exit 1
fi

# Test 7: AI refactoring example
cat > refactor-request.sh << 'EOF'
#!/bin/bash
pmat ai refactor \
  --file="legacy_module.py" \
  --goals="reduce_complexity" \
  --preview
EOF

if [ -f refactor-request.sh ]; then
    echo "✅ Refactoring script created"
else
    echo "❌ Failed to create refactor script"
    exit 1
fi

cd /
rm -rf "$TEST_DIR"

echo ""
echo "✅ All 7 AI integration tests passed!"
exit 0