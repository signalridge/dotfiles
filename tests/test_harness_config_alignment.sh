#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
for command in bash chezmoi jq python3; do
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
jq -e '.["skipDangerousModePermissionPrompt"] == false and
       (.["permissions"]["deny"] | index("Bash(git worktree:*)")) != null' \
    "$tmp_root/claude.json" >/dev/null

render dot_codex/modify_config.toml.tmpl >"$tmp_root/codex.sh"
bash -n "$tmp_root/codex.sh"
printf '' | bash "$tmp_root/codex.sh" >"$tmp_root/codex.toml"
python3 - "$tmp_root/codex.toml" <<'PY'
import sys
import tomllib

with open(sys.argv[1], "rb") as handle:
    config = tomllib.load(handle)
assert config["sandbox_mode"] == "workspace-write"
assert config["sandbox_workspace_write"]["network_access"] is True
assert config["sandbox_workspace_write"]["exclude_slash_tmp"] is True
assert config["shell_environment_policy"]["ignore_default_excludes"] is False
assert "AGENTS.md" in config["project_doc_fallback_filenames"]
PY

render dot_cursor/modify_cli-config.json.tmpl >"$tmp_root/cursor.sh"
bash -n "$tmp_root/cursor.sh"
printf '{}' | bash "$tmp_root/cursor.sh" >"$tmp_root/cursor.json"
jq -e '(.approvalMode == "allowlist") and
       ((.permissions.allow | index("Mcp(*:*)")) == null)' \
    "$tmp_root/cursor.json" >/dev/null

render dot_gemini/antigravity-cli/modify_private_settings.json.tmpl >"$tmp_root/antigravity.sh"
bash -n "$tmp_root/antigravity.sh"
printf '{}' | bash "$tmp_root/antigravity.sh" >"$tmp_root/antigravity.json"
jq -e '.toolPermission == "request-review" and
       .allowNonWorkspaceAccess == false and
       .enableTerminalSandbox == true' \
    "$tmp_root/antigravity.json" >/dev/null

render dot_kimi-code/modify_config.toml.tmpl >"$tmp_root/kimi.sh"
bash -n "$tmp_root/kimi.sh"
printf '' | bash "$tmp_root/kimi.sh" >"$tmp_root/kimi.toml"
python3 - "$tmp_root/kimi.toml" <<'PY'
import sys
import tomllib

with open(sys.argv[1], "rb") as handle:
    config = tomllib.load(handle)
assert config["default_permission_mode"] == "manual"
assert config["default_plan_mode"] is False
PY

render dot_pi/agent/subagents.json.tmpl | jq -e '
  .defaultMaxTurns == 80 and
  .defaultMaxToolCalls == 300 and
  .graceTurns == 5 and
  .fallbackSubagent == "none" and
  .disableDefaultAgents == true
' >/dev/null
jq -e . "$ROOT/dot_pi/agent/extensions/pi-permission-system/config.json" >/dev/null

[[ ! -e "$ROOT/dot_pi/agent/agents/Plan.md" ]]
! rg -n -i -S 'pi-plan-mode|display_name: Plan|agents/Plan|core-plan' \
    "$ROOT/dot_pi" "$ROOT/dot_codex" "$ROOT/.chezmoidata/pi.yaml"

for path in "$ROOT"/dot_pi/agent/agents/*.md; do
    ! rg -q 'pi-plan-mode' "$path"
done

core_links=()
while IFS= read -r path; do
    core_links+=("$path")
done < <(fd --type f --max-depth 1 'symlink_core-.*\.tmpl$' "$ROOT/dot_codex/prompts" | sort)
[[ "${#core_links[@]}" -eq 1 ]]
[[ "$(basename "${core_links[0]}")" == "symlink_core-commit.md.tmpl" ]]

echo "test_harness_config_alignment: OK"
