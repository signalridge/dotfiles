#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

FILES=(
    "$ROOT/dot_local/bin/executable_claude-manage.tmpl"
    "$ROOT/dot_local/bin/executable_codex-manage.tmpl"
    "$ROOT/dot_local/bin/executable_opencode-manage.tmpl"
)

for f in "${FILES[@]}"; do
    [[ -f "$f" ]] || {
        echo "missing file: $f" >&2
        exit 1
    }
done

if rg -n -- '--no-scripts' "${FILES[@]}" >/dev/null; then
    echo "assertion failed: unsupported --no-scripts flag found in manage scripts" >&2
    rg -n -- '--no-scripts' "${FILES[@]}" >&2 || true
    exit 1
fi

missing_exclude="$(rg -n 'chezmoi apply' "${FILES[@]}" | rg -v -- '--exclude scripts' || true)"
if [[ -n "$missing_exclude" ]]; then
    echo "assertion failed: every chezmoi apply call must include --exclude scripts" >&2
    echo "$missing_exclude" >&2
    exit 1
fi

echo "test_manage_chezmoi_apply_flags: OK"
