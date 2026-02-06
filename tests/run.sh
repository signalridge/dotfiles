#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

echo "== Running bootstrap tests =="

python3 "$ROOT/tests/test_setup_encryption_key.py"
bash "$ROOT/tests/test_init_args.sh"
bash "$ROOT/tests/test_install_nix_arch.sh"
bash "$ROOT/tests/test_chezmoiignore.sh"
bash "$ROOT/tests/test_setup_gopass.sh"
bash "$ROOT/tests/test_keys_manage_nonmenu.sh"

echo "OK"
