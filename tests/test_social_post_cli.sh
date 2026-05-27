#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
CLI="$ROOT/dot_local/bin/executable_social-post"
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

python3 -m py_compile "$CLI"

help_output="$(python3 "$CLI" --help)"
assert_contains "$help_output" "bluesky"
assert_contains "$help_output" "mastodon"
assert_contains "$help_output" "reddit"

body_file="$TMP_ROOT/body.md"
printf 'Shipped v2.0: faster builds, fewer deps.\n' >"$body_file"

bluesky_dry="$(python3 "$CLI" bluesky --file "$body_file" 2>/dev/null)"
assert_contains "$bluesky_dry" '"dry_run": true'
assert_contains "$bluesky_dry" '"platform": "bluesky"'
assert_contains "$bluesky_dry" '"-b"'

# dev.to articles have no character limit -> limit reported as null.
devto_dry="$(python3 "$CLI" devto --file "$body_file" 2>/dev/null)"
assert_contains "$devto_dry" '"limit": null'

# Over-limit posts must be rejected (exit non-zero) even in dry-run.
long_file="$TMP_ROOT/long.txt"
python3 -c "print('x' * 300)" >"$long_file"
if python3 "$CLI" x --file "$long_file" >/dev/null 2>&1; then
    echo "assertion failed: over-limit X post should have been rejected" >&2
    exit 1
fi

reddit_dry="$(python3 "$CLI" reddit --subreddit rust --title "Built a thing" --file "$body_file" 2>/dev/null)"
assert_contains "$reddit_dry" '"platform": "reddit"'
assert_contains "$reddit_dry" '"tool": "reddit-submit"'
assert_contains "$reddit_dry" '"subreddit": "rust"'

echo "test_social_post_cli: OK"
