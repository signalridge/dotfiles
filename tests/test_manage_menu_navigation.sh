#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

require_cmd() {
    command -v "$1" >/dev/null 2>&1
}

for c in bash chezmoi jq; do
    require_cmd "$c" || {
        echo "SKIP: missing dependency: $c" >&2
        exit 0
    }
done

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/manage-menu-test.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

export HOME="$TMP_ROOT/home"
mkdir -p "$HOME/.config/chezmoi"

BIN="$TMP_ROOT/bin"
STUB="$TMP_ROOT/stub"
mkdir -p "$BIN/lib/ai" "$BIN/lib" "$STUB"

# Render scripts/libs for isolated execution.
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/lib/common" >"$BIN/lib/common"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/lib/ai/core.tmpl" >"$BIN/lib/ai/core"
cp "$ROOT/dot_local/bin/lib/ai/codex" "$BIN/lib/ai/codex"
cp "$ROOT/dot_local/bin/lib/ai/claude" "$BIN/lib/ai/claude"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/executable_codex-manage" >"$BIN/codex-manage"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/executable_claude-manage" >"$BIN/claude-manage"
chmod +x "$BIN/lib/common" "$BIN/lib/ai/core" "$BIN/lib/ai/codex" "$BIN/lib/ai/claude" "$BIN/codex-manage" "$BIN/claude-manage"

# Stubs: keep deterministic, no network/key dependencies.
cat >"$STUB/chezmoi" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "data" ]]; then
    cat <<'JSON'
{"claudeProviderAccount":"anthropic","codexProviderAccount":"openai"}
JSON
    exit 0
fi
if [[ "${1:-}" == "apply" ]]; then
    exit 0
fi
exit 0
EOF

cat >"$STUB/gopass" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
    list) exit 0 ;;
    show) exit 1 ;;
    *)    exit 0 ;;
esac
EOF

cat >"$STUB/fzf" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

: "${FZF_STATE_FILE:?}"
: "${FZF_CHOICES_FILE:?}"

# Consume upstream list to avoid breaking pipelines.
cat >/dev/null || true

calls=0
if [[ -f "$FZF_STATE_FILE" ]]; then
    calls="$(cat "$FZF_STATE_FILE")"
fi
calls=$((calls + 1))
printf '%s\n' "$calls" >"$FZF_STATE_FILE"

choice="$(sed -n "${calls}p" "$FZF_CHOICES_FILE")"
if [[ -z "$choice" ]]; then
    exit 130
fi
printf '%s\n' "$choice"
EOF

chmod +x "$STUB/chezmoi" "$STUB/gopass" "$STUB/fzf"

BASE_PATH="$STUB:$BIN:$PATH"

run_case() {
    local script="$1"
    local label="$2"
    local expected_calls="$3"
    shift 3

    local choices_file state_file
    choices_file="$TMP_ROOT/${script}-${label}.choices"
    state_file="$TMP_ROOT/${script}-${label}.state"
    : >"$choices_file"
    : >"$state_file"

    local choice
    for choice in "$@"; do
        printf '%s\n' "$choice" >>"$choices_file"
    done

    set +e
    PATH="$BASE_PATH" \
        FZF_STATE_FILE="$state_file" \
        FZF_CHOICES_FILE="$choices_file" \
        "$BIN/$script" >/dev/null 2>&1
    local rc=$?
    set -e

    if [[ "$rc" -ne 0 ]]; then
        echo "expected $script ($label) rc=0, got rc=$rc" >&2
        exit 1
    fi

    local actual_calls
    actual_calls="$(cat "$state_file")"
    if [[ "$actual_calls" != "$expected_calls" ]]; then
        echo "unexpected fzf calls for $script ($label): expected $expected_calls, got $actual_calls" >&2
        exit 1
    fi
}

# Case 1: command success (list) should exit immediately (single menu invocation).
run_case codex-manage list-exit 1 \
    "list           Show all accounts" \
    "quit           Exit to shell"
run_case claude-manage list-exit 1 \
    "list           Show all accounts" \
    "quit           Exit to shell"

# Case 2: Back from child picker should return to top menu (menu -> picker -> menu).
run_case codex-manage back-to-menu 3 \
    "switch         Change default account" \
    "Back" \
    "quit           Exit to shell"
run_case claude-manage back-to-menu 3 \
    "switch         Change default account" \
    "Back" \
    "quit           Exit to shell"

echo "test_manage_menu_navigation: OK"
