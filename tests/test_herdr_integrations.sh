#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
for cmd in chezmoi jq; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "SKIP: $cmd not found" >&2
        exit 0
    }
done

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/herdr-integrations-test.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

export HOME="$TMP_ROOT/home"
mkdir -p "$HOME/.codex" "$TMP_ROOT/bin"
RENDERED="$TMP_ROOT/herdr-integrations.sh"
chezmoi execute-template --source "$ROOT" \
    <"$ROOT/.chezmoiscripts/run_after_14_sync-herdr-integrations.sh.tmpl" >"$RENDERED"
chmod +x "$RENDERED"

cat >"$TMP_ROOT/bin/herdr" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ "${1:-}" == "integration" ]]
case "${2:-}" in
    install)
        [[ "${HERDR_TEST_FAIL_INSTALL:-}" != "${3:-}" ]]
        ;;
    uninstall)
        exit 0
        ;;
    *) exit 2 ;;
esac
EOF
chmod +x "$TMP_ROOT/bin/herdr"
jq_dir="$(dirname "$(command -v jq)")"
PATH="$TMP_ROOT/bin:$jq_dir:/usr/bin:/bin"
export PATH

hooks_file="$HOME/.codex/hooks.json"
herdr_command="bash '$HOME/.codex/herdr-agent-state.sh' session"

# Installation failure must not touch an existing hooks file.
printf '%s\n' '{"hooks":{"SessionStart":[]}}' >"$hooks_file"
cp "$hooks_file" "$TMP_ROOT/hooks.before-install-failure"
set +e
HERDR_TEST_FAIL_INSTALL=codex bash "$RENDERED" >/dev/null 2>&1
install_rc=$?
set -e
[[ "$install_rc" -ne 0 ]]
[[ -f "$hooks_file" ]]
cmp -s "$TMP_ROOT/hooks.before-install-failure" "$hooks_file"

# Mixed user/Herdr hooks are preserved rather than silently discarded.
jq -n --arg herdr "$herdr_command" '{hooks:{SessionStart:[{hooks:[{command:$herdr},{command:"echo keep"}]}]}}' >"$hooks_file"
set +e
bash "$RENDERED" >"$TMP_ROOT/mixed.out" 2>&1
mixed_rc=$?
set -e
[[ "$mixed_rc" -ne 0 ]]
[[ -f "$hooks_file" ]]
grep -Fq "preserving $hooks_file" "$TMP_ROOT/mixed.out"
grep -Fq 'echo keep' "$hooks_file"

# A command that merely contains the Herdr path is not owned by Herdr.
jq -n --arg command "$herdr_command; echo keep" \
    '{hooks:{SessionStart:[{hooks:[{command:$command,type:"command",timeout:10}]}]}}' >"$hooks_file"
set +e
bash "$RENDERED" >/dev/null 2>&1
compound_rc=$?
set -e
[[ "$compound_rc" -ne 0 ]]
[[ -f "$hooks_file" ]]

# A legacy file containing only the exact Herdr hook is safe to remove; the
# managed inline Codex config remains the source of truth.
jq -n --arg herdr "$herdr_command" \
    '{hooks:{SessionStart:[{hooks:[{command:$herdr,type:"command",timeout:10}]}]}}' >"$hooks_file"
bash "$RENDERED" >/dev/null
[[ ! -e "$hooks_file" ]]

echo "test_herdr_integrations: OK"
