#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

require_cmd() {
    command -v "$1" >/dev/null 2>&1
}

for c in bash chezmoi git jq; do
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
    if ! grep -Fq -- "$needle" "$file"; then
        echo "assertion failed: expected '$file' to contain: $needle" >&2
        echo "--- file: $file ---" >&2
        cat "$file" >&2
        exit 1
    fi
}

assert_file_not_contains() {
    local file="$1"
    local needle="$2"
    if grep -Fq -- "$needle" "$file"; then
        echo "assertion failed: expected '$file' to not contain: $needle" >&2
        echo "--- file: $file ---" >&2
        cat "$file" >&2
        exit 1
    fi
}

assert_ignored_path() {
    local path="$1"
    if ! git -C "$ROOT" check-ignore -q "$path"; then
        echo "assertion failed: expected path to be ignored: $path" >&2
        git -C "$ROOT" check-ignore -v "$path" >&2 || true
        exit 1
    fi
}

assert_not_ignored_path() {
    local path="$1"
    if git -C "$ROOT" check-ignore -q "$path"; then
        echo "assertion failed: expected path to NOT be ignored: $path" >&2
        git -C "$ROOT" check-ignore -v "$path" >&2 || true
        exit 1
    fi
}

render_opencode() {
    local output="$1"
    local override_data="${2:-}"
    if [[ -n "$override_data" ]]; then
        chezmoi execute-template \
            --source "$ROOT" \
            --override-data "$override_data" \
            <"$ROOT/private_dot_config/opencode/opencode.jsonc.tmpl" \
            >"$output"
        return 0
    fi

    chezmoi execute-template \
        --source "$ROOT" \
        <"$ROOT/private_dot_config/opencode/opencode.jsonc.tmpl" \
        >"$output"
}

render_oh_my_opencode() {
    local output="$1"
    cat "$ROOT/private_dot_config/opencode/oh-my-opencode.jsonc" >"$output"
}

OPENCODE_DEFAULT="$TMP_ROOT/opencode-default.jsonc"
OH_MY_OPENCODE="$TMP_ROOT/oh-my-opencode.jsonc"
OPENCODE_WITH_GOPASS="$TMP_ROOT/opencode-with-gopass.jsonc"

render_opencode "$OPENCODE_DEFAULT"
render_oh_my_opencode "$OH_MY_OPENCODE"

ACCOUNT_BIN="$TMP_ROOT/account-bin"
mkdir -p "$ACCOUNT_BIN"

cat >"$ACCOUNT_BIN/gopass" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cmd="${1:-}"
shift || true
case "$cmd" in
    list)
        target="${1:-}"
        [[ "$target" == "-f" ]] && target="${2:-}"
        if [[ "$target" == "opencode/harui/private/api_key" || "$target" == "opencode/deepseek/private/api_key" || "$target" == "opencode/openai/private/api_key" ]]; then
            exit 0
        fi
        exit 1
        ;;
    show)
        target="${1:-}"
        if [[ "$target" == "--password" || "$target" == "-o" ]]; then
            target="${2:-}"
        fi
        if [[ "$target" == "opencode/harui/private/api_key" ]]; then
            printf '%s' "stub-account-key"
            exit 0
        fi
        if [[ "$target" == "opencode/deepseek/private/api_key" ]]; then
            printf '%s' "stub-deepseek-key"
            exit 0
        fi
        if [[ "$target" == "opencode/openai/private/api_key" ]]; then
            printf '%s' "stub-openai-key"
            exit 0
        fi
        exit 1
        ;;
    *)
        exit 1
        ;;
esac
EOF
chmod +x "$ACCOUNT_BIN/gopass"

PATH="$ACCOUNT_BIN:$PATH" render_opencode "$OPENCODE_WITH_GOPASS"

assert_jq "$OPENCODE_DEFAULT" '.plugin == ["oh-my-opencode", "opencode-plugin-openspec"]'
assert_jq "$OPENCODE_DEFAULT" '.plugin | length == 2'
assert_jq "$OPENCODE_DEFAULT" '.theme == "dracula"'
assert_jq "$OPENCODE_DEFAULT" '.model == .small_model'
assert_jq "$OPENCODE_DEFAULT" '.command["doctor-all"].agent == "build"'
assert_jq "$OPENCODE_DEFAULT" '.command["doctor-all"].template | length > 0'
assert_jq "$OPENCODE_DEFAULT" '.command["doctor-all"].template | contains("opencode mcp list")'
assert_jq "$OPENCODE_DEFAULT" '.command["doctor-all"].template | contains("mcp.context7")'
assert_jq "$OPENCODE_DEFAULT" '.command["doctor-all"].template | contains("mcp.serena")'
assert_jq "$OPENCODE_DEFAULT" '.command["spec-verify"].description | length > 0'
assert_jq "$OPENCODE_DEFAULT" '.default_agent == "build"'
assert_jq "$OPENCODE_DEFAULT" '.agent.build.model == .model'
assert_jq "$OPENCODE_DEFAULT" '.agent.build.variant == "xhigh"'
assert_jq "$OPENCODE_DEFAULT" '.agent.build.options.store == false'
assert_jq "$OPENCODE_DEFAULT" '.agent.plan.variant == "xhigh"'
assert_jq "$OPENCODE_DEFAULT" '.agent.plan.options.store == false'
assert_jq "$OPENCODE_DEFAULT" '.instructions | index("AGENTS.md") != null'
assert_jq "$OPENCODE_DEFAULT" '.watcher.ignore | index("**/.git/**") != null'
assert_jq "$OPENCODE_DEFAULT" '.lsp["rust-analyzer"].command == ["rust-analyzer"]'
assert_jq "$OPENCODE_DEFAULT" '.lsp["lua-language-server"].extensions | index(".lua") != null'
assert_jq "$OPENCODE_DEFAULT" '.lsp["typescript-language-server"].disabled == true'
assert_jq "$OPENCODE_DEFAULT" '.formatter["ruff-format"].command == ["ruff","format"]'
assert_jq "$OPENCODE_DEFAULT" '.formatter.rustfmt.extensions == [".rs"]'
assert_jq "$OPENCODE_DEFAULT" '.formatter.prettier.disabled == true'
assert_jq "$OPENCODE_DEFAULT" '.compaction.auto == true and .compaction.prune == true and .compaction.reserved == 16384'
assert_jq "$OPENCODE_DEFAULT" '.share == "manual"'
assert_jq "$OPENCODE_DEFAULT" '.autoupdate == "notify"'
assert_jq "$OPENCODE_DEFAULT" '.tui.diff_style == "auto"'
assert_jq "$OPENCODE_DEFAULT" '.tui.scroll_acceleration.enabled == true'
assert_jq "$OPENCODE_DEFAULT" '(.provider | has("openai_default")) == false'
assert_jq "$OPENCODE_DEFAULT" '(.provider | has("openai_work")) == false'
assert_jq "$OPENCODE_DEFAULT" '(.provider | has("openai_private")) == false'
assert_jq "$OPENCODE_DEFAULT" '.provider["deepseek@private"].env == ["DEEPSEEK_API_KEY"]'
assert_jq "$OPENCODE_DEFAULT" '.provider["deepseek@private"].models["deepseek-chat"].options.store == false'
assert_jq "$OPENCODE_DEFAULT" '(.provider["deepseek@private"].models["deepseek-chat"].variants | has("xhigh")) == true'
assert_jq "$OPENCODE_DEFAULT" '.provider["harui@private"].env == ["HARUI_API_KEY"]'
assert_jq "$OPENCODE_DEFAULT" '.provider["harui@private"].npm == "@ai-sdk/openai"'
assert_jq "$OPENCODE_DEFAULT" '.provider["harui@private"].options.baseURL == "https://codex.harui.edu.kg/v1"'
assert_jq "$OPENCODE_DEFAULT" '.provider["harui@private"].models["gpt-5.3-codex"].options.store == false'
assert_jq "$OPENCODE_DEFAULT" '.provider["qwen@private"].env == ["DASHSCOPE_API_KEY"]'
assert_jq "$OPENCODE_DEFAULT" '(.provider["qwen@private"].models["qwen3-max"].variants | has("medium")) == true'
assert_jq "$OPENCODE_DEFAULT" '.provider["kimi@private"].options.baseURL == "https://api.moonshot.ai/v1"'
assert_jq "$OPENCODE_DEFAULT" '.skills.paths | index(".agents/skills") != null'
assert_jq "$OPENCODE_DEFAULT" '.skills.paths | length == 1'
assert_jq "$OPENCODE_DEFAULT" '.mcp.tavily.type == "local"'
assert_jq "$OPENCODE_DEFAULT" '.mcp.tavily.enabled == true'
assert_jq "$OPENCODE_DEFAULT" '.mcp.tavily.command[0] | endswith("/.local/bin/mcp-tavily")'
assert_jq "$OPENCODE_DEFAULT" '.mcp.context7.type == "local"'
assert_jq "$OPENCODE_DEFAULT" '.mcp.context7.enabled == true'
assert_jq "$OPENCODE_DEFAULT" '.mcp.context7.command[0] | endswith("/.local/bin/mcp-context7")'
assert_jq "$OPENCODE_DEFAULT" '.mcp.serena.type == "local"'
assert_jq "$OPENCODE_DEFAULT" '.mcp.serena.enabled == true'
assert_jq "$OPENCODE_DEFAULT" '.mcp.serena.command | index("git+https://github.com/oraios/serena") != null'
assert_jq "$OPENCODE_DEFAULT" '.mcp.serena.command | index("--context") != null'
assert_jq "$OPENCODE_DEFAULT" '.mcp.serena.command | index("ide") != null'
assert_jq "$OPENCODE_DEFAULT" '.mcp.serena.command | index("--project") != null'
assert_jq "$OPENCODE_DEFAULT" '.mcp.serena.command | index(".") != null'
assert_jq "$OPENCODE_DEFAULT" '.mcp.serena.command | index("--enable-web-dashboard") != null'
assert_jq "$OPENCODE_DEFAULT" '.mcp.gitmcp.type == "remote"'
assert_jq "$OPENCODE_DEFAULT" '.mcp.gitmcp.url == "https://gitmcp.io/docs"'
assert_jq "$OPENCODE_DEFAULT" '.mcp.gitmcp.oauth == false'
assert_jq "$OPENCODE_DEFAULT" '.mcp.gitmcp.enabled == true'
assert_jq "$OPENCODE_WITH_GOPASS" '.provider["harui@private"].options.apiKey == "stub-account-key"'
assert_jq "$OPENCODE_WITH_GOPASS" '.provider["deepseek@private"].options.apiKey == "stub-deepseek-key"'
assert_jq "$OPENCODE_WITH_GOPASS" '.provider["openai@private"].options.apiKey == "stub-openai-key"'

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
assert_jq "$OH_MY_OPENCODE" '.disabled_hooks | index("startup-toast") != null'
assert_jq "$OH_MY_OPENCODE" '.disabled_mcps == []'
assert_jq "$OH_MY_OPENCODE" '.disabled_agents | index("sisyphus") != null'
assert_jq "$OH_MY_OPENCODE" '.disabled_skills == []'
assert_jq "$OH_MY_OPENCODE" '.disabled_commands == []'
assert_jq "$OH_MY_OPENCODE" 'has("disabled_tools") | not'
assert_jq "$OH_MY_OPENCODE" '.comment_checker.custom_prompt | length > 0'
assert_jq "$OH_MY_OPENCODE" '.ralph_loop.enabled == false'
assert_jq "$OH_MY_OPENCODE" '.sisyphus_agent.disabled == true'
assert_jq "$OH_MY_OPENCODE" '.sisyphus.tasks.claude_code_compat == false'
assert_jq "$OH_MY_OPENCODE" '.agents.build.category == "deep"'
assert_jq "$OH_MY_OPENCODE" '.agents.plan.category == "ultrabrain"'
assert_jq "$OH_MY_OPENCODE" '.agents.atlas.category == "ultrabrain"'
assert_jq "$OH_MY_OPENCODE" '(.agents | has("sisyphus-junior")) == false'
assert_jq "$OH_MY_OPENCODE" '.agents.prometheus.category == "unspecified-high"'
assert_jq "$OH_MY_OPENCODE" '.categories.ultrabrain.reasoningEffort == "xhigh"'
assert_jq "$OH_MY_OPENCODE" '.categories.deep.variant == "xhigh"'
assert_jq "$OH_MY_OPENCODE" '.categories.deep.reasoningEffort == "xhigh"'
assert_jq "$OH_MY_OPENCODE" '.categories.quick.textVerbosity == "low"'
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

theme_file="$ROOT/private_dot_config/opencode/themes/dracula.json"
test -f "$theme_file" || {
    echo "missing managed opencode theme asset: $theme_file" >&2
    exit 1
}

if ! jq -e . "$theme_file" >/dev/null 2>&1; then
    echo "assertion failed: opencode theme file is not valid JSON: $theme_file" >&2
    exit 1
fi

if awk '/^_opencode_manage\(\)/,/^}/' "$ROOT/dot_custom/functions.sh" | grep -q .; then
    echo "assertion failed: opencode manage completion should not be defined" >&2
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

assert_file_not_contains "$ROOT/dot_local/bin/executable_codex-manage.tmpl" 'Search and MCP readiness:'
assert_file_not_contains "$ROOT/dot_local/bin/executable_codex-manage.tmpl" 'check_mcp_server "tavily" "Tavily"'
assert_file_not_contains "$ROOT/dot_local/bin/executable_codex-manage.tmpl" 'tri-MCP readiness unknown'

assert_file_contains "$ROOT/dot_codex/config.toml.tmpl" '[mcp_servers.context7]'
assert_file_contains "$ROOT/dot_codex/config.toml.tmpl" '[mcp_servers.serena]'
assert_file_contains "$ROOT/dot_codex/config.toml.tmpl" 'git+https://github.com/oraios/serena'
assert_file_contains "$ROOT/dot_codex/config.toml.tmpl" '"--context", "codex"'
assert_file_contains "$ROOT/dot_codex/config.toml.tmpl" 'startup_timeout_sec = 30'
assert_file_contains "$ROOT/dot_codex/config.toml.tmpl" '[mcp_servers.gitmcp]'
assert_file_contains "$ROOT/dot_codex/config.toml.tmpl" 'url = "https://gitmcp.io/docs"'

assert_file_contains "$ROOT/.chezmoiscripts/run_after_11_sync-claude-mcp.sh.tmpl" 'ensure_user_mcp_json "context7"'
assert_file_contains "$ROOT/.chezmoiscripts/run_after_11_sync-claude-mcp.sh.tmpl" '/.local/bin/mcp-context7'
assert_file_contains "$ROOT/.chezmoiscripts/run_after_11_sync-claude-mcp.sh.tmpl" 'ensure_user_mcp_json "serena"'
assert_file_contains "$ROOT/.chezmoiscripts/run_after_11_sync-claude-mcp.sh.tmpl" '--context","ide-assistant"'
assert_file_contains "$ROOT/.chezmoiscripts/run_after_11_sync-claude-mcp.sh.tmpl" 'ensure_user_mcp_http "gitmcp" "https://gitmcp.io/docs"'

test -f "$ROOT/dot_local/bin/executable_mcp-context7.tmpl" || {
    echo "missing managed context7 wrapper template" >&2
    exit 1
}
assert_file_contains "$ROOT/dot_local/bin/executable_mcp-context7.tmpl" 'CONTEXT7_API_KEY'
assert_file_contains "$ROOT/dot_local/bin/executable_mcp-context7.tmpl" 'context7/api_key'
assert_file_contains "$ROOT/dot_local/bin/executable_mcp-context7.tmpl" '@upstash/context7-mcp@2.1.1'
assert_file_not_contains "$ROOT/dot_local/bin/executable_claude-manage.tmpl" 'Search and MCP readiness:'
assert_file_not_contains "$ROOT/dot_local/bin/executable_claude-manage.tmpl" 'check_user_mcp "context7" "Context7"'
assert_file_not_contains "$ROOT/dot_local/bin/executable_claude-manage.tmpl" 'check_user_mcp "serena" "Serena"'
assert_file_contains "$ROOT/private_dot_config/mise/config.toml.tmpl" 'node = "lts"'
assert_file_contains "$ROOT/private_dot_config/mise/config.toml.tmpl" 'uv = "latest"'

# --- Task 6.1: spec-verify syntax ---
assert_file_contains "$ROOT/private_dot_config/opencode/opencode.jsonc.tmpl" 'openspec validate <change-name>'

# --- Task 6.2: C1-C4 routing anchors ---
for f in "$ROOT/dot_claude/CLAUDE.md.tmpl" "$ROOT/dot_codex/AGENTS.md.tmpl" "$ROOT/private_dot_config/opencode/AGENTS.md.tmpl"; do
    assert_file_not_contains "$f" 'C0/C1/C2/C3'
    assert_file_not_contains "$f" 'Category: C0 | C1 | C2 | C3'
    assert_file_not_contains "$f" 'Read-only request -> `C0`'
    assert_file_contains "$f" 'C1'
    assert_file_contains "$f" 'C2'
    assert_file_contains "$f" 'C3'
    assert_file_contains "$f" 'C4'
    assert_file_contains "$f" 'DiscoveryScore'
    assert_file_contains "$f" 'ControlScore'
    assert_file_contains "$f" 'Intake Card'
    assert_file_contains "$f" 'If category is `C3` or `C4`'
    assert_file_contains "$f" 'Else `I = 2` and `R = 2` -> `C4`'
done

# --- Task 6.3: Spec-Kit bootstrap anchors ---
for f in "$ROOT/dot_claude/CLAUDE.md.tmpl" "$ROOT/dot_codex/AGENTS.md.tmpl" "$ROOT/private_dot_config/opencode/AGENTS.md.tmpl"; do
    assert_file_contains "$f" 'specify init --here --ai claude --script sh'
    assert_file_contains "$f" 'specify init --here --ai codex --script sh'
    assert_file_contains "$f" 'specify init --here --ai opencode --script sh'
done
assert_file_contains "$ROOT/dot_codex/AGENTS.md.tmpl" 'export CODEX_HOME="$PWD/.codex"'
assert_file_contains "$ROOT/dot_claude/CLAUDE.md.tmpl" 'export CODEX_HOME="$PWD/.codex"'
assert_file_contains "$ROOT/private_dot_config/opencode/AGENTS.md.tmpl" 'export CODEX_HOME="$PWD/.codex"'

# --- Task 6.4: AGENTS opsx syntax consistency ---
# Codex AGENTS: hyphen form only (except disambiguation note)
assert_file_contains "$ROOT/dot_codex/AGENTS.md.tmpl" '/opsx-new'
assert_file_contains "$ROOT/dot_codex/AGENTS.md.tmpl" '/opsx-archive'
assert_file_contains "$ROOT/dot_codex/AGENTS.md.tmpl" 'Cross-tool syntax note'
# OpenCode AGENTS: hyphen form
assert_file_contains "$ROOT/private_dot_config/opencode/AGENTS.md.tmpl" '/opsx-new'
assert_file_contains "$ROOT/private_dot_config/opencode/AGENTS.md.tmpl" '/opsx-archive'
assert_file_contains "$ROOT/private_dot_config/opencode/AGENTS.md.tmpl" 'Cross-tool syntax note'
# Claude AGENTS: colon form
assert_file_contains "$ROOT/dot_claude/CLAUDE.md.tmpl" '/opsx:new'
assert_file_contains "$ROOT/dot_claude/CLAUDE.md.tmpl" '/opsx:archive'

# --- Task 6.5: Guardrails references resolve (inline) ---
assert_file_contains "$ROOT/dot_codex/AGENTS.md.tmpl" '## Guardrails'
assert_file_contains "$ROOT/private_dot_config/opencode/AGENTS.md.tmpl" '## Guardrails'

# --- Task 6.6: Guardrails machine anchors ---
for f in "$ROOT/dot_codex/AGENTS.md.tmpl" "$ROOT/private_dot_config/opencode/AGENTS.md.tmpl"; do
    assert_file_contains "$f" 'Authentication'
    assert_file_contains "$f" 'Authorization'
    assert_file_contains "$f" 'Financial'
    assert_file_contains "$f" 'Security'
    assert_file_contains "$f" 'Data Schema'
    assert_file_contains "$f" 'External APIs'
    assert_file_contains "$f" 'Irreversible Ops'
    assert_file_contains "$f" 'PII/Privacy'
    assert_file_contains "$f" 'Post-change report required'
    assert_file_contains "$f" 'explicit confirmation'
done

# --- Task 6.7: Sisyphus planner residue absent ---
assert_jq "$OH_MY_OPENCODE" '.sisyphus_agent.disabled == true'
assert_jq "$OH_MY_OPENCODE" '(.sisyphus_agent | has("planner_enabled")) | not'
assert_jq "$OH_MY_OPENCODE" '(.sisyphus_agent | has("replace_plan")) | not'
assert_jq "$OH_MY_OPENCODE" '(.sisyphus_agent | has("default_builder_enabled")) | not'

# --- Task 6.8: OpenSpec versioning posture explicit ---
# Long-lived OpenSpec traces are tracked in git and must not be ignored.
if grep -Eq '^openspec/?$|^openspec/' "$ROOT/.gitignore"; then
    echo "assertion failed: .gitignore should not ignore openspec/" >&2
    grep -En '^openspec/?$|^openspec/' "$ROOT/.gitignore" >&2 || true
    exit 1
fi
assert_not_ignored_path "openspec/specs/.probe"
assert_not_ignored_path "openspec/changes/archive/.probe"
assert_file_contains "$ROOT/dot_claude/CLAUDE.md.tmpl" 'tracks all OpenSpec artifacts in git'
assert_file_contains "$ROOT/dot_codex/AGENTS.md.tmpl" 'tracks all OpenSpec artifacts in git'
assert_file_contains "$ROOT/private_dot_config/opencode/AGENTS.md.tmpl" 'OpenSpec Version Control'
assert_file_contains "$ROOT/private_dot_config/opencode/AGENTS.md.tmpl" 'Track all OpenSpec artifacts in git'
assert_file_contains "$ROOT/.github/workflows/openspec-trace-gate.yml" '.github/scripts/check_openspec_trace_gate.sh'
assert_file_contains "$ROOT/.github/scripts/check_openspec_trace_gate.sh" 'unexpected files under openspec/changes'
assert_file_contains "$ROOT/.github/scripts/check_openspec_trace_gate.sh" 'archive these changes before merge'

# --- Task 8.4: Tavily-first anchor wording ---
assert_file_contains "$ROOT/dot_codex/AGENTS.md.tmpl" 'Tavily MCP'
assert_file_contains "$ROOT/private_dot_config/opencode/AGENTS.md.tmpl" 'Tavily MCP'
assert_file_contains "$ROOT/dot_claude/CLAUDE.md.tmpl" 'Tavily MCP'
assert_file_contains "$ROOT/dot_codex/AGENTS.md.tmpl" 'Context7 MCP'
assert_file_contains "$ROOT/dot_codex/AGENTS.md.tmpl" 'Serena MCP'
assert_file_contains "$ROOT/private_dot_config/opencode/AGENTS.md.tmpl" 'Context7 MCP'
assert_file_contains "$ROOT/private_dot_config/opencode/AGENTS.md.tmpl" 'Serena MCP'
assert_file_contains "$ROOT/dot_claude/CLAUDE.md.tmpl" 'Context7 MCP'
assert_file_contains "$ROOT/dot_claude/CLAUDE.md.tmpl" 'Serena MCP'

# --- Task 9.4: Research subagent model routes explicit ---
assert_jq "$OH_MY_OPENCODE" '.agents.librarian.category == "deep"'
assert_jq "$OH_MY_OPENCODE" '.agents.explore.category == "deep"'
assert_jq "$OH_MY_OPENCODE" '.agents.oracle.category == "ultrabrain"'
assert_jq "$OH_MY_OPENCODE" '.agents.librarian.model == "openai/gpt-5.3-codex"'
assert_jq "$OH_MY_OPENCODE" '.agents.explore.model == "openai/gpt-5.3-codex"'
assert_jq "$OH_MY_OPENCODE" '.agents.oracle.model == "openai/gpt-5.3-codex"'

# --- Task 2.3: Runtime boundary wording machine-checkable ---
assert_file_contains "$ROOT/dot_codex/AGENTS.md.tmpl" 'limited runtime hook capability'
assert_file_contains "$ROOT/private_dot_config/opencode/AGENTS.md.tmpl" 'OPENCODE_DISABLE_CLAUDE_CODE=1'
assert_file_contains "$ROOT/private_dot_config/opencode/AGENTS.md.tmpl" 'AGENTS -> CLAUDE fallback'

# --- Task 9.2/9.3: Subagent execution diagnostics ---
assert_file_contains "$ROOT/private_dot_config/opencode/AGENTS.md.tmpl" 'background-first'
assert_file_contains "$ROOT/private_dot_config/opencode/AGENTS.md.tmpl" 'No assistant or tool response found'

# --- Task 3.4: Command-surface compatibility ---
assert_file_contains "$ROOT/private_dot_config/opencode/AGENTS.md.tmpl" '.opencode/command/'
assert_file_contains "$ROOT/private_dot_config/opencode/AGENTS.md.tmpl" 'routing/planning/context: `route`, `plan`, `context`'

# --- Task 4.1/4.3: Spec-Kit install + diagnostics anchors ---
assert_file_contains "$ROOT/private_dot_config/mise/config.toml.tmpl" '"pipx:specify-cli"'
assert_file_contains "$ROOT/dot_local/bin/executable_codex-manage.tmpl" 'specify check'
assert_file_contains "$ROOT/dot_local/bin/executable_claude-manage.tmpl" 'specify check'
assert_file_contains "$ROOT/dot_local/bin/executable_codex-manage.tmpl" 'specify check passed'
assert_file_contains "$ROOT/dot_local/bin/executable_claude-manage.tmpl" 'specify check passed'

# --- worktree-first-ai-workflow: baseline ignore rule ---
assert_file_contains "$ROOT/.gitignore" '.worktrees/'
assert_ignored_path ".worktrees/.probe"

# --- worktree-first-ai-workflow: prompt visibility (scheme 1) ---
assert_file_contains "$ROOT/private_dot_config/starship.toml" '[custom.worktree]'
assert_file_contains "$ROOT/private_dot_config/starship.toml" 'right_format'
assert_file_contains "$ROOT/private_dot_config/starship.toml" '.worktrees/'
assert_file_contains "$ROOT/private_dot_config/starship.toml" 'wt:'

# --- worktree-first-ai-workflow: helper anchors ---
assert_file_contains "$ROOT/dot_custom/functions.sh" 'wt-new()'
assert_file_contains "$ROOT/dot_custom/functions.sh" 'wt-go()'
assert_file_contains "$ROOT/dot_custom/functions.sh" 'wt-ls()'
assert_file_contains "$ROOT/dot_custom/functions.sh" 'wt-rm()'
assert_file_contains "$ROOT/dot_custom/functions.sh" 'wt-prune()'
assert_file_contains "$ROOT/dot_custom/functions.sh" 'Path collision:'
assert_file_contains "$ROOT/dot_custom/functions.sh" 'Nested worktree creation is not supported.'

# --- worktree-first-ai-workflow: policy anchors ---
assert_file_contains "$ROOT/dot_claude/CLAUDE.md.tmpl" 'Worktree Gate (C2+)'
assert_file_contains "$ROOT/dot_codex/AGENTS.md.tmpl" 'Worktree Gate (C2+)'
assert_file_contains "$ROOT/private_dot_config/opencode/AGENTS.md.tmpl" 'Worktree Gate (C2+)'

# --- worktree-first-ai-workflow: cross-tool shared command projection ---
test -f "$ROOT/dot_agents/commands/core/route.md" || {
    echo "missing core route command" >&2
    exit 1
}
assert_file_contains "$ROOT/dot_agents/commands/core/worktree.md" 'wt-new'
assert_file_contains "$ROOT/dot_agents/commands/core/worktree.md" 'one-task-one-branch-one-worktree'
assert_file_contains "$ROOT/dot_agents/commands/core/plan.md" '/opsx:new <change-name>'
assert_file_contains "$ROOT/dot_agents/commands/core/plan.md" '/opsx-new <change-name>'
assert_file_contains "$ROOT/dot_agents/commands/core/plan.md" 'openspec init --tools <tool>'
assert_file_contains "$ROOT/dot_agents/commands/core/test.md" '/opsx:verify'
assert_file_contains "$ROOT/dot_agents/commands/core/test.md" '/opsx-verify'
assert_file_contains "$ROOT/dot_agents/commands/core/context.md" 'If category is `C4`, suggest Spec-Kit bootstrap first'
assert_file_contains "$ROOT/dot_codex/prompts/symlink_core-worktree.md.tmpl" '.agents/commands/core/worktree.md'
assert_file_contains "$ROOT/dot_agents/commands/core/route.md" '## Intake Card'
assert_file_contains "$ROOT/dot_codex/prompts/symlink_core-route.md.tmpl" '.agents/commands/core/route.md'

# --- serena-context7-mcp-integration: tri-MCP routing anchors ---
assert_file_contains "$ROOT/dot_agents/commands/core/context.md" 'Tri-MCP Routing Policy'
assert_file_contains "$ROOT/dot_agents/commands/core/context.md" 'Library/framework/API docs'
assert_file_contains "$ROOT/dot_agents/commands/core/context.md" 'Context7'
assert_file_contains "$ROOT/dot_agents/commands/core/context.md" 'Tavily'
assert_file_contains "$ROOT/dot_agents/commands/core/context.md" 'Serena'
assert_file_contains "$ROOT/README.md" 'Task -> MCP Routing'
assert_file_contains "$ROOT/README.md" 'mcp-context7'
assert_file_contains "$ROOT/README.zh-CN.md" '任务 -> MCP 路由'
assert_file_contains "$ROOT/README.zh-CN.md" 'mcp-context7'
assert_file_contains "$ROOT/README.ja.md" 'タスク -> MCP ルーティング'
assert_file_contains "$ROOT/README.ja.md" 'mcp-context7'

echo "test_opencode_config_rendering: OK"
