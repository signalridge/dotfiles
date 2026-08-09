#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
for cmd in chezmoi python3 unzip; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "SKIP: $cmd not found" >&2
        exit 0
    }
done

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/pinned-downloads-test.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

version="$(chezmoi execute-template --source "$ROOT" '{{ .versions.azureFunctionsVersion }}')"
archive="$TMP_ROOT/func.zip"
mkdir -p "$TMP_ROOT/archive"
cat >"$TMP_ROOT/archive/func" <<EOF
#!/usr/bin/env bash
[[ "\${1:-}" == "--version" ]] || exit 2
printf '%s\n' "$version"
EOF
chmod +x "$TMP_ROOT/archive/func"
printf '#!/usr/bin/env bash\nexit 0\n' >"$TMP_ROOT/archive/gozip"
chmod +x "$TMP_ROOT/archive/gozip"
python3 - "$TMP_ROOT/archive" "$archive" <<'PY'
import pathlib
import sys
import zipfile

source = pathlib.Path(sys.argv[1])
with zipfile.ZipFile(sys.argv[2], "w") as zf:
    for path in source.iterdir():
        info = zipfile.ZipInfo(path.name)
        info.external_attr = (path.stat().st_mode & 0xFFFF) << 16
        zf.writestr(info, path.read_bytes())
PY
if command -v sha256sum >/dev/null 2>&1; then
    archive_sha="$(sha256sum "$archive" | awk '{print $1}')"
else
    archive_sha="$(shasum -a 256 "$archive" | awk '{print $1}')"
fi

mkdir -p "$TMP_ROOT/bin"
cat >"$TMP_ROOT/bin/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
out=""
while (($# > 0)); do
    case "$1" in
        -o) out="$2"; shift 2 ;;
        *) shift ;;
    esac
done
[[ -n "$out" ]]
printf 'download\n' >>"${AZURE_CURL_LOG:?}"
cp "${AZURE_TEST_ARCHIVE:?}" "$out"
EOF
chmod +x "$TMP_ROOT/bin/curl"

AZURE_SCRIPT="$TMP_ROOT/azure.sh"
chezmoi execute-template --source "$ROOT" --override-data '{"work":true}' \
    <"$ROOT/.chezmoiscripts/run_onchange_after_16_azure-functions-core-tools.sh.tmpl" >"$AZURE_SCRIPT"
chmod +x "$AZURE_SCRIPT"

export HOME="$TMP_ROOT/home"
export XDG_DATA_HOME="$TMP_ROOT/data"
export AZURE_TEST_ARCHIVE="$archive"
export AZURE_CURL_LOG="$TMP_ROOT/azure-curl.log"
: >"$AZURE_CURL_LOG"
export PATH="$TMP_ROOT/bin:$PATH"
mkdir -p "$HOME"
legacy_target="$XDG_DATA_HOME/azure-functions-core-tools/$version"
mkdir -p "$legacy_target"
cat >"$legacy_target/func" <<EOF
#!/usr/bin/env bash
printf '%s\n' "$version"
EOF
chmod +x "$legacy_target/func"
printf 'legacy\n' >"$legacy_target/unverified"
AZURE_FUNCTIONS_OVERRIDE_URL="https://example.invalid/func.zip" \
    AZURE_FUNCTIONS_OVERRIDE_SHA256="$archive_sha" \
    bash "$AZURE_SCRIPT" >/dev/null
[[ -x "$XDG_DATA_HOME/azure-functions-core-tools/$version/func" ]]
[[ "$("$HOME/.local/bin/func" --version)" == "$version" ]]
[[ "$(cat "$XDG_DATA_HOME/azure-functions-core-tools/$version/.archive.sha256")" == "$archive_sha" ]]
[[ ! -e "$XDG_DATA_HOME/azure-functions-core-tools/$version/unverified" ]]
[[ "$(wc -l <"$AZURE_CURL_LOG" | tr -d ' ')" == "1" ]]
AZURE_FUNCTIONS_OVERRIDE_URL="https://example.invalid/func.zip" \
    AZURE_FUNCTIONS_OVERRIDE_SHA256="$archive_sha" \
    bash "$AZURE_SCRIPT" >/dev/null
[[ "$(wc -l <"$AZURE_CURL_LOG" | tr -d ' ')" == "1" ]]

rm -rf "$XDG_DATA_HOME/azure-functions-core-tools" "$HOME/.local/bin/func"
set +e
AZURE_FUNCTIONS_OVERRIDE_URL="https://example.invalid/func.zip" \
    AZURE_FUNCTIONS_OVERRIDE_SHA256="$(printf '0%.0s' {1..64})" \
    bash "$AZURE_SCRIPT" >/dev/null 2>&1
bad_sha_rc=$?
set -e
[[ "$bad_sha_rc" -ne 0 ]]
[[ ! -e "$XDG_DATA_HOME/azure-functions-core-tools/$version" ]]

PAPERLIB_RENDERED="$TMP_ROOT/paperlib.sh"
chezmoi execute-template --source "$ROOT" \
    <"$ROOT/.chezmoiscripts/run_onchange_after_09_install-paperlib.sh.tmpl" >"$PAPERLIB_RENDERED"

# Execute the mismatch path and prove it stops before mounting/installing.
if command -v shasum >/dev/null 2>&1; then
    cat >"$TMP_ROOT/bin/hdiutil" <<'EOF'
#!/usr/bin/env bash
touch "${PAPERLIB_HDIUTIL_MARKER:?}"
exit 1
EOF
    chmod +x "$TMP_ROOT/bin/hdiutil"
    export PAPERLIB_HDIUTIL_MARKER="$TMP_ROOT/hdiutil-called"
    set +e
    bash "$PAPERLIB_RENDERED" >/dev/null 2>&1
    paperlib_bad_sha_rc=$?
    set -e
    [[ "$paperlib_bad_sha_rc" -ne 0 ]]
    [[ ! -e "$PAPERLIB_HDIUTIL_MARKER" ]]

    # A verified candidate replaces rather than merges with the old bundle, and
    # a post-swap verification failure restores the previous app.
    paperlib_volume="$TMP_ROOT/Volumes/Paperlib"
    applications_dir="$TMP_ROOT/Applications"
    PAPERLIB_REAL_MV="$(command -v mv)"
    export PAPERLIB_REAL_MV
    mkdir -p "$paperlib_volume/Paperlib.app" "$applications_dir/Paperlib.app"
    printf 'new\n' >"$paperlib_volume/Paperlib.app/new.txt"
    printf 'stale\n' >"$applications_dir/Paperlib.app/old-only.txt"
    export PAPERLIB_TEST_VOLUME="$paperlib_volume"
    cat >"$TMP_ROOT/bin/hdiutil" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
    attach) printf '/dev/disk-test\tApple_HFS\t%s\n' "${PAPERLIB_TEST_VOLUME:?}" ;;
    detach) exit 0 ;;
    *) exit 2 ;;
esac
EOF
    cat >"$TMP_ROOT/bin/file" <<'EOF'
#!/usr/bin/env bash
printf '%s: zlib compressed data\n' "${1:-file}"
EOF
    cat >"$TMP_ROOT/bin/ditto" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cp -R "$1" "$2"
EOF
    cat >"$TMP_ROOT/bin/codesign" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
path="${!#}"
if [[ "${PAPERLIB_FAIL_FINAL_VERIFY:-0}" == "1" \
    && "$path" == */Applications/Paperlib.app ]]; then
    exit 1
fi
exit 0
EOF
    chmod +x "$TMP_ROOT/bin/hdiutil" "$TMP_ROOT/bin/file" \
        "$TMP_ROOT/bin/ditto" "$TMP_ROOT/bin/codesign"

    PAPERLIB_OVERRIDE_SHA256="$archive_sha" \
        PAPERLIB_OVERRIDE_URL="https://example.invalid/Paperlib.dmg" \
        PAPERLIB_APPLICATIONS_DIR="$applications_dir" \
        bash "$PAPERLIB_RENDERED" >/dev/null
    [[ -f "$applications_dir/Paperlib.app/new.txt" ]]
    [[ ! -e "$applications_dir/Paperlib.app/old-only.txt" ]]

    rm -rf "$applications_dir/Paperlib.app"
    mkdir -p "$applications_dir/Paperlib.app"
    printf 'old\n' >"$applications_dir/Paperlib.app/old.txt"
    set +e
    PAPERLIB_FAIL_FINAL_VERIFY=1 \
        PAPERLIB_OVERRIDE_SHA256="$archive_sha" \
        PAPERLIB_OVERRIDE_URL="https://example.invalid/Paperlib.dmg" \
        PAPERLIB_APPLICATIONS_DIR="$applications_dir" \
        bash "$PAPERLIB_RENDERED" >/dev/null 2>&1
    rollback_rc=$?
    set -e
    [[ "$rollback_rc" -ne 0 ]]
    [[ -f "$applications_dir/Paperlib.app/old.txt" ]]
    [[ ! -e "$applications_dir/Paperlib.app/new.txt" ]]
    if find "$applications_dir" -maxdepth 1 \
        \( -name '.paperlib-install.*' -o -name '.paperlib-backup.*' \) \
        -print -quit | grep -q .; then
        echo "Paperlib transaction temp directory leaked" >&2
        exit 1
    fi

    rm -rf "$applications_dir/Paperlib.app"
    mkdir -p "$applications_dir/Paperlib.app"
    printf 'only-old-copy\n' >"$applications_dir/Paperlib.app/old.txt"
    cat >"$TMP_ROOT/bin/mv" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${PAPERLIB_FAIL_ROLLBACK:-0}" == "1" && "${1:-}" == *paperlib-backup* ]]; then
    exit 1
fi
exec "${PAPERLIB_REAL_MV:?}" "$@"
EOF
    chmod +x "$TMP_ROOT/bin/mv"
    set +e
    PAPERLIB_FAIL_FINAL_VERIFY=1 \
        PAPERLIB_FAIL_ROLLBACK=1 \
        PAPERLIB_OVERRIDE_SHA256="$archive_sha" \
        PAPERLIB_OVERRIDE_URL="https://example.invalid/Paperlib.dmg" \
        PAPERLIB_APPLICATIONS_DIR="$applications_dir" \
        bash "$PAPERLIB_RENDERED" >"$TMP_ROOT/rollback-failure.out" 2>&1
    rollback_failure_rc=$?
    set -e
    [[ "$rollback_failure_rc" -ne 0 ]]
    grep -Fq 'backup retained at' "$TMP_ROOT/rollback-failure.out"
    retained_backup="$(find "$applications_dir" -path '*/.paperlib-backup.*/Paperlib.app/old.txt' -print -quit)"
    [[ -f "$retained_backup" ]]
    rm -f "$TMP_ROOT/bin/mv"
fi

echo "test_pinned_downloads: OK"
