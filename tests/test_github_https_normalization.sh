#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

require_cmd() {
    command -v "$1" >/dev/null 2>&1
}

require_cmd chezmoi || {
    echo "SKIP: chezmoi not found" >&2
    exit 0
}

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/github-https-normalization-test.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

export HOME="$TMP_ROOT/home"
mkdir -p "$HOME/.config/chezmoi"

CONFIG="$TMP_ROOT/chezmoi.toml"
cat >"$CONFIG" <<'EOF'
[data]
hostname = "test"
work = false
private = true
homeWifiSSIDs = ""
platform = "darwin"
installMasApps = false
timezone = "UTC"
gitUsername = "test"
gitEmail = "test@test.com"
useEncryption = true
headless = false
gopassRepository = "git@github.com:test/pass.git"
keysRepository = "ssh://git@github.com/test/keys.git"
codexProviderAccount = "openai"
opencodeProviderAccount = "openai"
EOF

render() {
    local src="$1"
    chezmoi execute-template --config "$CONFIG" --source "$ROOT" <"$ROOT/$src"
}

gopass_config="$(render private_dot_config/gopass/config.tmpl)"
setup_gopass="$(render .chezmoiscripts/run_onchange_after_06_setup-gopass.sh.tmpl)"
keys_manage="$(render dot_local/bin/executable_keys-manage.tmpl)"
gh_hosts="$(render private_dot_config/gh/private_hosts.yml.tmpl)"

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local label="$3"
    if [[ "$haystack" != *"$needle"* ]]; then
        echo "missing expected text in $label: $needle" >&2
        exit 1
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local label="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        echo "unexpected text in $label: $needle" >&2
        exit 1
    fi
}

assert_contains "$gopass_config" "source_url = https://github.com/test/pass.git" "gopass config"
assert_contains "$setup_gopass" "gopass clone --check-keys=false \"https://github.com/test/pass.git\"" "setup gopass"
assert_contains "$keys_manage" "KEYS_REPO=\"https://github.com/test/keys.git\"" "keys-manage"
assert_contains "$gh_hosts" "git_protocol: https" "gh hosts"

assert_not_contains "$gopass_config" "git@github.com" "gopass config"
assert_not_contains "$setup_gopass" "git@github.com" "setup gopass"
assert_not_contains "$keys_manage" "git@github.com" "keys-manage"
assert_not_contains "$gh_hosts" "git_protocol: ssh" "gh hosts"

echo "test_github_https_normalization: OK"
