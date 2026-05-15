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
    local aqua_mise_cmd=""
    local aqua_config_path=""

    aqua_mise_cmd="${AQUA_ROOT_DIR:-${XDG_DATA_HOME}/aquaproj-aqua}/bin/mise"
    aqua_config_path="${XDG_CONFIG_HOME:-$HOME/.config}/aquaproj-aqua/aqua.yaml"
    if [[ -n "${AQUA_GLOBAL_CONFIG:-}" ]]; then
        aqua_config_path="${AQUA_GLOBAL_CONFIG%%:*}"
    fi

    if [[ -x "$aqua_mise_cmd" ]] &&
        [[ -f "$aqua_config_path" ]] &&
        grep -Eq '^[[:space:]]*-[[:space:]]+name:[[:space:]]+jdx/mise@' "$aqua_config_path"; then
        mise_cmd="$aqua_mise_cmd"
    else
        mise_cmd="$(command -v mise 2>/dev/null || true)"
    fi

    [[ -n "$mise_cmd" ]] || return 0

    "$mise_cmd" --version >/dev/null 2>&1 || return 0
    out="$("$mise_cmd" activate zsh 2>/dev/null || true)"
    [[ -n "$out" ]] && eval "$out"
}

# Initialize shell tools
eval_if_cmd_exists "starship" starship init zsh
eval_if_cmd_exists "fzf" fzf --zsh
# Load sheldon after fzf so fzf-tab keeps Tab completion ownership.
eval_if_cmd_exists "sheldon" sheldon source
eval_if_cmd_exists "carapace" carapace _carapace
eval_if_cmd_exists "navi" navi widget zsh
eval_if_cmd_exists "zoxide" zoxide init zsh
eval_if_mise_activate
eval_if_cmd_exists "atuin" atuin init zsh
eval_if_cmd_exists "direnv" direnv hook zsh
