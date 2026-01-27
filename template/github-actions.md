# GitHub Actions for Add-on Builds

This repository uses GitHub Actions to automatically build and publish Home Assistant add-on container images. The workflows handle multi-architecture builds, linting, and pushing to GitHub Container Registry (GHCR).

## Workflows

### Builder Workflow (`.github/workflows/builder.yaml`)

Automatically builds and pushes add-on images when monitored files change.

**Triggered on:**
- Push to `main` branch
- Pull requests to `main` branch

**Monitored Files:**
- `build.yaml`
- `config.yaml`
- `Dockerfile`
- `rootfs/`
- `apparmor.txt`

When any of these files change in an add-on directory, the workflow:
1. Detects which add-ons changed
2. Builds for each supported architecture
3. Pushes images to GHCR (on main branch)
4. Runs in test mode (on pull requests)

**Supported Architectures:**
- `aarch64` (ARM 64-bit)
- `amd64` (Intel/AMD 64-bit)

Add additional architectures to your `config.yaml` and `build.yaml` to enable them:
- `armv7` (ARM 32-bit)
- `armhf` (ARM hard float)
- `i386` (Intel 32-bit)

### Lint Workflow (`.github/workflows/lint.yaml`)

Validates add-on configuration and code quality before builds.

**Checks:**
- Home Assistant Add-on Linter (config.yaml validation)
- Shellcheck (shell script validation)
- Markdown lint (mdl)
- JSON validation (jq)
- YAML lint (yamllint)

## Setup

### 1. Configure GitHub Container Registry

Enable pushing images to GHCR:

1. Create a GitHub Personal Access Token:
   - Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Generate new token (classic)
   - Select scopes: `write:packages`
   - Save the token

2. Add token to repository secrets:
   - Go to your repository Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `CR_PAT`
   - Value: Your personal access token

### 2. Configure Your Add-on

**In `config.yaml`:**

```yaml
name: "Your Add-on"
version: "1.0.0"
slug: "your_addon"
arch:
  - aarch64
  - amd64
image: "ghcr.io/{username}/ha-addons-{slug}-{arch}"
```

The `{arch}` placeholder is automatically replaced with the architecture being built.

**In `build.yaml`:**

```yaml
build_from:
  aarch64: "ghcr.io/home-assistant/aarch64-base:3.23"
  amd64: "ghcr.io/home-assistant/amd64-base:3.23"
labels:
  maintainer: "Your Name <email@example.com>"
  org.opencontainers.image.source: https://github.com/{username}/{repo}/tree/main/{addon}
  org.opencontainers.image.version: "1.0.0"
```

### 3. Image Naming Convention

The workflow uses this naming pattern:

```
ghcr.io/{repository_owner}/ha-addons-{addon_slug}-{arch}
```

For example, for the romm add-on in this repository:
```
ghcr.io/rigerc/ha-addons-romm-aarch64
ghcr.io/rigerc/ha-addons-romm-amd64
```

## Building

### Automatic Builds

Simply push your changes to the `main` branch:

```bash
git add .
git commit -m "feat: Update add-on to version 1.0.0"
git push origin main
```

The workflow will automatically:
1. Detect changed add-ons
2. Build for each architecture
3. Push images to GHCR
4. Create a GitHub release draft

### Pull Request Builds

When you open a pull request, builds run in test mode without pushing images:

```bash
git checkout -b feature/new-feature
# Make changes
git push origin feature/new-feature
# Open PR on GitHub
```

### Manual Builds

To build locally or manually:

```bash
# Set up Docker credentials
echo $CR_PAT | docker login ghcr.io -u USERNAME --password-stdin

# Build all architectures
docker run --rm --privileged \
  -v ~/.docker/config.json:/root/.docker/config.json:ro \
  -v $(pwd):/data \
  ghcr.io/home-assistant/amd64-builder \
  --all -t /data/{addon} \
  -r https://github.com/{username}/{repository}
```

## Workflow Details

### Builder Workflow Steps

1. **Initialize Builds** (`init` job):
   - Checks out repository
   - Gets changed files
   - Finds all add-on directories
   - Determines which add-ons need building

2. **Build** (`build` job):
   - Runs for each changed add-on × architecture combination
   - Gets add-on information from config.yaml
   - Checks if architecture is supported
   - Restores Docker layer cache
   - Builds image using Home Assistant builder
   - Pushes to GHCR (main branch only)

### Docker Layer Caching

The workflow caches Docker layers between builds to speed up builds:

```yaml
- name: Cache Docker layers
  uses: actions/cache@v5.0.2
  with:
    path: /tmp/.buildx-cache
    key: ${{ runner.os }}-buildx-${{ matrix.addon }}-${{ matrix.arch }}-${{ github.sha }}
    restore-keys: |
      ${{ runner.os }}-buildx-${{ matrix.addon }}-${{ matrix.arch }}-
      ${{ runner.os }}-buildx-${{ matrix.addon }}-
```

### Build Labels

Images are labeled with metadata from `build.yaml`:

```
org.opencontainers.image.title
org.opencontainers.image.description
org.opencontainers.image.version
org.opencontainers.image.source
org.opencontainers.image.licenses
org.opencontainers.image.authors
```

## Version Management

### Updating Version

When releasing a new version:

1. Update `version` in `config.yaml`
2. Update `org.opencontainers.image.version` in `build.yaml`
3. Update `CHANGELOG.md`
4. Commit and push

```bash
# Update version in config.yaml and build.yaml
# Update CHANGELOG.md
git add config.yaml build.yaml CHANGELOG.md
git commit -m "chore: Bump version to 1.1.0"
git push origin main
```

### Breaking Versions

For breaking changes, add to `config.yaml`:

```yaml
breaking_versions:
  - "2.0.0"
  - "3.0.0"
```

This forces users to manually update when crossing these versions.

## Troubleshooting

### Build Fails

**Check workflow logs:**
1. Go to Actions tab in GitHub
2. Click on the failed workflow run
3. Expand the failed job
4. Review error messages

**Common issues:**
- Invalid `config.yaml` syntax
- Invalid `build.yaml` syntax
- Dockerfile build errors
- Base image not found
- Missing `CR_PAT` secret

### Images Not Pushing

**Verify `CR_PAT` secret:**
1. Check secret exists in repository settings
2. Verify token has `write:packages` scope
3. Regenerate token if expired

**Check image name in config.yaml:**
```yaml
# Correct - uses {arch} placeholder
image: "ghcr.io/user/ha-addons-myaddon-{arch}"

# Incorrect - hardcoded architecture
image: "ghcr.io/user/ha-addons-myaddon-amd64"
```

### Architecture Not Building

**Check `config.yaml`:**
```yaml
arch:
  - aarch64
  - amd64
```

**Check `build.yaml`:**
```yaml
build_from:
  aarch64: "ghcr.io/home-assistant/aarch64-base:3.23"
  amd64: "ghcr.io/home-assistant/amd64-base:3.23"
```

Both files must list the architecture.

## Best Practices

1. **Test locally first** - Use local build before pushing
2. **Use semantic versioning** - Follow MAJOR.MINOR.PATCH format
3. **Update changelog** - Document changes in CHANGELOG.md
4. **Monitor builds** - Check Actions tab for build status
5. **Use draft PRs** - Open PRs to test before merging
6. **Tag releases** - Create GitHub tags for release versions
7. **Review security** - Check base images for updates

## Example Workflow

```bash
# 1. Create feature branch
git checkout -b feature/new-feature

# 2. Make changes to add-on
# Edit files, test locally

# 3. Commit and push
git add .
git commit -m "feat: Add new feature"
git push origin feature/new-feature

# 4. Open pull request on GitHub
# Workflow will build and test (without pushing)

# 5. Review build results in Actions tab
# Fix any issues if needed

# 6. Merge pull request
# Workflow will build and push to GHCR

# 7. (Optional) Create GitHub release
# Go to Releases → Create new release
```

## References

- [Home Assistant Builder Action](https://github.com/home-assistant/actions/blob/master/builder/README.md)
- [Home Assistant Add-on Development](https://developers.home-assistant.io/docs/add-ons/)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
