---
allowed-tools:
  - Bash
  - AskUserQuestion
  - mcp__narsil-mcp__*
  - Skill
argument-hint: [topic or domain to generate rules for]
description: Generate modular Claude Code rules for a specific topic using codebase analysis
---

# Modular Rules Generation Workflow

## Overview

This command generates modular Claude Code rules in `.claude/rules/` that are short, succinct, and optimized for LLM coding agents with path-specific scoping support.

## 1. Understand User's Request

Parse the user's `$ARGUMENT` to understand what rules they want to generate. Examples:
- "frontend validation"
- "API error handling"
- "database transactions"
- "authentication patterns"

## 2. Explore Codebase with Narsil-MCP

**MANDATORY PREREQUISITE**: Before invoking the modular-rules-generator skill, you MUST use narsil-mcp to explore the codebase and gather context.

### Check index status:
```bash
mcp-cli info narsil-mcp/get_index_status
mcp-cli call narsil-mcp/get_index_status '{"repo":"."}'
```

### Search for relevant code:
```bash
mcp-cli info narsil-mcp/search_code
mcp-cli call narsil-mcp/search_code '{
  "query": "KEYWORDS_FROM_ARGUMENT",
  "repo": ".",
  "max_results": 20
}'
```

### Find relevant symbols (functions, structs, classes):
```bash
mcp-cli info narsil-mcp/find_symbols
mcp-cli call narsil-mcp/find_symbols '{
  "repo": ".",
  "symbol_type": "all",
  "pattern": "*RELEVANT_PATTERN*"
}'
```

### Get project structure:
```bash
mcp-cli info narsil-mcp/get_project_structure
mcp-cli call narsil-mcp/get_project_structure '{
  "repo": ".",
  "max_depth": 4
}'
```

### Check for existing patterns (if applicable):
```bash
# For security-related rules
mcp-cli info narsil-mcp/scan_security
mcp-cli call narsil-mcp/scan_security '{
  "repo": ".",
  "severity_threshold": "medium"
}'

# For complexity/quality rules
mcp-cli info narsil-mcp/get_hotspots
mcp-cli call narsil-mcp/get_hotspots '{
  "repo": ".",
  "days": 30,
  "min_complexity": 10
}'

# For dependency-related rules
mcp-cli info narsil-mcp/get_dependencies
mcp-cli call narsil-mcp/get_dependencies '{
  "repo": ".",
  "path": "RELEVANT_PATH",
  "direction": "both"
}'
```

### Semantic search for patterns:
```bash
mcp-cli info narsil-mcp/semantic_search
mcp-cli call narsil-mcp/semantic_search '{
  "query": "DESCRIBE_PATTERN_IN_NATURAL_LANGUAGE",
  "repo": ".",
  "max_results": 15
}'
```

## 3. Analyze Findings

Review the narsil-mcp results to identify:
- **Existing patterns** - How the codebase currently handles this topic
- **Common practices** - Repeated approaches across files
- **Anti-patterns** - Things to avoid based on existing issues
- **File locations** - Where rules should be scoped
- **Key conventions** - Naming, structure, organization patterns

## 4. Prepare Context for Skill

Synthesize the narsil-mcp findings into a clear context summary:

```
Based on codebase analysis:

1. Relevant files and paths:
   - [list key files/directories]

2. Existing patterns discovered:
   - [pattern 1]
   - [pattern 2]

3. Common conventions:
   - [convention 1]
   - [convention 2]

4. Issues to address:
   - [issue 1]
   - [issue 2]

5. Scope recommendations:
   - [path scope 1]
   - [path scope 2]
```

## 5. Invoke Modular Rules Generator

Now that you have codebase context, invoke the skill:

```bash
# Use the Skill tool to invoke modular-rules-generator
```

**Pass the full context to the skill**, including:
- User's original request ($ARGUMENT)
- Codebase analysis findings
- Recommended path scopes
- Existing patterns to reinforce or correct

## 6. Review Generated Rules

After the skill completes:
1. Review the generated rule files in `.claude/rules/`
2. Verify they follow modular rules best practices:
   - Short and succinct
   - Path-specific scoping where appropriate
   - LLM-optimized format
   - Clear, actionable guidance

## 7. Report to User

Show the user:
- What rules were generated
- Where they were saved
- Which paths they apply to
- Summary of what the rules enforce

**Example output:**
```
Generated modular rules for: frontend validation

Created rules:
- .claude/rules/frontend/validation.md
  Scope: frontend/src/**/*.{ts,tsx}
  Enforces: Input validation patterns, error handling, type safety

- .claude/rules/frontend/form-handling.md
  Scope: frontend/src/components/forms/**/*
  Enforces: Form state management, submission handling, validation triggers

Based on codebase analysis:
- Found 23 existing validation functions
- Identified 5 common patterns
- 3 path-specific scopes recommended
```

## Error Handling

| Error | Action |
|-------|--------|
| Narsil-MCP not available | Check `.mcp.json`, verify server is running |
| No relevant code found | Broaden search, ask user for clarification |
| Unclear topic | Ask clarifying questions about scope |
| Rules directory missing | Create `.claude/rules/` directory |

## Best Practices

1. **Always explore first** - Never generate rules without codebase context
2. **Use multiple narsil-mcp tools** - Get comprehensive understanding
3. **Look for existing patterns** - Reinforce what works, fix what doesn't
4. **Scope appropriately** - Use path-specific rules where relevant
5. **Be specific** - Vague rules are ignored; specific rules are followed
6. **Include examples** - Show actual code from the codebase when possible

## Important Notes

- **MANDATORY**: You MUST use narsil-mcp BEFORE invoking modular-rules-generator
- The quality of generated rules depends on the quality of codebase analysis
- Spend time understanding existing patterns before generating new rules
- Rules should reflect reality in the codebase, not just best practices
- Path scoping makes rules more relevant and actionable

## References

- `.claude/skills/modular-rules-generator/SKILL.md` - Skill documentation
- `.claude/narsil-reference.md` - Narsil-MCP tool reference
- Existing rules in `.claude/rules/` - Examples of good modular rules
