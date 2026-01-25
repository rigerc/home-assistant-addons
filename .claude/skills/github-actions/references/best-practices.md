# Best Practices

Recommended patterns for production-ready GitHub Actions workflows.

## Workflow Organization

### Logical File Structure

```
.github/
├── workflows/
│   ├── ci.yml              # Continuous Integration
│   ├── cd.yml              # Continuous Deployment
│   ├── release.yml         # Release automation
│   └── dependencies.yml    # Dependency updates
└── actions/
    ├── setup-node/
    │   └── action.yml
    └── deploy/
        └── action.yml
```

### Descriptive Naming

```yaml
# ✅ Good
name: CI - Test and Build
name: Deploy to Production
name: Publish Release

# ❌ Bad
name: workflow1
name: test
name: deploy.yml
```

## Performance Optimization

### Use Caching

```yaml
steps:
  - uses: actions/cache@v4
    with:
      path: ~/.npm
      key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
```

### Parallel Jobs

```yaml
# ✅ Good - Run in parallel
jobs:
  lint:
    runs-on: ubuntu-latest
  test:
    runs-on: ubuntu-latest
  type-check:
    runs-on: ubuntu-latest

# ❌ Bad - Sequential when parallel possible
jobs:
  lint:
    runs-on: ubuntu-latest
  test:
    needs: lint  # Unnecessary dependency
```

### Optimize Checkout

```yaml
# Shallow clone (default, faster)
- uses: actions/checkout@v5

# Full history (only when needed)
- uses: actions/checkout@v5
  with:
    fetch-depth: 0
```

### Limit Matrix Combinations

```yaml
# ✅ Good - Focused matrix
strategy:
  matrix:
    os: [ubuntu-latest, macos-latest]
    node-version: [18, 20]

# ❌ Bad - Too many combinations
strategy:
  matrix:
    os: [ubuntu-20.04, ubuntu-22.04, macos-12, macos-13, windows-2019, windows-2022]
    node-version: [14, 16, 18, 20, 21]
```

## Dependency Management

### Pin Action Versions

```yaml
# ✅ Good - Specific major version
- uses: actions/checkout@v5
- uses: actions/setup-node@v4
- uses: actions/cache@v4

# ✅ Better - Specific minor version
- uses: actions/checkout@v5.1.0

# ❌ Bad - Unpinned or @main
- uses: actions/checkout@main
- uses: actions/checkout@v1
```

### Use Official Actions

```yaml
# ✅ Good - Official actions
- uses: actions/checkout@v5
- uses: actions/setup-node@v4

# ⚠️ Review community actions
- uses: some-user/custom-action@v1
```

## Error Handling

### Continue-On-Error

```yaml
steps:
  - name: Optional lint
    id: lint
    continue-on-error: true
    run: npm run lint

  - name: Check result
    if: steps.lint.outcome == 'failure'
    run: echo "Lint failed"
```

### Set Timeouts

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    timeout-minutes: 10
```

### Use Fail-Fast

```yaml
strategy:
  fail-fast: true  # Cancel all if one fails
  matrix:
    node-version: [18, 20]
```

## Security Practices

### Minimal Permissions

```yaml
# ✅ Good
permissions:
  contents: read
  pull-requests: write

# ❌ Bad
permissions: write-all
```

### Use Environments

```yaml
jobs:
  deploy-staging:
    environment: staging
  deploy-production:
    environment: production
```

### Don't Log Secrets

```yaml
# ✅ Good
env:
  API_KEY: ${{ secrets.API_KEY }}
run: curl -H "Authorization: Bearer $API_KEY" https://api.example.com

# ❌ Bad
run: echo "Deploying with ${{ secrets.API_KEY }}"
```

## Testing and Validation

### Test Locally with act

```bash
# Install act
brew install act  # macOS
choco install act  # Windows

# Test workflow
act push
act -j test
```

### Use Workflow Dispatch for Testing

```yaml
on:
  workflow_dispatch:
    inputs:
      dry-run:
        description: 'Dry run (no deployment)'
        type: boolean
        default: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy
        run: |
          if [ "${{ inputs.dry-run }}" = "true" ]; then
            echo "Dry run - skipping deployment"
          else
            ./deploy.sh
          fi
```

## Workflow Design

### Single Responsibility

```yaml
# ✅ Good - Each workflow has one purpose
# ci.yml - Run tests and linting
# cd.yml - Deploy to environments
# release.yml - Create releases

# ❌ Bad - One workflow does everything
# build.yml - Tests, linting, building, deploying, releasing
```

### Use Reusable Workflows

```yaml
# ✅ Good - Reusable workflow
# .github/workflows/test.yml
on:
  workflow_call:
    inputs:
      node-version:
        required: true

# ✅ Good - Caller
jobs:
  test:
    uses: ./.github/workflows/test.yml
    with:
      node-version: '20'
```

### Use Composite Actions

```yaml
# .github/actions/setup-node/action.yml
name: 'Setup Node.js'
runs:
  using: 'composite'
  steps:
    - uses: actions/setup-node@v4
    - uses: actions/cache@v4
    - shell: bash
      run: npm ci

# Use composite action
- uses: ./.github/actions/setup-node
  with:
    node-version: '20'
```

## Documentation

### Comment Complex Workflows

```yaml
# Deploy to production environment
# Requires approval via environment protection rules
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    environment: production
    steps:
      - name: Deploy
        run: ./scripts/deploy.sh
```

### Add Deployment Links

```yaml
jobs:
  deploy:
    environment:
      name: production
      url: https://prod.example.com
```

### Add Summary

```yaml
steps:
  - run: npm test

  - name: Add summary
    run: |
      echo "## Test Results :rocket:" >> $GITHUB_STEP_SUMMARY
      echo "- All tests passed!" >> $GITHUB_STEP_SUMMARY
```

## Maintenance

### Regular Updates

- Review and update pinned action versions monthly
- Test updates in development branch first
- Monitor GitHub changelogs for breaking changes

### Monitor Usage

```yaml
steps:
  - name: Monitor
    run: |
      echo "Run number: ${{ github.run_number }}"
      echo "Run ID: ${{ github.run_id }}"
```

### Clean Up Artifacts

```yaml
- uses: actions/upload-artifact@v4
  with:
    name: build-output
    path: dist/
    retention-days: 7  # Auto-delete after 7 days
```

## Checklist

- [ ] Descriptive workflow and job names
- [ ] Consistent file structure
- [ ] Pinned action versions
- [ ] Minimal permissions
- [ ] Environment-specific secrets
- [ ] Appropriate caching
- [ ] Parallel job execution
- [ ] Proper error handling
- [ ] Timeout values set
- [ ] Reusable workflows for duplication
- [ ] Composite actions for repeated steps
- [ ] Status notifications configured
- [ ] Documentation added
- [ ] Tested locally with act
- [ ] Security scanning enabled
