# Best Practices for GitHub Actions

## Overview

Effective GitHub Actions workflows balance security, performance, cost efficiency, and maintainability. This guide provides production-tested practices for building reliable automation.

## Security Best Practices

### Secret Management

#### Never Log Secrets

Prevent secrets from appearing in logs:

```yaml
# Bad: Secret visible in logs
steps:
  - run: echo "Token is ${{ secrets.API_TOKEN }}"

# Good: Use secret in environment variable
steps:
  - env:
      API_TOKEN: ${{ secrets.API_TOKEN }}
    run: ./script.sh  # Script uses $API_TOKEN without logging
```

#### Mask Sensitive Values

Mask dynamically generated secrets:

```yaml
steps:
  - name: Generate and mask token
    run: |
      TOKEN=$(generate-token)
      echo "::add-mask::$TOKEN"
      echo "TOKEN=$TOKEN" >> $GITHUB_ENV
```

#### Limit Secret Scope

Store secrets at the most specific level:

```yaml
# Environment secrets for deployment
jobs:
  deploy:
    environment: production
    steps:
      - env:
          DEPLOY_KEY: ${{ secrets.DEPLOY_KEY }}  # Environment-level
        run: ./deploy.sh

# Repository secrets for general use
  build:
    steps:
      - env:
          BUILD_TOKEN: ${{ secrets.BUILD_TOKEN }}  # Repository-level
        run: npm run build
```

#### Rotate Secrets Regularly

Establish secret rotation schedules:
- API keys: Every 90 days
- Deploy keys: Every 180 days
- Personal access tokens: Every 90 days

Automate rotation where possible and maintain secret versioning.

#### Use Secret Scanning

Enable secret scanning in repository settings to detect accidentally committed secrets. Configure push protection to prevent secret commits.

### Permission Management

#### Principle of Least Privilege

Grant minimum necessary permissions:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read  # Only read, not write
      pull-requests: write  # Only for commenting
    steps:
      - uses: actions/checkout@v4
      - run: npm run build
```

#### Set Default Permissions

Configure repository-wide default permissions:
1. Repository Settings > Actions > General
2. Workflow permissions > "Read repository contents and packages permissions"
3. Override in workflows only when needed

#### Explicit Permission Declaration

Always declare permissions explicitly:

```yaml
# Bad: Relies on defaults
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - run: ./deploy.sh

# Good: Explicit permissions
jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      deployments: write
    steps:
      - run: ./deploy.sh
```

### Action Pinning

#### Pin to Commit SHA

Pin third-party actions to specific commit SHAs:

```yaml
# Best: Pinned to SHA (most secure)
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11  # v4.1.1

# Good: Pinned to tag
- uses: actions/checkout@v4.1.1

# Avoid: Floating tag (can change)
- uses: actions/checkout@v4

# Never: Branch reference (changes frequently)
- uses: actions/checkout@main
```

#### Verify Action Sources

Before using third-party actions:
- Review action source code
- Check repository reputation and maintenance
- Verify security advisories
- Use actions from verified creators when possible

#### Monitor Action Updates

Track action updates and security advisories:

```yaml
# Create dependabot.yml
version: 2
updates:
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
```

### Code Injection Prevention

#### Avoid Direct Expression Interpolation

Prevent script injection through expressions:

```yaml
# Vulnerable: User input directly in script
- name: Greet user
  run: echo "Hello ${{ github.event.issue.title }}"

# Secure: Use environment variable
- name: Greet user
  env:
    TITLE: ${{ github.event.issue.title }}
  run: echo "Hello $TITLE"
```

#### Validate User Input

Validate and sanitize user-controlled data:

```yaml
steps:
  - name: Validate input
    env:
      USER_INPUT: ${{ github.event.issue.title }}
    run: |
      if [[ ! "$USER_INPUT" =~ ^[a-zA-Z0-9\ ]+$ ]]; then
        echo "::error::Invalid input format"
        exit 1
      fi
      echo "Input validated: $USER_INPUT"
```

#### Use Actions for Complex Operations

Prefer using actions over inline scripts for security-sensitive operations:

```yaml
# Vulnerable: Inline script with user data
- run: |
    comment="${{ github.event.comment.body }}"
    gh pr comment $PR_NUMBER --body "$comment"

# Secure: Use official action
- uses: actions/github-script@v7
  with:
    script: |
      github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body: context.payload.comment.body
      })
```

### Pull Request Security

#### Limit pull_request_target Usage

Use `pull_request_target` carefully as it grants access to secrets:

```yaml
# Dangerous: Checks out PR code with access to secrets
on: pull_request_target
jobs:
  build:
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.pull_request.head.sha }}  # PR code
      - run: npm install  # Could run malicious code with secret access

# Safer: Separate untrusted and trusted operations
on: pull_request_target
jobs:
  build-untrusted:
    permissions:
      contents: read  # No secrets
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.pull_request.head.sha }}
      - run: npm run build
      - uses: actions/upload-artifact@v4
        with:
          name: build-output
          path: dist/

  deploy-trusted:
    needs: build-untrusted
    permissions:
      deployments: write
    steps:
      - uses: actions/download-artifact@v4
      - run: ./deploy.sh  # Only runs trusted code
        env:
          DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}
```

#### Fork Pull Request Handling

Understand fork behavior:
- Forks cannot access repository secrets
- `pull_request_target` grants base repository secrets to fork PR
- Limit what fork PRs can execute

```yaml
# Safe for fork PRs
on: pull_request
jobs:
  test:
    steps:
      - uses: actions/checkout@v4
      - run: npm test  # No secrets needed
```

## Performance Optimization

### Caching Strategies

#### Cache Dependencies

Cache package manager dependencies:

```yaml
steps:
  - uses: actions/checkout@v4

  - uses: actions/setup-node@v4
    with:
      node-version: 20
      cache: 'npm'  # Built-in caching

  # Or manual caching
  - uses: actions/cache@v3
    with:
      path: ~/.npm
      key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
      restore-keys: |
        ${{ runner.os }}-npm-
```

#### Cache Build Outputs

Cache compiled artifacts:

```yaml
steps:
  - uses: actions/cache@v3
    with:
      path: |
        dist/
        build/
      key: build-${{ runner.os }}-${{ hashFiles('src/**') }}

  - name: Build
    run: |
      if [ -d "dist" ]; then
        echo "Using cached build"
      else
        npm run build
      fi
```

#### Cache Optimization

Optimize cache effectiveness:
- Use specific cache keys with content hashes
- Include OS in cache key for cross-platform builds
- Set appropriate restore-keys for fallback
- Monitor cache hit rates

```yaml
# Optimized cache strategy
- uses: actions/cache@v3
  with:
    path: node_modules
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}-${{ hashFiles('**/package.json') }}
    restore-keys: |
      ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}-
      ${{ runner.os }}-node-
```

### Concurrency Control

#### Cancel Redundant Runs

Cancel outdated workflow runs:

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true  # Cancel older runs
```

#### Environment-Specific Concurrency

Control concurrent deployments:

```yaml
jobs:
  deploy:
    environment: production
    concurrency:
      group: production-deploy
      cancel-in-progress: false  # Wait for completion
    steps:
      - run: ./deploy.sh
```

#### Branch-Specific Concurrency

Different strategies per branch:

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}  # Only for non-main
```

### Job Dependencies

#### Optimize Job Parallelism

Run independent jobs in parallel:

```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - run: npm run lint

  test:
    runs-on: ubuntu-latest
    steps:
      - run: npm test

  build:
    runs-on: ubuntu-latest
    steps:
      - run: npm run build

  # These run in parallel, then deploy waits
  deploy:
    needs: [lint, test, build]
    runs-on: ubuntu-latest
    steps:
      - run: ./deploy.sh
```

#### Conditional Dependencies

Skip unnecessary work:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: npm test

  deploy:
    needs: test
    if: github.ref == 'refs/heads/main'  # Only on main branch
    runs-on: ubuntu-latest
    steps:
      - run: ./deploy.sh
```

### Matrix Strategy Optimization

#### Smart Matrix Usage

Use matrices for parallel execution:

```yaml
jobs:
  test:
    strategy:
      matrix:
        node: [18, 20, 22]
        os: [ubuntu-latest, windows-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
      - run: npm test
```

#### Fail-Fast Strategy

Configure failure behavior:

```yaml
strategy:
  fail-fast: false  # Continue all matrix jobs even if one fails
  matrix:
    version: [3.8, 3.9, 3.10, 3.11]
```

#### Matrix Includes/Excludes

Optimize matrix combinations:

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, windows-latest]
    node: [18, 20]
    exclude:
      - os: windows-latest
        node: 18  # Skip specific combination
    include:
      - os: macos-latest
        node: 20  # Add specific combination
```

## Cost Optimization

### Efficient Runner Usage

#### Choose Appropriate Runners

Select cost-effective runner types:

```yaml
jobs:
  # Use smaller runners for simple tasks
  lint:
    runs-on: ubuntu-latest  # 2-core, standard
    steps:
      - run: npm run lint

  # Use larger runners only when needed
  build:
    runs-on: ubuntu-latest-4-core  # 4-core for faster builds
    steps:
      - run: npm run build
```

#### Self-Hosted Runners

Consider self-hosted runners for:
- High-volume workflows
- Specialized hardware requirements
- Private network access
- Cost reduction at scale

```yaml
jobs:
  deploy:
    runs-on: [self-hosted, production]
    steps:
      - run: ./deploy.sh
```

### Conditional Execution

#### Path Filters

Run workflows only when relevant files change:

```yaml
on:
  push:
    paths:
      - 'src/**'
      - 'package*.json'
  pull_request:
    paths:
      - 'src/**'
      - 'package*.json'
```

#### Branch Filters

Limit workflow execution to specific branches:

```yaml
on:
  push:
    branches:
      - main
      - 'release/**'
    branches-ignore:
      - 'wip/**'
```

#### Conditional Steps

Skip unnecessary steps:

```yaml
steps:
  - name: Expensive operation
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    run: ./expensive-task.sh

  - name: Fast check
    run: npm run quick-check
```

### Artifact Management

#### Limit Artifact Retention

Set appropriate retention periods:

```yaml
steps:
  - uses: actions/upload-artifact@v4
    with:
      name: build-output
      path: dist/
      retention-days: 7  # Delete after 7 days
```

#### Compress Artifacts

Reduce artifact storage costs:

```yaml
steps:
  - name: Compress artifacts
    run: tar -czf build.tar.gz dist/

  - uses: actions/upload-artifact@v4
    with:
      name: build
      path: build.tar.gz
```

## Maintainability

### Workflow Organization

#### Reusable Workflows

Extract common patterns:

```yaml
# .github/workflows/reusable-test.yml
name: Test Workflow

on:
  workflow_call:
    inputs:
      node-version:
        required: true
        type: string

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}
      - run: npm test

# .github/workflows/ci.yml
jobs:
  test-node-18:
    uses: ./.github/workflows/reusable-test.yml@main
    with:
      node-version: '18'

  test-node-20:
    uses: ./.github/workflows/reusable-test.yml@main
    with:
      node-version: '20'
```

#### Composite Actions

Create reusable action sequences:

```yaml
# .github/actions/setup/action.yml
name: Setup Project
description: Install dependencies and cache
runs:
  using: composite
  steps:
    - uses: actions/setup-node@v4
      with:
        node-version: 20
    - uses: actions/cache@v3
      with:
        path: node_modules
        key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
    - run: npm ci
      shell: bash

# Use in workflow
jobs:
  build:
    steps:
      - uses: ./.github/actions/setup
      - run: npm run build
```

### Documentation

#### Workflow Comments

Document complex logic:

```yaml
name: Production Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      # Check deployment window (9 AM - 5 PM UTC)
      # Prevents off-hours deployments
      - name: Validate deployment time
        run: |
          hour=$(date -u +%H)
          if [ $hour -lt 9 ] || [ $hour -ge 17 ]; then
            echo "Deployments only allowed 9 AM - 5 PM UTC"
            exit 1
          fi
```

#### Input Descriptions

Describe workflow inputs clearly:

```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment (dev/staging/prod)'
        required: true
        type: choice
        options:
          - dev
          - staging
          - prod
      dry-run:
        description: 'Preview changes without applying'
        required: false
        type: boolean
        default: false
```

### Version Control

#### Action Versioning

Use semantic versioning for custom actions:

```yaml
# After releasing action v1.2.3
git tag -a v1.2.3 -m "Release version 1.2.3"
git push origin v1.2.3

# Also update major version tag
git tag -fa v1 -m "Update v1 to 1.2.3"
git push origin v1 --force
```

#### Workflow Testing

Test workflow changes before merging:

```yaml
# Test workflow in feature branch
on:
  push:
    branches:
      - main
      - 'feature/**'  # Test in feature branches
```

## Testing Workflows

### Workflow Dispatch for Testing

Create test workflows:

```yaml
name: Test Workflow

on:
  workflow_dispatch:
    inputs:
      test-scenario:
        description: 'Test scenario to run'
        type: choice
        options:
          - success-path
          - error-handling
          - edge-cases

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Run test scenario
        run: ./test-${{ inputs.test-scenario }}.sh
```

### Local Testing

Test workflows locally using act:

```bash
# Install act
brew install act

# Run workflow locally
act push

# Run specific job
act -j build

# With secrets
act -s GITHUB_TOKEN=your_token
```

### Validation Scripts

Validate workflow syntax:

```bash
# Validate all workflows
for f in .github/workflows/*.yml; do
  yamllint "$f"
  actionlint "$f"
done
```

## Monitoring and Observability

### Status Checks

Configure required status checks:
1. Repository Settings > Branches
2. Add branch protection rule
3. Require status checks: select workflows

### Notifications

Set up workflow failure notifications:

```yaml
jobs:
  notify-failure:
    if: failure()
    runs-on: ubuntu-latest
    steps:
      - name: Send notification
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              body: '⚠️ Workflow failed. Please investigate.'
            })
```

### Job Summaries

Create informative summaries:

```yaml
steps:
  - name: Test summary
    run: |
      echo "## Test Results" >> $GITHUB_STEP_SUMMARY
      echo "" >> $GITHUB_STEP_SUMMARY
      echo "**Total:** 150" >> $GITHUB_STEP_SUMMARY
      echo "**Passed:** 145" >> $GITHUB_STEP_SUMMARY
      echo "**Failed:** 5" >> $GITHUB_STEP_SUMMARY
```

## Environment Management

### Environment Protection Rules

Configure environment protections:
1. Repository Settings > Environments
2. Add environment (e.g., production)
3. Configure protection rules:
   - Required reviewers
   - Wait timer
   - Deployment branches

```yaml
jobs:
  deploy-production:
    environment:
      name: production
      url: https://example.com
    steps:
      - run: ./deploy.sh
```

### Environment Variables

Organize environment configuration:

```yaml
env:
  # Workflow-level
  NODE_ENV: production
  CACHE_VERSION: v1

jobs:
  build:
    env:
      # Job-level
      BUILD_TARGET: production
    steps:
      - name: Build
        env:
          # Step-level
          EXTRA_FLAGS: --optimize
        run: npm run build
```

## Error Handling

### Graceful Failures

Handle failures appropriately:

```yaml
steps:
  - name: Optional step
    continue-on-error: true
    run: ./optional-task.sh

  - name: Required step
    run: ./critical-task.sh

  - name: Cleanup
    if: always()  # Run even if previous steps fail
    run: ./cleanup.sh
```

### Retry Logic

Implement retry strategies:

```yaml
steps:
  - name: Flaky operation
    uses: nick-invision/retry@v2
    with:
      timeout_minutes: 10
      max_attempts: 3
      command: npm test
```

### Fallback Strategies

Provide fallbacks for external dependencies:

```yaml
steps:
  - name: Download from primary source
    id: primary
    continue-on-error: true
    run: wget https://primary.example.com/file

  - name: Download from fallback
    if: steps.primary.outcome == 'failure'
    run: wget https://fallback.example.com/file
```

## Compliance and Auditing

### Audit Logs

Monitor workflow activity through audit logs:
- Organization Settings > Audit log
- Filter by "Action: prepared_workflow_job"
- Review workflow execution patterns

### SBOM Generation

Generate software bill of materials:

```yaml
steps:
  - name: Generate SBOM
    uses: anchore/sbom-action@v0
    with:
      format: cyclonedx-json
      output-file: sbom.json

  - uses: actions/upload-artifact@v4
    with:
      name: sbom
      path: sbom.json
```

### License Compliance

Check dependency licenses:

```yaml
steps:
  - name: License check
    run: |
      npm install -g license-checker
      license-checker --onlyAllow "MIT;Apache-2.0;BSD-3-Clause"
```
