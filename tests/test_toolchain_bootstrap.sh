#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

require_cmd() {
    command -v "$1" >/dev/null 2>&1
}

for c in bash chezmoi grep; do
    require_cmd "$c" || {
        echo "SKIP: missing dependency: $c" >&2
        exit 0
    }
done

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/toolchain-bootstrap-test.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

assert_file_contains() {
    local file="$1"
    local needle="$2"
    if ! grep -Fq -- "$needle" "$file"; then
        echo "assertion failed: expected '$file' to contain: $needle" >&2
        echo "--- file: $file ---" >&2
        cat "$file" >&2
        exit 1
    fi
}

assert_file_not_contains() {
    local file="$1"
    local needle="$2"
    if grep -Fq -- "$needle" "$file"; then
        echo "assertion failed: expected '$file' to not contain: $needle" >&2
        echo "--- file: $file ---" >&2
        cat "$file" >&2
        exit 1
    fi
}

RENDERED_MISE_INSTALL="$TMP_ROOT/run_onchange_after_07_mise-install.sh"
chezmoi execute-template \
    --source "$ROOT" \
    <"$ROOT/.chezmoiscripts/run_onchange_after_07_mise-install.sh.tmpl" \
    >"$RENDERED_MISE_INSTALL"

assert_file_contains "$ROOT/private_dot_config/aquaproj-aqua/aqua.yaml" 'jdx/mise@'
assert_file_not_contains "$ROOT/.chezmoidata/nix.yaml" '- mise # runtime/tool version manager'

assert_file_contains "$RENDERED_MISE_INSTALL" 'export AQUA_GLOBAL_CONFIG="$AQUA_CONFIG_PATH"'
assert_file_contains "$RENDERED_MISE_INSTALL" 'mise_cmd="$aqua_bin_dir/mise"'
assert_file_contains "$RENDERED_MISE_INSTALL" 'Error: aqua-managed mise not found'
assert_file_not_contains "$RENDERED_MISE_INSTALL" '$HOME/.nix-profile/bin/mise'
assert_file_not_contains "$RENDERED_MISE_INSTALL" 'source_nix_env.sh'
assert_file_not_contains "$RENDERED_MISE_INSTALL" 'Only use nix-installed mise'

assert_file_contains "$ROOT/dot_custom/eval.sh" 'aqua_mise_cmd='
assert_file_contains "$ROOT/dot_custom/eval.sh" 'jdx/mise@'
assert_file_not_contains "$ROOT/dot_custom/eval.sh" '*/aquaproj-aqua/bin/mise) return 0 ;;'

assert_file_not_contains "$ROOT/nix-config/flake.nix.tmpl" 'CGO_ENABLED = 1;'
assert_file_not_contains "$ROOT/nix-config/flake.nix.tmpl" 'nixpkgs direnv 2.37.1 enables external linking on Darwin but ships'

assert_file_contains "$ROOT/README.md" '5. `04` install pinned aqua installer/version'
assert_file_contains "$ROOT/README.md" '6. `05` install tools from `private_dot_config/aquaproj-aqua/aqua.yaml` (including `mise`)'
assert_file_contains "$ROOT/README.md" '7. `06` bootstrap gopass store (interactive clone)'
assert_file_contains "$ROOT/README.md" '8. `07` install runtimes/tools via aqua-managed `mise`'
assert_file_contains "$ROOT/README.ja.md" '5. `04` ピン留め済みの aqua installer/aqua をインストール'
assert_file_contains "$ROOT/README.ja.md" '6. `05` `private_dot_config/aquaproj-aqua/aqua.yaml` に基づいてツール（`mise` を含む）を導入'
assert_file_contains "$ROOT/README.ja.md" '7. `06` gopass ストアを初期化（対話式 clone）'
assert_file_contains "$ROOT/README.ja.md" '8. `07` aqua が提供する `mise` でランタイム/ツールを導入'
assert_file_contains "$ROOT/README.zh-CN.md" '5. `04` 安装固定版本的 aqua installer/aqua'
assert_file_contains "$ROOT/README.zh-CN.md" '6. `05` 根据 `private_dot_config/aquaproj-aqua/aqua.yaml` 安装工具（含 `mise`）'
assert_file_contains "$ROOT/README.zh-CN.md" '7. `06` 初始化 gopass store（交互式 clone）'
assert_file_contains "$ROOT/README.zh-CN.md" '8. `07` 通过 aqua 提供的 `mise` 安装 runtime 与工具'

echo "test_toolchain_bootstrap: OK"
