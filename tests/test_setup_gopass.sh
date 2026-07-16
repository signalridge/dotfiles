#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMPL="$ROOT/.chezmoiscripts/run_onchange_after_06_setup-gopass.sh.tmpl"

require_cmd() {
    command -v "$1" >/dev/null 2>&1
}

require_cmd chezmoi || {
    echo "SKIP: chezmoi not found" >&2
    exit 0
}

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/setup-gopass-test.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

export HOME="$TMP_ROOT/home"
mkdir -p "$HOME/.config/chezmoi"
export XDG_CONFIG_HOME="$HOME/.config"

GOPASS_REPO="git@example.com:example/password-store.git"
cat >"$HOME/.config/chezmoi/chezmoi.toml" <<EOF
[data]
useEncryption = true
gopassRepository = "$GOPASS_REPO"
EOF

RENDERED="$TMP_ROOT/setup-gopass.sh"
chezmoi execute-template --config "$HOME/.config/chezmoi/chezmoi.toml" --source "$ROOT" <"$TMPL" >"$RENDERED"

mkdir -p "$HOME/.ssh"
echo "dummy" >"$HOME/.ssh/main"

BIN="$TMP_ROOT/bin"
mkdir -p "$BIN"
export AQUA_ROOT_DIR="$TMP_ROOT/aquaproj-aqua"
mkdir -p "$AQUA_ROOT_DIR/bin"

LOG="$TMP_ROOT/gopass.log"
cat >"$BIN/gopass" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

log="${GOPASS_TEST_LOG:-/dev/null}"
echo "gopass $*" >>"$log"

cmd="${1:-}"
shift || true

case "$cmd" in
  clone)
    mkdir -p "$HOME/.local/share/gopass/stores/root"
    exit 0
    ;;
  ls)
    [[ "${GOPASS_TEST_FAIL_LS:-0}" != "1" ]] || exit 7
    if [[ "${1:-}" == "--flat" ]]; then
      echo "dummy/secret"
    else
      echo "dummy"
    fi
    exit 0
    ;;
  show)
    [[ "${GOPASS_TEST_FAIL_SHOW:-0}" != "1" ]] || exit 8
    exit 0
    ;;
  *)
    echo "unsupported gopass subcommand: $cmd" >&2
    exit 2
    ;;
esac
EOF
chmod +x "$BIN/gopass"
ln -sf "$BIN/gopass" "$AQUA_ROOT_DIR/bin/gopass"

export PATH="$BIN:$PATH"
export GOPASS_TEST_LOG="$LOG"

###############################################################################
# Case 1: an existing store is accepted only after read/decrypt verification.
mkdir -p "$HOME/.local/share/gopass/stores/root/.git"
rm -f "$LOG"
bash "$RENDERED" </dev/null >/dev/null 2>&1
grep -q "gopass ls" "$LOG"
grep -q "gopass show" "$LOG"

set +e
GOPASS_TEST_FAIL_LS=1 bash "$RENDERED" </dev/null >/dev/null 2>&1
fail_ls_rc=$?
GOPASS_TEST_FAIL_SHOW=1 bash "$RENDERED" </dev/null >/dev/null 2>&1
fail_show_rc=$?
set -e
[[ "$fail_ls_rc" -ne 0 ]] || {
    echo "expected an unreadable existing store to fail" >&2
    exit 1
}
[[ "$fail_show_rc" -ne 0 ]] || {
    echo "expected an undecryptable existing store to fail" >&2
    exit 1
}

rm -rf "$HOME/.local/share/gopass/stores/root"

###############################################################################
# Case 2: user says 'no' -> exit 0 and do not clone.
###############################################################################
rm -f "$LOG"
mkdir -p "$HOME/.config/gopass/age"
printf "no\n" | bash "$RENDERED" >/dev/null 2>&1

if [[ -d "$HOME/.local/share/gopass/stores/root" ]]; then
    echo "store was created unexpectedly when user declined" >&2
    exit 1
fi

###############################################################################
# Case 3: user says 'yes' -> clone, back up age identities dir, verify calls.
###############################################################################
rm -f "$LOG"
mkdir -p "$HOME/.config/gopass/age"
echo "identity" >"$HOME/.config/gopass/age/key.txt"
printf "yes\n" | bash "$RENDERED" >/dev/null 2>&1

[[ -d "$HOME/.local/share/gopass/stores/root" ]] || {
    echo "store was not created" >&2
    exit 1
}
[[ ! -d "$HOME/.config/gopass/age" ]] || {
    echo "expected ~/.config/gopass/age to be moved aside" >&2
    exit 1
}
age_backup_count="$(
    find "$HOME/.config/gopass" -maxdepth 1 -type d -name 'age.backup.*' | wc -l | tr -d ' '
)"
[[ "$age_backup_count" == "1" ]] || {
    echo "expected exactly one age backup, found $age_backup_count" >&2
    find "$HOME/.config/gopass" -maxdepth 1 -type d -print >&2
    exit 1
}
age_backup_dir="$(find "$HOME/.config/gopass" -maxdepth 1 -type d -name 'age.backup.*' -print -quit)"
[[ -f "$age_backup_dir/key.txt" ]] || {
    echo "expected age identity material to be preserved in backup" >&2
    exit 1
}

grep -q "gopass clone" "$LOG" || {
    echo "expected gopass clone to be invoked" >&2
    cat "$LOG" >&2
    exit 1
}
grep -q "gopass ls" "$LOG" || {
    echo "expected gopass ls to be invoked" >&2
    cat "$LOG" >&2
    exit 1
}
grep -q "gopass show" "$LOG" || {
    echo "expected gopass show to be invoked" >&2
    cat "$LOG" >&2
    exit 1
}

echo "test_setup_gopass: OK"
