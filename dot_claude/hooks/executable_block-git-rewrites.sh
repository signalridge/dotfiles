#!/bin/bash
# block-git-rewrites.sh - Guard dangerous git history rewrite operations.
# Hook type: PreToolUse (Bash)
#
# Design goals (low-noise, unified output):
# - BLOCK: only for truly irreversible/dangerous actions (rare).
# - ASK: for risky but recoverable actions.
# - Output: 2 lines max (status + next remediation).

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

cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // ""' 2>/dev/null || echo "")
[[ -n "$cwd" ]] || cwd="$PWD"
chezmoi_source="$HOME/.local/share/chezmoi"

protected_branches='main|master|develop|release'

matches() {
    local pattern="$1"
    printf '%s\n' "$command" | grep -qE "$pattern"
}

# A git rule only counts when git is in COMMAND POSITION: at the start of a
# line, or immediately after a shell separator, with any leading VAR=value
# assignments skipped. grep works line by line, so `^` already covers a newline
# separator.
#
# WHY (added 2026-09-06). Every rule below used to grep the raw command TEXT, so
# merely MENTIONING one tripped it -- writing a test that asserts on the string
# "git worktree *", grepping a config for it, or echoing it in a message. That is
# not hypothetical: it blocked this repository's own permission-policy test, and
# it is the third instance of the same family of defect found in one day (the
# other two were the global `Bash(git:*)` deny rules and the global
# pi-permission-system git bans).
#
# THE TRADE IS DELIBERATE. A git call hidden inside a quoted string that some
# other program then executes -- `bash -c '...'`, a heredoc piped to a shell --
# is no longer matched. This hook is an accident guard, not a sandbox: the
# sessions it runs in are bypassPermissions by policy, so a false block on
# routine work costs more than a miss on a deliberately indirect invocation.
# If you need a real boundary, use the OS sandbox, not a text pattern.
cmd_position='(^|[;&|(){}])[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*'

git_cmd() {
    matches "${cmd_position}git[[:space:]]+$1"
}

# Unified output: 2 lines (status + Next action)
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

# The chezmoi source tree is the live main checkout. Worktrees and branch
# switching are forbidden there because chezmoi recursively consumes its data.
if [[ "$cwd" == "$chezmoi_source" || "$cwd" == "$chezmoi_source/"* ]]; then
    if git_cmd 'worktree([[:space:]]|$)'; then
        block "GIT-WORKTREE" "Worktrees are forbidden in the chezmoi source tree." "Edit the shared main checkout instead."
    fi

    if git_cmd 'switch([[:space:]]|$)'; then
        block "GIT-BRANCH-SWITCH" "Branch switching or creation is forbidden in the chezmoi source tree." "Stay on the shared main checkout."
    fi

    # Any checkout that can move HEAD. The previous pattern matched only the
    # flag forms (-b/--branch/--orphan), so a plain `git checkout <branch>` --
    # the whole switch, minus the flag -- walked straight through it; pairing it
    # with `git branch <name>` reproduced exactly what -b does. `git checkout --
    # <path>` restores a file without leaving the branch, so it stays allowed.
    if git_cmd 'checkout([[:space:]]|$)' &&
        ! git_cmd 'checkout[[:space:]]+--([[:space:]]|$)'; then
        block "GIT-BRANCH-SWITCH" "Branch switching or creation is forbidden in the chezmoi source tree." "Stay on the shared main checkout; use 'git restore' to discard file changes."
    fi
fi

if git_cmd 'rebase[[:space:]]+(-i|--interactive)'; then
    block "GIT-REBASE-I" "Interactive rebase requires manual input." "Use regular rebase or merge instead."
fi

if git_cmd "branch[[:space:]]+(-d|-D|--delete)[[:space:]]+($protected_branches)"; then
    block "GIT-DELETE-PROTECTED" "Cannot delete protected branch." "Use a feature branch."
fi

if git_cmd "push.*(--delete[[:space:]]+($protected_branches)|:[[:space:]]*($protected_branches))"; then
    block "GIT-PUSH-DELETE-PROTECTED" "Cannot delete protected remote branch." "Use a feature branch."
fi

# The force-flag and branch-name checks stay unanchored on purpose: they are
# secondary conditions, only reached once a real `git push` has been found in
# command position by the check on their left.
if git_cmd 'push' && matches '(^|[[:space:]])(--force|-f)([[:space:]]|$)'; then
    if matches "($protected_branches)"; then
        block "GIT-FORCE-PUSH-PROTECTED" "Force push to protected branch not allowed." "Use a feature branch."
    fi
fi

# --- ASK rules (risky but recoverable) ---

if git_cmd 'push' && matches '(^|[[:space:]])(--force|-f)([[:space:]]|$)'; then
    ask "GIT-FORCE-PUSH" "Force push rewrites remote history." "Confirm you want to rewrite."
fi

if git_cmd 'commit.*--amend'; then
    ask "GIT-AMEND" "--amend rewrites the last commit." "Verify commit not pushed (git status shows ahead)."
fi

if git_cmd 'reset[[:space:]]+--hard'; then
    ask "GIT-RESET-HARD" "git reset --hard discards uncommitted changes." "Consider git stash first."
fi

if git_cmd "rebase.*origin/($protected_branches)"; then
    ask "GIT-REBASE-PROTECTED" "Rebasing onto protected branch." "Ensure you are on a feature branch."
fi

if git_cmd 'clean[[:space:]]+(-[a-z]*f[a-z]*d|-[a-z]*d[a-z]*f)'; then
    ask "GIT-CLEAN-FD" "git clean -fd deletes untracked files." "Run git clean -n first to preview."
fi

if git_cmd "checkout[[:space:]]+(-f|--force)[[:space:]]+($protected_branches)"; then
    ask "GIT-CHECKOUT-FORCE" "Force checkout discards local changes." "Stash or commit first."
fi

exit 0
