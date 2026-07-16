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

tpm_rev="$(chezmoi execute-template --source "$ROOT" '{{ .versions.tpmRev }}')"
tpm_sha="$(chezmoi execute-template --source "$ROOT" '{{ .versions.tpmSha256 }}')"
[[ "$tpm_rev" =~ ^[0-9a-f]{40}$ ]]
[[ "$tpm_sha" =~ ^[0-9a-f]{64}$ ]]
assert_file_contains "$RENDERED" "https://github.com/tmux-plugins/tpm/archive/${tpm_rev}.tar.gz"
assert_file_contains "$RENDERED" "checksum.sha256 = \"${tpm_sha}\""
assert_file_not_contains "$RENDERED" 'tmux-plugins/tpm/archive/refs/heads/master'

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
assert_file_contains "$RENDERED" '[".harnesses/skills/typescript/expo-deployment"]'
assert_file_contains "$RENDERED" 'include = ["skills-*/plugins/expo/skills/expo-deployment/**"]'
assert_file_contains "$RENDERED" '[".harnesses/skills/cloud/azure-deploy"]'
assert_file_contains "$RENDERED" 'include = ["skills-*/.github/plugins/azure-skills/skills/azure-deploy/**"]'
assert_file_contains "$RENDERED" '[".harnesses/skills/product/create-prd"]'
assert_file_contains "$RENDERED" 'include = ["pm-skills-*/pm-execution/skills/create-prd/**"]'
assert_file_contains "$RENDERED" '[".harnesses/skills/product/opportunity-solution-tree"]'
assert_file_contains "$RENDERED" 'include = ["pm-skills-*/pm-product-discovery/skills/opportunity-solution-tree/**"]'
assert_file_contains "$RENDERED" '[".harnesses/skills/product/intended-vs-implemented"]'
assert_file_contains "$RENDERED" 'include = ["pm-skills-*/pm-ai-shipping/skills/intended-vs-implemented/**"]'

assert_file_not_contains "$RENDERED" 'hugging-face-jobs'
assert_file_not_contains "$RENDERED" 'plugins/expo-deployment/skills'
assert_file_not_contains "$RENDERED" 'plugins/sentry-skills/skills/skill-scanner'
assert_file_not_contains "$RENDERED" 'plugins/gh-cli/skills/using-gh-cli'
assert_file_not_contains "$RENDERED" '.github/skills/azd-deployment'

# TypeScript/JavaScript skills intentionally stay in one category so the whole
# family can be enabled as a unit from skill-activate.
assert_file_contains "$RENDERED" '[".harnesses/skills/typescript/ts-allowjs-mixing"]'
assert_file_contains "$RENDERED" '[".harnesses/skills/typescript/typescript-core"]'
assert_file_contains "$RENDERED" '[".harnesses/skills/typescript/react-best-practices"]'
assert_file_contains "$RENDERED" '[".harnesses/skills/typescript/next-best-practices"]'
assert_file_contains "$RENDERED" '[".harnesses/skills/typescript/ts-tanstack-query"]'
assert_file_contains "$RENDERED" '[".harnesses/skills/typescript/react-native-architecture"]'
assert_file_contains "$RENDERED" '[".harnesses/skills/typescript/ts-nodejs-backend"]'
assert_file_contains "$RENDERED" '[".harnesses/skills/typescript/ts-prisma"]'
assert_file_contains "$RENDERED" '[".harnesses/skills/typescript/ts-vitest"]'
assert_file_contains "$RENDERED" '[".harnesses/skills/typescript/ts-turborepo"]'
assert_file_not_contains "$RENDERED" '[".harnesses/skills/ts-types/'
assert_file_not_contains "$RENDERED" '[".harnesses/skills/ts-data/'
assert_file_not_contains "$RENDERED" '[".harnesses/skills/ts-testing/'
assert_file_not_contains "$RENDERED" '[".harnesses/skills/node-backend/ts-nodejs-backend"]'
assert_file_not_contains "$RENDERED" '[".harnesses/skills/build-tools/ts-turborepo"]'
assert_file_not_contains "$RENDERED" '[".harnesses/skills/frontend/ts-tanstack-query"]'
assert_file_not_contains "$RENDERED" '[".harnesses/skills/mobile/react-native-architecture"]'

python3 "$ROOT/tests/validate_skill_frontmatter.py" "$ROOT/dot_harnesses/skills" >/dev/null
assert_file_not_contains "$ROOT/dot_harnesses/skills/social/oss-x-post/SKILL.md" \
    'SKILL=~/.harnesses/skills/oss-x-post'

echo "test_skill_library: OK"
