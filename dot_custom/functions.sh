# shellcheck shell=bash
# ─────────────────────────────────────────────────────────────
# Alt+Up/Down Directory Navigation
# ─────────────────────────────────────────────────────────────
_cd_up() {
    cd .. || return 1
    zle reset-prompt
}

_cd_back() {
    cd - >/dev/null 2>&1 || return 1
    zle reset-prompt
}

zle -N _cd_up
zle -N _cd_back

# Alt+Up = cd .., Alt+Down = cd -
bindkey '^[[1;3A' _cd_up
bindkey '^[[1;3B' _cd_back

# Also support Option key on macOS Terminal.app
bindkey '^[^[[A' _cd_up
bindkey '^[^[[B' _cd_back

# FZF-powered shell functions

# ─────────────────────────────────────────────────────────────
# ghq + fzf Integration
# ─────────────────────────────────────────────────────────────

# dev - Interactive repository selector with ghq
# Usage: dev [query]
# Features:
#   - Fuzzy search through all ghq-managed repos
#   - Preview with eza tree + README + git branch
#   - Auto-rename tmux session
#   - Ctrl+O: open in VS Code
#   - Ctrl+E: open in editor
#   - Ctrl+Y: copy path to clipboard
dev() {
    local repo
    repo=$(
        ghq list | fzf \
            --query="${1:-}" \
            --preview '
            repo_path="$(ghq root)/{}"
            echo -e "\033[1;34m📁 {}\033[0m"
            echo ""
            # Show git branch if available
            if [ -d "$repo_path/.git" ]; then
                branch=$(git -C "$repo_path" branch --show-current 2>/dev/null)
                echo -e "\033[1;33m⎇ $branch\033[0m"
                echo ""
            fi
            # Show directory tree
            eza --tree --level=2 --color=always --icons --git-ignore "$repo_path" 2>/dev/null
            echo ""
            # Show README if exists
            for readme in "$repo_path"/README{,.md,.rst,.txt} "$repo_path"/readme{,.md}; do
                if [ -f "$readme" ]; then
                    echo -e "\033[1;32m📖 README\033[0m"
                    bat --color=always --style=plain --line-range=:20 "$readme" 2>/dev/null
                    break
                fi
            done
        ' \
            --preview-window='right:55%:border-left:wrap' \
            --header='Enter: cd | Ctrl+O: VS Code | Ctrl+E: Editor | Ctrl+Y: copy path' \
            --bind='ctrl-o:execute-silent(code "$(ghq root)/{}"),ctrl-e:execute(${EDITOR:-nvim} "$(ghq root)/{}"),ctrl-y:execute-silent(echo "$(ghq root)/{}" | pbcopy)+abort'
    )
    if [[ -n "$repo" ]]; then
        cd "$(ghq root)/$repo" || return 1
        # Rename tmux session if inside tmux
        if [[ -n "$TMUX" ]]; then
            tmux rename-session "${repo##*/}"
        fi
    fi
}

# Ctrl+G: Quick ghq jump (ZLE widget for instant access)
_ghq_fzf_cd() {
    local repo
    repo=$(
        ghq list | fzf \
            --height=40% \
            --reverse \
            --preview 'eza --tree --level=1 --color=always --icons "$(ghq root)/{}"' \
            --preview-window='right:40%:border-left'
    )
    if [[ -n "$repo" ]]; then
        # shellcheck disable=SC2034  # BUFFER is used by zle
        BUFFER="cd \"$(ghq root)/$repo\""
        zle accept-line
    fi
    zle reset-prompt
}
zle -N _ghq_fzf_cd
bindkey '^g' _ghq_fzf_cd # Ctrl+G for ghq jump

# Rebind navi to Ctrl+N (default is Ctrl+G which we use for ghq)
if [[ -n "$(whence _navi_widget)" ]]; then
    bindkey '^n' _navi_widget
fi

# ghq wrapper: no args = fzf select, with args = normal ghq
ghq() {
    if [[ $# -eq 0 ]]; then
        dev
    else
        command ghq "$@"
    fi
}

# ─────────────────────────────────────────────────────────────
# fgc - Fuzzy git checkout (branches)
# Usage: fgc
# ─────────────────────────────────────────────────────────────
fgc() {
    local branch
    branch=$(git branch -a --color=always |
        grep -v '/HEAD' |
        fzf --ansi --preview 'git log --oneline --graph --color=always {1}' |
        sed 's/^[* ]*//' |
        sed 's/remotes\/origin\///')
    if [[ -n "$branch" ]]; then
        git checkout "$branch"
    fi
}

# ─────────────────────────────────────────────────────────────
# fgl - Fuzzy git log (show commits)
# Usage: fgl
# ─────────────────────────────────────────────────────────────
fgl() {
    git log --oneline --color=always |
        fzf --ansi --preview 'git show --color=always {1}' |
        awk '{print $1}' |
        xargs -I {} git show {}
}

# ─────────────────────────────────────────────────────────────
# fga - Fuzzy git add (select files to stage)
# Usage: fga
# ─────────────────────────────────────────────────────────────
fga() {
    local files
    files=$(git status -s | fzf -m --preview 'git diff --color=always {2}' | awk '{print $2}')
    if [[ -n "$files" ]]; then
        echo "$files" | tr '\n' '\0' | xargs -0 git add
        git status -s
    fi
}

# ─────────────────────────────────────────────────────────────
# fkill - Fuzzy process kill (with confirmation)
# Usage: fkill [-9] (use -9 for SIGKILL, default is SIGTERM)
# ─────────────────────────────────────────────────────────────
fkill() {
    local signal="-15" # SIGTERM by default (graceful)
    [[ "$1" == "-9" ]] && signal="-9"

    local selection
    selection=$(ps aux | tail -n +2 | fzf -m --header="Select process(es) to kill (SIGTERM)")

    if [[ -z "$selection" ]]; then
        return 0
    fi

    local pids
    pids=$(echo "$selection" | awk '{print $2}')

    echo "Will kill the following PIDs with signal $signal:"
    echo "$pids"
    echo -n "Confirm? [y/N] "
    read -r confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo "$pids" | tr '\n' '\0' | xargs -0 kill "$signal"
        echo "Done."
    else
        echo "Cancelled."
    fi
}

# ─────────────────────────────────────────────────────────────
# fenv - Fuzzy environment variable viewer
# Usage: fenv
# ─────────────────────────────────────────────────────────────
fenv() {
    printenv | fzf
}

# ─────────────────────────────────────────────────────────────
# chezmoi-cd - Quick jump to chezmoi source
# Usage: chezmoi-cd
# ─────────────────────────────────────────────────────────────
chezmoi-cd() {
    cd "$(chezmoi source-path)" || return 1
}
alias dotcd="chezmoi-cd"

# ─────────────────────────────────────────────────────────────
# mkcd / take - Make directory and cd into it
# Usage: mkcd <dirname>
# ─────────────────────────────────────────────────────────────
mkcd() {
    mkdir -p "$1" && cd "$1" || return 1
}
alias take="mkcd" # Alternative name

# ─────────────────────────────────────────────────────────────
# aicommit - Generate commit message with AI CLI
# Usage: aicommit [--dry-run|-n] [provider] [type]
# Providers: codex (default), gemini, claude, auto
# Type: optional prefix override (wip, feat, fix, chore, etc.)
# Config: AICOMMIT_PROVIDER env var
# Note: For context-aware commits in Claude Code, use /commit command
# ─────────────────────────────────────────────────────────────
aicommit() {
    local dry_run=false
    local provider="${AICOMMIT_PROVIDER:-codex}"
    local type_override=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
        --dry-run | -n) dry_run=true ;;
        claude | codex | gemini | auto) provider="$1" ;;
        *) [[ -z "$type_override" ]] && type_override="$1" ;;
        esac
        shift
    done

    # Get staged diff
    local diff
    diff=$(git diff --cached --stat --patch)

    if [[ -z "$diff" ]]; then
        echo "No staged changes. Use 'git add' first."
        local untracked
        untracked=$(git ls-files --others --exclude-standard)
        if [[ -n "$untracked" ]]; then
            echo ""
            echo "Untracked files (use 'git add' to include):"
            echo "$untracked" | sed 's/^/  /'
        fi
        return 1
    fi

    # Prompt template
    local type_rule="- Types: feat, fix, docs, style, refactor, perf, test, chore"
    if [[ -n "$type_override" ]]; then
        type_rule="- MUST use type: $type_override"
    fi

    local prompt="Generate a concise git commit message following conventional commits format.

Rules:
- Use format: type(scope): description
${type_rule}
- Keep the first line under 72 characters
- Focus on WHY, not WHAT
- No period at the end
- Be specific but concise

Diff:
$diff

Return ONLY the commit message, nothing else."

    local message=""
    local error_output=""

    # Determine provider order
    local providers=()
    if [[ "$provider" == "auto" ]]; then
        providers=(gemini claude codex)
    else
        providers=("$provider")
    fi

    # Try providers in order
    for p in "${providers[@]}"; do
        [[ -n "$message" ]] && break
        case "$p" in
        claude)
            command -v claude &>/dev/null || continue
            error_output=$(echo "$prompt" | claude --print 2>&1) || continue
            [[ "$error_output" == *"error"* || "$error_output" == *"auth"* ]] && continue
            message=$(echo "$error_output" | head -1)
            ;;
        codex)
            command -v codex &>/dev/null || continue
            local tmp_out
            tmp_out=$(mktemp)
            # Use codex exec for non-interactive mode, output to temp file
            codex exec -o "$tmp_out" --skip-git-repo-check "$prompt" &>/dev/null || {
                rm -f "$tmp_out"
                continue
            }
            message=$(head -1 "$tmp_out" 2>/dev/null)
            rm -f "$tmp_out"
            [[ -z "$message" ]] && continue
            ;;
        gemini)
            command -v gemini &>/dev/null || continue
            # gemini-2.5-flash: fast, 1M context; --sandbox disables agentic mode
            error_output=$(gemini -m gemini-2.5-flash -o text --sandbox "$prompt" 2>&1) || continue
            [[ "$error_output" == *"error"* || "$error_output" == *"Error"* ]] && continue
            # Skip "Loaded cached credentials" line
            message=$(echo "$error_output" | grep -v "^Loaded" | head -1)
            ;;
        esac
    done

    if [[ -z "$message" ]]; then
        echo "Failed to generate commit message with provider: $provider"
        [[ -n "$error_output" ]] && echo -e "\nError: ${error_output:0:300}"
        return 1
    fi

    # Clean up: remove quotes, backticks, leading/trailing whitespace
    message=$(echo "$message" | sed -E 's/^[[:space:]`"'"'"']+//; s/[`"'"'"'[:space:]]+$//')

    if $dry_run; then
        echo "[$provider] $message"
    else
        echo "Committing: $message"
        git commit -m "$message"
    fi
}

# ─────────────────────────────────────────────────────────────
# Direnv Helper Functions
# ─────────────────────────────────────────────────────────────

# create_direnv_venv - Create Python venv with direnv
# Usage: create_direnv_venv
create_direnv_venv() {
    echo 'layout python' >.envrc
    direnv allow
}

# create_direnv_nix - Create Nix flake environment with direnv
# Usage: create_direnv_nix
create_direnv_nix() {
    echo 'use flake' >.envrc
    direnv allow
}

# create_direnv_mise - Create mise environment with direnv
# Usage: create_direnv_mise
create_direnv_mise() {
    echo 'use mise' >.envrc
    direnv allow
}

# ─────────────────────────────────────────────────────────────
# Project Creation
# ─────────────────────────────────────────────────────────────

# create_py_project - Quick Python project setup with uv
# Usage: create_py_project [name]
create_py_project() {
    local name="${1:-.}"
    if [[ "$name" != "." ]]; then
        mkdir -p "$name" && cd "$name" || return 1
    fi
    uv init
    create_direnv_venv
    echo "Python project created!"
}

# ─────────────────────────────────────────────────────────────
# System Utilities
# ─────────────────────────────────────────────────────────────

# o - Open in Finder (or default file manager)
# Usage: o [path]
o() {
    open "${1:-.}"
}

# port - Show process using a specific port
# Usage: port <port_number>
port() {
    if [[ -z "$1" ]]; then
        echo "Usage: port <port_number>"
        return 1
    fi
    lsof -i ":$1"
}

# clip - Copy stdin to clipboard (cross-platform)
# Usage: echo "text" | clip
clip() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        pbcopy
    else
        xclip -selection clipboard
    fi
}

# ─────────────────────────────────────────────────────────────
# GitHub Utilities
# ─────────────────────────────────────────────────────────────

# gh_latest - Get latest release version of a GitHub repo
# Usage: gh_latest <owner/repo>
gh_latest() {
    local repo="$1"
    if [[ -z "$repo" ]]; then
        echo "Usage: gh_latest <owner/repo>"
        return 1
    fi
    gh api "repos/${repo}/releases/latest" --jq '.tag_name'
}

# gh_clone - Clone a GitHub repo to ghq root
# Usage: gh_clone <owner/repo>
gh_clone() {
    local repo="$1"
    if [[ -z "$repo" ]]; then
        echo "Usage: gh_clone <owner/repo>"
        return 1
    fi
    ghq get "https://github.com/${repo}"
}

# ─────────────────────────────────────────────────────────────
# Quick Edit
# ─────────────────────────────────────────────────────────────

# dotfiles - Open dotfiles in editor
# Usage: dotfiles
dotfiles() {
    ${EDITOR:-nvim} "$(chezmoi source-path)"
}

# zshconfig - Edit zsh config
# Usage: zshconfig
zshconfig() {
    ${EDITOR:-nvim} "$(chezmoi source-path)/dot_zshrc"
}

# ─────────────────────────────────────────────────────────────
# Development Environment Backup
# ─────────────────────────────────────────────────────────────

# backup_dev_env - Backup development environment configs
# Usage: backup_dev_env
backup_dev_env() {
    local backup_dir="${1:-$(chezmoi source-path)/backups}"
    local date_str
    date_str=$(date +%Y%m%d)

    mkdir -p "$backup_dir"

    echo "Backing up development environment..."

    # Brewfile
    if command -v brew &>/dev/null; then
        echo "  - Generating Brewfile..."
        brew bundle dump --force --file="$backup_dir/Brewfile.$date_str"
    fi

    # mise tools
    if command -v mise &>/dev/null; then
        echo "  - Backing up mise config..."
        mise list --json >"$backup_dir/mise-tools.$date_str.json" 2>/dev/null || true
    fi

    # VS Code extensions
    if command -v code &>/dev/null; then
        echo "  - Backing up VS Code extensions..."
        code --list-extensions >"$backup_dir/vscode-extensions.$date_str.txt"
    fi

    # npm global packages
    if command -v npm &>/dev/null; then
        echo "  - Backing up npm global packages..."
        npm list -g --depth=0 --json >"$backup_dir/npm-global.$date_str.json" 2>/dev/null || true
    fi

    echo "Backup completed: $backup_dir"
}

# restore_vscode_ext - Restore VS Code extensions from backup
# Usage: restore_vscode_ext [backup_file]
restore_vscode_ext() {
    local backup_file="${1:-$(chezmoi source-path)/backups/vscode-extensions.txt}"
    if [[ -f "$backup_file" ]]; then
        echo "Restoring VS Code extensions from $backup_file..."
        xargs -L 1 code --install-extension <"$backup_file"
    else
        echo "Backup file not found: $backup_file"
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────
# Git Utilities
# Note: Some of these also exist as git aliases, but shell functions
# provide additional features (cd, user feedback, etc.)
# ─────────────────────────────────────────────────────────────

# git-root - Jump to git repository root (can't be a git alias - needs cd)
# Usage: git-root
git-root() {
    local root
    root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -n "$root" ]]; then
        cd "$root" || return 1
    else
        echo "Not in a git repository"
        return 1
    fi
}

# git-undo - Undo last commit (keep changes staged)
# Usage: git-undo
git-undo() {
    git reset --soft HEAD~1
    echo "Last commit undone. Changes are staged."
}

# git-branches - Show branches sorted by last commit date
# Usage: git-branches
git-branches() {
    git for-each-ref --sort=-committerdate refs/heads/ \
        --format='%(color:blue)%(committerdate:relative)%(color:reset) %(color:green)%(refname:short)%(color:reset) %(color:yellow)%(authorname)%(color:reset)'
}

# git-cleanup - Delete merged branches
# Usage: git-cleanup
git-cleanup() {
    local branches
    branches=$(git branch --merged | grep -v '\*' | grep -v 'main' | grep -v 'master')
    if [[ -z "$branches" ]]; then
        echo "No merged branches to delete"
        return 0
    fi
    echo "Branches to delete:"
    echo "$branches"
    echo ""
    printf "Delete these branches? [y/N] "
    read -r confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo "$branches" | xargs git branch -d
        echo "Done."
    else
        echo "Cancelled."
    fi
}

# ─────────────────────────────────────────────────────────────
# Quick Directory Operations
# ─────────────────────────────────────────────────────────────

# up - Go up N directories
# Usage: up 3  (equivalent to cd ../../..)
up() {
    local count="${1:-1}"
    # Validate: must be positive integer, max 20 levels
    if ! [[ "$count" =~ ^[0-9]+$ ]] || [[ "$count" -lt 1 ]] || [[ "$count" -gt 20 ]]; then
        echo "Usage: up <1-20>"
        return 1
    fi
    local path=""
    for ((i = 0; i < count; i++)); do
        path="../$path"
    done
    cd "$path" || return 1
}

# ─────────────────────────────────────────────────────────────
# AeroSpace Utilities (macOS only)
# ─────────────────────────────────────────────────────────────

if [[ "$OSTYPE" == darwin* ]] && command -v aerospace &>/dev/null; then
    # wsrun - Run command in specified workspace
    # Usage: wsrun <workspace> <command> [args...]
    # Examples:
    #   wsrun 5 code .              # Open VS Code in workspace 5
    #   wsrun 4 code ~/project      # Open project in workspace 4
    #   wsrun 6 open -a Safari      # Open Safari in workspace 6
    #   wsrun 3 open ~/Documents    # Open Finder in workspace 3
    wsrun() {
        if [[ $# -lt 2 ]]; then
            echo "Usage: wsrun <workspace> <command> [args...]"
            echo "Examples:"
            echo "  wsrun 5 code .          # VS Code in workspace 5"
            echo "  wsrun 4 open -a Safari  # Safari in workspace 4"
            return 1
        fi
        local workspace="$1"
        shift
        aerospace workspace "$workspace" && "$@"
    }

    # ws - Quick workspace switch
    # Usage: ws <number>
    ws() {
        aerospace workspace "${1:-1}"
    }

    # wsm - Move current window to workspace
    # Usage: wsm <number>
    wsm() {
        aerospace move-node-to-workspace "${1:-1}"
    }
fi

# ─────────────────────────────────────────────────────────────
# Completion Functions for Custom Scripts
# ─────────────────────────────────────────────────────────────

# Account list helper for completions (avoid ANSI parsing)
_ai_tool_accounts() {
    local tool="$1"

    if ! command -v chezmoi &>/dev/null || ! command -v jq &>/dev/null; then
        return 0
    fi

    case "$tool" in
    claude)
        chezmoi data --format json 2>/dev/null | jq -r '.claude.accounts // {} | keys[]' 2>/dev/null
        ;;
    codex)
        chezmoi data --format json 2>/dev/null | jq -r '.codex.accounts // {} | keys[]' 2>/dev/null
        ;;
    esac
}

# claude-manage completion
_claude_manage() {
    local curcontext="$curcontext" state line
    typeset -A opt_args

    local -a commands=(
        'switch:Change default account'
        'sw:Change default account (alias)'
        'add-account:Add new account'
        'edit-account:Edit account config'
        'remove-account:Remove account'
        'add-key:Add API key'
        'update-key:Update API key'
        'delete-key:Delete API key'
        'test:Test connectivity'
        'list:List accounts'
        'ls:List accounts (alias)'
        'current:Show current account'
        'help:Show help'
    )

    _arguments -C \
        '1: :->command' \
        '*: :->account'

    case "$state" in
    command)
        _describe -t commands 'claude-manage commands' commands
        ;;
    account)
        case "${line[1]}" in
        switch | sw | test | add-key | update-key | delete-key | edit-account | remove-account)
            local -a accounts
            local acct
            while IFS= read -r acct; do
                [[ -n "$acct" ]] && accounts+=("$acct")
            done < <(_ai_tool_accounts claude)
            _describe -t accounts 'accounts' accounts
            ;;
        esac
        ;;
    esac
}

# claude-with completion
_claude_with() {
    local curcontext="$curcontext"
    typeset -A opt_args

    local -a accounts
    local acct
    while IFS= read -r acct; do
        [[ -n "$acct" ]] && accounts+=("$acct")
    done < <(_ai_tool_accounts claude)

    _arguments -C \
        '1:account:->_accounts' \
        '*:claude options:->options'

    case "$state" in
    _accounts)
        _describe -t accounts 'accounts' accounts
        ;;
    esac
}

# codex-manage completion
_codex_manage() {
    local curcontext="$curcontext" state line
    typeset -A opt_args

    # shellcheck disable=SC2034
    local -a commands=(
        'switch:Change default account'
        'sw:Change default account (alias)'
        'add-account:Add new account'
        'edit-account:Edit account config'
        'remove-account:Remove account'
        'add-key:Add API key'
        'update-key:Update API key'
        'delete-key:Delete API key'
        'test:Test connectivity'
        'list:List accounts'
        'ls:List accounts (alias)'
        'current:Show current account'
        'help:Show help'
    )

    _arguments -C \
        '1: :->command' \
        '*: :->account'

    case "$state" in
    command)
        _describe -t commands 'codex-manage commands' commands
        ;;
    account)
        case "${line[1]}" in
        switch | sw | test | add-key | update-key | delete-key | edit-account | remove-account)
            local -a accounts
            local acct
            while IFS= read -r acct; do
                [[ -n "$acct" ]] && accounts+=("$acct")
            done < <(_ai_tool_accounts codex)
            _describe -t accounts 'accounts' accounts
            ;;
        esac
        ;;
    esac
}

# codex-with completion
_codex_with() {
    local curcontext="$curcontext"
    # shellcheck disable=SC2034
    typeset -A opt_args

    local -a accounts
    local acct
    while IFS= read -r acct; do
        [[ -n "$acct" ]] && accounts+=("$acct")
    done < <(_ai_tool_accounts codex)

    _arguments -C \
        '1:account:->_accounts' \
        '*:codex options:->options'

    case "$state" in
    _accounts)
        _describe -t accounts 'accounts' accounts
        ;;
    esac
}

# Register completions when in zsh
if [[ -n "$ZSH_VERSION" ]]; then
    compdef _claude_manage claude-manage 2>/dev/null
    compdef _claude_manage ccm 2>/dev/null
    compdef _claude_with claude-with 2>/dev/null
    compdef _claude_with ccw 2>/dev/null
    compdef _codex_manage codex-manage 2>/dev/null
    compdef _codex_manage cxm 2>/dev/null
    compdef _codex_with codex-with 2>/dev/null
    compdef _codex_with cxw 2>/dev/null
fi

# ─────────────────────────────────────────────────────────────
# Claude Code Integration
# ─────────────────────────────────────────────────────────────

# ccc - Launch Claude Code in current directory
# Usage: ccc [args...]
ccc() {
    if command -v claude &>/dev/null; then
        claude "$@"
    else
        echo "Claude Code not installed. Install from: https://docs.anthropic.com/claude-code"
        return 1
    fi
}

# ccr - Resume last Claude Code session
# Usage: ccr
ccr() {
    if command -v claude &>/dev/null; then
        claude --resume
    else
        echo "Claude Code not installed"
        return 1
    fi
}

# ccp - Claude Code with specific prompt
# Usage: ccp "your prompt here"
ccp() {
    if [[ -z "$1" ]]; then
        echo "Usage: ccp \"your prompt\""
        return 1
    fi
    if command -v claude &>/dev/null; then
        claude -p "$1"
    else
        echo "Claude Code not installed"
        return 1
    fi
}
