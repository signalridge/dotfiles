#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/tmux-ai-status-test.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

mkdir -p "$TMP_ROOT/bin" "$TMP_ROOT/tmp"

cat >"$TMP_ROOT/bin/tmux" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail

if [[ "$1" == "show-option" && "$2" == "-gqv" ]]; then
    case "$3" in
        @tmux2k-ai-icon) printf '%s\n' "AI" ;;
        @tmux2k-ai-activity-threshold) printf '%s\n' "30" ;;
        *) exit 1 ;;
    esac
    exit 0
fi

if [[ "$1" == "has-session" ]]; then
    exit 0
fi

if [[ "$1" == "display-message" && "$2" == "-p" ]]; then
    if [[ "$3" == '#{pid}' ]]; then
        printf '%s\n' "4242"
        exit 0
    fi
    if [[ "$3" == "-t" ]]; then
        case "$4" in
            %1) printf '/dev/ttys001\n' ;;
            %2) printf '/dev/ttys002\n' ;;
            %3) printf '/dev/ttys003\n' ;;
            *) ;;
        esac
        exit 0
    fi
    exit 0
fi

if [[ "$1" == "list-panes" && "$2" == "-a" ]]; then
    printf '%%1\t/dev/ttys001\n'
    printf '%%2\t/dev/ttys002\n'
    printf '%%3\t/dev/ttys003\n'
    exit 0
fi

if [[ "$1" == "list-panes" && "$2" == "-t" ]]; then
    case "$3" in
        s:1) printf '/dev/ttys001\n' ;;
        s:2) printf '/dev/ttys002\n' ;;
        s:3) printf '/dev/ttys003\n' ;;
        *) ;;
    esac
    exit 0
fi

if [[ "$1" == "capture-pane" ]]; then
    pane_id=""
    while (($# > 0)); do
        case "$1" in
            -t)
                pane_id="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    case " ${TMUX_AI_BUSY_PANES:-} " in
        *" $pane_id "*)
            printf '%s\n' "Working (2s - esc to interrupt)"
            ;;
        *)
            case " ${TMUX_AI_WAITING_PANES:-} " in
                *" $pane_id "*)
                    printf '%s\n' "Waiting for background terminal (4m 12s - esc to interrupt)"
                    ;;
            esac
            case " ${TMUX_AI_STALE_BUSY_PANES:-} " in
                *" $pane_id "*)
                    printf '%s\n' "Working (12s - esc to interrupt)"
                    printf '%s\n' "old output 1"
                    printf '%s\n' "old output 2"
                    printf '%s\n' "old output 3"
                    printf '%s\n' "old output 4"
                    printf '%s\n' "old output 5"
                    printf '%s\n' "old output 6"
                    printf '%s\n' "old output 7"
                    printf '%s\n' "old output 8"
                    ;;
            esac
            printf '%s\n' "idle prompt"
            ;;
    esac
    exit 0
fi

exit 1
STUB

cat >"$TMP_ROOT/bin/ps" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail

if [[ "$*" == "-eo pid=,ppid=,stat=,tty=,comm=" ]]; then
    printf '111 1 S+ ttys001 claude\n'
    printf '222 1 S+ ttys002 codex\n'
    printf '333 1 S+ ttys003 opencode\n'
    printf '444 1 S  ttys001 claude\n'
    printf '555 1 S+ ttys009 codex\n'
    exit 0
fi

exit 1
STUB

cat >"$TMP_ROOT/bin/date" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail

if [[ "$1" == "+%s" ]]; then
    printf '%s\n' "${TMUX_AI_NOW:-110}"
    exit 0
fi

exit 1
STUB

chmod +x "$TMP_ROOT/bin/tmux" "$TMP_ROOT/bin/ps" "$TMP_ROOT/bin/date"

run_status() {
    PATH="$TMP_ROOT/bin:$PATH" \
        TMPDIR="$TMP_ROOT/tmp" \
        TMUX_AI_BUSY_PANES="${TMUX_AI_BUSY_PANES:-}" \
        TMUX_AI_WAITING_PANES="${TMUX_AI_WAITING_PANES:-}" \
        TMUX_AI_STALE_BUSY_PANES="${TMUX_AI_STALE_BUSY_PANES:-}" \
        bash "$ROOT/private_dot_config/tmux/executable_tmux2k-ai.sh" "$@"
}

assert_equals() {
    local actual="$1"
    local expected="$2"
    if [[ "$actual" != "$expected" ]]; then
        echo "assertion failed: expected '$expected', got '$actual'" >&2
        exit 1
    fi
}

assert_file_contains() {
    local file="$1"
    local expected="$2"
    if ! grep -Fq "$expected" "$file"; then
        echo "assertion failed: expected '$file' to contain '$expected'" >&2
        cat "$file" >&2
        exit 1
    fi
}

# No hook state means "session present, busy unknown", so all dots are idle.
assert_equals "$(run_status s:2)" "AI ○◇○"

# Existing sessions that have not loaded hooks yet can still show busy when
# their own TUI status says the turn is interruptible.
TMUX_AI_BUSY_PANES="%1 %3"
assert_equals "$(run_status s:2)" "AI ●◇●"
unset TMUX_AI_BUSY_PANES

TMUX_AI_WAITING_PANES="%2"
assert_equals "$(run_status s:2)" "AI ○◆○"
unset TMUX_AI_WAITING_PANES

TMUX_AI_STALE_BUSY_PANES="%2"
assert_equals "$(run_status s:2)" "AI ○◇○"
unset TMUX_AI_STALE_BUSY_PANES

state_dir="$TMP_ROOT/tmp/tmux2k-ai-4242"
mkdir -p "$state_dir"
cat >"$state_dir/_1.state" <<'EOF'
tool=claude
state=busy
pid=111
updated_at=110
EOF
cat >"$state_dir/_2.state" <<'EOF'
tool=codex
state=busy
pid=999
updated_at=110
EOF
cat >"$state_dir/_3.state" <<'EOF'
tool=opencode
state=busy
pid=333
updated_at=110
EOF

assert_equals "$(run_status)" "AI ●○●"
assert_equals "$(run_status s:1)" "AI ◆○●"
assert_equals "$(run_status s:2)" "AI ●◇●"
assert_equals "$(run_status s:3)" "AI ●○◆"
assert_equals "$(run_status s:9)" "AI ●○●"

TMUX_AI_BUSY_PANES="%2"
assert_equals "$(run_status s:2)" "AI ●◆●"
unset TMUX_AI_BUSY_PANES

TMUX_PANE=%2 \
    PATH="$TMP_ROOT/bin:$PATH" \
    TMPDIR="$TMP_ROOT/tmp" \
    bash "$ROOT/dot_local/bin/executable_tmux-ai-agent-state" codex busy
assert_file_contains "$state_dir/_2.state" "tool=codex"
assert_file_contains "$state_dir/_2.state" "state=busy"
assert_file_contains "$state_dir/_2.state" "pid=222"
assert_equals "$(run_status s:2)" "AI ●◆●"

TMUX_PANE=%2 \
    PATH="$TMP_ROOT/bin:$PATH" \
    TMPDIR="$TMP_ROOT/tmp" \
    bash "$ROOT/dot_local/bin/executable_tmux-ai-agent-state" codex idle
assert_file_contains "$state_dir/_2.state" "state=idle"
assert_equals "$(run_status s:2)" "AI ●◇●"

TMUX_AI_BUSY_PANES="%2"
assert_equals "$(run_status s:2)" "AI ●◇●"
unset TMUX_AI_BUSY_PANES

echo "test_tmux_ai_status: OK"
