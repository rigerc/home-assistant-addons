# Move README Generation to manifest.sh

## TL;DR

> **Goal**: Migrate README generation logic from `.github/actions/update-readme/action.yaml` into `scripts/manifest.sh` using gomplate templating.
> 
> **Key Innovation**: Environment variables (REPOSITORY, REPOSITORY_URL, AUTHOR_NAME, ADDONS_DATA) are **automatically derived inside the script** using git commands and jq - no manual setup needed!
> 
> **Deliverables**: 
> - Updated `scripts/manifest.sh` with new `--generate-readme` (`-g`) flag
> - Functions to generate root README.md and individual addon READMEs
> - Gomplate installation/verification
> - **Auto-derivation of all environment variables from git remote and manifest.json**
> - All functionality that exists in the GitHub Action
>
> **Estimated Effort**: Medium (~2-3 hours)
> **Parallel Execution**: NO - sequential implementation
> **Critical Path**: Parse args → Check gomplate → Generate root README → Generate addon READMEs

---

## Context

### Original Request
Move README generation from `.github/actions/update-readme/action.yaml` to `scripts/manifest.sh` using gomplate.

### Current State Analysis

**`.github/actions/update-readme/action.yaml` does:**
1. Installs jq and gomplate
2. Reads addon info from `manifest.json`
3. Sets environment variables for gomplate:
   - `REPOSITORY`, `REPOSITORY_URL`, `AUTHOR_NAME` (from GitHub context)
   - `ADDONS_DATA` (JSON array from manifest)
   - `ADDON_SLUG` (for individual addons)
4. Generates root `README.md` using `.README.tmpl`
5. Generates individual addon `README.md` files using `.README_ADDON.tmpl`

**Templates used:**
- `.README.tmpl`: Generates main repository README with addon list
- `.README_ADDON.tmpl`: Generates individual addon READMEs

**Current `manifest.sh` already does:**
- Generates `manifest.json` from addon directories
- Updates `dependabot.yml`
- Updates workflow dispatch inputs in `deployer.yaml` and `deployer-v3.yaml`
- Creates release-drafter configs

### Interview Summary
This is a migration/refactoring task to consolidate README generation into the existing manifest script, enabling local execution without GitHub Actions.

---

## Work Objectives

### Core Objective
Move the README generation functionality from the GitHub composite action into `scripts/manifest.sh` with the same capabilities, allowing local execution.

### Concrete Deliverables
1. New command-line flag `-g, --generate-readme` in `manifest.sh`
2. Gomplate installation/verification logic
3. `generate_root_readme()` function
4. `generate_addon_readme()` function  
5. Updated `usage()` function with new flag documentation
6. Integration into `main()` function

### Definition of Done
- [ ] `manifest.sh --generate-readme` generates both root README and all addon READMEs
- [ ] Works locally (not just in GitHub Actions)
- [ ] Can optionally generate READMEs for specific addons only
- [ ] Follows Google Shell Style Guide (skill guidelines)
- [ ] All existing functionality preserved

### Must Have
- Gomplate installation/verification (local or auto-install)
- Environment variable setup **automatically derived inside the script** using git and jq
- Support for generating specific addons or all addons
- Error handling for missing templates or manifest.json

### Must NOT Have (Guardrails)
- Do NOT remove the GitHub Action (keep for backward compatibility)
- Do NOT modify the templates (use existing `.README.tmpl` and `.README_ADDON.tmpl`)
- Do NOT change the manifest.json generation logic
- Do NOT add new dependencies beyond gomplate (which action already uses)

---

## Verification Strategy

### Test Decision
- **Infrastructure exists**: YES (gomplate already used in GitHub Action)
- **Automated tests**: NO (shell scripts typically don't have unit tests)
- **Framework**: None (manual verification via script execution)

### Agent-Executed QA Scenarios (MANDATORY)

**Scenario 1: Generate all READMEs locally**
```bash
# Preconditions: In project root directory
# Tool: Bash
Steps:
  1. Run: ./scripts/manifest.sh -g
  2. Verify: Check that README.md exists and has content
  3. Verify: Check that each addon has README.md (e.g., romm/README.md)
  4. Verify: Open README.md and confirm it contains "Home Assistant Add-ons"
  5. Verify: Open an addon README (e.g., romm/README.md) and confirm it has addon-specific content
Expected Result: All README files generated with correct content
Evidence: File listing with timestamps and content excerpts
```

**Scenario 2: Help documentation updated**
```bash
# Tool: Bash
Steps:
  1. Run: ./scripts/manifest.sh -h
  2. Verify: Help output includes --generate-readme flag
  3. Verify: Help shows example usage with -g flag
Expected Result: Help text includes new flag documentation
Evidence: Screenshot or output capture of help text
```

**Scenario 3: Gomplate not installed**
```bash
# Preconditions: Temporarily move gomplate binary
# Tool: Bash
Steps:
  1. Rename gomplate: mv /usr/local/bin/gomplate /tmp/gomplate.bak
  2. Run: ./scripts/manifest.sh -g
  3. Verify: Script handles missing gomplate gracefully (offers to install or shows helpful error)
  4. Restore gomplate: mv /tmp/gomplate.bak /usr/local/bin/gomplate
Expected Result: Graceful handling of missing dependency
Evidence: Error message output and restoration confirmation
```

---

## Execution Strategy

### Sequential Implementation
This task is sequential due to dependencies:
1. Add CLI flag support (depends: none)
2. Add gomplate check (depends: none)
3. Add root README function (depends: gomplate check)
4. Add addon README function (depends: root README function pattern)
5. Update main function (depends: all above)
6. Update usage docs (depends: flag implementation)

### Dependency Matrix
| Task | Depends On | Can Parallelize With |
|------|------------|---------------------|
| 1. Parse args flag | None | None |
| 2. Gomplate check | None | None |
| 3. Root README gen | 2 | None |
| 4. Addon README gen | 3 | None |
| 5. Update usage | 1 | 2, 3, 4 |
| 6. Integrate main | 1-5 | None |

### Agent Dispatch Summary
| Wave | Tasks | Recommended Profile |
|------|-------|-------------------|
| 1 | 1, 2, 5 | `quick` + `shell-scripting` |
| 2 | 3, 4 | `unspecified-low` + `shell-scripting` |
| 3 | 6 | `quick` |

---

## TODOs

- [ ] 1. Add new command-line flag parsing for README generation

  **What to do**:
  - Add `GENERATE_README=false` to the Options section
  - Add case handling in `parse_args()` for `-g, --generate-readme`
  - Follow existing pattern from other flags (lines 77-103)

  **Must NOT do**:
  - Change existing flag behaviors
  - Remove existing flags
  - Change flag short forms

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: `shell-scripting` (for style guide compliance)

  **Parallelization**:
  - **Can Run In Parallel**: NO (sequential)
  - **Blocked By**: None

  **References**:
  - Pattern: Lines 77-103 in `scripts/manifest.sh` (existing parse_args function)
  - Style: `references/style-guide.md` (Google Shell Style Guide)

  **Acceptance Criteria**:
  - [ ] `./scripts/manifest.sh -h` shows new `-g, --generate-readme` flag
  - [ ] `./scripts/manifest.sh -g` sets the flag (doesn't need to work yet)
  - [ ] `./scripts/manifest.sh -g -d -w` works with combined flags

  **Agent-Executed QA Scenario**:
  ```bash
  Scenario: Help shows new flag
    Tool: Bash
    Steps:
      1. Run: ./scripts/manifest.sh -h | grep -E "generate|readme"
      2. Assert: Output contains "generate-readme" or similar
    Expected Result: Help text includes the new flag
  ```

  **Commit**: NO (group with Task 5)

---

- [ ] 2. Implement gomplate availability check

  **What to do**:
  - Add `check_gomplate()` function that verifies gomplate is installed
  - If not found, offer to install or print helpful error
  - Store gomplate version or path for later use

  **Must NOT do**:
  - Force installation (ask or just warn)
  - Use sudo without explicit user consent
  - Assume gomplate is in a specific path

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: `shell-scripting`

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Blocked By**: None
  - **Blocks**: Task 3, Task 4

  **References**:
  - Pattern: `err()` function (lines 30-33) for error handling
  - Install pattern: Lines 16-22 in action.yaml (GOMPLATE_VERSION, curl, chmod)

  **Acceptance Criteria**:
  - [ ] Function checks if gomplate command exists
  - [ ] Returns success if gomplate available
  - [ ] Returns error with helpful message if not available (includes install instructions)

  **Agent-Executed QA Scenario**:
  ```bash
  Scenario: Gomplate check works
    Tool: Bash
    Steps:
      1. Ensure gomplate is installed: which gomplate || echo "Need gomplate"
      2. Run: source scripts/manifest.sh && check_gomplate
      3. Assert: Returns 0 when gomplate exists
    Expected Result: Check passes when gomplate installed
  ```

  **Commit**: NO (group with other tasks)

---

- [ ] 3. Implement root README.md generation function with automatic env vars

  **What to do**:
  - Add `generate_root_readme()` function
  - **Derive environment variables INSIDE the script** (no external setup needed):
    - `REPOSITORY`: Parse from `git remote get-url origin`
      - Example: `git@github.com:rigerc/home-assistant-addons.git` → `rigerc/home-assistant-addons`
      - Example: `https://github.com/rigerc/home-assistant-addons` → `rigerc/home-assistant-addons`
    - `REPOSITORY_URL`: Construct from REPOSITORY
      - Pattern: `https://github.com/${REPOSITORY}`
    - `AUTHOR_NAME`: Extract first part of REPOSITORY (e.g., "rigerc" from "rigerc/home-assistant-addons")
      - Fallback: `git config user.name` or default "rig"
    - `ADDONS_DATA`: Read entire content of manifest.json using jq or cat
      - Must be JSON array as string: `$(jq -c '.' manifest.json)`
  - Uses gomplate with `.README.tmpl` → `README.md`
  - Export all vars before calling gomplate

  **Must NOT do**:
  - Require user to set environment variables manually
  - Hardcode repository values
  - Modify the template file
  - Generate if manifest.json doesn't exist

  **Recommended Agent Profile**:
  - **Category**: `unspecified-low`
  - **Skills**: `shell-scripting`
  - **Rationale**: Needs careful handling of environment variables and git detection

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Blocked By**: Task 2 (gomplate check)
  - **Blocks**: Task 4

  **References**:
  - Pattern: `extract_addon_info()` (lines 114-181) for YAML parsing with yq
  - Template usage: Lines 50-53 in action.yaml (gomplate --file=.README.tmpl --out=README.md)
  - Environment setup: Lines 45-49 in action.yaml (REPOSITORY, REPOSITORY_URL, etc.)
  - Constants pattern: Lines 12-23 (SCRIPT_DIR, PROJECT_ROOT, etc.)

  **Acceptance Criteria**:
  - [ ] Function generates root README.md from .README.tmpl
  - [ ] **Automatically derives all environment variables** using git commands (no manual setup needed)
  - [ ] Handles both SSH and HTTPS git remote URLs
  - [ ] Has sensible fallback defaults if git remote unavailable
  - [ ] Handles missing manifest.json gracefully
  - [ ] Outputs success message when complete

  **Agent-Executed QA Scenario**:
  ```bash
  Scenario: Generate root README with auto-derived env vars
    Tool: Bash
    Preconditions: manifest.json exists, in git repo
    Steps:
      1. Verify git remote: git remote get-url origin
      2. Backup: cp README.md README.md.bak
      3. Run: source scripts/manifest.sh && generate_root_readme
      4. Verify: cat README.md | grep "Home Assistant Add-ons"
      5. Verify: cat README.md | grep "Available Add-ons"
      6. Verify: README contains correct repo URL (matches git remote)
      7. Restore: mv README.md.bak README.md
    Expected Result: README.md generated with correct repository info from git
    Evidence: Content verification output showing correct repo paths
  ```

  **Agent-Executed QA Scenario (env var derivation)**:
  ```bash
  Scenario: Environment variables auto-derived correctly
    Tool: Bash
    Preconditions: In git repo with origin remote
    Steps:
      1. Run: source scripts/manifest.sh && setup_gomplate_env
      2. Verify: echo "REPOSITORY=${REPOSITORY}" matches git remote
      3. Verify: echo "REPOSITORY_URL=${REPOSITORY_URL}" contains github.com
      4. Verify: echo "AUTHOR_NAME=${AUTHOR_NAME}" equals repo owner
      5. Verify: echo "ADDONS_DATA" contains JSON array
    Expected Result: All env vars correctly set from git and manifest.json
    Evidence: Env var values displayed and verified
  ```

  **Commit**: NO (group with Task 4)

---

- [ ] 4. Implement individual addon README generation function

  **What to do**:
  - Add `generate_addon_readmes()` function
  - Optionally accept specific addon slugs as arguments (for selective generation)
  - Iterates through manifest.json or uses provided slugs
  - For each addon:
    - Sets `ADDON_SLUG` environment variable
    - Uses gomplate with `.README_ADDON.tmpl` → `{slug}/README.md`
  - Skips if addon directory doesn't exist

  **Must NOT do**:
  - Generate for non-existent addons
  - Overwrite without confirming (just do it - it's version controlled)
  - Modify template files

  **Recommended Agent Profile**:
  - **Category**: `unspecified-low`
  - **Skills**: `shell-scripting`
  - **Rationale**: Similar complexity to root README, needs iteration logic

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Blocked By**: Task 3 (pattern established)
  - **Blocks**: None

  **References**:
  - Pattern: `create_release_drafter_configs()` (lines 423-465) for iteration over slugs
  - Template usage: Lines 55-61 in action.yaml (loop with ADDON_SLUG export)
  - Slug handling: Lines 55-61 in action.yaml

  **Acceptance Criteria**:
  - [ ] Function generates README for each addon in manifest.json
  - [ ] Sets ADDON_SLUG environment variable before each gomplate call
  - [ ] Accepts optional list of specific slugs to generate (for selective updates)
  - [ ] Outputs progress messages (like "Generating README for {addon}")

  **Agent-Executed QA Scenario**:
  ```bash
  Scenario: Generate all addon READMEs
    Tool: Bash
    Preconditions: manifest.json exists with addons
    Steps:
      1. List current addon READMEs: ls */README.md
      2. Run: source scripts/manifest.sh && generate_addon_readmes
      3. Verify: ls */README.md shows files exist
      4. Sample: cat romm/README.md | grep -E "Romm|Documentation"
    Expected Result: All addon READMEs generated with proper content
    Evidence: File listing and content excerpt
  ```

  **Agent-Executed QA Scenario (selective)**:
  ```bash
  Scenario: Generate specific addon README
    Tool: Bash
    Steps:
      1. Run: source scripts/manifest.sh && generate_addon_readmes "romm"
      2. Verify: Only romm/README.md was regenerated
    Expected Result: Can target specific addons
  ```

  **Commit**: YES (with Task 3)
  - Message: `feat(manifest): add README generation functions`
  - Files: `scripts/manifest.sh`

---

- [ ] 5. Update usage documentation and help text

  **What to do**:
  - Update `usage()` function to document `-g, --generate-readme` flag
  - Add examples showing how to use the new flag
  - Update script header comment if needed

  **Must NOT do**:
  - Remove existing documentation
  - Change existing examples
  - Use confusing language

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: `shell-scripting`

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 1-4)
  - **Blocked By**: None
  - **Depends On**: Task 1 (to know flag name)

  **References**:
  - Pattern: Lines 44-64 in manifest.sh (existing usage function)
  - Header comment: Lines 1-8

  **Acceptance Criteria**:
  - [ ] Help text shows `-g, --generate-readme` option
  - [ ] Help text includes description of what it does
  - [ ] Help text shows example: `-d -w -r -g` for "update all configs and generate READMEs"

  **Agent-Executed QA Scenario**:
  ```bash
  Scenario: Updated help is accurate
    Tool: Bash
    Steps:
      1. Run: ./scripts/manifest.sh -h
      2. Assert: Output contains "generate-readme"
      3. Assert: Output contains "README.md"
      4. Assert: Example line shows combined flags
    Expected Result: Help is accurate and complete
  ```

  **Commit**: NO (group with Task 1)

---

- [ ] 6. Integrate into main function and test end-to-end

  **What to do**:
  - Add call to `check_gomplate()` if flag is set
  - Add call to `generate_root_readme()` if flag is set
    - This function will auto-derive all environment variables internally
  - Add call to `generate_addon_readmes()` if flag is set
    - This function will set ADDON_SLUG internally for each addon
  - Handle the case where manifest.json doesn't exist yet (generate it first)

  **Must NOT do**:
  - Break existing flag combinations
  - Change execution order of existing features
  - Generate READMEs if manifest generation fails
  - Require external environment variable setup (all handled inside functions)

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: `shell-scripting`

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Blocked By**: Tasks 1-5
  - **Blocks**: None (final task)

  **References**:
  - Pattern: `main()` function (lines 478-506)
  - Integration pattern: Lines 485-503 (existing conditional calls)

  **Acceptance Criteria**:
  - [ ] `./scripts/manifest.sh -g` generates all READMEs
  - [ ] `./scripts/manifest.sh -g -d` generates READMEs and updates dependabot
  - [ ] All flags work in combination
  - [ ] Script exits with error if gomplate not available
  - [ ] Script generates manifest first if needed

  **Agent-Executed QA Scenario (Full test)**:
  ```bash
  Scenario: Complete README generation workflow
    Tool: Bash
    Preconditions: In project root, manifest.json may or may not exist
    Steps:
      1. Ensure gomplate installed: gomplate --version
      2. Run: ./scripts/manifest.sh -g
      3. Verify: manifest.json was generated/updated
      4. Verify: README.md was generated with content
      5. Verify: Each addon has README.md
      6. Verify: All READMEs contain expected sections
    Expected Result: Complete workflow succeeds
    Evidence: All file contents verified
  ```

  **Commit**: YES
  - Message: `feat(manifest): integrate README generation into main`
  - Files: `scripts/manifest.sh`

---

## Commit Strategy

| After Task | Message | Files | Verification |
|------------|---------|-------|--------------|
| 1, 5 | `feat(manifest): add --generate-readme flag and docs` | `scripts/manifest.sh` | `./scripts/manifest.sh -h \| grep generate` |
| 3, 4 | `feat(manifest): implement README generation functions` | `scripts/manifest.sh` | `./scripts/manifest.sh -g` generates files |
| 6 | `feat(manifest): integrate README generation into main flow` | `scripts/manifest.sh` | `./scripts/manifest.sh -d -w -r -g` works |

---

## Success Criteria

### Verification Commands
```bash
# Test help documentation
./scripts/manifest.sh -h | grep -E "generate|readme"

# Test single flag
./scripts/manifest.sh -g
cat README.md | head -20

# Test combined flags
./scripts/manifest.sh -d -w -r -g

# Verify all addons have READMEs
ls */README.md
```

### Final Checklist
- [ ] All "Must Have" features implemented
- [ ] All "Must NOT Have" guardrails respected
- [ ] Help documentation updated
- [ ] Script passes shellcheck: `shellcheck scripts/manifest.sh`
- [ ] End-to-end test successful

---

## Appendix: Implementation Notes

### Environment Variables for gomplate
The templates expect these environment variables:

**Root template (.README.tmpl):**
- `REPOSITORY` - GitHub repo path (e.g., "rigerc/home-assistant-addons")
- `REPOSITORY_URL` - Full URL (e.g., "https://github.com/rigerc/home-assistant-addons")
- `AUTHOR_NAME` - Repo owner (e.g., "rig")
- `ADDONS_DATA` - JSON array from manifest.json

**Addon template (.README_ADDON.tmpl):**
- All of the above PLUS:
- `ADDON_SLUG` - Specific addon being generated

### Deriving Environment Variables Inside the Script

**Implementation approach for generating env vars:**

```bash
# 1. Get git remote URL and parse it
get_repo_info() {
  local remote_url
  remote_url="$(git remote get-url origin 2>/dev/null || echo "")"
  
  # Parse different URL formats:
  # SSH: git@github.com:owner/repo.git → owner/repo
  # HTTPS: https://github.com/owner/repo → owner/repo
  # HTTPS with .git: https://github.com/owner/repo.git → owner/repo
  
  local repo_path="${remote_url}"
  repo_path="${repo_path#git@github.com:}"     # Remove SSH prefix
  repo_path="${repo_path#https://github.com/}" # Remove HTTPS prefix
  repo_path="${repo_path%.git}"               # Remove .git suffix
  
  echo "${repo_path}"
}

# 2. Set up all environment variables for gomplate
setup_gomplate_env() {
  local repo_slug
  repo_slug="$(get_repo_info)"
  
  # Fallback if git remote not available
  if [[ -z "${repo_slug}" ]]; then
    repo_slug="rigerc/home-assistant-addons"  # Default fallback
  fi
  
  export REPOSITORY="${repo_slug}"
  export REPOSITORY_URL="https://github.com/${repo_slug}"
  export AUTHOR_NAME="${repo_slug%%/*}"  # Extract owner (before first /)
  export ADDONS_DATA="$(jq -c '.' "${MANIFEST_OUTPUT}")"
}
```

**Example output of the derivation:**
```bash
$ git remote get-url origin
git@github.com:rigerc/home-assistant-addons.git

$ get_repo_info
rigerc/home-assistant-addons

$ echo "${REPOSITORY}"
# rigerc/home-assistant-addons

$ echo "${AUTHOR_NAME}"
# rigerc
```

### Gomplate Installation Pattern (from action.yaml)
```bash
GOMPLATE_VERSION="${GOMPLATE_VERSION:-v4.3.0}"
curl -o /usr/local/bin/gomplate -sSL "https://github.com/hairyhenderson/gomplate/releases/download/${GOMPLATE_VERSION}/gomplate_linux-amd64"
chmod +x /usr/local/bin/gomplate
```

For local script, we should:
1. Check if gomplate exists
2. If not, suggest installation or auto-install to a local bin directory
3. Use local gomplate if available, system if available

### Manifest.json Structure
```json
[
  {
    "slug": "romm",
    "version": "0.1.26",
    "name": "Romm",
    "description": "Self-hosted ROM collection manager...",
    "arch": ["aarch64", "amd64"],
    "image": "ghcr.io/rigerc/home-assistant-addons/romm",
    "tag": "latest",
    "project": "https://github.com/rommapp/romm"
  }
]
```

This structure is used by both templates via the `ADDONS_DATA` environment variable.
