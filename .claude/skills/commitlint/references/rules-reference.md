# Commitlint Rules Reference

This document provides a comprehensive reference for all commitlint rules. Rules control how commit messages are validated.

## Rule Configuration Format

Each rule is configured using the following format:

```javascript
{
  'rule-name': [severity, applicability, value]
}
```

- **Severity:**
  - `0` - Disabled (rule is not applied)
  - `1` - Warning (rule violation is reported but doesn't fail the commit)
  - `2` - Error (rule violation fails the commit)
- **Applicability:**
  - `always` - The condition must be met
  - `never` - The condition must not be met
- **Value:** Rule-specific configuration (varies by rule)

## Commit Message Structure

Commitlint validates commits following this structure:

```
type(scope): subject

body

footer
```

Where:
- **header** = `type(scope): subject`
- **type** = Commit category (feat, fix, etc.)
- **scope** = Optional context specifier
- **subject** = Brief description
- **body** = Optional detailed description
- **footer** = Optional metadata (breaking changes, issue references, etc.)

## Body Rules

### body-case

**Condition:** Body text matches specified case style

**Configuration:**
```javascript
{
  'body-case': [2, 'always', 'lower-case']
}
```

**Possible values:**
- `'lower-case'` - lowercase only
- `'upper-case'` - UPPERCASE only
- `'camel-case'` - camelCase
- `'kebab-case'` - kebab-case
- `'pascal-case'` - PascalCase
- `'sentence-case'` - Sentence case
- `'snake-case'` - snake_case
- `'start-case'` - Start Case

### body-empty

**Condition:** Body is empty

**Configuration:**
```javascript
{
  'body-empty': [1, 'never'] // Warn if body is empty
}
```

### body-full-stop

**Condition:** Body ends with specified character

**Configuration:**
```javascript
{
  'body-full-stop': [2, 'never', '.'] // Error if body ends with period
}
```

### body-leading-blank

**Condition:** Body begins with a blank line

**Configuration:**
```javascript
{
  'body-leading-blank': [2, 'always'] // Require blank line before body
}
```

**Example:**
```
feat: add new feature
                      ← blank line required
This is the body text that explains the feature in detail.
```

### body-max-length

**Condition:** Body has maximum character count

**Configuration:**
```javascript
{
  'body-max-length': [2, 'always', 500] // Limit body to 500 characters
}
```

Default: `Infinity` (no limit)

### body-max-line-length

**Condition:** Each body line has maximum character count (URLs are excluded)

**Configuration:**
```javascript
{
  'body-max-line-length': [2, 'always', 100] // Limit each line to 100 characters
}
```

Default: `Infinity` (no limit)

### body-min-length

**Condition:** Body has minimum character count

**Configuration:**
```javascript
{
  'body-min-length': [2, 'always', 20] // Require at least 20 characters
}
```

Default: `0` (no minimum)

## Footer Rules

### footer-empty

**Condition:** Footer is empty

**Configuration:**
```javascript
{
  'footer-empty': [1, 'never'] // Warn if footer is empty
}
```

### footer-leading-blank

**Condition:** Footer begins with a blank line

**Configuration:**
```javascript
{
  'footer-leading-blank': [2, 'always'] // Require blank line before footer
}
```

### footer-max-length

**Condition:** Footer has maximum character count

**Configuration:**
```javascript
{
  'footer-max-length': [2, 'always', 300]
}
```

Default: `Infinity`

### footer-max-line-length

**Condition:** Each footer line has maximum character count

**Configuration:**
```javascript
{
  'footer-max-line-length': [2, 'always', 100]
}
```

Default: `Infinity`

### footer-min-length

**Condition:** Footer has minimum character count

**Configuration:**
```javascript
{
  'footer-min-length': [2, 'always', 10]
}
```

Default: `0`

## Header Rules

### header-case

**Condition:** Header matches specified case style

**Configuration:**
```javascript
{
  'header-case': [2, 'always', 'lower-case']
}
```

**Possible values:** Same as `body-case`

### header-full-stop

**Condition:** Header ends with specified character

**Configuration:**
```javascript
{
  'header-full-stop': [2, 'never', '.'] // Don't allow period at end
}
```

Default value: `'.'`

### header-max-length

**Condition:** Header has maximum character count

**Configuration:**
```javascript
{
  'header-max-length': [2, 'always', 72] // Conventional limit
}
```

Default: `72`

Common values: 50-100 characters

### header-min-length

**Condition:** Header has minimum character count

**Configuration:**
```javascript
{
  'header-min-length': [2, 'always', 10]
}
```

Default: `0`

### header-trim

**Condition:** Header must not have leading or trailing whitespace

**Configuration:**
```javascript
{
  'header-trim': [2, 'always'] // Remove whitespace
}
```

## Scope Rules

### scope-case

**Condition:** Scope matches specified case style

**Configuration:**
```javascript
{
  'scope-case': [2, 'always', 'kebab-case']
}
```

**Possible values:** Same as `body-case`

**Examples:**
```
feat(user-auth): ... // kebab-case
feat(UserAuth): ...  // PascalCase
feat(user_auth): ... // snake_case
```

### scope-empty

**Condition:** Scope is empty

**Configuration:**
```javascript
{
  'scope-empty': [2, 'never'] // Require scope
}
```

### scope-enum

**Condition:** Scope is in allowed list

**Configuration:**
```javascript
{
  'scope-enum': [2, 'always', ['api', 'ui', 'db', 'auth']]
}
```

**Example valid commits:**
```
feat(api): add endpoint
fix(ui): button styling
chore(db): update schema
```

### scope-max-length

**Condition:** Scope has maximum character count

**Configuration:**
```javascript
{
  'scope-max-length': [2, 'always', 20]
}
```

Default: `Infinity`

### scope-min-length

**Condition:** Scope has minimum character count

**Configuration:**
```javascript
{
  'scope-min-length': [2, 'always', 2]
}
```

Default: `0`

## Subject Rules

### subject-case

**Condition:** Subject matches specified case style

**Configuration:**
```javascript
{
  'subject-case': [2, 'always', 'sentence-case']
}
```

**Possible values:** Same as `body-case`

**Examples:**
```
feat: Add new feature     // sentence-case
feat: add new feature     // lower-case
feat: ADD NEW FEATURE     // upper-case
```

### subject-empty

**Condition:** Subject is empty

**Configuration:**
```javascript
{
  'subject-empty': [2, 'never'] // Require subject
}
```

### subject-full-stop

**Condition:** Subject ends with specified character

**Configuration:**
```javascript
{
  'subject-full-stop': [2, 'never', '.'] // No period at end
}
```

Default value: `'.'`

### subject-max-length

**Condition:** Subject has maximum character count

**Configuration:**
```javascript
{
  'subject-max-length': [2, 'always', 50]
}
```

Default: `Infinity`

### subject-min-length

**Condition:** Subject has minimum character count

**Configuration:**
```javascript
{
  'subject-min-length': [2, 'always', 10]
}
```

Default: `0`

### subject-exclamation-mark

**Condition:** Subject must/must not start with exclamation mark

**Configuration:**
```javascript
{
  'subject-exclamation-mark': [2, 'never'] // Don't allow ! at start of subject
}
```

Note: This is different from the `!` used in `type!:` for breaking changes.

## Type Rules

### type-case

**Condition:** Type matches specified case style

**Configuration:**
```javascript
{
  'type-case': [2, 'always', 'lower-case']
}
```

**Possible values:** Same as `body-case`

### type-empty

**Condition:** Type is empty

**Configuration:**
```javascript
{
  'type-empty': [2, 'never'] // Require type
}
```

### type-enum

**Condition:** Type is in allowed list

**Configuration:**
```javascript
{
  'type-enum': [2, 'always', [
    'feat',
    'fix',
    'docs',
    'style',
    'refactor',
    'test',
    'chore',
    'ci',
    'build',
    'revert'
  ]]
}
```

This is the most commonly customized rule. Adjust the list to match team conventions.

### type-max-length

**Condition:** Type has maximum character count

**Configuration:**
```javascript
{
  'type-max-length': [2, 'always', 15]
}
```

Default: `Infinity`

### type-min-length

**Condition:** Type has minimum character count

**Configuration:**
```javascript
{
  'type-min-length': [2, 'always', 2]
}
```

Default: `0`

## Breaking Change Rules

### breaking-change-exclamation-mark

**Condition:** Breaking change marker consistency (XNOR operation)

**Configuration:**
```javascript
{
  'breaking-change-exclamation-mark': [2, 'always']
}
```

**Behavior:**
- ✅ Pass: Both `!` in header AND `BREAKING CHANGE:` in footer
- ✅ Pass: Neither `!` nor `BREAKING CHANGE:`
- ❌ Fail: Only `!` without footer
- ❌ Fail: Only `BREAKING CHANGE:` without `!`

**Valid examples:**
```
feat!: major API change

BREAKING CHANGE: API v1 is removed
```

```
feat: minor change
```

**Invalid examples:**
```
feat!: change
(no footer with BREAKING CHANGE)
```

```
feat: change

BREAKING CHANGE: something
(no ! in header)
```

## Reference Rules

### references-empty

**Condition:** References section has at least one entry

**Configuration:**
```javascript
{
  'references-empty': [2, 'never'] // Require issue references
}
```

**Example:**
```
fix: resolve login bug

Closes #123
Fixes #456
```

## Signed-off-by Rules

### signed-off-by

**Condition:** Commit includes `Signed-off-by:` trailer

**Configuration:**
```javascript
{
  'signed-off-by': [2, 'always', 'Signed-off-by:']
}
```

**Example:**
```
feat: add feature

Signed-off-by: John Doe <john@example.com>
```

## Trailer Rules

### trailer-exists

**Condition:** Specific trailer exists in commit

**Configuration:**
```javascript
{
  'trailer-exists': [2, 'always', 'Reviewed-by:']
}
```

**Example:**
```
feat: add feature

Reviewed-by: Jane Smith <jane@example.com>
```

## Common Configuration Patterns

### Minimal Configuration

```javascript
export default {
  extends: ['@commitlint/config-conventional']
};
```

Uses all default Conventional Commits rules.

### Strict Configuration

```javascript
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'header-max-length': [2, 'always', 72],
    'body-max-line-length': [2, 'always', 100],
    'body-leading-blank': [2, 'always'],
    'footer-leading-blank': [2, 'always'],
    'scope-empty': [2, 'never'],
    'subject-case': [2, 'always', 'sentence-case'],
    'type-enum': [2, 'always', [
      'feat', 'fix', 'docs', 'style', 'refactor',
      'test', 'chore', 'ci', 'build', 'revert'
    ]]
  }
};
```

### Lenient Configuration

```javascript
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'header-max-length': [0], // Disabled
    'body-max-line-length': [0], // Disabled
    'scope-empty': [1, 'never'], // Warning only
    'subject-case': [0], // Allow any case
  }
};
```

### Monorepo Configuration

```javascript
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'scope-enum': [2, 'always', [
      'api',
      'web-app',
      'mobile-app',
      'shared-components',
      'docs',
      'infra'
    ]],
    'scope-empty': [2, 'never'], // Scope required
  }
};
```

### Custom Type Configuration

```javascript
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [2, 'always', [
      'feature',   // Instead of feat
      'bugfix',    // Instead of fix
      'hotfix',    // Critical fixes
      'docs',
      'refactor',
      'test',
      'chore',
      'release'    // Custom type
    ]]
  }
};
```

## Rule Priority and Overriding

Rules defined locally override extended configurations:

```javascript
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // This overrides the default type-enum from config-conventional
    'type-enum': [2, 'always', ['custom', 'types', 'list']]
  }
};
```

To disable a rule from an extended config:

```javascript
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'scope-case': [0] // Disable this rule completely
  }
};
```

## Debugging Rules

Test specific rules using the CLI:

```bash
# Test with verbose output
echo "feat: test message" | npx commitlint --verbose

# Test specific commit
npx commitlint --from HEAD~1 --to HEAD --verbose

# Show which rules are applied
npx commitlint --print-config
```

## Custom Rules

Create custom rules for project-specific validation:

```javascript
export default {
  extends: ['@commitlint/config-conventional'],
  plugins: [
    {
      rules: {
        'custom-rule': ({ header }) => {
          const valid = header.includes('JIRA-');
          return [
            valid,
            'Header must include JIRA ticket reference'
          ];
        }
      }
    }
  ],
  rules: {
    'custom-rule': [2, 'always']
  }
};
```

## Performance Considerations

- Disable unused rules to improve validation speed
- Use `scope-enum` and `type-enum` for faster validation than regex patterns
- Avoid complex custom rules with heavy computation
- Consider warning (`1`) instead of error (`2`) for non-critical rules

## Migration Guide

### Updating from Older Configurations

**Before (commitlint v7 and earlier):**
```javascript
module.exports = {
  rules: {
    'header-max-length': [2, 'always', 100]
  }
};
```

**After (commitlint v8+):**
```javascript
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'header-max-length': [2, 'always', 100]
  }
};
```

Key changes:
- Use ES modules (`export default`) instead of CommonJS
- Explicitly extend base configurations
- Update deprecated rule names (check changelog)
