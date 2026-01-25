# Skill Generator

A Claude Code skill for creating high-quality, well-structured skills that follow official best practices.

## What This Skill Does

The `skill-generator` skill helps you create production-ready Claude Code skills by:

1. **Fetching latest documentation** - Uses `!curl` to get current best practices from official docs
2. **Asking clarifying questions** - Gathers concrete examples and requirements
3. **Planning resources** - Identifies needed scripts, references, examples, and assets
4. **Generating structure** - Creates proper directory layout
5. **Writing SKILL.md** - Produces well-formatted skill with strong triggers and imperative form
6. **Creating resources** - Builds supporting files (references, examples, scripts)
7. **Validating** - Ensures the skill meets quality standards

## Trigger Phrases

This skill activates when you say:
- "create a skill"
- "generate a skill"
- "build a new skill"
- "make a skill for Claude Code"
- Or mention creating reusable Claude Code capabilities

## Skill Contents

```
skill-generator/
├── SKILL.md                               # Main skill (2,123 words)
├── references/
│   └── skill-creator-methodology.md       # Complete methodology reference
├── examples/
│   ├── simple-skill-example.md            # Minimal skill example
│   └── complex-skill-example.md           # Comprehensive skill with all resources
└── scripts/
    └── validate-skill.sh                  # Validation utility
```

## Progressive Disclosure

**SKILL.md (2,123 words):**
- Core workflow for generating skills
- Essential best practices
- Quick reference to resources

**references/skill-creator-methodology.md (~6,500 words):**
- Complete original skill-creator documentation
- Detailed patterns and techniques
- Advanced use cases and examples

**examples/ (2 files):**
- Simple JSON validator skill (minimal structure)
- Complex database migrations skill (full structure with all resource types)

**scripts/validate-skill.sh:**
- Automated quality checking
- Validates structure, frontmatter, writing style, content length
- Checks for resource references and common sections

## Key Features

### Fetches Latest Documentation

The skill always starts by fetching the most current documentation:

```bash
!curl -s https://code.claude.com/docs/en/skills.md
```

This ensures generated skills follow the latest standards and best practices.

### Strong Trigger Phrases

Generated skills include specific, realistic trigger phrases in third person:

✅ **Good:**
```yaml
description: This skill should be used when the user asks to "create a hook", "add a PreToolUse hook", or mentions hook events.
```

❌ **Bad:**
```yaml
description: Provides guidance for hooks.
```

### Imperative Writing Style

All generated content uses imperative/infinitive form:

✅ **Correct:** "Parse the configuration. Validate the input. Use the grep tool."

❌ **Incorrect:** "You should parse... You need to validate... You can use..."

### Progressive Disclosure

Skills are structured to minimize context bloat:
- Core concepts in SKILL.md (1,500-2,000 words)
- Detailed content in references/ (2,000-5,000+ words per file)
- Working examples in examples/
- Utilities in scripts/

## Usage Examples

### Basic Usage

```
User: "Create a skill for validating JSON files"
```

The skill will:
1. Fetch latest skills documentation
2. Ask about specific use cases and triggers
3. Identify that a simple skill with no bundled resources is appropriate
4. Generate SKILL.md with proper structure and triggers
5. Validate the generated skill

### Complex Usage

```
User: "Create a skill for managing database migrations"
```

The skill will:
1. Fetch latest documentation
2. Ask about migration workflows, rollback needs, validation requirements
3. Identify need for:
   - `scripts/generate-migration.sh` (code reuse)
   - `references/patterns.md` (detailed SQL patterns)
   - `examples/create-table.sql` (working examples)
4. Create full directory structure
5. Generate comprehensive SKILL.md with resource references
6. Create all supporting files
7. Validate the complete skill

## Validation

Use the included validation script to check any skill:

```bash
./scripts/validate-skill.sh path/to/skill-directory
```

Checks:
- ✅ Directory structure exists
- ✅ SKILL.md has valid YAML frontmatter
- ✅ Required fields present (name, description, version)
- ✅ Description uses third person
- ✅ Trigger phrases are quoted
- ✅ Body uses imperative form (not second person)
- ✅ Content length is appropriate (1,500-2,000 words ideal)
- ✅ Resource directories referenced in SKILL.md
- ✅ Scripts are executable
- ✅ Recommended sections present

## Best Practices Applied

The skill follows all best practices it teaches:

1. **Third-person description** with 8 specific trigger phrases
2. **Imperative form** throughout the body
3. **Appropriate length** (2,123 words - slightly above ideal but comprehensive)
4. **Progressive disclosure** - details in references/, examples in examples/
5. **Complete resources** - methodology reference, working examples, validation script
6. **Clear structure** - Purpose, When to Use, Core Workflow sections
7. **Resource references** - All supporting files clearly mentioned

## Examples Included

### Simple Skill: JSON Validator

Shows minimal skill structure for straightforward tasks:
- No bundled resources needed
- ~800 words
- Clear workflow
- Strong triggers

### Complex Skill: Database Migrations

Demonstrates comprehensive skill with all resource types:
- references/ for detailed patterns (2,500+ words)
- examples/ for working SQL files
- scripts/ for generation, validation, rollback
- SKILL.md stays lean (1,200 words)
- Progressive disclosure in action

## Generated Skills Will Have

✅ Third-person description with specific triggers
✅ Imperative/infinitive form throughout
✅ Appropriate length (1,500-2,000 words in SKILL.md)
✅ Progressive disclosure (details in references/)
✅ Complete working examples
✅ Executable scripts with documentation
✅ Clear resource references
✅ Required sections (Purpose, When to Use, Core Workflow)
✅ Validation-ready structure

## Version

Current version: 0.1.0

## Contributing

When improving this skill:
1. Fetch latest documentation first
2. Test with both simple and complex skill generation
3. Validate using `validate-skill.sh`
4. Ensure examples remain current
5. Keep SKILL.md lean (move details to references/)
