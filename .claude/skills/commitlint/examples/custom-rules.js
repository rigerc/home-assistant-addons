// Advanced configuration with custom rules and plugins
// Demonstrates creating custom validation rules

export default {
  extends: ['@commitlint/config-conventional'],

  // Custom parser for JIRA ticket integration
  parserPreset: {
    parserOpts: {
      // Match: type(scope): PROJ-123 subject
      headerPattern: /^(\w+)(?:\(([^)]*)\))?: (?:([A-Z]+-\d+) )?(.+)$/,
      headerCorrespondence: ['type', 'scope', 'ticket', 'subject']
    }
  },

  // Define custom rules via plugins
  plugins: [
    {
      rules: {
        // Require JIRA ticket reference
        'jira-ticket-required': ({ ticket, type }) => {
          // Skip for certain commit types
          const skipTypes = ['chore', 'docs', 'style'];
          if (skipTypes.includes(type)) {
            return [true];
          }

          return [
            Boolean(ticket),
            'Commit message must include JIRA ticket reference (e.g., PROJ-123)'
          ];
        },

        // Validate ticket format
        'jira-ticket-format': ({ ticket }) => {
          if (!ticket) return [true]; // Allow missing (handled by other rule)

          const validFormat = /^[A-Z]+-\d+$/.test(ticket);
          return [
            validFormat,
            'JIRA ticket must match format: PROJECT-123'
          ];
        },

        // Prevent profanity
        'no-profanity': ({ raw }) => {
          const profanityPattern = /\b(damn|hell|crap)\b/i;
          const hasProfanity = profanityPattern.test(raw);

          return [
            !hasProfanity,
            'Commit message contains inappropriate language'
          ];
        },

        // Require co-author for large changes
        'require-co-author': ({ body, footer }) => {
          const fullMessage = `${body || ''}\n${footer || ''}`;
          const linesChanged = fullMessage.split('\n').length;

          // If commit has large body, require co-author
          if (linesChanged > 20) {
            const hasCoAuthor = /Co-authored-by:/i.test(fullMessage);
            return [
              hasCoAuthor,
              'Large commits should include Co-authored-by: trailer'
            ];
          }

          return [true];
        },

        // Ensure breaking changes are well documented
        'breaking-change-detail': ({ body, footer, header }) => {
          const hasBreakingIndicator = header.includes('!');
          const fullMessage = `${body || ''}\n${footer || ''}`;
          const hasBreakingChange = /BREAKING CHANGE:/i.test(fullMessage);

          if (hasBreakingIndicator || hasBreakingChange) {
            // Require detailed explanation (>50 chars)
            const breakingText = fullMessage.split(/BREAKING CHANGE:/i)[1] || '';
            const hasDetail = breakingText.trim().length > 50;

            return [
              hasDetail,
              'Breaking changes must include detailed explanation (>50 chars)'
            ];
          }

          return [true];
        }
      }
    }
  ],

  // Enable custom rules
  rules: {
    // Standard rules
    'type-enum': [2, 'always', [
      'feat', 'fix', 'docs', 'style', 'refactor',
      'perf', 'test', 'build', 'ci', 'chore', 'revert'
    ]],
    'header-max-length': [2, 'always', 100],
    'body-max-line-length': [2, 'always', 100],
    'subject-case': [2, 'always', 'sentence-case'],

    // Custom rules
    'jira-ticket-required': [2, 'always'],
    'jira-ticket-format': [2, 'always'],
    'no-profanity': [2, 'always'],
    'require-co-author': [1, 'always'], // Warning, not error
    'breaking-change-detail': [2, 'always']
  },

  // Custom ignores
  ignores: [
    // Ignore WIP commits
    (commit) => commit.includes('WIP'),

    // Ignore automated dependency updates
    (commit) => commit.startsWith('chore(deps):'),

    // Ignore release commits
    (commit) => /^chore\(release\): v\d+\.\d+\.\d+/.test(commit)
  ],

  defaultIgnores: true,

  helpUrl: 'https://wiki.company.com/commit-guidelines'
};

// Example valid commits:
// feat(auth): PROJ-123 add OAuth2 support
// fix(api): PROJ-456 resolve timeout in user endpoint
// docs: update API documentation (no ticket required for docs)
// feat!: PROJ-789 migrate to new database schema
//
// BREAKING CHANGE: The database schema has changed significantly.
// All existing data will be migrated automatically on first startup,
// but the migration may take up to 10 minutes for large databases.
// Ensure you have a backup before upgrading.
