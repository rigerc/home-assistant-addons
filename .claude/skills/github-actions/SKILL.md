---
name: github-actions
description: This skill should be used when the user asks to "create a GitHub Actions workflow", "write a workflow file", "set up CI/CD", "configure GitHub Actions", or mentions GitHub Actions concepts like workflows, jobs, steps, triggers, matrix builds, caching, or deployment. Use when creating, debugging, or modifying workflow files in `.github/workflows/`.
version: 1.0.0
---

# GitHub Actions

Create, configure, and troubleshoot GitHub Actions workflows for CI/CD, automation, and deployment.

## Purpose

Generate production-ready GitHub Actions workflow files, debug workflow issues, and implement CI/CD best practices. Use official actions, proper caching, security patterns, and workflow organization.

## When to Use This Skill

Use this skill when:
- Creating a new workflow file (`.github/workflows/*.yml`)
- Setting up CI/CD for a project (tests, builds, deployment)
- Debugging workflow failures or syntax errors
- Configuring workflow triggers (push, PR, schedule, manual)
- Implementing matrix builds or caching strategies
- Setting up deployment with environments
- Learning GitHub Actions syntax and patterns

## Core Workflow

### Step 1: Understand Requirements

Identify what the workflow should accomplish:

**Common workflow types:**
- **CI**: Run tests, linting, type checking on push/PR
- **CD**: Build and deploy to environments (staging, production)
- **Scheduled**: Run cron jobs (maintenance, reports)
- **Manual**: Trigger on-demand with `workflow_dispatch`
- **Release**: Create releases, publish packages

**Ask clarifying questions:**
- What triggers should start the workflow? (push, PR, schedule, manual)
- What actions need to happen? (test, build, deploy, notify)
- Are there multiple environments? (dev, staging, production)
- Does it need matrix builds? (multiple OS, versions)

### Step 2: Choose Workflow Template

Select a base template and customize:

**Basic CI Template:**
```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - name: Setup
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - name: Install
        run: npm ci
      - name: Test
        run: npm test
```

**Deployment Template:**
```yaml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  deploy:
    environment: production
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - name: Deploy
        run: ./scripts/deploy.sh
```

### Step 2.5: Look Up Action Documentation

Find documentation for any action to understand its inputs, outputs, and usage.

**Parse action references:**

Actions follow the pattern `owner/repo@version`:
- `actions/checkout@v5` → GitHub: `actions/checkout`
- `actions/setup-node@v4` → GitHub: `actions/setup-node`
- `aws-actions/configure-aws-credentials@v4` → GitHub: `aws-actions/configure-aws-credentials`
- `docker://alpine:3.18` → Docker image (not a GitHub action)

**Fetch documentation using context7:**

Use context7 to get official GitHub Actions documentation:

```
Use Skill Tool: context7 query-docs
libraryId: /actions/checkout
query: What inputs and outputs does this action support?
```

**Fetch documentation using web reader:**

Use web reader to fetch README from the action's GitHub repository:

```
Use Tool: web_reader__webReader
url: https://github.com/actions/checkout/blob/main/README.md
```

**Common action documentation URLs:**

| Action | Documentation URL |
|--------|-------------------|
| `actions/checkout` | https://github.com/actions/checkout |
| `actions/setup-node` | https://github.com/actions/setup-node |
| `actions/setup-python` | https://github.com/actions/setup-python |
| `actions/setup-go` | https://github.com/actions/setup-go |
| `actions/cache` | https://github.com/actions/cache |
| `actions/upload-artifact` | https://github.com/actions/upload-artifact |
| `actions/download-artifact` | https://github.com/actions/download-artifact |

**Workflow for looking up unknown actions:**

1. Parse the action name (remove version suffix)
2. Construct the GitHub URL: `https://github.com/{owner}/{repo}`
3. Add `/blob/main/README.md` for documentation
4. Use web reader or context7 to fetch details

**Example lookup:**

For `actions/checkout@v5`:
1. Action: `actions/checkout`
2. URL: `https://github.com/actions/checkout/blob/main/README.md`
3. Use context7 or web reader to fetch inputs like `fetch-depth`, `ref`, `token`

### Step 3: Configure Triggers

Set when the workflow runs:

```yaml
on:
  # Push to specific branches
  push:
    branches: [main, develop]
    paths: ['src/**', 'tests/**']

  # Pull request activity
  pull_request:
    types: [opened, synchronize, reopened]
    branches: [main]

  # Manual trigger
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        type: choice
        options: [staging, production]

  # Schedule (cron syntax)
  schedule:
    - cron: '0 0 * * *'  # Daily at midnight UTC
```

**Trigger patterns:**
- Use `branches` to filter which branches trigger
- Use `paths` to only run when specific files change
- Use `types` with PR events for specific activities
- Use `workflow_dispatch` for manual triggers with inputs

### Step 4: Configure Jobs

Define what work to execute:

```yaml
jobs:
  # Single job
  test:
    runs-on: ubuntu-latest
    steps:
      - run: npm test

  # Multiple jobs (run in parallel)
  lint:
    runs-on: ubuntu-latest
    steps:
      - run: npm run lint

  test:
    runs-on: ubuntu-latest
    steps:
      - run: npm test

  # Job dependencies
  build:
    needs: [lint, test]
    runs-on: ubuntu-latest
    steps:
      - run: npm run build

  # Deployment (requires success)
  deploy:
    needs: build
    environment: production
    runs-on: ubuntu-latest
    steps:
      - run: ./deploy.sh
```

### Step 5: Setup Matrix Builds (Optional)

Run jobs across multiple configurations:

```yaml
jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
        node-version: [18, 20]
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
      - run: npm test
```

**Matrix guidelines:**
- Use `runs-on: ${{ matrix.os }}` for OS matrix
- Maximum 256 total combinations per workflow
- Use `max-parallel` to limit concurrent jobs
- Consider trade-off: more combinations = longer workflow time

### Step 6: Add Caching

Speed up workflows by caching dependencies:

```yaml
steps:
  - name: Cache node modules
    uses: actions/cache@v4
    with:
      path: ~/.npm
      key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
      restore-keys: |
        ${{ runner.os }}-node-

  - name: Install dependencies
    run: npm ci
```

**Cache key patterns:**
- Include runner OS: `${{ runner.os }}`
- Hash lockfile: `${{ hashFiles('**/package-lock.json') }}`
- Use restore-keys for partial matches
- Language-specific paths: `~/.npm` (npm), `~/.cache/pip` (pip)

### Step 7: Handle Secrets

Securely access sensitive data:

```yaml
jobs:
  deploy:
    environment: production
    runs-on: ubuntu-latest
    steps:
      - name: Deploy
        env:
          API_KEY: ${{ secrets.API_KEY }}
        run: |
          curl -H "Authorization: Bearer $API_KEY" https://api.example.com
```

**Secret best practices:**
- Never log secrets directly (they're auto-masked)
- Use environment-specific secrets
- Use `secrets: inherit` for reusable workflows
- Minimize `GITHUB_TOKEN` permissions

### Step 8: Add Artifacts (Optional)

Share files between jobs:

```yaml
# Upload
- name: Upload build
  uses: actions/upload-artifact@v4
  with:
    name: build-output
    path: dist/
    retention-days: 7

# Download (in another job)
- name: Download build
  uses: actions/download-artifact@v4
  with:
    name: build-output
    path: ./dist
```

### Step 9: Save and Validate

Save the workflow file and check syntax:

1. Save to `.github/workflows/workflow-name.yml`
2. GitHub automatically validates YAML syntax
3. Check the Actions tab for syntax errors
4. Use `act` to test workflows locally (optional)

**Common syntax issues:**
- Indentation must be consistent (2 spaces recommended)
- Colons (`:`) need a space after them
- Strings with special chars need quotes
- Boolean values: `true`, `false` (unquoted)

## Debugging Workflows

### Check Workflow Syntax

```yaml
# Invalid - missing space after colon
name:workflow

# Valid
name: workflow
```

### Debug Failed Steps

```yaml
steps:
  - name: Debug info
    run: |
      echo "Runner OS: ${{ runner.os }}"
      echo "Workspace: ${{ github.workspace }}"
      echo "Event: ${{ github.event_name }}"
```

### Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| "Permission denied" | Make script executable: `chmod +x script.sh` |
| "Command not found" | Use full path or install in earlier step |
| "Cache miss" | Check cache key matches file hash |
| "Secret not found" | Verify secret name and scope |
| "Job timeout" | Increase `timeout-minutes` |

## Additional Resources

### Reference Files

For detailed information, consult:
- **`references/triggers-events.md`** - Complete trigger configuration, cron syntax, all event types
- **`references/jobs-matrix.md`** - Matrix strategy, job dependencies, concurrency, runners
- **`references/caching-artifacts.md`** - Caching patterns, artifact sharing, optimization
- **`references/secrets-security.md`** - Secret management, security best practices, OIDC
- **`references/best-practices.md`** - Workflow organization, performance, maintenance

### Example Files

Working examples in `examples/`:
- **`examples/ci-workflow.yml`** - Complete CI workflow with tests and linting
- **`examples/deploy-workflow.yml`** - Deployment workflow with environments
- **`examples/matrix-build.yml`** - Matrix build across OS and versions
- **`examples/scheduled-workflow.yml`** - Cron-based scheduled tasks

### Quick Reference

**File location:** `.github/workflows/*.yml`

**Basic structure:**
```yaml
name: workflow-name
on: [push]
jobs:
  job-id:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - run: command
```

**Official actions:**
- `actions/checkout@v5` - Checkout repository
- `actions/setup-node@v4` - Setup Node.js
- `actions/cache@v4` - Cache dependencies
- `actions/upload-artifact@v4` - Upload artifacts
- `actions/download-artifact@v4` - Download artifacts

**Looking up action documentation:**

To find documentation for any action:
1. Parse: `owner/repo@version` → `owner/repo`
2. URL: `https://github.com/owner/repo`
3. Use context7: query `/actions/repo-name` for official actions
4. Use web reader: fetch README.md for detailed documentation
