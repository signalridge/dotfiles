#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

fail() {
    echo "openspec-trace-gate: $*" >&2
    exit 1
}

assert_not_ignored() {
    local path="$1"
    local tmp
    tmp="$(mktemp "${TMPDIR:-/tmp}/openspec-check-ignore.XXXXXX")"
    if git check-ignore -v "$path" >"$tmp" 2>/dev/null; then
        local detail
        detail="$(cat "$tmp")"
        rm -f "$tmp"
        fail "path is ignored by git ($path): $detail"
    fi
    rm -f "$tmp"
}

# OpenSpec is optional per PR/repo.
# Enforce only when the current branch (HEAD tree) tracks openspec assets.
tracked_openspec_count="$(git ls-tree -r --name-only HEAD -- openspec 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$tracked_openspec_count" == "0" ]]; then
    echo "openspec-trace-gate: skipped (current branch does not track openspec assets)"
    exit 0
fi

# 1) OpenSpec paths must not be ignored once OpenSpec is in use.
assert_not_ignored "openspec/.probe"
assert_not_ignored "openspec/specs/.probe"
assert_not_ignored "openspec/changes/archive/.probe"

# 2) Merge gate: all active changes must be archived before merge.
if [[ -d "openspec/changes" ]]; then
    mapfile -t active_changes < <(find openspec/changes -mindepth 1 -maxdepth 1 -type d ! -name archive | sort)
    if ((${#active_changes[@]} > 0)); then
        printf 'openspec-trace-gate: unarchived OpenSpec changes found:\n' >&2
        printf '  - %s\n' "${active_changes[@]}" >&2
        fail "archive these changes before merge (openspec archive <change-name> --yes)"
    fi
fi

# 3) All OpenSpec files must be tracked by git.
mapfile -t openspec_files < <(find openspec -type f 2>/dev/null | sort)
if ((${#openspec_files[@]} > 0)); then
    untracked=()
    for f in "${openspec_files[@]}"; do
        if ! git ls-files --error-unmatch "$f" >/dev/null 2>&1; then
            untracked+=("$f")
        fi
    done

    if ((${#untracked[@]} > 0)); then
        printf 'openspec-trace-gate: openspec files are not tracked:\n' >&2
        printf '  - %s\n' "${untracked[@]}" >&2
        fail "track all openspec files in git before merge"
    fi
fi

# 4) openspec/specs and openspec/changes must follow strict file layout.
unexpected_specs=()
if [[ -d "openspec/specs" ]]; then
    while IFS= read -r f; do
        rel="${f#openspec/}"
        case "$rel" in
        specs/*/spec.md) ;;
        *)
            unexpected_specs+=("$f")
            ;;
        esac
    done < <(find openspec/specs -type f | sort)
fi

unexpected_changes=()
if [[ -d "openspec/changes" ]]; then
    while IFS= read -r f; do
        rel="${f#openspec/changes/}"
        case "$rel" in
        archive/*/.openspec.yaml | \
            archive/*/proposal.md | \
            archive/*/design.md | \
            archive/*/tasks.md | \
            archive/*/README.md | \
            archive/*/specs/*/spec.md) ;;
        *)
            unexpected_changes+=("$f")
            ;;
        esac
    done < <(find openspec/changes -type f | sort)
fi

if ((${#unexpected_specs[@]} > 0)); then
    printf 'openspec-trace-gate: unexpected files under openspec/specs:\n' >&2
    printf '  - %s\n' "${unexpected_specs[@]}" >&2
    fail "only openspec/specs/<capability>/spec.md is allowed"
fi

if ((${#unexpected_changes[@]} > 0)); then
    printf 'openspec-trace-gate: unexpected files under openspec/changes:\n' >&2
    printf '  - %s\n' "${unexpected_changes[@]}" >&2
    fail "only OpenSpec change artifact files are allowed in openspec/changes"
fi

echo "openspec-trace-gate: OK"
