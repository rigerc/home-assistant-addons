// Monorepo configuration with automatic scope detection
// Demonstrates scope validation for monorepo projects

import { readdirSync, statSync } from 'fs';
import { join } from 'path';

// Automatically discover package scopes from directories
function getPackageScopes() {
  const packagesDir = join(process.cwd(), 'packages');

  try {
    const packages = readdirSync(packagesDir)
      .filter(file => {
        const fullPath = join(packagesDir, file);
        return statSync(fullPath).isDirectory();
      });

    return packages;
  } catch (error) {
    // Fallback if packages directory doesn't exist
    return [];
  }
}

// Additional allowed scopes beyond package names
const additionalScopes = [
  'root',       // Root-level changes
  'deps',       // Dependency updates
  'ci',         // CI/CD configuration
  'docs',       // Documentation
  'tooling',    // Development tools
  'infra',      // Infrastructure
  'release'     // Release-related changes
];

// Combine package scopes with additional scopes
const allowedScopes = [
  ...getPackageScopes(),
  ...additionalScopes
];

export default {
  extends: ['@commitlint/config-conventional'],

  rules: {
    // Enforce scope from allowed list
    'scope-enum': [2, 'always', allowedScopes],

    // Require scope for most commit types
    'scope-empty': [2, 'never'],

    // Allow multiple scopes for cross-package changes
    'scope-case': [2, 'always', 'kebab-case'],

    // Custom types for monorepo
    'type-enum': [2, 'always', [
      'feat',      // New feature
      'fix',       // Bug fix
      'docs',      // Documentation
      'style',     // Code style
      'refactor',  // Refactoring
      'perf',      // Performance
      'test',      // Tests
      'build',     // Build system
      'ci',        // CI configuration
      'chore',     // Maintenance
      'revert',    // Revert
      'release'    // Release commits
    ]],

    'header-max-length': [2, 'always', 100],
    'subject-case': [2, 'always', 'sentence-case']
  },

  // Custom ignores for monorepo
  ignores: [
    // Ignore Lerna/Nx automated commits
    (commit) => commit.startsWith('chore(release):'),

    // Ignore automated version bumps
    (commit) => /^chore\([^)]+\): v\d+\.\d+\.\d+/.test(commit)
  ],

  defaultIgnores: true,

  helpUrl: 'https://github.com/yourorg/monorepo/blob/main/CONTRIBUTING.md'
};

// Example valid commits for monorepo:
//
// Single package:
// feat(api-server): add GraphQL support
// fix(web-app): resolve routing issue on Safari
// docs(shared-utils): update API documentation
//
// Multiple packages:
// feat(api-server,web-app): implement real-time notifications
// refactor(shared-utils,api-server): standardize error handling
//
// Root-level:
// chore(root): update workspace dependencies
// ci(root): add automated release workflow
// docs(root): update main README
//
// Infrastructure:
// feat(infra): add Redis caching layer
// fix(infra): resolve Kubernetes deployment issue
