---
description: Retrieve documentation for a GitHub Action from its repository
---

# GitHub Action Documentation

Fetches and displays documentation for a GitHub Action by retrieving its README.md and action.yml from the action's repository.

## Usage

```bash
/github-action-docs <action_reference>
```

### Action Reference Formats

- `actions/checkout` - fetch from default branch
- `actions/checkout@v4` - fetch from specific tag
- `owner/repo@tag` - custom action with specific version
- `owner/repo` - custom action from default branch

## Examples

```bash
/github-action-docs actions/checkout
/github-action-docs actions/checkout@v4
/github-action-docs aws-actions/configure-aws-credentials@v4
/github-action-docs my-org/my-custom-action@v1.0.0
```

---

Please retrieve the GitHub Action documentation specified below.

## Action Reference

{{ action_reference }}

---

Use the GitHub MCP tools to fetch the documentation:

1. **Parse the action reference** to extract `owner` and `repo`:
   - Format: `{owner}/{repo}[@{tag}]`
   - Example: `actions/checkout@v4` → owner=`actions`, repo=`checkout`, tag=`v4`

2. **Determine the ref to use**:
   - If a tag/version is specified (e.g., `@v4`), use that as the ref
   - If no tag is specified, use the default branch (try `main` first, then `master`)

3. **Fetch the documentation files** using `mcp__github__get_file_contents`:
   - **README.md** - Main documentation
   - **action.yml** - Action definition with inputs, outputs, and usage

4. **Display the results**:
   - Show the README.md content first (as markdown)
   - Then show the action.yml content (as code)
   - Include links to the GitHub repository for more details

### Tool Usage

```json
{
  "tool": "mcp__github__get_file_contents",
  "parameters": {
    "owner": "<owner>",
    "repo": "<repo>",
    "path": "README.md",
    "ref": "<tag_or_default_branch>"
  }
}
```

If the first attempt fails (e.g., wrong default branch), try with an alternative branch or without the ref parameter.

Begin by parsing the action reference and fetching the documentation.
