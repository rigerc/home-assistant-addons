---
name: commitlint
description: This skill should be used when the user asks to "setup commitlint", "configure commitlint", "add commit linting", "create commitlint config", "lint commit messages", "setup husky for commits", "add commit-msg hook", "validate commits", or mentions commitlint, conventional commits, commit conventions, or commit message validation.
version: 0.1.0
---

# Commitlint Configuration and Setup

## Purpose

Configure commitlint to enforce commit message conventions in projects. Commitlint validates commit messages against configurable rules, ensuring consistent commit history that enables automated changelogs, version bumps, and semantic release workflows.

## When to Use This Skill

Use this skill when:
- Setting up commitlint for a new or existing project
- Configuring commit message validation rules
- Integrating commitlint with git hooks (Husky)
- Setting up commitlint in CI/CD pipelines
- Creating custom commit message conventions
- Troubleshooting commitlint configuration issues
- Migrating between commitlint configurations

## Core Workflow

### Step 1: Install Commitlint

Install commitlint CLI and a configuration package as development dependencies.

**Using npm:**
```bash
npm install -D @commitlint/cli @commitlint/config-conventional
```

**Using other package managers:**
- **yarn:** `yarn add -D @commitlint/cli @commitlint/config-conventional`
- **pnpm:** `pnpm add -D @commitlint/cli @commitlint/config-conventional`
- **bun:** `bun add -d @commitlint/cli @commitlint/config-conventional`
- **deno:** `deno add -D npm:@commitlint/cli npm:@commitlint/config-conventional`

The `@commitlint/config-conventional` package provides the standard Conventional Commits specification. Alternative configurations can be used based on project needs.

### Step 2: Create Configuration File

Create a configuration file in the project root. The recommended approach uses ES module syntax:

```bash
echo "export default { extends: ['@commitlint/config-conventional'] };" > commitlint.config.js
```

**Important considerations:**
- **Node v24+:** If the project lacks a `package.json`, commitlint may fail to load the config. Fix by either:
  - Adding `package.json` with `npm init es6`
  - Renaming config to `commitlint.config.mjs`
- **TypeScript projects:** Use `.ts`, `.cts`, or `.mts` extensions with proper type imports

Commitlint automatically discovers configuration files in this priority order:
1. `.commitlintrc` (various formats: `.json`, `.yaml`, `.yml`, `.js`, `.cjs`, `.mjs`, `.ts`, `.cts`, `.mts`)
2. `commitlint.config.*` (same extension variants)
3. `commitlint` field in `package.json`

### Step 3: Configure Rules (Optional)

Customize rules in the configuration file to match project requirements:

```javascript
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [2, 'always', [
      'feat',
      'fix',
      'docs',
      'style',
      'refactor',
      'test',
      'chore',
      'ci',
      'build',
      'revert'
    ]],
    'subject-case': [2, 'always', 'sentence-case'],
    'header-max-length': [2, 'always', 100]
  }
};
```

Rule configuration format: `[severity, applicability, value]`
- **Severity:** `0` (disable), `1` (warning), `2` (error)
- **Applicability:** `always` or `never`
- **Value:** Rule-specific configuration

### Step 4: Set Up Git Hook with Husky

Install and configure Husky to run commitlint on commit messages:

**Install Husky:**
```bash
npm install --save-dev husky
npx husky init
```

**Create commit-msg hook:**
```bash
echo "npx --no -- commitlint --edit \$1" > .husky/commit-msg
```

**For Windows users:**
```bash
echo "npx --no -- commitlint --edit `$1`" > .husky/commit-msg
```

**Alternative using npm script:**
```bash
npm pkg set scripts.commitlint="commitlint --edit"
echo "npm run commitlint \${1}" > .husky/commit-msg
```

Ensure the hook file is executable (Unix-like systems):
```bash
chmod +x .husky/commit-msg
```

### Step 5: Test the Setup

**Test against recent commits:**
```bash
npx commitlint --from HEAD~1 --to HEAD --verbose
```

This validates the last commit. Use `--verbose` flag for detailed output.

**Test the hook by committing:**
```bash
# This should fail
git commit -m "foo: invalid type"

# This should succeed
git commit -m "feat: add new feature"
```

Valid commit message format follows Conventional Commits:
```
type(scope?): subject
body?
footer?
```

Common types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`, `build`, `revert`

### Step 6: Configure CI/CD Integration (Optional)

Add commitlint validation to CI pipelines to ensure all commits are validated:

**GitHub Actions example:**
```yaml
name: Lint Commits
on: [push, pull_request]

jobs:
  commitlint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: actions/setup-node@v4
        with:
          node-version: lts/*
      - run: npm install -D @commitlint/cli @commitlint/config-conventional
      - name: Validate current commit
        if: github.event_name == 'push'
        run: npx commitlint --last --verbose
      - name: Validate PR commits
        if: github.event_name == 'pull_request'
        run: npx commitlint --from ${{ github.event.pull_request.base.sha }} --to ${{ github.event.pull_request.head.sha }} --verbose
```

## Common Commit Message Patterns

**Feature addition:**
```
feat(auth): add OAuth2 authentication support
```

**Bug fix:**
```
fix(api): resolve null pointer exception in user endpoint
```

**Breaking change:**
```
feat(api)!: migrate to v2 API endpoints

BREAKING CHANGE: API v1 endpoints are no longer supported
```

**Documentation:**
```
docs(readme): update installation instructions
```

**Chore:**
```
chore(deps): update dependencies to latest versions
```

## Configuration Options

### Extending Multiple Configurations

```javascript
export default {
  extends: [
    '@commitlint/config-conventional',
    'commitlint-config-lerna'
  ]
};
```

### Using Custom Parser Presets

```javascript
export default {
  parserPreset: 'conventional-changelog-atom',
  rules: {
    // Custom rules
  }
};
```

### Ignoring Certain Commits

```javascript
export default {
  extends: ['@commitlint/config-conventional'],
  ignores: [
    (commit) => commit.includes('WIP'),
    (commit) => commit.startsWith('Merge')
  ],
  defaultIgnores: true // Keep default ignores (merge commits, version tags, etc.)
};
```

### TypeScript Configuration

```typescript
import type { UserConfig } from '@commitlint/types';
import { RuleConfigSeverity } from '@commitlint/types';

const Configuration: UserConfig = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [RuleConfigSeverity.Error, 'always', ['feat', 'fix']],
  },
};

export default Configuration;
```

## Troubleshooting

**Error: "Please add rules to your commitlint.config.js"**
- Ensure configuration file exports a valid configuration object
- For Node v24+, verify `package.json` exists or use `.mjs` extension
- Check that the config file is in the project root

**Hook not executing:**
- Verify `.husky/commit-msg` file exists and is executable
- Check file encoding (must be UTF-8, especially on Windows)
- Ensure Husky is properly initialized with `npx husky init`

**Yarn v2+ compatibility issues:**
- Commitlint doesn't support Yarn v2 Plug'n'Play by default
- Use `nodeLinker: node-modules` in `.yarnrc.yml` as a workaround

**CI failures on shallow clones:**
- Set `fetch-depth: 0` in checkout actions to fetch full git history
- Commitlint needs commit history to validate ranges

## Additional Resources

### Reference Files

Detailed documentation available in `references/`:
- **`references/configuration-options.md`** - Complete configuration reference with all available options
- **`references/rules-reference.md`** - Comprehensive list of all commitlint rules with examples
- **`references/ci-setup.md`** - CI/CD integration examples for multiple platforms
- **`references/commit-conventions.md`** - Deep dive into Conventional Commits specification

### Example Files

Working configuration examples in `examples/`:
- **`examples/basic-config.js`** - Simple conventional commits setup
- **`examples/typescript-config.ts`** - TypeScript configuration with type safety
- **`examples/custom-rules.js`** - Advanced custom rule configuration
- **`examples/monorepo-config.js`** - Configuration for monorepo projects
- **`examples/husky-setup.sh`** - Complete Husky setup script

### External Documentation

- **Official commitlint docs:** Referenced from `/mnt/d/dev/projects/ha-addons-3/docs/commitlint/`
- **Conventional Commits:** https://www.conventionalcommits.org/
- **Husky documentation:** https://typicode.github.io/husky/

## Best Practices

✅ **DO:**
- Use `@commitlint/config-conventional` as a starting point
- Configure git hooks for immediate feedback during development
- Integrate with CI/CD for enforcement
- Customize rules to match team conventions
- Use `--verbose` flag when debugging
- Test configuration with `--from` and `--to` flags
- Document custom conventions in project README

❌ **DON'T:**
- Skip CI integration (local hooks can be bypassed)
- Use overly restrictive rules that hinder development
- Ignore default commit patterns (merges, reverts) without reason
- Forget to commit the configuration file to version control
- Use deprecated hook managers (prefer Husky v9+)
- Create configuration files without testing them first

## Quick Reference

**Common commands:**
```bash
# Lint last commit
npx commitlint --from HEAD~1

# Lint range of commits
npx commitlint --from <ref> --to <ref>

# Lint with verbose output
npx commitlint --last --verbose

# Use specific config file
npx commitlint --config ./custom-config.js

# Edit commit message interactively
npx commitlint --edit
```

**Standard commit types:**
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation changes
- `style` - Code style changes (formatting, etc.)
- `refactor` - Code refactoring
- `test` - Test changes
- `chore` - Maintenance tasks
- `ci` - CI/CD changes
- `build` - Build system changes
- `revert` - Revert previous commit

**Rule severity levels:**
- `0` - Disabled
- `1` - Warning (doesn't fail)
- `2` - Error (fails commit)
