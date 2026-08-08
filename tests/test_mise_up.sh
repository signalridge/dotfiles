#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.chezmoiscripts/run_after_23_mise-up.sh"

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/mise-up-test.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

export HOME="$TMP_ROOT/home"
export XDG_STATE_HOME="$TMP_ROOT/state"
export AQUA_ROOT_DIR="$TMP_ROOT/aqua"
TOOL_BIN="$TMP_ROOT/tool-bin"
mkdir -p "$HOME" "$AQUA_ROOT_DIR/bin" "$TOOL_BIN"

# `mise env -s bash` injects a tool bin dir carrying npm, so the node bootstrap
# branch stays out of the way regardless of the host's real PATH.
cat >"$TOOL_BIN/npm" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

cat >"$AQUA_ROOT_DIR/bin/mise" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${MISE_TEST_ARGV_LOG:?}"
if [[ "${1:-}" == "env" ]]; then
    printf 'export PATH=%q:$PATH\n' "${MISE_TEST_TOOL_BIN:?}"
    exit 0
fi
if [[ "${1:-}" == "up" ]]; then
    printf 'up\n' >>"${MISE_TEST_UP_LOG:?}"
    # Explicit exit: a bare [[ ]] here would be swallowed by the `exit 0` below.
    if [[ "${MISE_TEST_FAIL:-0}" == "1" ]]; then
        exit 1
    fi
fi
exit 0
EOF
chmod +x "$AQUA_ROOT_DIR/bin/mise" "$TOOL_BIN/npm"

export MISE_TEST_TOOL_BIN="$TOOL_BIN"
export MISE_TEST_ARGV_LOG="$TMP_ROOT/argv.log"
export MISE_TEST_UP_LOG="$TMP_ROOT/up.log"
: >"$MISE_TEST_ARGV_LOG"
: >"$MISE_TEST_UP_LOG"
state_file="$XDG_STATE_HOME/chezmoi/mise-up-last-success"

up_count() {
    wc -l <"$MISE_TEST_UP_LOG" | tr -d ' '
}

# A failed upgrade stays non-fatal but must not consume the 7-day interval.
MISE_TEST_FAIL=1 bash "$SCRIPT" >/dev/null 2>&1
[[ ! -e "$state_file" ]] || {
    echo "failed upgrade must not record success" >&2
    exit 1
}
[[ "$(up_count)" == "1" ]]

# A successful upgrade records the timestamp.
bash "$SCRIPT" >/dev/null
[[ -s "$state_file" ]]
[[ "$(up_count)" == "2" ]]

# ...and is then throttled until the interval elapses.
bash "$SCRIPT" >/dev/null
[[ "$(up_count)" == "2" ]]

# A timestamp older than the interval retriggers the upgrade.
printf '%s\n' "$(($(date +%s) - 8 * 86400))" >"$state_file"
bash "$SCRIPT" >/dev/null
[[ "$(up_count)" == "3" ]]

# A malformed timestamp must not wedge the script into permanent skipping.
printf 'garbage\n' >"$state_file"
bash "$SCRIPT" >/dev/null
[[ "$(up_count)" == "4" ]]

# --bump would rewrite ~/.config/mise/config.toml, which chezmoi owns; the two
# would then fight on every apply. Guard the invariant, not just today's code.
if grep -q -- '--bump' "$MISE_TEST_ARGV_LOG"; then
    echo "mise must never be invoked with --bump (chezmoi owns mise config.toml)" >&2
    exit 1
fi

echo "test_mise_up: OK"
