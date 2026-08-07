#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

require_cmd() {
    command -v "$1" >/dev/null 2>&1
}

for c in git openssl jq python3; do
    require_cmd "$c" || {
        echo "SKIP: missing dependency: $c" >&2
        exit 0
    }
done
require_cmd chezmoi || {
    echo "SKIP: missing dependency: chezmoi" >&2
    exit 0
}
REAL_OPENSSL="$(command -v openssl)"

PASS="test-pass-123"

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/keys-manage-test.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

export HOME="$TMP_ROOT/home"
mkdir -p "$HOME/.config/chezmoi"

REMOTE="$TMP_ROOT/remote.git"
LOCAL_REPO="$HOME/.local/share/keys-backup"

git init --bare "$REMOTE" >/dev/null

# Seed minimal chezmoi data so the template renders with a repo URL.
cat >"$HOME/.config/chezmoi/chezmoi.toml" <<EOF
[data]
keysRepository = "$REMOTE"
EOF

# Render keys-manage + common lib into a temp bin dir.
BIN="$TMP_ROOT/bin"
mkdir -p "$BIN/lib/keys-manage"

chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/executable_keys-manage.tmpl" >"$BIN/keys-manage"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/lib/common" >"$BIN/lib/common"
cp "$ROOT/dot_local/bin/lib/keys-manage/"*.sh "$BIN/lib/keys-manage/"
chmod +x "$BIN/keys-manage" "$BIN/lib/common"
export PATH="$BIN:$PATH"

set +e
unsafe_password_output="$(keys-manage --password secret status 2>&1)"
unsafe_password_rc=$?
set -e
[[ "$unsafe_password_rc" -eq 2 ]]
grep -Fq "unsafe because secrets appear" <<<"$unsafe_password_output"
password_file="$TMP_ROOT/password"
printf '%s\n' "$PASS" >"$password_file"
chmod 600 "$password_file"
keys-manage --password-file "$password_file" --help >/dev/null 2>&1
ln -s "$password_file" "$TMP_ROOT/password-link"
if keys-manage --password-file "$TMP_ROOT/password-link" --help >/dev/null 2>&1; then
    echo "expected symlinked password file to be rejected" >&2
    exit 1
fi

# Create a local working repo that tracks the bare remote.
mkdir -p "$LOCAL_REPO"
(
    cd "$LOCAL_REPO"
    git init -b main >/dev/null
    git config user.name "CI Test"
    git config user.email "ci-test@example.com"
    git remote add origin "$REMOTE"

    cat >.gitignore <<'EOF'
.keys-manage/
backup-list.txt
backup-metadata.json
EOF

    cat >backup-metadata.json <<'JSON'
{
  "version": 2,
  "filters": {
    "include_patterns": ["*"],
    "exclude_patterns": ["known_hosts*", "authorized_keys*"],
    "custom_paths": []
  },
  "files": {}
}
JSON
    : >backup-list.txt

    # Track only encrypted control files in git; keep plaintext working copies local+ignored.
    openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -pass "pass:$PASS" \
        -in backup-list.txt -out backup-list.txt.enc >/dev/null 2>&1
    openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -pass "pass:$PASS" \
        -in backup-metadata.json -out backup-metadata.json.enc >/dev/null 2>&1
    chmod 600 backup-list.txt.enc backup-metadata.json.enc

    git add .gitignore backup-metadata.json.enc backup-list.txt.enc
    git commit -m "init" >/dev/null
    git push -u origin main >/dev/null
)

# Create a secret file under HOME and add it to backup list.
mkdir -p "$HOME/.ssh"
SECRET_FILE="$HOME/.ssh/main"
echo "dummy-key-content" >"$SECRET_FILE"
chmod 600 "$SECRET_FILE"
echo "dummy-pub-content" >"$SECRET_FILE.pub"
chmod 644 "$SECRET_FILE.pub"
# shellcheck disable=SC2088 # Literal tilde paths exercise list normalization.
printf '%s\n' "~/.ssh/main" "~/.ssh/main.pub" >>"$LOCAL_REPO/backup-list.txt"

# Sync should encrypt, update metadata, commit, and push.
KEYS_BACKUP_PASSWORD="$PASS" KEYS_MANAGE_CONTROL_CONFLICT_POLICY=local keys-manage sync >/dev/null

# Plain control files must not be tracked.
git -C "$LOCAL_REPO" ls-files --error-unmatch backup-list.txt >/dev/null 2>&1 && {
    echo "expected backup-list.txt to be gitignored (not tracked)" >&2
    exit 1
}
git -C "$LOCAL_REPO" ls-files --error-unmatch backup-metadata.json >/dev/null 2>&1 && {
    echo "expected backup-metadata.json to be gitignored (not tracked)" >&2
    exit 1
}
git -C "$LOCAL_REPO" ls-files --error-unmatch backup-list.txt.enc >/dev/null 2>&1 || {
    echo "expected backup-list.txt.enc to be tracked" >&2
    exit 1
}
git -C "$LOCAL_REPO" ls-files --error-unmatch backup-metadata.json.enc >/dev/null 2>&1 || {
    echo "expected backup-metadata.json.enc to be tracked" >&2
    exit 1
}

# backup-list and metadata must not leak absolute paths.
grep -qxF '.ssh/main' "$LOCAL_REPO/backup-list.txt" || {
    echo "expected backup-list.txt to contain .ssh/main" >&2
    cat "$LOCAL_REPO/backup-list.txt" >&2 || true
    exit 1
}
grep -qxF '.ssh/main.pub' "$LOCAL_REPO/backup-list.txt" || {
    echo "expected backup-list.txt to contain .ssh/main.pub" >&2
    cat "$LOCAL_REPO/backup-list.txt" >&2 || true
    exit 1
}

jq -r '.files | keys[]' "$LOCAL_REPO/backup-metadata.json" | grep -q '^/' && {
    echo "backup-metadata.json contains absolute path keys (should be HOME-relative)" >&2
    jq -r '.files | keys[]' "$LOCAL_REPO/backup-metadata.json" >&2
    exit 1
}

jq -e '.files | has(".ssh/main")' "$LOCAL_REPO/backup-metadata.json" >/dev/null || {
    echo "expected backup-metadata.json to contain .ssh/main key" >&2
    jq -r '.files | keys[]' "$LOCAL_REPO/backup-metadata.json" >&2
    exit 1
}
jq -e '.files | has(".ssh/main.pub")' "$LOCAL_REPO/backup-metadata.json" >/dev/null || {
    echo "expected backup-metadata.json to contain .ssh/main.pub key" >&2
    jq -r '.files | keys[]' "$LOCAL_REPO/backup-metadata.json" >&2
    exit 1
}

python3 - "$LOCAL_REPO/backup-files/.ssh/main.pub" <<'PY'
import sys
data=open(sys.argv[1], "rb").read(8)
if data != b"Salted__":
  raise SystemExit(f"expected encrypted pub key (Salted__), got: {data!r}")
PY

# Restore primitives must preserve the old destination on decryption failure and
# reject traversal/symlink escapes from HOME.
(
    # shellcheck disable=SC2329 # Called by sourced library functions.
    log_error() { :; }
    # shellcheck disable=SC2034 # Consumed while sourcing the library.
    BACKUP_FILES_DIR="backup-files"
    # shellcheck disable=SC2034 # Expanded while sourcing the library.
    METADATA_FILE="$LOCAL_REPO/backup-metadata.json"
    # shellcheck source=../dot_local/bin/lib/keys-manage/core.sh
    source "$ROOT/dot_local/bin/lib/keys-manage/core.sh"

    # openssl enc -aes-256-cbc is unauthenticated, so a wrong password is only
    # rejected when the decrypted final block fails its PKCS#7 padding check --
    # which a random key passes roughly 1 time in 256. Drive the
    # preserve-on-failure assertion with an injected openssl failure (as the
    # encrypt side below already does) instead of a wrong password, and assert
    # separately the property a wrong password always has: it can never
    # reproduce the original plaintext.
    mkdir -p "$TMP_ROOT/failing-bin"
    printf '#!/bin/sh\nexit 1\n' >"$TMP_ROOT/failing-bin/openssl"
    chmod +x "$TMP_ROOT/failing-bin/openssl"

    preserved="$TMP_ROOT/preserved-secret"
    printf '%s\n' "keep-me" >"$preserved"
    if PATH="$TMP_ROOT/failing-bin:$PATH" \
        decrypt_file "$LOCAL_REPO/backup-files/.ssh/main" "$preserved" "$PASS" 2>/dev/null; then
        echo "expected injected decryption failure" >&2
        exit 1
    fi
    [[ "$(cat "$preserved")" == "keep-me" ]]

    wrong_password_dest="$TMP_ROOT/wrong-password-output"
    if decrypt_file "$LOCAL_REPO/backup-files/.ssh/main" "$wrong_password_dest" "wrong-password" 2>/dev/null &&
        cmp -s "$wrong_password_dest" "$SECRET_FILE"; then
        echo "wrong-password decryption reproduced the plaintext" >&2
        exit 1
    fi
    rm -f "$wrong_password_dest"

    directory_dest="$TMP_ROOT/directory-destination"
    mkdir -p "$directory_dest"
    if decrypt_file "$LOCAL_REPO/backup-files/.ssh/main" "$directory_dest" "$PASS" 2>/dev/null; then
        echo "expected decryption to a directory to fail" >&2
        exit 1
    fi
    if encrypt_file "$SECRET_FILE" "$directory_dest" "$PASS" 2>/dev/null; then
        echo "expected encryption to a directory to fail" >&2
        exit 1
    fi
    if find "$directory_dest" -maxdepth 1 \
        \( -name '.keys-decrypt.*' -o -name '.keys-encrypt.*' \) \
        -print -quit | grep -q .; then
        echo "secret temp file leaked into destination directory" >&2
        exit 1
    fi

    encrypted_preserved="$TMP_ROOT/preserved-ciphertext"
    printf '%s\n' "last-good-ciphertext" >"$encrypted_preserved"
    if PATH="$TMP_ROOT/failing-bin:$PATH" encrypt_file "$SECRET_FILE" "$encrypted_preserved" "$PASS" 2>/dev/null; then
        echo "expected injected encryption failure" >&2
        exit 1
    fi
    [[ "$(cat "$encrypted_preserved")" == "last-good-ciphertext" ]]

    if get_absolute_path "backup-files/../outside" >/dev/null 2>&1; then
        echo "expected traversal restore path to be rejected" >&2
        exit 1
    fi

    outside="$TMP_ROOT/outside-home"
    mkdir -p "$outside"
    ln -s "$outside" "$HOME/escaped-parent"
    if restore_target_is_safe "$HOME/escaped-parent/secret"; then
        echo "expected symlink escape restore target to be rejected" >&2
        exit 1
    fi
)

# Global password-file works after the command as documented.
keys-manage verify --password-file "$password_file" >/dev/null

# Environment-provided passwords are captured and unset before any child process.
export REAL_OPENSSL
export OPENSSL_ENV_LOG="$TMP_ROOT/openssl-env.log"
cat >"$BIN/openssl" <<'EOF'
#!/usr/bin/env bash
if [[ -n "${KEYS_BACKUP_PASSWORD+x}" ]]; then
    echo set >"$OPENSSL_ENV_LOG"
else
    echo unset >"$OPENSSL_ENV_LOG"
fi
exec "$REAL_OPENSSL" "$@"
EOF
chmod +x "$BIN/openssl"
KEYS_BACKUP_PASSWORD="$PASS" keys-manage verify >/dev/null
[[ "$(cat "$OPENSSL_ENV_LOG")" == "unset" ]]

# History ordering: deterministic blocks, latest-first.
cat >"$LOCAL_REPO/backup-history.log" <<'LOG'
[2026-02-04T00:00:00Z] event a1
[2026-02-04T00:00:00Z] event a2
[2026-02-04T00:00:01Z] event b1
[2026-02-04T00:00:02Z] event c1
[2026-02-04T00:00:02Z] event c2
LOG

out="$(KEYS_BACKUP_PASSWORD="$PASS" keys-manage history 2)"

printf '%s' "$out" | grep -q "\\[2026-02-04T00:00:02Z\\]" || {
    echo "history output missing latest timestamp" >&2
    printf '%s\n' "$out" >&2
    exit 1
}

positions=$(printf '%s' "$out" | python3 -c 'import sys; s=sys.stdin.read(); print(s.find("[2026-02-04T00:00:02Z]")); print(s.find("[2026-02-04T00:00:01Z]"))')
latest_pos=$(echo "$positions" | sed -n '1p')
next_pos=$(echo "$positions" | sed -n '2p')

if [[ "$latest_pos" -lt 0 || "$next_pos" -lt 0 || "$latest_pos" -gt "$next_pos" ]]; then
    echo "history ordering check failed" >&2
    printf '%s\n' "$out" >&2
    exit 1
fi

# Remote missing should cause sync failure (require-online).
rm -rf "$REMOTE"
set +e
KEYS_BACKUP_PASSWORD="$PASS" keys-manage sync >/dev/null 2>&1
rc=$?
set -e

if [[ $rc -eq 0 ]]; then
    echo "expected keys-manage sync to fail when remote is missing" >&2
    exit 1
fi

echo "test_keys_manage_nonmenu: OK"
