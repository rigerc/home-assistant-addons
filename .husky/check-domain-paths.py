#!/usr/bin/env python3
"""
Pre-commit check to prevent commits to domain-specific paths when on main branch.
Works on Windows, macOS, and Linux.
"""
import sys
import re
from pathlib import Path


def parse_domain_paths(file_path):
    """Parse the domain-paths.yaml file and extract path patterns."""
    patterns = []
    content = Path(file_path).read_text()

    # Extract path patterns using regex
    # Match lines like: - huntarr/**
    for match in re.finditer(r'^\s*-\s+([^\s#]+)', content, re.MULTILINE):
        pattern = match.group(1)
        # Convert glob pattern to regex
        # huntarr/** becomes ^huntarr/.*$
        regex_pattern = pattern.replace('**', '.*').replace('*', '[^/]*')
        regex_pattern = f"^{regex_pattern}$"
        patterns.append((pattern, re.compile(regex_pattern)))

    return patterns


def check_files(domain_file, files):
    """Check if any files match domain path patterns."""
    patterns = parse_domain_paths(domain_file)
    blocked = []

    for file_path in files:
        for pattern_str, pattern_re in patterns:
            if pattern_re.match(file_path):
                blocked.append((file_path, pattern_str))
                break

    return blocked


if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(0)

    domain_file = sys.argv[1]
    files = sys.argv[2:]

    try:
        blocked = check_files(domain_file, files)
    except FileNotFoundError:
        # Domain paths file doesn't exist, skip check
        sys.exit(0)
    except Exception:
        # Any error, skip to avoid blocking commits
        sys.exit(0)

    if blocked:
        print("COMMIT BLOCKED")
        print()
        print("You are on the 'main' branch and attempting to commit files")
        print("that belong to domain-specific paths. These changes should be")
        print("made on feature branches instead.")
        print()
        print("Blocked files:")
        for file_path, _pattern in blocked:
            print(f"  - {file_path}")
        print()
        print("To proceed, you can:")
        print("  1. Create a feature branch: git checkout -b feature/your-feature")
        print("  2. Unstage the files: git reset HEAD <files>")
        print()
        sys.exit(1)

    sys.exit(0)
