#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "SKIP: missing dependency: $1" >&2
        exit 0
    }
}

for c in bash chezmoi; do
    require_cmd "$c"
done

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/codex-connector-plugins.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

export HOME="$TMP_ROOT/home"
mkdir -p "$HOME/.nix-profile/bin"

SCRIPT="$TMP_ROOT/sync-codex-connector-plugins.sh"
chezmoi execute-template --source "$ROOT" <"$ROOT/.chezmoiscripts/run_after_13_sync-codex-connector-plugins.sh" >"$SCRIPT"
chmod +x "$SCRIPT"

cat >"$HOME/.nix-profile/bin/codex" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case "$*" in
"plugin list")
    [[ "${CODEX_FAKE_LIST_FAIL:-0}" != "1" ]] || exit 9
    if [[ -n "${CODEX_FAKE_LIST_FILE:-}" ]]; then
        cat "$CODEX_FAKE_LIST_FILE"
    fi
    ;;
"plugin add "*)
    printf '%s\n' "$*" >>"${CODEX_FAKE_CALLS_FILE:?}"
    ;;
*)
    echo "unexpected codex args: $*" >&2
    exit 64
    ;;
esac
EOF
chmod +x "$HOME/.nix-profile/bin/codex"

LIST_FILE="$TMP_ROOT/plugin-list.txt"
CALLS_FILE="$TMP_ROOT/calls.txt"
export CODEX_FAKE_LIST_FILE="$LIST_FILE"
export CODEX_FAKE_CALLS_FILE="$CALLS_FILE"

assert_contains() {
    local haystack="$1"
    local needle="$2"

    if [[ "$haystack" != *"$needle"* ]]; then
        echo "expected output to contain: $needle" >&2
        echo "--- output ---" >&2
        printf '%s\n' "$haystack" >&2
        exit 1
    fi
}

set +e
list_failure_output="$(CODEX_FAKE_LIST_FAIL=1 "$SCRIPT" 2>&1)"
list_failure_rc=$?
set -e
[[ "$list_failure_rc" -ne 0 ]]
assert_contains "$list_failure_output" "failed to list Codex plugins"

cat >"$LIST_FILE" <<'EOF'
PLUGIN                           STATUS         VERSION  PATH
github@openai-api-curated        not installed           /tmp/github
EOF
: >"$CALLS_FILE"
output="$("$SCRIPT")"
assert_contains "$output" "Skipped: slack@openai-curated (not available in current Codex marketplace)"
if [[ -s "$CALLS_FILE" ]]; then
    echo "expected unavailable plugin to skip install" >&2
    cat "$CALLS_FILE" >&2
    exit 1
fi

cat >"$LIST_FILE" <<'EOF'
PLUGIN                   STATUS         VERSION  PATH
slack@openai-curated     not installed           /tmp/slack
EOF
: >"$CALLS_FILE"
output="$("$SCRIPT")"
assert_contains "$output" "Plugin installed: slack@openai-curated"
if ! grep -Fxq "plugin add slack@openai-curated" "$CALLS_FILE"; then
    echo "expected missing plugin to be installed" >&2
    cat "$CALLS_FILE" >&2
    exit 1
fi

cat >"$LIST_FILE" <<'EOF'
PLUGIN                   STATUS     VERSION  PATH
slack@openai-curated     installed  0.1.2    /tmp/slack
EOF
: >"$CALLS_FILE"
output="$("$SCRIPT")"
assert_contains "$output" "Plugin exists: slack@openai-curated"
if [[ -s "$CALLS_FILE" ]]; then
    echo "expected installed plugin to skip install" >&2
    cat "$CALLS_FILE" >&2
    exit 1
fi

echo "test_codex_connector_plugins: OK"
