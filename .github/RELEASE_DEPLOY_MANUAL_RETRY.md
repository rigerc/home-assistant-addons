# Manual Release Deploy Retry Guide

This guide explains how to manually retry a failed release build or trigger a build for an existing release.

## When to Use Manual Retry

Use the manual retry workflow when:
- A build failed due to transient issues (network, rate limiting, temporary service outage)
- You've fixed a build issue and want to retry without creating a new release PR
- You need to rebuild packages for an existing release

## Prerequisites

Before manually retrying, ensure:
1. The release tag exists in the repository (e.g., `profilarr-v1.2.3`)
2. The release draft exists (check GitHub Releases page)
3. You have push access to the repository

## How to Retry via GitHub UI

1. Go to **Actions** tab in your repository
2. Select **Release Deploy** workflow from the left sidebar
3. Click **Run workflow** button (top right)
4. Fill in the required inputs:
   - **addon**: The addon name (e.g., `profilarr`, `romm`, `cleanuparr`)
   - **version**: The version string (e.g., `v1.2.3`)
   - **tag**: The complete release tag (e.g., `profilarr-v1.2.3`)
5. Click **Run workflow**

## How to Retry via GitHub CLI

```bash
# Install GitHub CLI if needed
# brew install gh  # macOS
# sudo apt install gh  # Ubuntu/Debian

# Authenticate
gh auth login

# Run the workflow
gh workflow run release-deploy.yaml \
  --ref main \
  -f addon='profilarr' \
  -f version='v1.2.3' \
  -f tag='profilarr-v1.2.3'
```

## Input Format Examples

| Addon | Version | Tag |
|-------|---------|-----|
| profilarr | v1.2.3 | profilarr-v1.2.3 |
| romm | v0.4.1 | romm-v0.4.1 |
| cleanuparr | v0.4.0 | cleanuparr-v0.4.0 |
| huntarr | v0.3.0 | huntarr-v0.3.0 |

## What Happens During Retry

1. **Extract addon info** - Validates addon name against manifest
2. **Build** - Builds for aarch64 and amd64 architectures
3. **On Success**:
   - Adds build status to release notes
   - Publishes the draft release
   - Triggers metadata update
4. **On Failure**:
   - Adds failure status to release notes (temporarily)
   - Creates a GitHub issue to track the failure
   - Deletes the draft release and tag

## Troubleshooting

### "Release not found" error

If you get a release not found error during manual retry:
1. Check that the release tag still exists: `git tag | grep <tag-name>`
2. Check GitHub Releases page to verify the draft exists
3. If the tag was deleted in a previous cleanup, you'll need to:
   - Create a new commit with `fix:` or `feat:` to trigger a new release PR
   - Or manually recreate the tag and draft release

### Build still fails after retry

If the build continues to fail:
1. Review the workflow logs carefully
2. Check the specific build step that's failing
3. Test the build locally using `.github/workflows/builder.yaml`
4. Fix the underlying issue in a new PR
5. Merge the fix and wait for automatic release

### Manual retry doesn't publish the release

Check that:
1. Both architecture builds (aarch64 and amd64) completed successfully
2. The `publish-release` job ran without errors
3. The release has the "Build Information" section added

## Build Status in Releases

After a successful build, the release notes will include:

```markdown
---

## 🏗️ Build Information

✅ **Build Status**: Success
📦 **Architectures**: aarch64, amd64
🔗 **Workflow Run**: [link to workflow run]
⏱️ **Built**: 2026-02-05 12:34:56 UTC

Packages are available at: `ghcr.io/[owner]/[addon]`
```

## Automatic Issue Creation

When a build fails, an issue is automatically created with:
- Build failure details
- Link to failed workflow run
- Instructions for manual retry
- Suggested next steps

Look for issues labeled `build-failure` and `automation`.

## Best Practices

1. **Check logs first** - Always review the workflow logs before retrying
2. **Fix root cause** - Don't retry repeatedly without addressing the underlying issue
3. **Use CLI for bulk retries** - If multiple addons failed, use the CLI in a script
4. **Monitor the retry** - Watch the workflow progress after triggering
5. **Close tracking issues** - After successful retry, close the auto-created issue

## Related Workflows

- **Builder** (`.github/workflows/builder.yaml`) - Tests builds on PRs
- **Release Please** (`.github/workflows/release-please.yaml`) - Creates releases
- **Addon Metadata** (`.github/workflows/addon-metadata.yaml`) - Updates repository metadata
