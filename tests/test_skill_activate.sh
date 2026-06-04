#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
CLI="$ROOT/dot_local/bin/executable_skill-activate"

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/skill-activate-test.XXXXXX")"
cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

HOME_DIR="$TMP_ROOT/home"
LIBRARY="$TMP_ROOT/library"
mkdir -p "$HOME_DIR" "$LIBRARY"

fail() {
    echo "assertion failed: $*" >&2
    exit 1
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    [[ "$haystack" == *"$needle"* ]] || fail "expected output to contain: $needle"
}

assert_symlink_to() {
    local link="$1"
    local target="$2"
    [ -L "$link" ] || fail "expected symlink: $link"
    [ "$(readlink "$link")" = "$target" ] || fail "expected $link -> $target"
}

assert_missing() {
    local path="$1"
    [ ! -e "$path" ] || fail "expected missing path: $path"
}

make_skill() {
    local category="$1"
    local name="$2"
    local description="$3"
    local dir="$LIBRARY/$category/$name"
    mkdir -p "$dir"
    cat >"$dir/SKILL.md" <<EOF
---
name: $name
description: $description
---

# $name
EOF
}

run_skill_activate() {
    HOME="$HOME_DIR" SKILL_LIBRARY="$LIBRARY" bash "$CLI" "$@"
}

make_skill "typescript" "ts-one" "First TypeScript skill"
make_skill "typescript" "ts-two" "Second TypeScript skill"
make_skill "python" "py-one" "Python skill"

list_output="$(run_skill_activate user --list)"
assert_contains "$list_output" "typescript"
assert_contains "$list_output" "ts-one"
assert_contains "$list_output" "ts-two"

category_output="$(run_skill_activate user --category typescript)"
assert_contains "$category_output" "activated 2 skill(s) in category 'typescript'"
assert_symlink_to "$HOME_DIR/.claude/skills/ts-one" "$LIBRARY/typescript/ts-one"
assert_symlink_to "$HOME_DIR/.claude/skills/ts-two" "$LIBRARY/typescript/ts-two"
assert_symlink_to "$HOME_DIR/.codex/skills/ts-one" "$LIBRARY/typescript/ts-one"
assert_symlink_to "$HOME_DIR/.codex/skills/ts-two" "$LIBRARY/typescript/ts-two"
assert_missing "$HOME_DIR/.claude/skills/py-one"
assert_missing "$HOME_DIR/.codex/skills/py-one"

IDX="$TMP_ROOT/index.tsv"
{
    printf 'py-one\tpython\t%s\tPython skill\n' "$LIBRARY/python/py-one"
    printf 'ts-one\ttypescript\t%s\tFirst TypeScript skill\n' "$LIBRARY/typescript/ts-one"
    printf 'ts-two\ttypescript\t%s\tSecond TypeScript skill\n' "$LIBRARY/typescript/ts-two"
} >"$IDX"

run_skill_activate __toggle_category ts-one user "$IDX"
assert_missing "$HOME_DIR/.claude/skills/ts-one"
assert_missing "$HOME_DIR/.claude/skills/ts-two"
assert_missing "$HOME_DIR/.codex/skills/ts-one"
assert_missing "$HOME_DIR/.codex/skills/ts-two"

run_skill_activate __toggle_category ts-one user "$IDX"
assert_symlink_to "$HOME_DIR/.claude/skills/ts-one" "$LIBRARY/typescript/ts-one"
assert_symlink_to "$HOME_DIR/.claude/skills/ts-two" "$LIBRARY/typescript/ts-two"
assert_missing "$HOME_DIR/.claude/skills/py-one"

if run_skill_activate user --category missing >"$TMP_ROOT/missing.out" 2>"$TMP_ROOT/missing.err"; then
    fail "expected missing category to fail"
fi
assert_contains "$(cat "$TMP_ROOT/missing.err")" "category not found: missing"

echo "test_skill_activate: OK"
