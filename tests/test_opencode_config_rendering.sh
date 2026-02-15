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

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/opencode-config-test.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

assert_jq() {
    local file="$1"
    local expr="$2"
    if ! jq -e "$expr" "$file" >/dev/null; then
        echo "assertion failed: $expr" >&2
        echo "--- file: $file ---" >&2
        cat "$file" >&2
        exit 1
    fi
}

assert_file_contains() {
    local file="$1"
    local needle="$2"
    if ! grep -Fq "$needle" "$file"; then
        echo "assertion failed: expected '$file' to contain: $needle" >&2
        echo "--- file: $file ---" >&2
        cat "$file" >&2
        exit 1
    fi
}

render_opencode() {
    local account="$1"
    local output="$2"
    local override_data
    override_data="$(jq -cn --arg account "$account" '{opencodeProviderAccount: $account}')"

    chezmoi execute-template \
        --source "$ROOT" \
        --override-data "$override_data" \
        <"$ROOT/private_dot_config/opencode/opencode.jsonc.tmpl" \
        >"$output"
}

render_oh_my_opencode() {
    local output="$1"
    chezmoi execute-template \
        --source "$ROOT" \
        <"$ROOT/private_dot_config/opencode/oh-my-opencode.jsonc.tmpl" \
        >"$output"
}

OPENCODE_DEFAULT="$TMP_ROOT/opencode-default.jsonc"
OPENCODE_DEEPSEEK="$TMP_ROOT/opencode-deepseek.jsonc"
OPENCODE_HARUI="$TMP_ROOT/opencode-harui.jsonc"
OH_MY_OPENCODE="$TMP_ROOT/oh-my-opencode.jsonc"

render_opencode "openai" "$OPENCODE_DEFAULT"
render_opencode "deepseek@private" "$OPENCODE_DEEPSEEK"
render_opencode "harui@private" "$OPENCODE_HARUI"
render_oh_my_opencode "$OH_MY_OPENCODE"

assert_jq "$OPENCODE_DEFAULT" '.plugin == ["oh-my-opencode", "opencode-plugin-openspec"]'
assert_jq "$OPENCODE_DEFAULT" '.plugin | length == 2'
assert_jq "$OPENCODE_DEFAULT" '.model == "openai/gpt-5.3-codex" and .small_model == "openai/gpt-5.3-codex"'
assert_jq "$OPENCODE_DEEPSEEK" '.model == "deepseek/deepseek-chat" and .small_model == "deepseek/deepseek-chat"'
assert_jq "$OPENCODE_HARUI" '.model == "harui/gpt-5.3-codex" and .small_model == "harui/gpt-5.3-codex"'
assert_jq "$OPENCODE_DEFAULT" '.default_agent == "build"'
assert_jq "$OPENCODE_DEFAULT" '.instructions | index("AGENTS.md") != null'
assert_jq "$OPENCODE_DEFAULT" '.watcher.ignore | index("**/.git/**") != null'
assert_jq "$OPENCODE_DEFAULT" '.compaction.auto == true and .compaction.prune == true and .compaction.reserved == 16384'
assert_jq "$OPENCODE_DEFAULT" '.provider.deepseek.env == ["DEEPSEEK_API_KEY"]'
assert_jq "$OPENCODE_DEFAULT" '.provider.harui.env == ["HARUI_API_KEY"]'
assert_jq "$OPENCODE_DEFAULT" '.provider.harui.options.baseURL == "https://codex.harui.edu.kg"'
assert_jq "$OPENCODE_DEFAULT" '.provider.qwen.env == ["DASHSCOPE_API_KEY"]'
assert_jq "$OPENCODE_DEFAULT" '.provider.kimi.options.baseURL == "https://api.moonshot.ai/v1"'
assert_jq "$OPENCODE_DEFAULT" '.skills.paths | index(".agents/skills") != null'
assert_jq "$OPENCODE_DEFAULT" '.skills.paths | length == 1'

assert_jq "$OPENCODE_DEFAULT" '.permission.edit == "ask"'
assert_jq "$OPENCODE_DEFAULT" '.permission.bash == "ask"'
assert_jq "$OPENCODE_DEFAULT" '.permission.external_directory == "ask"'
assert_jq "$OPENCODE_DEFAULT" '.permission.task == "ask"'
assert_jq "$OPENCODE_DEFAULT" '.permission.skill == "ask"'

assert_jq "$OH_MY_OPENCODE" '.claude_code.mcp == false'
assert_jq "$OH_MY_OPENCODE" '.claude_code.commands == false'
assert_jq "$OH_MY_OPENCODE" '.claude_code.skills == false'
assert_jq "$OH_MY_OPENCODE" '.claude_code.agents == false'
assert_jq "$OH_MY_OPENCODE" '.claude_code.hooks == false'
assert_jq "$OH_MY_OPENCODE" '.claude_code.plugins == false'
assert_jq "$OH_MY_OPENCODE" '.disabled_hooks | index("claude-code-hooks") != null'
assert_jq "$OH_MY_OPENCODE" '.disabled_mcps == []'
assert_jq "$OH_MY_OPENCODE" '.disabled_agents == []'
assert_jq "$OH_MY_OPENCODE" '.disabled_skills == []'
assert_jq "$OH_MY_OPENCODE" '.disabled_commands == []'
assert_jq "$OH_MY_OPENCODE" '.disabled_tools == []'
assert_jq "$OH_MY_OPENCODE" '.sisyphus.tasks.claude_code_compat == false'
assert_jq "$OH_MY_OPENCODE" '.agents.atlas.category == "ultrabrain"'
assert_jq "$OH_MY_OPENCODE" '.agents["sisyphus-junior"].category == "deep"'
assert_jq "$OH_MY_OPENCODE" '.agents.prometheus.category == "unspecified-high"'
assert_jq "$OH_MY_OPENCODE" '.categories.quick.model == "anthropic/claude-haiku-4-5"'
assert_jq "$OH_MY_OPENCODE" '.categories.quick.description | length > 0'
assert_jq "$OH_MY_OPENCODE" '.background_task.defaultConcurrency == 4'
assert_jq "$OH_MY_OPENCODE" '.tmux.enabled == true'
assert_jq "$OH_MY_OPENCODE" '.websearch.provider == "exa"'
assert_jq "$OH_MY_OPENCODE" '.skills.sources | length == 1'
assert_jq "$OH_MY_OPENCODE" '.skills.sources[0].path == ".agents/skills"'
assert_jq "$OH_MY_OPENCODE" '.skills.sources[0].recursive == true'
assert_jq "$OH_MY_OPENCODE" '.experimental.truncate_all_tool_outputs == false'
assert_jq "$OH_MY_OPENCODE" '.experimental.aggressive_truncation == false'
assert_jq "$OH_MY_OPENCODE" '.experimental.auto_resume == false'
assert_jq "$OH_MY_OPENCODE" '.experimental.preemptive_compaction == false'
assert_jq "$OH_MY_OPENCODE" '.experimental.dynamic_context_pruning.enabled == true'
assert_jq "$OH_MY_OPENCODE" '.experimental.dynamic_context_pruning.notification == "detailed"'
assert_jq "$OH_MY_OPENCODE" '.experimental.dynamic_context_pruning.turn_protection.enabled == true'
assert_jq "$OH_MY_OPENCODE" '.experimental.dynamic_context_pruning.turn_protection.turns == 4'
assert_jq "$OH_MY_OPENCODE" '.experimental.dynamic_context_pruning.strategies.deduplication.enabled == true'
assert_jq "$OH_MY_OPENCODE" '.experimental.dynamic_context_pruning.strategies.supersede_writes.enabled == true'
assert_jq "$OH_MY_OPENCODE" '.experimental.dynamic_context_pruning.strategies.supersede_writes.aggressive == false'
assert_jq "$OH_MY_OPENCODE" '.experimental.dynamic_context_pruning.strategies.purge_errors.enabled == true'
assert_jq "$OH_MY_OPENCODE" '.experimental.dynamic_context_pruning.strategies.purge_errors.turns == 6'
assert_jq "$OH_MY_OPENCODE" '.experimental.task_system == true'
assert_jq "$OH_MY_OPENCODE" '.experimental.plugin_load_timeout_ms == 15000'
assert_jq "$OH_MY_OPENCODE" '.experimental.safe_hook_creation == true'

test -f "$ROOT/private_dot_config/opencode/commands/symlink_core.tmpl" || {
    echo "missing opencode commands/core symlink template" >&2
    exit 1
}

assert_file_contains "$ROOT/private_dot_config/opencode/commands/symlink_core.tmpl" ".agents/commands/core"

if [[ -f "$ROOT/private_dot_config/opencode/symlink_commands.tmpl" ]]; then
    echo "assertion failed: legacy commands root symlink template should not exist" >&2
    exit 1
fi

if [[ -d "$ROOT/private_dot_config/opencode/command" ]] &&
    find "$ROOT/private_dot_config/opencode/command" -type f -name '*.tmpl' | grep -q .; then
    echo "assertion failed: flat compatibility command aliases should not be managed" >&2
    find "$ROOT/private_dot_config/opencode/command" -type f -name '*.tmpl' >&2
    exit 1
fi

test -f "$ROOT/private_dot_config/opencode/symlink_skills.tmpl" || {
    echo "missing opencode global skills projection template" >&2
    exit 1
}

test -f "$ROOT/private_dot_config/opencode/AGENTS.md.tmpl" || {
    echo "missing opencode user-level AGENTS template" >&2
    exit 1
}

assert_file_contains "$ROOT/private_dot_config/opencode/AGENTS.md.tmpl" "## OpenSpec Execution Gate"
assert_file_contains "$ROOT/private_dot_config/opencode/AGENTS.md.tmpl" "## OpenCode Runtime Boundaries"
assert_file_contains "$ROOT/private_dot_config/opencode/AGENTS.md.tmpl" "## Command and Skill Sources"

opencode_manage_completion_block="$(awk '/^_opencode_manage\(\)/,/^}/' "$ROOT/dot_custom/functions.sh")"
if ! grep -Fq "'doctor:Run workflow diagnostics'" <<<"$opencode_manage_completion_block"; then
    echo "assertion failed: opencode completion is missing doctor subcommand" >&2
    echo "--- _opencode_manage block ---" >&2
    echo "$opencode_manage_completion_block" >&2
    exit 1
fi

claude_manage_completion_block="$(awk '/^_claude_manage\(\)/,/^}/' "$ROOT/dot_custom/functions.sh")"
if ! grep -Fq "'doctor:Run workflow diagnostics'" <<<"$claude_manage_completion_block"; then
    echo "assertion failed: claude completion is missing doctor subcommand" >&2
    echo "--- _claude_manage block ---" >&2
    echo "$claude_manage_completion_block" >&2
    exit 1
fi

codex_manage_completion_block="$(awk '/^_codex_manage\(\)/,/^}/' "$ROOT/dot_custom/functions.sh")"
if ! grep -Fq "'doctor:Run workflow diagnostics'" <<<"$codex_manage_completion_block"; then
    echo "assertion failed: codex completion is missing doctor subcommand" >&2
    echo "--- _codex_manage block ---" >&2
    echo "$codex_manage_completion_block" >&2
    exit 1
fi

echo "test_opencode_config_rendering: OK"
