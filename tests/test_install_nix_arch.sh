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
[[ "$(run_get_arch Darwin x86_64 0)" == "x86_64-darwin" ]] || {
    echo "Darwin x86_64 mismatch" >&2
    exit 1
}

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
