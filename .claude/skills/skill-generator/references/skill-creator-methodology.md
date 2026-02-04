# Complete Skill Creator Methodology

This reference provides the full methodology from the original skill-creator documentation for creating high-quality Claude Code skills.

## Skills Overview

Skills are modular, self-contained packages that extend Claude's capabilities by providing specialized knowledge, workflows, and tools. They transform Claude from a general-purpose agent into a specialized agent equipped with procedural knowledge.

### What Skills Provide

1. **Specialized workflows** - Multi-step procedures for specific domains
2. **Tool integrations** - Instructions for working with specific file formats or APIs
3. **Domain expertise** - Company-specific knowledge, schemas, business logic
4. **Bundled resources** - Scripts, references, and assets for complex tasks

### Skill Anatomy

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter (name, description)
│   └── Markdown instructions
└── Bundled Resources (optional)
    ├── scripts/          - Executable code
    ├── references/       - Documentation loaded as needed
    └── assets/           - Files used in output
```

## Progressive Disclosure System

Skills use three-level loading:

1. **Metadata (name + description)** - Always in context (~100 words)
2. **SKILL.md body** - When skill triggers (<5k words, ideally 1.5-2k)
3. **Bundled resources** - As needed by Claude (unlimited)

This approach keeps the context lean while providing depth when needed.

## Detailed Creation Process

### Step 1: Understanding with Concrete Examples

Gather specific examples of how the skill will be used:

**Key questions:**
- What functionality should this skill support?
- Can you provide example queries that should trigger this skill?
- What would users say when they need this skill?
- What are the common use cases?

**Example for image-editor skill:**
- "Remove red-eye from this photo"
- "Rotate this image 90 degrees"
- "Crop this screenshot"
- "Convert PNG to JPG"

Don't overwhelm users with too many questions. Start with the most important and follow up.

### Step 2: Planning Reusable Contents

Analyze each example to identify reusable resources:

**Scripts (`scripts/`)** - When:
- Same code is rewritten repeatedly
- Deterministic execution required
- Complex operations need reliability

**References (`references/`)** - When:
- Detailed documentation would bloat SKILL.md
- Domain knowledge referenced selectively
- Schemas, APIs, or patterns needed

**Assets (`assets/`)** - When:
- Files used in output (templates, images)
- Boilerplate copied or modified
- Resources not loaded into context

**Examples:**

1. **PDF editor skill** - Needs `scripts/rotate_pdf.py` (rewriting same rotation code)
2. **Frontend builder skill** - Needs `assets/hello-world/` template (boilerplate HTML/React)
3. **BigQuery skill** - Needs `references/schema.md` (table schemas and relationships)
4. **Hooks skill** - Needs `scripts/validate-hook-schema.sh` and `references/patterns.md`

### Step 3: Create Structure

Create directory structure:

```bash
mkdir -p skills/skill-name/{references,examples,scripts}
touch skills/skill-name/SKILL.md
```

Only create directories you actually need. Delete any you don't.

### Step 4: Implement Resources

#### Scripts Implementation

Create executable utilities:

```bash
#!/bin/bash
# scripts/validate.sh
# Clear usage instructions
# Proper error handling
# Accept standard inputs
```

Make executable: `chmod +x scripts/validate.sh`

Document usage in SKILL.md:
```markdown
### Validation Script

Use `scripts/validate.sh` to validate configuration:

\`\`\`bash
./scripts/validate.sh config.yaml
\`\`\`
```

#### References Implementation

Create detailed documentation:

```markdown
# references/patterns.md

## Common Patterns

### Pattern 1: Basic Usage
[Detailed explanation - 500+ words]

### Pattern 2: Advanced Techniques
[Comprehensive guide - 800+ words]

### Pattern 3: Edge Cases
[Thorough coverage - 600+ words]
```

Reference files can be 2,000-5,000+ words. They're loaded only when Claude needs them.

#### Examples Implementation

Provide complete, working examples:

```bash
# examples/basic-usage.sh
#!/bin/bash
# Complete working example showing typical usage
# Include comments explaining each step
# Demonstrate best practices
```

```yaml
# examples/config.yaml
# Working configuration template
# Well-commented
# Shows all options
```

#### Assets Implementation

Include output resources:

```
assets/
├── templates/
│   └── page.html       # HTML boilerplate
├── styles/
│   └── base.css        # CSS template
└── images/
    └── logo.png        # Brand assets
```

### Step 5: Write SKILL.md

#### Frontmatter

```yaml
---
name: skill-name
description: This skill should be used when the user asks to "specific phrase 1", "specific phrase 2", "specific phrase 3", or mentions "key concept". Include exact trigger phrases users would say.
version: 0.1.0
---
```

**Critical:** Description determines when Claude loads the skill. Use:
- Third person ("This skill should be used when...")
- Specific user queries ("create a hook", "validate schema")
- Concrete scenarios users would mention

#### Body Content

Target 1,500-2,000 words, maximum 3,000. Use imperative/infinitive form.

**Required sections:**

```markdown
# Skill Name

Brief introduction (2-3 sentences).

## Purpose

What this skill accomplishes (1-2 paragraphs).

## When to Use This Skill

Specific scenarios:
- [Scenario 1]
- [Scenario 2]
- [Scenario 3]

## Core Workflow

### Step 1: [Action]

[Imperative instructions]

### Step 2: [Action]

[Imperative instructions]

### Step 3: [Action]

[Imperative instructions]

## Additional Resources

### Reference Files

For detailed information:
- **`references/patterns.md`** - Common patterns and techniques
- **`references/advanced.md`** - Advanced use cases

### Example Files

Working examples:
- **`examples/basic.sh`** - Simple usage
- **`examples/advanced.sh`** - Complex scenario

### Scripts

Utility scripts:
- **`scripts/validate.sh`** - Validation helper
- **`scripts/setup.sh`** - Setup automation

## Best Practices

Key recommendations for using this skill effectively.

## Common Pitfalls

What to avoid and why.
```

#### Progressive Disclosure in Practice

**Keep in SKILL.md (always loaded):**
- Core concepts overview
- Essential workflow steps
- Quick reference tables
- Pointers to resources
- Most common use cases

**Move to references/ (loaded as needed):**
- Detailed pattern guides
- Comprehensive API docs
- Migration guides
- Edge cases
- Troubleshooting
- Advanced techniques

**Result:** SKILL.md stays focused and lean, while detailed content is available when needed.

### Step 6: Validation

**Structure validation:**
```bash
# Check structure
ls -la skills/skill-name/
cat skills/skill-name/SKILL.md | head -20

# Validate YAML frontmatter
# Ensure name and description present
# Check all referenced files exist
```

**Description quality checklist:**
- [ ] Uses third person
- [ ] Contains 3-5 specific trigger phrases
- [ ] Trigger phrases are realistic user queries
- [ ] Mentions key concepts clearly

**Content quality checklist:**
- [ ] Imperative/infinitive form throughout
- [ ] Body is 1,500-2,000 words (max 3,000)
- [ ] Detailed content in references/
- [ ] All references mentioned in SKILL.md
- [ ] Examples are complete and working
- [ ] Scripts are executable

**Testing:**
- Test that expected queries trigger the skill
- Verify references load when needed
- Run examples to ensure they work
- Execute scripts to verify functionality

### Step 7: Iteration

After using the skill:

1. **Notice struggles** - Where did Claude get confused?
2. **Identify gaps** - What information was missing?
3. **Strengthen triggers** - Were trigger phrases specific enough?
4. **Balance content** - Should anything move to/from references/?
5. **Improve examples** - Do examples cover all use cases?
6. **Update scripts** - Do utilities handle edge cases?

**Common improvements:**
- Add missing trigger phrases to description
- Move long sections to references/
- Add edge case examples
- Create missing utility scripts
- Clarify ambiguous instructions
- Add troubleshooting section

## Writing Style Requirements

### Imperative/Infinitive Form

Write verb-first instructions:

**Correct:**
```
Parse the configuration file.
Extract the version field.
Validate against the schema.
Handle errors gracefully.
```

**Incorrect:**
```
You should parse the configuration.
Claude can extract the version.
Users might validate against schema.
You need to handle errors.
```

### Third-Person Description

Frontmatter uses third person:

**Correct:**
```yaml
description: This skill should be used when the user asks to "create X", "build Y", or mentions "Z".
```

**Incorrect:**
```yaml
description: Use when you want to create X...
description: Load this skill when creating X...
description: Helps you build Y...
```

### Objective Instructions

Focus on actions, not actors:

**Correct:**
```
Check file existence before reading.
Validate input matches expected format.
Log errors and exit with status 1.
```

**Incorrect:**
```
You can check if the file exists.
Claude should validate the input.
Users might want to log errors.
```

## Common Mistakes

### Mistake 1: Weak Triggers

❌ **Bad:**
```yaml
description: Provides guidance for working with databases.
```

Problems:
- Not third person
- No specific triggers
- Vague and generic

✅ **Good:**
```yaml
description: This skill should be used when the user asks to "run a migration", "rollback database changes", "generate migration file", or mentions database schema updates.
```

Why it works:
- Third person
- Specific user queries
- Concrete scenarios

### Mistake 2: Bloated SKILL.md

❌ **Bad:**
```
skill-name/
└── SKILL.md (8,000 words - everything in one file)
```

Problems:
- Always loads 8,000 words
- No progressive disclosure
- Bloats context unnecessarily

✅ **Good:**
```
skill-name/
├── SKILL.md (1,800 words)
└── references/
    ├── patterns.md (2,500 words)
    ├── advanced.md (2,800 words)
    └── api-reference.md (2,200 words)
```

Why it works:
- Core content always loaded
- Details loaded as needed
- Progressive disclosure

### Mistake 3: Second Person

❌ **Bad:**
```markdown
You should start by reading the configuration.
You need to validate the input.
You can use the validation script.
```

Problems:
- Second person instead of imperative
- Sounds like advice, not instructions

✅ **Good:**
```markdown
Start by reading the configuration file.
Validate the input before processing.
Use the validation script to check format.
```

Why it works:
- Imperative form
- Direct instructions
- Action-focused

### Mistake 4: Hidden Resources

❌ **Bad:**
```markdown
# SKILL.md

[Core content about the skill]

[No mention of references/ or examples/]
```

Problems:
- Claude doesn't know resources exist
- Can't load them when needed

✅ **Good:**
```markdown
# SKILL.md

[Core content]

## Additional Resources

### Reference Files
- **`references/patterns.md`** - Detailed patterns
- **`references/api-reference.md`** - API documentation

### Examples
- **`examples/basic.sh`** - Simple usage
- **`examples/advanced.sh`** - Complex scenario

### Scripts
- **`scripts/validate.sh`** - Validation utility
```

Why it works:
- Claude knows resources exist
- Can load them when needed
- Clear description of each

## Best Practices Summary

### DO:

✅ Start by fetching latest docs (`!curl`)
✅ Ask clarifying questions about use cases
✅ Use third-person description with specific triggers
✅ Keep SKILL.md lean (1,500-2,000 words)
✅ Move details to references/
✅ Write in imperative/infinitive form
✅ Create complete working examples
✅ Make scripts executable with clear docs
✅ Reference all supporting files
✅ Validate structure and content
✅ Test with realistic queries

### DON'T:

❌ Skip fetching latest documentation
❌ Use vague or generic triggers
❌ Write in second person
❌ Put everything in SKILL.md (>3,000 words)
❌ Create broken or incomplete examples
❌ Forget to reference supporting files
❌ Skip validation
❌ Assume requirements without asking
❌ Use passive voice or suggestions
❌ Include unreferenced resources

## Quick Templates

### Minimal Skill

```
skill-name/
└── SKILL.md
```

Use when: Simple knowledge, no complex resources

### Standard Skill

```
skill-name/
├── SKILL.md
├── references/
│   └── detailed-guide.md
└── examples/
    └── basic-example.sh
```

Use when: Most skills with documentation and examples

### Complete Skill

```
skill-name/
├── SKILL.md
├── references/
│   ├── patterns.md
│   ├── advanced.md
│   └── api-reference.md
├── examples/
│   ├── basic.sh
│   ├── advanced.sh
│   └── config.yaml
└── scripts/
    ├── validate.sh
    └── setup.sh
```

Use when: Complex domains with utilities

## Implementation Checklist

**Planning:**
- [ ] Understand use cases with concrete examples
- [ ] Identify needed scripts/references/examples/assets
- [ ] Plan progressive disclosure strategy

**Structure:**
- [ ] Create skill directory
- [ ] Create only needed subdirectories
- [ ] Delete unnecessary directories

**SKILL.md:**
- [ ] Write third-person description with triggers
- [ ] Use imperative form throughout body
- [ ] Keep body 1,500-2,000 words
- [ ] Reference all supporting files
- [ ] Include all required sections

**Resources:**
- [ ] Create references/ files for detailed content
- [ ] Write complete working examples/
- [ ] Build executable scripts/ with docs
- [ ] Add assets/ if needed for output

**Validation:**
- [ ] Check structure is correct
- [ ] Validate YAML frontmatter
- [ ] Verify trigger phrases are specific
- [ ] Confirm imperative form used
- [ ] Test all examples work
- [ ] Verify all scripts execute
- [ ] Check all references exist

**Testing:**
- [ ] Test skill triggers on expected queries
- [ ] Verify references load when needed
- [ ] Run examples successfully
- [ ] Execute scripts without errors

## Real-World Examples

### Hook Development Skill

**Structure:**
```
hook-development/
├── SKILL.md (1,651 words)
├── references/
│   ├── patterns.md
│   ├── advanced.md
│   └── troubleshooting.md
├── examples/
│   ├── pre-tool-use.sh
│   ├── post-tool-use.sh
│   └── stop-hook.sh
└── scripts/
    ├── validate-hook-schema.sh
    ├── test-hook.sh
    └── create-hook-template.sh
```

**Why it works:**
- Lean SKILL.md with core concepts
- Detailed patterns in references/
- Complete working examples
- Useful utility scripts
- Strong trigger phrases

### Agent Development Skill

**Structure:**
```
agent-development/
├── SKILL.md (1,438 words)
├── references/
│   ├── ai-generation-prompt.md
│   └── best-practices.md
└── examples/
    ├── basic-agent.yaml
    └── advanced-agent.yaml
```

**Why it works:**
- Focused SKILL.md
- AI prompt in references/
- Real agent examples
- Clear triggers

### MCP Integration Skill

**Structure:**
```
mcp-integration/
├── SKILL.md (1,892 words)
├── references/
│   ├── server-types.md
│   ├── configuration.md
│   └── troubleshooting.md
└── examples/
    ├── basic-server.json
    └── authenticated-server.json
```

**Why it works:**
- Progressive disclosure
- Comprehensive references
- Configuration examples
- Specific triggers

## Advanced Techniques

### Context Management

For large skills:
1. Keep SKILL.md minimal (core workflow only)
2. Create multiple focused references/
3. Use clear section names for easy grep
4. Include search patterns in SKILL.md

Example:
```markdown
## Finding Patterns

To find specific patterns, search references:

\`\`\`bash
grep -r "authentication" references/
grep -r "error handling" references/
\`\`\`
```

### Skill Composition

Skills can reference other skills:

```markdown
## Related Skills

This skill works with:
- **hook-development** - For creating hooks
- **agent-development** - For building agents
- **mcp-integration** - For MCP servers

Load these skills when working across domains.
```

### Version Management

Use semantic versioning:

```yaml
---
version: 1.2.3
---
```

- Major: Breaking changes
- Minor: New features
- Patch: Bug fixes

Document changes in SKILL.md or references/changelog.md.

## Conclusion

Creating effective skills requires:

1. **Understanding** - Concrete examples of usage
2. **Planning** - Identifying reusable resources
3. **Structure** - Proper directory organization
4. **Content** - Lean SKILL.md, detailed references/
5. **Style** - Imperative form, specific triggers
6. **Validation** - Thorough testing
7. **Iteration** - Continuous improvement

Focus on progressive disclosure, strong triggers, and imperative writing for skills that load when needed and provide targeted guidance.
