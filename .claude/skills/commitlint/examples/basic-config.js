// Basic commitlint configuration using Conventional Commits
// This is the simplest setup - just extends the conventional config

export default {
  extends: ['@commitlint/config-conventional']
};

// This configuration enables:
// - Standard commit types (feat, fix, docs, etc.)
// - Optional scope in parentheses
// - Subject validation (max 72 chars, no period at end)
// - Proper commit message format: type(scope): subject

// Example valid commits:
// feat: add user authentication
// fix(api): resolve null pointer exception
// docs: update README with installation steps
// chore(deps): update dependencies
