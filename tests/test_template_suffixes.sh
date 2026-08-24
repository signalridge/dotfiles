#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
invalid=0

while IFS= read -r path; do
    if ! grep -Fq '{{' "$ROOT/$path"; then
        printf 'static source file must not use .tmpl: %s\n' "$path" >&2
        invalid=1
    fi
done < <(git -C "$ROOT" ls-files '*.tmpl')

if ((invalid)); then
    exit 1
fi

echo "test_template_suffixes: OK"
