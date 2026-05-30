#!/usr/bin/env bash
# tmux2k ai status - stable AI agent counter for the tmux status bar.
#
# Shows foreground AI coding agent sessions (claude/codex/opencode) that are
# occupying tmux panes. The current window may be highlighted with a different
# shape, but busy state comes from explicit lifecycle hooks written by the
# agent runtime, with a narrow TUI-status fallback for already-running sessions
# that have not loaded the hook config yet. It does not use generic terminal
# output changes or keyboard input as an activity signal.
#
# Dot display:
#   No agents      -> (empty - segment hidden)
#   Busy turn      -> "●" (current: "◆")
#   Idle/unknown   -> "○" (current: "◇")
#   Example        -> "󰚩 ●◇●"
#
# Loaded directly from tmux.conf post-TPM, independent of tmux2k's
# plugin discovery. No symlink needed.

get_tmux_option() {
    local option_value
    option_value=$(tmux show-option -gqv "$1" 2>/dev/null || true)
    printf '%s\n' "${option_value:-$2}"
}

normalize_tty() {
    local tty="$1"
    tty="${tty#/dev/}"
    printf '%s\n' "$tty"
}

agent_tool_for_command() {
    local command_name="${1##*/}"

    case "$command_name" in
    claude)
        printf '%s\n' "claude"
        ;;
    codex | codex-aarch64-* | codex-x86_64-*)
        printf '%s\n' "codex"
        ;;
    opencode)
        printf '%s\n' "opencode"
        ;;
    *)
        return 1
        ;;
    esac
}

state_file_for_pane() {
    local cache_dir="$1"
    local pane_id="$2"
    local safe_pane_id

    safe_pane_id="${pane_id//[^[:alnum:]_.-]/_}"
    printf '%s/%s.state\n' "$cache_dir" "$safe_pane_id"
}

read_state_field() {
    local state_file="$1"
    local field="$2"

    awk -F= -v field="$field" '$1 == field { print substr($0, length(field) + 2); exit }' "$state_file"
}

pane_hook_state() {
    local pane_id="$1"
    local tool="$2"
    local pid="$3"
    local cache_dir="$4"
    local state_file state_tool state_value state_pid

    state_file=$(state_file_for_pane "$cache_dir" "$pane_id")
    [[ -r "$state_file" ]] || {
        printf '%s\n' "unknown"
        return
    }

    state_tool=$(read_state_field "$state_file" "tool")
    state_value=$(read_state_field "$state_file" "state")
    state_pid=$(read_state_field "$state_file" "pid")

    [[ "$state_tool" == "$tool" && "$state_pid" == "$pid" ]] || {
        printf '%s\n' "unknown"
        return
    }

    case "$state_value" in
    busy | idle)
        printf '%s\n' "$state_value"
        ;;
    *)
        printf '%s\n' "unknown"
        ;;
    esac
}

pane_tui_looks_busy() {
    local pane_id="$1"
    local screen

    screen=$(tmux capture-pane -p -t "$pane_id" -S -18 2>/dev/null || true)
    [[ -n "$screen" ]] || return 1

    # This is intentionally a narrow fallback for existing sessions that have
    # not reloaded hook config yet. Claude and Codex both expose an interrupt
    # hint while a turn is in progress; normal typing at an idle prompt does not.
    printf '%s\n' "$screen" | grep -Fq "esc to interrupt"
}

pane_is_busy() {
    local pane_id="$1"
    local tool="$2"
    local pid="$3"
    local cache_dir="$4"
    local hook_state

    hook_state=$(pane_hook_state "$pane_id" "$tool" "$pid" "$cache_dir")
    [[ "$hook_state" == "busy" ]] && return 0
    pane_tui_looks_busy "$pane_id"
}

ai_icon=$(get_tmux_option "@tmux2k-ai-icon" "󰚩")

main() {
    # $1 = optional current window target, e.g. "ws-7:3". This is used only to
    # change shape for the current agent pane, never to decide active vs idle.
    local target="${1:-}"

    tmux has-session 2>/dev/null || return

    # Build a set of TTYs owned by tmux panes. Matching by foreground TTY is
    # more stable than pane_current_command for Claude Code, which may appear
    # as its version number to tmux while the real foreground process is
    # still named "claude".
    local server_pid cache_dir
    server_pid=$(tmux display-message -p '#{pid}' 2>/dev/null || true)
    cache_dir="${TMPDIR:-/tmp}/tmux2k-ai-${server_pid:-default}"
    mkdir -p "$cache_dir" 2>/dev/null || return

    declare -A pane_ttys=()
    declare -A pane_ids=()
    local pane_ttys_order=()
    local pane_id pane_tty normalized_tty
    while IFS=$'\t' read -r pane_id pane_tty; do
        normalized_tty=$(normalize_tty "$pane_tty")
        [[ -n "$normalized_tty" && "$normalized_tty" != "??" ]] || continue
        pane_ttys[$normalized_tty]=1
        pane_ids[$normalized_tty]="$pane_id"
        pane_ttys_order+=("$normalized_tty")
    done < <(tmux list-panes -a -F '#{pane_id}	#{pane_tty}' 2>/dev/null || true)

    declare -A current_ttys=()
    if [[ -n "$target" ]]; then
        while IFS= read -r pane_tty; do
            normalized_tty=$(normalize_tty "$pane_tty")
            [[ -n "${pane_ttys[$normalized_tty]:-}" ]] || continue
            current_ttys[$normalized_tty]=1
        done < <(tmux list-panes -t "$target" -F '#{pane_tty}' 2>/dev/null || true)
    fi

    declare -A tty_tools=()
    declare -A tty_pids=()
    declare -A seen_ttys=()
    local _pid _ppid stat tty command_name tool

    # STAT contains "+" for processes in the foreground process group of
    # their controlling terminal. That gives us a stable "this agent occupies
    # this pane" signal without treating output activity as busy/idle state.
    while read -r _pid _ppid stat tty command_name; do
        [[ "$stat" == *+* ]] || continue
        normalized_tty=$(normalize_tty "$tty")
        [[ -n "${pane_ttys[$normalized_tty]:-}" ]] || continue
        [[ -z "${seen_ttys[$normalized_tty]:-}" ]] || continue

        if ! tool=$(agent_tool_for_command "$command_name"); then
            continue
        fi

        seen_ttys[$normalized_tty]=1
        tty_tools[$normalized_tty]="$tool"
        tty_pids[$normalized_tty]="$_pid"
    done < <(ps -eo pid=,ppid=,stat=,tty=,comm= 2>/dev/null || true)

    local dots="" pane_tool pane_pid
    for normalized_tty in "${pane_ttys_order[@]}"; do
        pane_tool="${tty_tools[$normalized_tty]:-}"
        [[ -n "$pane_tool" ]] || continue
        pane_pid="${tty_pids[$normalized_tty]:-}"
        [[ -n "$pane_pid" ]] || continue

        pane_id="${pane_ids[$normalized_tty]:-}"
        [[ -n "$pane_id" ]] || continue

        if pane_is_busy "$pane_id" "$pane_tool" "$pane_pid" "$cache_dir"; then
            if [[ -n "${current_ttys[$normalized_tty]:-}" ]]; then
                dots+="◆"
            else
                dots+="●"
            fi
        else
            if [[ -n "${current_ttys[$normalized_tty]:-}" ]]; then
                dots+="◇"
            else
                dots+="○"
            fi
        fi
    done

    [[ -n "$dots" ]] || return
    printf '%s %s\n' "$ai_icon" "$dots"
}

main "$@"
