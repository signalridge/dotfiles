#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMPL="$ROOT/.chezmoiscripts/run_onchange_after_04_setup-gopass.sh.tmpl"

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

GOPASS_REPO="git@example.com:example/password-store.git"
cat >"$HOME/.config/chezmoi/chezmoi.toml" <<EOF
[data]
useEncryption = true
gopassRepository = "$GOPASS_REPO"
EOF

RENDERED="$TMP_ROOT/setup-gopass.sh"
chezmoi execute-template --source "$ROOT" <"$TMPL" >"$RENDERED"

mkdir -p "$HOME/.ssh"
echo "dummy" >"$HOME/.ssh/main"

BIN="$TMP_ROOT/bin"
mkdir -p "$BIN"

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
    if [[ "${1:-}" == "--flat" ]]; then
      echo "dummy/secret"
    else
      echo "dummy"
    fi
    exit 0
    ;;
  show)
    # Always succeed.
    exit 0
    ;;
  *)
    echo "unsupported gopass subcommand: $cmd" >&2
    exit 2
    ;;
esac
EOF
chmod +x "$BIN/gopass"

export PATH="$BIN:$PATH"
export GOPASS_TEST_LOG="$LOG"

###############################################################################
# Case 1: store already exists -> exit 0 without needing gopass/ssh checks.
###############################################################################
mkdir -p "$HOME/.local/share/gopass/stores/root"
rm -f "$LOG"
bash "$RENDERED" </dev/null >/dev/null 2>&1

if [[ -s "$LOG" ]]; then
    echo "expected gopass not to be called when store exists" >&2
    cat "$LOG" >&2
    exit 1
fi

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
# Case 3: user says 'yes' -> clone, remove age identities dir, verify calls.
###############################################################################
rm -f "$LOG"
mkdir -p "$HOME/.config/gopass/age"
printf "yes\n" | bash "$RENDERED" >/dev/null 2>&1

[[ -d "$HOME/.local/share/gopass/stores/root" ]] || {
    echo "store was not created" >&2
    exit 1
}
[[ ! -d "$HOME/.config/gopass/age" ]] || {
    echo "expected ~/.config/gopass/age to be removed" >&2
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
