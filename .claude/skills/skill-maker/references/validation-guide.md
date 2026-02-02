# Claude Skills CLI Validation Guide

Complete guide to passing claude-skills-cli validation checks for high-quality skills.

## Scaffolding Skills

Use the CLI to scaffold skill structure automatically:

```bash
npx claude-skills-cli init --name [skill-name] --description "Brief description with trigger keywords" --project --with-examples
```

**Flags explained:**
- `--name` - Skill name in kebab-case
- `--description` - Short trigger-rich description
- `--project` - Create in `.claude/skills/` (project-specific)
- `--with-examples` - Generate example files in examples/

**After scaffolding:**
1. Fetch latest docs: `curl -s https://code.claude.com/docs/en/skills.md`
2. Edit SKILL.md to match validation requirements
3. Add detailed content to references/
4. Validate: `npx claude-skills-cli validate .claude/skills/[skill-name] --loose`

## Validation Levels

The claude-skills-cli validates skills at three strictness levels:

- **Default** - Strict checks (50 line max)
- **--lenient** - Moderate checks (150 line max)
- **--loose** - Practical checks (500 line max) - **RECOMMENDED TARGET**

**Use --loose validation** for all skills. It provides sufficient quality checks while allowing practical skill development without excessive optimization.

## Validation Command

```bash
npx claude-skills-cli validate .claude/skills/skill-name --loose
```

## Structure & Format Checks

### Name Format
- Must use kebab-case: `skill-name`, not `skill_name` or `SkillName`
- Directory name must match skill name in frontmatter
- No spaces, underscores, or capitals

**Example:**
```
✅ .claude/skills/database-migration/
   SKILL.md with name: database-migration

❌ .claude/skills/database_migration/
   SKILL.md with name: DatabaseMigration
```

### YAML Frontmatter
- Must be valid YAML
- Must start and end with `---`
- No syntax errors

**Example:**
```yaml
---
name: skill-name
description: This skill should be used when...
version: 0.1.0
---
```

### Required Fields
- `name` - Required, matches directory
- `description` - Required, <200 chars optimal
- `version` - Optional but recommended

## Level 1: Metadata Validation

### Description Length
- **Optimal:** <200 characters (~30 tokens)
- **Maximum:** 280 characters
- Concise descriptions load faster and are more effective

**Good examples:**
```yaml
# 186 chars
description: This skill should be used when the user asks to "create a hook", "add a PreToolUse hook", "validate tool use", or mentions hook events (PreToolUse, PostToolUse, Stop).

# 171 chars
description: This skill should be used when the user asks to "create a skill", "generate a skill", "build a new skill", or wants to create reusable Claude Code capabilities.
```

**Too long:**
```yaml
# 312 chars - TOO VERBOSE
description: This skill should be used when the user asks to "create a skill", "generate a skill", "build a new skill", "make a skill for Claude Code", "scaffold a skill", "design a skill", "implement a skill", or wants to create reusable Claude Code capabilities with proper structure and documentation.
```

### Trigger Phrase Presence
- Must include 3-5 specific trigger phrases
- Phrases should be actual user queries
- Use quotes around phrases: `"create X"`, `"build Y"`

**Good:**
```yaml
description: This skill should be used when the user asks to "run migration", "rollback database", "generate migration file", or mentions database schema changes.
```

**Bad:**
```yaml
description: Use for database operations.  # No specific triggers
description: Helps with migrations.  # Vague
```

### User Phrasing (Third-Person)
- Must use third-person: "when the user asks to"
- Action-oriented with gerunds: "creating", "building", "running"
- Not "you" or "I" perspective

**Correct:**
```yaml
description: This skill should be used when the user asks to "create X"...
description: Use when the user mentions "building Y"...
```

**Incorrect:**
```yaml
description: Use this skill when you want to create X...
description: Load when I need to build Y...
description: Helps you with Z...
```

### Keyword Richness
- Include domain-specific terms
- Align keywords with SKILL.md content
- Use technical vocabulary users would say

**Good:**
```yaml
description: This skill should be used when the user asks to "create a hook", "add a PreToolUse hook", "validate tool use", or mentions hook events (PreToolUse, PostToolUse, Stop).
# Keywords: hook, PreToolUse, validate, tool use, events
```

**Bad:**
```yaml
description: This skill helps with automation tasks.
# Keywords: automation, tasks (too generic)
```

## Level 2: SKILL.md Body Validation

### Line Count Limits
- **--loose (RECOMMENDED):** 500 lines max
- --lenient: 150 lines max (optional stricter target)
- Default: 50 lines max (optional strictest target)

Lines are counted from first line after frontmatter to end of file.

**Target 500 lines maximum** with --loose validation. This provides enough space for:
- Comprehensive workflow documentation
- Essential examples and code snippets
- Common mistakes and best practices
- References to supporting files

**If approaching 500 lines:**
- Move detailed patterns to references/
- Consolidate repetitive sections
- Move extensive code examples to examples/
- Keep core workflow focused
- If there are many reference files, make a `references/index.md` file with a index of all files, and then include it in the SKILL.md's reference section using `@references/index.md`.

### Word Count
- **Optimal:** <1000 words
- **Acceptable:** 1000-2000 words
- **Maximum:** 3000 words

Word count includes all markdown content except frontmatter.

**Distribution:**
- Purpose: 50-100 words
- Core Workflow: 400-600 words
- References section: 100-200 words
- Common Mistakes: 100-200 words
- Templates: 100-200 words

### Token Estimate
- **Budget:** <6500 tokens total
- Roughly 0.75 words per token
- Validation may warn if approaching limit

### Code Blocks
- **Optimal:** 1-2 code blocks
- **Maximum:** 5 code blocks
- Keep examples minimal and focused
- Move extensive code to examples/

**Good:**
```markdown
## Core Workflow

### Step 1: Create Configuration

\`\`\`yaml
name: my-skill
description: Brief description
\`\`\`

### Step 2: Validate

Run validation:
\`\`\`bash
npx claude-skills-cli validate .claude/skills/my-skill
\`\`\`
```

**Too many:**
```markdown
# 8 code blocks showing every possible variation
# Move most to examples/ or references/
```

### Sections
- **Recommended:** 3-5 sections
- Use clear level-2 headers (`##`)
- Logical organization

**Standard sections:**
1. Purpose
2. Core Workflow (with subsections)
3. Common Mistakes or Best Practices
4. References
5. Templates (optional)

## Level 3: References Validation

### Referenced Files Exist
- All files mentioned in SKILL.md must exist
- Use exact paths relative to skill directory
- Check spelling and case sensitivity

**SKILL.md example:**
```markdown
## References

- **`references/patterns.md`** - Detailed patterns
- **`examples/basic.sh`** - Working example
```

**Validate these exist:**
```bash
ls .claude/skills/skill-name/references/patterns.md
ls .claude/skills/skill-name/examples/basic.sh
```

### No Orphaned Files
- All files in skill directory should be referenced
- Remove unused files before validation
- Common orphans: old backups, test files, drafts

**Check for orphans:**
```bash
# List all files
find .claude/skills/skill-name -type f

# Ensure each is referenced in SKILL.md or intentional
```

### Nesting Depth
- Keep directory nesting shallow
- **Optimal:** 2 levels max (skill-name/references/file.md)
- **Acceptable:** 3 levels (skill-name/examples/category/file.sh)
- Avoid deep nesting for simplicity

**Good:**
```
skill-name/
├── SKILL.md
├── references/
│   ├── patterns.md
│   └── advanced.md
└── examples/
    └── basic.sh
```

**Avoid:**
```
skill-name/
├── SKILL.md
└── docs/
    └── detailed/
        └── subcategory/
            └── nested/
                └── file.md  # Too deep
```

### Progressive Disclosure Structure
- SKILL.md: Core concepts only
- references/: Detailed documentation
- examples/: Working code
- scripts/: Utilities

**Proper disclosure:**
```
skill-name/
├── SKILL.md (50 lines, core workflow)
├── references/
│   ├── patterns.md (2000+ words, detailed)
│   └── api-reference.md (3000+ words, comprehensive)
└── examples/
    └── complete-example.sh (working code)
```

## Validation Checklist

Before running validation:

**Structure:**
- [ ] Directory name is kebab-case
- [ ] Directory name matches frontmatter name
- [ ] Valid YAML frontmatter
- [ ] Required fields present (name, description)

**Metadata (Level 1):**
- [ ] Description <200 chars
- [ ] 3-5 specific trigger phrases with quotes
- [ ] Third-person phrasing with gerunds
- [ ] Keyword-rich and aligned with content

**Body (Level 2 - --loose targets):**
- [ ] Line count ≤500 lines
- [ ] Word count <3000 (aim for <1000)
- [ ] Code blocks reasonable (1-2 optimal, 5 max)
- [ ] Sections organized (3-5 recommended)
- [ ] Imperative writing style
- [ ] Quick Start section included

**References (Level 3):**
- [ ] All referenced files exist
- [ ] No orphaned files
- [ ] Shallow nesting (2-3 levels max)
- [ ] Progressive disclosure applied

## Common Validation Errors

### Error: Directory name doesn't match skill name
```
❌ Directory: .claude/skills/database_migration/
   Frontmatter: name: database-migration
```

**Fix:** Rename directory to match:
```bash
mv .claude/skills/database_migration .claude/skills/database-migration
```

### Error: Description too long
```
❌ description: This skill should be used when the user asks to "create a database migration", "run a database migration", "rollback a database migration", "generate a new migration file", "validate migration files", "check migration status", or mentions database schema changes, database migrations, or schema updates.
# 324 characters
```

**Fix:** Condense to essential triggers:
```yaml
✅ description: This skill should be used when the user asks to "run migration", "rollback migration", "generate migration file", or mentions database schema changes.
# 171 characters
```

### Error: Missing trigger phrases
```
❌ description: This skill helps with database operations.
```

**Fix:** Add specific phrases:
```yaml
✅ description: This skill should be used when the user asks to "query database", "run SQL", "manage schema", or mentions database operations.
```

### Error: Body exceeds line limit
```
❌ SKILL.md: 287 lines (default limit: 50)
```

**Fix:** Move content to references:
```markdown
✅ SKILL.md: 48 lines (core workflow only)
   references/patterns.md: 150 lines (detailed patterns)
   references/advanced.md: 89 lines (advanced techniques)
```

### Error: Referenced file not found
```
❌ SKILL.md references: references/patterns.md
   File doesn't exist
```

**Fix:** Create the file or remove reference:
```bash
touch .claude/skills/skill-name/references/patterns.md
# OR remove the reference from SKILL.md
```

### Error: Orphaned files detected
```
❌ Found: references/old-draft.md
   Not referenced in SKILL.md
```

**Fix:** Remove or reference the file:
```bash
rm references/old-draft.md
# OR add reference in SKILL.md
```

## Optimization Tips

### Condense Description
Use abbreviations and combine similar phrases:
```yaml
❌ "create a hook", "add a hook", "generate a hook", "make a hook"

✅ "create/add hook", "generate hook"
```

### Reduce Line Count
Combine short sections, use lists instead of paragraphs:
```markdown
❌ ## Step 1
   Do this first.

   ## Step 2
   Then do this.

   ## Step 3
   Finally do this.

✅ ## Core Steps
   1. Do this first
   2. Then do this
   3. Finally do this
```

### Limit Code Blocks
Show syntax, not full examples:
```markdown
❌ Three complete working examples inline

✅ One syntax example, reference examples/:
   See `examples/complete.sh` for full implementation
```

### Shallow Structure
Flatten nested directories:
```bash
❌ references/patterns/authentication/oauth2.md

✅ references/oauth2-patterns.md
```

## Running Validation

Always validate with --loose flag:

```bash
npx claude-skills-cli validate .claude/skills/my-skill --loose
```

Fix all errors (❌) before considering the skill complete. Address warnings (⚠️) and recommendations to improve quality.

## Validation Report Interpretation

The validator will output:
- ✅ Passed checks
- ⚠️ Warnings (non-blocking)
- ❌ Errors (must fix)

**Example output:**
```
✅ Structure & Format
✅ YAML frontmatter valid
✅ Required fields present

⚠️ Description is 215 chars (optimal: <200)
✅ Trigger phrases present
✅ Third-person phrasing

✅ Line count: 142 (limit: 150)
⚠️ Word count: 1,247 (optimal: <1000)
✅ Code blocks: 2
✅ Sections: 4

✅ All referenced files exist
✅ No orphaned files
✅ Nesting depth: 2
```

**Action items:**
- **Fix all ❌ errors** - Required for validation to pass
- **Address ⚠️ warnings** - Strongly recommended improvements
- ✅ items are good - No action needed

## Handling Warnings and Recommendations

Warnings indicate quality improvements that should be addressed:

### Common Warnings

**⚠️ Description is 215 chars (optimal: <200)**
- **Fix:** Condense trigger phrases or use abbreviations
- **Example:** Change "create/add/generate/make hook" to "create/add hook"

**⚠️ Word count: 1,247 (optimal: <1000)**
- **Fix:** Move detailed content to references/
- Identify repetitive sections to consolidate
- Move examples to examples/ directory

**⚠️ SKILL.md contains 6 code examples (recommended: 1-2)**
- **Fix:** Keep 1-2 essential examples in SKILL.md
- Move others to examples/ or references/
- Reference them in SKILL.md

**⚠️ SKILL.md contains 27 sections (recommended: 3-5)**
- **Fix:** Consolidate related sections
- Use subsections (###) instead of top-level sections (##)
- Move detailed breakdowns to references/

**⚠️ Missing "## Quick Start" section**
- **Fix:** Add a Quick Start section with minimal working example
- Keep it brief (3-5 lines showing basic usage)

**⚠️ Description missing trigger keywords ('Use when...', 'Use for...', 'Use to...')**
- **Fix:** Start description with "Use when" or "This skill should be used when"
- Makes triggering more explicit

**⚠️ Description contains long lists (5 commas, 212 chars)**
- **Fix:** Reduce number of trigger phrases to 3-5 most important ones
- Move comprehensive trigger list to SKILL.md body if needed

### When to Address Warnings

**Always fix:**
- Missing trigger keywords (impacts discoverability)
- Excessive code blocks (bloats context)
- Missing Quick Start (reduces clarity)

**Usually fix:**
- Description length >200 chars (performance impact)
- Word count significantly over 1000 (context efficiency)
- Too many sections (organization issue)

**Optional to fix:**
- Minor overages (205 chars, 1050 words)
- Recommendations that don't apply to your skill's nature
- Style preferences that conflict with skill requirements

## Summary

The claude-skills-cli validates:
1. **Structure** - Naming, format, frontmatter
2. **Metadata** - Description quality and triggers
3. **Body** - Length, organization, code blocks
4. **References** - File existence, structure, disclosure

Pass --loose validation by:
- Keep descriptions <200 chars with specific triggers
- Limit SKILL.md to 500 lines maximum
- Move extensive details to references/
- Reference all files properly in SKILL.md
- Use progressive disclosure (core in SKILL.md, details in references/)
- Fix all errors (❌) and address warnings (⚠️)

**Recommended workflow:**
1. Scaffold: `npx claude-skills-cli init --name [skill-name] --description "..." --project --with-examples`
2. Edit SKILL.md with validation targets in mind
3. Create references/ for detailed content
4. Validate: `npx claude-skills-cli validate .claude/skills/[skill-name] --loose`
5. Fix errors and address warnings
6. Re-validate until passing

Always run --loose validation before considering a skill complete.
