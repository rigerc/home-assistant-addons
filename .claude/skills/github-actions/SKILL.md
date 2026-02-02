---
name: github-actions
# IMPORTANT: Keep description on ONE line for Claude Code compatibility
# prettier-ignore
description: This skill should be used when the user asks to "create workflow", "debug GitHub Actions", "write action", or mentions CI/CD, workflows, runners, jobs.
---

# GitHub Actions

Comprehensive guide for creating workflows, debugging CI/CD pipelines, and building custom actions on GitHub.

## Quick Start

Create a basic CI workflow in `.github/workflows/ci.yml`:

```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: npm test
```

## Core Concepts

**Workflows** - YAML files in `.github/workflows/` that automate tasks
**Events** - Triggers like push, pull_request, schedule that start workflows
**Jobs** - Collections of steps that run on the same runner
**Steps** - Individual tasks within a job (run commands or use actions)
**Actions** - Reusable components (from Marketplace or custom-built)
**Runners** - Servers that execute workflows (GitHub-hosted or self-hosted)
**Contexts** - Access runtime data using `${{ github.*, env.*, etc }}`

## Common Workflows

### Basic CI/CD Pattern

1. **Test on push/PR** - Run tests automatically for every code change
2. **Build artifacts** - Compile, package, or bundle your application
3. **Deploy** - Push to staging/production on successful merges
4. **Notify** - Send status updates to Slack, email, etc.

### Matrix Builds

Test across multiple OS, language versions, or configurations:

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, windows-latest, macos-latest]
    node: [16, 18, 20]
runs-on: ${{ matrix.os }}
```

### Dependency Caching

Speed up workflows by caching dependencies:

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
```

## Debugging Workflows

**Common issues:**
- Syntax errors in YAML - Use online YAML validators
- Missing permissions - Add `permissions:` block to workflow
- Secrets not available - Check repository/organization settings
- Steps failing - Use `ACTIONS_STEP_DEBUG=true` secret for verbose logs
- Context expression errors - Use `toJSON()` to inspect: `${{ toJSON(github) }}`

**Debugging techniques:**
1. Add `- run: env | sort` to inspect environment variables
2. Use `actions/upload-artifact` to save files for inspection
3. Check workflow run logs in Actions tab
4. Use `if: always()` to run cleanup steps even on failure

## Creating Actions

Three types of custom actions:

**1. Composite Actions** - Combine multiple workflow steps
**2. JavaScript Actions** - Use Node.js with @actions/toolkit
**3. Docker Actions** - Package code in containers for any language

Choose composite for simple step combinations, JavaScript for GitHub API integration, Docker for complex multi-language logic.

## Reference Files

Complete documentation organized by topic:

**Core Syntax & Configuration:**
- `references/workflow-syntax.md` - Complete workflow YAML syntax reference
- `references/events-that-trigger-workflows.md` - All event triggers and filters
- `references/contexts.md` - Available contexts and their properties
- `references/expressions.md` - Expression syntax and functions

**Building Actions:**
- `references/action-metadata-syntax.md` - action.yml metadata reference
- `references/create-a-composite-action.md` - Step-by-step composite action guide
- `references/create-a-javascript-action.md` - Build JavaScript actions with toolkit
- `references/create-a-docker-container-action.md` - Package actions in containers

**Advanced Features:**
- `references/dependency-caching.md` - Cache dependencies for faster builds
- `references/reuse-workflows.md` - Create reusable workflows across repos
- `references/best-practices.md` - Security, performance, and maintainability tips
- `references/debugging-guide.md` - Troubleshooting common workflow issues

## Examples

Working workflow templates:

- `examples/ci-basic.yml` - Simple test and build workflow
- `examples/ci-matrix.yml` - Multi-platform matrix build
- `examples/deploy-docker.yml` - Build and push Docker images
- `examples/deploy-pages.yml` - Deploy static site to GitHub Pages
- `examples/scheduled-cleanup.yml` - Run tasks on cron schedule
- `examples/reusable-workflow.yml` - Callable workflow pattern

## Best Practices

**Security:**
- Use specific action versions (`actions/checkout@v4`, not `@main`)
- Limit `GITHUB_TOKEN` permissions with `permissions:` block
- Store credentials in secrets, never hardcode in workflows
- Use `pull_request_target` carefully to avoid code injection

**Performance:**
- Cache dependencies to reduce build times
- Run independent jobs in parallel (default behavior)
- Use `concurrency:` to cancel outdated runs
- Minimize runner usage to stay within limits

**Maintainability:**
- Use reusable workflows to share common patterns
- Organize complex workflows into multiple files
- Add descriptive `name:` fields to all jobs and steps
- Document non-obvious logic with YAML comments
