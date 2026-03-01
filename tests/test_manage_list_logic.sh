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
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/lib/common" >"$BIN/lib/common"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/lib/ai/core.tmpl" >"$BIN/lib/ai/core"
cp "$ROOT/dot_local/bin/lib/ai/codex" "$BIN/lib/ai/codex"
cp "$ROOT/dot_local/bin/lib/ai/claude" "$BIN/lib/ai/claude"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/executable_codex-manage" >"$BIN/codex-manage"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/executable_claude-manage" >"$BIN/claude-manage"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/executable_codex-with" >"$BIN/codex-with"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/executable_claude-with" >"$BIN/claude-with"
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
{"claudeProviderAccount":"qwen@beta","codexProviderAccount":"deepseek@private"}
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
            codex)
                echo "codex/deepseek/private/api_key"
                exit 0
                ;;
            claude)
                echo "claude/qwen/beta/api_key"
                exit 0
                ;;
            codex/deepseek/private/api_key|\
            claude/qwen/beta/api_key)
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
            codex/deepseek/private/api_key|\
            claude/qwen/beta/api_key)
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
if [[ "${CURL_FORCE_FAIL_MESSAGES:-0}" == "1" && "$args" == *"/v1/messages"* ]]; then
    exit 7
fi
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
NOJQ_PATH="$TMP_ROOT/no-jq-bin"
mkdir -p "$NOJQ_PATH"
ln -sf "$(command -v bash)" "$NOJQ_PATH/bash"
ln -sf "$(command -v dirname)" "$NOJQ_PATH/dirname"
ln -sf "$(command -v awk)" "$NOJQ_PATH/awk"
ln -sf "$STUB/chezmoi" "$NOJQ_PATH/chezmoi"
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
assert_contains "$codex_list" "deepseek@private"
assert_not_contains "$codex_list" "kimi"
assert_not_contains "$codex_list" "qwen@beta"
assert_not_contains "$codex_list" "(no key)"

# claude-manage list: native accounts + valid third-party for claude path only.
assert_contains "$claude_list" "anthropic (native)"
assert_contains "$claude_list" "opus (native)"
assert_contains "$claude_list" "haiku (native)"
assert_contains "$claude_list" "qwen@beta"
assert_not_contains "$claude_list" "qwen@private"
assert_not_contains "$claude_list" "kimi"
assert_not_contains "$claude_list" "deepseek"
assert_not_contains "$claude_list" "doubao@private"
assert_not_contains "$claude_list" "naapi@private"
assert_not_contains "$claude_list" "(no key)"

# list-visible runtime accounts must be operable for switch.
PATH="$BASE_PATH" "$BIN/codex-manage" switch deepseek@private >/dev/null
PATH="$BASE_PATH" "$BIN/claude-manage" switch qwen@beta >/dev/null

# list-visible runtime accounts must be operable for test.
PATH="$BASE_PATH" "$BIN/codex-manage" test deepseek@private >/dev/null
PATH="$BASE_PATH" "$BIN/claude-manage" test qwen@beta >/dev/null

# claude-manage test should report network error gracefully when curl fails.
claude_fail_output="$(CURL_FORCE_FAIL_MESSAGES=1 PATH="$BASE_PATH" "$BIN/claude-manage" test qwen@beta 2>&1 || true)"
assert_contains "$claude_fail_output" "Network error"

# list-visible runtime accounts must be operable for launcher entrypoints.
PATH="$BASE_PATH" "$BIN/codex-with" deepseek@private --version >/dev/null
PATH="$BASE_PATH" "$BIN/claude-with" qwen@beta --version >/dev/null

# doctor: parity diagnostics should be available in both tools.
codex_doctor="$(PATH="$BASE_PATH" "$BIN/codex-manage" doctor | strip_ansi)"
claude_doctor="$(PATH="$BASE_PATH" "$BIN/claude-manage" doctor | strip_ansi)"
assert_contains "$codex_doctor" "Codex Account Doctor"
assert_contains "$codex_doctor" "current selector: deepseek@private (deepseek)"
assert_contains "$codex_doctor" "Summary:"
assert_not_contains "$codex_doctor" "\\033["
assert_contains "$claude_doctor" "Claude Account Doctor"
assert_contains "$claude_doctor" "current selector: qwen@beta (qwen)"
assert_contains "$claude_doctor" "Summary:"
assert_not_contains "$claude_doctor" "\\033["

# doctor: missing jq should fail fast with actionable error instead of abrupt exit.
set +e
codex_doctor_nojq="$(PATH="$NOJQ_PATH" "$BIN/codex-manage" doctor 2>&1)"
codex_doctor_nojq_rc=$?
claude_doctor_nojq="$(PATH="$NOJQ_PATH" "$BIN/claude-manage" doctor 2>&1)"
claude_doctor_nojq_rc=$?
set -e
assert_equals "$codex_doctor_nojq_rc" "1"
assert_equals "$claude_doctor_nojq_rc" "1"
assert_contains "$codex_doctor_nojq" "required command not found: jq"
assert_contains "$claude_doctor_nojq" "required command not found: jq"

# Canonical write path should be tool-specific.
codex_api_path="$(
    PATH="$BASE_PATH" bash -c "source '$BIN/lib/ai/codex'; api_key_path deepseek alpha"
)"
claude_api_path="$(
    PATH="$BASE_PATH" bash -c "source '$BIN/lib/ai/claude'; api_key_path deepseek alpha"
)"
opencode_api_path="$(
    PATH="$BASE_PATH" AI_TOOL_CONTEXT=opencode bash -c "source '$BIN/lib/ai/core'; api_key_path deepseek alpha"
)"
assert_equals "$codex_api_path" "codex/deepseek/alpha/api_key"
assert_equals "$claude_api_path" "claude/deepseek/alpha/api_key"
assert_equals "$opencode_api_path" "opencode/deepseek/alpha/api_key"

# Candidate paths use provider/account canonical path only.
codex_candidates="$(
    PATH="$BASE_PATH" bash -c "source '$BIN/lib/ai/codex'; api_key_path_candidates kimi private"
)"
claude_candidates="$(
    PATH="$BASE_PATH" bash -c "source '$BIN/lib/ai/claude'; api_key_path_candidates kimi private"
)"
assert_equals "$codex_candidates" $'codex/kimi/private/api_key'
assert_equals "$claude_candidates" $'claude/kimi/private/api_key'

# Store operations always write to tool-specific canonical path.
PATH="$BASE_PATH" bash -c "source '$BIN/lib/ai/codex'; store_api_key deepseek alpha sk-test"
assert_equals "$(tail -n1 "$INSERT_LOG")" "codex/deepseek/alpha/api_key"

echo "test_manage_list_logic: OK"
