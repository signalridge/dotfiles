#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

require_cmd() {
    command -v "$1" >/dev/null 2>&1
}

for c in bash chezmoi jq; do
    require_cmd "$c" || {
        echo "SKIP: missing dependency: $c" >&2
        exit 0
    }
done

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/codex-model-test.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

export HOME="$TMP_ROOT/home"
mkdir -p "$HOME/.config/chezmoi" "$HOME/.codex"

BIN="$TMP_ROOT/bin"
STUB="$TMP_ROOT/stub"
mkdir -p "$BIN/lib/ai" "$BIN/lib" "$STUB"

# Render scripts/libs for isolated execution.
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/lib/common.tmpl" >"$BIN/lib/common"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/lib/ai/core.tmpl" >"$BIN/lib/ai/core"
cp "$ROOT/dot_local/bin/lib/ai/codex.tmpl" "$BIN/lib/ai/codex"
chezmoi execute-template --source "$ROOT" <"$ROOT/dot_local/bin/executable_codex-token.tmpl" >"$BIN/codex-token"
chmod +x "$BIN/lib/common" "$BIN/lib/ai/core" "$BIN/lib/ai/codex" "$BIN/codex-token"

cat >"$STUB/chezmoi" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "data" ]]; then
    cat <<'JSON'
{"claudeProviderAccount":"anthropic","codexProviderAccount":"deepseek@private"}
JSON
    exit 0
fi
if [[ "${1:-}" == "apply" ]]; then
    exit 0
fi
exit 0
EOF
chmod +x "$STUB/chezmoi"

assert_equals() {
    local actual="$1"
    local expected="$2"
    if [[ "$actual" != "$expected" ]]; then
        echo "expected: $expected" >&2
        echo "actual  : $actual" >&2
        exit 1
    fi
}

cat >"$HOME/.codex/config.toml" <<'EOF'
model_provider = "deepseek"
model = "deepseek-chat"

[model_providers.deepseek]
name = "DeepSeek"
base_url = "https://api.deepseek.com/v1"

[model_providers.kimi]
name = "Kimi"
base_url = "https://api.moonshot.ai/v1"
EOF

BASE_PATH="$STUB:$BIN:$PATH"

deepseek_model="$(
    PATH="$BASE_PATH" "$BIN/codex-token" --config deepseek@private | jq -r '.model'
)"
kimi_model="$(
    PATH="$BASE_PATH" "$BIN/codex-token" --config kimi@private | jq -r '.model'
)"
openai_model="$(
    PATH="$BASE_PATH" "$BIN/codex-token" --config openai | jq -r '.model'
)"

assert_equals "$deepseek_model" "deepseek-chat"
assert_equals "$kimi_model" "kimi-k2-0711-preview"
assert_equals "$openai_model" "gpt-5.3-codex"

echo "test_codex_model_selection: OK"
