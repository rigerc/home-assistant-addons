#!/bin/bash
# Example bootstrap commands for release-please

# Set your GitHub token
export GITHUB_TOKEN="ghp_your_token_here"

# Example 1: Bootstrap a simple Node.js project
release-please bootstrap \
  --token=$GITHUB_TOKEN \
  --repo-url=myowner/myproject \
  --release-type=node

# Example 2: Bootstrap a Python project with custom package name
release-please bootstrap \
  --token=$GITHUB_TOKEN \
  --repo-url=myowner/myproject \
  --release-type=python \
  --package-name=my-package

# Example 3: Bootstrap a Rust project
release-please bootstrap \
  --token=$GITHUB_TOKEN \
  --repo-url=myowner/myproject \
  --release-type=rust

# Example 4: Bootstrap with initial version (for existing projects)
release-please bootstrap \
  --token=$GITHUB_TOKEN \
  --repo-url=myowner/myproject \
  --release-type=node \
  --initial-version=2.0.0

# Example 5: Bootstrap for a monorepo
release-please bootstrap \
  --token=$GITHUB_TOKEN \
  --repo-url=myowner/monorepo \
  --release-type=node \
  --path=packages/frontend

# Test with dry-run before creating actual PR
release-please release-pr \
  --token=$GITHUB_TOKEN \
  --repo-url=myowner/myproject \
  --dry-run \
  --debug
