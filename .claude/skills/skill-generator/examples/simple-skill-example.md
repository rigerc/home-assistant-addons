# Example: Simple Skill for JSON Validation

This example shows a minimal skill with no bundled resources.

## Directory Structure

```
json-validator/
└── SKILL.md
```

## SKILL.md Content

```yaml
---
name: json-validator
description: This skill should be used when the user asks to "validate JSON", "check JSON syntax", "verify JSON format", or mentions JSON validation. Provides systematic JSON validation and formatting.
version: 0.1.0
---

# JSON Validator

This skill provides systematic JSON validation and formatting capabilities.

## Purpose

Validate JSON files and strings, identify syntax errors, and format JSON output properly. Helps ensure JSON data integrity before use.

## When to Use This Skill

Use this skill when:
- The user asks to validate JSON files or strings
- JSON syntax errors need to be identified
- JSON formatting or pretty-printing is needed
- Verifying JSON structure before processing

## Core Workflow

### Step 1: Identify JSON Source

Determine whether validating:
- File path (read using Read tool)
- JSON string provided by user
- JSON output from a command

### Step 2: Parse and Validate

Use jq to validate JSON syntax:

\`\`\`bash
echo "$json_string" | jq .
# OR
jq . < file.json
\`\`\`

If jq succeeds, JSON is valid. If it fails, output shows the syntax error.

### Step 3: Report Results

For valid JSON:
- Confirm validation successful
- Show formatted output if requested

For invalid JSON:
- Show the error message
- Identify the line and column of the error
- Suggest the fix if obvious

## Validation Patterns

### Validate File

\`\`\`bash
jq . < data.json
\`\`\`

### Validate String

\`\`\`bash
echo '{"key": "value"}' | jq .
\`\`\`

### Format JSON

\`\`\`bash
jq . < compact.json > formatted.json
\`\`\`

### Check Specific Schema

\`\`\`bash
# Verify required fields exist
jq 'has("field1") and has("field2")' < data.json
\`\`\`

## Common Errors

### Trailing Comma

\`\`\`json
{
  "key": "value",
}
\`\`\`

Error: `parse error: Expected another key-value pair at line 3, column 1`

Fix: Remove trailing comma after "value"

### Missing Quote

\`\`\`json
{
  key: "value"
}
\`\`\`

Error: `parse error: Invalid numeric literal at line 2, column 4`

Fix: Add quotes around key: `"key": "value"`

### Single Quotes

\`\`\`json
{
  'key': 'value'
}
\`\`\`

Error: `parse error: Invalid numeric literal at line 2, column 2`

Fix: Use double quotes: `"key": "value"`

## Best Practices

- Always validate JSON before processing
- Use jq for both validation and formatting
- Provide clear error messages with line numbers
- Suggest fixes for common syntax errors
- Format JSON for readability when outputting
```

## Why This Works

**Strong triggers:**
- "validate JSON"
- "check JSON syntax"
- "verify JSON format"
- "JSON validation"

**Imperative form:**
- "Determine whether validating"
- "Use jq to validate"
- "Show formatted output"

**Focused content:**
- Core workflow in 3 steps
- Common patterns
- Error examples
- No need for references/ (content is concise)

**Appropriate length:**
- ~800 words
- Could be expanded but works as minimal skill
