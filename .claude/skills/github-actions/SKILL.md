---
name: github-actions
description: This skill should be used when the user asks to "create a GitHub Actions workflow", "write a workflow file", "debug a workflow", "create a custom action", "build a JavaScript action", "build a Docker action", "build a composite action", "set up CI/CD", "configure GitHub Actions", "troubleshoot workflow failures", "use workflow events", "create reusable workflows", "optimize workflows", "use matrix builds", "cache dependencies in workflows", or mentions GitHub Actions, CI/CD pipelines, workflow syntax, action development, or workflow automation.
version: 1.0.0
---

# GitHub Actions - Comprehensive Guide

Master GitHub Actions workflows and custom action development. This skill provides comprehensive coverage of creating, debugging, and optimizing GitHub Actions for CI/CD automation.

## Purpose

Provide complete guidance for working with GitHub Actions, from basic workflow creation to advanced action development. Cover workflow syntax, event triggers, job orchestration, custom action creation (JavaScript, Docker, composite), debugging techniques, optimization patterns, and best practices for production CI/CD pipelines.

## When to Use This Skill

Use this skill when:
- Creating or modifying GitHub Actions workflows
- Building custom actions (JavaScript, Docker, or composite)
- Debugging workflow failures or unexpected behavior
- Setting up CI/CD pipelines for testing and deployment
- Optimizing workflow performance and costs
- Implementing matrix builds or parallel jobs
- Using advanced features like reusable workflows or caching
- Understanding workflow events and triggers
- Securing workflows and managing secrets
- Migrating from other CI/CD platforms

## Core Concepts

### Workflows

A **workflow** is an automated process defined in YAML that runs when triggered by events. Workflows contain one or more jobs that execute on runners.

**Location**: `.github/workflows/*.yml` or `.github/workflows/*.yaml`

**Basic structure**:
```yaml
name: Workflow Name
on: [push, pull_request]
jobs:
  job-id:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: echo "Hello World"
```

### Events

Events trigger workflow runs. Common events include:
- **push**: Code pushed to repository
- **pull_request**: PR opened, synchronized, or reopened
- **schedule**: Cron-based scheduling
- **workflow_dispatch**: Manual trigger
- **release**: Release published
- **issues**: Issue opened, edited, etc.

### Jobs

Jobs are collections of steps that execute on the same runner. Jobs run in parallel by default unless dependencies are specified with `needs`.

### Steps

Steps are individual tasks within a job. Each step either:
- Runs a command (`run`)
- Uses an action (`uses`)

### Actions

Actions are reusable units of code that perform specific tasks. Three types:
- **JavaScript actions**: Run directly on runners, fastest
- **Docker actions**: Run in containers, more isolated
- **Composite actions**: Combine multiple steps into one action

### Runners

Runners are servers that execute workflows. GitHub provides hosted runners (Ubuntu, Windows, macOS) or you can self-host.

## Essential Workflows

### Create a Basic CI Workflow

Start with continuous integration to test code on every push:

```yaml
name: CI
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test

      - name: Run linter
        run: npm run lint
```

### Matrix Builds

Test across multiple versions or platforms:

```yaml
jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        node-version: [18, 20, 22]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
      - run: npm ci
      - run: npm test
```

### Deployment Workflow

Deploy after successful tests:

```yaml
name: Deploy
on:
  push:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm test

  deploy:
    needs: test
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to production
        run: ./deploy.sh
        env:
          DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}
```

## Action Development

### Choose Action Type

**JavaScript Action** - Use when:
- Need fast execution
- Interacting with GitHub API
- Processing data or files
- Cross-platform compatibility needed

**Docker Action** - Use when:
- Need specific runtime environment
- Using non-JavaScript languages
- Require specific system dependencies
- Isolation is critical

**Composite Action** - Use when:
- Combining existing actions/steps
- Reusing workflow patterns
- Don't need custom code
- Want simplest maintenance

### Create a JavaScript Action

**Structure**:
```
my-action/
├── action.yml          # Metadata
├── index.js            # Entry point
├── package.json        # Dependencies
└── README.md           # Documentation
```

**action.yml**:
```yaml
name: 'My JavaScript Action'
description: 'Does something useful'
inputs:
  who-to-greet:
    description: 'Who to greet'
    required: true
    default: 'World'
outputs:
  time:
    description: 'The time we greeted you'
runs:
  using: 'node20'
  main: 'index.js'
```

**index.js**:
```javascript
const core = require('@actions/core');
const github = require('@actions/github');

try {
  const nameToGreet = core.getInput('who-to-greet');
  console.log(`Hello ${nameToGreet}`);

  const time = new Date().toTimeString();
  core.setOutput('time', time);

  const payload = JSON.stringify(github.context.payload, null, 2);
  console.log(`Event payload: ${payload}`);
} catch (error) {
  core.setFailed(error.message);
}
```

### Create a Composite Action

**action.yml**:
```yaml
name: 'Setup Node.js with Caching'
description: 'Sets up Node.js with dependency caching'
inputs:
  node-version:
    description: 'Node.js version'
    required: true
    default: '20'
runs:
  using: 'composite'
  steps:
    - uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
        cache: 'npm'

    - name: Install dependencies
      run: npm ci
      shell: bash

    - name: Cache node_modules
      uses: actions/cache@v4
      with:
        path: node_modules
        key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
```

## Debugging Workflows

### Enable Debug Logging

Set repository secrets:
- `ACTIONS_STEP_DEBUG`: `true` (detailed step logs)
- `ACTIONS_RUNNER_DEBUG`: `true` (runner diagnostic logs)

### Common Issues

**Workflow not triggering**:
- Check event configuration matches actual event
- Verify workflow file in `.github/workflows/`
- Check file has `.yml` or `.yaml` extension
- Ensure proper YAML syntax

**Job failures**:
- Check step exit codes (non-zero = failure)
- Review logs for error messages
- Verify permissions and secrets
- Check runner compatibility

**Permission errors**:
- Add `permissions:` block to workflow
- Grant necessary token permissions
- Use `GITHUB_TOKEN` correctly

**Timeout issues**:
- Default timeout is 360 minutes
- Set `timeout-minutes:` on jobs/steps
- Optimize slow operations
- Check for hanging processes

## Optimization Techniques

### Caching Dependencies

```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.npm
      node_modules
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-node-
```

### Conditional Execution

```yaml
- name: Deploy
  if: github.ref == 'refs/heads/main' && github.event_name == 'push'
  run: ./deploy.sh
```

### Parallel Jobs

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

  # Both run in parallel
```

### Job Dependencies

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: npm run build

  test:
    needs: build  # Waits for build
    runs-on: ubuntu-latest
    steps:
      - run: npm test
```

## Security Best Practices

### Never Log Secrets

```yaml
# BAD - Don't do this
- run: echo "Token is ${{ secrets.API_TOKEN }}"

# GOOD - Use secrets safely
- run: curl -H "Authorization: Bearer ${{ secrets.API_TOKEN }}" api.example.com
```

### Use Minimal Permissions

```yaml
permissions:
  contents: read
  pull-requests: write
  issues: write
```

### Pin Action Versions

```yaml
# GOOD - Pin to commit SHA
- uses: actions/checkout@8ade135a41bc03ea155e62e844d188df1ea18608  # v4.1.0

# ACCEPTABLE - Pin to major version
- uses: actions/checkout@v4

# BAD - Unpinned
- uses: actions/checkout@main
```

### Validate Inputs

In custom actions:
```javascript
const core = require('@actions/core');

const input = core.getInput('user-input');
// Validate before using
if (!/^[a-zA-Z0-9-]+$/.test(input)) {
  core.setFailed('Invalid input format');
}
```

## Advanced Patterns

### Reusable Workflows

**caller.yml**:
```yaml
jobs:
  call-workflow:
    uses: ./.github/workflows/reusable.yml
    with:
      environment: production
    secrets:
      token: ${{ secrets.DEPLOY_TOKEN }}
```

**reusable.yml**:
```yaml
on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
    secrets:
      token:
        required: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying to ${{ inputs.environment }}"
```

### Dynamic Matrix

```yaml
jobs:
  generate-matrix:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.set-matrix.outputs.matrix }}
    steps:
      - id: set-matrix
        run: echo "matrix={\"include\":[{\"project\":\"foo\"},{\"project\":\"bar\"}]}" >> $GITHUB_OUTPUT

  build:
    needs: generate-matrix
    strategy:
      matrix: ${{ fromJSON(needs.generate-matrix.outputs.matrix) }}
    runs-on: ubuntu-latest
    steps:
      - run: echo "Building ${{ matrix.project }}"
```

### Environments and Approvals

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://prod.example.com
    steps:
      - run: ./deploy.sh
```

Configure environment protection rules in repository settings for manual approval gates.

## Quick Reference

### Common Events
- `push`: Code pushed
- `pull_request`: PR activity
- `workflow_dispatch`: Manual trigger
- `schedule`: Cron schedule
- `release`: Release created

### Common Actions
- `actions/checkout@v4`: Clone repository
- `actions/setup-node@v4`: Set up Node.js
- `actions/setup-python@v5`: Set up Python
- `actions/cache@v4`: Cache dependencies
- `actions/upload-artifact@v4`: Upload build artifacts
- `actions/download-artifact@v4`: Download artifacts

### Contexts
- `${{ github.actor }}`: User who triggered workflow
- `${{ github.event_name }}`: Event that triggered
- `${{ github.ref }}`: Branch or tag ref
- `${{ github.sha }}`: Commit SHA
- `${{ runner.os }}`: Runner OS
- `${{ secrets.SECRET_NAME }}`: Access secrets
- `${{ env.VAR_NAME }}`: Access environment variables

## Additional Resources

### Reference Files

For comprehensive documentation on specific topics:

- **`references/workflow-syntax-reference.md`** - Complete workflow YAML syntax
- **`references/events-reference.md`** - All workflow events and triggers
- **`references/contexts-reference.md`** - GitHub Actions contexts and expressions
- **`references/action-metadata-syntax.md`** - Action.yml metadata specification
- **`references/creating-javascript-actions.md`** - JavaScript action development guide
- **`references/creating-docker-actions.md`** - Docker action development guide
- **`references/creating-composite-actions.md`** - Composite action development guide
- **`references/reusable-workflows-guide.md`** - Reusable workflow patterns
- **`references/debugging-guide.md`** - Troubleshooting and debugging workflows
- **`references/best-practices.md`** - Security and optimization best practices
- **`references/dependency-caching.md`** - Dependency caching strategies

### Example Files

Working examples in `examples/`:

- **`examples/ci-basic.yml`** - Basic CI workflow
- **`examples/ci-matrix.yml`** - Matrix build workflow
- **`examples/deploy-docker.yml`** - Docker build and deploy
- **`examples/deploy-pages.yml`** - GitHub Pages deployment
- **`examples/reusable-workflow.yml`** - Reusable workflow template
- **`examples/scheduled-cleanup.yml`** - Scheduled maintenance workflow

### Next Steps

1. **Start Simple**: Begin with a basic CI workflow testing your code
2. **Add Complexity Gradually**: Add matrix builds, caching, deployments
3. **Create Reusable Actions**: Extract common patterns into composite actions
4. **Optimize**: Add caching, parallelize jobs, use environments
5. **Secure**: Follow security best practices, audit workflows regularly

## Common Patterns Summary

**Test on PR**:
```yaml
on:
  pull_request:
    branches: [ main ]
```

**Deploy on main**:
```yaml
on:
  push:
    branches: [ main ]
```

**Schedule (cron)**:
```yaml
on:
  schedule:
    - cron: '0 0 * * *'  # Daily at midnight
```

**Manual trigger**:
```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        type: choice
        options:
          - staging
          - production
```

**Multiple events**:
```yaml
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:
```

This skill provides the foundation for mastering GitHub Actions. Consult the reference files for detailed syntax and the examples for working implementations.
