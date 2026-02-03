# Commitlint Configuration Options Reference

Complete reference for all commitlint configuration options.

## Configuration File Locations

Commitlint automatically discovers configuration from these locations (in order of priority):

### File-based Configuration

1. `.commitlintrc`
2. `.commitlintrc.json`
3. `.commitlintrc.yaml` / `.commitlintrc.yml`
4. `.commitlintrc.js` / `.commitlintrc.cjs` / `.commitlintrc.mjs`
5. `.commitlintrc.ts` / `.commitlintrc.cts` / `.commitlintrc.mts`
6. `commitlint.config.js` / `.cjs` / `.mjs`
7. `commitlint.config.ts` / `.cts` / `.mts`

### Package.json Configuration

Add a `commitlint` field:

```json
{
  "commitlint": {
    "extends": ["@commitlint/config-conventional"]
  }
}
```

Also works with `package.yaml` (pnpm).

### CLI Override

```bash
commitlint --config ./path/to/config.js
```

## Configuration Object Schema

```typescript
interface UserConfig {
  extends?: string[];
  parserPreset?: string | ParserPreset;
  formatter?: string;
  rules?: RulesConfig;
  ignores?: IgnoreFunction[];
  defaultIgnores?: boolean;
  helpUrl?: string;
  prompt?: PromptConfig;
  plugins?: Plugin[];
}
```

## Core Configuration Options

### extends

**Type:** `string[]`

**Description:** Array of shareable configurations to extend from

**Resolution:** Uses Node.js module resolution algorithm
- npm packages: `@commitlint/config-conventional`
- Scoped packages: `@company/commitlint-config`
- Shorthand: `'lerna'` resolves to `commitlint-config-lerna`
- Local files: `'./custom-config.js'`

**Examples:**

```javascript
// Single extend
export default {
  extends: ['@commitlint/config-conventional']
};
```

```javascript
// Multiple extends (applied in order)
export default {
  extends: [
    '@commitlint/config-conventional',
    '@commitlint/config-lerna-scopes',
    './local-config.js'
  ]
};
```

```javascript
// Nested extends (configs can extend other configs)
// base-config.js
export default {
  extends: ['@commitlint/config-conventional']
};

// commitlint.config.js
export default {
  extends: ['./base-config.js'],
  rules: {
    'header-max-length': [2, 'always', 100]
  }
};
```

**Popular extends:**
- `@commitlint/config-conventional` - Conventional Commits standard
- `@commitlint/config-angular` - Angular commit convention
- `@commitlint/config-lerna-scopes` - Lerna monorepo scopes
- `@commitlint/config-nx-scopes` - Nx monorepo scopes

### parserPreset

**Type:** `string | ParserPreset`

**Description:** Parser preset for parsing commit messages

**Default:** Uses parser from extended configs

**Examples:**

```javascript
// npm package
export default {
  parserPreset: 'conventional-changelog-atom'
};
```

```javascript
// Local preset
export default {
  parserPreset: './parser-preset.js'
};
```

```javascript
// Inline preset object
export default {
  parserPreset: {
    parserOpts: {
      headerPattern: /^(\w*)(?:\((.*)\))?!?: (.*)$/,
      headerCorrespondence: ['type', 'scope', 'subject']
    }
  }
};
```

**Custom parser pattern example:**

```javascript
export default {
  parserPreset: {
    parserOpts: {
      // Match: TICKET-123: type(scope): subject
      headerPattern: /^([A-Z]+-\d+): (\w*)(?:\((.*)\))?: (.*)$/,
      headerCorrespondence: ['ticket', 'type', 'scope', 'subject'],

      // Reference patterns for footer
      referenceActions: ['closes', 'fixes', 'resolves'],
      issuePrefixes: ['JIRA-', '#'],

      // Note keywords
      noteKeywords: ['BREAKING CHANGE', 'BREAKING CHANGES'],

      // Field patterns
      fieldPattern: /^-(.*?)-$/,
      revertPattern: /^(?:Revert|revert:)\s"?([\s\S]+?)"?\s*This reverts commit (\w*)\./i,
      revertCorrespondence: ['header', 'hash']
    }
  }
};
```

### formatter

**Type:** `string`

**Description:** Output formatter for displaying validation results

**Default:** `'@commitlint/format'`

**Examples:**

```javascript
export default {
  formatter: '@commitlint/format'
};
```

Custom formatters must export a function:

```javascript
// custom-formatter.js
export default (report, options) => {
  const { results } = report;
  return results
    .map(result => `${result.valid ? '✅' : '❌'} ${result.input}`)
    .join('\n');
};
```

### rules

**Type:** `RulesConfig<RuleConfig>`

**Description:** Rule configuration object

**Format:** `{ 'rule-name': [severity, applicability, value] }`

**Severity:**
- `0` - Disabled
- `1` - Warning
- `2` - Error

**Applicability:**
- `'always'` - Condition must be true
- `'never'` - Condition must be false

**Examples:**

```javascript
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // Override extended rules
    'header-max-length': [2, 'always', 100],

    // Disable a rule
    'scope-case': [0],

    // Add custom rules
    'type-enum': [2, 'always', [
      'feat', 'fix', 'docs', 'chore', 'refactor'
    ]],

    // Warning instead of error
    'body-max-line-length': [1, 'always', 100]
  }
};
```

See `rules-reference.md` for complete rule documentation.

### ignores

**Type:** `((commit: string) => boolean)[]`

**Description:** Array of functions that return `true` to ignore a commit

**Default:** Includes patterns for merge commits, version tags, and automated commits

**Examples:**

```javascript
export default {
  ignores: [
    // Ignore WIP commits
    (commit) => commit.includes('WIP'),

    // Ignore commits starting with "chore: release"
    (commit) => commit.startsWith('chore: release'),

    // Ignore Dependabot commits
    (commit) => commit.includes('dependabot'),

    // Ignore empty commits
    (commit) => commit.trim() === '',

    // Complex pattern
    (commit) => {
      const wipPattern = /\b(wip|WIP|work in progress)\b/i;
      return wipPattern.test(commit);
    }
  ]
};
```

**Default ignores include:**
- Merge commits: `Merge pull request`, `Merge branch`
- Revert commits: `Revert "..."`
- Version tags: `v1.2.3` (semver pattern)
- Automated merges: `Automatic merge`, `Auto-merged`

See: https://github.com/conventional-changelog/commitlint/blob/master/%40commitlint/is-ignored/src/defaults.ts

### defaultIgnores

**Type:** `boolean`

**Description:** Whether to use default ignore patterns

**Default:** `true`

**Examples:**

```javascript
// Disable all default ignores
export default {
  defaultIgnores: false
};
```

```javascript
// Use custom ignores only
export default {
  defaultIgnores: false,
  ignores: [
    (commit) => commit.includes('skip-lint')
  ]
};
```

```javascript
// Combine default and custom ignores
export default {
  defaultIgnores: true, // Keep defaults
  ignores: [
    (commit) => commit.includes('WIP') // Add custom
  ]
};
```

### helpUrl

**Type:** `string`

**Description:** Custom URL shown when validation fails

**Default:** `'https://github.com/conventional-changelog/commitlint/#what-is-commitlint'`

**Examples:**

```javascript
export default {
  helpUrl: 'https://wiki.company.com/commit-guidelines'
};
```

```javascript
export default {
  helpUrl: 'https://github.com/your-org/your-repo/blob/main/CONTRIBUTING.md#commit-messages'
};
```

### prompt

**Type:** `PromptConfig`

**Description:** Configuration for interactive commit prompts

**Used by:** `@commitlint/cz-commitlint` and `@commitlint/prompt-cli`

**Examples:**

```javascript
export default {
  prompt: {
    messages: {
      type: 'Select the type of change:',
      scope: 'Denote the scope:',
      subject: 'Write a short description:',
      body: 'Provide a longer description:',
      breaking: 'Describe the breaking changes:',
      footer: 'List issues closed:',
      confirmCommit: 'Are you sure?'
    },
    questions: {
      type: {
        description: 'Select the type of change',
        enum: {
          feat: {
            description: 'A new feature',
            title: 'Features',
            emoji: '✨'
          },
          fix: {
            description: 'A bug fix',
            title: 'Bug Fixes',
            emoji: '🐛'
          }
        }
      },
      scope: {
        description: 'What is the scope of this change'
      },
      subject: {
        description: 'Write a short, imperative description'
      }
    }
  }
};
```

See `prompt-reference.md` for complete prompt configuration.

### plugins

**Type:** `Plugin[]`

**Description:** Array of plugin objects with custom rules

**Examples:**

```javascript
export default {
  plugins: [
    {
      rules: {
        'jira-ticket-required': ({ header }) => {
          const hasTicket = /JIRA-\d+/.test(header);
          return [
            hasTicket,
            'Commit message must include JIRA ticket (e.g., JIRA-123)'
          ];
        },
        'no-swearing': ({ raw }) => {
          const badWords = ['damn', 'hell'];
          const hasBadWord = badWords.some(word => raw.toLowerCase().includes(word));
          return [
            !hasBadWord,
            'Commit message contains inappropriate language'
          ];
        }
      }
    }
  ],
  rules: {
    'jira-ticket-required': [2, 'always'],
    'no-swearing': [2, 'always']
  }
};
```

**Plugin structure:**

```typescript
interface Plugin {
  rules: {
    [ruleName: string]: (parsed: Commit, when?: string, value?: any) => [boolean, string?]
  }
}

interface Commit {
  raw: string;        // Full commit message
  header: string;     // First line
  type: string | null;
  scope: string | null;
  subject: string | null;
  body: string | null;
  footer: string | null;
  notes: Note[];
  references: Reference[];
  mentions: string[];
  revert: Revert | null;
  merge: Merge | null;
}
```

## TypeScript Configuration

### Basic TypeScript Config

```typescript
import type { UserConfig } from '@commitlint/types';

const Configuration: UserConfig = {
  extends: ['@commitlint/config-conventional']
};

export default Configuration;
```

### TypeScript with Enums

```typescript
import type { UserConfig } from '@commitlint/types';
import { RuleConfigSeverity } from '@commitlint/types';

const Configuration: UserConfig = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      RuleConfigSeverity.Error,
      'always',
      ['feat', 'fix', 'docs', 'chore']
    ],
    'header-max-length': [RuleConfigSeverity.Warning, 'always', 100]
  }
};

export default Configuration;
```

### Advanced TypeScript Config

```typescript
import type { UserConfig, QualifiedRules } from '@commitlint/types';
import { RuleConfigSeverity, RuleConfigQuality } from '@commitlint/types';

const rules: QualifiedRules = {
  'header-max-length': [RuleConfigSeverity.Error, 'always', 72],
  'body-leading-blank': [RuleConfigSeverity.Error, 'always'],
  'type-enum': [
    RuleConfigSeverity.Error,
    'always',
    ['feat', 'fix', 'docs', 'style', 'refactor', 'test', 'chore']
  ]
};

const Configuration: UserConfig = {
  extends: ['@commitlint/config-conventional'],
  rules,
  ignores: [(commit) => commit.includes('WIP')],
  defaultIgnores: true,
  helpUrl: 'https://example.com/commit-guide'
};

export default Configuration;
```

## Environment-Specific Configuration

### Using Environment Variables

```javascript
const isCI = process.env.CI === 'true';

export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // Stricter rules in CI
    'body-max-line-length': isCI ? [2, 'always', 100] : [1, 'always', 100]
  }
};
```

### Conditional Configuration

```javascript
const isDevelopment = process.env.NODE_ENV === 'development';

export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'subject-case': isDevelopment
      ? [1, 'always', 'sentence-case'] // Warning in dev
      : [2, 'always', 'sentence-case']  // Error in production
  }
};
```

## Monorepo Configurations

### Lerna Scopes

```javascript
export default {
  extends: [
    '@commitlint/config-conventional',
    '@commitlint/config-lerna-scopes'
  ]
};
```

Automatically derives scopes from Lerna packages.

### Manual Monorepo Scopes

```javascript
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'scope-enum': [2, 'always', [
      'frontend',
      'backend',
      'shared',
      'docs',
      'infra',
      'tools'
    ]],
    'scope-empty': [2, 'never'] // Scope required
  }
};
```

### Dynamic Scopes from File System

```javascript
import { readdirSync } from 'fs';
import { join } from 'path';

const packages = readdirSync(join(__dirname, 'packages'));

export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'scope-enum': [2, 'always', packages]
  }
};
```

## CommonJS Format

Still supported for compatibility:

```javascript
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'header-max-length': [2, 'always', 100]
  }
};
```

## Configuration Loading Order

1. CLI `--config` flag (highest priority)
2. `commitlint` field in `package.json`
3. `.commitlintrc` (various formats)
4. `commitlint.config.*` files
5. Extended configurations (loaded recursively)

## Debugging Configuration

### Print Current Configuration

```bash
npx commitlint --print-config
```

Shows the resolved configuration with all extends merged.

### Validate Configuration

```bash
npx commitlint --help-url
```

Shows the configured help URL.

### Test Configuration

```bash
# Test with specific message
echo "feat: test" | npx commitlint

# Test with verbose output
npx commitlint --from HEAD~1 --verbose

# Test config loading
npx commitlint --print-config > config-dump.json
```

## Common Configuration Patterns

### Strict Conventional Commits

```javascript
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'body-leading-blank': [2, 'always'],
    'footer-leading-blank': [2, 'always'],
    'header-max-length': [2, 'always', 72],
    'scope-case': [2, 'always', 'kebab-case'],
    'subject-case': [2, 'always', 'sentence-case'],
    'subject-empty': [2, 'never'],
    'subject-full-stop': [2, 'never', '.'],
    'type-case': [2, 'always', 'lower-case'],
    'type-empty': [2, 'never'],
    'type-enum': [2, 'always', [
      'feat', 'fix', 'docs', 'style', 'refactor',
      'perf', 'test', 'build', 'ci', 'chore', 'revert'
    ]]
  }
};
```

### Lenient Configuration

```javascript
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'body-max-line-length': [0],
    'header-max-length': [0],
    'scope-case': [0],
    'subject-case': [0]
  }
};
```

### JIRA Integration

```javascript
export default {
  extends: ['@commitlint/config-conventional'],
  parserPreset: {
    parserOpts: {
      headerPattern: /^([A-Z]+-\d+): (\w*)(?:\((.*)\))?: (.*)$/,
      headerCorrespondence: ['ticket', 'type', 'scope', 'subject']
    }
  },
  plugins: [
    {
      rules: {
        'jira-ticket': ({ ticket }) => [
          Boolean(ticket),
          'Commit must include JIRA ticket'
        ]
      }
    }
  ],
  rules: {
    'jira-ticket': [2, 'always']
  }
};
```

## Migration from v17 to v18+

Key changes:
- ES modules are default (use `.mjs` for CJS projects)
- Some rule names changed (check changelog)
- Parser preset structure updated

```javascript
// v17 and earlier
module.exports = {
  extends: ['@commitlint/config-conventional']
};

// v18+
export default {
  extends: ['@commitlint/config-conventional']
};
```
