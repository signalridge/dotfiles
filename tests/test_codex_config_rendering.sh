#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

require_cmd() {
    command -v "$1" >/dev/null 2>&1
}

for c in bash chezmoi; do
    require_cmd "$c" || {
        echo "SKIP: missing dependency: $c" >&2
        exit 0
    }
done

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/codex-config-render.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

export HOME="$TMP_ROOT/home"
mkdir -p "$HOME/.config/chezmoi" "$HOME/.codex"

assert_file_contains() {
    local file="$1"
    local expected="$2"
    if ! grep -Fq "$expected" "$file"; then
        echo "expected to find: $expected" >&2
        echo "--- $file ---" >&2
        cat "$file" >&2
        exit 1
    fi
}

RENDERED="$TMP_ROOT/config.toml"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_codex/config.toml.tmpl" >"$RENDERED"

assert_file_contains "$RENDERED" 'model = "gpt-5.4"'
assert_file_contains "$RENDERED" 'model_reasoning_effort = "xhigh"'
assert_file_contains "$RENDERED" 'service_tier = "fast"'
assert_file_contains "$RENDERED" 'fast_mode = true'

echo "test_codex_config_rendering: OK"
