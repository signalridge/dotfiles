#!/usr/bin/env bash
# tmux2k ai plugin — AI agent counter for the status bar.
#
# Shows the number of AI coding agents (claude/codex/opencode) running in
# tmux panes. When no agents exist, outputs nothing (segment collapses).
#
# Display:
#   No agents  → (empty — segment hidden)
#   All quiet  → "󰚩 3"      (3 agents, no new output)
#   Has alerts → "󰚩 2/5"    (2 of 5 agents have unseen output)
#
# Deployed by chezmoi to ~/.config/tmux/tmux2k-ai.sh, then symlinked
# into the tmux2k plugins dir by run_after_12_sync-tmux2k-ai.sh.

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$current_dir/../lib/utils.sh"

ai_icon=$(get_tmux_option "@tmux2k-ai-icon" "󰚩")

main() {
    tmux has-session 2>/dev/null || return

    # Fast path: find AI agent processes by real binary name.
    # ps comm gives the executable basename — immune to aqua's argv[0] rewrite.
    local agents
    agents=$(ps -eo pid,ppid,comm 2>/dev/null |
        awk '$3 ~ /^(claude|codex|opencode)$/ {print $2}' || true)
    [[ -z "$agents" ]] && return

    # Map tmux pane_pid → window_activity_flag (1 = unseen output).
    declare -A pane_activity=()
    while IFS=' ' read -r ppid flag; do
        [[ -n "$ppid" ]] && pane_activity[$ppid]=$flag
    done < <(tmux list-panes -a -F '#{pane_pid} #{?window_activity_flag,1,0}' 2>/dev/null || true)

    local total=0 alert=0
    while read -r parent_pid; do
        [[ -z "$parent_pid" ]] && continue
        if [[ -n "${pane_activity[$parent_pid]:-}" ]]; then
            total=$((total + 1))
            [[ "${pane_activity[$parent_pid]}" == "1" ]] && alert=$((alert + 1))
        fi
    done <<<"$agents"

    ((total == 0)) && return

    if ((alert > 0)); then
        echo "$ai_icon $alert/$total"
    else
        echo "$ai_icon $total"
    fi
}

main
