#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

require_cmd() {
    command -v "$1" >/dev/null 2>&1
}

for c in bash chezmoi grep python3 sed sort uniq; do
    require_cmd "$c" || {
        echo "SKIP: missing dependency: $c" >&2
        exit 0
    }
done

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/skill-library-test.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

assert_file_contains() {
    local file="$1"
    local needle="$2"
    if ! grep -Fq -- "$needle" "$file"; then
        echo "assertion failed: expected '$file' to contain: $needle" >&2
        exit 1
    fi
}

assert_file_not_contains() {
    local file="$1"
    local needle="$2"
    if grep -Fq -- "$needle" "$file"; then
        echo "assertion failed: expected '$file' to not contain: $needle" >&2
        exit 1
    fi
}

RENDERED="$TMP_ROOT/chezmoiexternal.toml"
chezmoi execute-template --source "$ROOT" <"$ROOT/.chezmoiexternal.toml.tmpl" >"$RENDERED"

duplicate_targets="$(
    grep -E '^\["\.harnesses/skills/' "$RENDERED" |
        sed -E 's/^\["([^"]+)".*/\1/' |
        sort |
        uniq -d
)"
if [ -n "$duplicate_targets" ]; then
    echo "assertion failed: duplicate external skill targets:" >&2
    printf '%s\n' "$duplicate_targets" >&2
    exit 1
fi

# External paths must match the currently pinned upstream trees. These assertions
# catch include/strip drift without downloading every archive in tests.
assert_file_contains "$RENDERED" '[".harnesses/skills/ai-llm/hugging-face-datasets"]'
assert_file_contains "$RENDERED" 'include = ["skills-*/skills/huggingface-datasets/**"]'
assert_file_contains "$RENDERED" '[".harnesses/skills/ai-llm/hugging-face-evaluation"]'
assert_file_contains "$RENDERED" 'include = ["skills-*/skills/huggingface-community-evals/**"]'
assert_file_contains "$RENDERED" '[".harnesses/skills/ai-llm/hugging-face-cli"]'
assert_file_contains "$RENDERED" 'include = ["skills-*/skills/hf-cli/**"]'
assert_file_contains "$RENDERED" '[".harnesses/skills/meta/skill-scanner"]'
assert_file_contains "$RENDERED" 'include = ["skills-*/skills/skill-scanner/**"]'
assert_file_contains "$RENDERED" '[".harnesses/skills/devtools/using-gh-cli"]'
assert_file_contains "$RENDERED" 'include = ["skills-*/.codex/skills/gh-cli/**"]'
assert_file_contains "$RENDERED" '[".harnesses/skills/mobile/expo-deployment"]'
assert_file_contains "$RENDERED" 'include = ["skills-*/plugins/expo/skills/expo-deployment/**"]'
assert_file_contains "$RENDERED" '[".harnesses/skills/cloud/azure-deploy"]'
assert_file_contains "$RENDERED" 'include = ["skills-*/.github/plugins/azure-skills/skills/azure-deploy/**"]'

assert_file_not_contains "$RENDERED" 'hugging-face-jobs'
assert_file_not_contains "$RENDERED" 'plugins/expo-deployment/skills'
assert_file_not_contains "$RENDERED" 'plugins/sentry-skills/skills/skill-scanner'
assert_file_not_contains "$RENDERED" 'plugins/gh-cli/skills/using-gh-cli'
assert_file_not_contains "$RENDERED" '.github/skills/azd-deployment'

# TypeScript is intentionally split by function instead of one oversized bucket.
assert_file_contains "$RENDERED" '[".harnesses/skills/ts-types/ts-allowjs-mixing"]'
assert_file_contains "$RENDERED" '[".harnesses/skills/ts-types/typescript-core"]'
assert_file_contains "$RENDERED" '[".harnesses/skills/frontend/react-best-practices"]'
assert_file_contains "$RENDERED" '[".harnesses/skills/frontend/next-best-practices"]'
assert_file_contains "$RENDERED" '[".harnesses/skills/frontend/ts-tanstack-query"]'
assert_file_contains "$RENDERED" '[".harnesses/skills/mobile/react-native-architecture"]'
assert_file_contains "$RENDERED" '[".harnesses/skills/node-backend/ts-nodejs-backend"]'
assert_file_contains "$RENDERED" '[".harnesses/skills/ts-data/ts-prisma"]'
assert_file_contains "$RENDERED" '[".harnesses/skills/ts-testing/ts-vitest"]'
assert_file_contains "$RENDERED" '[".harnesses/skills/build-tools/ts-turborepo"]'
assert_file_not_contains "$RENDERED" '[".harnesses/skills/typescript/'

VALIDATOR="$HOME/.codex/skills/.system/skill-creator/scripts/quick_validate.py"
if [ -f "$VALIDATOR" ]; then
    python3 "$VALIDATOR" "$ROOT/dot_harnesses/skills/social/oss-x-post" >/dev/null
    python3 "$VALIDATOR" "$ROOT/dot_harnesses/skills/media/remotion" >/dev/null
else
    echo "SKIP: missing Codex skill validator: $VALIDATOR" >&2
fi
assert_file_not_contains "$ROOT/dot_harnesses/skills/social/oss-x-post/SKILL.md" \
    'SKILL=~/.harnesses/skills/oss-x-post'

echo "test_skill_library: OK"
