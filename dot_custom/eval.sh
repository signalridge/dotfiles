# shellcheck shell=bash
# Shell initialization helpers
# Conditionally eval commands only if the tool exists

eval_if_cmd_exists() {
    local cmd="$1"
    shift
    if command -v "$cmd" >/dev/null 2>&1; then
        local out=""
        out="$("$@" 2>/dev/null || true)"
        [[ -n "$out" ]] && eval "$out"
    fi
}

# Initialize shell tools
eval_if_cmd_exists "starship" starship init zsh
eval_if_cmd_exists "sheldon" sheldon source
eval_if_cmd_exists "fzf" fzf --zsh
eval_if_cmd_exists "navi" navi widget zsh
eval_if_cmd_exists "zoxide" zoxide init zsh
eval_if_cmd_exists "mise" mise activate zsh
eval_if_cmd_exists "atuin" atuin init zsh
eval_if_cmd_exists "direnv" direnv hook zsh
