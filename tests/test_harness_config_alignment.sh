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

# Claude Code settings are a modify_ script, not a full-file template: the CLI
# rewrites ~/.claude/settings.json at runtime (`/model`, `/effort`, `/config`,
# `claude plugin install`) and so do run_after_11 and run_after_14. Exercise
# both branches -- fresh machine, and merge over an existing document.
render dot_claude/modify_settings.json.tmpl >"$tmp_root/claude.sh"
bash -n "$tmp_root/claude.sh"
printf '' | bash "$tmp_root/claude.sh" >"$tmp_root/claude.json"
jq -e '.["skipDangerousModePermissionPrompt"] == true and
       .permissions.defaultMode == "bypassPermissions" and
       .alwaysThinkingEnabled == true and
       (.env.ENABLE_TOOL_SEARCH == "auto:15") and
       (.effortLevel | type) == "string"' \
    "$tmp_root/claude.json" >/dev/null

# The whole point of the conversion. A key the CLI owns must survive the merge,
# a seeded default must yield to the value already on disk, and a managed key
# must still win. Nothing about the previous full-file template could pass this.
printf '%s' '{"model":"claude-opus-5[1m]","effortLevel":"max","outputStyle":"x",
              "enabledPlugins":{"user-added@somewhere":true},
              "permissions":{"defaultMode":"default","deny":["Bash(stale *)"]}}' |
    bash "$tmp_root/claude.sh" >"$tmp_root/claude-merged.json"
jq -e '.model == "claude-opus-5[1m]" and
       .outputStyle == "x" and
       .effortLevel == "max" and
       .enabledPlugins["user-added@somewhere"] == true and
       .enabledPlugins["slack@claude-plugins-official"] == true and
       .permissions.defaultMode == "bypassPermissions" and
       (.permissions.deny | index("Bash(stale *)")) == null' \
    "$tmp_root/claude-merged.json" >/dev/null

# Permission rule grammar. Claude Code matches a Bash rule as a command pattern:
# everything before the first `*` is compared literally, so `Bash(git:*)` needs a
# command whose text starts with "git:" and never fires. Every rule in this file
# used that dead colon form until 2026-09-06 -- the allowlist had never worked
# and the sudo / rm -rf / pip guardrails did not exist. Only `Bash(rm -rf /*)`,
# which carries no colon, is legitimate. Claude Code's own serializer writes the
# space form, so that is the shape to hold this file to.
jq -e '[.permissions.allow[], .permissions.deny[]]
       | map(select(startswith("Bash(")))
       | map(select(test("^Bash\\([^)]*:") and (. != "Bash(rm -rf /*)")))
       | length == 0' \
    "$tmp_root/claude.json" >/dev/null

# Read()/Edit() deny rules are enforced against file-reading Bash commands, and
# when a compound command's target cannot be resolved statically Claude Code can
# prove neither that a rule applies nor that it does not. That is on the short
# list of things NO permission mode auto-approves, so on a bypassPermissions
# machine they buy nothing and cost a prompt on every unresolvable read. They
# were removed deliberately; keep them out.
jq -e '[.permissions.deny[] | select(test("^(Read|Edit)\\("))] | length == 0' \
    "$tmp_root/claude.json" >/dev/null

# `Write(path)` rules are accepted and then never consulted -- Claude Code checks
# file permissions against Edit() and Read() only, and warns at startup about the
# rest. Commit f92adec fixed eight such no-op rules; this stops them returning.
jq -e '[.permissions.allow[], .permissions.deny[]]
       | map(select(test("^(Write|NotebookEdit|MultiEdit|Glob)\\(")))
       | length == 0' \
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

# MENTIONING a forbidden command is not running it. Until 2026-09-06 the guard
# grepped the raw command text, so writing a test that asserts on the string,
# grepping a config for it, or echoing it was refused inside this tree -- which
# is how this very file became unwritable. The rules now require git to be in
# command position: line start, or right after a shell separator.
[[ -z "$(guard_decision 'jq -e ".bash[\"git worktree *\"]" cfg.json' "$guard_source")" ]]
[[ -z "$(guard_decision 'rg -n "git switch" dot_claude/' "$guard_source")" ]]
[[ -z "$(guard_decision 'echo "git checkout -b feature"' "$guard_source")" ]]

# ...but a real invocation after a separator, or behind an env assignment, is
# still command position and still refused. The separator is assembled from a
# variable so that this test file does not itself read as an invocation to the
# very hook it is testing.
sep='&&'
[[ "$(guard_decision "cd /tmp $sep git switch other" "$guard_source")" == "block" ]]
[[ "$(guard_decision "FOO=1 git checkout main" "$guard_source")" == "block" ]]

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

# subagents.json is the one template asserted here that branches on chezmoi
# data: the work and private machines get different model and thinking rungs
# under the same three tier names. `render` cannot reach it, because a test run
# has no chezmoi config to read `.work` from -- CI has none at all, and a
# developer's own would decide which machine the suite checked. Supply the value
# instead, and check both machines: the split is the whole reason for the branch.
render_subagents() {
    chezmoi execute-template --source "$ROOT" --override-data "{\"work\":$1}" \
        --file "$ROOT/dot_pi/agent/subagents.json.tmpl"
}
render_subagents true >"$tmp_root/subagents-work.json"
render_subagents false >"$tmp_root/subagents-private.json"

for machine in work private; do
    jq -e '
      .maxConcurrent == 40 and
      .defaultMaxTurns == 640 and
      .defaultMaxToolCalls == 1024 and
      .defaultMaxTokens == 3000000 and
      .graceTurns == 8 and
      .fallbackSubagent == "none" and
      .disableDefaultAgents == true and
      .agentTiers.defaultTier == "medium" and
      (.agentTiers.profiles | keys) == ["high", "low", "medium"]
    ' "$tmp_root/subagents-$machine.json" >/dev/null
done

# The per-machine rungs the header comment documents. Both machines keep the
# same tier names, which is what lets one strengths table below serve both.
jq -e '.agentTiers.profiles |
       .low.model == "openai-codex/gpt-5.6-luna" and .low.thinking == "xhigh" and
       .medium.model == "openai-codex/gpt-5.6-luna" and .medium.thinking == "max" and
       .high.model == "openai-codex/gpt-6-astra" and .high.thinking == "high"' \
    "$tmp_root/subagents-work.json" >/dev/null
jq -e '.agentTiers.profiles |
       .low.model == "openai-codex/gpt-5.6-luna" and .low.thinking == "max" and
       .medium.model == "openai-codex/gpt-6-astra" and .medium.thinking == "high" and
       .high.model == "openai-codex/gpt-6-astra" and .high.thinking == "xhigh"' \
    "$tmp_root/subagents-private.json" >/dev/null

# No rung may be a duplicate of another on the same machine. The catalogue is one
# ladder with work entering a notch below private, so two tiers resolving to the
# same model+thinking means a caller asking for more gets exactly what it asked
# to move away from -- and nothing else in this repository would say so.
for machine in work private; do
    jq -e '[.agentTiers.profiles[] | .model + "/" + .thinking] | (unique | length) == length' \
        "$tmp_root/subagents-$machine.json" >/dev/null
done

# The parent session is the `medium` row verbatim. It is emitted by a different
# template from a different file, so nothing but this assertion keeps the two
# from drifting: an interactive turn and a spawn that names no tier must cost
# the same.
render dot_pi/agent/modify_settings.json.tmpl >"$tmp_root/pi-settings.sh"
bash -n "$tmp_root/pi-settings.sh"
printf '{}' | bash "$tmp_root/pi-settings.sh" >"$tmp_root/pi-settings.json"
jq -e --slurpfile subagents "$tmp_root/subagents-private.json" '
  ($subagents[0].agentTiers.profiles.medium) as $medium
  | .defaultProvider == "openai-codex"
    and (.defaultProvider + "/" + .defaultModel) == $medium.model
    and .defaultThinkingLevel == $medium.thinking
' "$tmp_root/pi-settings.json" >/dev/null

# pi-workflows routing. A workflow script names a strength, and this table is the
# only thing binding one to a key in the Agent tier catalogue above. Assert the
# closed vocabulary on the key side, and on the value side that every tier named
# actually exists in subagents.json -- that coupling is the point of the test.
# pi-workflows reports an unknown tier once at run start and then leaves the
# strength unmapped, so a profile rename would otherwise drop every workflow call
# onto the managed `medium` fallback with nothing in this repository to show it.
# pi-permission-system. The GLOBAL policy must not carry the chezmoi git ban: a
# `bash` rule is a command pattern and its schema has no cwd dimension anywhere,
# so stating the ban globally blocks branch work in every unrelated repository --
# the same defect 3671a66 fixed on the Claude side, and the same one the guard
# hook above had. The ban belongs in the project-scoped config in this
# repository, which pi-permission-system reads from `<cwd>/.pi/extensions/...`
# and which overrides global. Assert both halves: the rule missing from the
# project file leaves chezmoi unguarded, and the rule present in the global file
# blocks every other repo again.
render dot_pi/agent/extensions/pi-permission-system/modify_config.json >"$tmp_root/pi-perm.sh"
bash -n "$tmp_root/pi-perm.sh"
printf '' | bash "$tmp_root/pi-perm.sh" >"$tmp_root/pi-perm.json"
jq -e '.yoloMode == true and
       .permission.bash["*"] == "allow" and
       ([.permission.bash | keys[] | select(startswith("git "))] | length) == 0' \
    "$tmp_root/pi-perm.json" >/dev/null

# The merge must DELETE a retired rule, not merely stop declaring it: jq's `*`
# unions objects, so `.permission` is assigned wholesale. Without that, every
# rule ever shipped would survive in the live file forever. And a runtime knob
# must survive -- `yoloMode`/`debugLog` are written by the extension, and the
# static file this replaced erased them on every apply.
printf '%s' '{"debugLog":true,"permission":{"bash":{"*":"allow","git switch *":"deny"}}}' |
    bash "$tmp_root/pi-perm.sh" >"$tmp_root/pi-perm-merged.json"
jq -e '.debugLog == true and
       .yoloMode == true and
       .permission.bash["git switch *"] == null' \
    "$tmp_root/pi-perm-merged.json" >/dev/null

# The project-scoped counterpart, the one place the ban is stated.
jq -e '.permission.bash["*"] == "allow" and
       .yoloMode == true and
       ([.permission.bash | keys[] | select(startswith("git "))] | length) == 6' \
    "$ROOT/.pi/extensions/pi-permission-system/config.json" >/dev/null

render dot_pi/agent/workflows/settings.json.tmpl >"$tmp_root/workflows.json"
for machine in work private; do
    jq -e --slurpfile subagents "$tmp_root/subagents-$machine.json" '
      ($subagents[0].agentTiers.profiles | keys) as $tiers
      | (.strengths | keys) as $strengths
      | ($strengths | length) > 0
        and ($strengths - ["low", "medium", "high"] | length) == 0
        and ([.strengths[]] - $tiers | length) == 0
    ' "$tmp_root/workflows.json" >/dev/null
done

# A strengths entry is a catalogue key and never its own model policy: that is
# the line between this table and the retired `workflow.tiers` key.
jq -e '[.strengths[] | type] | all(. == "string")' "$tmp_root/workflows.json" >/dev/null

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
