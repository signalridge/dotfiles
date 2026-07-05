#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

section_block() {
    local file="$1"
    local section="$2"
    awk -v section="$section" '
        $0 ~ "^    " section ":$" { in_section = 1; next }
        in_section && $0 ~ "^    [^[:space:]][^:]*:" { exit }
        in_section { print }
    ' "$file"
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    if ! grep -Fq -- "$needle" <<<"$haystack"; then
        echo "expected block to contain: $needle" >&2
        echo "$haystack" >&2
        exit 1
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    if grep -Fq -- "$needle" <<<"$haystack"; then
        echo "expected block not to contain: $needle" >&2
        echo "$haystack" >&2
        exit 1
    fi
}

aerospace_shared="$(section_block "$ROOT/.chezmoidata/aerospace.yaml" shared)"
aerospace_private="$(section_block "$ROOT/.chezmoidata/aerospace.yaml" private)"
assert_contains "$aerospace_shared" "com.raycast.macos"
assert_not_contains "$aerospace_private" "com.raycast.macos"

hammerspoon_shared="$(section_block "$ROOT/.chezmoidata/hammerspoon.yaml" shared)"
hammerspoon_work="$(section_block "$ROOT/.chezmoidata/hammerspoon.yaml" work)"
assert_not_contains "$hammerspoon_shared" "app: DBeaver"
assert_contains "$hammerspoon_work" "app: DBeaver"

doubao_account="$(
    awk '
        /^    doubao@private:$/ { in_section = 1; next }
        in_section && /^    [^[:space:]][^:]*:$/ { exit }
        in_section { print }
    ' "$ROOT/.chezmoidata/claude.yaml"
)"
assert_contains "$doubao_account" "model: ark-code-latest"
assert_contains "$doubao_account" "small_model: ark-code-latest"
assert_contains "$doubao_account" "haiku_model: ark-code-latest"
assert_contains "$doubao_account" "sonnet_model: ark-code-latest"
assert_contains "$doubao_account" "opus_model: ark-code-latest"
assert_not_contains "$doubao_account" "kimi-k2.5"

glm_provider="$(section_block "$ROOT/.chezmoidata/claude.yaml" glm)"
newapi_provider="$(section_block "$ROOT/.chezmoidata/claude.yaml" newapi)"
newapi_account="$(
    awk '
        /^    newapi@private:$/ { in_section = 1; next }
        in_section && /^    [^[:space:]][^:]*:$/ { exit }
        in_section { print }
    ' "$ROOT/.chezmoidata/claude.yaml"
)"
assert_contains "$glm_provider" "base_url: https://api.z.ai/api/anthropic"
assert_not_contains "$glm_provider" "newapi.3689403.xyz"
assert_contains "$newapi_provider" "base_url: https://newapi.3689403.xyz/"
assert_contains "$newapi_account" "provider: newapi"
assert_contains "$newapi_account" "model: glm-5.2"
assert_contains "$newapi_account" "auto_compact_window: 1000000"

echo "test_profile_alignment: OK"
