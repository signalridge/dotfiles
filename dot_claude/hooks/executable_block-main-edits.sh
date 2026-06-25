#!/bin/bash
# block-main-edits.sh - Confirm edits on protected branches
# Hook type: PreToolUse (Write, Edit)
#
# Design goals (low-noise, unified output):
# - ASK: only when editing non-allowed files on protected branches.
# - Output: 2 lines max (status + next remediation).

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

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

file_path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.path // ""' 2>/dev/null || echo "")

# Judge the branch by where the *edited file* lives, not the hook's CWD.
# CC always runs from the primary checkout (usually main), so a CWD-based
# check flags every edit as "main" even when the file is in a feature
# worktree under .worktrees/<branch>. Resolve the file's own directory and
# ask git there: a linked worktree reports its own branch, not main.
if [[ -n "$file_path" ]]; then
    target_dir=$(dirname -- "$file_path")
else
    target_dir="."
fi
# New-file writes target a path that doesn't exist yet; walk up to the
# nearest existing ancestor so git can resolve the containing worktree.
while [[ "$target_dir" != "/" && "$target_dir" != "." && ! -d "$target_dir" ]]; do
    target_dir=$(dirname -- "$target_dir")
done

if ! git -C "$target_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    exit 0
fi

branch=$(git -C "$target_dir" branch --show-current 2>/dev/null || echo "")
[[ -n "$branch" ]] || exit 0

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

# Unified output: 2 lines (status + Next action)
msg="ASK MAIN-EDIT: Editing '${file_path}' on protected branch '${branch}'.
Next: git checkout -b fix/<topic> (or set CLAUDE_ALLOW_PROTECTED_BRANCH_EDITS=1)."

jq -n --arg reason "$msg" '{
    hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "ask",
        permissionDecisionReason: $reason
    }
}'
exit 0
