#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

command -v chezmoi >/dev/null 2>&1 || {
    echo "SKIP: chezmoi not found" >&2
    exit 0
}

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/cursor-agent-test.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

export HOME="$TMP_ROOT/home"
export XDG_DATA_HOME="$TMP_ROOT/data"
export TMPDIR="$TMP_ROOT/tmp"
mkdir -p "$HOME" "$XDG_DATA_HOME" "$TMPDIR" "$TMP_ROOT/bin" "$TMP_ROOT/archive/root"

RENDERED="$TMP_ROOT/cursor-agent.sh"
chezmoi execute-template --source "$ROOT" \
    <"$ROOT/.chezmoiscripts/run_after_15_cursor-agent.sh.tmpl" >"$RENDERED"
chmod +x "$RENDERED"

cat >"$TMP_ROOT/archive/root/cursor-agent" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ "${1:-}" == "--version" ]] || exit 2
printf 'smoke\n' >>"${CURSOR_TEST_SMOKE_LOG:?}"
[[ "${CURSOR_TEST_SMOKE_FAIL:-0}" != "1" ]] || exit 1
printf '%s\n' "cursor-agent test"
EOF
chmod +x "$TMP_ROOT/archive/root/cursor-agent"
tar -czf "$TMP_ROOT/agent.tar.gz" -C "$TMP_ROOT/archive" root
if command -v sha256sum >/dev/null 2>&1; then
    archive_sha="$(sha256sum "$TMP_ROOT/agent.tar.gz" | awk '{print $1}')"
else
    archive_sha="$(shasum -a 256 "$TMP_ROOT/agent.tar.gz" | awk '{print $1}')"
fi

cat >"$TMP_ROOT/bin/uname" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
    -s) echo Linux ;;
    -m) echo x86_64 ;;
    *) exit 1 ;;
esac
EOF

cat >"$TMP_ROOT/bin/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

out=""
while (($# > 0)); do
    case "$1" in
        -o)
            out="$2"
            shift 2
            ;;
        *) shift ;;
    esac
done
[[ -n "$out" ]]
printf 'download\n' >>"${CURSOR_TEST_DOWNLOAD_LOG:?}"
cp "${CURSOR_TEST_ARCHIVE:?}" "$out"
EOF
chmod +x "$TMP_ROOT/bin/uname" "$TMP_ROOT/bin/curl"

export PATH="$TMP_ROOT/bin:/usr/bin:/bin"
export CURSOR_TEST_ARCHIVE="$TMP_ROOT/agent.tar.gz"
export CURSOR_TEST_DOWNLOAD_LOG="$TMP_ROOT/download.log"
export CURSOR_TEST_SMOKE_LOG="$TMP_ROOT/smoke.log"
: >"$CURSOR_TEST_DOWNLOAD_LOG"
: >"$CURSOR_TEST_SMOKE_LOG"

valid_version="2026.07.09-a3815c0"
run_cursor() {
    local version="$1"
    local sha256="$2"
    CURSOR_AGENT_OVERRIDE_VERSION="$version" \
        CURSOR_AGENT_OVERRIDE_SHA256="$sha256" \
        CURSOR_AGENT_OVERRIDE_URL="https://example.invalid/cursor-agent.tar.gz" \
        bash "$RENDERED"
}

run_cursor "$valid_version" "$archive_sha" >/dev/null
install_root="$(cd "$XDG_DATA_HOME/cursor-agent/versions" && pwd -P)"
target="$install_root/$valid_version"
[[ -x "$target/cursor-agent" ]]
[[ "$(cat "$target/.archive.sha256")" == "$archive_sha" ]]
[[ "$(readlink "$HOME/.local/bin/cursor-agent")" == "$target/cursor-agent" ]]
[[ "$(readlink "$HOME/.local/bin/agent")" == "$target/cursor-agent" ]]
[[ "$(wc -l <"$CURSOR_TEST_DOWNLOAD_LOG" | tr -d ' ')" == "1" ]]
[[ "$(wc -l <"$CURSOR_TEST_SMOKE_LOG" | tr -d ' ')" == "1" ]]

# A verified existing install is reused without another download or execution.
run_cursor "$valid_version" "$archive_sha" >/dev/null
[[ "$(wc -l <"$CURSOR_TEST_DOWNLOAD_LOG" | tr -d ' ')" == "1" ]]
[[ "$(wc -l <"$CURSOR_TEST_SMOKE_LOG" | tr -d ' ')" == "1" ]]

# Pinned metadata must never turn path-like input into an rm -rf target.
: >"$CURSOR_TEST_DOWNLOAD_LOG"
set +e
run_cursor ".." "$archive_sha" >"$TMP_ROOT/invalid.out" 2>&1
invalid_rc=$?
set -e
[[ "$invalid_rc" -ne 0 ]]
[[ -x "$target/cursor-agent" ]]
[[ ! -s "$CURSOR_TEST_DOWNLOAD_LOG" ]]

# A bad checksum stops before extraction or execution and preserves the old link.
bad_hash_version="2026.07.10-bbbbbbb"
smoke_count_before="$(wc -l <"$CURSOR_TEST_SMOKE_LOG" | tr -d ' ')"
set +e
run_cursor "$bad_hash_version" "$(printf '0%.0s' {1..64})" >"$TMP_ROOT/hash.out" 2>&1
hash_rc=$?
set -e
[[ "$hash_rc" -ne 0 ]]
[[ ! -e "$install_root/$bad_hash_version" ]]
[[ "$(wc -l <"$CURSOR_TEST_SMOKE_LOG" | tr -d ' ')" == "$smoke_count_before" ]]
[[ "$(readlink "$HOME/.local/bin/cursor-agent")" == "$target/cursor-agent" ]]

# Even verified bytes must pass a smoke test before replacing the working version.
next_version="2026.07.11-ccccccc"
set +e
CURSOR_TEST_SMOKE_FAIL=1 run_cursor "$next_version" "$archive_sha" >"$TMP_ROOT/smoke.out" 2>&1
smoke_rc=$?
set -e
[[ "$smoke_rc" -ne 0 ]]
[[ ! -e "$install_root/$next_version" ]]
[[ "$(readlink "$HOME/.local/bin/cursor-agent")" == "$target/cursor-agent" ]]
if find "$install_root" -maxdepth 1 -name '.tmp-*' -print -quit | grep -q .; then
    echo "temporary install directory leaked" >&2
    exit 1
fi
if find "$TMPDIR" -maxdepth 1 -name 'cursor-agent.tar.gz.*' -print -quit | grep -q .; then
    echo "temporary archive leaked" >&2
    exit 1
fi

echo "test_cursor_agent_install: OK"
