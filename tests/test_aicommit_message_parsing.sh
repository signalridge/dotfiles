#!/usr/bin/env bash
# Guards how aicommit (dot_custom/functions.sh) turns a provider's raw stdout
# into a commit subject. Both AI CLIs habitually wrap the message in a markdown
# code fence despite the prompt asking for the bare message; the fence line used
# to be taken as the message and then stripped to "" by the quote/backtick
# cleanup, so aicommit refused a perfectly good subject with a blank `got:`.
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

require_cmd() {
    command -v "$1" >/dev/null 2>&1
}

for c in zsh git; do
    require_cmd "$c" || {
        echo "SKIP: missing dependency: $c" >&2
        exit 0
    }
done

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/aicommit-test.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

REPO="$TMP_ROOT/repo"
BIN="$TMP_ROOT/bin"
mkdir -p "$REPO" "$BIN"

# A repo with something staged — aicommit bails out early otherwise.
git -C "$REPO" init -q
git -C "$REPO" config user.email test@example.com
git -C "$REPO" config user.name test
printf 'hello\n' >"$REPO/a.txt"
git -C "$REPO" add a.txt

# Stub provider. Emits whatever STUB_OUTPUT holds, so each case can reshape the
# reply without touching the function under test.
cat >"$BIN/claude" <<'STUB'
#!/usr/bin/env bash
cat >/dev/null # drain the prompt on stdin
printf '%b' "$STUB_OUTPUT"
STUB
chmod +x "$BIN/claude"

run_aicommit() {
    # zsh -f: functions.sh is a zsh file (zle/bindkey at top level); skip rc
    # files so the developer's own config cannot colour the result.
    (
        cd "$REPO" || exit 1
        PATH="$BIN:$PATH" zsh -f -c \
            "source '$ROOT/dot_custom/functions.sh' >/dev/null 2>&1; aicommit --dry-run claude" 2>&1
    )
}

assert_contains() {
    local haystack="$1" needle="$2" label="$3"
    if ! grep -Fq -- "$needle" <<<"$haystack"; then
        echo "FAIL [$label]: expected output to contain: $needle" >&2
        echo "got: $haystack" >&2
        exit 1
    fi
}

assert_not_contains() {
    local haystack="$1" needle="$2" label="$3"
    if grep -Fq -- "$needle" <<<"$haystack"; then
        echo "FAIL [$label]: expected output NOT to contain: $needle" >&2
        echo "got: $haystack" >&2
        exit 1
    fi
}

# 1. Fenced reply — the regression. The subject sits on line 2.
export STUB_OUTPUT='```\nchore(aqua): pin antigravity-cli\n```\n'
out="$(run_aicommit || true)" # refusal cases exit 1 by design; assert on text
assert_contains "$out" "chore(aqua): pin antigravity-cli" "fenced"
assert_not_contains "$out" "Refusing to commit" "fenced"

# 2. Language-tagged fence, as CLIs emit when they guess a syntax.
export STUB_OUTPUT='```text\nfix(shell): drop stale PATH entry\n```\n'
out="$(run_aicommit || true)" # refusal cases exit 1 by design; assert on text
assert_contains "$out" "fix(shell): drop stale PATH entry" "tagged fence"
assert_not_contains "$out" "Refusing to commit" "tagged fence"

# 3. Bare reply keeps working.
export STUB_OUTPUT='feat(nix): add darwin rebuild alias\n'
out="$(run_aicommit || true)" # refusal cases exit 1 by design; assert on text
assert_contains "$out" "feat(nix): add darwin rebuild alias" "bare"

# 4. The guard must still reject non-conventional noise — stripping fences is
#    not licence to commit a preamble or a stray warning.
export STUB_OUTPUT='Here is your commit message:\n'
out="$(run_aicommit || true)" # refusal cases exit 1 by design; assert on text
assert_contains "$out" "Refusing to commit" "preamble"

# 5. A fence wrapping noise is still noise.
export STUB_OUTPUT='```\nUpdated the aqua config\n```\n'
out="$(run_aicommit || true)" # refusal cases exit 1 by design; assert on text
assert_contains "$out" "Refusing to commit" "fenced noise"

echo "OK: tests/test_aicommit_message_parsing.sh"
