---
name: skill-maker
description: Use when creating/generating/scaffolding skills, or validating Claude Code skills.
argument-hint: [skill-name] [description]
version: 1.0.0
allowed-tools: Read, Grep, Write, Bash, Edit
---

# Skill Maker

Create production-ready Claude Code skills optimized for claude-skills-cli validation.

## Workflow

1. Ask about functionality and trigger phrases (gather 2-3 examples)
2. Read latest documentation for current best practices:
   !`curl -s https://code.claude.com/docs/en/skills.md`
3. Scaffold the skill structure:
   `npx claude-skills-cli init --name [skill-name] --description "Brief description with trigger keywords" --project --with-examples`
4. Edit SKILL.md frontmatter and body:
   - Description: <200 chars, 3-5 triggers, include "Use when"
   - Body: <50 lines, 3-5 sections, 1-2 code blocks
5. Move detailed content to references/
6. Validate: `npx claude-skills-cli validate .claude/skills/[skill-name] --loose`

## References

Complete validation requirements and writing guides:
- **`references/validation-guide.md`** - Full validation criteria and optimization tips
- **`references/writing-guide.md`** - Style guide and best practices
