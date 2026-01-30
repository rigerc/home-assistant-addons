---
name: dependabot
description: This skill should be used when the user asks to "create dependabot config", "setup dependabot", "configure dependabot.yml", "add dependabot", "enable dependency updates", "write dependabot configuration", or mentions Dependabot version updates, security updates, or automated dependency management.
version: 0.1.0
---

# Dependabot Configuration

Create and manage Dependabot configuration files for automated dependency updates in GitHub repositories.

## Purpose

Generate properly structured `dependabot.yml` configuration files that enable Dependabot to automatically update dependencies, create pull requests for security vulnerabilities, and keep projects up to date across multiple package ecosystems.

## When to Use This Skill

Use this skill when:
- Creating a new `.github/dependabot.yml` configuration file
- Adding Dependabot to a project for the first time
- Configuring dependency update schedules and policies
- Setting up Dependabot for multiple package managers (monorepo)
- Customizing pull request labels, reviewers, and commit messages
- Configuring access to private package registries
- Grouping related dependency updates
- Controlling which dependencies to update or ignore

## Core Workflow

### Step 1: Identify Package Ecosystems

Determine which package managers are used in the repository.

Scan for manifest files to identify ecosystems:
- `package.json` → npm
- `Gemfile` → bundler
- `requirements.txt`, `pyproject.toml` → pip
- `Cargo.toml` → cargo
- `go.mod` → gomod
- `pom.xml` → maven
- `build.gradle` → gradle
- `Dockerfile` → docker
- `.github/workflows/*.yml` → github-actions

Common ecosystem values:
- `npm` (JavaScript/TypeScript)
- `pip` (Python)
- `bundler` (Ruby)
- `cargo` (Rust)
- `gomod` (Go)
- `maven` (Java - Maven)
- `gradle` (Java - Gradle)
- `composer` (PHP)
- `nuget` (.NET)
- `docker` (Docker images)
- `github-actions` (GitHub Actions workflows)
- `terraform` (Terraform modules)

### Step 2: Determine Configuration Requirements

Ask about project-specific needs:

**Update schedule:**
- How frequently should dependencies be checked? (`daily`, `weekly`, `monthly`)
- Specific day/time for updates?

**Scope:**
- Update all dependencies or only specific ones?
- Different policies for production vs. development dependencies?
- Any packages to ignore or exclude?

**Pull request customization:**
- Should PRs have specific labels?
- Assign reviewers or assignees?
- Customize commit message format?

**Private registries:**
- Are any private package registries used?
- Need authentication configuration?

### Step 3: Create Basic Configuration

Start with the minimal required structure:

```yaml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
```

**Required fields:**
- `version`: Always `2` (current syntax version)
- `package-ecosystem`: Package manager identifier
- `directory`: Location of manifest files (usually `"/"`)
- `schedule.interval`: Update frequency

Place the file at `.github/dependabot.yml` in the repository root.

### Step 4: Add Common Customizations

Enhance the basic configuration with common options:

**Labels and reviewers:**
```yaml
labels:
  - "dependencies"
  - "npm"
reviewers:
  - "engineering-team"
assignees:
  - "tech-lead"
```

**Commit message customization:**
```yaml
commit-message:
  prefix: "npm"
  include: "scope"
```

**PR limits:**
```yaml
open-pull-requests-limit: 5
```

**Schedule timing:**
```yaml
schedule:
  interval: "weekly"
  day: "monday"
  time: "05:00"
  timezone: "America/Los_Angeles"
```

### Step 5: Configure Advanced Options (If Needed)

**Grouped updates:**
```yaml
groups:
  react-ecosystem:
    patterns:
      - "react"
      - "react-dom"
      - "@types/react*"

  dev-dependencies:
    dependency-type: "development"
    update-types:
      - "minor"
      - "patch"
```

**Selective updates:**
```yaml
allow:
  - dependency-type: "production"
  - dependency-name: "@myorg/*"

ignore:
  - dependency-name: "lodash"
  - dependency-name: "webpack"
    update-types: ["version-update:semver-major"]
```

**Private registries:**
```yaml
registries:
  npm-github:
    type: npm-registry
    url: https://npm.pkg.github.com
    token: ${{secrets.NPM_TOKEN}}

updates:
  - package-ecosystem: "npm"
    directory: "/"
    registries:
      - npm-github
```

### Step 6: Handle Multiple Ecosystems

For projects using multiple package managers, create separate update configurations:

```yaml
version: 2
updates:
  # Frontend dependencies
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    labels:
      - "dependencies"
      - "frontend"

  # Backend dependencies
  - package-ecosystem: "pip"
    directory: "/backend"
    schedule:
      interval: "weekly"
    labels:
      - "dependencies"
      - "backend"

  # Docker images
  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "monthly"
    labels:
      - "dependencies"
      - "docker"

  # GitHub Actions
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    labels:
      - "dependencies"
      - "ci"
```

### Step 7: Validate Configuration

Verify the configuration is valid:

1. Check YAML syntax (no tabs, proper indentation)
2. Ensure required fields are present
3. Verify ecosystem values are correct
4. Confirm directory paths exist
5. Validate schedule values (`daily`, `weekly`, `monthly`)
6. Check that referenced secrets exist in repository settings

Common validation errors:
- Using tabs instead of spaces
- Missing required fields
- Invalid ecosystem names
- Incorrect directory paths
- Malformed `allow`/`ignore` patterns

## Common Patterns

### Pattern: Basic Single Ecosystem

```yaml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    open-pull-requests-limit: 5
    labels:
      - "dependencies"
```

### Pattern: Production vs Development Split

```yaml
version: 2
updates:
  # Production dependencies - weekly
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    allow:
      - dependency-type: "production"
    labels:
      - "dependencies"
      - "production"

  # Development dependencies - monthly
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "monthly"
    allow:
      - dependency-type: "development"
    labels:
      - "dependencies"
      - "development"
```

### Pattern: Monorepo with Workspaces

```yaml
version: 2
updates:
  # Root workspace
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"

  # Frontend package
  - package-ecosystem: "npm"
    directory: "/packages/frontend"
    schedule:
      interval: "weekly"

  # Backend package
  - package-ecosystem: "npm"
    directory: "/packages/backend"
    schedule:
      interval: "weekly"
```

### Pattern: Grouped Updates

```yaml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    groups:
      # Group all minor and patch updates
      non-major:
        update-types:
          - "minor"
          - "patch"

      # Framework updates together
      react:
        patterns:
          - "react*"
          - "@types/react*"
```

## Quick Decision Matrix

**Choose update frequency:**
- `daily`: Critical production apps, security-sensitive projects
- `weekly`: Most projects (recommended default)
- `monthly`: Stable projects, fewer changes desired

**Choose versioning strategy:**
- `lockfile-only`: Update lockfiles, don't change manifest (npm, cargo default)
- `increase`: Always update version in manifest (bundler, pip default)
- `increase-if-necessary`: Only update manifest when needed
- `widen`: Expand version range to include new versions

**Configure PR limits:**
- `3-5`: Conservative, easier to review
- `10`: More aggressive updates
- `0`: Disable version updates (keep security updates only)

## Additional Resources

### Reference Files

For detailed information about all configuration options:
- **`references/configuration-options.md`** - Complete reference for all `dependabot.yml` options including `allow`, `ignore`, `groups`, `schedule`, `registries`, versioning strategies, and advanced configuration
- **`references/supported-ecosystems.md`** - Comprehensive guide to all supported package ecosystems with specific configuration examples for npm, pip, Docker, GitHub Actions, and more

### Example Files

Working example configurations in `examples/`:
- **`examples/basic-config.yml`** - Simple single-ecosystem configuration
- **`examples/multi-ecosystem.yml`** - Multiple package managers in one repository
- **`examples/grouped-updates.yml`** - Group related dependencies together
- **`examples/selective-updates.yml`** - Control exactly which dependencies update
- **`examples/monorepo.yml`** - Handle multiple packages in a monorepo
- **`examples/private-registry.yml`** - Configure private package registries
- **`examples/production-dev-split.yml`** - Different schedules for prod/dev dependencies

## Troubleshooting

### Configuration not working

**Check:**
1. File is at `.github/dependabot.yml` (exact path required)
2. YAML syntax is valid (no tabs, proper indentation)
3. All required fields are present
4. Package ecosystem names are correct
5. Directory paths match manifest file locations

### No pull requests created

**Possible causes:**
- Open PR limit reached
- All dependencies already up to date
- Dependencies excluded by `ignore` rules
- Schedule hasn't run yet
- Dependency graph not enabled

**Solutions:**
1. Check Dependabot logs in repository Security tab
2. Verify `allow`/`ignore` configuration
3. Ensure Dependabot is enabled in repository settings
4. Wait for next scheduled run

### Too many pull requests

**Solutions:**
1. Reduce `open-pull-requests-limit`
2. Use `groups` to combine related updates
3. Change `interval` to `weekly` or `monthly`
4. Add packages to `ignore` list

### Authentication failures

**Solutions:**
1. Verify secrets are configured in repository settings
2. Check registry URLs are correct
3. Ensure tokens have required permissions
4. Use `${{secrets.NAME}}` syntax (not plain text)

## Best Practices

✅ **DO:**
- Start with basic configuration and iterate
- Use weekly schedule for most projects
- Group related dependencies together
- Label PRs for easy filtering
- Add reviewers for important updates
- Use private registries for internal packages
- Test configuration with a single ecosystem first

❌ **DON'T:**
- Use tabs for indentation (YAML requires spaces)
- Set interval to `daily` unless necessary
- Ignore all major version updates blindly
- Leave authentication tokens in plain text
- Create too many separate ecosystem entries for monorepos
- Set `open-pull-requests-limit` too high initially
