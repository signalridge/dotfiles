#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# The test replaces HOME, but the script still needs the real chezmoi source.
export CHEZMOI_SOURCE_DIR="$repo_root"
temporary=$(mktemp -d)
trap 'rm -rf "$temporary"' EXIT
export HOME="$temporary/home"
mkdir -p "$HOME/.nix-profile/bin" "$HOME/.codex"
export HERDR_TEST_LOG="$temporary/installs"
# Do not invoke real integrations or touch the user's home directory.
printf '%s\n' '#!/bin/bash' 'echo "$*" >> "$HERDR_TEST_LOG"' >"$HOME/.nix-profile/bin/herdr"
chmod +x "$HOME/.nix-profile/bin/herdr"
hooks="$HOME/.codex/hooks.json"
prefix="bash '$HOME/.codex/herdr-agent-state.sh'"
run_sync() {
    : >"$HERDR_TEST_LOG"
    bash "$repo_root/.chezmoiscripts/run_after_14_sync-herdr-integrations.sh" >"$temporary/output" 2>&1
}
assert_integrations() {
    printf '%s\n' 'integration install codex' 'integration install claude' >"$temporary/expected-installs"
    cmp "$temporary/expected-installs" "$HERDR_TEST_LOG"
}

# Reproduce a Rex SessionStart hook sharing an event with Herdr.
jq -n --arg prefix "$prefix" '{hooks:{SessionStart:[
    {hooks:[{command:"rex __internal session-start --agent codex",timeout:5,type:"command"}]},
    {hooks:[{command:($prefix + " session"),timeout:10,type:"command"}]}
]}}' >"$hooks"
jq 'del(.hooks.SessionStart[1])' "$hooks" >"$temporary/expected.json"
run_sync
jq -se '.[0] == .[1]' "$hooks" "$temporary/expected.json" >/dev/null
assert_integrations
cp "$hooks" "$temporary/before.json"
run_sync
cmp "$hooks" "$temporary/before.json"
printf 'ok - mixed Rex/Herdr hooks preserve Rex, finish all integrations and are idempotent\n'

# Preserve metadata, unrelated events, empty arrays, and extended hook objects.
# Remove known hooks even when nested alongside unrelated hooks in one group.
jq -n --arg prefix "$prefix" '{version:1,hooks:{
    SessionStart:[{matcher:"*",custom:true,hooks:[
        {command:($prefix + " session"),timeout:10,type:"command"},
        {command:"rex session-start",timeout:5,type:"command"},
        {command:($prefix + " session"),timeout:10,type:"command",custom:true}
    ]}],
    UserPromptSubmit:[{hooks:[{command:($prefix + " working"),timeout:10,type:"command"}]}],
    Stop:[{hooks:[{command:($prefix + " idle"),timeout:10,type:"command"}]}],
    Empty:[],Unrelated:[{hooks:[]}]
}}' >"$hooks"
jq 'del(.hooks.SessionStart[0].hooks[0], .hooks.UserPromptSubmit, .hooks.Stop)' "$hooks" >"$temporary/expected.json"
run_sync
jq -se '.[0] == .[1]' "$hooks" "$temporary/expected.json" >/dev/null
assert_integrations
printf 'ok - mixed groups, metadata, unknown hook fields and unrelated events survive\n'

jq -n --arg prefix "$prefix" '{hooks:{SessionStart:[{hooks:[
    {command:($prefix + " session"),timeout:10,type:"command"}
]}]}}' >"$hooks"
run_sync
test ! -e "$hooks"
assert_integrations
run_sync
assert_integrations
printf 'ok - Herdr-only file is removed; missing file is harmless\n'

jq -n --arg prefix "$prefix" '{version:1,hooks:{SessionStart:[{hooks:[
    {command:($prefix + " session"),timeout:10,type:"command"}
]}]}}' >"$hooks"
run_sync
jq -e '. == {version:1,hooks:{}}' "$hooks" >/dev/null
printf 'ok - top-level metadata prevents file removal\n'

for invalid in '{' 'null' '{"hooks":[]}' '{"hooks":{"SessionStart":[{}]}}' '{"hooks":{"SessionStart":[{"hooks":[null]}]}}' '{"hooks":{}} {}' ''; do
    printf '%s\n' "$invalid" >"$hooks"
    cp "$hooks" "$temporary/before.json"
    if run_sync; then
        printf 'not ok - accepted invalid hooks: %s\n' "$invalid" >&2
        exit 1
    fi
    cmp "$hooks" "$temporary/before.json"
    if compgen -G "${hooks}.??????" >/dev/null; then
        printf 'not ok - temporary hook file leaked\n' >&2
        exit 1
    fi
done
printf 'ok - malformed JSON and invalid structures are preserved and rejected without temporary-file leaks\n'
