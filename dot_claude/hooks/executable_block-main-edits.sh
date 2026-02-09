#!/bin/bash
# block-main-edits.sh - Confirm edits on protected branches
# Hook type: PreToolUse (Write, Edit)
#
# Design goals (low-noise, unified output):
# - ASK: only when editing non-allowed files on protected branches.
# - Output: 2 lines max (LEVEL RULE_ID: reason + Next: remediation).

set -euo pipefail

# Explicit escape hatch for intentional protected-branch maintenance.
if [[ "${CLAUDE_ALLOW_PROTECTED_BRANCH_EDITS:-0}" == "1" ]]; then
    exit 0
fi

input=$(cat 2>/dev/null) || true
[[ -n "$input" ]] || exit 0

tool=$(echo "$input" | jq -r '.tool_name // ""' 2>/dev/null || echo "")
if [[ "$tool" != "Write" && "$tool" != "Edit" && "$tool" != "MultiEdit" ]]; then
    exit 0
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    exit 0
fi

branch=$(git branch --show-current 2>/dev/null || echo "")
[[ -n "$branch" ]] || exit 0

file_path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.path // ""' 2>/dev/null || echo "")

protected=false
case "$branch" in
main | master | develop | release/*)
    protected=true
    ;;
esac
[[ "$protected" == true ]] || exit 0

# Allow low-risk docs/config updates on protected branches.
allowed_patterns=(
    "README.md"
    "CHANGELOG.md"
    ".claude/*"
    "docs/*"
)
for pattern in "${allowed_patterns[@]}"; do
    # shellcheck disable=SC2053
    if [[ "$file_path" == $pattern ]]; then
        exit 0
    fi
done

# Unified output: 2 lines (LEVEL RULE_ID: reason + Next: action)
msg="ASK MAIN-EDIT: Editing '${file_path}' on protected branch '${branch}'.
Next: git checkout -b fix/<topic> (or set CLAUDE_ALLOW_PROTECTED_BRANCH_EDITS=1)."

jq -n --arg reason "$msg" '{decision:"ask", reason:$reason}'
exit 0
