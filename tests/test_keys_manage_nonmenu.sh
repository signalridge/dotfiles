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

# Create a local working repo that tracks the bare remote.
mkdir -p "$LOCAL_REPO"
(
    cd "$LOCAL_REPO"
    git init -b main >/dev/null
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
{
    echo ".ssh/main"
    echo ".ssh/main.pub"
} >>"$LOCAL_REPO/backup-list.txt"

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

# Verify should succeed and must not crash.
KEYS_BACKUP_PASSWORD="$PASS" keys-manage verify >/dev/null

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
