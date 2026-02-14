# shellcheck shell=bash
# Shell initialization helpers
# Conditionally eval commands only if the tool exists

[[ -o interactive ]] || return 0
[[ -t 0 && -t 1 ]] || return 0

eval_if_cmd_exists() {
    local cmd="$1"
    shift
    if command -v "$cmd" >/dev/null 2>&1; then
        local out=""
        out="$("$@" 2>/dev/null || true)"
        [[ -n "$out" ]] && eval "$out"
    fi
}

eval_if_mise_activate() {
    local mise_cmd=""
    local out=""
    mise_cmd="$(command -v mise 2>/dev/null || true)"
    [[ -n "$mise_cmd" ]] || return 0

    # Skip aqua proxy wrapper for missing commands (can spawn repeated failures).
    case "$mise_cmd" in
    */aquaproj-aqua/bin/mise) return 0 ;;
    esac

    "$mise_cmd" --version >/dev/null 2>&1 || return 0
    out="$("$mise_cmd" activate zsh 2>/dev/null || true)"
    [[ -n "$out" ]] && eval "$out"
}

# Initialize shell tools
eval_if_cmd_exists "starship" starship init zsh
eval_if_cmd_exists "fzf" fzf --zsh
# Load sheldon after fzf so fzf-tab keeps Tab completion ownership.
eval_if_cmd_exists "sheldon" sheldon source
eval_if_cmd_exists "navi" navi widget zsh
eval_if_cmd_exists "zoxide" zoxide init zsh
eval_if_mise_activate
eval_if_cmd_exists "atuin" atuin init zsh
eval_if_cmd_exists "direnv" direnv hook zsh
