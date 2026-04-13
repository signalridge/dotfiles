#!/usr/bin/env bash
# tmux2k ai plugin — AI agent counter for the status bar.
#
# Shows the total number of AI coding agents (claude/codex/opencode)
# running inside tmux panes. When none exist, outputs nothing.
# Activity-level alerts are left to tmux's monitor-activity (window
# tab highlighting), avoiding #() cache vs activity-flag race conditions.
#
# Display:
#   No agents → (empty — segment hidden)
#   Has agents → "󰚩 3"
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

    # Collect all tmux pane PIDs to confirm agents live inside tmux.
    declare -A pane_pids=()
    while IFS=' ' read -r ppid; do
        [[ -n "$ppid" ]] && pane_pids[$ppid]=1
    done < <(tmux list-panes -a -F '#{pane_pid}' 2>/dev/null || true)

    local total=0
    while read -r parent_pid; do
        [[ -n "${pane_pids[$parent_pid]:-}" ]] && total=$((total + 1))
    done <<<"$agents"

    ((total == 0)) && return
    echo "$ai_icon $total"
}

main
