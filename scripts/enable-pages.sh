#!/bin/bash
# Script to help enable GitHub Pages for the repository

echo "=== GitHub Pages Setup Instructions ==="
echo ""
echo "The deployment workflow is ready! To enable GitHub Pages:"
echo ""
echo "1. Go to: https://github.com/paiml/pmat-book/settings/pages"
echo ""
echo "2. Under 'Build and deployment':"
echo "   - Source: Select 'GitHub Actions'"
echo ""
echo "3. The deployment workflow will run automatically on the next push"
echo ""
echo "4. Once deployed, the book will be available at:"
echo "   📚 https://paiml.github.io/pmat-book/"
echo ""
echo "Current deployment status:"
echo "https://github.com/paiml/pmat-book/actions/workflows/deploy.yml"
echo ""
echo "If you have the GitHub CLI installed, you can enable it with:"
echo "gh api repos/paiml/pmat-book/pages -X POST -f source.workflow.branch=main"
echo ""

# Try to enable with GitHub CLI if available
if command -v gh &> /dev/null; then
    echo "GitHub CLI detected. Attempting to enable Pages..."
    if gh api repos/paiml/pmat-book/pages -X POST -f source.workflow.branch=main 2>/dev/null; then
        echo "✅ GitHub Pages enabled successfully!"
    else
        echo "⚠️  Could not enable Pages automatically. Please follow manual steps above."
    fi
else
    echo "ℹ️  GitHub CLI not found. Please follow the manual steps above."
fi