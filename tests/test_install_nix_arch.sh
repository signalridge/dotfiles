#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

require_cmd() {
    command -v "$1" >/dev/null 2>&1
}

require_cmd chezmoi || {
    echo "SKIP: missing dependency: chezmoi" >&2
    exit 0
}

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/install-nix-arch-test.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

SCRIPT="$TMP_ROOT/install-nix.sh"
chezmoi execute-template --source "$ROOT" <"$ROOT/.chezmoiscripts/run_onchange_before_00_install-nix.sh.tmpl" >"$SCRIPT"

STUB="$TMP_ROOT/stub"
mkdir -p "$STUB"

cat >"$STUB/uname" <<'EOF'
#!/bin/sh
set -eu
case "${1:-}" in
  -s) printf '%s\n' "${UNAME_S:?}" ;;
  -m) printf '%s\n' "${UNAME_M:?}" ;;
  *) exit 1 ;;
esac
EOF

cat >"$STUB/sysctl" <<'EOF'
#!/bin/sh
set -eu
if [ "${1:-}" = "-n" ] && [ "${2:-}" = "hw.optional.arm64" ]; then
  printf '%s\n' "${SYSCTL_ARM64:-0}"
  exit 0
fi
exit 1
EOF

chmod +x "$STUB/uname" "$STUB/sysctl"

run_get_arch() {
    local os="$1"
    local cpu="$2"
    local rosetta_arm64="${3:-0}"

    PATH="$STUB:$PATH" UNAME_S="$os" UNAME_M="$cpu" SYSCTL_ARM64="$rosetta_arm64" \
        NIX_INSTALLER_RUN_MAIN=0 sh -c '. "$1"; get_arch' sh "$SCRIPT"
}

[[ "$(run_get_arch Linux x86_64)" == "x86_64-linux" ]] || {
    echo "Linux x86_64 mismatch" >&2
    exit 1
}
[[ "$(run_get_arch Linux arm64)" == "aarch64-linux" ]] || {
    echo "Linux arm64 mismatch" >&2
    exit 1
}
[[ "$(run_get_arch Darwin arm64)" == "aarch64-darwin" ]] || {
    echo "Darwin arm64 mismatch" >&2
    exit 1
}
[[ "$(run_get_arch Darwin x86_64 1)" == "aarch64-darwin" ]] || {
    echo "Darwin Rosetta mismatch" >&2
    exit 1
}

set +e
PATH="$STUB:$PATH" UNAME_S="Darwin" UNAME_M="x86_64" SYSCTL_ARM64="0" NIX_INSTALLER_RUN_MAIN=0 \
    sh -c '. "$1"; get_arch' sh "$SCRIPT" >/dev/null 2>&1
rc=$?
set -e
if [[ $rc -eq 0 ]]; then
    echo "expected unsupported Darwin x86_64 to fail" >&2
    exit 1
fi

expected_aarch64_darwin="$(chezmoi execute-template --source "$ROOT" '{{ .versions.nixInstallerAarch64DarwinSha256 }}')"
expected_aarch64_linux="$(chezmoi execute-template --source "$ROOT" '{{ .versions.nixInstallerAarch64LinuxSha256 }}')"
expected_x86_64_linux="$(chezmoi execute-template --source "$ROOT" '{{ .versions.nixInstallerX8664LinuxSha256 }}')"

[[ "$(
    NIX_INSTALLER_RUN_MAIN=0 sh -c '. "$1"; expected_sha256_for_arch aarch64-darwin' sh "$SCRIPT"
)" == "$expected_aarch64_darwin" ]] || {
    echo "aarch64-darwin sha256 mismatch" >&2
    exit 1
}
[[ "$(
    NIX_INSTALLER_RUN_MAIN=0 sh -c '. "$1"; expected_sha256_for_arch aarch64-linux' sh "$SCRIPT"
)" == "$expected_aarch64_linux" ]] || {
    echo "aarch64-linux sha256 mismatch" >&2
    exit 1
}
[[ "$(
    NIX_INSTALLER_RUN_MAIN=0 sh -c '. "$1"; expected_sha256_for_arch x86_64-linux' sh "$SCRIPT"
)" == "$expected_x86_64_linux" ]] || {
    echo "x86_64-linux sha256 mismatch" >&2
    exit 1
}

sample="$TMP_ROOT/sample"
printf 'sample installer bytes' >"$sample"
if command -v sha256sum >/dev/null 2>&1; then
    sample_sha="$(sha256sum "$sample" | awk '{print $1}')"
else
    sample_sha="$(shasum -a 256 "$sample" | awk '{print $1}')"
fi
NIX_INSTALLER_RUN_MAIN=0 sh -c '. "$1"; verify_sha256 "$2" "$3"' sh "$SCRIPT" "$sample" "$sample_sha"

set +e
NIX_INSTALLER_RUN_MAIN=0 sh -c '. "$1"; verify_sha256 "$2" "$3"' sh "$SCRIPT" "$sample" "0000000000000000000000000000000000000000000000000000000000000000" >/dev/null 2>&1
rc=$?
set -e
if [[ $rc -eq 0 ]]; then
    echo "expected sha256 mismatch to fail" >&2
    exit 1
fi

set +e
PATH="$STUB:$PATH" UNAME_S="Linux" UNAME_M="mips64" NIX_INSTALLER_RUN_MAIN=0 \
    sh -c '. "$1"; get_arch' sh "$SCRIPT" >/dev/null 2>&1
rc=$?
set -e
if [[ $rc -eq 0 ]]; then
    echo "expected unsupported CPU to fail" >&2
    exit 1
fi

# A failed updater, or one that returns success without reaching the pinned
# version, must leave run_onchange pending instead of being recorded as success.
UPGRADE_STUB="$TMP_ROOT/upgrade-stub"
mkdir -p "$UPGRADE_STUB"
cat >"$UPGRADE_STUB/nix" <<'EOF'
#!/bin/sh
printf '%s\n' 'nix (Nix) 0.0.0'
EOF
cat >"$UPGRADE_STUB/uname" <<'EOF'
#!/bin/sh
[ "${1:-}" = "-s" ] && { echo Linux; exit 0; }
exit 1
EOF
cat >"$UPGRADE_STUB/determinate-nixd" <<'EOF'
#!/bin/sh
exit 0
EOF
cat >"$UPGRADE_STUB/sudo" <<'EOF'
#!/bin/sh
exit "${NIX_TEST_SUDO_RC:-0}"
EOF
chmod +x "$UPGRADE_STUB/nix" "$UPGRADE_STUB/uname" \
    "$UPGRADE_STUB/determinate-nixd" "$UPGRADE_STUB/sudo"

set +e
PATH="$UPGRADE_STUB:/usr/bin:/bin" NIX_TEST_SUDO_RC=9 bash "$SCRIPT" >/dev/null 2>&1
upgrade_failed_rc=$?
PATH="$UPGRADE_STUB:/usr/bin:/bin" NIX_TEST_SUDO_RC=0 bash "$SCRIPT" >/dev/null 2>&1
wrong_version_rc=$?
set -e
[[ "$upgrade_failed_rc" -ne 0 ]] || {
    echo "expected failed Nix upgrade to return non-zero" >&2
    exit 1
}
[[ "$wrong_version_rc" -ne 0 ]] || {
    echo "expected post-upgrade version mismatch to return non-zero" >&2
    exit 1
}

# The cold-start age fallback must resolve the repository-pinned nixpkgs commit
# for both profile installation and ephemeral execution.
AGE_BIN="$TMP_ROOT/age-bin"
AGE_LOG="$TMP_ROOT/age-nix.log"
mkdir -p "$AGE_BIN" "$TMP_ROOT/age-home"
cat >"$AGE_BIN/nix" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${NIX_CALL_LOG:?}"
[[ " $* " != *" profile add "* ]]
EOF
chmod +x "$AGE_BIN/nix"
NIX_CALL_LOG="$AGE_LOG" HOME="$TMP_ROOT/age-home" PATH="$AGE_BIN:/usr/bin:/bin" \
    bash "$ROOT/.chezmoitemplates/shell/age_command_wrapper.sh" --version
nixpkgs_rev="$(awk '$1 == "nixpkgsBootstrapRev:" { print $2 }' "$ROOT/.chezmoidata/versions.yaml")"
[[ "$nixpkgs_rev" =~ ^[0-9a-f]{40}$ ]]
[[ "$(grep -Fc "github:NixOS/nixpkgs/${nixpkgs_rev}#age" "$AGE_LOG")" == "2" ]]

echo "test_install_nix_arch: OK"
