# CLI Commands Reference

Complete reference for all release-please CLI commands and options.

## Installation

```bash
npm install -g release-please
```

## Global Options

Available on all commands:

| Option | Type | Description |
|--------|------|-------------|
| `--token` | string | REQUIRED. GitHub token with repo write permissions |
| `--repo-url` | string | REQUIRED. GitHub repository in format `<owner>/<repo>` |
| `--api-url` | string | Base URI for REST API. Defaults to `https://api.github.com` |
| `--graphql-url` | string | Base URI for GraphQL. Defaults to `https://api.github.com` |
| `--target-branch` | string | Branch for release PRs and tags. Defaults to default branch |
| `--dry-run` | boolean | Report activity without taking effect |
| `--debug` | boolean | Set log level to DEBUG |
| `--trace` | boolean | Set log level to TRACE |

## Commands

### bootstrap

Generate initial configuration files.

```bash
release-please bootstrap \
  --token=$GITHUB_TOKEN \
  --repo-url=<owner>/<repo> \
  --release-type=<release-type>
```

#### Bootstrap Options

| Option | Type | Description |
|--------|------|-------------|
| `--config-file` | string | Path to config file. Default: `release-please-config.json` |
| `--manifest-file` | string | Path to manifest file. Default: `.release-please-manifest.json` |
| `--release-type` | ReleaseType | Language strategy for the package |
| `--package-name` | string | Name of the package |
| `--component` | string | Component name for branch/tag |
| `--path` | string | Path for changes. Default: `.` |
| `--initial-version` | string | Starting version. Default: `0.0.0` |
| `--versioning` | VersioningStrategy | Version bumping strategy |
| `--bump-minor-pre-major` | boolean | Bump minor for breaking changes < 1.0.0 |
| `--bump-patch-for-minor-pre-major` | boolean | Bump patch for features < 1.0.0 |
| `--prerelease-type` | string | Prerelease type (alpha, beta, rc) |
| `--draft` | boolean | Create releases as drafts |
| `--prerelease` | boolean | Mark releases as prereleases |
| `--force-tag-creation` | boolean | Force Git tag creation for drafts |
| `--draft-pull-request` | boolean | Create PRs as drafts |
| `--label` | string | Labels for release PRs. Default: `autorelease: pending` |
| `--release-label` | string | Labels after tagging. Default: `autorelease: tagged` |
| `--changelog-path` | string | Path to CHANGELOG. Default: `CHANGELOG.md` |
| `--changelog-type` | ChangelogType | Changelog strategy. Default: `default` |
| `--changelog-sections` | string | Comma-separated commit scopes for headings |
| `--changelog-host` | string | Host for commit links. Default: `https://github.com` |
| `--pull-request-title-pattern` | string | Override PR title pattern |
| `--pull-request-header` | string | Override PR header |
| `--pull-request-footer` | string | Override PR footer |
| `--component-no-space` | boolean | Disable space before component in PR title |
| `--extra-files` | string[] | Extra file paths to update |
| `--version-file` | string | Ruby only. Path to version.rb |

### release-pr

Create or update release pull requests.

```bash
release-please release-pr \
  --token=$GITHUB_TOKEN \
  --repo-url=<owner>/<repo>
```

#### With Manifest Config

When `release-please-config.json` exists:

| Option | Type | Description |
|--------|------|-------------|
| `--config-file` | string | Path to config file. Default: `release-please-config.json` |
| `--manifest-file` | string | Path to manifest file. Default: `.release-please-manifest.json` |
| `--skip-labeling` | boolean | Skip applying labels to PRs |

#### Without Manifest Config

All options from `bootstrap` command plus:

| Option | Type | Description |
|--------|------|-------------|
| `--monorepo-tags` | boolean | Add prefix to tags for monorepos |
| `--signoff` | string | Add Signed-off-by line. Format: `Name <email>` |
| `--include-v-in-tags` | boolean | Include "v" in tag versions. Default: `true` |

### github-release

Create GitHub releases from merged release PRs.

```bash
release-please github-release \
  --token=$GITHUB_TOKEN \
  --repo-url=<owner>/<repo>
```

#### With Manifest Config

| Option | Type | Description |
|--------|------|-------------|
| `--config-file` | string | Path to config file. Default: `release-please-config.json` |
| `--manifest-file` | string | Path to manifest file. Default: `.release-please-manifest.json` |

#### Without Manifest Config

| Option | Type | Description |
|--------|------|-------------|
| `--path` | string | Path for changes. Default: `.` |
| `--package-name` | string | Name of the package |
| `--component` | string | Component name for branch/tag |
| `--release-type` | ReleaseType | Language strategy |
| `--monorepo-tags` | boolean | Add prefix to tags |
| `--pull-request-title-pattern` | string | Override PR title pattern |
| `--pull-request-header` | string | Override PR header |
| `--pull-request-footer` | string | Override PR footer |
| `--draft` | boolean | Create releases as drafts |
| `--prerelease` | boolean | Mark releases as prereleases |
| `--force-tag-creation` | boolean | Force Git tag creation |
| `--label` | string | Labels for release PRs. Default: `autorelease: pending` |
| `--release-label` | string | Labels after tagging. Default: `autorelease: tagged` |
| `--include-v-in-tags` | boolean | Include "v" in tag versions. Default: `true` |

## Deprecated Commands

### manifest-pr

Deprecated. Use `release-pr` instead.

### manifest-release

Deprecated. Use `github-release` instead.

## Common Workflows

### Initial Setup

```bash
# Bootstrap configuration
release-please bootstrap \
  --token=$GITHUB_TOKEN \
  --repo-url=myowner/myrepo \
  --release-type=node

# Review and merge the bootstrap PR
```

### Test Locally

```bash
# Dry run with debug output
release-please release-pr \
  --token=$GITHUB_TOKEN \
  --repo-url=myowner/myrepo \
  --dry-run \
  --debug

# Test against a feature branch
release-please release-pr \
  --token=$GITHUB_TOKEN \
  --repo-url=myowner/myrepo \
  --target-branch=feature/test \
  --dry-run
```

### Manual Release Creation

```bash
# Create release PR
release-please release-pr \
  --token=$GITHUB_TOKEN \
  --repo-url=myowner/myrepo

# After merging PR, create GitHub release
release-please github-release \
  --token=$GITHUB_TOKEN \
  --repo-url=myowner/myrepo
```

### Force Specific Version

```bash
release-please release-pr \
  --token=$GITHUB_TOKEN \
  --repo-url=myowner/myrepo \
  --release-as=2.0.0
```

## Environment Variables

```bash
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
```

Set token as environment variable to avoid passing it repeatedly.

## Exit Codes

- `0`: Success
- `1`: Error occurred

Use `--debug` or `--trace` to diagnose errors.
