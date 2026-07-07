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

run_skill_activate_in() {
    local workdir="$1"
    shift
    HOME="$HOME_DIR" SKILL_LIBRARY="$LIBRARY" bash -c 'cd "$1" && shift && bash "$@"' bash "$workdir" "$CLI" "$@"
}

make_skill "typescript" "ts-one" "First TypeScript skill"
make_skill "typescript" "ts-two" "Second TypeScript skill"
make_skill "python" "py-one" "Python skill"

help_output="$(bash "$CLI" --help)"
assert_contains "$help_output" "Ctrl-A flips"
assert_contains "$help_output" "every skill in the highlighted row's category"
assert_contains "$help_output" "skill-activate --category <category>"
assert_contains "$help_output" "skill-activate --sync"
assert_contains "$help_output" "current directory: ./.claude/skills/ + ./.codex/skills/ + ./.pi/skills/ + ./.cursor/skills/"

PROJECT_DIR="$TMP_ROOT/project"
mkdir -p "$PROJECT_DIR"

list_output="$(run_skill_activate_in "$PROJECT_DIR" --list)"
assert_contains "$list_output" "typescript"
assert_contains "$list_output" "ts-one"
assert_contains "$list_output" "ts-two"

category_output="$(run_skill_activate_in "$PROJECT_DIR" --category typescript)"
assert_contains "$category_output" "activated 2 skill(s) in category 'typescript'"
assert_symlink_to "$PROJECT_DIR/.claude/skills/ts-one" "$LIBRARY/typescript/ts-one"
assert_symlink_to "$PROJECT_DIR/.claude/skills/ts-two" "$LIBRARY/typescript/ts-two"
assert_symlink_to "$PROJECT_DIR/.codex/skills/ts-one" "$LIBRARY/typescript/ts-one"
assert_symlink_to "$PROJECT_DIR/.codex/skills/ts-two" "$LIBRARY/typescript/ts-two"
assert_symlink_to "$PROJECT_DIR/.pi/skills/ts-one" "$LIBRARY/typescript/ts-one"
assert_symlink_to "$PROJECT_DIR/.pi/skills/ts-two" "$LIBRARY/typescript/ts-two"
assert_symlink_to "$PROJECT_DIR/.cursor/skills/ts-one" "$LIBRARY/typescript/ts-one"
assert_symlink_to "$PROJECT_DIR/.cursor/skills/ts-two" "$LIBRARY/typescript/ts-two"
assert_missing "$PROJECT_DIR/.claude/skills/py-one"
assert_missing "$PROJECT_DIR/.codex/skills/py-one"
assert_missing "$PROJECT_DIR/.pi/skills/py-one"
assert_missing "$PROJECT_DIR/.cursor/skills/py-one"
assert_missing "$HOME_DIR/.claude/skills/ts-one"
assert_missing "$HOME_DIR/.codex/skills/ts-one"
assert_missing "$HOME_DIR/.cursor/skills/ts-one"
assert_missing "$PROJECT_DIR/.harnesses/skills/ts-one"
assert_missing "$PROJECT_DIR/.harnesses/skills/ts-two"

legacy_project_output="$(run_skill_activate_in "$PROJECT_DIR" project --category python)"
assert_contains "$legacy_project_output" "activated 1 skill(s) in category 'python'"
assert_symlink_to "$PROJECT_DIR/.claude/skills/py-one" "$LIBRARY/python/py-one"
assert_symlink_to "$PROJECT_DIR/.codex/skills/py-one" "$LIBRARY/python/py-one"
assert_symlink_to "$PROJECT_DIR/.pi/skills/py-one" "$LIBRARY/python/py-one"
assert_symlink_to "$PROJECT_DIR/.cursor/skills/py-one" "$LIBRARY/python/py-one"

if run_skill_activate_in "$PROJECT_DIR" user --category typescript >"$TMP_ROOT/user.out" 2>"$TMP_ROOT/user.err"; then
    fail "expected user scope to fail"
fi
assert_contains "$(cat "$TMP_ROOT/user.err")" "user scope was removed"
assert_missing "$HOME_DIR/.claude/skills/ts-two"
assert_missing "$HOME_DIR/.codex/skills/ts-two"

IDX="$TMP_ROOT/index.tsv"
{
    printf 'py-one\tpython\t%s\tPython skill\n' "$LIBRARY/python/py-one"
    printf 'ts-one\ttypescript\t%s\tFirst TypeScript skill\n' "$LIBRARY/typescript/ts-one"
    printf 'ts-two\ttypescript\t%s\tSecond TypeScript skill\n' "$LIBRARY/typescript/ts-two"
} >"$IDX"

PARTIAL_DIR="$TMP_ROOT/partial-project"
mkdir -p "$PARTIAL_DIR/.claude/skills"
ln -sfn "$LIBRARY/typescript/ts-one" "$PARTIAL_DIR/.claude/skills/ts-one"
partial_list_output="$(run_skill_activate_in "$PARTIAL_DIR" --list)"
assert_contains "$partial_list_output" "◐"
sync_output="$(run_skill_activate_in "$PARTIAL_DIR" --sync)"
assert_contains "$sync_output" "synced 1 partial skill(s)"
assert_symlink_to "$PARTIAL_DIR/.claude/skills/ts-one" "$LIBRARY/typescript/ts-one"
assert_symlink_to "$PARTIAL_DIR/.codex/skills/ts-one" "$LIBRARY/typescript/ts-one"
assert_symlink_to "$PARTIAL_DIR/.pi/skills/ts-one" "$LIBRARY/typescript/ts-one"
assert_symlink_to "$PARTIAL_DIR/.cursor/skills/ts-one" "$LIBRARY/typescript/ts-one"
assert_missing "$HOME_DIR/.claude/skills/ts-one"
assert_missing "$HOME_DIR/.codex/skills/ts-one"
rm -f "$PARTIAL_DIR/.codex/skills/ts-one"
run_skill_activate_in "$PARTIAL_DIR" __toggle ts-one "$IDX"
assert_symlink_to "$PARTIAL_DIR/.claude/skills/ts-one" "$LIBRARY/typescript/ts-one"
assert_symlink_to "$PARTIAL_DIR/.codex/skills/ts-one" "$LIBRARY/typescript/ts-one"
assert_symlink_to "$PARTIAL_DIR/.cursor/skills/ts-one" "$LIBRARY/typescript/ts-one"

PARTIAL_CATEGORY_DIR="$TMP_ROOT/partial-category-project"
mkdir -p "$PARTIAL_CATEGORY_DIR/.claude/skills"
ln -sfn "$LIBRARY/typescript/ts-one" "$PARTIAL_CATEGORY_DIR/.claude/skills/ts-one"
ln -sfn "$LIBRARY/typescript/ts-two" "$PARTIAL_CATEGORY_DIR/.claude/skills/ts-two"
run_skill_activate_in "$PARTIAL_CATEGORY_DIR" __toggle_category ts-one "$IDX"
assert_symlink_to "$PARTIAL_CATEGORY_DIR/.claude/skills/ts-one" "$LIBRARY/typescript/ts-one"
assert_symlink_to "$PARTIAL_CATEGORY_DIR/.claude/skills/ts-two" "$LIBRARY/typescript/ts-two"
assert_symlink_to "$PARTIAL_CATEGORY_DIR/.codex/skills/ts-one" "$LIBRARY/typescript/ts-one"
assert_symlink_to "$PARTIAL_CATEGORY_DIR/.codex/skills/ts-two" "$LIBRARY/typescript/ts-two"
assert_symlink_to "$PARTIAL_CATEGORY_DIR/.cursor/skills/ts-one" "$LIBRARY/typescript/ts-one"
assert_symlink_to "$PARTIAL_CATEGORY_DIR/.cursor/skills/ts-two" "$LIBRARY/typescript/ts-two"

run_skill_activate_in "$PROJECT_DIR" __toggle_category ts-one "$IDX"
assert_missing "$HOME_DIR/.claude/skills/ts-one"
assert_missing "$HOME_DIR/.claude/skills/ts-two"
assert_missing "$HOME_DIR/.codex/skills/ts-one"
assert_missing "$HOME_DIR/.codex/skills/ts-two"
assert_missing "$PROJECT_DIR/.claude/skills/ts-one"
assert_missing "$PROJECT_DIR/.claude/skills/ts-two"
assert_missing "$PROJECT_DIR/.codex/skills/ts-one"
assert_missing "$PROJECT_DIR/.codex/skills/ts-two"
assert_missing "$PROJECT_DIR/.cursor/skills/ts-one"
assert_missing "$PROJECT_DIR/.cursor/skills/ts-two"

run_skill_activate_in "$PROJECT_DIR" __toggle_category ts-one "$IDX"
assert_symlink_to "$PROJECT_DIR/.claude/skills/ts-one" "$LIBRARY/typescript/ts-one"
assert_symlink_to "$PROJECT_DIR/.claude/skills/ts-two" "$LIBRARY/typescript/ts-two"
assert_symlink_to "$PROJECT_DIR/.codex/skills/ts-one" "$LIBRARY/typescript/ts-one"
assert_symlink_to "$PROJECT_DIR/.codex/skills/ts-two" "$LIBRARY/typescript/ts-two"
assert_symlink_to "$PROJECT_DIR/.cursor/skills/ts-one" "$LIBRARY/typescript/ts-one"
assert_symlink_to "$PROJECT_DIR/.cursor/skills/ts-two" "$LIBRARY/typescript/ts-two"

if run_skill_activate_in "$PROJECT_DIR" --category missing >"$TMP_ROOT/missing.out" 2>"$TMP_ROOT/missing.err"; then
    fail "expected missing category to fail"
fi
assert_contains "$(cat "$TMP_ROOT/missing.err")" "category not found: missing"

echo "test_skill_activate: OK"
