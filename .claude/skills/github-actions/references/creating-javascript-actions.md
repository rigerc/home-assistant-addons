# Creating JavaScript Actions

Build custom JavaScript actions to extend GitHub Actions functionality with Node.js. JavaScript actions run directly on the runner, execute faster than Docker actions, and work across all runner operating systems.

## When to Use JavaScript Actions

Choose JavaScript actions when you need:

- Cross-platform compatibility (Linux, macOS, Windows)
- Fast execution without container overhead
- Direct access to the runner filesystem
- Integration with npm ecosystem
- GitHub API interactions via Octokit

Avoid JavaScript actions if you require:

- Specific system dependencies or tools
- Consistent execution environment
- Non-Node.js runtime (use Docker actions instead)

## Project Setup

### Initialize the Repository

Create a new public repository for your action:

```bash
mkdir hello-world-javascript-action
cd hello-world-javascript-action
git init
npm init -y
```

### Install Dependencies

Install the Actions Toolkit packages:

```bash
npm install @actions/core @actions/github
```

The `@actions/core` package provides:
- Input/output variable handling
- Workflow commands
- Exit status management
- Logging functions

The `@actions/github` package provides:
- Authenticated Octokit REST client
- GitHub Actions context information
- Webhook event payload access

### Install Build Tools

Use a bundler to package your code and dependencies into a single distributable file:

```bash
npm install --save-dev rollup @rollup/plugin-commonjs @rollup/plugin-node-resolve
```

Alternative bundlers:
- `@vercel/ncc` - Zero-config TypeScript compiler
- `webpack` - Full-featured bundler
- `esbuild` - Extremely fast bundler

## Action Metadata

Create `action.yml` to define your action's interface:

```yaml
name: Hello World
description: Greet someone and record the time

inputs:
  who-to-greet:
    description: Who to greet
    required: true
    default: World

outputs:
  time:
    description: The time we greeted you

runs:
  using: node20
  main: dist/index.js
```

### Metadata Components

**name**: Action display name in GitHub Marketplace and workflow logs

**description**: Brief explanation of action functionality (max 125 characters)

**inputs**: Define required and optional parameters
- Use kebab-case for input names
- Set `required: true` for mandatory inputs
- Provide sensible defaults when possible
- Include clear descriptions

**outputs**: Define values the action produces
- Use kebab-case for output names
- Document what each output contains

**runs.using**: Specify Node.js version (`node20` recommended)
- Use latest LTS version when possible
- Avoid deprecated versions (node12, node16)

**runs.main**: Path to compiled entry point
- Point to bundled distribution file
- Use `dist/index.js` convention

## Writing Action Code

### Basic Structure

Create `src/index.js` with core action logic:

```javascript
import * as core from "@actions/core";
import * as github from "@actions/github";

try {
  // Get inputs
  const nameToGreet = core.getInput("who-to-greet");
  core.info(`Hello ${nameToGreet}!`);

  // Perform action logic
  const time = new Date().toTimeString();

  // Set outputs
  core.setOutput("time", time);

  // Access GitHub context
  const payload = JSON.stringify(github.context.payload, undefined, 2);
  core.info(`The event payload: ${payload}`);
} catch (error) {
  core.setFailed(error.message);
}
```

### Using @actions/core

**Reading Inputs**

```javascript
// Required input (fails if missing)
const username = core.getInput("username", { required: true });

// Optional input with default
const branch = core.getInput("branch") || "main";

// Multiline input as array
const files = core.getMultilineInput("files");

// Boolean input
const dryRun = core.getBooleanInput("dry-run");
```

**Setting Outputs**

```javascript
// Set single output
core.setOutput("result", "success");

// Set multiple outputs
core.setOutput("branch", "main");
core.setOutput("commit", "abc123");
core.setOutput("status", "deployed");
```

**Logging Functions**

```javascript
// Info messages (visible in workflow logs)
core.info("Starting deployment...");

// Debug messages (visible with debug logging enabled)
core.debug(`Processing file: ${filename}`);

// Warning messages (creates annotation)
core.warning("API rate limit approaching");

// Error messages (creates annotation)
core.error("Failed to connect to database");

// Notice messages (creates annotation)
core.notice("Deployment completed successfully");
```

**Grouping Log Output**

```javascript
core.startGroup("Running tests");
// Test execution code
core.info("Test 1 passed");
core.info("Test 2 passed");
core.endGroup();

// Or use async wrapper
await core.group("Building project", async () => {
  await buildProject();
});
```

**Setting Secret Values**

```javascript
// Mask sensitive values in logs
const apiKey = core.getInput("api-key");
core.setSecret(apiKey);
```

**Exporting Variables**

```javascript
// Make variable available to subsequent steps
core.exportVariable("DEPLOY_URL", deploymentUrl);
```

**Modifying PATH**

```javascript
// Add directory to system PATH
core.addPath("/usr/local/custom/bin");
```

### Using @actions/github

**Accessing Context**

```javascript
import { context } from "@actions/github";

// Repository information
console.log(context.repo.owner);
console.log(context.repo.repo);

// Event details
console.log(context.eventName);
console.log(context.sha);
console.log(context.ref);

// Actor who triggered workflow
console.log(context.actor);

// Webhook payload
const pullRequest = context.payload.pull_request;
const issue = context.payload.issue;
```

**Using Octokit Client**

```javascript
import { getOctokit } from "@actions/github";

const token = core.getInput("github-token");
const octokit = getOctokit(token);

// Create issue comment
await octokit.rest.issues.createComment({
  owner: context.repo.owner,
  repo: context.repo.repo,
  issue_number: context.issue.number,
  body: "Deployment completed successfully!"
});

// Get pull request files
const { data: files } = await octokit.rest.pulls.listFiles({
  owner: context.repo.owner,
  repo: context.repo.repo,
  pull_number: context.payload.pull_request.number
});

// Create check run
await octokit.rest.checks.create({
  owner: context.repo.owner,
  repo: context.repo.repo,
  name: "My Action Check",
  head_sha: context.sha,
  status: "completed",
  conclusion: "success"
});
```

## Error Handling

### Proper Error Handling

```javascript
try {
  const result = await riskyOperation();
  core.setOutput("result", result);
} catch (error) {
  // Set action as failed with error message
  core.setFailed(`Action failed: ${error.message}`);

  // Log stack trace for debugging
  core.debug(error.stack);
}
```

### Custom Exit Codes

```javascript
import { ExitCode } from "@actions/core";

// Exit with specific code
process.exitCode = ExitCode.Failure; // 1
process.exitCode = ExitCode.Success; // 0
```

### Validation Errors

```javascript
function validateInputs() {
  const email = core.getInput("email");
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  if (!emailRegex.test(email)) {
    throw new Error(`Invalid email format: ${email}`);
  }
}

try {
  validateInputs();
  // Continue with action logic
} catch (error) {
  core.setFailed(error.message);
}
```

## Complete Working Example

### Action Metadata (action.yml)

```yaml
name: Repository Report
description: Generate a report of repository statistics

inputs:
  github-token:
    description: GitHub token for API access
    required: true
  include-issues:
    description: Include issue statistics
    required: false
    default: 'true'

outputs:
  total-stars:
    description: Total repository stars
  total-issues:
    description: Total open issues
  report-file:
    description: Path to generated report

runs:
  using: node20
  main: dist/index.js
```

### Action Code (src/index.js)

```javascript
import * as core from "@actions/core";
import { getOctokit, context } from "@actions/github";
import { writeFileSync } from "fs";

async function generateReport() {
  try {
    // Get inputs
    const token = core.getInput("github-token", { required: true });
    const includeIssues = core.getBooleanInput("include-issues");

    // Initialize Octokit
    const octokit = getOctokit(token);

    core.startGroup("Fetching repository data");

    // Get repository information
    const { data: repo } = await octokit.rest.repos.get({
      owner: context.repo.owner,
      repo: context.repo.repo
    });

    core.info(`Repository: ${repo.full_name}`);
    core.info(`Stars: ${repo.stargazers_count}`);

    // Set outputs
    core.setOutput("total-stars", repo.stargazers_count);

    let report = `# Repository Report\n\n`;
    report += `**Repository:** ${repo.full_name}\n`;
    report += `**Stars:** ${repo.stargazers_count}\n`;
    report += `**Forks:** ${repo.forks_count}\n`;

    // Get issue statistics if requested
    if (includeIssues) {
      const { data: issues } = await octokit.rest.issues.listForRepo({
        owner: context.repo.owner,
        repo: context.repo.repo,
        state: "open",
        per_page: 1
      });

      const totalIssues = parseInt(
        octokit.rest.issues.listForRepo.endpoint.DEFAULTS.headers.link || "0"
      );

      core.info(`Open Issues: ${totalIssues}`);
      core.setOutput("total-issues", totalIssues);

      report += `**Open Issues:** ${totalIssues}\n`;
    }

    core.endGroup();

    // Write report to file
    const reportPath = "repository-report.md";
    writeFileSync(reportPath, report);
    core.setOutput("report-file", reportPath);

    core.notice("Report generated successfully!");

  } catch (error) {
    core.setFailed(`Action failed: ${error.message}`);
    core.debug(error.stack);
  }
}

generateReport();
```

### Build Configuration (rollup.config.js)

```javascript
import commonjs from "@rollup/plugin-commonjs";
import { nodeResolve } from "@rollup/plugin-node-resolve";

const config = {
  input: "src/index.js",
  output: {
    esModule: true,
    file: "dist/index.js",
    format: "es",
    sourcemap: true,
  },
  plugins: [
    commonjs(),
    nodeResolve({ preferBuiltins: true })
  ],
};

export default config;
```

### Package Configuration

Add build script to `package.json`:

```json
{
  "name": "repository-report-action",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "build": "rollup --config rollup.config.js"
  },
  "dependencies": {
    "@actions/core": "^1.10.1",
    "@actions/github": "^6.0.0"
  },
  "devDependencies": {
    "@rollup/plugin-commonjs": "^25.0.7",
    "@rollup/plugin-node-resolve": "^15.2.3",
    "rollup": "^4.9.6"
  }
}
```

## Building and Distribution

### Compile Your Action

```bash
npm run build
```

This creates `dist/index.js` containing your code and all dependencies.

### Ignore node_modules

Add to `.gitignore`:

```
node_modules/
```

Never commit `node_modules` to your repository. Always commit the compiled `dist/` directory.

### Git Workflow

```bash
# Add files
git add src/index.js dist/index.js rollup.config.js package.json package-lock.json action.yml

# Commit changes
git commit -m "Initial action implementation"

# Tag release
git tag -a -m "Release version 1.0" v1
git tag -a -m "Release version 1.0.0" v1.0.0

# Push with tags
git push --follow-tags
```

### Version Tags

Use semantic versioning with multiple tag levels:

- `v1` - Major version (auto-updated for v1.x.x releases)
- `v1.0` - Minor version (auto-updated for v1.0.x releases)
- `v1.0.0` - Exact version (immutable)

Users can reference:
```yaml
uses: owner/action@v1       # Gets latest v1.x.x
uses: owner/action@v1.0     # Gets latest v1.0.x
uses: owner/action@v1.0.0   # Gets exact version
```

## Testing Your Action

### Local Testing with act

Install [act](https://github.com/nektos/act) to run workflows locally:

```bash
# Install act
brew install act  # macOS
# or
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Run workflow locally
act push
```

### Testing in a Workflow (Public Action)

Create `.github/workflows/test.yml` in a test repository:

```yaml
on:
  push:
    branches:
      - main

jobs:
  test_action:
    runs-on: ubuntu-latest

    steps:
      - name: Test repository report
        id: report
        uses: owner/repository-report-action@v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          include-issues: true

      - name: Display results
        run: |
          echo "Stars: ${{ steps.report.outputs.total-stars }}"
          echo "Issues: ${{ steps.report.outputs.total-issues }}"

      - name: Upload report
        uses: actions/upload-artifact@v4
        with:
          name: repository-report
          path: ${{ steps.report.outputs.report-file }}
```

### Testing in a Workflow (Private Action)

When testing in the same repository:

```yaml
on:
  push:
    branches:
      - main

jobs:
  test_action:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Test action
        uses: ./
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
```

## Advanced Patterns

### Conditional Logic

```javascript
import * as core from "@actions/core";

const environment = core.getInput("environment");

if (environment === "production") {
  core.warning("Deploying to production - proceed with caution");

  // Require approval
  const approved = core.getBooleanInput("approved");
  if (!approved) {
    core.setFailed("Production deployment requires approval");
    return;
  }
}

// Continue with deployment
core.info(`Deploying to ${environment}`);
```

### Working with Files

```javascript
import { readFileSync, writeFileSync, existsSync } from "fs";
import { join } from "path";

// Read file
const configPath = core.getInput("config-file");
if (!existsSync(configPath)) {
  core.setFailed(`Config file not found: ${configPath}`);
  return;
}

const config = JSON.parse(readFileSync(configPath, "utf8"));

// Write file
const outputPath = join(process.env.GITHUB_WORKSPACE, "output.json");
writeFileSync(outputPath, JSON.stringify(result, null, 2));
core.setOutput("output-file", outputPath);
```

### Making HTTP Requests

```javascript
import { request } from "@actions/http-client";

const client = new request.HttpClient("my-action");

try {
  const response = await client.getJson("https://api.example.com/data");

  if (response.statusCode !== 200) {
    core.setFailed(`API returned ${response.statusCode}`);
    return;
  }

  const data = response.result;
  core.info(`Received ${data.items.length} items`);
} catch (error) {
  core.setFailed(`API request failed: ${error.message}`);
}
```

### Async/Await Patterns

```javascript
async function processFiles(files) {
  const results = [];

  for (const file of files) {
    core.info(`Processing ${file}`);
    const result = await processFile(file);
    results.push(result);
  }

  return results;
}

async function main() {
  try {
    const files = core.getMultilineInput("files");
    const results = await processFiles(files);

    core.setOutput("processed-count", results.length);
    core.notice(`Processed ${results.length} files`);
  } catch (error) {
    core.setFailed(error.message);
  }
}

main();
```

### Environment Variables

```javascript
// Read environment variables
const workspace = process.env.GITHUB_WORKSPACE;
const repository = process.env.GITHUB_REPOSITORY;
const actor = process.env.GITHUB_ACTOR;
const sha = process.env.GITHUB_SHA;

// Set environment variable for subsequent steps
core.exportVariable("CUSTOM_VAR", "value");

// In later steps
const customValue = process.env.CUSTOM_VAR;
```

## Publishing Your Action

### Create README.md

Document your action thoroughly:

```markdown
# Repository Report Action

Generate comprehensive repository statistics and reports.

## Usage

```yaml
- uses: owner/repository-report-action@v1
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    include-issues: true
```

## Inputs

### `github-token`

**Required** GitHub token for API access. Use `${{ secrets.GITHUB_TOKEN }}`.

### `include-issues`

**Optional** Include issue statistics in report. Default: `true`.

## Outputs

### `total-stars`

Total number of repository stars.

### `total-issues`

Total number of open issues (if `include-issues` is true).

### `report-file`

Path to generated markdown report file.

## Example

```yaml
jobs:
  report:
    runs-on: ubuntu-latest
    steps:
      - uses: owner/repository-report-action@v1
        id: report
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}

      - run: cat ${{ steps.report.outputs.report-file }}
```

## License

MIT
```

### Publish to Marketplace

1. Create release on GitHub
2. Add release notes
3. Check "Publish this Action to GitHub Marketplace"
4. Choose category
5. Add icon and color

## Best Practices

### Security

- Never log sensitive information
- Use `core.setSecret()` for API keys and tokens
- Validate all inputs
- Use least-privilege tokens
- Pin action versions in workflows

### Performance

- Minimize dependencies
- Use efficient algorithms
- Cache API responses when possible
- Avoid unnecessary file operations
- Bundle code properly

### Reliability

- Handle all error cases
- Provide meaningful error messages
- Set appropriate timeouts
- Use try-catch blocks
- Validate inputs early

### Maintainability

- Use clear variable names
- Add comments for complex logic
- Keep functions small and focused
- Follow consistent code style
- Update dependencies regularly

### User Experience

- Provide helpful log messages
- Use log groups for related output
- Set clear outputs
- Document all inputs and outputs
- Include working examples

## Troubleshooting

### Action Not Found

Ensure:
- Repository is public or access is configured
- Tag exists and is pushed
- Action path is correct in workflow

### Import Errors

Check:
- Dependencies are installed
- Code is compiled with bundler
- `dist/index.js` is committed
- Node version matches `runs.using`

### Permission Errors

Verify:
- `GITHUB_TOKEN` has required permissions
- Repository settings allow workflow access
- Token is passed correctly to action

### Output Not Set

Confirm:
- `core.setOutput()` is called
- Output ID matches `action.yml`
- Step has an `id` in workflow
- Output is referenced correctly
