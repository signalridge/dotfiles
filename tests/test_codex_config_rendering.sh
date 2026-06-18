#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

require_cmd() {
    command -v "$1" >/dev/null 2>&1
}

for c in bash chezmoi; do
    require_cmd "$c" || {
        echo "SKIP: missing dependency: $c" >&2
        exit 0
    }
done

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/codex-config-render.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

export HOME="$TMP_ROOT/home"
mkdir -p "$HOME/.config/chezmoi" "$HOME/.codex"

assert_file_contains() {
    local file="$1"
    local expected="$2"
    if ! grep -Fq "$expected" "$file"; then
        echo "expected to find: $expected" >&2
        echo "--- $file ---" >&2
        cat "$file" >&2
        exit 1
    fi
}

assert_file_not_contains() {
    local file="$1"
    local unexpected="$2"
    if grep -Fq "$unexpected" "$file"; then
        echo "expected to not find: $unexpected" >&2
        echo "--- $file ---" >&2
        cat "$file" >&2
        exit 1
    fi
}

MODIFY_SCRIPT="$TMP_ROOT/modify_config.sh"
RENDERED="$TMP_ROOT/config.toml"
CLAUDE_SETTINGS="$TMP_ROOT/settings.json"
DEEPSEEK_CLAUDE_SETTINGS="$TMP_ROOT/settings-deepseek.json"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_codex/modify_config.toml.tmpl" >"$MODIFY_SCRIPT"
bash "$MODIFY_SCRIPT" </dev/null >"$RENDERED"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_claude/settings.json.tmpl" >"$CLAUDE_SETTINGS"

assert_file_contains "$RENDERED" 'model = "gpt-5.5"'
assert_file_contains "$RENDERED" 'model_reasoning_effort = "xhigh"'
assert_file_not_contains "$RENDERED" 'service_tier ='
assert_file_contains "$RENDERED" 'fast_mode = false'
assert_file_contains "$RENDERED" '[[hooks.UserPromptSubmit]]'
assert_file_contains "$RENDERED" 'tmux-ai-agent-state codex busy'
assert_file_contains "$RENDERED" '[[hooks.Stop]]'
assert_file_contains "$RENDERED" 'tmux-ai-agent-state codex idle'
assert_file_not_contains "$RENDERED" '[[hooks.SubagentStop]]'
assert_file_not_contains "$RENDERED" 'async = true'

assert_file_contains "$CLAUDE_SETTINGS" '"UserPromptSubmit"'
assert_file_contains "$CLAUDE_SETTINGS" 'tmux-ai-agent-state claude busy'
assert_file_contains "$CLAUDE_SETTINGS" '"SessionEnd"'
assert_file_contains "$CLAUDE_SETTINGS" '"Stop"'
assert_file_contains "$CLAUDE_SETTINGS" 'tmux-ai-agent-state claude idle'
assert_file_not_contains "$CLAUDE_SETTINGS" '"SubagentStop"'

chezmoi execute-template --source "$ROOT" \
    --override-data '{"claudeProviderAccount":"deepseek@private"}' \
    <"$ROOT/dot_claude/settings.json.tmpl" >"$DEEPSEEK_CLAUDE_SETTINGS"
assert_file_contains "$DEEPSEEK_CLAUDE_SETTINGS" '"ANTHROPIC_BASE_URL": "https://api.deepseek.com/anthropic"'
assert_file_contains "$DEEPSEEK_CLAUDE_SETTINGS" '"ANTHROPIC_MODEL": "deepseek-v4-pro[1m]"'
assert_file_contains "$DEEPSEEK_CLAUDE_SETTINGS" '"ANTHROPIC_DEFAULT_OPUS_MODEL": "deepseek-v4-pro[1m]"'
assert_file_contains "$DEEPSEEK_CLAUDE_SETTINGS" '"ANTHROPIC_DEFAULT_SONNET_MODEL": "deepseek-v4-pro[1m]"'
assert_file_contains "$DEEPSEEK_CLAUDE_SETTINGS" '"ANTHROPIC_DEFAULT_HAIKU_MODEL": "deepseek-v4-flash"'
assert_file_contains "$DEEPSEEK_CLAUDE_SETTINGS" '"CLAUDE_CODE_SUBAGENT_MODEL": "deepseek-v4-pro[1m]"'
assert_file_contains "$DEEPSEEK_CLAUDE_SETTINGS" '"CLAUDE_CODE_EFFORT_LEVEL": "max"'

cat >"$TMP_ROOT/existing-config.toml" <<'EOF'
model = "old-model"

[hooks.state]

[hooks.state."/Users/example/.codex/config.toml:session_start:0:0"]
trusted_hash = "sha256:aaa111"

[hooks.state."/Users/example/.codex/config.toml:user_prompt_submit:0:0"]
trusted_hash = "sha256:abc123"

[hooks.state."/Users/example/.codex/config.toml:stop:0:0"]
trusted_hash = "sha256:def456"

[hooks.state."/Users/example/.codex/config.toml:subagent_stop:0:0"]
trusted_hash = "sha256:old-subagent"

[projects."/tmp/example"]
trust_level = "trusted"

[projects."/tmp/other"]
trust_level = "trusted"
EOF

bash "$MODIFY_SCRIPT" <"$TMP_ROOT/existing-config.toml" >"$RENDERED"
assert_file_contains "$RENDERED" '[hooks.state]'
assert_file_contains "$RENDERED" '[hooks.state."/Users/example/.codex/config.toml:session_start:0:0"]'
assert_file_contains "$RENDERED" 'trusted_hash = "sha256:aaa111"'
assert_file_contains "$RENDERED" '[hooks.state."/Users/example/.codex/config.toml:user_prompt_submit:0:0"]'
assert_file_contains "$RENDERED" 'trusted_hash = "sha256:abc123"'
assert_file_contains "$RENDERED" '[hooks.state."/Users/example/.codex/config.toml:stop:0:0"]'
assert_file_contains "$RENDERED" 'trusted_hash = "sha256:def456"'
assert_file_not_contains "$RENDERED" 'subagent_stop'
assert_file_not_contains "$RENDERED" 'sha256:old-subagent'
assert_file_contains "$RENDERED" '[projects."/tmp/example"]'
assert_file_contains "$RENDERED" '[projects."/tmp/other"]'
assert_file_not_contains "$RENDERED" 'old-model'

echo "test_codex_config_rendering: OK"
