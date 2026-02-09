#!/bin/bash
# block-git-rewrites.sh - Guard dangerous git history rewrite operations.
# Hook type: PreToolUse (Bash)
#
# Design goals (low-noise, unified output):
# - BLOCK: only for truly irreversible/dangerous actions (rare).
# - ASK: for risky but recoverable actions.
# - Output: 2 lines max (LEVEL RULE_ID: reason + Next: remediation).

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

input=$(cat 2>/dev/null) || true
[[ -n "$input" ]] || exit 0

tool_name=$(echo "$input" | jq -r '.tool_name // ""' 2>/dev/null || echo "")
[[ "$tool_name" == "Bash" ]] || exit 0

command=$(echo "$input" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")
[[ -n "$command" ]] || exit 0

protected_branches='main|master|develop|release'

matches() {
    local pattern="$1"
    printf '%s\n' "$command" | grep -qE "$pattern"
}

# Unified output: 2 lines (LEVEL RULE_ID: reason + Next: action)
ask() {
    local rule_id="$1"
    local reason="$2"
    local next="$3"
    local msg="ASK ${rule_id}: ${reason}
Next: ${next}"
    jq -n --arg reason "$msg" '{decision:"ask", reason:$reason}'
    exit 0
}

block() {
    local rule_id="$1"
    local reason="$2"
    local next="$3"
    local msg="BLOCK ${rule_id}: ${reason}
Next: ${next}"
    jq -n --arg reason "$msg" '{decision:"block", reason:$reason}'
    exit 0
}

# --- BLOCK rules (truly dangerous, no recovery) ---

if matches 'git[[:space:]]+rebase[[:space:]]+(-i|--interactive)'; then
    block "GIT-REBASE-I" "Interactive rebase requires manual input." "Use regular rebase or merge instead."
fi

if matches "git[[:space:]]+branch[[:space:]]+(-d|-D|--delete)[[:space:]]+($protected_branches)"; then
    block "GIT-DELETE-PROTECTED" "Cannot delete protected branch." "Use a feature branch."
fi

if matches "git[[:space:]]+push.*(--delete[[:space:]]+($protected_branches)|:[[:space:]]*($protected_branches))"; then
    block "GIT-PUSH-DELETE-PROTECTED" "Cannot delete protected remote branch." "Use a feature branch."
fi

if matches 'git[[:space:]]+push' && matches '(^|[[:space:]])(--force|-f)([[:space:]]|$)'; then
    if matches "($protected_branches)"; then
        block "GIT-FORCE-PUSH-PROTECTED" "Force push to protected branch not allowed." "Use a feature branch."
    fi
fi

# --- ASK rules (risky but recoverable) ---

if matches '(^|[[:space:]])openspec[[:space:]]+archive([[:space:]]|$)'; then
    if matches '(^|[[:space:]])--yes([[:space:]]|$)'; then
        ask "OPENSPEC-ARCHIVE-YES" "openspec archive --yes finalizes the change." "Confirm explicitly (never auto-chain)."
    fi
    ask "OPENSPEC-ARCHIVE" "openspec archive finalizes the change." "Confirm explicitly (one step at a time)."
fi

if matches 'git[[:space:]]+push' && matches '(^|[[:space:]])(--force|-f)([[:space:]]|$)'; then
    ask "GIT-FORCE-PUSH" "Force push rewrites remote history." "Confirm you want to rewrite."
fi

if matches 'git[[:space:]]+commit.*--amend'; then
    ask "GIT-AMEND" "--amend rewrites the last commit." "Verify commit not pushed (git status shows ahead)."
fi

if matches 'git[[:space:]]+reset[[:space:]]+--hard'; then
    ask "GIT-RESET-HARD" "git reset --hard discards uncommitted changes." "Consider git stash first."
fi

if matches "git[[:space:]]+rebase.*origin/($protected_branches)"; then
    ask "GIT-REBASE-PROTECTED" "Rebasing onto protected branch." "Ensure you are on a feature branch."
fi

if matches 'git[[:space:]]+clean[[:space:]]+-[a-z]*f[a-z]*d|git[[:space:]]+clean[[:space:]]+-[a-z]*d[a-z]*f'; then
    ask "GIT-CLEAN-FD" "git clean -fd deletes untracked files." "Run git clean -n first to preview."
fi

if matches "git[[:space:]]+checkout[[:space:]]+(-f|--force)[[:space:]]+($protected_branches)"; then
    ask "GIT-CHECKOUT-FORCE" "Force checkout discards local changes." "Stash or commit first."
fi

exit 0
