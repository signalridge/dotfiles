#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

if ! cmp -s "$ROOT/AGENTS.md" "$ROOT/CLAUDE.md"; then
    echo "AGENTS.md and CLAUDE.md must remain byte-identical" >&2
    diff -u "$ROOT/AGENTS.md" "$ROOT/CLAUDE.md" >&2 || true
    exit 1
fi

[[ -x "$ROOT/init.sh" ]] || {
    echo "init.sh must be executable because the documented clone flow uses ./init.sh" >&2
    exit 1
}

for sentinel in .worktrees/sentinel nested/.worktrees/sentinel; do
    if git -C "$ROOT" check-ignore --no-index -q "$sentinel"; then
        echo "the constitution forbids hiding worktrees via .gitignore: $sentinel" >&2
        exit 1
    fi
done

python3 - "$ROOT/.gitleaks.toml" <<'PY'
import re
import sys
import tomllib

with open(sys.argv[1], "rb") as handle:
    config = tomllib.load(handle)
for allowlist in config.get("allowlists", []):
    for pattern in allowlist.get("paths", []):
        for sentinel in (".worktrees/sentinel", "nested/.worktrees/sentinel"):
            if re.search(pattern, sentinel):
                raise SystemExit(
                    f"the constitution forbids hiding worktrees via Gitleaks: {pattern!r}"
                )
PY

if grep -REq 'nixpkgs#[A-Za-z0-9]' \
    "$ROOT/.chezmoiscripts" "$ROOT/.chezmoitemplates" "$ROOT/.github/workflows"; then
    echo "bootstrap and CI commands must use the pinned nixpkgs revision" >&2
    exit 1
fi

gitleaks_job="$(sed -n '/^  gitleaks:/,$p' "$ROOT/.github/workflows/security.yml")"
grep -Fq 'fetch-depth: 0' <<<"$gitleaks_job" || {
    echo "gitleaks CI must fetch full history before scanning" >&2
    exit 1
}
grep -Fq 'gitleaks detect' <<<"$gitleaks_job" || {
    echo "gitleaks CI must scan Git history, not only the working tree" >&2
    exit 1
}
if grep -Fq -- '--no-git' <<<"$gitleaks_job"; then
    echo "gitleaks CI must not disable Git history scanning" >&2
    exit 1
fi

echo "test_repository_invariants: OK"
