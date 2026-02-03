// TypeScript configuration with type safety
// Demonstrates using TypeScript for commitlint configuration

import type { UserConfig } from '@commitlint/types';
import { RuleConfigSeverity } from '@commitlint/types';

const Configuration: UserConfig = {
  extends: ['@commitlint/config-conventional'],

  // Override specific rules with type-safe severity levels
  rules: {
    'type-enum': [
      RuleConfigSeverity.Error,
      'always',
      [
        'feat',     // New feature
        'fix',      // Bug fix
        'docs',     // Documentation
        'style',    // Code style (formatting)
        'refactor', // Code refactoring
        'perf',     // Performance improvement
        'test',     // Tests
        'build',    // Build system
        'ci',       // CI configuration
        'chore',    // Maintenance
        'revert'    // Revert previous commit
      ]
    ],

    'header-max-length': [RuleConfigSeverity.Error, 'always', 100],
    'body-leading-blank': [RuleConfigSeverity.Error, 'always'],
    'footer-leading-blank': [RuleConfigSeverity.Error, 'always'],
    'subject-case': [RuleConfigSeverity.Error, 'always', 'sentence-case']
  },

  // Custom ignore patterns
  ignores: [
    (commit) => commit.includes('WIP'),
    (commit) => commit.includes('[skip ci]')
  ],

  // Keep default ignores (merge commits, version tags, etc.)
  defaultIgnores: true,

  // Custom help URL shown on validation failure
  helpUrl: 'https://github.com/conventional-changelog/commitlint'
};

export default Configuration;
