# GitHub CLI Quickstart Reference

Get started quickly with the most common GitHub CLI commands.

## Installation

GitHub CLI is available for Linux, macOS, and Windows. Visit the [official documentation](https://cli.github.com/manual/installation) for platform-specific installation instructions.

Verify installation:

```bash
gh --version
```

## Authentication Flow

### Initial Authentication

```bash
gh auth login
```

The interactive prompt guides through:
1. **Account**: GitHub.com or GitHub Enterprise
2. **Protocol**: HTTPS or SSH
3. **Credentials**: Browser login or personal access token

### Authentication Status

Check current authentication:

```bash
gh auth status
```

### Logout

Remove credentials:

```bash
gh auth logout
```

## Repository Commands

### View Repository

```bash
# View in terminal
gh repo view OWNER/REPO

# View in browser
gh repo view OWNER/REPO --web

# Omit OWNER/REPO when inside a cloned repository
gh repo view
```

### Clone Repository

```bash
gh repo clone OWNER/REPO
gh repo clone octocat/hello-world
```

### Create Repository

```bash
# Interactive creation
gh repo create

# Create with specific options
gh repo create my-repo --public --source=. --remote=origin --push
```

### List Repositories

```bash
# List your repositories
gh repo list

# List organization repositories
gh repo list ORG-NAME

# Limit results
gh repo list --limit 10
```

## Issue Commands

### List Issues

```bash
# Basic list
gh issue list --repo OWNER/REPO

# Filter by assignee
gh issue list --assignee "@me"

# Filter by author
gh issue list --author monalisa

# Filter by state (default: open)
gh issue list --state closed

# Filter by labels
gh issue list --label bug,urgent

# Combine filters
gh issue list --assignee "@me" --label bug --state open
```

### Create Issue

```bash
# Interactive
gh issue create

# Non-interactive with title and body
gh issue create --title "Bug found" --body "Description here"

# With assignee
gh issue create --title "Fix bug" --assignee "@me"

# With labels
gh issue create --title "Feature" --label enhancement,good-first-issue

# In specific repository
gh issue create --repo OWNER/REPO --title "Issue"
```

### View Issue

```bash
gh issue view ISSUE-NUMBER
gh issue view 123 --repo OWNER/REPO
```

### Update Issue

```bash
# Add comment
gh issue comment 123 --body "This is a comment"

# Close issue
gh issue close 123

# Reopen issue
gh issue reopen 123

# Edit issue
gh issue edit 123 --title "New title"
```

### Search Issues

```bash
gh search issues --author "@me" --state open
gh search issues --label bug --repo OWNER/REPO
```

## Pull Request Commands

### List Pull Requests

```bash
# Basic list
gh pr list --repo OWNER/REPO

# Your PRs
gh pr list --author "@me"

# By label
gh pr list --label bug

# By state
gh pr list --state merged
gh pr list --state closed

# PRs awaiting your review
gh search prs --review-requested=@me --state=open
```

### Create Pull Request

```bash
# Interactive
gh pr create

# Draft PR
gh pr create --draft

# With title and body
gh pr create --title "Add feature" --body "Description"

# With base branch
gh pr create --base main --head feature-branch

# With assignee for review
gh pr create --reviewer monalisa

# With labels
gh pr create --label bug,high-priority
```

### View Pull Request

```bash
gh pr view PR-NUMBER
gh pr view 42 --web  # Open in browser
```

### Checkout Pull Request

```bash
gh pr checkout PR-NUMBER
gh pr checkout 42
```

### Update Pull Request

```bash
# Add comment
gh pr comment 42 --body "Looks good!"

# Request review
gh pr review 42 --approve
gh pr review 42 --request-changes --body "Changes needed"

# Merge PR
gh pr merge 42 --squash
gh pr merge 42 --merge
gh pr merge 42 --rebase

# Close PR
gh pr close 42
```

### Diff and Checks

```bash
# View diff
gh pr diff 42

# View checks status
gh pr checks 42
```

## Codespace Commands

The `cs` shorthand can substitute `codespace` in all commands.

### List Codespaces

```bash
gh codespace list
gh cs list
```

### Create Codespace

```bash
# Interactive
gh codespace create

# For specific repository
gh codespace create --repo OWNER/REPO

# With specific branch
gh codespace create --repo OWNER/REPO --branch feature-branch
```

### Open Codespace

```bash
# Open in VS Code
gh codespace code

# Open in browser
gh codespace code -w
```

### Delete Codespace

```bash
gh codespace delete CODESPACE-NAME
```

## Status Commands

### View Your Activity

```bash
gh status
```

Displays your current work across all subscribed repositories, including issues, pull requests, and review requests.

## Configuration Commands

### Set Configuration

```bash
# Set editor
gh config set editor "code -w"
gh config set editor vim

# Set Git protocol preference
gh config set git_protocol ssh

# Set default browser for --web flags
gh config set browser chromium
```

### View Configuration

```bash
gh config set
gh config set editor
gh config get editor
```

### Aliases

```bash
# Create alias
gh alias set prd "pr create --draft"
gh alias set ils "issue list --assignee @me"

# List aliases
gh alias list

# Delete alias
gh alias delete prd
```

## API Commands

### Basic API Access

```bash
# Get user info
gh api user

# Get repository info
gh api repos/octocat/hello-world

# List repositories
gh api /user/repos

# Paginated results
gh api /user/repos --paginate
```

### POST Requests

```bash
# Create issue via API
gh api /repos/OWNER/REPO/issues \
  --method POST \
  -f title='New issue' \
  -f body='Issue description'
```

### JSON Processing

```bash
# Extract specific field
gh api user --jq '.login'

# Filter array
gh api /user/repos --jq '.[].name'

# Complex query
gh api /user/repos --jq '.[] | select(.fork | not) | .name'
```

## Getting Help

### Built-in Help

```bash
# Top-level help
gh --help
gh

# Command help
gh issue --help
gh pr --help
gh repo --help

# Subcommand help
gh issue create --help
gh pr merge --help
```

### Environment Variables

View environment variables affecting GitHub CLI:

```bash
gh environment
```

Common environment variables:
- `GH_TOKEN` - Authentication token
- `GH_HOST` - GitHub hostname (default: github.com)
- `GH_EDITOR` - Text editor for multi-step commands
- `GH_BROWSER` - Browser for `--web` flags

## Tips and Tricks

### Context Awareness

When inside a cloned repository, omit `--repo OWNER/REPO`:

```bash
cd my-repo
gh issue list      # Automatically uses current repo
gh pr view 42      # Automatically uses current repo
```

### Combining with Other Tools

```bash
# Open all PRs in browser
gh pr list --json url --jq '.[].url' | xargs open

# Count open issues
gh issue list --json number --jq 'length'

# Export to CSV
gh pr list --json number,title,state --jq '.[] | [.number, .title, .state] | @csv'
```

### Scripting Patterns

```bash
# Check if repo exists
if gh repo view OWNER/REPO &>/dev/null; then
  echo "Repository exists"
fi

# Get latest release
gh release view --json tagName --jq '.tagName'

# Find issue by title
gh issue list --search "title:Bug in login" --json number --jq '.[0].number'
```
