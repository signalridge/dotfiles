#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
CLI="$ROOT/dot_agents/skills/social-media/oss-x-post/scripts/reddit-submit"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/reddit-submit-test.XXXXXX")"

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

help_output="$(bash "$CLI" --help)"
assert_contains "$help_output" "auth-url"
assert_contains "$help_output" "submit"

auth_output="$(
    bash "$CLI" auth-url \
        --client-id test_client \
        --redirect-uri http://localhost:8080/callback \
        --state fixed_state \
        2>/dev/null
)"
assert_contains "$auth_output" "response_type=code"
assert_contains "$auth_output" "duration=permanent"
assert_contains "$auth_output" "scope=identity+read+submit"

body_file="$TMP_ROOT/body.md"
printf 'This is a dry-run body.\n' >"$body_file"
dry_run_output="$(
    bash "$CLI" submit \
        --subreddit test \
        --title "Dry run title" \
        --body-file "$body_file" \
        2>/dev/null
)"
assert_contains "$dry_run_output" '"dry_run": true'
assert_contains "$dry_run_output" '"kind": "self"'
assert_contains "$dry_run_output" '"sr": "test"'

link_dry_run_output="$(
    bash "$CLI" submit \
        --subreddit r/test \
        --title "Dry run link" \
        --url "https://example.com/post" \
        2>/dev/null
)"
assert_contains "$link_dry_run_output" '"kind": "link"'
assert_contains "$link_dry_run_output" '"url": "https://example.com/post"'

echo "test_reddit_submit_cli: OK"
