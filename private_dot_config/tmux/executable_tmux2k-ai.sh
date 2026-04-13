#!/usr/bin/env bash
# tmux2k ai plugin — AI agent counter for the status bar.
#
# Shows AI coding agents (claude/codex/opencode) running in tmux panes.
# Uses window_activity timestamps (not window_activity_flag) to determine
# which agents are active, so the result is consistent across all windows
# regardless of which one the user is currently viewing.
#
# Display:
#   No agents → (empty — segment hidden)
#   All quiet → "󰚩 ○○○"   (3 agents, none active recently)
#   Has active → "󰚩 ●○○"  (1 of 3 had output in last N seconds)
#
# Deployed by chezmoi to ~/.config/tmux/tmux2k-ai.sh, then symlinked
# into the tmux2k plugins dir by run_after_12_sync-tmux2k-ai.sh.

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$current_dir/../lib/utils.sh"

ai_icon=$(get_tmux_option "@tmux2k-ai-icon" "󰚩")
# Seconds of inactivity before an agent is considered idle.
activity_threshold=$(get_tmux_option "@tmux2k-ai-activity-threshold" "30")

main() {
    tmux has-session 2>/dev/null || return

    # Fast path: find AI agent processes by real binary name.
    local agents
    agents=$(ps -eo pid,ppid,comm 2>/dev/null |
        awk '$3 ~ /^(claude|codex|opencode)$/ {print $2}' || true)
    [[ -z "$agents" ]] && return

    # Map pane_pid → window_activity (absolute unix timestamp).
    # Unlike window_activity_flag this does not depend on which window
    # the user is currently viewing, so the result is globally stable.
    declare -A pane_ts=()
    while IFS=' ' read -r ppid ts; do
        [[ -n "$ppid" ]] && pane_ts[$ppid]=$ts
    done < <(tmux list-panes -a -F '#{pane_pid} #{window_activity}' 2>/dev/null || true)

    local now total=0 active=0
    now=$(date +%s)

    while read -r parent_pid; do
        [[ -n "${pane_ts[$parent_pid]:-}" ]] || continue
        total=$((total + 1))
        ((now - pane_ts[$parent_pid] < activity_threshold)) && active=$((active + 1))
    done <<<"$agents"

    ((total == 0)) && return

    # Build dot indicators: ● = recent output, ○ = idle
    local dots="" i
    for ((i = 0; i < active; i++)); do dots+="●"; done
    for ((i = 0; i < total - active; i++)); do dots+="○"; done
    echo "$ai_icon $dots"
}

main
