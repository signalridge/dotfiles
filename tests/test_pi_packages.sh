#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
command -v chezmoi >/dev/null 2>&1 || {
    echo "SKIP: chezmoi not found" >&2
    exit 0
}
command -v jq >/dev/null 2>&1 || {
    echo "SKIP: jq not found" >&2
    exit 0
}

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/pi-packages-test.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

rendered_settings="$TMP_ROOT/modify-settings.sh"
chezmoi execute-template --source "$ROOT" \
    <"$ROOT/dot_pi/agent/modify_settings.json.tmpl" >"$rendered_settings"
chmod +x "$rendered_settings"
printf '{}' | bash "$rendered_settings" >"$TMP_ROOT/settings.json"

jq -e '.quietStartup == false' "$TMP_ROOT/settings.json" >/dev/null
jq -e '.theme == "signalridge-ridgeline"' "$TMP_ROOT/settings.json" >/dev/null
jq -e '(.name == "signalridge-ridgeline") and (.colors.accent != null) and (.colors.toolDiffAdded != null) and (.colors.thinkingMax != null)' \
    "$ROOT/dot_pi/agent/themes/signalridge-ridgeline.json" >/dev/null

# The rendered package list is an ordered contract: external infrastructure
# first, then every signalridge package as an unpinned npm spec. Asserting the
# exact array (not a count) keeps a dropped or silently re-pinned package visible.
jq -e '
    .packages == [
        "npm:pi-mcp-adapter",
        "npm:@gotgenes/pi-permission-system",
        "npm:pi-readseek",
        "npm:@hypabolic/pi-hypa",
        "npm:@signalridge/pi-subagents",
        "npm:@signalridge/pi-workflows",
        "npm:@signalridge/pi-goal",
        "npm:@signalridge/pi-ralph-wiggum",
        "npm:@signalridge/pi-plan-mode",
        "npm:@signalridge/pi-herdr-state",
        "npm:@signalridge/pi-gpt-fast",
        "npm:@signalridge/pi-agent-guidance",
        "npm:@signalridge/pi-input-history",
        "npm:@signalridge/pi-input-prefix",
        "npm:@signalridge/pi-statusline",
        "npm:@signalridge/pi-tab-status",
        "npm:@signalridge/pi-welcome",
        "npm:@signalridge/pi-session-recap",
        "npm:@signalridge/pi-usage-extension",
        "npm:@signalridge/pi-stamp",
        "npm:@signalridge/pi-lsp",
        "npm:@signalridge/pi-github-pr",
        "npm:@signalridge/pi-files-widget",
        "npm:@signalridge/pi-code-actions",
        "npm:@signalridge/pi-btw"
    ]
' "$TMP_ROOT/settings.json" >/dev/null

# Versions are deliberately unpinned so Pi installs the latest release and
# `pi update --extensions` can keep moving it forward. A version suffix on any
# entry (a scoped spec has exactly one "@", at index 0 of the bare name) would
# freeze an extension at whatever release happened to be current.
jq -e 'all(.packages[]; (split(":")[1] | split("/") | last | contains("@")) | not)' \
    "$TMP_ROOT/settings.json" >/dev/null

# Nothing may resolve to the development checkout: a path entry alongside the
# npm spec would make Pi load two copies of the same extension.
jq -e 'all(.packages[]; startswith("npm:"))' "$TMP_ROOT/settings.json" >/dev/null

# pi-subagents-protocol is a pure library (a dependency of the extensions that
# use it) and must never appear as a Pi resource. pi-worktree is forbidden by
# the repository constitution.
jq -e 'any(.packages[]; test("pi-subagents-protocol|pi-worktree$")) | not' \
    "$TMP_ROOT/settings.json" >/dev/null

# The vendored extension sources and the old dynamic-workflows config are gone
# from the source tree; the npm packages are the only implementation.
[[ ! -e "$ROOT/dot_pi/agent/extensions/pi-statusline/package.json" ]]
[[ ! -e "$ROOT/dot_pi/agent/extensions/pi-input-history/index.ts" ]]
[[ ! -e "$ROOT/dot_pi/workflows/settings.json" ]]
[[ ! -e "$ROOT/dot_pi/workflows/model-tiers.json.tmpl" ]]

rendered_cleanup="$TMP_ROOT/remove-legacy.sh"
chezmoi execute-template --source "$ROOT" \
    <"$ROOT/.chezmoiscripts/run_after_19_remove-legacy-pi-sources.sh.tmpl" >"$rendered_cleanup"
chmod +x "$rendered_cleanup"
legacy_agent="$TMP_ROOT/legacy-agent"
mkdir -p "$legacy_agent/extensions/pi-input-prefix" \
    "$legacy_agent/npm/node_modules/@tintinweb/pi-subagents" \
    "$legacy_agent/npm/node_modules/@quintinshaw/pi-dynamic-workflows" \
    "$legacy_agent/npm/node_modules/@narumitw/pi-goal" \
    "$legacy_agent/npm/node_modules/@narumitw/pi-statusline" \
    "$legacy_agent/npm/node_modules/pi-input-history"
cat >"$legacy_agent/extensions/pi-input-prefix/package.json" <<'EOF'
{
  "name": "pi-ext-input-prefix",
  "private": true
}
EOF
cat >"$legacy_agent/npm/package.json" <<'EOF'
{
  "name": "pi-extensions",
  "private": true,
  "dependencies": {
    "@gotgenes/pi-permission-system": "^24.0.0",
    "@tintinweb/pi-subagents": "^0.14.3",
    "@quintinshaw/pi-dynamic-workflows": "^3.5.1",
    "@narumitw/pi-goal": "^0.49.7",
    "@narumitw/pi-statusline": "^0.49.7",
    "pi-input-history": "^1.1.0"
  }
}
EOF
test_home="$TMP_ROOT/home"
mkdir -p "$test_home/.pi/workflows/projects/keep-me"
printf '%s\n' '{"keywordTriggerEnabled":false}' >"$test_home/.pi/workflows/settings.json"
printf '%s\n' '{"tiers":{"small":"old-model"}}' >"$test_home/.pi/workflows/model-tiers.json"
printf '%s\n' 'keep this workflow project' >"$test_home/.pi/workflows/projects/keep-me/README.txt"
HOME="$test_home" PI_CODING_AGENT_DIR="$legacy_agent" bash "$rendered_cleanup" >/dev/null
jq -e '(.dependencies // {}) | has("@tintinweb/pi-subagents") | not' "$legacy_agent/npm/package.json" >/dev/null
jq -e '(.dependencies // {}) | has("@quintinshaw/pi-dynamic-workflows") | not' "$legacy_agent/npm/package.json" >/dev/null
# An unrelated external package must survive the legacy sweep.
jq -e '(.dependencies // {}) | has("@gotgenes/pi-permission-system")' "$legacy_agent/npm/package.json" >/dev/null
[[ ! -e "$legacy_agent/extensions/pi-input-prefix" ]]
[[ ! -e "$legacy_agent/npm/node_modules/@tintinweb/pi-subagents" ]]

[[ ! -e "$legacy_agent/npm/node_modules/@quintinshaw/pi-dynamic-workflows" ]]
[[ ! -e "$legacy_agent/npm/node_modules/@narumitw/pi-goal" ]]
[[ ! -e "$legacy_agent/npm/node_modules/@narumitw/pi-statusline" ]]
[[ ! -e "$legacy_agent/npm/node_modules/pi-input-history" ]]
[[ ! -e "$test_home/.pi/workflows/settings.json" ]]
[[ ! -e "$test_home/.pi/workflows/model-tiers.json" ]]
[[ -f "$test_home/.pi/workflows/projects/keep-me/README.txt" ]]

printf '%s\n' "test_pi_packages: OK"
