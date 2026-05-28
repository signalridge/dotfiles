#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
CLI="$ROOT/dot_agents/skills/social-media/oss-x-post/scripts/social-post"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/social-post-test.XXXXXX")"

cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

assert_contains() {
    local haystack="$1"
    local needle="$2"
    if [[ "$haystack" != *"$needle"* ]]; then
        echo "assertion failed: expected output to contain: $needle" >&2
        echo "--- output ---" >&2
        printf '%s\n' "$haystack" >&2
        exit 1
    fi
}

bash -n "$CLI"

# usage exits non-zero by design; capture without tripping set -e.
help_output="$(bash "$CLI" --help 2>&1 || true)"
assert_contains "$help_output" "bluesky"
assert_contains "$help_output" "devto"
assert_contains "$help_output" "reddit"

body_file="$TMP_ROOT/body.md"
printf 'Shipped v2.0: faster builds, fewer deps.\n' >"$body_file"

bluesky_dry="$(bash "$CLI" bluesky --file "$body_file")"
assert_contains "$bluesky_dry" "DRY RUN"
assert_contains "$bluesky_dry" "bluesky"
assert_contains "$bluesky_dry" "crosspost -b --file"

# dev.to articles have no character limit.
devto_dry="$(bash "$CLI" devto --file "$body_file")"
assert_contains "$devto_dry" "(no limit)"

# Over-limit posts must be rejected (exit non-zero), even in dry-run.
long_file="$TMP_ROOT/long.txt"
python3 -c "print('x' * 300)" >"$long_file"
if bash "$CLI" x --file "$long_file" >/dev/null 2>&1; then
    echo "assertion failed: over-limit X post should have been rejected" >&2
    exit 1
fi

reddit_dry="$(bash "$CLI" reddit --subreddit rust --title "Built a thing" --file "$body_file")"
assert_contains "$reddit_dry" "reddit"
assert_contains "$reddit_dry" "tool:      reddit-submit"
assert_contains "$reddit_dry" "subreddit: rust"

# Reading from stdin (--file -) must not leave the child reading an empty stdin;
# the gate spools stdin to a tempfile internally.
stdin_dry="$(printf 'from stdin\n' | bash "$CLI" bluesky --file -)"
assert_contains "$stdin_dry" "DRY RUN"
# command substitution strips the trailing newline, so length is 10 not 11.
assert_contains "$stdin_dry" "length:    10 / 300"

echo "test_social_post_cli: OK"
