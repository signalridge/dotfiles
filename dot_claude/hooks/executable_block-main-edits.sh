#!/bin/bash
# block-main-edits.sh - Prevent direct edits on protected branches
# Hook type: PreToolUse (Write, Edit)

set -euo pipefail

# Handle case where stdin is unavailable or empty
input=$(cat 2>/dev/null) || true
if [[ -z "$input" ]]; then
    exit 0
fi

tool=$(echo "$input" | jq -r '.tool_name // ""' 2>/dev/null)

# Only check for Write and Edit tools
if [[ "$tool" != "Write" && "$tool" != "Edit" ]]; then
    exit 0
fi

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    exit 0
fi

# Get current branch
branch=$(git branch --show-current 2>/dev/null || echo "")

# Protected branches (main, master, develop, release/*)
protected_branches="main master develop"

for protected in $protected_branches; do
    if [[ "$branch" == "$protected" ]]; then
        # Get the file being edited
        file_path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.path // ""' 2>/dev/null)

        # Allow certain files even on protected branches
        # (e.g., documentation, config that's meant to be edited directly)
        allowed_patterns=(
            "README.md"
            "CHANGELOG.md"
            ".claude/*"
            "docs/*"
        )

        for pattern in "${allowed_patterns[@]}"; do
            # shellcheck disable=SC2053 # Intentional glob matching
            if [[ "$file_path" == $pattern ]]; then
                exit 0
            fi
        done

        echo "{\"decision\": \"block\", \"reason\": \"Direct edits on '$branch' branch are blocked. Create a feature branch first: git checkout -b feat/your-feature\"}"
        exit 0
    fi
done

# Check for release branches
if [[ "$branch" == release/* ]]; then
    echo "{\"decision\": \"block\", \"reason\": \"Direct edits on release branches are blocked. Use hotfix branch if needed.\"}"
    exit 0
fi

exit 0
