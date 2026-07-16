#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
command -v chezmoi >/dev/null 2>&1 || {
    echo "SKIP: chezmoi not found" >&2
    exit 0
}

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/run-onchange-hash-test.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

export HOME="$TMP_ROOT/home"
export XDG_CONFIG_HOME="$HOME/.config"
mkdir -p "$XDG_CONFIG_HOME/chezmoi"

DATA='{"platform":"darwin","hostname":"hash-test","timezone":"Etc/UTC","work":false,"private":true,"headless":false,"useEncryption":false,"installMasApps":false,"homeWifiSSIDs":"","gitUsername":"test","gitEmail":"test@example.com","jjSigningKey":"","claudeProviderAccount":"anthropic","codexProviderAccount":"openai"}'

assert_rendered_hashes() {
    local template="$1"
    local output
    output="$TMP_ROOT/$(basename "$template" .tmpl)"

    chezmoi execute-template --source "$ROOT" --override-data "$DATA" \
        <"$ROOT/$template" >"$output"

    if grep -Eq '^# .*: n/a$' "$output" ||
        ! grep -Eq '^# .+: [0-9a-f]{64}$' "$output"; then
        echo "invalid source-state trigger in $template" >&2
        cat "$output" >&2
        exit 1
    fi
}

# HOME intentionally has no target configuration. Triggers must still be hashes
# of the source state that will be written during this apply.
assert_rendered_hashes ".chezmoiscripts/run_onchange_after_02_init.sh.tmpl"
assert_rendered_hashes ".chezmoiscripts/run_onchange_after_03_set_profiles.sh.tmpl"
assert_rendered_hashes ".chezmoiscripts/run_onchange_after_05_aqua-install-tools.sh.tmpl"
assert_rendered_hashes ".chezmoiscripts/run_onchange_after_07_mise-install.sh.tmpl"
assert_rendered_hashes ".chezmoiscripts/run_onchange_after_17_load-launch-agents.sh.tmpl"

echo "test_run_onchange_source_hashes: OK"
