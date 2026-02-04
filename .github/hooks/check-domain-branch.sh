#!/usr/bin/env bash
# Pre-commit hook to enforce domain-based branching
# Prevents direct commits to main for domain-specific changes

set -e

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Only check if on main branch
if [[ "$CURRENT_BRANCH" != "main" ]]; then
  exit 0
fi

# Check if yq is available
if ! command -v yq &> /dev/null; then
  echo "⚠️  Warning: yq not found. Skipping domain branch check."
  exit 0
fi

# Path to domain configuration
DOMAIN_CONFIG=".github/domain-paths.yaml"

if [[ ! -f "$DOMAIN_CONFIG" ]]; then
  echo "⚠️  Warning: $DOMAIN_CONFIG not found. Skipping domain branch check."
  exit 0
fi

# Get list of staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR)

if [[ -z "$STAGED_FILES" ]]; then
  exit 0
fi

# Check which domains are affected
AFFECTED_DOMAINS=()

# Read all domains from config
DOMAINS=$(yq eval '.domains | keys | .[]' "$DOMAIN_CONFIG" 2>/dev/null)

for domain in $DOMAINS; do
  # Get paths for this domain
  PATHS=$(yq eval ".domains.$domain.paths[]" "$DOMAIN_CONFIG" 2>/dev/null)

  for path_pattern in $PATHS; do
    # Convert glob pattern to regex (remove /** suffix)
    path_prefix="${path_pattern%/**}"

    # Check if any staged files match this domain's paths
    while IFS= read -r file; do
      if [[ "$file" == "$path_prefix"* ]]; then
        # Domain affected, add to list if not already there
        if [[ ! " ${AFFECTED_DOMAINS[@]} " =~ " ${domain} " ]]; then
          AFFECTED_DOMAINS+=("$domain")
        fi
        break
      fi
    done <<< "$STAGED_FILES"
  done
done

# If no domains affected, allow commit
if [[ ${#AFFECTED_DOMAINS[@]} -eq 0 ]]; then
  exit 0
fi

# If domains are affected, block the commit
echo ""
echo "❌ Direct commits to 'main' are not allowed for domain-specific changes!"
echo ""
echo "📋 Affected domain(s): ${AFFECTED_DOMAINS[*]}"
echo ""
echo "🔧 To commit these changes:"
echo ""

if [[ ${#AFFECTED_DOMAINS[@]} -eq 1 ]]; then
  DOMAIN="${AFFECTED_DOMAINS[0]}"
  echo "  1. Switch to the domain branch:"
  echo "     git checkout -b app/$DOMAIN origin/app/$DOMAIN 2>/dev/null || git checkout -b app/$DOMAIN"
  echo ""
  echo "  2. Commit your changes:"
  echo "     git commit"
  echo ""
  echo "  3. Push to the domain branch:"
  echo "     git push -u origin app/$DOMAIN"
  echo ""
  echo "  The auto-branch-and-pr workflow will create a PR for you."
else
  echo "  Multiple domains affected: ${AFFECTED_DOMAINS[*]}"
  echo ""
  echo "  Option A - Commit to separate branches:"
  for domain in "${AFFECTED_DOMAINS[@]}"; do
    echo "    git checkout -b app/$domain"
    echo "    git add <files for $domain>"
    echo "    git commit"
    echo "    git push -u origin app/$domain"
  done
  echo ""
  echo "  Option B - Use --no-verify to bypass this check (not recommended):"
  echo "    git commit --no-verify"
fi
echo ""
echo "💡 Tip: Use branch protection on 'main' to enforce PR reviews."
echo ""

exit 1
