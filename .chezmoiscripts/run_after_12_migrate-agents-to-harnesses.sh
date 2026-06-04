#!/usr/bin/env bash
set -euo pipefail

old_root="$HOME/.agents"
new_root="$HOME/.harnesses"

if [ ! -e "$old_root" ]; then
    exit 0
fi

if [ -L "$old_root" ]; then
    target="$(readlink "$old_root")"
    case "$target" in
    "$new_root" | "$new_root"/*)
        exit 0
        ;;
    *)
        printf 'leaving symlinked %s unchanged -> %s\n' "$old_root" "$target" >&2
        exit 0
        ;;
    esac
fi

if [ ! -d "$old_root" ]; then
    printf 'leaving non-directory %s unchanged\n' "$old_root" >&2
    exit 0
fi

mkdir -p "$new_root"
timestamp="$(date +%Y%m%d%H%M%S)"

move_managed_entry() {
    local entry="$1"
    local src="$old_root/$entry"
    local dst="$new_root/$entry"
    local backup
    local suffix

    [ -e "$src" ] || return 0

    if [ ! -e "$dst" ]; then
        mv "$src" "$dst"
        printf 'migrated %s to %s\n' "$src" "$dst" >&2
        return 0
    fi

    mkdir -p "$new_root/legacy-agents"
    backup="$new_root/legacy-agents/${entry}-${timestamp}"
    suffix=1
    while [ -e "$backup" ]; do
        backup="$new_root/legacy-agents/${entry}-${timestamp}-${suffix}"
        suffix=$((suffix + 1))
    done
    mv "$src" "$backup"
    printf 'moved existing %s aside to %s because %s already exists\n' "$src" "$backup" "$dst" >&2
}

move_managed_entry "skills"
move_managed_entry "commands"

rmdir "$old_root" 2>/dev/null || true
