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

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/ai-gopass-migrate-test.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

export HOME="$TMP_ROOT/home"
mkdir -p "$HOME/.config/chezmoi" "$HOME/.codex"

BIN="$TMP_ROOT/bin"
STUB="$TMP_ROOT/stub"
STORE="$TMP_ROOT/gopass-store"
mkdir -p "$BIN/lib/ai" "$BIN/lib" "$STUB" "$STORE"

# Render scripts/libs for isolated execution.
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/lib/common.tmpl" >"$BIN/lib/common"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/lib/ai/core.tmpl" >"$BIN/lib/ai/core"
cp "$ROOT/dot_local/bin/lib/ai/codex.tmpl" "$BIN/lib/ai/codex"
cp "$ROOT/dot_local/bin/lib/ai/claude.tmpl" "$BIN/lib/ai/claude"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/executable_codex-manage.tmpl" >"$BIN/codex-manage"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/executable_claude-manage.tmpl" >"$BIN/claude-manage"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/executable_ai-gopass-migrate.tmpl" >"$BIN/ai-gopass-migrate"
chmod +x "$BIN/lib/common" "$BIN/lib/ai/core" "$BIN/lib/ai/codex" "$BIN/lib/ai/claude" \
    "$BIN/codex-manage" "$BIN/claude-manage" "$BIN/ai-gopass-migrate"

cat >"$HOME/.codex/config.toml" <<'EOF'
model_provider = "openai"
model = "gpt-5.2-codex"

[model_providers.openai]
name = "OpenAI"

[model_providers.deepseek]
name = "DeepSeek"
base_url = "https://api.deepseek.com"
wire_api = "responses"

[model_providers.kimi]
name = "Kimi"
base_url = "https://api.kimi.com/coding"
wire_api = "responses"

[model_providers.qwen]
name = "Qwen"
base_url = "https://dashscope.aliyuncs.com/apps/anthropic"
wire_api = "responses"
EOF

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

store="${GOPASS_STORE:?}"
cmd="${1:-}"
shift || true

case "$cmd" in
    list)
        target="${1:-}"
        if [[ "$target" == "-f" ]]; then
            target="${2:-}"
        fi
        path="${store}/${target}"
        if [[ -f "$path" ]]; then
            echo "$target"
            exit 0
        fi
        if [[ -d "$path" ]]; then
            find "$path" -type f | sed "s|^${store}/||" | sort
            exit 0
        fi
        exit 1
        ;;
    show)
        target="${1:-}"
        if [[ "$target" == "-o" ]]; then
            target="${2:-}"
        fi
        path="${store}/${target}"
        [[ -f "$path" ]] || exit 1
        cat "$path"
        ;;
    insert)
        if [[ "${1:-}" == "-f" ]]; then
            target="${2:-}"
            path="${store}/${target}"
            mkdir -p "$(dirname "$path")"
            cat >"$path"
            exit 0
        fi
        exit 1
        ;;
    rm)
        if [[ "${1:-}" == "-f" ]]; then
            target="${2:-}"
            rm -f "${store}/${target}" || true
            exit 0
        fi
        exit 1
        ;;
    *)
        exit 0
        ;;
esac
EOF

chmod +x "$STUB/chezmoi" "$STUB/gopass"

BASE_PATH="$STUB:$BIN:$PATH"
export GOPASS_STORE="$STORE"

put_key() {
    local path="$1"
    local value="$2"
    PATH="$BASE_PATH" bash -c "printf '%s' '$value' | gopass insert -f '$path'"
}

strip_ansi() {
    sed -E $'s/\x1B\\[[0-9;]*[mK]//g'
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    if ! grep -Fq "$needle" <<<"$haystack"; then
        echo "expected output to contain: $needle" >&2
        echo "$haystack" >&2
        exit 1
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    if grep -Fq "$needle" <<<"$haystack"; then
        echo "expected output NOT to contain: $needle" >&2
        echo "$haystack" >&2
        exit 1
    fi
}

# Seed legacy paths.
put_key "ai-tools/providers/deepseek/accounts/YWxwaGE/api_key" "shared-deepseek"
put_key "ai-tools/codex/providers/kimi/accounts/bGVnYWN5/api_key" "legacy-codex-kimi"
put_key "ai-tools/claude/providers/qwen/accounts/YmV0YQ/api_key" "legacy-claude-qwen"

# Dry-run should not create new paths.
PATH="$BASE_PATH" "$BIN/ai-gopass-migrate" >/dev/null
if PATH="$BASE_PATH" gopass show -o "codex/providers/deepseek/accounts/YWxwaGE/api_key" >/dev/null 2>&1; then
    echo "dry-run unexpectedly created migrated key" >&2
    exit 1
fi

# Apply migration.
PATH="$BASE_PATH" "$BIN/ai-gopass-migrate" --apply >/dev/null

# Shared key copied to both tools.
[[ "$(PATH="$BASE_PATH" gopass show -o "codex/providers/deepseek/accounts/YWxwaGE/api_key")" == "shared-deepseek" ]]
[[ "$(PATH="$BASE_PATH" gopass show -o "claude/providers/deepseek/accounts/YWxwaGE/api_key")" == "shared-deepseek" ]]

# Tool-specific legacy keys migrated to matching tool.
[[ "$(PATH="$BASE_PATH" gopass show -o "codex/providers/kimi/accounts/bGVnYWN5/api_key")" == "legacy-codex-kimi" ]]
[[ "$(PATH="$BASE_PATH" gopass show -o "claude/providers/qwen/accounts/YmV0YQ/api_key")" == "legacy-claude-qwen" ]]

# Old keys remain before cleanup.
PATH="$BASE_PATH" gopass show -o "ai-tools/providers/deepseek/accounts/YWxwaGE/api_key" >/dev/null
PATH="$BASE_PATH" gopass show -o "ai-tools/codex/providers/kimi/accounts/bGVnYWN5/api_key" >/dev/null
PATH="$BASE_PATH" gopass show -o "ai-tools/claude/providers/qwen/accounts/YmV0YQ/api_key" >/dev/null

# list now reflects only valid tool-specific paths.
codex_list="$(PATH="$BASE_PATH" "$BIN/codex-manage" list | strip_ansi)"
claude_list="$(PATH="$BASE_PATH" "$BIN/claude-manage" list | strip_ansi)"

assert_contains "$codex_list" "deepseek@alpha"
assert_contains "$codex_list" "kimi@legacy"
assert_not_contains "$codex_list" "qwen@beta"
assert_not_contains "$codex_list" "(no key)"

assert_contains "$claude_list" "deepseek@alpha"
assert_contains "$claude_list" "qwen@beta"
assert_not_contains "$claude_list" "kimi@legacy"
assert_not_contains "$claude_list" "(no key)"

# Cleanup removes legacy keys only.
PATH="$BASE_PATH" "$BIN/ai-gopass-migrate" --apply --cleanup >/dev/null

if PATH="$BASE_PATH" gopass show -o "ai-tools/providers/deepseek/accounts/YWxwaGE/api_key" >/dev/null 2>&1; then
    echo "expected shared legacy key to be removed by cleanup" >&2
    exit 1
fi
if PATH="$BASE_PATH" gopass show -o "ai-tools/codex/providers/kimi/accounts/bGVnYWN5/api_key" >/dev/null 2>&1; then
    echo "expected codex legacy key to be removed by cleanup" >&2
    exit 1
fi
if PATH="$BASE_PATH" gopass show -o "ai-tools/claude/providers/qwen/accounts/YmV0YQ/api_key" >/dev/null 2>&1; then
    echo "expected claude legacy key to be removed by cleanup" >&2
    exit 1
fi

PATH="$BASE_PATH" gopass show -o "codex/providers/deepseek/accounts/YWxwaGE/api_key" >/dev/null
PATH="$BASE_PATH" gopass show -o "claude/providers/deepseek/accounts/YWxwaGE/api_key" >/dev/null
PATH="$BASE_PATH" gopass show -o "codex/providers/kimi/accounts/bGVnYWN5/api_key" >/dev/null
PATH="$BASE_PATH" gopass show -o "claude/providers/qwen/accounts/YmV0YQ/api_key" >/dev/null

echo "test_ai_gopass_migrate: OK"
