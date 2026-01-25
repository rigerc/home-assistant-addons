#!/bin/bash
# Validate SKILL.md content for quality and completeness

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <path-to-SKILL.md>"
    echo "Example: $0 ./skills/my-skill/SKILL.md"
    exit 1
fi

SKILL_MD="$1"
ERRORS=0
WARNINGS=0

# If a directory was passed, look for SKILL.md in it
if [ -d "$SKILL_MD" ]; then
    SKILL_MD="$SKILL_MD/SKILL.md"
fi

echo "Validating SKILL.md at: ${SKILL_MD}"
echo ""

# Check if SKILL.md exists
if [ ! -f "$SKILL_MD" ]; then
    echo "❌ ERROR: SKILL.md not found at ${SKILL_MD}"
    exit 1
fi

echo "✅ SKILL.md file found"
echo ""

# Validate YAML frontmatter
echo "Checking YAML frontmatter..."

# Check for frontmatter delimiters
if ! grep -q "^---$" "$SKILL_MD"; then
    echo "❌ ERROR: No YAML frontmatter found (missing --- delimiters)"
    ((ERRORS++))
else
    echo "✅ YAML frontmatter delimiters found"

    # Extract frontmatter (everything between first two --- lines)
    FRONTMATTER=$(awk '/^---$/{c++; if(c==1){p=1; next} if(c==2){p=0}} p' "$SKILL_MD")

    # Check for required fields
    if ! echo "$FRONTMATTER" | grep -q "^name:"; then
        echo "❌ ERROR: Missing 'name' field in frontmatter"
        ((ERRORS++))
    else
        NAME=$(echo "$FRONTMATTER" | grep "^name:" | sed 's/name: *//')
        echo "✅ Name field found: ${NAME}"
    fi

    if ! echo "$FRONTMATTER" | grep -q "^description:"; then
        echo "❌ ERROR: Missing 'description' field in frontmatter"
        ((ERRORS++))
    else
        DESCRIPTION=$(echo "$FRONTMATTER" | grep "^description:" | sed 's/description: *//')

        # Check description uses third person
        if echo "$DESCRIPTION" | grep -qiE "^(use|load|helps? you|you should|you can)"; then
            echo "⚠️  WARNING: Description may not use third person"
            echo "   Should start with 'This skill should be used when...'"
            ((WARNINGS++))
        else
            echo "✅ Description appears to use third person"
        fi

        # Check for specific trigger phrases
        if ! echo "$DESCRIPTION" | grep -q '"'; then
            echo "⚠️  WARNING: Description has no quoted trigger phrases"
            echo "   Should include specific queries like \"create X\", \"build Y\""
            ((WARNINGS++))
        else
            TRIGGER_COUNT=$(echo "$DESCRIPTION" | grep -o '"[^"]*"' | wc -l)
            echo "✅ Found ${TRIGGER_COUNT} trigger phrases in quotes"

            if [ "$TRIGGER_COUNT" -lt 3 ]; then
                echo "⚠️  WARNING: Consider adding more trigger phrases (found ${TRIGGER_COUNT}, recommend 3-5)"
                ((WARNINGS++))
            fi
        fi
    fi

    if ! echo "$FRONTMATTER" | grep -q "^version:"; then
        echo "⚠️  WARNING: Missing 'version' field in frontmatter"
        ((WARNINGS++))
    else
        VERSION=$(echo "$FRONTMATTER" | grep "^version:" | sed 's/version: *//')
        echo "✅ Version field found: ${VERSION}"
    fi
fi

echo ""

# Check writing style
echo "Checking writing style..."

# Extract body (everything after second ---)
BODY=$(awk '/^---$/{c++; if(c==2) {p=1; next}} p' "$SKILL_MD")

# Check for second person
SECOND_PERSON_MATCHES=$(echo "$BODY" | grep -iE "\byou (should|can|need|must|will|might|may)\b" | grep -v "^#" | grep -v "^\*\*" | grep -v "^❌" || true)

if [ -n "$SECOND_PERSON_MATCHES" ]; then
    # Count actual matches (not in example blocks)
    # Exclude lines that are clearly examples (starting with special chars or in code blocks)
    ACTUAL_MATCHES=$(echo "$SECOND_PERSON_MATCHES" | grep -v '```' | grep -v '^>' | wc -l)

    if [ "$ACTUAL_MATCHES" -gt 5 ]; then
        echo "⚠️  WARNING: Body may contain second person ('you should', 'you can', etc.)"
        echo "   Should use imperative form instead"
        echo "   Found ${ACTUAL_MATCHES} potential matches (examples excluded)"
        ((WARNINGS++))
    else
        echo "✅ Minimal second person usage (likely in examples only)"
    fi
else
    echo "✅ No second person usage found"
fi

echo ""

# Check content length
echo "Checking content length..."

WORD_COUNT=$(echo "$BODY" | wc -w)
echo "   Body word count: ${WORD_COUNT}"

if [ "$WORD_COUNT" -gt 3000 ]; then
    echo "⚠️  WARNING: SKILL.md body is very long (${WORD_COUNT} words)"
    echo "   Consider moving detailed content to references/"
    ((WARNINGS++))
elif [ "$WORD_COUNT" -gt 2000 ]; then
    echo "ℹ️  INFO: SKILL.md body is on the longer side (${WORD_COUNT} words)"
    echo "   Target is 1,500-2,000 words. Consider references/ for details."
elif [ "$WORD_COUNT" -lt 500 ]; then
    echo "⚠️  WARNING: SKILL.md body seems short (${WORD_COUNT} words)"
    echo "   Ensure adequate guidance is provided"
    ((WARNINGS++))
else
    echo "✅ Content length looks good (${WORD_COUNT} words)"
fi

echo ""

# Check for recommended sections
echo "Checking recommended sections..."

if grep -qi "^## Purpose" "$SKILL_MD" || grep -qi "^# Purpose" "$SKILL_MD"; then
    echo "✅ Purpose section found"
else
    echo "⚠️  WARNING: No 'Purpose' section found"
    ((WARNINGS++))
fi

if grep -qi "^## When to Use" "$SKILL_MD"; then
    echo "✅ 'When to Use' section found"
else
    echo "⚠️  WARNING: No 'When to Use This Skill' section found"
    ((WARNINGS++))
fi

if grep -qi "^## Core Workflow\|^## Workflow" "$SKILL_MD"; then
    echo "✅ Workflow section found"
else
    echo "⚠️  WARNING: No 'Core Workflow' section found"
    ((WARNINGS++))
fi

echo ""

# Summary
echo "========================================="
echo "Validation Summary"
echo "========================================="
echo "Errors:   ${ERRORS}"
echo "Warnings: ${WARNINGS}"
echo ""

if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo "✅ SKILL.md validation passed!"
    exit 0
elif [ "$ERRORS" -eq 0 ]; then
    echo "⚠️  SKILL.md validation passed with ${WARNINGS} warnings"
    echo "   Review warnings above to improve skill quality"
    exit 0
else
    echo "❌ SKILL.md validation failed with ${ERRORS} errors"
    echo "   Fix errors above before using the skill"
    exit 1
fi
