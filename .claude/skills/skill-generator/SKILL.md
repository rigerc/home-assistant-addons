---
name: skill-generator
description: This skill should be used when the user asks to "create a skill", "generate a skill", "build a new skill", "make a skill for Claude Code", or wants to create reusable Claude Code capabilities. Generates well-structured skills using the latest official documentation.
version: 0.1.0
allowed-tools: Read, Grep, Write, Bash, Edit
---

# Skill Generator for Claude Code

This skill provides a systematic approach to creating high-quality Claude Code skills by fetching the latest official documentation and applying best practices.

## Purpose

Generate well-structured, production-ready Claude Code skills that follow official standards, use progressive disclosure, and include proper trigger phrases. The skill ensures consistency with the latest Claude Code documentation by fetching it at runtime.

## When to Use This Skill

Use this skill when:
- The user requests creation of a new skill ("create a skill for X")
- Generating a skill to automate repetitive tasks
- Building domain-specific capabilities for Claude Code
- Converting workflows into reusable skills
- The user wants a skill that follows current best practices

## Core Workflow

### Step 1: Latest Documentation

!`curl -s https://code.claude.com/docs/en/skills.md`

Read and internalize this documentation to ensure the generated skill follows current best practices, structure requirements, and writing conventions.

### Step 2: Understand Requirements

Gather concrete examples of how the skill will be used:

**Essential questions:**
- What functionality should this skill provide?
- What would a user say to trigger this skill? (Need specific phrases)
- Can you provide 2-3 example queries this skill should handle?
- What workflows or tasks should this skill automate?

**Example dialogue:**
```
User: "Create a skill for database migrations"

Ask: "What specific tasks should the database migration skill handle?
For example:
- 'Run the latest migration'
- 'Rollback the last migration'
- 'Generate a new migration file'

What else should it support?"
```

Do not overwhelm with too many questions at once. Start with the most critical ones.

### Step 3: Plan Reusable Resources

Analyze the examples to identify what resources the skill needs:

**Scripts (`scripts/`)** - Create when:
- The same code is rewritten repeatedly
- Deterministic execution is required
- Complex operations need reliability
- Example: `scripts/validate_schema.sh`, `scripts/run_migration.py`

**References (`references/`)** - Create when:
- Detailed documentation would bloat SKILL.md
- Domain knowledge needs to be referenced selectively
- API specs, schemas, or patterns are needed
- Target: Reference files can be 2,000-5,000+ words
- Example: `references/api-reference.md`, `references/patterns.md`

**Examples (`examples/`)** - Create when:
- Working code examples help users understand
- Configuration templates are needed
- Real-world usage examples clarify the workflow
- Example: `examples/basic-hook.sh`, `examples/config.yaml`

**Assets (`assets/`)** - Create when:
- Files will be used in output (templates, images, fonts)
- Boilerplate code needs to be copied
- Not loaded into context, but used directly
- Example: `assets/template.html`, `assets/logo.png`

### Step 4: Create Directory Structure

Create only the directories actually needed:

```bash
mkdir -p ./skills/[skill-name]/{references,examples,scripts}
```

Delete unnecessary directories. If no scripts are needed, don't create `scripts/`.

### Step 5: Write SKILL.md

#### Frontmatter Requirements

**Critical:** The description determines when Claude loads the skill. Include specific trigger phrases users would actually say.

```yaml
---
name: skill-name
description: This skill should be used when the user asks to "specific phrase 1", "specific phrase 2", "specific phrase 3", or mentions "key concept". Be concrete and specific about triggers.
version: 0.1.0
---
```

**Good trigger examples:**
```yaml
description: This skill should be used when the user asks to "create a hook", "add a PreToolUse hook", "validate tool use", or mentions hook events (PreToolUse, PostToolUse, Stop).
```

**Bad trigger examples:**
```yaml
description: Use this skill when working with hooks.  # Wrong person, vague
description: Provides hook guidance.  # No specific triggers
description: Helper for hooks.  # Generic, no user queries
```

#### Body Content (1,500-2,000 words ideal, <3,000 max)

Use **imperative/infinitive form** throughout (verb-first instructions):

**Correct:**
```
To create a migration, run the generation script.
Validate the schema before applying changes.
Check for pending migrations first.
```

**Incorrect:**
```
You should create a migration by running...
You need to validate the schema...
Users can check for pending migrations...
```

**Essential sections:**

1. **Purpose** (2-3 sentences) - What the skill does
2. **When to Use This Skill** - Specific scenarios
3. **Core Workflow** - Step-by-step procedures
4. **Additional Resources** - Point to references/examples/scripts

**Example structure:**

```markdown
## Purpose

[Brief description of what the skill accomplishes]

## When to Use This Skill

Use this skill when:
- [Scenario 1]
- [Scenario 2]
- [Scenario 3]

## Core Workflow

### Step 1: [Action]

[Instructions in imperative form]

### Step 2: [Action]

[Instructions in imperative form]

## Additional Resources

### Reference Files

For detailed information, consult:
- **`references/patterns.md`** - Common patterns and best practices
- **`references/api-reference.md`** - Complete API documentation

### Example Files

Working examples in `examples/`:
- **`examples/basic-usage.sh`** - Simple use case
- **`examples/advanced-usage.sh`** - Complex scenario

### Scripts

Utility scripts in `scripts/`:
- **`scripts/validate.sh`** - Validation helper
- **`scripts/setup.sh`** - Setup automation
```

#### Keep SKILL.md Lean

Move detailed content to `references/`:
- Long pattern guides → `references/patterns.md`
- API documentation → `references/api-reference.md`
- Advanced techniques → `references/advanced.md`
- Troubleshooting guides → `references/troubleshooting.md`

Reference these files in SKILL.md so Claude knows they exist and can load them as needed.

### Step 6: Create Supporting Resources

#### References Files

Create detailed documentation that would bloat SKILL.md:

```bash
# Example: references/patterns.md
# Include comprehensive patterns, edge cases, detailed examples
# Can be 2,000-5,000+ words
```

Use imperative form in references as well. These files provide depth without bloating the core skill.

#### Example Files

Create complete, working examples:

```bash
# Example: examples/basic-migration.sh
#!/bin/bash
# Working example showing typical usage
```

Ensure examples are:
- Complete and runnable
- Well-commented
- Demonstrate real use cases
- Include error handling

#### Script Files

Create executable utilities:

```bash
# Example: scripts/validate-schema.sh
#!/bin/bash
# Validation utility for schema files
```

Scripts should be:
- Executable (`chmod +x`)
- Well-documented with usage instructions
- Handle errors gracefully
- Accept standard inputs

### Step 7: Validate the Skill

**Structure validation:**
- [ ] SKILL.md exists with valid YAML frontmatter
- [ ] Frontmatter has `name` and `description`
- [ ] Description uses third person with specific triggers
- [ ] Body uses imperative/infinitive form (not second person)
- [ ] Body length is reasonable (1,500-2,000 words ideal)
- [ ] All referenced files actually exist

**Content validation:**
- [ ] Trigger phrases are specific user queries
- [ ] Instructions are clear and actionable
- [ ] Progressive disclosure applied (details in references/)
- [ ] Examples are complete and working
- [ ] Scripts are executable and documented

**Test the skill:**
1. Check that trigger phrases match user queries
2. Verify references load when needed
3. Test examples execute correctly
4. Validate scripts work as expected

## Progressive Disclosure Strategy

### What Goes Where

**SKILL.md (always loaded when triggered):**
- Core concepts and overview (200-400 words)
- Essential workflow steps (400-800 words)
- Quick reference to resources (200-300 words)
- Most common use cases (400-600 words)
- **Total: 1,500-2,000 words**

**references/ (loaded as needed by Claude):**
- Detailed patterns and techniques (2,000+ words per file)
- Comprehensive API documentation
- Migration guides
- Edge cases and troubleshooting
- Advanced scenarios

**examples/ (loaded when needed):**
- Complete working code
- Configuration templates
- Real-world usage examples

**scripts/ (may execute without loading):**
- Validation utilities
- Setup automation
- Testing helpers

## Writing Style Rules

### Imperative/Infinitive Form Only

Write direct instructions, not suggestions:

**Correct:**
```
Parse the configuration file using jq.
Extract the version field.
Validate the semver format.
```

**Incorrect:**
```
You should parse the configuration file.
Claude can extract the version field.
The user might validate the semver format.
```

### Third-Person in Description

Frontmatter description must use third person:

**Correct:**
```yaml
description: This skill should be used when the user asks to "create X", "build Y", or mentions "Z concept".
```

**Incorrect:**
```yaml
description: Use this skill when you need to create X...
description: Load when creating X...
```

### Objective Instructional Language

Focus on actions, not actors:

**Correct:**
```
Check the file exists before reading.
Validate input format matches expected schema.
Handle errors by logging and exiting gracefully.
```

**Incorrect:**
```
You can check if the file exists.
Claude should validate the input format.
Users might want to handle errors.
```

## Common Mistakes to Avoid

### Mistake 1: Vague Trigger Description

❌ **Bad:**
```yaml
description: Helps with creating skills.
```

**Why:** No specific triggers, not third person, vague

✅ **Good:**
```yaml
description: This skill should be used when the user asks to "create a skill", "generate a new skill", "build a skill for X", or wants to create reusable Claude Code capabilities.
```

**Why:** Third person, specific phrases, concrete scenarios

### Mistake 2: Everything in SKILL.md

❌ **Bad:**
```
skill-name/
└── SKILL.md (6,000 words)
```

**Why:** Bloats context, no progressive disclosure

✅ **Good:**
```
skill-name/
├── SKILL.md (1,800 words)
└── references/
    ├── patterns.md (2,500 words)
    └── api-reference.md (3,000 words)
```

**Why:** Core in SKILL.md, details load as needed

### Mistake 3: Using Second Person

❌ **Bad:**
```
You should start by reading the docs.
You need to validate the input.
You can use the grep tool.
```

**Why:** Second person instead of imperative

✅ **Good:**
```
Start by reading the documentation.
Validate the input before processing.
Use the grep tool to search.
```

**Why:** Imperative form, direct instructions

### Mistake 4: Missing Resource References

❌ **Bad:**
```markdown
# SKILL.md

[Content about using the skill]

[No mention of references/ or examples/]
```

**Why:** Claude doesn't know resources exist

✅ **Good:**
```markdown
# SKILL.md

[Content]

## Additional Resources

### Reference Files
- **`references/patterns.md`** - Detailed patterns
- **`references/api-reference.md`** - Complete API docs

### Examples
- **`examples/basic.sh`** - Simple example
- **`examples/advanced.sh`** - Complex scenario
```

**Why:** Claude knows where to find information

## Validation Checklist

Before finalizing a generated skill:

**Structure:**
- [ ] Directory named appropriately (lowercase, hyphens)
- [ ] SKILL.md has valid YAML frontmatter
- [ ] Frontmatter includes `name`, `description`, `version`
- [ ] Only needed directories created (references/, examples/, scripts/)

**Description Quality:**
- [ ] Uses third person ("This skill should be used when...")
- [ ] Includes 3-5 specific trigger phrases
- [ ] Trigger phrases are what users would actually say
- [ ] Mentions key concepts that should trigger the skill

**Content Quality:**
- [ ] Body uses imperative/infinitive form throughout
- [ ] SKILL.md is 1,500-2,000 words (max 3,000)
- [ ] Detailed content moved to references/
- [ ] Examples are complete and working
- [ ] Scripts are executable with proper permissions

**Progressive Disclosure:**
- [ ] Core concepts in SKILL.md
- [ ] Detailed docs in references/
- [ ] Working examples in examples/
- [ ] Utilities in scripts/
- [ ] SKILL.md references all resources

**Validation:**
- [ ] All referenced files exist
- [ ] No broken links or references
- [ ] Examples execute without errors
- [ ] Scripts have correct permissions

## Quick Reference Templates

### Minimal Skill Structure

```
skill-name/
└── SKILL.md
```

For simple knowledge-based skills with no complex resources.

### Standard Skill Structure (Recommended)

```
skill-name/
├── SKILL.md
├── references/
│   ├── patterns.md
│   └── api-reference.md
└── examples/
    └── basic-usage.sh
```

For most skills with detailed documentation and examples.

### Complete Skill Structure

```
skill-name/
├── SKILL.md
├── references/
│   ├── patterns.md
│   ├── advanced.md
│   └── troubleshooting.md
├── examples/
│   ├── basic.sh
│   ├── advanced.sh
│   └── config.yaml
└── scripts/
    ├── validate.sh
    └── setup.sh
```

For complex skills requiring utilities and comprehensive documentation.

## Implementation Steps Summary

To generate a skill:

1. **Fetch docs**: Run `!curl -s https://code.claude.com/docs/en/skills.md`
2. **Understand**: Ask about use cases, triggers, and requirements
3. **Plan**: Identify needed scripts/references/examples/assets
4. **Structure**: Create directory with needed subdirectories
5. **Write SKILL.md**:
   - Third-person description with specific triggers
   - Imperative-form body (1,500-2,000 words)
   - Reference supporting files
6. **Create resources**: Add references/, examples/, scripts/ as planned
7. **Validate**: Check structure, description, style, organization
8. **Test**: Verify triggers work and resources load correctly

## Additional Resources

### Example Skills to Study

Reference these skills from the plugin-dev plugin:
- `../hook-development/` - Excellent progressive disclosure
- `../agent-development/` - Strong trigger phrases
- `../mcp-integration/` - Comprehensive references
- `../plugin-settings/` - Good examples integration
- `../command-development/` - Clear critical concepts

### Reference Files

For the complete original skill-creator methodology:
- **`references/skill-creator-methodology.md`** - Full original documentation

## Best Practices

✅ **DO:**
- Fetch latest docs using `!curl` at start
- Ask clarifying questions about use cases
- Use specific trigger phrases in description
- Keep SKILL.md lean (1,500-2,000 words)
- Move details to references/
- Write in imperative form
- Create complete working examples
- Reference all supporting files
- Validate before finalizing

❌ **DON'T:**
- Skip fetching latest documentation
- Use vague trigger descriptions
- Write in second person
- Put everything in SKILL.md
- Create empty or broken examples
- Forget to reference supporting files
- Skip validation
- Assume requirements without asking
