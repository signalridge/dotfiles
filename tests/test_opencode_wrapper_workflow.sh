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

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/opencode-wrapper-test.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

export HOME="$TMP_ROOT/home"
mkdir -p "$HOME/.config/chezmoi" "$HOME/.config/opencode"
cat >"$HOME/.config/chezmoi/chezmoi.toml" <<'EOF'
[data]
claudeProviderAccount = "anthropic"
codexProviderAccount = "openai"
opencodeProviderAccount = "deepseek@private"
EOF

BIN="$TMP_ROOT/bin"
STUB="$TMP_ROOT/stub"
mkdir -p "$BIN/lib/ai" "$BIN/lib" "$STUB"

# Render scripts/libs for isolated execution.
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/lib/common.tmpl" >"$BIN/lib/common"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/lib/ai/core.tmpl" >"$BIN/lib/ai/core"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/lib/ai/opencode.tmpl" >"$BIN/lib/ai/opencode"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/executable_opencode-token.tmpl" >"$BIN/opencode-token"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/executable_opencode-with.tmpl" >"$BIN/opencode-with"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/executable_opencode-manage.tmpl" >"$BIN/opencode-manage"
chmod +x "$BIN/lib/common" "$BIN/lib/ai/core" "$BIN/lib/ai/opencode" \
    "$BIN/opencode-token" "$BIN/opencode-with" "$BIN/opencode-manage"

cat >"$HOME/.config/opencode/opencode.jsonc" <<'EOF'
{
  "model": "deepseek/deepseek-chat",
  "small_model": "deepseek/deepseek-chat",
  "provider": {
    "deepseek": {
      "npm": "@ai-sdk/openai-compatible",
      "env": ["DEEPSEEK_API_KEY"],
      "options": {
        "baseURL": "https://api.deepseek.com/v1"
      },
      "models": {
        "deepseek-chat": {}
      }
    },
    "qwen": {
      "npm": "@ai-sdk/openai-compatible",
      "env": ["DASHSCOPE_API_KEY"],
      "options": {
        "baseURL": "https://dashscope.aliyuncs.com/compatible-mode/v1"
      },
      "models": {
        "qwen3-coder-plus": {}
      }
    }
  }
}
EOF

cat >"$HOME/.config/opencode/oh-my-opencode.jsonc" <<'EOF'
{
  "claude_code": {
    "mcp": false,
    "commands": false,
    "skills": false,
    "agents": false,
    "hooks": false,
    "plugins": false
  },
  "disabled_hooks": ["claude-code-hooks"],
  "skills": {
    "sources": [
      { "path": ".agents/skills", "recursive": true }
    ]
  }
}
EOF

cat >"$HOME/.config/opencode/AGENTS.md" <<'EOF'
# OpenCode test instructions
EOF

# Stubs
cat >"$STUB/chezmoi" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "data" ]]; then
    cat <<'JSON'
{"claudeProviderAccount":"anthropic","codexProviderAccount":"openai","opencodeProviderAccount":"deepseek@private"}
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
            opencode/providers/deepseek/accounts)
                echo "opencode/providers/deepseek/accounts/YWxwaGE/api_key"
                exit 0
                ;;
            opencode/providers/qwen/accounts)
                echo "opencode/providers/qwen/accounts/YmV0YQ/api_key"
                exit 0
                ;;
            opencode/providers/deepseek/accounts/YWxwaGE/api_key|\
            opencode/providers/qwen/accounts/YmV0YQ/api_key)
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
            opencode/providers/deepseek/accounts/YWxwaGE/api_key|\
            opencode/providers/qwen/accounts/YmV0YQ/api_key)
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

cat >"$STUB/opencode" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
{
    echo "OPENCODE_DISABLE_CLAUDE_CODE_PROMPT=${OPENCODE_DISABLE_CLAUDE_CODE_PROMPT:-}"
    echo "OPENCODE_DISABLE_EXTERNAL_SKILLS=${OPENCODE_DISABLE_EXTERNAL_SKILLS:-}"
    echo "DEEPSEEK_API_KEY=${DEEPSEEK_API_KEY:-}"
    echo "DASHSCOPE_API_KEY=${DASHSCOPE_API_KEY:-}"
    echo "OPENCODE_CONFIG_CONTENT=${OPENCODE_CONFIG_CONTENT:-}"
} >"${OPENCODE_CAPTURE_ENV:?}"
printf '%s\n' "$@" >"${OPENCODE_CAPTURE_ARGS:?}"
exit 0
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
cat <<'OUT'
{"ok":true}
200
OUT
EOF

chmod +x "$STUB/chezmoi" "$STUB/gopass" "$STUB/opencode" "$STUB/curl"

BASE_PATH="$STUB:$BIN:$PATH"
INSERT_LOG="$TMP_ROOT/gopass-insert.log"
CAPTURE_ENV="$TMP_ROOT/opencode.env"
CAPTURE_ARGS="$TMP_ROOT/opencode.args"
: >"$INSERT_LOG"
export GOPASS_INSERT_LOG="$INSERT_LOG"
export OPENCODE_CAPTURE_ENV="$CAPTURE_ENV"
export OPENCODE_CAPTURE_ARGS="$CAPTURE_ARGS"

assert_equals() {
    local actual="$1"
    local expected="$2"
    if [[ "$actual" != "$expected" ]]; then
        echo "expected: $expected" >&2
        echo "actual  : $actual" >&2
        exit 1
    fi
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

# opencode-token config resolution
cfg="$(PATH="$BASE_PATH" "$BIN/opencode-token" --config deepseek@private)"
assert_equals "$(echo "$cfg" | jq -r '.provider')" "deepseek"
assert_equals "$(echo "$cfg" | jq -r '.model')" "deepseek-chat"
assert_equals "$(echo "$cfg" | jq -r '.model_ref')" "deepseek/deepseek-chat"
assert_equals "$(echo "$cfg" | jq -r '.env_var')" "DEEPSEEK_API_KEY"

PATH="$BASE_PATH" "$BIN/opencode-token" --check deepseek@alpha
PATH="$BASE_PATH" "$BIN/opencode-token" --check openai

# opencode-manage list and switch
list_out="$(PATH="$BASE_PATH" "$BIN/opencode-manage" list | sed -E $'s/\x1B\\[[0-9;]*[mK]//g')"
assert_contains "$list_out" "openai (native)"
assert_contains "$list_out" "anthropic (native)"
assert_contains "$list_out" "deepseek@alpha"

# Current selector should remain runtime-switchable even without stored key.
PATH="$BASE_PATH" "$BIN/opencode-manage" switch deepseek@private >/dev/null
PATH="$BASE_PATH" "$BIN/opencode-manage" switch deepseek@alpha >/dev/null
assert_contains "$(cat "$HOME/.config/chezmoi/chezmoi.toml")" "opencodeProviderAccount = \"deepseek@alpha\""

# Doctor should provide readiness summary and selector state.
doctor_out="$(PATH="$BASE_PATH" "$BIN/opencode-manage" doctor | sed -E $'s/\x1B\\[[0-9;]*[mK]//g')"
assert_contains "$doctor_out" "OpenCode Workflow Doctor"
assert_contains "$doctor_out" "current selector: deepseek@private (deepseek)"
assert_contains "$doctor_out" "claude_code.mcp disabled"
assert_contains "$doctor_out" "no-Claude compatibility bridge policy active"
assert_contains "$doctor_out" "Summary:"

# opencode-with should inject runtime isolation flags, model override, and provider key
PATH="$BASE_PATH" "$BIN/opencode-with" deepseek@alpha run "hello" >/dev/null
env_dump="$(cat "$CAPTURE_ENV")"
assert_contains "$env_dump" "OPENCODE_DISABLE_CLAUDE_CODE_PROMPT=1"
assert_contains "$env_dump" "OPENCODE_DISABLE_EXTERNAL_SKILLS=1"
assert_contains "$env_dump" "DEEPSEEK_API_KEY=test-key"
assert_equals "$(grep '^OPENCODE_CONFIG_CONTENT=' "$CAPTURE_ENV" | sed 's/^OPENCODE_CONFIG_CONTENT=//g' | jq -r '.model')" "deepseek/deepseek-chat"

# Canonical write path should be tool-specific.
opencode_api_path="$(
    PATH="$BASE_PATH" bash -c "source '$BIN/lib/ai/opencode'; api_key_path deepseek alpha"
)"
assert_equals "$opencode_api_path" "opencode/providers/deepseek/accounts/YWxwaGE/api_key"

echo "test_opencode_wrapper_workflow: OK"
