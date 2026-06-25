#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/dot_local/bin/executable_mcp-postgres"

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/mcp-postgres-test.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

assert_contains() {
    local haystack="$1"
    local needle="$2"
    if [[ "$haystack" != *"$needle"* ]]; then
        echo "expected output to contain: $needle" >&2
        echo "$haystack" >&2
        exit 1
    fi
}

BIN="$TMP_ROOT/bin"
mkdir -p "$BIN"
LOG="$TMP_ROOT/bunx.log"
cat >"$BIN/bunx" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'bunx' >"${MCP_POSTGRES_TEST_LOG:?}"
for arg in "$@"; do
    printf ' %s' "$arg" >>"${MCP_POSTGRES_TEST_LOG:?}"
done
printf '\n' >>"${MCP_POSTGRES_TEST_LOG:?}"
EOF
chmod +x "$BIN/bunx"

set +e
disabled_output="$(
    PATH="$BIN:$PATH" PG_DSN="postgresql://user:pass@localhost/db" bash "$SCRIPT" 2>&1
)"
disabled_rc=$?
set -e

if [[ "$disabled_rc" -eq 0 ]]; then
    echo "expected deprecated Postgres MCP wrapper to fail closed by default" >&2
    exit 1
fi
assert_contains "$disabled_output" "disabled by default"
[[ ! -f "$LOG" ]] || {
    echo "bunx should not be invoked when wrapper is disabled" >&2
    cat "$LOG" >&2
    exit 1
}

PATH="$BIN:$PATH" \
    PG_DSN="postgresql://user:pass@localhost/db" \
    MCP_POSTGRES_ALLOW_DEPRECATED_REFERENCE=1 \
    MCP_POSTGRES_TEST_LOG="$LOG" \
    bash "$SCRIPT" --transport stdio >/dev/null 2>&1

assert_contains "$(cat "$LOG")" "bunx @modelcontextprotocol/server-postgres@0.6.2 postgresql://user:pass@localhost/db --transport stdio"

echo "test_mcp_postgres_wrapper: OK"
