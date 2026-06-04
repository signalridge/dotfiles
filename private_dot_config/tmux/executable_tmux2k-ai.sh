#!/usr/bin/env bash
# tmux2k ai status - stable AI agent counter for the tmux status bar.
#
# Shows foreground AI coding agent sessions (claude/codex) that are
# occupying tmux panes. The current window may be highlighted with a different
# shape, but busy state comes from explicit lifecycle hooks written by the
# agent runtime, with a narrow TUI-status fallback for already-running sessions
# that have not loaded the hook config yet. It does not use generic terminal
# output changes or keyboard input as an activity signal.
#
# Dot display:
#   No agents      -> (empty - segment hidden)
#   Busy turn      -> "■" (current: "●")
#   Idle/unknown   -> "□" (current: "○")
#   Example        -> "󰚩 ■○■"
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

state_file_matches_pane() {
    local state_file="$1"
    local tool="$2"
    local pid="$3"
    local state_tool state_pid

    [[ -r "$state_file" ]] || return 1

    state_tool=$(read_state_field "$state_file" "tool")
    state_pid=$(read_state_field "$state_file" "pid")
    [[ "$state_tool" == "$tool" && "$state_pid" == "$pid" ]]
}

pane_hook_state() {
    local pane_id="$1"
    local tool="$2"
    local pid="$3"
    local cache_dir="$4"
    local state_file state_value

    state_file=$(state_file_for_pane "$cache_dir" "$pane_id")
    state_file_matches_pane "$state_file" "$tool" "$pid" || {
        printf '%s\n' "unknown"
        return
    }
    state_value=$(read_state_field "$state_file" "state")

    case "$state_value" in
    busy | idle)
        printf '%s\n' "$state_value"
        ;;
    *)
        printf '%s\n' "unknown"
        ;;
    esac
}

pane_hook_state_age_seconds() {
    local pane_id="$1"
    local tool="$2"
    local pid="$3"
    local cache_dir="$4"
    local state_file state_updated_at now

    state_file=$(state_file_for_pane "$cache_dir" "$pane_id")
    state_file_matches_pane "$state_file" "$tool" "$pid" || return 1

    state_updated_at=$(read_state_field "$state_file" "updated_at")
    [[ "$state_updated_at" =~ ^[0-9]+$ ]] || return 1

    now=$(date +%s 2>/dev/null || true)
    [[ "$now" =~ ^[0-9]+$ ]] || return 1
    ((now >= state_updated_at)) || return 1

    printf '%s\n' "$((now - state_updated_at))"
}

pane_transcript_after_state() {
    local state_file="$1"
    local max_lines="${2:-120}"
    local transcript_path transcript_line_count start_line

    transcript_path=$(read_state_field "$state_file" "transcript_path")
    [[ -n "$transcript_path" && -r "$transcript_path" ]] || return 1

    transcript_line_count=$(read_state_field "$state_file" "transcript_line_count")
    if [[ "$transcript_line_count" =~ ^[0-9]+$ ]]; then
        start_line=$((transcript_line_count + 1))
        tail -n +"$start_line" "$transcript_path" 2>/dev/null | tail -"$max_lines"
        return
    fi

    tail -"$max_lines" "$transcript_path" 2>/dev/null
}

pane_transcript_records_user_abort() {
    local pane_id="$1"
    local tool="$2"
    local pid="$3"
    local cache_dir="$4"
    local state_file recent turn_id

    state_file=$(state_file_for_pane "$cache_dir" "$pane_id")
    state_file_matches_pane "$state_file" "$tool" "$pid" || return 1

    recent=$(pane_transcript_after_state "$state_file" 160) || return 1
    [[ -n "$recent" ]] || return 1

    case "$tool" in
    codex)
        turn_id=$(read_state_field "$state_file" "turn_id")
        if [[ -n "$turn_id" ]] &&
            printf '%s\n' "$recent" | grep -F "\"turn_id\":\"$turn_id\"" | grep -Eq '"type"[[:space:]]*:[[:space:]]*"turn_aborted"|<turn_aborted>'; then
            return 0
        fi

        printf '%s\n' "$recent" | grep -Eq '"type"[[:space:]]*:[[:space:]]*"turn_aborted"|<turn_aborted>'
        ;;
    claude)
        printf '%s\n' "$recent" | grep -Fq '[Request interrupted by user]'
        ;;
    *)
        return 1
        ;;
    esac
}

pane_recent_nonblank() {
    local pane_id="$1"
    local line_count="${2:-12}"
    local screen

    screen=$(tmux capture-pane -p -t "$pane_id" -S -60 2>/dev/null || true)
    [[ -n "$screen" ]] || return 1
    printf '%s\n' "$screen" | sed '/^[[:space:]]*$/d' | tail -"$line_count"
}

pane_tui_looks_busy() {
    local pane_id="$1"
    local recent

    recent=$(pane_recent_nonblank "$pane_id" 8) || return 1

    # This is intentionally a narrow fallback for existing sessions that have
    # not reloaded hook config yet. Claude and Codex both expose an interrupt
    # hint while a turn is in progress. Only inspect the bottom status area so
    # stale "esc to interrupt" text already pushed into scrollback does not
    # override a later idle prompt.
    printf '%s\n' "$recent" | tail -5 | grep -Fq 'esc to interrupt' ||
        printf '%s\n' "$recent" | grep -Eq '(Working|Waiting for background terminal) .*esc to interrupt|esc to interrupt.*(Working|Waiting for background terminal)'
}

pane_tui_looks_idle_after_abort() {
    local pane_id="$1"
    local tool="$2"
    local recent

    recent=$(pane_recent_nonblank "$pane_id" 12) || return 1
    case "$tool" in
    codex)
        # Codex emits this after Esc cancellation. There is no Codex hook for
        # this path, so a previous UserPromptSubmit busy state can remain set.
        printf '%s\n' "$recent" | grep -Fq 'Conversation interrupted - tell the model what to do differently.'
        ;;
    claude)
        # Claude Code returns to its prompt/footer after Esc or /clear without
        # necessarily running Stop. Treat the visible prompt as idle only when
        # the running "esc to interrupt" status is absent.
        ! printf '%s\n' "$recent" | tail -5 | grep -Fq 'esc to interrupt' &&
            printf '%s\n' "$recent" | tail -5 | grep -Eq '^❯' &&
            printf '%s\n' "$recent" | tail -5 | grep -Fq 'bypass permissions'
        ;;
    *)
        return 1
        ;;
    esac
}

pane_is_busy() {
    local pane_id="$1"
    local tool="$2"
    local pid="$3"
    local cache_dir="$4"
    local hook_state hook_age

    hook_state=$(pane_hook_state "$pane_id" "$tool" "$pid" "$cache_dir")
    case "$hook_state" in
    busy)
        if ! pane_tui_looks_busy "$pane_id"; then
            hook_age=$(pane_hook_state_age_seconds "$pane_id" "$tool" "$pid" "$cache_dir" 2>/dev/null || true)
            # Avoid flipping a freshly submitted follow-up prompt idle while
            # Codex has not yet redrawn its "esc to interrupt" running status.
            if [[ -n "$hook_age" && "$hook_age" -ge 2 ]]; then
                pane_transcript_records_user_abort "$pane_id" "$tool" "$pid" "$cache_dir" && return 1
                pane_tui_looks_idle_after_abort "$pane_id" "$tool" && return 1
            fi
        fi
        return 0
        ;;
    idle)
        # Session-start or resume hooks can write an idle baseline before Codex
        # begins an automatic continuation. If the live TUI footer says the
        # turn is interruptible, treat that as the fresher signal.
        pane_tui_looks_busy "$pane_id" && return 0
        return 1
        ;;
    esac

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
                dots+="●"
            else
                dots+="■"
            fi
        else
            if [[ -n "${current_ttys[$normalized_tty]:-}" ]]; then
                dots+="○"
            else
                dots+="□"
            fi
        fi
    done

    [[ -n "$dots" ]] || return
    printf '%s %s\n' "$ai_icon" "$dots"
}

main "$@"
