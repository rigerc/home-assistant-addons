# Skill Writing Style Guide

Complete guide to writing effective, concise skills that pass validation and provide clear instructions.

## Scaffolding Workflow

Start by scaffolding the skill structure:

```bash
npx claude-skills-cli init --name skill-name --description "Brief description with trigger keywords" --project --with-examples
```

This creates:
```
.claude/skills/skill-name/
├── SKILL.md (template)
└── examples/ (if --with-examples)
```

**Inject latest documentation:**

Before editing, fetch current best practices:
```
!curl -s https://code.claude.com/docs/en/skills.md
```

This ensures you follow the latest official guidelines for structure, frontmatter, and progressive disclosure.

## Writing Style Fundamentals

### Imperative/Infinitive Form

Write direct, action-first instructions. Never use second person ("you should").

**Correct examples:**
```markdown
Parse the configuration file using jq.
Extract the version field from metadata.
Validate the input against the schema.
Run the validation command to check structure.
Create the directory structure before writing files.
```

**Incorrect examples:**
```markdown
You should parse the configuration file.
Claude can extract the version field.
The user might validate against the schema.
You need to run the validation command.
You'll want to create the directory first.
```

### Third-Person in Description

Frontmatter descriptions always use third person from the user's perspective.

**Correct:**
```yaml
description: This skill should be used when the user asks to "create X", "build Y", or mentions "Z concept".
```

**Incorrect:**
```yaml
description: Use this skill when you need to create X...
description: Load when I want to build Y...
description: Helps you with Z concept...
description: You can use this for creating X...
```

### Action-Oriented Language

Focus on what to do, not on who does it or how they feel about it.

**Correct:**
```markdown
Check file existence before reading.
Validate input format matches schema.
Handle errors by logging details and exiting with status 1.
```

**Incorrect:**
```markdown
You can check if the file exists before you read it.
It would be good to validate that the input format is correct.
Consider handling errors gracefully.
```

## Description Writing

### Structure Formula

```
This skill should be used when the user asks to "[phrase1]", "[phrase2]", "[phrase3]", or mentions "[concept]".
```

### Trigger Phrases

Choose phrases users would actually say:

**Good phrases:**
- "create a hook" (common request)
- "add error handling" (specific action)
- "validate configuration" (clear intent)
- "generate migration file" (exact workflow)

**Bad phrases:**
- "work with hooks" (vague)
- "do error stuff" (informal, unclear)
- "check things" (non-specific)
- "manage databases" (too broad)

### Gerunds in Descriptions

Use gerunds (-ing forms) for ongoing or conceptual actions:

```yaml
# Good
description: This skill should be used when the user asks to "create a skill", or mentions "building skills", "generating capabilities", or "scaffolding projects".

# Context keywords with gerunds: building, generating, scaffolding
```

### Character Limits

**Target: <200 characters** (~30 tokens)

Techniques to reduce length:
1. Combine similar phrases with slashes: "create/add/generate"
2. Use abbreviations: "config" vs "configuration"
3. Remove unnecessary words: "is used" → "triggers"
4. Condense concepts: "hook events (PreToolUse, PostToolUse)" instead of listing separately

**Example optimization:**
```yaml
# 247 chars - TOO LONG
description: This skill should be used when the user asks to "create a database migration", "run a database migration", "rollback a database migration", "generate a new migration file", or mentions database schema changes or updates.

# 171 chars - OPTIMIZED
description: This skill should be used when the user asks to "create/run/rollback migration", "generate migration file", or mentions database schema changes.
```

## Body Structure

### Section Organization

**Essential sections (3-5 total):**

1. **Purpose** - What the skill accomplishes (50-100 words)
2. **Core Workflow** - Step-by-step instructions (400-600 words)
3. **References/Examples** - Pointers to supporting files (100-200 words)
4. **Common Mistakes** OR **Best Practices** (100-200 words)
5. **Templates** (optional, 100-200 words)

### Section Headers

Use clear, action-oriented headers:

**Good:**
```markdown
## Core Workflow
## Validation Steps
## Common Mistakes
## References
```

**Avoid:**
```markdown
## How to Use This Skill
## Things to Know
## Other Information
## Additional Content
```

### Workflow Steps

Number steps and use imperative verbs:

```markdown
## Core Workflow

### Step 1: Gather Requirements

Ask targeted questions about functionality needs.
Identify specific trigger phrases from user examples.

### Step 2: Plan Structure

Determine required resources (scripts, references, examples).
Create only directories actually needed.

### Step 3: Write SKILL.md

Use frontmatter with description <200 chars.
Keep body content <50 lines (default validation).
```

### Code Block Usage

**Optimal: 1-2 code blocks**

Show syntax and minimal examples only. Move full examples to `examples/`.

**Good (2 blocks):**
```markdown
## Core Workflow

### Step 1: Write Frontmatter

\`\`\`yaml
---
name: skill-name
description: This skill should be used when...
version: 0.1.0
---
\`\`\`

### Step 2: Validate

\`\`\`bash
npx claude-skills-cli validate .claude/skills/my-skill --loose
\`\`\`
```

**Too many (5+ blocks):**
```markdown
# Multiple variations of frontmatter
# Multiple command examples
# Multiple validation outputs
# Full script implementations
# Complete configuration files

Move these to references/ and examples/
```

## Progressive Disclosure

### What Stays in SKILL.md

**Keep (always loaded):**
- Overview and purpose
- Essential workflow steps
- Quick reference pointers
- Most common use cases
- Validation instructions

**Total: 50-150 lines, <1000 words**

### What Moves to References

**Move (loaded as needed):**
- Detailed pattern guides
- Comprehensive API documentation
- Troubleshooting guides
- Edge cases and advanced techniques
- Historical context
- Long explanations

**Files can be 2000-5000+ words each**

### Linking Strategy

Always reference supporting files in SKILL.md:

```markdown
## References

Detailed documentation in supporting files:
- **`references/patterns.md`** - Common patterns and techniques
- **`references/api-reference.md`** - Complete API documentation
- **`references/troubleshooting.md`** - Error handling and debugging

## Examples

Working code in examples directory:
- **`examples/basic.sh`** - Simple usage example
- **`examples/advanced.sh`** - Complex scenario with error handling
```

This tells Claude:
1. These files exist
2. What they contain
3. When to load them

## Line Reduction Techniques

### 1. Combine Short Sections

**Before (12 lines):**
```markdown
## Step 1

First step instructions.

## Step 2

Second step instructions.

## Step 3

Third step instructions.
```

**After (6 lines):**
```markdown
## Core Steps

1. First step instructions
2. Second step instructions
3. Third step instructions
```

### 2. Use Lists Instead of Paragraphs

**Before (8 lines):**
```markdown
You should start by reading the documentation.
Then validate your input format.
After that, run the transformation script.
Finally, check the output for errors.
```

**After (4 lines):**
```markdown
1. Read documentation
2. Validate input format
3. Run transformation script
4. Check output for errors
```

### 3. Condense Examples

**Before (15 lines):**
```markdown
## Example Configuration

Here is an example of a basic configuration file:

\`\`\`yaml
name: my-skill
description: This is my skill
version: 1.0.0
\`\`\`

As you can see, it includes the name, description, and version.
```

**After (6 lines):**
```markdown
## Example Configuration

\`\`\`yaml
name: my-skill
description: Brief description
version: 1.0.0
\`\`\`
```

### 4. Move Explanations to References

**Before (in SKILL.md, 25 lines):**
```markdown
## Understanding Hooks

Hooks are event-driven functions that execute at specific times...
[20 more lines of explanation]
```

**After (in SKILL.md, 3 lines):**
```markdown
## References

- **`references/hooks-explained.md`** - Complete hook system documentation
```

**In references/hooks-explained.md (25+ lines):**
```markdown
# Understanding Hooks

Hooks are event-driven functions that execute at specific times...
[Complete detailed explanation]
```

### 5. Flatten Nested Structures

**Before (10 lines):**
```markdown
## Resources

### Reference Files

#### Patterns
- patterns.md

#### API Documentation
- api-reference.md
```

**After (4 lines):**
```markdown
## References

- **`references/patterns.md`** - Common patterns
- **`references/api-reference.md`** - API documentation
```

## Common Writing Mistakes

### Mistake 1: Verbose Descriptions

❌ **Too verbose (312 chars):**
```yaml
description: This skill should be used when the user asks to "create a skill", "generate a skill", "build a new skill", "make a skill for Claude Code", "scaffold a skill", "design a skill", "implement a skill", or wants to create reusable Claude Code capabilities with proper structure and documentation.
```

✅ **Concise (171 chars):**
```yaml
description: This skill should be used when the user asks to "create a skill", "generate a skill", "build a new skill", or wants to create reusable Claude Code capabilities.
```

### Mistake 2: Using Second Person

❌ **Second person:**
```markdown
You should start by reading the configuration file.
You need to validate your input before processing.
You can use the validation script to check errors.
```

✅ **Imperative:**
```markdown
Start by reading the configuration file.
Validate input before processing.
Use the validation script to check errors.
```

### Mistake 3: Bloated SKILL.md

❌ **Everything inline:**
```markdown
# SKILL.md (500 lines)

## Purpose
[...]

## Detailed Patterns
[150 lines of patterns]

## Complete API Reference
[200 lines of API docs]

## Troubleshooting Guide
[100 lines of debugging]
```

✅ **Progressive disclosure:**
```markdown
# SKILL.md (50 lines)

## Purpose
[...]

## Core Workflow
[...]

## References
- **`references/patterns.md`** - Detailed patterns
- **`references/api-reference.md`** - Complete API reference
- **`references/troubleshooting.md`** - Debugging guide
```

### Mistake 4: Non-Specific Triggers

❌ **Vague:**
```yaml
description: Helps with database tasks.
description: Use for automation needs.
description: Assists with configurations.
```

✅ **Specific:**
```yaml
description: This skill should be used when the user asks to "run migration", "rollback database", or mentions schema changes.
description: This skill should be used when the user asks to "create a hook", "automate validation", or mentions event-driven workflows.
description: This skill should be used when the user asks to "generate config", "validate YAML", or mentions configuration management.
```

### Mistake 5: Too Many Code Blocks

❌ **Excessive (7 blocks):**
```markdown
Basic example:
\`\`\`yaml
[...]
\`\`\`

Advanced example:
\`\`\`yaml
[...]
\`\`\`

Alternative format:
\`\`\`yaml
[...]
\`\`\`

[4 more blocks...]
```

✅ **Minimal (2 blocks):**
```markdown
Basic configuration:
\`\`\`yaml
name: skill-name
description: Brief description
\`\`\`

Validation:
\`\`\`bash
npx claude-skills-cli validate .claude/skills/my-skill
\`\`\`

See `examples/` for complete configurations.
```

## Templates

### Minimal Skill (Knowledge-Only)

```markdown
---
name: concept-explainer
description: This skill should be used when the user asks to "explain X", "describe Y", or mentions "Z concept".
version: 0.1.0
---

# Concept Explainer

Brief description of skill purpose.

## Purpose

Explain what this skill accomplishes in 2-3 sentences.

## Key Concepts

### Concept 1

Brief explanation.

### Concept 2

Brief explanation.

### Concept 3

Brief explanation.

## When to Apply

- Scenario 1
- Scenario 2
- Scenario 3
```

### Standard Skill (With Resources)

```markdown
---
name: workflow-automation
description: This skill should be used when the user asks to "automate X", "create workflow for Y", or mentions "Z process".
version: 0.1.0
---

# Workflow Automation

Brief description of skill purpose.

## Purpose

What this skill accomplishes in 2-3 sentences.

## Core Workflow

### Step 1: Action

Imperative instructions.

### Step 2: Action

Imperative instructions.

### Step 3: Action

Imperative instructions.

## Validation

\`\`\`bash
npx claude-skills-cli validate .claude/skills/workflow-automation --loose
\`\`\`

## References

Supporting documentation:
- **`references/patterns.md`** - Detailed patterns
- **`references/advanced.md`** - Advanced techniques

Working examples:
- **`examples/basic.sh`** - Simple workflow
- **`examples/advanced.sh`** - Complex workflow
```

## Validation Checklist

Before finalizing skill content:

**Writing Style:**
- [ ] All instructions use imperative/infinitive form
- [ ] No second person ("you", "your")
- [ ] Description uses third person
- [ ] Action-oriented language throughout

**Description:**
- [ ] <200 characters
- [ ] 3-5 specific trigger phrases
- [ ] Includes gerunds for conceptual triggers
- [ ] Keywords align with content

**Body:**
- [ ] 50-150 lines total
- [ ] <1000 words
- [ ] 3-5 clear sections
- [ ] 1-2 code blocks maximum

**Progressive Disclosure:**
- [ ] Core workflow in SKILL.md
- [ ] Detailed docs in references/
- [ ] Examples properly referenced
- [ ] All references mentioned in SKILL.md

**Line Optimization:**
- [ ] Short sections combined
- [ ] Lists used instead of paragraphs
- [ ] Examples condensed
- [ ] Explanations moved to references

## Summary

Effective skill writing requires:

1. **Imperative form** - Direct, action-first instructions
2. **Third-person descriptions** - "when the user asks to"
3. **Concise triggers** - Specific phrases <200 chars
4. **Lean body** - 50-150 lines with 1-2 code blocks
5. **Progressive disclosure** - Details in references/
6. **Clear references** - Always mention supporting files

Follow these guidelines to create skills that validate cleanly and provide focused, actionable instructions.
