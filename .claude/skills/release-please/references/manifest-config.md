# Manifest Configuration Reference

Complete reference for `release-please-config.json` and `.release-please-manifest.json`.

## File Structure

### release-please-config.json

Defines package configuration and release behavior. Must exist at the root of the repository.

### .release-please-manifest.json

Tracks current versions for each package. Auto-managed by release-please.

## Top-Level Configuration Options

### Bootstrap Options

```json
{
  "bootstrap-sha": "6fc119838885b0cb831e78ddd23ac01cb819e585",
  "last-release-sha": "7td2b9838885b3adf52e78ddd23ac01cb819e631"
}
```

- `bootstrap-sha`: SHA where commit scanning stops for initial release. Ignored after first release.
- `last-release-sha`: Override the SHA used as the previous release marker. Never ignored, remove after use.

### Release Behavior

```json
{
  "release-type": "node",
  "release-as": "1.2.3",
  "versioning": "default",
  "draft": true,
  "prerelease": true,
  "prerelease-type": "beta",
  "force-tag-creation": true,
  "skip-github-release": false
}
```

- `release-type`: Default release type for packages (node, python, rust, etc.)
- `release-as`: Force next version to this specific version
- `versioning`: Versioning strategy (default, always-bump-patch, etc.)
- `draft`: Create GitHub releases as drafts
- `prerelease`: Mark releases as pre-releases
- `prerelease-type`: Set prerelease type (alpha, beta, rc)
- `force-tag-creation`: Create Git tags immediately for draft releases
- `skip-github-release`: Skip creating GitHub releases (requires custom tagging)

### Pre-Major Versioning

```json
{
  "bump-minor-pre-major": true,
  "bump-patch-for-minor-pre-major": true
}
```

- `bump-minor-pre-major`: Breaking changes bump minor (not major) for versions < 1.0.0
- `bump-patch-for-minor-pre-major`: Features bump patch (not minor) for versions < 1.0.0

### Changelog Configuration

```json
{
  "changelog-type": "default",
  "changelog-host": "https://github.com",
  "changelog-sections": [
    {"type": "feat", "section": "Features", "hidden": false},
    {"type": "fix", "section": "Bug Fixes", "hidden": false},
    {"type": "chore", "section": "Chores", "hidden": true},
    {"type": "docs", "section": "Documentation", "hidden": false}
  ],
  "skip-changelog": false
}
```

- `changelog-type`: default or github (uses GitHub API for notes)
- `changelog-host`: Base URL for commit links (default: https://github.com)
- `changelog-sections`: Custom sections and commit type mappings
- `skip-changelog`: Skip updating CHANGELOG.md

### Pull Request Configuration

```json
{
  "draft-pull-request": true,
  "label": "autorelease: pending",
  "release-label": "autorelease: tagged",
  "pull-request-title-pattern": "chore${scope}: release${component} ${version}",
  "pull-request-header": ":robot: I have created a release",
  "pull-request-footer": "This PR was generated with Release Please."
}
```

- `draft-pull-request`: Create release PRs as drafts
- `label`: Labels for pending release PRs (comma-separated)
- `release-label`: Labels after release is tagged (comma-separated)
- `pull-request-title-pattern`: Template for PR title
- `pull-request-header`: Custom header text
- `pull-request-footer`: Custom footer text

### Monorepo Settings

```json
{
  "separate-pull-requests": false,
  "group-pull-request-title-pattern": "chore: release ${branch}",
  "always-update": false,
  "always-link-local": true
}
```

- `separate-pull-requests`: Create separate PR for each package
- `group-pull-request-title-pattern`: Title pattern when grouping releases
- `always-update`: Update PRs even when release notes unchanged
- `always-link-local`: Force link local dependencies (workspace plugins)

### Performance Tuning

```json
{
  "release-search-depth": 400,
  "commit-search-depth": 500,
  "sequential-calls": false
}
```

- `release-search-depth`: Limit number of releases to search
- `commit-search-depth`: Limit number of commits to scan
- `sequential-calls`: Make API calls sequentially (reduces throttling)

### Plugins

```json
{
  "plugins": [
    "node-workspace",
    "cargo-workspace",
    "maven-workspace",
    {
      "type": "node-workspace",
      "updatePeerDependencies": true,
      "merge": true
    },
    {
      "type": "linked-versions",
      "groupName": "my group",
      "components": ["pkgA", "pkgB"]
    },
    {
      "type": "group-priority",
      "groups": ["snapshot"]
    }
  ]
}
```

- `node-workspace`: Update Node.js workspace dependencies
- `cargo-workspace`: Update Cargo workspace dependencies
- `maven-workspace`: Update Maven workspace dependencies
- `linked-versions`: Sync versions across components
- `sentence-case`: Capitalize commit messages in changelog
- `group-priority`: Prioritize specific release groups

## Package Configuration

Packages are defined under the `packages` key with paths as keys:

```json
{
  "packages": {
    "path/to/package": {
      "component": "package-name",
      "package-name": "npm-package-name",
      "release-type": "node",
      "release-as": "2.0.0",
      "versioning": "default",
      "changelog-path": "CHANGELOG.md",
      "changelog-host": "https://github.com",
      "changelog-type": "default",
      "extra-files": ["README.md"],
      "exclude-paths": ["tests/**"],
      "include-component-in-tag": true,
      "draft": false,
      "prerelease": false
    }
  }
}
```

### Package Options

- `component`: Component name for tags and branches
- `package-name`: Package name (required for some types)
- `release-type`: Override default release type
- `release-as`: Override default release version
- `versioning`: Override default versioning strategy
- `changelog-path`: Path to changelog relative to package
- `changelog-host`: Override default changelog host
- `changelog-type`: Override default changelog type
- `extra-files`: Additional files to update
- `exclude-paths`: Paths to exclude from commit consideration
- `include-component-in-tag`: Include component name in tags
- `draft`: Override default draft setting
- `prerelease`: Override default prerelease setting

## Root Path Package

Use `"."` as path to release from repository root:

```json
{
  "packages": {
    ".": {
      "release-type": "simple"
    }
  }
}
```

## Manifest File Format

`.release-please-manifest.json` tracks versions:

```json
{
  ".": "1.2.3",
  "packages/frontend": "2.0.0",
  "packages/backend": "1.5.0"
}
```

Manually edit this file only during bootstrap to set initial versions.

## Extra Files Configuration

### Simple Files

```json
{
  "extra-files": [
    "VERSION.txt",
    "manifest.json"
  ]
}
```

### JSON Files

```json
{
  "extra-files": [
    {
      "type": "json",
      "path": "package.json",
      "jsonpath": "$.version"
    },
    {
      "type": "json",
      "path": "manifest.json",
      "jsonpath": "$.app.version"
    }
  ]
}
```

### YAML Files

```json
{
  "extra-files": [
    {
      "type": "yaml",
      "path": "config/app.yaml",
      "jsonpath": "$.version"
    }
  ]
}
```

### XML Files

```json
{
  "extra-files": [
    {
      "type": "xml",
      "path": "pom.xml",
      "xpath": "//project/version"
    }
  ]
}
```

### TOML Files

```json
{
  "extra-files": [
    {
      "type": "toml",
      "path": "Cargo.toml",
      "jsonpath": "$.package.version"
    }
  ]
}
```

### Generic Files with Annotations

```json
{
  "extra-files": [
    {
      "type": "generic",
      "path": "README.md"
    }
  ]
}
```

Use annotations in the file:
- `x-release-please-version` - Mark version line
- `x-release-please-major` - Always update major
- `x-release-please-minor` - Always update minor
- `x-release-please-patch` - Always update patch
- `x-release-please-start-version` / `x-release-please-end` - Block annotation

## Complete Example

```json
{
  "bootstrap-sha": "abc123",
  "release-type": "node",
  "bump-minor-pre-major": true,
  "changelog-sections": [
    {"type": "feat", "section": "Features"},
    {"type": "fix", "section": "Bug Fixes"}
  ],
  "plugins": ["node-workspace"],
  "packages": {
    ".": {},
    "packages/pkg-a": {
      "component": "pkg-a"
    },
    "packages/pkg-b": {
      "release-type": "python",
      "package-name": "my-pkg-b"
    }
  }
}
```
