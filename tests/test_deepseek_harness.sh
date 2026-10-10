#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/deepseek-harness-test.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin/lib" "$tmp/home" "$tmp/workspace"
cp "$ROOT/dot_local/bin/executable_dsh-with" "$tmp/bin/dsh-with"
cp "$ROOT/dot_local/bin/lib/common" "$tmp/bin/lib/common"
cat >"$tmp/bin/mise" <<'STUB'
#!/usr/bin/env bash
printf 'key=%s\ncwd=%s\n' "${CLIPROXY_API_KEY:-}" "$PWD"
printf 'arg=%s\n' "$@"
exit "${TEST_DSH_EXIT:-0}"
STUB
cat >"$tmp/bin/gopass" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$TEST_GOPASS_LOG"
[[ "${TEST_GOPASS_FAIL:-0}" != 1 ]] || exit 1
[[ "$*" == "show -o ${DSH_GOPASS_PATH:-claude/cliproxy/private/api_key}" ]] || exit 1
printf 'test-only-deepseek-key\n'
STUB
chmod +x "$tmp/bin/"{dsh-with,mise,gopass}
export HOME="$tmp/home" PATH="$tmp/bin:/usr/bin:/bin"
export XDG_CONFIG_HOME="$HOME/.config" TEST_GOPASS_LOG="$tmp/gopass.log"
unset CLIPROXY_API_KEY DSH_GOPASS_PATH AQUA_CONFIG AQUA_GLOBAL_CONFIG AQUA_ROOT_DIR XDG_DATA_HOME PASSWORD_STORE_DIR || true
cd "$tmp/workspace"

bash -n "$tmp/bin/dsh-with"
"$tmp/bin/dsh-with" >"$tmp/default"
grep -Fxq 'key=test-only-deepseek-key' "$tmp/default"
grep -Fxq "cwd=$PWD" "$tmp/default"
grep -Fxq 'arg=web' "$tmp/default"
grep -Fxq 'show -o claude/cliproxy/private/api_key' "$TEST_GOPASS_LOG"

: >"$TEST_GOPASS_LOG"
CLIPROXY_API_KEY=caller-key "$tmp/bin/dsh-with" headless 'one argument with spaces' >"$tmp/env"
grep -Fxq 'key=caller-key' "$tmp/env"
grep -Fxq 'arg=one argument with spaces' "$tmp/env"
[[ ! -s "$TEST_GOPASS_LOG" ]]

DSH_GOPASS_PATH=claude/cliproxy/work/api_key "$tmp/bin/dsh-with" web --no-open >"$tmp/custom"
grep -Fxq 'show -o claude/cliproxy/work/api_key' "$TEST_GOPASS_LOG"
grep -Fxq 'arg=--no-open' "$tmp/custom"

: >"$TEST_GOPASS_LOG"
for flag in --version --help --dump-config --dump-default-config --dump-config-schema; do
    TEST_GOPASS_FAIL=1 "$tmp/bin/dsh-with" "$flag" >/dev/null
    [[ ! -s "$TEST_GOPASS_LOG" ]]
done

if TEST_GOPASS_FAIL=1 "$tmp/bin/dsh-with" web >"$tmp/failure" 2>&1; then
    echo 'FAIL: missing credentials must fail closed' >&2
    exit 1
fi
if grep -Eq 'test-only-deepseek-key|arg=' "$tmp/failure"; then
    echo 'FAIL: credentials failure leaked a key or launched dsh' >&2
    exit 1
fi

set +e
CLIPROXY_API_KEY=caller-key TEST_DSH_EXIT=7 "$tmp/bin/dsh-with" headless task >/dev/null
rc=$?
set -e
[[ "$rc" -eq 7 ]]
grep -Fq '"npm:@deepseek-ai/dsh" = "0.2.0-rc.2"' "$ROOT/private_dot_config/mise/config.toml.tmpl"
grep -Fq 'enabled: false' "$ROOT/dot_dsh/cordis.patch.yml"
grep -Fq 'mode: DISABLED' "$ROOT/dot_dsh/cordis.patch.yml"
grep -Fq 'api: openai-responses' "$ROOT/dot_dsh/cordis.patch.yml"
grep -Fq 'baseURL: http://127.0.0.1:8317/v1' "$ROOT/dot_dsh/cordis.patch.yml"
grep -Fq 'apiKeyEnv: CLIPROXY_API_KEY' "$ROOT/dot_dsh/cordis.patch.yml"
grep -Fq 'provider: cliproxy' "$ROOT/dot_dsh/cordis.patch.yml"
grep -Fq 'model: gpt-6.1-sol' "$ROOT/dot_dsh/cordis.patch.yml"
grep -Fq 'reasoningEffort: high' "$ROOT/dot_dsh/cordis.patch.yml"
if grep -Eq 'anthropic-messages|/anthropic' "$ROOT/dot_dsh/cordis.patch.yml"; then
    echo 'FAIL: the OAuth proxy route must use OpenAI, not Anthropic' >&2
    exit 1
fi
echo 'test_deepseek_harness: OK'
