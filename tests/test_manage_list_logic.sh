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

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/manage-list-test.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

export HOME="$TMP_ROOT/home"
mkdir -p "$HOME/.config/chezmoi" "$HOME/.codex"
cat >"$HOME/.config/chezmoi/chezmoi.toml" <<'EOF'
[data]
claudeProviderAccount = "anthropic"
codexProviderAccount = "openai"
EOF

BIN="$TMP_ROOT/bin"
STUB="$TMP_ROOT/stub"
mkdir -p "$BIN/lib/ai" "$BIN/lib" "$STUB"

# Render scripts/libs for isolated execution.
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/lib/common.tmpl" >"$BIN/lib/common"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/lib/ai/core.tmpl" >"$BIN/lib/ai/core"
cp "$ROOT/dot_local/bin/lib/ai/codex.tmpl" "$BIN/lib/ai/codex"
cp "$ROOT/dot_local/bin/lib/ai/claude.tmpl" "$BIN/lib/ai/claude"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/executable_codex-manage.tmpl" >"$BIN/codex-manage"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/executable_claude-manage.tmpl" >"$BIN/claude-manage"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/executable_codex-with.tmpl" >"$BIN/codex-with"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/executable_claude-with.tmpl" >"$BIN/claude-with"
chmod +x "$BIN/lib/common" "$BIN/lib/ai/core" "$BIN/lib/ai/codex" "$BIN/lib/ai/claude" \
    "$BIN/codex-manage" "$BIN/claude-manage" "$BIN/codex-with" "$BIN/claude-with"

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

# Stubs
cat >"$STUB/chezmoi" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "data" ]]; then
    cat <<'JSON'
{"claudeProviderAccount":"anthropic","codexProviderAccount":"glm@ghost"}
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

cmd="${1:-}"
shift || true

case "$cmd" in
    list)
        target="${1:-}"
        if [[ "$target" == "-f" ]]; then
            target="${2:-}"
        fi
        case "$target" in
            codex/providers/deepseek/accounts)
                echo "codex/providers/deepseek/accounts/YWxwaGE/api_key"
                exit 0
                ;;
            codex/providers/kimi/accounts)
                echo "codex/providers/kimi/accounts/bGVnYWN5/api_key"
                exit 0
                ;;
            claude/providers/qwen/accounts)
                echo "claude/providers/qwen/accounts/YmV0YQ/api_key"
                exit 0
                ;;
            claude/providers/kimi/accounts)
                echo "claude/providers/kimi/accounts/bGVnYWN5/api_key"
                exit 0
                ;;
            codex/providers/deepseek/accounts/YWxwaGE/api_key|\
            codex/providers/kimi/accounts/bGVnYWN5/api_key|\
            claude/providers/qwen/accounts/YmV0YQ/api_key|\
            claude/providers/kimi/accounts/bGVnYWN5/api_key)
                exit 0
                ;;
            *)
                exit 1
                ;;
        esac
        ;;
    show)
        target="${1:-}"
        if [[ "$target" == "-o" ]]; then
            target="${2:-}"
        fi
        case "$target" in
            codex/providers/deepseek/accounts/YWxwaGE/api_key|\
            codex/providers/kimi/accounts/bGVnYWN5/api_key|\
            claude/providers/qwen/accounts/YmV0YQ/api_key|\
            claude/providers/kimi/accounts/bGVnYWN5/api_key)
                echo "test-key"
                exit 0
                ;;
            *)
                exit 1
                ;;
        esac
        ;;
    insert)
        if [[ "${1:-}" == "-f" ]]; then
            printf '%s\n' "${2:-}" >>"${GOPASS_INSERT_LOG:?}"
            exit 0
        fi
        exit 1
        ;;
    rm)
        exit 0
        ;;
    *)
        exit 0
        ;;
esac
EOF

cat >"$STUB/codex-token" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
    --check) exit 0 ;;
    --config)
        echo '{"provider":"deepseek","model":"deepseek-chat","base_url":"https://api.deepseek.com"}'
        exit 0
        ;;
    *)
        echo "test-key"
        exit 0
        ;;
esac
EOF

cat >"$STUB/claude-token" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
    --check) exit 0 ;;
    --config)
        echo '{"provider":"qwen","model":"qwen3-coder-plus","base_url":"https://dashscope.aliyuncs.com/apps/anthropic"}'
        exit 0
        ;;
    *)
        echo "test-key"
        exit 0
        ;;
esac
EOF

cat >"$STUB/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
args="$*"
if [[ "$args" == *"/v1/models"* ]]; then
    cat <<'OUT'
{"object":"list","data":[]}
200
OUT
    exit 0
fi
if [[ "$args" == *"/v1/messages"* ]]; then
    cat <<'OUT'
{"id":"msg_123","type":"message"}
200
OUT
    exit 0
fi
if [[ "$args" == *"/v1/responses"* ]]; then
    cat <<'OUT'
{"error":{"message":"Upstream request failed","type":"upstream_error"}}
502
OUT
    exit 0
fi
cat <<'OUT'
{"ok":true}
200
OUT
EOF

cat >"$STUB/codex" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exit 0
EOF

cat >"$STUB/claude" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exit 0
EOF

chmod +x "$STUB/chezmoi" "$STUB/gopass" "$STUB/codex-token" "$STUB/claude-token" \
    "$STUB/curl" "$STUB/codex" "$STUB/claude"

BASE_PATH="$STUB:$BIN:$PATH"
INSERT_LOG="$TMP_ROOT/gopass-insert.log"
: >"$INSERT_LOG"
export GOPASS_INSERT_LOG="$INSERT_LOG"

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

assert_equals() {
    local actual="$1"
    local expected="$2"
    if [[ "$actual" != "$expected" ]]; then
        echo "expected: $expected" >&2
        echo "actual  : $actual" >&2
        exit 1
    fi
}

codex_list="$(PATH="$BASE_PATH" "$BIN/codex-manage" list | strip_ansi)"
claude_list="$(PATH="$BASE_PATH" "$BIN/claude-manage" list | strip_ansi)"

# codex-manage list: native + valid third-party for codex path only.
assert_contains "$codex_list" "openai (native)"
assert_contains "$codex_list" "deepseek@alpha"
assert_contains "$codex_list" "kimi@legacy"
assert_not_contains "$codex_list" "qwen@beta"
assert_not_contains "$codex_list" "glm@ghost"
assert_not_contains "$codex_list" "(no key)"

# claude-manage list: native accounts + valid third-party for claude path only.
assert_contains "$claude_list" "anthropic (native)"
assert_contains "$claude_list" "opus (native)"
assert_contains "$claude_list" "haiku (native)"
assert_contains "$claude_list" "qwen@beta"
assert_contains "$claude_list" "kimi@legacy"
assert_not_contains "$claude_list" "deepseek@alpha"
assert_not_contains "$claude_list" "doubao@private"
assert_not_contains "$claude_list" "naapi@private"
assert_not_contains "$claude_list" "(no key)"

# list-visible runtime accounts must be operable for switch.
PATH="$BASE_PATH" "$BIN/codex-manage" switch deepseek@alpha >/dev/null
PATH="$BASE_PATH" "$BIN/claude-manage" switch qwen@beta >/dev/null

# list-visible runtime accounts must be operable for test.
PATH="$BASE_PATH" "$BIN/codex-manage" test deepseek@alpha >/dev/null
PATH="$BASE_PATH" "$BIN/claude-manage" test qwen@beta >/dev/null

# list-visible runtime accounts must be operable for launcher entrypoints.
PATH="$BASE_PATH" "$BIN/codex-with" deepseek@alpha --version >/dev/null
PATH="$BASE_PATH" "$BIN/claude-with" qwen@beta --version >/dev/null

# Canonical write path should be tool-specific.
codex_api_path="$(
    PATH="$BASE_PATH" bash -c "source '$BIN/lib/ai/codex'; api_key_path deepseek alpha"
)"
claude_api_path="$(
    PATH="$BASE_PATH" bash -c "source '$BIN/lib/ai/claude'; api_key_path deepseek alpha"
)"
assert_equals "$codex_api_path" "codex/providers/deepseek/accounts/YWxwaGE/api_key"
assert_equals "$claude_api_path" "claude/providers/deepseek/accounts/YWxwaGE/api_key"

# Candidate paths are now single canonical path per tool.
codex_candidates="$(
    PATH="$BASE_PATH" bash -c "source '$BIN/lib/ai/codex'; api_key_path_candidates kimi legacy"
)"
claude_candidates="$(
    PATH="$BASE_PATH" bash -c "source '$BIN/lib/ai/claude'; api_key_path_candidates kimi legacy"
)"
assert_equals "$codex_candidates" "codex/providers/kimi/accounts/bGVnYWN5/api_key"
assert_equals "$claude_candidates" "claude/providers/kimi/accounts/bGVnYWN5/api_key"

# Store operations always write to tool-specific canonical path.
PATH="$BASE_PATH" bash -c "source '$BIN/lib/ai/codex'; store_api_key deepseek alpha sk-test"
assert_equals "$(tail -n1 "$INSERT_LOG")" "codex/providers/deepseek/accounts/YWxwaGE/api_key"

echo "test_manage_list_logic: OK"
