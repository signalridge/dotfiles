#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
command -v chezmoi >/dev/null 2>&1 || {
    echo "SKIP: chezmoi not found" >&2
    exit 0
}

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/pi-extension-update-test.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

export HOME="$TMP_ROOT/home"
export XDG_STATE_HOME="$TMP_ROOT/state"
export AQUA_ROOT_DIR="$TMP_ROOT/aqua"
PI_BIN="$TMP_ROOT/pi-bin"
mkdir -p "$HOME" "$AQUA_ROOT_DIR/bin" "$PI_BIN"

RENDERED="$TMP_ROOT/update-pi-extensions.sh"
chezmoi execute-template --source "$ROOT" \
    <"$ROOT/.chezmoiscripts/run_after_20_update-pi-extensions.sh.tmpl" >"$RENDERED"
chmod +x "$RENDERED"

cat >"$AQUA_ROOT_DIR/bin/mise" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ "${1:-}" == "env" && "${2:-}" == "-s" && "${3:-}" == "bash" ]]
printf 'export PATH=%q:$PATH\n' "${PI_TEST_BIN:?}"
EOF

cat >"$PI_BIN/pi" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ "${1:-}" == "update" && "${2:-}" == "--extensions" ]] || exit 64
printf 'update\n' >>"${PI_TEST_LOG:?}"
[[ "${PI_TEST_FAIL:-0}" != "1" ]]
EOF
chmod +x "$AQUA_ROOT_DIR/bin/mise" "$PI_BIN/pi"

export PI_TEST_BIN="$PI_BIN"
export PI_TEST_LOG="$TMP_ROOT/pi.log"
: >"$PI_TEST_LOG"
state_file="$XDG_STATE_HOME/chezmoi/pi-extensions-last-success"

# Failure remains non-fatal, but must not consume the weekly/package trigger.
PI_TEST_FAIL=1 bash "$RENDERED" >/dev/null 2>&1
[[ ! -e "$state_file" ]]
[[ "$(wc -l <"$PI_TEST_LOG" | tr -d ' ')" == "1" ]]

bash "$RENDERED" >/dev/null
[[ -s "$state_file" ]]
[[ "$(wc -l <"$PI_TEST_LOG" | tr -d ' ')" == "2" ]]

# A successful reconciliation is throttled until the key changes.
bash "$RENDERED" >/dev/null
[[ "$(wc -l <"$PI_TEST_LOG" | tr -d ' ')" == "2" ]]

# Exercise the macOS shasum fallback by hiding sha256sum from PATH.
portable_bin="$TMP_ROOT/portable-bin"
mkdir -p "$portable_bin"
for command in awk bash cat env mkdir mktemp mv rm; do
    ln -s "$(command -v "$command")" "$portable_bin/$command"
done
cat >"$portable_bin/shasum" <<'EOF'
#!/bin/bash
set -euo pipefail
[[ "${1:-}" == "-a" && "${2:-}" == "256" ]]
cat >/dev/null
printf 'portable-test-hash  -\n'
EOF
chmod +x "$portable_bin/shasum"

original_path="$PATH"
export PATH="$portable_bin"
rm -f "$state_file" "$PI_TEST_LOG"
"$BASH" "$RENDERED" >/dev/null
export PATH="$original_path"
[[ "$(cat "$state_file")" == "portable-test-hash" ]]
[[ "$(wc -l <"$PI_TEST_LOG" | tr -d ' ')" == "1" ]]

echo "test_pi_extension_update: OK"
