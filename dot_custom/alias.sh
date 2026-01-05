# shellcheck shell=bash
# Shell aliases
# Conditionally create aliases only if the tool exists

alias_if_cmd_exists() {
    local cmd="$1"
    local alias_name="$2"
    if command -v "$cmd" >/dev/null 2>&1; then
        # shellcheck disable=SC2139
        alias "$alias_name"="$cmd"
    fi
}

# Editor aliases
alias_if_cmd_exists "chezmoi" "dot"
alias_if_cmd_exists "nvim" "vi"
alias_if_cmd_exists "nvim" "vim"
alias_if_cmd_exists "nvim" "view"

# Modern CLI replacements
alias_if_cmd_exists "eza" "ls"
alias la="ls -a"
if command -v eza >/dev/null 2>&1; then
    alias ll="ls -l --git"
    alias lla="ls -la --git"
    alias lt="ls --tree"
else
    alias ll="ls -l"
fi

alias_if_cmd_exists "bat" "cat"
alias_if_cmd_exists "dust" "du"
alias_if_cmd_exists "duf" "df"
alias_if_cmd_exists "tldr" "man"
alias_if_cmd_exists "hyperfine" "hf"
alias_if_cmd_exists "lazygit" "lg"

# ─────────────────────────────────────────────────────────────
# Global Aliases (zsh only) - Expand anywhere in command line
# Usage: cat file G error  =>  cat file | grep error
# ─────────────────────────────────────────────────────────────
if [[ -n "$ZSH_VERSION" ]]; then
    alias -g L='| less'
    alias -g G='| grep'
    alias -g H='| head'
    alias -g T='| tail'
    alias -g W='| wc -l'
    alias -g S='| sort'
    alias -g U='| uniq'
    alias -g J='| jq'
    alias -g CP='| pbcopy'
    alias -g F='$(fzf)'
    alias -g N='>/dev/null 2>&1'
    alias -g N1='>/dev/null'
    alias -g N2='2>/dev/null'
fi

# ─────────────────────────────────────────────────────────────
# Quick Commands
# ─────────────────────────────────────────────────────────────
# yy - Copy last command to clipboard
alias yy="fc -ln -1 | tr -d '\n' | pbcopy && echo 'Copied to clipboard'"

# galias - List all global aliases
alias galias="alias -g"

# Safe file operations
alias cp="cp -iv"
alias mv="mv -iv"
alias mkdir="mkdir -pv"
