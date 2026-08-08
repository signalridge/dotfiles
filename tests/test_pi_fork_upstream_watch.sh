#!/usr/bin/env bash
set -euo pipefail

# The vendored-fork watch in script 20 is the only thing telling us a fork has drifted
# from its upstream, so its signal has to be exact: silent on the first run (it has no
# baseline yet), silent while upstream stands still, loud exactly once per new release,
# and never resetting a baseline just because the network was down.

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
command -v chezmoi >/dev/null 2>&1 || {
    echo "SKIP: chezmoi not found" >&2
    exit 0
}
command -v jq >/dev/null 2>&1 || {
    echo "SKIP: jq not found" >&2
    exit 0
}

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/pi-fork-watch-test.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

export HOME="$TMP_ROOT/home"
export XDG_STATE_HOME="$TMP_ROOT/state"
export AQUA_ROOT_DIR="$TMP_ROOT/aqua"
STUB_BIN="$TMP_ROOT/stub"
mkdir -p "$HOME" "$AQUA_ROOT_DIR/bin" "$STUB_BIN"

RENDERED="$TMP_ROOT/update-pi-extensions.sh"
chezmoi execute-template --source "$ROOT" \
    <"$ROOT/.chezmoiscripts/run_after_20_update-pi-extensions.sh.tmpl" >"$RENDERED"

cat >"$AQUA_ROOT_DIR/bin/mise" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ "${1:-}" == "env" ]] || exit 64
printf 'export PATH=%q:$PATH\n' "${FORK_TEST_STUB_BIN:?}"
EOF

cat >"$STUB_BIN/pi" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ "${1:-}" == "update" && "${2:-}" == "--extensions" ]] || exit 64
exit 0
EOF

# Serves whatever version the case under test wants, or fails outright when asked to.
cat >"$STUB_BIN/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${FORK_TEST_CURL_FAIL:-0}" == "1" ]]; then
    exit 22
fi
printf '{"version":"%s"}\n' "${FORK_TEST_VERSION:?}"
EOF
chmod +x "$AQUA_ROOT_DIR/bin/mise" "$STUB_BIN/pi" "$STUB_BIN/curl"

export FORK_TEST_STUB_BIN="$STUB_BIN"
throttle_state="$XDG_STATE_HOME/chezmoi/pi-extensions-last-success"
fork_state="$XDG_STATE_HOME/chezmoi/pi-vendored-upstream"

# Script 20 throttles itself to once per ISO week; drop the marker so each case runs.
run_script() {
    rm -f "$throttle_state"
    bash "$RENDERED" 2>"$TMP_ROOT/stderr.txt" >"$TMP_ROOT/stdout.txt"
}

recorded_version() {
    awk -F'\t' -v k="$1" '$1 == k { print $2 }' "$fork_state" 2>/dev/null || true
}

assert_no_note() {
    if grep -q "may need a rebase" "$TMP_ROOT/stderr.txt"; then
        echo "FAIL: $1 — unexpected rebase note:" >&2
        cat "$TMP_ROOT/stderr.txt" >&2
        exit 1
    fi
}

# 1. First sighting establishes a baseline without nagging about it.
FORK_TEST_VERSION=0.49.5 run_script
assert_no_note "first run"
[[ "$(recorded_version '@narumitw/pi-statusline')" == "0.49.5" ]] || {
    echo "FAIL: baseline not recorded" >&2
    exit 1
}

# 2. Upstream standing still stays quiet, however often the script runs.
FORK_TEST_VERSION=0.49.5 run_script
assert_no_note "unchanged upstream"

# 3. A new upstream release reports once, naming both versions and the fork directory.
FORK_TEST_VERSION=0.50.0 run_script
grep -q "@narumitw/pi-statusline moved 0.49.5 -> 0.50.0" "$TMP_ROOT/stderr.txt" || {
    echo "FAIL: no note for a changed upstream:" >&2
    cat "$TMP_ROOT/stderr.txt" >&2
    exit 1
}
grep -q "dot_pi/agent/extensions/pi-statusline" "$TMP_ROOT/stderr.txt" || {
    echo "FAIL: note does not name the fork directory" >&2
    exit 1
}

# 4. ...and only once: the new version becomes the baseline.
FORK_TEST_VERSION=0.50.0 run_script
assert_no_note "already-reported release"

# 5. A failed lookup must carry the baseline forward. Resetting it would re-report the
#    same release on the next successful run, training the reader to ignore the notice.
FORK_TEST_CURL_FAIL=1 FORK_TEST_VERSION=unused run_script
assert_no_note "failed lookup"
[[ "$(recorded_version '@narumitw/pi-statusline')" == "0.50.0" ]] || {
    echo "FAIL: baseline lost after a failed lookup" >&2
    exit 1
}

echo "test_pi_fork_upstream_watch: OK"
