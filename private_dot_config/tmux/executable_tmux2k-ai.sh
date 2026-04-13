#!/usr/bin/env bash
# tmux2k ai plugin — AI agent counter for the status bar.
#
# Shows AI coding agents (claude/codex/opencode) running in tmux panes.
# Uses window_activity timestamps for consistent active/idle counts, and
# the current window target ($1) to mark which agent is "here" (◆).
#
# Display:
#   No agents  → (empty — segment hidden)
#   In AI win  → "󰚩 ●◆○"  (◆ at this agent's position among all agents)
#   In shell   → "󰚩 ●●○"  (no ◆ — current window has no agent)
#
# Deployed by chezmoi to ~/.config/tmux/tmux2k-ai.sh, then symlinked
# into the tmux2k plugins dir by run_after_12_sync-tmux2k-ai.sh.

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$current_dir/../lib/utils.sh"

ai_icon=$(get_tmux_option "@tmux2k-ai-icon" "󰚩")
# Seconds of inactivity before an agent is considered idle.
activity_threshold=$(get_tmux_option "@tmux2k-ai-activity-threshold" "30")

main() {
    # $1 = current window target, e.g. "ws-7:3" (session:window_index).
    # Passed via #{session_name}:#{window_index} in the tmux format string.
    local target="${1:-}"

    tmux has-session 2>/dev/null || return

    # Fast path: find AI agent processes by real binary name.
    local agents
    agents=$(ps -eo pid,ppid,comm 2>/dev/null |
        awk '$3 ~ /^(claude|codex|opencode)$/ {print $2}' || true)
    [[ -z "$agents" ]] && return

    # Build a set of AI agent parent PIDs for quick lookup.
    declare -A agent_set=()
    while read -r parent_pid; do
        [[ -n "$parent_pid" ]] && agent_set[$parent_pid]=1
    done <<<"$agents"

    # Collect current window's pane PIDs for the ◆ marker.
    declare -A current_panes=()
    if [[ -n "$target" ]]; then
        while IFS=' ' read -r ppid; do
            [[ -n "$ppid" ]] && current_panes[$ppid]=1
        done < <(tmux list-panes -t "$target" -F '#{pane_pid}' 2>/dev/null || true)
    fi

    # Walk panes in tmux's natural order (stable across refreshes).
    # Each AI agent gets a fixed position; ◆ appears at the right slot.
    local now dots=""
    now=$(date +%s)
    while IFS=' ' read -r ppid ts; do
        [[ -n "${agent_set[$ppid]:-}" ]] || continue
        if [[ -n "${current_panes[$ppid]:-}" ]]; then
            dots+="◆"
        elif ((now - ts < activity_threshold)); then
            dots+="●"
        else
            dots+="○"
        fi
    done < <(tmux list-panes -a -F '#{pane_pid} #{window_activity}' 2>/dev/null || true)

    [[ -z "$dots" ]] && return
    echo "$ai_icon $dots"
}

main "$@"
