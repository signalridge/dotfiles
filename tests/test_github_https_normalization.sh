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
useremail = "test@example.com"
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

# ─────────────────────────────────────────────────────────────
# Runtime: normalize_github_origin rewrites existing SSH remotes.
# Covers the upgrade case where a machine was set up on the SSH-era
# config and already has `git@github.com:...` baked into .git/config.
# ─────────────────────────────────────────────────────────────
if require_cmd git; then
    # keys-manage/core.sh expects these constants to be pre-declared by the
    # keys-manage entry script. Export them here so we can source the lib
    # for the helper under test without bringing in the full CLI. (`export`
    # also tells shellcheck they're consumed externally — silences SC2034.)
    export KEYS_REPO=""
    export REPO_DIR="$TMP_ROOT/keys-backup"
    export BACKUP_FILES_DIR="backup-files"
    export BACKUP_LIST="$REPO_DIR/backup-list.txt"
    export BACKUP_LIST_ENC="$REPO_DIR/backup-list.txt.enc"
    export METADATA_FILE="$REPO_DIR/backup-metadata.json"
    export METADATA_FILE_ENC="$REPO_DIR/backup-metadata.json.enc"
    export CONTROL_STATE_DIR="$REPO_DIR/.keys-manage"
    export CONTROL_BASELINE_LIST="$CONTROL_STATE_DIR/backup-list.remote.sha256"
    export CONTROL_BASELINE_META="$CONTROL_STATE_DIR/backup-metadata.remote.sha256"
    export HISTORY_LOG="$REPO_DIR/backup-history.log"
    export RESTORE_SNAPSHOT_DIR="$REPO_DIR/restore-snapshots"
    # shellcheck source=../dot_local/bin/lib/common
    source "$ROOT/dot_local/bin/lib/common"
    # shellcheck source=../dot_local/bin/lib/keys-manage/core.sh
    source "$ROOT/dot_local/bin/lib/keys-manage/core.sh"

    assert_origin_normalized() {
        local input="$1"
        local expected="$2"
        local label="$3"
        local dir
        dir=$(mktemp -d "$TMP_ROOT/repo.XXXXXX")
        git -C "$dir" init -q
        git -C "$dir" remote add origin "$input"
        normalize_github_origin "$dir" >/dev/null
        local got
        got=$(git -C "$dir" remote get-url origin)
        if [[ "$got" != "$expected" ]]; then
            echo "normalize_github_origin($label): expected '$expected', got '$got'" >&2
            exit 1
        fi
    }

    assert_origin_normalized \
        "git@github.com:test/keys.git" \
        "https://github.com/test/keys.git" \
        "scp-style SSH"
    assert_origin_normalized \
        "ssh://git@github.com/test/keys.git" \
        "https://github.com/test/keys.git" \
        "ssh:// URL"
    assert_origin_normalized \
        "https://github.com/test/keys.git" \
        "https://github.com/test/keys.git" \
        "already HTTPS (no-op)"
    assert_origin_normalized \
        "git@gitlab.com:test/keys.git" \
        "git@gitlab.com:test/keys.git" \
        "non-github SSH untouched"

    # Runtime: run_before_01 has an earlier fast-path origin normalizer that
    # must not depend on later helper functions being defined.
    rendered_run_before="$TMP_ROOT/run_before_01.sh"
    render .chezmoiscripts/run_before_01_setup-encryption-key.sh.tmpl >"$rendered_run_before"
    chmod +x "$rendered_run_before"

    fast_home="$TMP_ROOT/run-before-home"
    fast_repo="$fast_home/.local/share/keys-backup"
    mkdir -p "$fast_repo/backup-files" "$fast_home/.ssh"
    touch "$fast_home/.ssh/main" "$fast_repo/backup-list.txt"
    git -C "$fast_repo" init -q
    git -C "$fast_repo" remote add origin "git@github.com:test/keys.git"

    HOME="$fast_home" KEYS_REPO="https://github.com/test/keys.git" bash "$rendered_run_before" >/dev/null
    fast_origin="$(git -C "$fast_repo" remote get-url origin)"
    if [[ "$fast_origin" != "https://github.com/test/keys.git" ]]; then
        echo "run_before_01 fast path: expected HTTPS origin, got '$fast_origin'" >&2
        exit 1
    fi
fi

# ─────────────────────────────────────────────────────────────
# .chezmoi.toml.tmpl must fail loud when identity prompts are unset
# and there's no TTY. Prior behavior silently wrote prompt-label
# placeholders ("GitHub username", etc.) into the config, which then
# leaked into URLs as `https://github.com/GitHub username/...`.
# ─────────────────────────────────────────────────────────────
assert_identity_render_fails_without_tty() {
    local stderr
    stderr=$(DOTFILES_USE_ENCRYPTION=false chezmoi execute-template \
        --config /dev/null --config-format toml \
        --init --stdinisatty=false \
        --source "$ROOT" \
        <"$ROOT/.chezmoi.toml.tmpl" 2>&1 >/dev/null) && {
        echo "expected toml.tmpl render to fail when identity data is unset in non-TTY mode" >&2
        echo "$stderr" >&2
        exit 1
    }
    # Any of {hostname, useremail, gitUsername, gitEmail} should trigger the
    # guard; the first one in source order wins. Match the shared suffix.
    if [[ "$stderr" != *"is unset and there is no TTY to prompt"* ]]; then
        echo "expected identity fail-fast message in stderr, got:" >&2
        echo "$stderr" >&2
        exit 1
    fi
}

assert_identity_render_fails_without_tty

assert_use_encryption_env_overrides_config() {
    local rendered
    rendered=$(DOTFILES_USE_ENCRYPTION=false chezmoi execute-template \
        --config "$CONFIG" \
        --init --stdinisatty=false \
        --source "$ROOT" \
        <"$ROOT/.chezmoi.toml.tmpl")

    assert_contains "$rendered" "useEncryption = false" "useEncryption env override"
}

assert_use_encryption_message_avoids_pipe_to_sh() {
    local stderr
    stderr=$(chezmoi execute-template \
        --config /dev/null --config-format toml \
        --init --stdinisatty=false \
        --source "$ROOT" \
        <"$ROOT/.chezmoi.toml.tmpl" 2>&1 >/dev/null) && {
        echo "expected toml.tmpl render to fail when useEncryption is unset in non-TTY mode" >&2
        echo "$stderr" >&2
        exit 1
    }
    assert_contains "$stderr" "Download init.sh and run it interactively" "useEncryption fail message"
    assert_not_contains "$stderr" "| DOTFILES_USE_ENCRYPTION" "useEncryption fail message"
}

assert_use_encryption_env_overrides_config
assert_use_encryption_message_avoids_pipe_to_sh

echo "test_github_https_normalization: OK"
