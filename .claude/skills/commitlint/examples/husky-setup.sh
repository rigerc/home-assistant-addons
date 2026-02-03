#!/bin/bash
#
# Complete Husky setup script for commitlint
# This script installs and configures Husky with commitlint integration

set -e  # Exit on error

echo "=== Commitlint + Husky Setup ==="
echo ""

# Detect package manager
if [ -f "package-lock.json" ]; then
    PKG_MANAGER="npm"
    INSTALL_CMD="npm install --save-dev"
    RUN_CMD="npx"
elif [ -f "yarn.lock" ]; then
    PKG_MANAGER="yarn"
    INSTALL_CMD="yarn add --dev"
    RUN_CMD="yarn"
elif [ -f "pnpm-lock.yaml" ]; then
    PKG_MANAGER="pnpm"
    INSTALL_CMD="pnpm add --save-dev"
    RUN_CMD="pnpm dlx"
elif [ -f "bun.lockb" ]; then
    PKG_MANAGER="bun"
    INSTALL_CMD="bun add --dev"
    RUN_CMD="bunx"
else
    echo "No lock file found. Using npm as default."
    PKG_MANAGER="npm"
    INSTALL_CMD="npm install --save-dev"
    RUN_CMD="npx"
fi

echo "Detected package manager: $PKG_MANAGER"
echo ""

# Step 1: Install commitlint
echo "[1/5] Installing commitlint..."
$INSTALL_CMD @commitlint/cli @commitlint/config-conventional

# Step 2: Create commitlint configuration
echo "[2/5] Creating commitlint configuration..."

if [ ! -f "commitlint.config.js" ]; then
    cat > commitlint.config.js << 'EOF'
export default {
  extends: ['@commitlint/config-conventional']
};
EOF
    echo "  ✓ Created commitlint.config.js"
else
    echo "  ⚠ commitlint.config.js already exists, skipping"
fi

# Step 3: Install Husky
echo "[3/5] Installing Husky..."
$INSTALL_CMD husky

# Step 4: Initialize Husky
echo "[4/5] Initializing Husky..."

if [ "$PKG_MANAGER" = "npm" ]; then
    npx husky init
elif [ "$PKG_MANAGER" = "yarn" ]; then
    yarn husky init
elif [ "$PKG_MANAGER" = "pnpm" ]; then
    pnpm husky init
elif [ "$PKG_MANAGER" = "bun" ]; then
    bunx husky init
fi

# Step 5: Create commit-msg hook
echo "[5/5] Creating commit-msg hook..."

mkdir -p .husky

# Create commit-msg hook with appropriate command for package manager
if [ "$PKG_MANAGER" = "npm" ]; then
    HOOK_CMD='npx --no -- commitlint --edit $1'
elif [ "$PKG_MANAGER" = "yarn" ]; then
    HOOK_CMD='yarn commitlint --edit $1'
elif [ "$PKG_MANAGER" = "pnpm" ]; then
    HOOK_CMD='pnpm dlx commitlint --edit $1'
elif [ "$PKG_MANAGER" = "bun" ]; then
    HOOK_CMD='bunx commitlint --edit $1'
fi

cat > .husky/commit-msg << EOF
#!/usr/bin/env sh
. "\$(dirname "\$0")/_/husky.sh"

$HOOK_CMD
EOF

# Make hook executable (Unix-like systems)
chmod +x .husky/commit-msg

echo "  ✓ Created .husky/commit-msg hook"
echo ""

# Test the setup
echo "=== Testing Setup ==="
echo ""
echo "Running commitlint against last commit (if available)..."

if git rev-parse HEAD >/dev/null 2>&1; then
    if $RUN_CMD commitlint --from HEAD~1 --to HEAD --verbose; then
        echo ""
        echo "✓ Test passed! Your last commit follows the conventions."
    else
        echo ""
        echo "⚠ Test failed, but setup is complete."
        echo "  Your last commit doesn't follow conventions."
        echo "  This is normal if you haven't been using commitlint before."
    fi
else
    echo "No commits found. Skipping test."
fi

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "Next steps:"
echo "1. Try making a commit: git commit -m \"test: verify commitlint\""
echo "2. Valid commit format: type(scope): subject"
echo "3. Common types: feat, fix, docs, chore, refactor, test"
echo ""
echo "Examples of valid commits:"
echo "  feat: add user authentication"
echo "  fix(api): resolve timeout issue"
echo "  docs: update README installation steps"
echo ""
echo "Configuration file: commitlint.config.js"
echo "Hook file: .husky/commit-msg"
echo ""

# Optional: Add commitlint script to package.json
if command -v jq &> /dev/null; then
    echo "Adding npm script to package.json..."

    if [ -f "package.json" ]; then
        # Check if scripts.commitlint already exists
        if ! jq -e '.scripts.commitlint' package.json > /dev/null 2>&1; then
            jq '.scripts.commitlint = "commitlint --edit"' package.json > package.json.tmp
            mv package.json.tmp package.json
            echo "  ✓ Added 'commitlint' script to package.json"
        else
            echo "  ⚠ 'commitlint' script already exists in package.json"
        fi
    fi
else
    echo "Note: Install 'jq' to automatically add scripts to package.json"
fi

echo ""
echo "Happy committing! 🎉"
