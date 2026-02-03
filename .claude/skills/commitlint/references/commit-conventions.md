# Conventional Commits Deep Dive

Comprehensive guide to Conventional Commits specification and patterns.

## Specification Overview

Conventional Commits is a specification for adding human and machine-readable meaning to commit messages. It provides an easy set of rules for creating an explicit commit history.

### Official Format

```
<type>[optional scope][optional !]: <subject>

[optional body]

[optional footer(s)]
```

### Components

#### Type (Required)

Describes the category of change:

**Standard types from Conventional Commits:**
- `feat` - New feature for users
- `fix` - Bug fix for users
- `docs` - Documentation changes
- `style` - Code style changes (formatting, semicolons, etc.)
- `refactor` - Code change that neither fixes a bug nor adds a feature
- `perf` - Performance improvement
- `test` - Adding or fixing tests
- `build` - Changes to build system or dependencies
- `ci` - Changes to CI configuration files and scripts
- `chore` - Other changes that don't modify src or test files
- `revert` - Reverts a previous commit

**Extended types (optional):**
- `security` - Security fixes or improvements
- `deps` - Dependency updates
- `breaking` - Breaking changes (though `!` is preferred)
- `wip` - Work in progress (typically not committed to main branches)

#### Scope (Optional)

Provides additional context about what part of the codebase changed:

```
feat(auth): add OAuth2 support
fix(api): handle null response from database
docs(readme): update installation instructions
```

**Scope guidelines:**
- Use lowercase
- Keep concise (1-2 words)
- Use consistent naming across the project
- Match component/module names when possible

**Common scopes:**
- `api` - API changes
- `ui` - User interface
- `db` - Database
- `auth` - Authentication
- `config` - Configuration
- `deps` - Dependencies
- `core` - Core functionality
- Package names in monorepos

**Multiple scopes:**

Commitlint supports multiple scopes with delimiters:

```
feat(api,db): synchronize user schema between API and database
```

Default delimiters: `/`, `\`, `,`

Configure with `scope-case` rule:

```javascript
export default {
  rules: {
    'scope-case': [2, 'always', 'kebab-case'],
    'scope-delimiter-style': [2, 'always', ',']
  }
};
```

#### Subject (Required)

Brief description of the change:

**Guidelines:**
- Use imperative mood ("add" not "added" or "adds")
- Don't capitalize first letter (when using `lower-case` convention)
- No period at the end
- Keep under 50-72 characters
- Be specific and descriptive

**Good examples:**
```
add user authentication middleware
fix race condition in cache invalidation
update dependency versions in package.json
```

**Bad examples:**
```
Added some stuff          // Past tense, vague
Fixes bugs.               // Too generic, has period
UPDATED THE README FILE   // All caps
fix                       // Too short, no description
```

#### Breaking Change Indicator (Optional)

Use `!` after type/scope to indicate breaking changes:

```
feat!: remove deprecated v1 API
feat(api)!: change response format to JSON:API spec
```

**Must be accompanied by `BREAKING CHANGE:` in footer:**

```
feat!: change config file format

BREAKING CHANGE: Configuration must now use YAML instead of JSON.
All config.json files need to be migrated to config.yaml.
```

#### Body (Optional)

Detailed explanation of the change:

**Guidelines:**
- Separate from subject with a blank line
- Wrap at 72 characters per line (URLs can exceed)
- Explain what and why, not how
- Use paragraphs for complex changes
- Use bullet points for lists

**Example:**
```
feat: implement caching layer for API responses

The API was experiencing performance issues under high load due to
repeated database queries for the same data. This change introduces
a Redis-based caching layer that:

- Caches GET responses for 5 minutes
- Invalidates cache on PUT/POST/DELETE operations
- Reduces average response time from 200ms to 50ms
- Decreases database load by approximately 70%

The cache TTL can be configured via CACHE_TTL environment variable.
```

#### Footer (Optional)

Metadata about the commit:

**Common footer patterns:**

**Breaking changes:**
```
BREAKING CHANGE: API v1 endpoints removed. Use v2 endpoints instead.
```

**Issue references:**
```
Closes #123
Fixes #456, #789
Resolves gh-123
```

**Reviewed by:**
```
Reviewed-by: John Doe <john@example.com>
```

**Signed-off:**
```
Signed-off-by: Jane Smith <jane@example.com>
```

**Co-authors:**
```
Co-authored-by: Bob Johnson <bob@example.com>
```

**Multiple footers:**
```
feat: add user export functionality

Closes #234
Reviewed-by: Alice <alice@example.com>
Co-authored-by: Bob <bob@example.com>
```

## Complete Examples

### Simple Feature

```
feat: add dark mode toggle

Implement a dark mode toggle in the settings panel. The preference
is persisted to localStorage and applied on page load.
```

### Bug Fix with Issue Reference

```
fix: prevent memory leak in event listeners

Event listeners were not being cleaned up when components unmounted,
causing memory usage to grow over time. This change ensures all
listeners are properly removed in the cleanup phase.

Fixes #789
```

### Breaking Change

```
feat!: migrate to TypeScript strict mode

BREAKING CHANGE: All imports must now use explicit file extensions.
Update imports from './module' to './module.js' or './module.ts'.

This change enables better type checking and catches more potential
errors at compile time. Migration guide available at:
https://docs.example.com/typescript-migration
```

### Documentation Update

```
docs(api): add examples for authentication endpoints

Added code examples for:
- OAuth2 flow
- API key authentication
- JWT token refresh

Examples include error handling and edge cases.
```

### Chore with Scope

```
chore(deps): update React to v18.2.0

Update React and React DOM to latest stable version. All tests pass
without modifications. No breaking changes in this update.
```

### Refactor

```
refactor(auth): extract validation logic to separate module

Moved authentication validation logic from controller to dedicated
validator module. This improves:
- Code organization
- Testability
- Reusability across different auth methods

No functional changes to authentication behavior.
```

### Performance Improvement

```
perf(render): optimize component re-renders with memo

Wrap expensive components in React.memo() to prevent unnecessary
re-renders. Reduces render time by ~40% on complex pages.

Benchmarks:
- Before: 150ms average render time
- After: 90ms average render time
```

### Revert

```
revert: feat: add experimental feature X

This reverts commit a1b2c3d4.

Feature X caused performance regressions in production. Reverting
until optimization work is complete.

Fixes #456
```

## Advanced Patterns

### Monorepo Commits

**Scope-based approach:**
```
feat(web-app): add user profile page
fix(api-server): handle database connection timeout
chore(shared-utils): update lodash to v4.17.21
```

**Multiple affected packages:**
```
refactor(api,web-app): standardize error response format

Update both API server and web app to use consistent error response
structure: { error: { code, message, details } }
```

### Atomic Commits

Each commit should represent a single logical change:

**Good - Atomic:**
```
feat: add user authentication
feat: add user profile page
feat: add logout functionality
```

**Bad - Mixed concerns:**
```
feat: add authentication, profile page, and logout
```

### Squash vs Linear History

**Squash merges:**
- Combine PR commits into one
- Use comprehensive commit message covering all changes
- Good for feature branches

```
feat: implement user authentication system

This PR implements complete user authentication including:
- Login/logout endpoints
- Session management with JWT
- Password hashing with bcrypt
- Email verification flow
- Password reset functionality

Closes #123, #124, #125
```

**Linear history:**
- Keep individual commits
- Each commit should be well-formed
- Good for complex features

```
feat(auth): add login endpoint
feat(auth): implement JWT session management
feat(auth): add password hashing
feat(auth): add email verification
feat(auth): add password reset
```

## Tooling Integration

### Automated Changelog Generation

Conventional commits enable automated changelog generation:

```markdown
# Changelog

## [2.0.0] - 2024-01-15

### Features
- add dark mode support (#123)
- implement user export functionality (#234)

### Bug Fixes
- prevent memory leak in event listeners (#789)
- fix race condition in cache invalidation (#456)

### BREAKING CHANGES
- migrate to TypeScript strict mode

## [1.5.0] - 2023-12-01
...
```

Tools: `conventional-changelog`, `standard-version`, `semantic-release`

### Semantic Versioning

Map commit types to version bumps:

- `fix:` → Patch version (1.0.0 → 1.0.1)
- `feat:` → Minor version (1.0.0 → 1.1.0)
- `BREAKING CHANGE:` or `!` → Major version (1.0.0 → 2.0.0)

### Automated Release Notes

```markdown
## What's Changed

### 🚀 Features
* add dark mode toggle by @jane in #123
* implement caching layer by @john in #234

### 🐛 Bug Fixes
* prevent memory leak by @bob in #789

### 📚 Documentation
* update API examples by @alice in #456

**Full Changelog**: v1.0.0...v2.0.0
```

## Team Adoption Strategies

### 1. Start with Basics

Begin with simple types only:

```javascript
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [2, 'always', ['feat', 'fix', 'docs', 'chore']]
  }
};
```

Expand over time as team gets comfortable.

### 2. Provide Examples

Create a CONTRIBUTING.md with examples:

```markdown
# Commit Message Guidelines

## Format
type(scope): subject

## Examples

### Adding a feature
`feat(auth): add OAuth2 support`

### Fixing a bug
`fix(api): handle null pointer in user endpoint`

### Updating documentation
`docs(readme): update installation steps`
```

### 3. Use Interactive Prompts

Install commitizen:

```bash
npm install -D @commitlint/cz-commitlint commitizen
```

Configure in package.json:

```json
{
  "scripts": {
    "commit": "git-cz"
  },
  "config": {
    "commitizen": {
      "path": "@commitlint/cz-commitlint"
    }
  }
}
```

Users run `npm run commit` for guided commit creation.

### 4. Enforce Gradually

**Phase 1 - Warnings:**
```javascript
export default {
  rules: {
    'type-enum': [1, 'always', types] // Warning only
  }
};
```

**Phase 2 - Errors in CI only:**
```javascript
const isCI = process.env.CI === 'true';
export default {
  rules: {
    'type-enum': [isCI ? 2 : 1, 'always', types]
  }
};
```

**Phase 3 - Errors everywhere:**
```javascript
export default {
  rules: {
    'type-enum': [2, 'always', types] // Block commits
  }
};
```

### 5. Document Benefits

Show the team:
- Automated changelog generation
- Easier code review (understand changes at a glance)
- Better git history navigation
- Automated semantic versioning
- Improved project communication

## Common Patterns

### Feature Flags

```
feat(flags): add feature flag for new dashboard

Implement feature flag system to control rollout of new dashboard.
Flag can be toggled via admin panel or environment variable.

Feature: NEW_DASHBOARD_ENABLED
```

### Database Migrations

```
feat(db): add user preferences table

Migration: 20240115_add_user_preferences

Creates new table for storing user preferences including:
- Theme selection
- Language preference
- Notification settings

Run: npm run migrate
```

### API Changes

```
feat(api): add pagination to user list endpoint

Update GET /api/users to support pagination via query parameters:
- ?page=1 (default)
- ?limit=20 (default)

Response includes pagination metadata:
{
  "data": [...],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "totalPages": 8
  }
}
```

### Security Fixes

```
fix(security): sanitize user input in search query

Prevent XSS attacks by sanitizing user input before rendering search
results. All HTML tags are now escaped except for whitelisted tags.

CVE: Not assigned (internal finding)
Severity: Medium
```

### Dependency Updates

```
chore(deps): update axios to 1.6.2

Security update to address CVE-2023-45857. No API changes.

Release notes: https://github.com/axios/axios/releases/tag/v1.6.2
```

## Anti-Patterns

### ❌ Vague Commits

```
fix: bug
chore: updates
feat: changes
```

### ❌ Multiple Concerns

```
feat: add login page, fix header bug, update readme
```

Should be three commits:
```
feat: add login page
fix: correct header alignment on mobile
docs: update readme with login instructions
```

### ❌ Missing Type

```
add new feature
```

Should be:
```
feat: add user export functionality
```

### ❌ Wrong Type

```
feat: fix typo in documentation
```

Should be:
```
docs: fix typo in installation guide
```

### ❌ Over-scoping

```
feat(src/components/auth/login/LoginForm.tsx): add remember me checkbox
```

Should be:
```
feat(auth): add remember me checkbox
```

### ❌ Missing Context

```
fix: update code
```

Should be:
```
fix(auth): prevent session timeout on page navigation

Session was timing out when navigating between pages due to incorrect
token refresh logic. Now refreshes token before expiration.
```

## Customizing for Your Team

### Industry-Specific Types

**E-commerce:**
```javascript
'type-enum': [2, 'always', [
  'feat', 'fix', 'docs',
  'product',   // Product catalog changes
  'checkout',  // Checkout flow changes
  'payment',   // Payment processing
  'shipping'   // Shipping logic
]]
```

**Data Science:**
```javascript
'type-enum': [2, 'always', [
  'feat', 'fix', 'docs',
  'model',      // ML model changes
  'data',       // Dataset updates
  'experiment', // New experiments
  'pipeline'    // Data pipeline changes
]]
```

**Infrastructure:**
```javascript
'type-enum': [2, 'always', [
  'feat', 'fix', 'docs',
  'infra',    // Infrastructure changes
  'deploy',   // Deployment updates
  'monitor',  // Monitoring/alerting
  'security'  // Security updates
]]
```

### Ticket Integration

Force ticket references:

```javascript
export default {
  parserPreset: {
    parserOpts: {
      headerPattern: /^(\w+)(?:\(([^)]*)\))?: (PROJ-\d+) (.+)$/,
      headerCorrespondence: ['type', 'scope', 'ticket', 'subject']
    }
  },
  plugins: [{
    rules: {
      'ticket-required': ({ ticket }) => [
        Boolean(ticket),
        'Commit must include ticket reference (e.g., PROJ-123)'
      ]
    }
  }],
  rules: {
    'ticket-required': [2, 'always']
  }
};
```

Format: `feat(api): PROJ-123 add new endpoint`
