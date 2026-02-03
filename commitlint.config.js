module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // Enforce that a scope is always present
    'scope-empty': [2, 'never'],

    // Optional but commonly paired with strict scope enforcement
    'scope-case': [2, 'always', 'kebab-case'],
  },
};