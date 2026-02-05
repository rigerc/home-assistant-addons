---
name: release-please
description: This skill should be used when the user asks to "setup release-please", "configure release-please", "create release automation", "bootstrap release-please", "add release-please to repo", "automate releases with release-please", or mentions release-please, GitHub release automation, or conventional commits based releasing.
version: 0.1.0
---

# Release Please

Automate versioning and releases using conventional commits with release-please, Google's tool for automated release management.

## Purpose

Generate release pull requests and GitHub releases based on conventional commits. Parse commit messages to determine semantic version bumps, update version files, and create changelogs automatically.

## When to Use This Skill

Use this skill when:
- Setting up automated releases for a new or existing repository
- Configuring release-please for monorepos or single packages
- Troubleshooting release-please configuration or workflow issues
- Bootstrapping release-please with the CLI or GitHub Actions
- Customizing changelog formatting or versioning strategies
- Setting up manifest-based releases for complex projects

## Core Workflow

### Step 1: Install the CLI

Install release-please globally for local testing and bootstrap:

```bash
npm i release-please -g
```

### Step 2: Choose Configuration Approach

**Manifest-based (recommended):** Use for monorepos or single packages. Configuration is stored in source-controlled JSON files.

**CLI-based (legacy):** Specify all options via command-line flags. Less flexible, harder to maintain.

Always use manifest-based configuration unless there's a specific reason not to.

### Step 3: Bootstrap with the CLI

Run the bootstrap command to generate initial configuration files:

```bash
release-please bootstrap \
  --token=$GITHUB_TOKEN \
  --repo-url=<owner>/<repo> \
  --release-type=<release-type>
```

This opens a pull request with:
- `release-please-config.json` - Package configuration
- `.release-please-manifest.json` - Version tracking

Common release types: `node`, `python`, `rust`, `go`, `java`, `maven`, `ruby`, `php`, `dart`, `elixir`, `simple`

### Step 4: Configure Packages (Manifest-based)

Edit `release-please-config.json` to configure packages. For a single package at the root:

```json
{
  "packages": {
    ".": {
      "release-type": "node"
    }
  }
}
```

For a monorepo with multiple packages:

```json
{
  "packages": {
    "packages/frontend": {
      "release-type": "node"
    },
    "packages/backend": {
      "release-type": "python",
      "package-name": "my-backend"
    },
    "packages/rust-lib": {
      "release-type": "rust"
    }
  }
}
```

### Step 5: Test with Dry Run

Before merging, test the configuration with dry-run mode:

```bash
release-please release-pr \
  --token=$GITHUB_TOKEN \
  --repo-url=<owner>/<repo> \
  --dry-run \
  --debug
```

This shows what release-please would do without making changes.

### Step 6: Set Up GitHub Actions

Read this for documentation on release-please-action: `https://raw.githubusercontent.com/googleapis/release-please-action/refs/heads/main/README.md`

Create `.github/workflows/release-please.yml` to automate:

```yaml
on:
  push:
    branches:
      - main

permissions:
  contents: write
  pull-requests: write

jobs:
  release-please:
    runs-on: ubuntu-latest
    steps:
      - uses: googleapis/release-please-action@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
```

### Step 7: Use Conventional Commits

Follow the conventional commits specification to trigger version bumps:

- `feat:` - Minor version bump
- `fix:` - Patch version bump
- `BREAKING CHANGE:` - Major version bump
- `feat(lang)!: ` - Major with scope and exclamation
- `fix(api):` - Patch with scope

Examples:
```
feat: add user authentication
fix: resolve memory leak
feat(auth)!: change token format
```

### Step 8: Manage Release PRs

Release-please automatically:
1. Creates a release PR when conventional commits are detected
2. Updates the PR as new commits are added
3. Tags the release and creates GitHub release after merging

Never manually edit the release PR. Let release-please manage it.

## Configuration Options

**Configuration Schema Reference:** For complete configuration validation and all available options, consult **`references/config-schema.json`**. This JSON schema defines the full structure of `release-please-config.json`, including all supported properties, their types, and valid values. Use it to validate configurations programmatically or discover advanced options not covered here.

### Per-Package Options

Override defaults for specific packages:

```json
{
  "packages": {
    "path/to/pkg": {
      "release-type": "python",
      "package-name": "custom-name",
      "component": "my-component",
      "changelog-path": "docs/CHANGELOG.md",
      "changelog-type": "github",
      "changelog-host": "https://github.com",
      "extra-files": ["README.md"]
    }
  }
}
```

### Top-Level Defaults

Set defaults that apply to all packages:

```json
{
  "release-type": "node",
  "bump-minor-pre-major": true,
  "bump-patch-for-minor-pre-major": false,
  "draft": false,
  "prerelease": false,
  "changelog-sections": [
    {"type": "feat", "section": "Features"},
    {"type": "fix", "section": "Bug Fixes"}
  ],
  "packages": {
    ".": {}
  }
}
```

### Versioning Strategies

Control how versions are bumped based on commits:

| Strategy | Description |
|----------|-------------|
| `default` | Standard SemVer (feat→minor, fix→patch, BREAKING→major) |
| `always-bump-patch` | Always increment patch |
| `always-bump-minor` | Always increment minor |
| `always-bump-major` | Always increment major |
| `service-pack` | Java-style service packs (1.2.3-sp.1) |
| `prerelease` | Prerelease versions (1.2.0-beta.1) |

Configure with `"versioning": "strategy-name"` or `"prerelease": true`.

### Monorepo Plugins

Enable plugins for monorepo-specific features:

```json
{
  "plugins": [
    "node-workspace",
    "cargo-workspace",
    "maven-workspace",
    "linked-versions",
    "sentence-case",
    "group-priority"
  ]
}
```

The workspace plugins automatically update inter-package dependencies.

## Advanced Features

### Custom File Updates

Update files other than standard package files:

```json
{
  "extra-files": [
    "VERSION.txt",
    {
      "type": "json",
      "path": "manifest.json",
      "jsonpath": "$.version"
    },
    {
      "type": "yaml",
      "path": "config/app.yaml",
      "jsonpath": "$.app.version"
    }
  ]
}
```

Annotate files to mark version locations:

Inline annotations:
```yaml
# x-release-please-version
version: "1.0.0"  # x-release-please-major
```

Block annotations:
```yaml
# x-release-please-start-version
dependencies:
  my-lib: "1.0.0"
# x-release-please-end
```

### Pull Request Customization

Customize PR appearance:

```json
{
  "pull-request-title-pattern": "chore${scope}: release${component} ${version}",
  "pull-request-header": ":robot: I have created a release *beep* *boop*",
  "pull-request-footer": "This PR was generated with Release Please.",
  "draft-pull-request": true,
  "label": "autorelease: pending",
  "release-label": "autorelease: tagged"
}
```

### Bootstrap Configuration

Set initial state for existing repositories:

```json
{
  "bootstrap-sha": "abc123def456...",
  "packages": {
    ".": {
      "release-as": "2.0.0"
    }
  }
}
```

Manually set versions in `.release-please-manifest.json`:

```json
{
  ".": "1.5.0"
}
```

### Multiple Release Branches

Support LTS or maintenance branches:

```yaml
# .github/workflows/release-please.yml
jobs:
  release-please-main:
    # ... config for main branch
    with:
      target-branch: main

  release-please-1.x:
    # ... config for 1.x branch
    with:
      target-branch: release/1.x
```

## Troubleshooting

### Debug with CLI

Use debug mode to understand what's happening:

```bash
release-please release-pr \
  --token=$GITHUB_TOKEN \
  --repo-url=<owner>/<repo> \
  --debug \
  --trace
```

### Test in Separate Branch

Test configuration changes safely:

```bash
release-please release-pr \
  --token=$GITHUB_TOKEN \
  --repo-url=<owner>/<repo> \
  --target-branch=test-branch \
  --dry-run
```

### Common Issues

**No release PR created:** Check that commits follow conventional commits format. Use `--debug` to see commit parsing.

**Wrong version bump:** Verify conventional commits. `feat!` or `BREAKING CHANGE:` footer triggers major bump.

**Previous release not found:** With manifest config, check `.release-please-manifest.json` exists. Without manifest, may need `--initial-version`.

**Tag not found:** Check `include-component-in-tag` if using simple tags like `v1.0.0` instead of `component-v1.0.0`.

**Draft release issues:** Use `"force-tag-creation": true` when `"draft": true` to ensure tags are created immediately.

### Force Re-run

If a release PR was closed and reopened, manually add labels:
1. Remove `autorelease:closed` label
2. Add `autorelease:pending` and `release-please:force-run` labels

## Lifecycle Labels

Release-please uses labels to track release state:

- `autorelease: pending` - Release PR is open and pending merge
- `autorelease: tagged` - Release has been created and tagged
- `autorelease: snapshot` - Snapshot version PR (Java/Maven)

Customize with `"label"` and `"release-label"` configuration.

## Additional Resources

### Reference Files

For detailed configuration options:
- **`references/config-schema.json`** - Official JSON schema for validating release-please-config.json. Contains all configuration properties, types, and valid values. Use this schema to validate configurations programmatically or discover advanced options.
- **`references/manifest-config.md`** - Complete manifest configuration reference
- **`references/cli-commands.md`** - All CLI commands and options
- **`references/release-types.md`** - Supported languages and package managers

### Example Files

Working configurations in `examples/`:
- **`examples/simple-node.json`** - Single Node.js package
- **`examples/monorepo-mixed.json`** - Multi-language monorepo
- **`examples/github-action.yml`** - Complete GitHub Actions workflow
- **`examples/bootstrap-commands.sh`** - Bootstrap CLI commands

### Official Documentation

- [release-please GitHub](https://github.com/googleapis/release-please)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)
