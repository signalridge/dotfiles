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

[[ "$(
    NIX_INSTALLER_RUN_MAIN=0 sh -c '. "$1"; expected_sha256_for_arch aarch64-darwin' sh "$SCRIPT"
)" == "17c0845f0133c9544b293449d853f5873ef9692b61cea1fe2ddf3b3a2500b81b" ]] || {
    echo "aarch64-darwin sha256 mismatch" >&2
    exit 1
}
[[ "$(
    NIX_INSTALLER_RUN_MAIN=0 sh -c '. "$1"; expected_sha256_for_arch aarch64-linux' sh "$SCRIPT"
)" == "0b2321832c1bf10503c6b299b382bd70b00023771650c93efbf1ba4c99de8284" ]] || {
    echo "aarch64-linux sha256 mismatch" >&2
    exit 1
}
[[ "$(
    NIX_INSTALLER_RUN_MAIN=0 sh -c '. "$1"; expected_sha256_for_arch x86_64-linux' sh "$SCRIPT"
)" == "b7961969faefef53e5bc5a6986fd50a09b1ea3e04578ff58c5408edb0d4113b0" ]] || {
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

echo "test_install_nix_arch: OK"
