# GitHub Actions Workflows - Complete Guide

Your repository uses a sophisticated CI/CD system for Home Assistant add-ons. Here's how it works.

## Overview

Your repository contains 4 Home Assistant add-ons:
- **cleanuparr** (v0.2.15)
- **huntarr** (v0.1.8)
- **profilarr** (v1.0.13)
- **romm** (v0.2.0)

The workflows handle automated releases, building multi-architecture Docker images, and continuous integration testing.

## Quick Start: Making a Release

**TL;DR** - To release a new version:

1. **Make your changes** and commit to main using conventional commits:
   ```bash
   git commit -m "feat(huntarr): add new search feature"
   git push origin main
   ```

2. **Wait for Release Please** to create/update a Release PR (automated)

3. **Review the Release PR**:
   - Check the generated CHANGELOG
   - Verify version bump is correct

4. **Merge the Release PR** - This automatically:
   - Creates a GitHub release with git tag
   - Builds Docker images for all architectures
   - Publishes to GitHub Container Registry

**That's it!** The entire build and publish process is automated.

## How Releases Work

### Release Flow

```
1. Push to main → addon-metadata.yml
   ├─ Updates manifests and configs
   └─ Triggers Builder workflow

2. Builder workflow completes → lint.yaml
   ├─ Validates addon changes
   └─ Builds/tests images

3. release-please.yaml runs
   ├─ Creates/updates Release PRs
   ├─ Generates CHANGELOGs
   └─ When merged, creates GitHub releases

4. Releases created → addon-build.yaml
   └─ Builds and publishes final Docker images
```

### 1. Release Please Workflow

**File**: `.github/workflows/release-please.yaml`

**Triggers**: Push to main, manual dispatch

**How it works**:

```yaml
# Step 1: Release Please analyzes commit messages
# Looks for conventional commits (feat:, fix:, etc.)
# Creates/updates Release PRs for each addon

# Step 2: When Release PR is merged
# - Creates GitHub release with tag like "cleanuparr-0.2.16"
# - Updates CHANGELOG.md
# - Updates version in config.yaml and build.yaml

# Step 3: Triggers builds
# For each released addon, dispatches addon-build.yaml
```

**Configuration files**:
- `release-please-config.json` - Defines packages and changelog sections
- `.release-please-manifest.json` - Current versions

**Version updates happen in**:
- `{addon}/config.yaml` (version field)
- `{addon}/build.yaml` (org.opencontainers.image.version label)
- `{addon}/CHANGELOG.md` (generated)

### 2. Addon Build Workflow

**File**: `.github/workflows/addon-build.yaml`

**Triggers**: Workflow dispatch (called by release-please)

**How it works**:

```yaml
# Job 1: Prepare
# - Gets addon info (architectures, version)
# - Updates OCI labels in build.yaml
# - Commits metadata changes

# Job 2: Build (matrix)
# - Builds for each architecture (aarch64, amd64)
# - Pushes to ghcr.io
# - 3 hour timeout per arch

# Job 3: Metadata
# - Triggers addon-metadata workflow to update manifests
```

**Container registry**: `ghcr.io/{owner}/{addon}`

## Continuous Integration

### 3. Builder Workflow

**File**: `.github/workflows/builder.yaml`

**Triggers**:
- Push to main (addon files changed)
- Pull requests (addon files changed)
- Manual dispatch
- After addon-metadata completes

**Monitored files**:
```bash
build.yaml config.yaml Dockerfile rootfs/** apparmor.txt
```

**How it works**:

```yaml
# Job 1: Init
# - Finds changed addons
# - Determines if dev branch/PR (validation only) or main (build & push)

# Job 2: Build (matrix)
# For each [changed addon] × [architecture]:
# - Validates supported arch
# - Caches Docker layers
# - Dev/PR: Validates build only (--test flag)
# - Main: Builds and pushes images
```

**Branch behavior**:
- **main branch**: Builds and pushes images to registry
- **dev-* branches / PRs**: Validation only (no push)

### 4. Lint Workflow

**File**: `.github/workflows/lint.yaml`

**Triggers**: Same as builder.yaml

**Linting steps**:
1. **Addon-specific**:
   - Verifies `build.yaml` has `labels.project` key
   - Home Assistant add-on linter (`frenck/action-addon-linter`)

2. **Dockerfile**: hadolint validation

3. **Shell scripts**: Shellcheck (ignores `.claude`, `docs`, `scripts`)

4. **Markdown**: markdownlint (ignores README, CHANGELOG, DOCS)

5. **JSON**: jq validation

6. **YAML**: yamllint

### 5. Addon Metadata Workflow

**File**: `.github/workflows/addon-metadata.yml`

**Triggers**:
- Changes to config.yaml, Dockerfile, build.yaml
- Pull requests (if from same repo)
- Manual dispatch

**What it does**:
```bash
# Runs scripts/manifest.sh with various flags:
./scripts/manifest.sh     # Generate manifest
./scripts/manifest.sh -d  # Update dependabot config
./scripts/manifest.sh -w  # Update workflow dispatch inputs
```

Commits changes with: `chore: update addon manifest and configs [skip ci]`

## Developer's Guide

### Making a Release

#### Option 1: Automatic Release (Recommended)

1. **Use conventional commits** on main branch:
   ```bash
   feat(cleanuparr): add new cleanup feature
   fix(huntarr): resolve search bug
   chore(profilarr): update dependencies
   ```

2. **Release Please creates/updates PR**:
   - Analyzes commits since last release
   - Groups changes by type (features, fixes, etc.)
   - Updates CHANGELOG and version files

3. **Review and merge Release PR**:
   - Check the generated CHANGELOG
   - Verify version bump is correct
   - Merge the PR

4. **Automatic build triggers**:
   - GitHub release created with tag
   - Docker images built for all architectures
   - Published to GitHub Container Registry

#### Option 2: Manual Build

Trigger specific addon build:

```bash
# Via GitHub CLI
gh workflow run addon-build.yaml -f addon=cleanuparr

# Or via GitHub UI
# Actions → Addon Build and Release → Run workflow → Select addon
```

### Contributing Workflow

#### For New Features/Fixes

1. **Create feature branch**:
   ```bash
   git checkout -b feat/my-feature
   # or
   git checkout -b fix/my-bugfix
   ```

2. **Make changes to addon files**:
   ```bash
   # Modify addon files
   vim cleanuparr/rootfs/usr/bin/run.sh
   vim cleanuparr/config.yaml
   ```

3. **Create PR to main**:
   - CI runs automatically (builder + lint workflows)
   - Validates build without pushing images
   - Must pass all lint checks

4. **After approval, merge to main**:
   - Builder workflow builds and pushes images
   - Release Please opens/updates Release PR

5. **Merge Release PR when ready**:
   - Creates GitHub release
   - Triggers final production builds

#### For Quick Fixes

```bash
# Make changes directly on main (if you have permissions)
git checkout main
git pull
vim huntarr/Dockerfile
git add huntarr/Dockerfile
git commit -m "fix(huntarr): update base image"
git push

# Release Please will automatically create release PR
```

### Commit Message Format

Use **Conventional Commits** format:

```bash
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types**:
- `feat`: New feature → triggers minor version bump
- `fix`: Bug fix → triggers patch version bump
- `perf`: Performance improvement
- `refactor`: Code refactoring
- `chore`: Maintenance
- `docs`: Documentation
- `build`: Dependency updates
- `ci`: CI/CD changes

**Scopes** (addon names):
- `cleanuparr`
- `huntarr`
- `profilarr`
- `romm`

**Examples**:
```bash
feat(cleanuparr): add support for custom filters
fix(huntarr): resolve authentication timeout
chore(profilarr): update Python dependencies
docs(romm): improve installation instructions
```

**Breaking changes** (triggers major version bump):
```bash
feat(cleanuparr)!: redesign configuration format

BREAKING CHANGE: Configuration now uses YAML instead of JSON
```

### Testing Changes

#### Local Validation

```bash
# Check YAML syntax
yamllint .

# Lint shell scripts
shellcheck huntarr/rootfs/etc/**/*.sh

# Validate JSON
jq . release-please-config.json

# Test Dockerfile
docker build -t test ./cleanuparr
```

#### PR Validation

When you open a PR:
- ✓ Lint checks run automatically
- ✓ Build validation (no push)
- ✓ Shellcheck, hadolint, yamllint
- ✓ Addon linter checks

**Skip CI**: Add `[skip ci]` or `[ci skip]` to commit message

### Working with Workflows

#### View Workflow Runs

```bash
# List recent workflow runs
gh run list --workflow=release-please.yaml

# View specific run
gh run view <run-id>

# Watch workflow in real-time
gh run watch
```

#### Manual Triggers

```bash
# Trigger release please
gh workflow run release-please.yaml

# Build specific addon
gh workflow run addon-build.yaml -f addon=cleanuparr

# Regenerate metadata
gh workflow run addon-metadata.yml
```

#### Debug Build Issues

```bash
# Check builder workflow
gh run list --workflow=builder.yaml --limit 5

# View logs
gh run view <run-id> --log

# Re-run failed jobs
gh run rerun <run-id> --failed
```

### Concurrency Controls

**Builder and Lint workflows**:
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```
- Multiple pushes to same branch cancel previous runs
- Saves CI resources

**Release Please**:
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: false
```
- Never cancels release operations
- Ensures releases complete fully

### Best Practices

1. **Always use conventional commits** for automatic releases

2. **Test locally first** before pushing:
   ```bash
   # Validate configs
   yq eval . */config.yaml
   yq eval . */build.yaml
   ```

3. **Review Release PRs carefully**:
   - Check CHANGELOG accuracy
   - Verify version bumps
   - Test built images before merging

4. **Use PR labels**:
   - Add `ci` label to skip builder/lint on PRs
   - Useful for documentation-only changes

5. **Monitor builds**:
   ```bash
   # Watch addon build
   gh run watch
   ```

6. **Update metadata after config changes**:
   ```bash
   # Manually trigger if needed
   gh workflow run addon-metadata.yml
   ```

### Architecture Support

Current matrix builds for:
- `aarch64` (ARM 64-bit)
- `amd64` (x86 64-bit)

To add architecture, update `builder.yaml`:
```yaml
matrix:
  arch: ["aarch64", "amd64", "armv7"]  # Add armv7
```

### Troubleshooting

**Release PR not created**:
- Check commit messages use conventional format
- Verify changes are in tracked addons
- Review release-please.yaml logs

**Build fails**:
- Check Dockerfile syntax
- Verify base image availability
- Review architecture support in `config.yaml`

**Lint failures**:
- Run linters locally first
- Check `build.yaml` has `labels.project` key
- Ensure shell scripts are bash-compliant

**Images not pushing**:
- Verify on main branch (not PR)
- Check GITHUB_TOKEN permissions
- Ensure ghcr.io authentication works

### Key Files Reference

**Configuration**:
- `release-please-config.json` - Release automation config
- `.release-please-manifest.json` - Current versions
- `.github/dependabot.yml` - Dependency automation

**Per-addon**:
- `{addon}/config.yaml` - HA addon configuration
- `{addon}/build.yaml` - Build settings and labels
- `{addon}/CHANGELOG.md` - Release history (auto-generated)
- `{addon}/Dockerfile` - Container build instructions

**Scripts**:
- `scripts/manifest.sh` - Metadata generation script

**Actions**:
- `.github/actions/find-addons` - Discovers addon directories

---

This automation ensures consistent, reliable releases with minimal manual intervention while maintaining high code quality through comprehensive CI checks.
