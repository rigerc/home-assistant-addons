#!/usr/bin/env python3
"""
Pre-commit hook to enforce domain-based branching.
Prevents direct commits to main for domain-specific changes.
"""

import subprocess
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("⚠️  Warning: PyYAML not installed. Skipping domain branch check.")
    print("   Install with: pip install pyyaml")
    sys.exit(0)


def get_current_branch():
    """Get the current git branch name."""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError:
        return None


def get_staged_files():
    """Get list of staged files."""
    try:
        result = subprocess.run(
            ["git", "diff", "--cached", "--name-only", "--diff-filter=ACMR"],
            capture_output=True,
            text=True,
            check=True
        )
        return [f for f in result.stdout.strip().split('\n') if f]
    except subprocess.CalledProcessError:
        return []


def load_domain_config():
    """Load domain configuration from YAML."""
    config_path = Path(".github/domain-paths.yaml")

    if not config_path.exists():
        return None

    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            return yaml.safe_load(f)
    except Exception as e:
        print(f"⚠️  Warning: Could not parse {config_path}: {e}")
        return None


def get_affected_domains(staged_files, domain_config):
    """Determine which domains are affected by staged files."""
    if not domain_config or 'domains' not in domain_config:
        return []

    affected_domains = set()

    for domain, config in domain_config['domains'].items():
        paths = config.get('paths', [])

        for path_pattern in paths:
            # Convert glob pattern to prefix (remove /** suffix)
            path_prefix = path_pattern.rstrip('/**').rstrip('/*')

            # Check if any staged file matches this domain's paths
            for file in staged_files:
                if file.startswith(path_prefix + '/') or file.startswith(path_prefix + '\\'):
                    affected_domains.add(domain)
                    break

    return sorted(affected_domains)


def main():
    """Main hook logic."""
    # Get current branch
    current_branch = get_current_branch()

    if current_branch is None:
        print("⚠️  Warning: Could not determine current branch.")
        sys.exit(0)

    # Only check if on main branch
    if current_branch != "main":
        sys.exit(0)

    # Get staged files
    staged_files = get_staged_files()

    if not staged_files:
        sys.exit(0)

    # Load domain configuration
    domain_config = load_domain_config()

    if domain_config is None:
        sys.exit(0)

    # Check which domains are affected
    affected_domains = get_affected_domains(staged_files, domain_config)

    # If no domains affected, allow commit
    if not affected_domains:
        sys.exit(0)

    # Block the commit and provide guidance
    print()
    print("❌ Direct commits to 'main' are not allowed for domain-specific changes!")
    print()
    print(f"📋 Affected domain(s): {', '.join(affected_domains)}")
    print()
    print("🔧 To commit these changes:")
    print()

    if len(affected_domains) == 1:
        domain = affected_domains[0]
        print("  1. Switch to the domain branch:")
        print(f"     git checkout -b app/{domain}")
        print()
        print("  2. Commit your changes:")
        print("     git commit")
        print()
        print("  3. Push to the domain branch:")
        print(f"     git push -u origin app/{domain}")
        print()
        print("  The auto-branch-and-pr workflow will create a PR for you.")
    else:
        print(f"  Multiple domains affected: {', '.join(affected_domains)}")
        print()
        print("  Option A - Commit to separate branches:")
        for domain in affected_domains:
            print(f"    git checkout -b app/{domain}")
            print(f"    git add <files for {domain}>")
            print("    git commit")
            print(f"    git push -u origin app/{domain}")
        print()
        print("  Option B - Use --no-verify to bypass this check (not recommended):")
        print("    git commit --no-verify")

    print()
    print("💡 Tip: Use branch protection on 'main' to enforce PR reviews.")
    print()

    sys.exit(1)


if __name__ == "__main__":
    main()
