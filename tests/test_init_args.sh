#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/init-args-test.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

export HOME="$TMP_ROOT/home"
mkdir -p "$HOME"

BIN="$TMP_ROOT/bin"
mkdir -p "$BIN"

ARGS_FILE="$TMP_ROOT/chezmoi-args.txt"
export CHEZMOI_ARGS_FILE="$ARGS_FILE"

cat >"$BIN/chezmoi" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

: "${CHEZMOI_ARGS_FILE:?}"
printf '%s\n' "$*" >"$CHEZMOI_ARGS_FILE"
EOF
chmod +x "$BIN/chezmoi"
export PATH="$BIN:$PATH"

# Copy init.sh into a directory that is NOT a chezmoi source dir, so it takes the
# remote init path (where --repo/--ref/--depth/--ssh are used).
SCRIPT_DIR="$TMP_ROOT/script"
mkdir -p "$SCRIPT_DIR"
cp "$ROOT/init.sh" "$SCRIPT_DIR/init.sh"
chmod +x "$SCRIPT_DIR/init.sh"

"$SCRIPT_DIR/init.sh" --repo alice/dotfiles --ref v1 --depth 10 --ssh -- --foo bar
expected="init --apply --branch v1 --depth 10 --ssh --foo bar alice/dotfiles"
got="$(cat "$ARGS_FILE")"
if [[ "$got" != "$expected" ]]; then
    echo "unexpected chezmoi args:" >&2
    echo "  expected: $expected" >&2
    echo "  got:      $got" >&2
    exit 1
fi

"$SCRIPT_DIR/init.sh" --repo alice/dotfiles --branch v2 -- --baz
expected="init --apply --branch v2 --baz alice/dotfiles"
got="$(cat "$ARGS_FILE")"
if [[ "$got" != "$expected" ]]; then
    echo "unexpected chezmoi args for --branch alias:" >&2
    echo "  expected: $expected" >&2
    echo "  got:      $got" >&2
    exit 1
fi

set +e
out="$("$SCRIPT_DIR/init.sh" --repo 2>&1)"
rc=$?
set -e
if [[ $rc -ne 2 ]] || [[ "$out" != *"--repo requires a value"* ]]; then
    echo "expected --repo missing-value error (rc=2)" >&2
    echo "rc=$rc" >&2
    echo "$out" >&2
    exit 1
fi

set +e
out="$("$SCRIPT_DIR/init.sh" --unknown 2>&1)"
rc=$?
set -e
if [[ $rc -ne 2 ]] || [[ "$out" != *"unknown option"* ]]; then
    echo "expected unknown-option error (rc=2)" >&2
    echo "rc=$rc" >&2
    echo "$out" >&2
    exit 1
fi

echo "test_init_args: OK"
