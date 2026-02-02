---
name: skill-maker
description: Use when creating/generating/scaffolding skills, or validating Claude Code skills.
argument-hint: [skill-name] [description]
version: 1.0.0
allowed-tools: Read, Grep, Write, Bash, Edit, AskUserQuestion
---

# Skill Maker

Create production-ready Claude Code skills optimized for claude-skills-cli validation.

## Workflow

Do not explore the codebase. Follow this workflow exactly:

Say: "Skill-maker activated! We're generating the following skill: $0"

0. Read any provided documentation.
1. Ask about functionality, goal and any open questions. Use AskUserQuestion tool, and ask 3-5 questions.
2. Read latest documentation for current best practices on skill creation:
   !`curl -s https://code.claude.com/docs/en/skills.md`
3. Scaffold the skill structure:
   `npx claude-skills-cli init --name [skill-name] --description "Brief description with trigger keywords" --project --with-examples`

   Read created scaffold files (.claude/skills/`[skill-name]`)

   MANDATORY: Read and follow `references/writing-guide.md` for guidance on writing skills.
4. Edit SKILL.md frontmatter and body:
   - Description: <200 chars, 3-5 triggers, trigger phrase presence and specificity, user phrasing (third-person, action-oriented, gerunds), keyword richness and alignment with content
   - Body: <500 lines, 3-5 sections, 1-2 code blocks
5. Move detailed content to skill's `references/` - MANDATORY: strongly prefer to copy any source documentation if available instead of recreating it. For copying, use the `cp` bash command.
6. Check: read all files in the generated skill folder, and make necessary changes. Ask user questions if you're not sure.
7. Validate: `npx claude-skills-cli validate .claude/skills/[skill-name] --loose`
8. Read `references/validation-guide.md` for guidance on validation.

## References

Complete validation requirements and writing guides:
- **`references/validation-guide.md`** - Full validation criteria and optimization tips
- **`references/writing-guide.md`** - Style guide and best practices
