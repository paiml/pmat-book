#!/usr/bin/env bash
# Install git hooks for pmat-book repository
#
# Run this script after cloning the repository to set up git hooks:
#   bash scripts/install-hooks.sh

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Installing git hooks for pmat-book...${NC}"

# Get the repository root directory
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK_DIR="${REPO_ROOT}/.git/hooks"

# Check if we're in a git repository
if [ ! -d "${REPO_ROOT}/.git" ]; then
    echo -e "${YELLOW}Error: Not in a git repository${NC}"
    exit 1
fi

# Create pre-commit hook
cat > "${HOOK_DIR}/pre-commit" <<'EOF'
#!/usr/bin/env bash
# Pre-commit hook for pmat-book repository
# Prevents the 404 issue by warning about unpushed commits
#
# This hook ensures that all commits are pushed to GitHub to trigger
# the GitHub Pages deployment workflow.

set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Get the current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Get the remote tracking branch
REMOTE_BRANCH=$(git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null || echo "")

if [ -z "${REMOTE_BRANCH}" ]; then
    echo -e "${YELLOW}⚠️  Warning: No remote tracking branch set for ${CURRENT_BRANCH}${NC}"
    echo -e "${YELLOW}   Set up tracking with: git push -u origin ${CURRENT_BRANCH}${NC}"
    exit 0
fi

# Check for unpushed commits
UNPUSHED_COMMITS=$(git log "${REMOTE_BRANCH}..HEAD" --oneline 2>/dev/null || echo "")

if [ -n "${UNPUSHED_COMMITS}" ]; then
    COMMIT_COUNT=$(echo "${UNPUSHED_COMMITS}" | wc -l)

    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}⚠️  WARNING: You have ${COMMIT_COUNT} unpushed commit(s)${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}Unpushed commits:${NC}"
    echo "${UNPUSHED_COMMITS}"
    echo ""
    echo -e "${YELLOW}⚠️  These commits are NOT deployed to GitHub Pages!${NC}"
    echo -e "${YELLOW}   The book at https://paiml.github.io/pmat-book/ is out of date.${NC}"
    echo ""
    echo -e "${GREEN}To fix this, push your commits after this commit:${NC}"
    echo -e "${GREEN}   git push origin ${CURRENT_BRANCH}${NC}"
    echo ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Allow the commit but remind to push
    echo -e "${GREEN}✅ Commit allowed, but REMEMBER TO PUSH!${NC}"
    echo ""
fi

# Run mdbook test if mdbook is available (warning-only, doesn't block commit)
if command -v mdbook >/dev/null 2>&1; then
    echo -e "${GREEN}Running mdbook test...${NC}"
    if mdbook test 2>&1 | grep -q "test result: FAILED"; then
        echo -e "${YELLOW}⚠️  mdbook test has failures (not blocking commit)${NC}"
        echo -e "${YELLOW}   Run 'mdbook test' to see details${NC}"
    else
        echo -e "${GREEN}✅ mdbook test passed${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  mdbook not found, skipping book tests${NC}"
    echo -e "${YELLOW}   Install with: cargo install mdbook${NC}"
fi

exit 0
EOF

# Make the hook executable
chmod +x "${HOOK_DIR}/pre-commit"

echo -e "${GREEN}✅ Pre-commit hook installed successfully${NC}"
echo ""
echo -e "${GREEN}The hook will:${NC}"
echo -e "  1. Warn you about unpushed commits (prevents 404 issues)"
echo -e "  2. Run mdbook test (warning-only, doesn't block commits)"
echo ""
echo -e "${YELLOW}To bypass the hook (not recommended):${NC}"
echo -e "  git commit --no-verify"
