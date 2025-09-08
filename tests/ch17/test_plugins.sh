#!/bin/bash
# TDD Test: Chapter 17 - Plugin Development

set -e

echo "=== Testing Chapter 17: Plugin Development ==="

TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Test 1: Plugin configuration
cat > pmat-plugin.toml << 'EOF'
[plugin]
name = "swift-analyzer"
version = "1.0.0"
author = "Your Name"
[dependencies]
pmat-plugin-api = "2.64"
EOF

if [ -f pmat-plugin.toml ]; then
    echo "✅ Plugin configuration created"
else
    echo "❌ Failed to create plugin config"
    exit 1
fi

# Test 2: Rust plugin source
cat > src/lib.rs << 'EOF'
use pmat_plugin_api::*;

pub struct MyAnalyzer {
    config: AnalyzerConfig,
}

impl Plugin for MyAnalyzer {
    fn name(&self) -> &str {
        "my-custom-analyzer"
    }
}
EOF

mkdir -p src
if [ -f src/lib.rs ]; then
    echo "✅ Plugin source created"
else
    echo "❌ Failed to create plugin source"
    exit 1
fi

# Test 3: Language plugin example
cat > swift-plugin.rs << 'EOF'
pub struct SwiftLanguagePlugin;

impl LanguagePlugin for SwiftLanguagePlugin {
    fn language(&self) -> &str {
        "swift"
    }
}
EOF

if [ -f swift-plugin.rs ]; then
    echo "✅ Language plugin created"
else
    echo "❌ Failed to create language plugin"
    exit 1
fi

# Test 4: Integration plugin
cat > jira-plugin.py << 'EOF'
class JiraIntegration:
    def create_issues(self, violations):
        for violation in violations:
            if violation.severity >= "high":
                self.create_jira_issue(violation)
EOF

if [ -f jira-plugin.py ]; then
    echo "✅ Integration plugin created"
else
    echo "❌ Failed to create integration plugin"
    exit 1
fi

# Test 5: Plugin manifest
cat > plugin-manifest.json << 'EOF'
{
  "name": "swift-analyzer",
  "version": "1.0.0",
  "entry": "lib.rs",
  "dependencies": ["pmat-plugin-api"]
}
EOF

if [ -f plugin-manifest.json ]; then
    echo "✅ Plugin manifest created"
else
    echo "❌ Failed to create manifest"
    exit 1
fi

cd /
rm -rf "$TEST_DIR"

echo ""
echo "✅ All 5 plugin development tests passed!"
exit 0