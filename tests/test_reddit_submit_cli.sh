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

# Dry-run must call out that post_requirements are not validated -- otherwise
# users get a clean dry-run and an unexpected --yes rejection.
assert_contains "$link_dry_run_output" 'post_requirements are NOT validated in dry-run'

# A body containing newlines must survive the payload-to-form derivation; the
# dry-run JSON preserves the raw text so we can assert on it.
multiline_body_file="$TMP_ROOT/multi.md"
printf 'line one\n\nline two with spaces\n' >"$multiline_body_file"
multi_dry_run_output="$(
    bash "$CLI" submit \
        --subreddit test \
        --title "Multi-line body" \
        --body-file "$multiline_body_file" \
        2>/dev/null
)"
assert_contains "$multi_dry_run_output" 'line one'
assert_contains "$multi_dry_run_output" 'line two with spaces'

# Forgotten value after a flag (e.g. `--subreddit --title foo`) must error.
if bash "$CLI" submit --subreddit --title "x" --body "y" >/dev/null 2>&1; then
    echo "assertion failed: missing value after --subreddit should have been rejected" >&2
    exit 1
fi

echo "test_reddit_submit_cli: OK"
