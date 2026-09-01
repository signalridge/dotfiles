#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
for command in bash chezmoi jq python3 grep; do
    command -v "$command" >/dev/null 2>&1 || {
        echo "SKIP: missing dependency: $command"
        exit 0
    }
done

tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/harness-config-test.XXXXXX")"
trap 'rm -rf "$tmp_root"' EXIT

render() {
    chezmoi execute-template --source "$ROOT" --file "$ROOT/$1"
}

render dot_claude/settings.json.tmpl >"$tmp_root/claude.json"
jq -e '.["skipDangerousModePermissionPrompt"] == true and
       .permissions.defaultMode == "bypassPermissions"' \
    "$tmp_root/claude.json" >/dev/null

# The chezmoi git worktree/branch guard is cwd-scoped, so it lives in the PreToolUse hook
# and not in the static deny list: a deny entry cannot say "only inside the
# chezmoi source tree", and the copy that tried blocked branch creation in every
# unrelated repository. Assert the hook is wired, then assert what it decides.
jq -e '[.hooks.PreToolUse[] | select(.matcher == "Bash") | .hooks[].command]
       | any(test("block-git-rewrites\\.sh$"))' \
    "$tmp_root/claude.json" >/dev/null

guard="$ROOT/dot_claude/hooks/executable_block-git-rewrites.sh"
guard_home="$tmp_root/guard-home"
guard_source="$guard_home/.local/share/chezmoi"

# The hook's decision for <command> in <cwd>, empty when it stays silent.
guard_decision() {
    jq -n --arg command "$1" --arg cwd "$2" \
        '{tool_name: "Bash", tool_input: {command: $command}, cwd: $cwd}' |
        HOME="$guard_home" bash "$guard" | jq -r '.decision // ""'
}

# Inside the chezmoi source tree, everything that can move HEAD is refused.
for blocked in \
    "git worktree add ../wt-x" \
    "git switch -c feature" \
    "git checkout -b feature" \
    "git checkout main"; do
    [[ "$(guard_decision "$blocked" "$guard_source")" == "block" ]]
    [[ "$(guard_decision "$blocked" "$guard_source/dot_pi")" == "block" ]]
done

# Restoring a file never leaves the branch, so it stays allowed.
[[ -z "$(guard_decision "git checkout -- README.md" "$guard_source")" ]]
[[ -z "$(guard_decision "git status" "$guard_source")" ]]

# Outside the source tree the rule does not apply at all.
for allowed in \
    "git worktree add ../wt-x" \
    "git switch -c feature" \
    "git checkout -b feature" \
    "git checkout main"; do
    [[ -z "$(guard_decision "$allowed" "$guard_home/src/other-repo")" ]]
done

render dot_codex/modify_config.toml.tmpl >"$tmp_root/codex.sh"
bash -n "$tmp_root/codex.sh"
printf '' | bash "$tmp_root/codex.sh" >"$tmp_root/codex.toml"
python3 - "$tmp_root/codex.toml" <<'PY'
import sys
import tomllib

with open(sys.argv[1], "rb") as handle:
    config = tomllib.load(handle)
assert config["approval_policy"] == "never"
assert config["sandbox_mode"] == "danger-full-access"
assert config["sandbox_workspace_write"]["network_access"] is True
assert config["sandbox_workspace_write"]["exclude_slash_tmp"] is False
assert config["shell_environment_policy"]["ignore_default_excludes"] is True
assert "AGENTS.md" in config["project_doc_fallback_filenames"]
PY

render dot_cursor/modify_cli-config.json >"$tmp_root/cursor.sh"
bash -n "$tmp_root/cursor.sh"
printf '{}' | bash "$tmp_root/cursor.sh" >"$tmp_root/cursor.json"
jq -e '(.approvalMode == "unrestricted") and
       ((.permissions.allow | index("Mcp(*:*)")) != null) and
       (.permissions.deny == [])' \
    "$tmp_root/cursor.json" >/dev/null

render dot_gemini/antigravity-cli/modify_private_settings.json.tmpl >"$tmp_root/antigravity.sh"
bash -n "$tmp_root/antigravity.sh"
printf '{}' | bash "$tmp_root/antigravity.sh" >"$tmp_root/antigravity.json"
jq -e '.toolPermission == "always-proceed" and
       .allowNonWorkspaceAccess == true and
       .enableTerminalSandbox == false' \
    "$tmp_root/antigravity.json" >/dev/null

render dot_kimi-code/modify_config.toml >"$tmp_root/kimi.sh"
bash -n "$tmp_root/kimi.sh"
printf '' | bash "$tmp_root/kimi.sh" >"$tmp_root/kimi.toml"
python3 - "$tmp_root/kimi.toml" <<'PY'
import sys
import tomllib

with open(sys.argv[1], "rb") as handle:
    config = tomllib.load(handle)
assert config["default_permission_mode"] == "yolo"
assert config["default_plan_mode"] is False
PY

render dot_pi/agent/subagents.json.tmpl | jq -e '
  .maxConcurrent == 40 and
  .defaultMaxTurns == 640 and
  .defaultMaxToolCalls == 1024 and
  .defaultMaxTokens == 3000000 and
  .graceTurns == 8 and
  .fallbackSubagent == "none" and
  .disableDefaultAgents == true
' >/dev/null
jq -e '.permission["*"] == "allow" and
       .permission.bash["*"] == "allow" and
       .permission.mcp["*"] == "allow" and
       .permission.external_directory["*"] == "allow"' \
    "$ROOT/dot_pi/agent/extensions/pi-permission-system/config.json" >/dev/null

[[ ! -e "$ROOT/dot_pi/agent/agents/Plan.md" ]]
if grep -R -E -n 'pi-plan-mode|display_name: Plan|agents/Plan|core-plan' \
    "$ROOT/dot_pi" "$ROOT/dot_codex" "$ROOT/.chezmoidata/pi.yaml"; then
    exit 1
fi

for path in "$ROOT"/dot_pi/agent/agents/*.md; do
    ! grep -q 'pi-plan-mode' "$path"
done

core_links=()
for path in "$ROOT"/dot_codex/prompts/symlink_core-*.tmpl; do
    [ -f "$path" ] || continue
    core_links+=("$path")
done
[[ "${#core_links[@]}" -eq 1 ]]
[[ "$(basename "${core_links[0]}")" == "symlink_core-commit.md.tmpl" ]]

echo "test_harness_config_alignment: OK"
