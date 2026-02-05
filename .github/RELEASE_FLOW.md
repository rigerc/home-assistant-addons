# Release Flow Documentation

This document explains how the automated release and build system works, ensuring releases are only published when builds succeed.

## Overview

The system uses a **two-stage workflow approach**:
1. **Stage 1**: release-please creates DRAFT releases
2. **Stage 2**: release-deploy builds and conditionally publishes drafts

This ensures **no public releases without packages** and **no double-triggering**.

## Complete Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│  Developer pushes conventional commits to main branch               │
└────────────────────────┬────────────────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  release-please      │
              │  - Creates/updates   │
              │    release PR        │
              └──────────┬───────────┘
                         │
                 Developer merges PR
                         │
                         ▼
              ┌──────────────────────┐
              │  release-please      │
              │  - Creates DRAFT     │
              │    release           │
              │  - Tags: addon-vX.Y  │
              │  - draft: true ✓     │
              └──────────┬───────────┘
                         │
                         │ Triggers via workflow_dispatch
                         │ (NOT release event - avoids double-trigger)
                         │
                         ▼
              ┌──────────────────────┐
              │  release-deploy      │
              │  (workflow_dispatch) │
              └──────────┬───────────┘
                         │
                         ├─────────────────────────────────┐
                         │                                 │
                         ▼                                 ▼
              ┌──────────────────┐           ┌──────────────────┐
              │  Build aarch64   │           │  Build amd64     │
              └──────────┬───────┘           └──────────┬───────┘
                         │                              │
                         └──────────┬───────────────────┘
                                    │
                    ┌───────────────┴────────────────┐
                    │                                │
                SUCCESS                          FAILURE
                    │                                │
                    ▼                                ▼
         ┌────────────────────┐          ┌──────────────────────┐
         │  publish-release   │          │  cleanup-on-failure  │
         │  - Add build info  │          │  - Add failure info  │
         │  - draft: false ✓  │          │  - Create issue      │
         │  - NOW PUBLIC      │          │  - Delete draft      │
         └──────────┬─────────┘          │  - Delete tag        │
                    │                    └──────────────────────┘
                    ▼                              │
         ┌────────────────────┐                   │
         │  trigger-metadata  │                   │
         │  - Update repo.json│          ❌ NO PUBLIC RELEASE
         └────────────────────┘
                    │
                    │
         ✅ RELEASE PUBLISHED WITH PACKAGES
```

## Key Design Decisions

### 1. No Release Event Triggers

**Why?**
- Draft release creation doesn't reliably trigger `release.created` events
- Publishing a draft would trigger `release.published`, causing a **double build**

**Solution:**
- Use only `workflow_dispatch` as the trigger
- release-please explicitly calls release-deploy via workflow_dispatch
- No automatic response to release events

### 2. Draft-First Approach

**Why?**
- Allows building packages before release is public
- Enables cleanup if build fails
- Maintains clean release history

**Configuration:**
```json
{
  "draft": true,  // release-please creates drafts
  "prerelease": false
}
```

### 3. Conditional Publishing

**How it works:**
```yaml
publish-release:
  needs: [extract-addon, build]  # Requires ALL to succeed
  # This job only runs if both dependencies succeed
  # Changes draft=false, making release public
```

**If build fails:**
```yaml
cleanup-on-failure:
  needs: [extract-addon, build]
  if: failure()  # Runs if ANY dependency fails
  # Deletes draft and tag - no public release
```

**Result:** Releases are ONLY published when builds succeed

## Trigger Methods

### 1. Automatic (via release-please)

When a release PR is merged:
```yaml
# .github/workflows/release-please.yaml
trigger-build:
  needs: release-please
  if: needs.release-please.outputs.releases_created == 'true'
  # Calls: gh workflow run release-deploy.yaml with addon/version/tag
```

### 2. Manual Retry

For failed builds or manual intervention:
```bash
gh workflow run release-deploy.yaml \
  --ref main \
  -f addon='profilarr' \
  -f version='v1.2.3' \
  -f tag='profilarr-v1.2.3'
```

Or via GitHub UI: Actions → Release Deploy → Run workflow

## Advantages

✅ **No orphaned releases** - Draft deleted if build fails
✅ **No double-triggering** - Only workflow_dispatch used
✅ **Conditional publishing** - Requires successful builds
✅ **Manual retry** - Can retry without new release PR
✅ **Build tracking** - Status added to release notes
✅ **Issue creation** - Auto-tracks failures

## Workflow States

### Draft Release States

| State | Condition | Actions Available |
|-------|-----------|-------------------|
| **Draft (building)** | Build in progress | Wait or cancel |
| **Published** | Build succeeded | None - release is live |
| **Deleted** | Build failed | Manual retry with workflow_dispatch |

### Build Outcomes

| Outcome | Draft Status | Tag Status | Issue Created | Release Notes |
|---------|-------------|------------|---------------|---------------|
| ✅ Success | Published | Kept | No | Build info added |
| ❌ Failure | Deleted | Deleted | Yes | N/A (deleted) |

## Troubleshooting

### Q: Why didn't my release trigger a build?

**A:** Check that:
1. release-please workflow completed successfully
2. `trigger-build` job ran (check workflow logs)
3. release-deploy workflow was triggered (check Actions tab)

### Q: Release is stuck as draft

**A:** This means the build hasn't completed or failed. Check:
1. release-deploy workflow status
2. Build job logs for errors
3. Manually retry if needed

### Q: How do I republish a deleted failed release?

**A:** Two options:
1. **Fix and retry**: Fix the issue, then manual workflow_dispatch
2. **New release**: Create new commits to trigger new release PR

### Q: Can I publish a draft manually?

**A:** Yes, but not recommended. Better to:
1. Investigate why build failed or didn't run
2. Fix the issue
3. Use manual workflow_dispatch to rebuild

Manual publishing means packages won't be built automatically.

## Related Files

- `.github/workflows/release-please.yaml` - Creates drafts and triggers builds
- `.github/workflows/release-deploy.yaml` - Builds and publishes
- `.github/RELEASE_DEPLOY_MANUAL_RETRY.md` - Manual retry guide
- `release-please-config.json` - Release-please configuration

## Monitoring

### Check Build Status

```bash
# List recent release-deploy runs
gh run list --workflow=release-deploy.yaml --limit 5

# Watch a specific run
gh run watch <run-id>

# View run logs
gh run view <run-id> --log
```

### Check Draft Releases

```bash
# List all releases (including drafts)
gh release list

# View specific release
gh release view <tag> --json isDraft,publishedAt
```

### Check Build Failure Issues

```bash
# List build failure issues
gh issue list --label build-failure
```

## Best Practices

1. **Monitor release-please PRs** - Review before merging
2. **Watch build progress** - Don't merge next PR until build completes
3. **Fix failures quickly** - Use auto-created issues as tracking
4. **Test in builder.yaml first** - Catch issues before release
5. **Use manual retry for transient failures** - Network issues, rate limits, etc.
