#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
command -v chezmoi >/dev/null 2>&1 || {
    echo "SKIP: chezmoi not found" >&2
    exit 0
}

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/herdr-plugins-test.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

export HOME="$TMP_ROOT/home"
export AQUA_ROOT_DIR="$TMP_ROOT/aqua"
mkdir -p "$HOME" "$AQUA_ROOT_DIR/bin" "$TMP_ROOT/empty-bin"

RENDERED="$TMP_ROOT/herdr-plugins.sh"
chezmoi execute-template --source "$ROOT" \
    <"$ROOT/.chezmoiscripts/run_onchange_after_18_herdr-plugins.sh.tmpl" >"$RENDERED"
chmod +x "$RENDERED"

# Missing required reconciler must leave run_onchange pending.
set +e
PATH="$TMP_ROOT/empty-bin:/usr/bin:/bin" bash "$RENDERED" >/dev/null 2>&1
missing_rc=$?
set -e
[[ "$missing_rc" -ne 0 ]]

cat >"$AQUA_ROOT_DIR/bin/herdr" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ "${1:-}" == "plugin" ]]
case "${2:-}" in
    list)
        [[ "${HERDR_TEST_FAIL_LIST:-0}" != "1" ]] || exit 9
        printf '%s\n' "${HERDR_TEST_LIST:-}"
        exit 0
        ;;
    install)
        [[ "${4:-}" == "--ref" && "${5:-}" =~ ^[0-9a-f]{40}$ && "${6:-}" == "--yes" ]]
        printf '%s\n' "${3:-}" >>"${HERDR_TEST_LOG:?}"
        [[ "${HERDR_TEST_FAIL_INSTALL:-0}" != "1" ]] || exit 8
        exit 0
        ;;
    *) exit 2 ;;
esac
EOF
chmod +x "$AQUA_ROOT_DIR/bin/herdr"
export HERDR_TEST_LOG="$TMP_ROOT/install.log"
read -r first_spec first_rev < <(awk -F'"' '/^install_plugin / { print $2, $4; exit }' "$RENDERED")
[[ -n "$first_spec" && "$first_rev" =~ ^[0-9a-f]{40}$ ]]
: >"$HERDR_TEST_LOG"

set +e
HERDR_TEST_FAIL_LIST=1 bash "$RENDERED" >/dev/null 2>&1
list_rc=$?
set -e
[[ "$list_rc" -ne 0 ]]
[[ ! -s "$HERDR_TEST_LOG" ]]

set +e
HERDR_TEST_FAIL_INSTALL=1 bash "$RENDERED" >/dev/null 2>&1
install_rc=$?
set -e
[[ "$install_rc" -ne 0 ]]
[[ -s "$HERDR_TEST_LOG" ]]

: >"$HERDR_TEST_LOG"
bash "$RENDERED" >/dev/null
[[ -s "$HERDR_TEST_LOG" ]]

: >"$HERDR_TEST_LOG"
HERDR_TEST_LIST="[github:${first_spec}-extra@${first_rev}]" bash "$RENDERED" >/dev/null
grep -Fxq "$first_spec" "$HERDR_TEST_LOG"

: >"$HERDR_TEST_LOG"
HERDR_TEST_LIST="[github:${first_spec}@${first_rev}]" bash "$RENDERED" >/dev/null
! grep -Fxq "$first_spec" "$HERDR_TEST_LOG"

echo "test_herdr_plugins: OK"
