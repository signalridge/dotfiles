#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

require_cmd() {
    command -v "$1" >/dev/null 2>&1
}

fail() {
    echo "$*" >&2
    exit 1
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
NEWAPI_CLAUDE_SETTINGS="$TMP_ROOT/settings-newapi.json"
PI_MCP="$TMP_ROOT/pi-mcp.json"
PI_SETTINGS_MODIFY="$TMP_ROOT/pi-settings-modify.sh"
PI_SETTINGS="$TMP_ROOT/pi-settings.json"
PI_MODELS="$TMP_ROOT/pi-models.json"
PI_DATA="$TMP_ROOT/pi-data.json"
PI_SUBAGENTS_CONFIG="$ROOT/dot_pi/agent/subagents.json"
PI_AGENTS_DIR="$ROOT/dot_pi/agent/agents"
CURSOR_MCP="$TMP_ROOT/cursor-mcp.json"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_codex/modify_config.toml.tmpl" >"$MODIFY_SCRIPT"
bash "$MODIFY_SCRIPT" </dev/null >"$RENDERED"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_claude/settings.json.tmpl" >"$CLAUDE_SETTINGS"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_pi/agent/mcp.json.tmpl" >"$PI_MCP"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_pi/agent/modify_settings.json.tmpl" >"$PI_SETTINGS_MODIFY"
bash "$PI_SETTINGS_MODIFY" </dev/null >"$PI_SETTINGS"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_pi/agent/private_models.json.tmpl" >"$PI_MODELS"
chezmoi data --source "$ROOT" --format json >"$PI_DATA"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_cursor/mcp.json.tmpl" >"$CURSOR_MCP"

assert_file_contains "$RENDERED" 'model = "gpt-5.6-sol"'
assert_file_contains "$RENDERED" 'model_reasoning_effort = "max"'
assert_file_not_contains "$RENDERED" 'service_tier ='
assert_file_contains "$RENDERED" 'fast_mode = false'
assert_file_contains "$RENDERED" '[[hooks.UserPromptSubmit]]'
assert_file_contains "$RENDERED" 'tmux-ai-agent-state codex busy'
assert_file_contains "$RENDERED" '[[hooks.Stop]]'
assert_file_contains "$RENDERED" 'tmux-ai-agent-state codex idle'
assert_file_not_contains "$RENDERED" '[[hooks.SubagentStop]]'
assert_file_not_contains "$RENDERED" 'async = true'

assert_file_contains "$RENDERED" '[model_providers.krill]'
assert_file_contains "$RENDERED" 'base_url = "https://api.krill-ai.com/codex/v1"'
assert_file_contains "$RENDERED" 'requires_openai_auth = true'
assert_file_contains "$RENDERED" 'wire_api = "responses"'

assert_file_contains "$CLAUDE_SETTINGS" '"UserPromptSubmit"'
assert_file_contains "$CLAUDE_SETTINGS" 'tmux-ai-agent-state claude busy'
assert_file_contains "$CLAUDE_SETTINGS" '"SessionEnd"'
assert_file_contains "$CLAUDE_SETTINGS" '"Stop"'
assert_file_contains "$CLAUDE_SETTINGS" 'tmux-ai-agent-state claude idle'
assert_file_not_contains "$CLAUDE_SETTINGS" '"SubagentStop"'
assert_file_not_contains "$CLAUDE_SETTINGS" '"Bash(codegraph:*)"'
assert_file_not_contains "$CLAUDE_SETTINGS" '"mcp__codegraph__*"'

assert_file_not_contains "$PI_MCP" '"codegraph"'
assert_file_not_contains "$PI_MCP" '"@colbymchenry/codegraph@1.2.0"'
assert_file_not_contains "$CURSOR_MCP" '"codegraph"'
assert_file_not_contains "$CURSOR_MCP" '"@colbymchenry/codegraph@1.2.0"'
assert_file_contains "$PI_SETTINGS" '"defaultProvider": "krill"'
assert_file_contains "$PI_SETTINGS" '"defaultModel": "gpt-5.6-sol"'
assert_file_not_contains "$PI_SETTINGS" '"defaultProvider": "openai-codex"'
jq -e '
    .compaction == {
        "enabled": true,
        "keepRecentTokens": 16000,
        "reserveTokens": 65536
    }
' "$PI_SETTINGS" >/dev/null
jq -e '
    .branchSummary == {
        "reserveTokens": 16384,
        "skipPrompt": false
    }
' "$PI_SETTINGS" >/dev/null
assert_file_not_contains "$PI_SETTINGS" 'pi-ultra-compact'
jq -e '
    [.packages[] | select(. == "npm:pi-continue@0.9.3")] | length == 0
' "$PI_SETTINGS" >/dev/null
jq -e '
    .defaultThinkingLevel == "max"
    and (has("subagents") | not)
    and ([.packages[] | select(. == "npm:@tintinweb/pi-subagents@0.13.0")] | length == 1)
    and ([.packages[] | select(. == "npm:pi-subagents")] | length == 0)
' "$PI_SETTINGS" >/dev/null
jq -e '
    . == {
        "maxConcurrent": 4,
        "defaultMaxTurns": 0,
        "graceTurns": 8,
        "defaultJoinMode": "smart",
        "schedulingEnabled": false,
        "scopeModels": false,
        "disableDefaultAgents": true,
        "toolDescriptionMode": "full",
        "fleetView": true,
        "widgetMode": "background"
    }
' "$PI_SUBAGENTS_CONFIG" >/dev/null
for agent in worker planner researcher reviewer oracle context-builder scout delegate; do
    assert_file_contains "$PI_AGENTS_DIR/$agent.md" 'model: krill/gpt-5.6-sol'
    assert_file_contains "$PI_AGENTS_DIR/$agent.md" 'thinking: max'
    assert_file_contains "$PI_AGENTS_DIR/$agent.md" 'max_turns: 0'
done
[[ ! -e "$ROOT/dot_pi/agent/extensions/subagent/config.json" ]] || fail "legacy pi-subagents config still exists"
[[ ! -e "$ROOT/dot_pi/agent/extensions/pi-continue.json" ]] || fail "pi-continue.json still exists (extension removed)"
# openai-codex is built into Pi; models.json must contain only custom providers.
jq -e '
    (.providers | has("openai-codex") | not)
' "$PI_MODELS" >/dev/null
jq -e '
    (.providers.qwen.models[] | select(.id == "qwen3-coder-plus")) as $coder
    | (.providers.qwen.models[] | select(.id == "qwen3-max")) as $max
    | $coder.contextWindow == 1000000
      and $coder.maxTokens == 65536
      and $max.contextWindow == 262144
      and $max.maxTokens == 65536
' "$PI_MODELS" >/dev/null
jq -e '
    (.providers.doubao.models[] | select(.id == "doubao-seed-1-6-thinking-250715")) as $model
    | $model.contextWindow == 256000
      and $model.maxTokens == 16000
' "$PI_MODELS" >/dev/null
jq -e 'all(.providers[]?.models[]?; has("contextWindow") and has("maxTokens"))' \
    "$PI_MODELS" >/dev/null
assert_file_not_contains "$PI_MODELS" 'OPENAI-CODEX_API_KEY'
jq -e '
    all(.pi.customProviders[]?.models[]?;
        type == "object" and has("contextWindow") and has("maxTokens"))
' "$PI_DATA" >/dev/null

chezmoi execute-template --source "$ROOT" \
    --override-data '{"claudeProviderAccount":"deepseek@private"}' \
    <"$ROOT/dot_claude/settings.json.tmpl" >"$DEEPSEEK_CLAUDE_SETTINGS"
assert_file_contains "$DEEPSEEK_CLAUDE_SETTINGS" '"ANTHROPIC_BASE_URL": "https://api.deepseek.com/anthropic"'
assert_file_contains "$DEEPSEEK_CLAUDE_SETTINGS" '"ANTHROPIC_MODEL": "deepseek-v4-pro[1m]"'
assert_file_contains "$DEEPSEEK_CLAUDE_SETTINGS" '"ANTHROPIC_DEFAULT_OPUS_MODEL": "deepseek-v4-pro[1m]"'
assert_file_contains "$DEEPSEEK_CLAUDE_SETTINGS" '"ANTHROPIC_DEFAULT_SONNET_MODEL": "deepseek-v4-pro[1m]"'
assert_file_contains "$DEEPSEEK_CLAUDE_SETTINGS" '"ANTHROPIC_DEFAULT_HAIKU_MODEL": "deepseek-v4-flash"'
assert_file_contains "$DEEPSEEK_CLAUDE_SETTINGS" '"CLAUDE_CODE_SUBAGENT_MODEL": "deepseek-v4-pro[1m]"'
assert_file_not_contains "$DEEPSEEK_CLAUDE_SETTINGS" 'CLAUDE_CODE_EFFORT_LEVEL'

chezmoi execute-template --source "$ROOT" \
    --override-data '{"claudeProviderAccount":"newapi@private"}' \
    <"$ROOT/dot_claude/settings.json.tmpl" >"$NEWAPI_CLAUDE_SETTINGS"
assert_file_contains "$NEWAPI_CLAUDE_SETTINGS" '"ANTHROPIC_BASE_URL": "https://newapi.3689403.xyz/"'
assert_file_contains "$NEWAPI_CLAUDE_SETTINGS" '"ANTHROPIC_MODEL": "glm-5.2"'
assert_file_contains "$NEWAPI_CLAUDE_SETTINGS" '"ANTHROPIC_SMALL_FAST_MODEL": "glm-4.7"'
assert_file_contains "$NEWAPI_CLAUDE_SETTINGS" '"ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-5.2"'
assert_file_contains "$NEWAPI_CLAUDE_SETTINGS" '"ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-5.2"'
assert_file_contains "$NEWAPI_CLAUDE_SETTINGS" '"ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.7"'
assert_file_contains "$NEWAPI_CLAUDE_SETTINGS" '"CLAUDE_CODE_SUBAGENT_MODEL": "glm-5.2"'
assert_file_contains "$NEWAPI_CLAUDE_SETTINGS" '"CLAUDE_CODE_AUTO_COMPACT_WINDOW": "1000000"'
assert_file_not_contains "$NEWAPI_CLAUDE_SETTINGS" 'CLAUDE_CODE_EFFORT_LEVEL'

KRILL_CLAUDE_SETTINGS="$TMP_ROOT/settings-krill.json"
chezmoi execute-template --source "$ROOT" \
    --override-data '{"claudeProviderAccount":"krill@private"}' \
    <"$ROOT/dot_claude/settings.json.tmpl" >"$KRILL_CLAUDE_SETTINGS"
assert_file_contains "$KRILL_CLAUDE_SETTINGS" '"ANTHROPIC_BASE_URL": "https://api.krill-ai.com/codex"'
assert_file_contains "$KRILL_CLAUDE_SETTINGS" '"ANTHROPIC_MODEL": "gpt-5.6-sol"'
assert_file_contains "$KRILL_CLAUDE_SETTINGS" '"CLAUDE_CODE_ATTRIBUTION_HEADER": "0"'
assert_file_contains "$KRILL_CLAUDE_SETTINGS" '"CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS": "1"'
assert_file_contains "$KRILL_CLAUDE_SETTINGS" '"ANTHROPIC_DEFAULT_OPUS_MODEL_SUPPORTED_CAPABILITIES": "thinking,adaptive_thinking,temperature,effort,max_effort"'
assert_file_contains "$KRILL_CLAUDE_SETTINGS" '"ANTHROPIC_DEFAULT_SONNET_MODEL_SUPPORTED_CAPABILITIES": "thinking,adaptive_thinking,temperature,effort,max_effort"'
assert_file_contains "$KRILL_CLAUDE_SETTINGS" '"ANTHROPIC_DEFAULT_HAIKU_MODEL_SUPPORTED_CAPABILITIES": "thinking,adaptive_thinking,temperature,effort,max_effort"'
assert_file_contains "$KRILL_CLAUDE_SETTINGS" '"CLAUDE_CODE_SUBAGENT_MODEL": "gpt-5.6-sol"'
assert_file_not_contains "$KRILL_CLAUDE_SETTINGS" 'CLAUDE_CODE_EFFORT_LEVEL'

# Native Anthropic default must not leak krill-only env keys.
assert_file_not_contains "$CLAUDE_SETTINGS" 'CLAUDE_CODE_ATTRIBUTION_HEADER'
assert_file_not_contains "$CLAUDE_SETTINGS" 'SUPPORTED_CAPABILITIES'

# Codex now runs GPT-5.6 at max in every environment; Claude keeps its
# existing personal/work effort split. Render both explicitly via --override-data
# so the assertions don't depend on the ambient work/private value.

# Personal render (work=false): Codex default and named [profiles.*] use max;
# "medium" must not appear anywhere. Claude also runs max.
PERSONAL_CODEX_MODIFY="$TMP_ROOT/modify_config-personal.sh"
PERSONAL_CODEX="$TMP_ROOT/config-personal.toml"
PERSONAL_CLAUDE_SETTINGS="$TMP_ROOT/settings-personal.json"
chezmoi execute-template --source "$ROOT" --override-data '{"work":false}' \
    <"$ROOT/dot_codex/modify_config.toml.tmpl" >"$PERSONAL_CODEX_MODIFY"
bash "$PERSONAL_CODEX_MODIFY" </dev/null >"$PERSONAL_CODEX"
assert_file_contains "$PERSONAL_CODEX" 'model_reasoning_effort = "max"'
assert_file_not_contains "$PERSONAL_CODEX" 'model_reasoning_effort = "medium"'
chezmoi execute-template --source "$ROOT" --override-data '{"work":false}' \
    <"$ROOT/dot_claude/settings.json.tmpl" >"$PERSONAL_CLAUDE_SETTINGS"
assert_file_contains "$PERSONAL_CLAUDE_SETTINGS" '"effortLevel": "max"'

# Work render (work=true): Codex remains at max (including deep-review/research),
# while Claude keeps its existing medium work profile.
WORK_CODEX_MODIFY="$TMP_ROOT/modify_config-work.sh"
WORK_CODEX="$TMP_ROOT/config-work.toml"
WORK_CLAUDE_SETTINGS="$TMP_ROOT/settings-work.json"
chezmoi execute-template --source "$ROOT" --override-data '{"work":true}' \
    <"$ROOT/dot_codex/modify_config.toml.tmpl" >"$WORK_CODEX_MODIFY"
bash "$WORK_CODEX_MODIFY" </dev/null >"$WORK_CODEX"
assert_file_contains "$WORK_CODEX" 'model_reasoning_effort = "max"'
assert_file_not_contains "$WORK_CODEX" 'model_reasoning_effort = "medium"'
chezmoi execute-template --source "$ROOT" --override-data '{"work":true}' \
    <"$ROOT/dot_claude/settings.json.tmpl" >"$WORK_CLAUDE_SETTINGS"
assert_file_contains "$WORK_CLAUDE_SETTINGS" '"effortLevel": "medium"'

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
