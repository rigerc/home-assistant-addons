# GitHub CLI Command Reference

Complete reference for GitHub CLI command structure and navigation.

## Command Structure

GitHub CLI follows a hierarchical command structure:

```
gh [GLOBAL_OPTIONS] COMMAND [COMMAND_OPTIONS] [SUBCOMMAND] [SUBCOMMAND_OPTIONS] [ARGUMENTS]
```

### Example Breakdown

```bash
gh --help                    # Top-level help
gh issue --help              # Command help
gh issue create --help       # Subcommand help
gh issue create --title "X"  # Full command with options
```

## Global Options

Options available for all `gh` commands:

| Option | Description |
|--------|-------------|
| `--help` | Show help for the current command |
| `--version` | Display GitHub CLI version |
| `--hostname HOST` | Override default GitHub host |
| `--verbose` | Enable verbose output |

## Top-Level Commands

View all available commands:

```bash
gh
```

### Core Commands

| Command | Description |
|---------|-------------|
| `auth` | Authenticate with GitHub accounts |
| `issue` | Manage issues |
| `pr` | Manage pull requests |
| `repo` | Manage repositories |
| `codespace` | Manage codespaces |
| `release` | Manage releases |
| `run` | View and workflow GitHub Actions runs |
| `workflow` | View GitHub Actions workflows |
| `extension` | Manage extensions |
| `alias` | Create command aliases |
| `config` | Configure GitHub CLI settings |
| `api` | Make API requests |
| `search` | Search for issues, PRs, repositories |
| `status` | View status across repositories |
| `environment` | View environment variables |
| `completion` | Generate shell completion scripts |
| `help` | View help (same as `--help`) |
| `format` | Format help output |

## Authentication Commands

### `gh auth`

```bash
# Login
gh auth login [flags]

# Logout
gh auth logout [hostname]

# Status
gh auth status

# Switch accounts (same platform)
gh auth switch
```

#### auth login flags

| Flag | Description |
|------|-------------|
| `--hostname` | GitHub hostname (default: github.com) |
| `--web` | Authenticate with web browser |
| `--with-token` | Read token from standard input |

#### auth logout flags

| Flag | Description |
|------|-------------|
| `--hostname` | Specific host to logout from |

#### auth switch

No flags available. Interactive selection menu.

## Issue Commands

### `gh issue`

```bash
# List issues
gh issue list [flags]

# View issue
gh issue view {issue-number} [flags]

# Create issue
gh issue create [flags]

# Edit issue
gh issue edit {issue-number} [flags]

# Close issue
gh issue close {issue-number} [flags]

# Reopen issue
gh issue reopen {issue-number} [flags]

# Lock issue conversation
gh issue lock {issue-number} [flags]

# Unlock issue conversation
gh issue unlock {issue-number} [flags]

# Add comment
gh issue comment {issue-number} [flags]

# Transfer issue
gh issue transfer {issue-number} {new-repo} [flags]

# Subscribe to issue
gh issue pin {issue-number} [flags]
```

#### Common issue list flags

| Flag | Description |
|------|-------------|
| `--limit` | Maximum number of items |
| `--state` | Filter by state (open, closed, all) |
| `--assignee` | Filter by assignee |
| `--author` | Filter by author |
| `--label` | Filter by label(s) |
| `--search` | Search query |
| `--json` | Output JSON with specified fields |
| `--jq` | Filter JSON output |
| `--web` | Open in browser |

#### issue create flags

| Flag | Description |
|------|-------------|
| `--title` | Issue title |
| `--body` | Issue body/description |
| `--assignee` | Assign to user |
| `--label` | Add label(s) |
| `--milestone` | Add to milestone |
| `--project` | Add to project |
| `--repo` | Repository (OWNER/REPO) |

## Pull Request Commands

### `gh pr`

```bash
# List PRs
gh pr list [flags]

# View PR
gh pr view {pr-number} [flags]

# Create PR
gh pr create [flags]

# Checkout PR
gh pr checkout {pr-number} [flags]

# Diff PR
gh pr diff {pr-number} [flags]

# Merge PR
gh pr merge {pr-number} [flags]

# Close PR
gh pr close {pr-number} [flags]

# Reopen PR
gh pr reopen {pr-number} [flags]

# Review PR
gh pr review {pr-number} [flags]

# Add comment
gh pr comment {pr-number} [flags]

# Checks status
gh pr checks {pr-number} [flags]

# Ready for review
gh pr ready {pr-number} [flags]

# Convert to draft
gh pr draft {pr-number} [flags]
```

#### Common pr list flags

Same as issue list flags, plus:

| Flag | Description |
|------|-------------|
| `--base` | Filter by base branch |
| `--head` | Filter by head branch |

#### pr create flags

| Flag | Description |
|------|-------------|
| `--title` | PR title |
| `--body` | PR description |
| `--base` | Base branch |
| `--head` | Head branch |
| `--draft` | Create as draft |
| `--reviewer` | Request review from |
| `--assignee` | Assign to |
| `--label` | Add label(s) |
| `--milestone` | Add to milestone |
| `--project` | Add to project |

#### pr merge flags

| Flag | Description |
|------|-------------|
| `--squash` | Merge with squash commit |
| `--merge` | Merge with merge commit |
| `--rebase` | Merge by rebasing |
| `--subject` | Commit subject (squash) |
| `--body` | Commit body (squash) |
| `--delete-branch` | Delete branch after merge |

## Repository Commands

### `gh repo`

```bash
# List repositories
gh repo list [flags]

# View repository
gh repo view [repository] [flags]

# Create repository
gh repo create [name] [flags]

# Clone repository
gh repo clone {repository} [dir]

# Delete repository
gh repo delete {repository} [flags]

# Fork repository
gh repo fork {repository} [flags]

# Archive repository
gh repo archive {repository} [flags]

# View README
gh repo view --json readmeBody --jq .readmeBody
```

#### repo create flags

| Flag | Description |
|------|-------------|
| `--public` | Public repository |
| `--private` | Private repository |
| `--source` | Source path |
| `--remote` | Remote name |
| `--push` | Push after creation |
| `--description` | Repository description |
| `--clone` | Clone after creation |

## Codespace Commands

### `gh codespace` (or `gh cs`)

```bash
# List codespaces
gh codespace list [flags]

# Create codespace
gh codespace create [flags]

# Start codespace
gh codespace start {codespace} [flags]

# Stop codespace
gh codespace stop {codespace} [flags]

# Delete codespace
gh codespace delete {codespace} [flags]

# Open in VS Code
gh codespace code {codespace} [flags]

# SSH into codespace
gh codespace ssh {codespace} [flags]

# View logs
gh codespace logs {codespace} [flags]
```

#### codespace create flags

| Flag | Description |
|------|-------------|
| `--repo` | Repository (OWNER/REPO) |
| `--branch` | Branch name |
| `--machine` | Machine type |

#### codespace code flags

| Flag | Description |
|------|-------------|
| `--web` | Open in browser |
| `--insiders` | Use VS Code Insiders |

## Extension Commands

### `gh extension`

```bash
# List extensions
gh extension list

# Install extension
gh extension install {repository|path}

# Upgrade extension
gh extension upgrade {extension} [flags]

# Remove extension
gh extension remove {extension}

# Create extension
gh extension create {name} [flags]
```

#### extension install

Accepts:
- Full URL: `https://github.com/owner/gh-extension`
- Owner/repo: `owner/gh-extension`
- Local path: `.` (current directory)

#### extension upgrade flags

| Flag | Description |
|------|-------------|
| `--all` | Upgrade all extensions |

## Alias Commands

### `gh alias`

```bash
# View aliases
gh alias list

# Create alias
gh alias set {alias} {expansion}

# Delete alias
gh alias delete {alias}
```

#### Aliases Examples

```bash
gh alias set prd "pr create --draft"
gh alias set ils "issue list --assignee @me"
gh alias set rv "repo view --web"
```

## Configuration Commands

### `gh config`

```bash
# View configuration
gh config get {key}

# Set configuration
gh config set {key} {value}

# List all configuration
gh config list

# Remove configuration
gh config unset {key}
```

#### Common Config Keys

| Key | Description | Example |
|-----|-------------|---------|
| `editor` | Text editor | `"code -w"`, `"vim"` |
| `git_protocol` | Git protocol | `"ssh"`, `"https"` |
| `browser` | Browser for `--web` | `"chrome"`, `"firefox"` |
| `prompt` | Enable/disable prompts | `"enabled"`, `"disabled"` |

#### Host-Specific Configuration

```bash
gh config set --host github.com editor "code -w"
gh config set --host github.enterprise.com git_protocol ssh
```

## API Commands

### `gh api`

```bash
# GET request
gh api {endpoint} [flags]

# POST request
gh api {endpoint} --method POST [flags]

# PUT request
gh api {endpoint} --method PUT [flags]

# DELETE request
gh api {endpoint} --method DELETE [flags]

# PATCH request
gh api {endpoint} --method PATCH [flags]
```

#### api flags

| Flag | Description |
|------|-------------|
| `--method` | HTTP method (GET, POST, PUT, DELETE, PATCH) |
| `--hostname` | Override hostname |
| `--header` | Add header (`-H` also works) |
| `--field` | Add form field (`-f` also works) |
| `--input` | Read body from file |
| `--jq` | Filter JSON output |
| `--paginate` | Paginate through all results |
| `--silent` | Suppress output |
| `--verbose` | Show HTTP request/response |

#### API Examples

```bash
# Get user info
gh api user

# Create issue
gh api /repos/OWNER/REPO/issues -f title='Bug' -f body='Description'

# Get with JSON filter
gh api user --jq '.login'

# Custom headers
gh api /user/starred/OWNER/REPO --method PUT

# Paginated results
gh api /user/repos --paginate
```

## Search Commands

### `gh search`

```bash
# Search repositories
gh search repos {query} [flags]

# Search issues
gh search issues {query} [flags]

# Search pull requests
gh search prs {query} [flags]

# Search code
gh search code {query} [flags]
```

#### search flags

| Flag | Description |
|------|-------------|
| `--owner` | Limit to owner/organization |
| `--limit` | Maximum results |
| `--json` | Output JSON with fields |
| `--jq` | Filter JSON output |
| `--web` | Open in browser |

## Release Commands

### `gh release`

```bash
# List releases
gh release list [flags]

# View release
gh release view {tag} [flags]

# Create release
gh release create {tag} [flags]

# Delete release
gh release delete {tag} [flags]

# Download release assets
gh release download {tag} [flags]
```

## Help System

### `gh help` / `--help`

```bash
# Top-level help
gh --help
gh help

# Command help
gh issue --help
gh help issue

# Subcommand help
gh issue create --help
gh help issue create

# Formatting help
gh help formatting
```

### `gh format`

View help output formatting options:

```bash
gh format
```

Shows how to use JSON output with `--json` and `--jq` flags.

## Environment Variables

### `gh environment`

View all environment variables affecting GitHub CLI:

```bash
gh environment
```

### Available Environment Variables

| Variable | Description |
|----------|-------------|
| `GH_TOKEN` | Authentication token |
| `GH_HOST` | Default GitHub hostname |
| `GH_ENTERPRISE_TOKEN` | Enterprise token (deprecated) |
| `GH_EDITOR` | Text editor |
| `GH_BROWSER` | Browser for `--web` |
| `GH_PROMPT_DISABLED` | Disable prompts (true/false) |
| `GH_NO_UPDATE_NOTIFIER` | Disable update checks (true/false) |
| `GH_DEBUG` | Enable debug output (true/false) |
| `GH_CONFIG_DIR` | Configuration directory |
| `GH_DATA_DIR` | Data directory |

## Completion

### Generate Shell Completions

```bash
# Bash
gh completion -s bash > /etc/bash_completion.d/gh

# Zsh
gh completion -s zsh > /usr/local/share/zsh/site-functions/_gh

# Fish
gh completion -s fish > ~/.config/fish/completions/gh.fish
```

## Getting Help Online

For complete command reference, visit:
- [GitHub CLI Manual](https://cli.github.com/manual/gh)
- [GitHub CLI Documentation](https://docs.github.com/en/github-cli)

## Command Discovery

Explore available commands:

```bash
# Top-level commands
gh

# Command subcommands
gh COMMAND

# Flags for subcommand
gh COMMAND SUBCOMMAND --help
```
