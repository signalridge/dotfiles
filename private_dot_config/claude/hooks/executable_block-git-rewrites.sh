#!/bin/bash
# Claude Git Safety Hook
# Blocks dangerous git operations that could rewrite history

# Get the command from Claude's input (passed as JSON via stdin)
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

if [[ -z "$COMMAND" ]]; then
    exit 0
fi

# Protected branches
PROTECTED_BRANCHES="main|master|develop|release"

# Check for dangerous operations
check_dangerous() {
    local cmd="$1"

    # Block force push to protected branches
    if echo "$cmd" | grep -qE 'git\s+push.*--force|git\s+push.*-f'; then
        # Check if pushing to protected branch
        if echo "$cmd" | grep -qE "($PROTECTED_BRANCHES)"; then
            echo '{"decision": "block", "reason": "BLOCKED: Force push to protected branch (main/master/develop/release) is not allowed. Use a feature branch instead."}'
            exit 0
        fi
        # Warn but allow force push to other branches
        echo '{"decision": "ask", "reason": "WARNING: Force push detected. This rewrites remote history. Are you sure?"}'
        exit 0
    fi

    # Block git commit --amend (with exceptions)
    if echo "$cmd" | grep -qE 'git\s+commit.*--amend'; then
        echo '{"decision": "ask", "reason": "WARNING: --amend rewrites the last commit. Only safe if: (1) commit not pushed to remote, (2) you made the original commit. Verify with: git status (should show \"ahead of origin\")"}'
        exit 0
    fi

    # Block hard reset
    if echo "$cmd" | grep -qE 'git\s+reset\s+--hard'; then
        echo '{"decision": "ask", "reason": "WARNING: git reset --hard will discard all uncommitted changes permanently. Consider using git stash first."}'
        exit 0
    fi

    # Block interactive rebase
    if echo "$cmd" | grep -qE 'git\s+rebase\s+-i|git\s+rebase\s+--interactive'; then
        echo '{"decision": "block", "reason": "BLOCKED: Interactive rebase requires manual input and is not supported. Use regular rebase or merge instead."}'
        exit 0
    fi

    # Block rebase on protected branches
    if echo "$cmd" | grep -qE 'git\s+rebase.*origin/('"$PROTECTED_BRANCHES"')'; then
        echo '{"decision": "ask", "reason": "WARNING: Rebasing onto protected branch. Make sure you are on a feature branch, not main/master."}'
        exit 0
    fi

    # Block git clean -fd (force delete untracked files)
    if echo "$cmd" | grep -qE 'git\s+clean\s+-[a-z]*f[a-z]*d|git\s+clean\s+-[a-z]*d[a-z]*f'; then
        echo '{"decision": "ask", "reason": "WARNING: git clean -fd will permanently delete untracked files and directories. Consider using git clean -n first to preview."}'
        exit 0
    fi

    # Block checkout with --force on protected branches
    if echo "$cmd" | grep -qE 'git\s+checkout\s+--force\s+('"$PROTECTED_BRANCHES"')|git\s+checkout\s+-f\s+('"$PROTECTED_BRANCHES"')'; then
        echo '{"decision": "ask", "reason": "WARNING: Force checkout will discard local changes."}'
        exit 0
    fi

    # Block branch deletion of protected branches
    if echo "$cmd" | grep -qE 'git\s+branch\s+-[dD]\s+('"$PROTECTED_BRANCHES"')|git\s+branch\s+--delete\s+('"$PROTECTED_BRANCHES"')'; then
        echo '{"decision": "block", "reason": "BLOCKED: Cannot delete protected branch (main/master/develop/release)."}'
        exit 0
    fi

    # Block push --delete of protected branches
    if echo "$cmd" | grep -qE 'git\s+push.*--delete\s+('"$PROTECTED_BRANCHES"')|git\s+push.*:\s*('"$PROTECTED_BRANCHES"')'; then
        echo '{"decision": "block", "reason": "BLOCKED: Cannot delete protected remote branch."}'
        exit 0
    fi
}

check_dangerous "$COMMAND"

# Allow all other commands
exit 0
