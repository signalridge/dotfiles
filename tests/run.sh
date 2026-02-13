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
bash "$ROOT/tests/test_codex_model_selection.sh"
bash "$ROOT/tests/test_manage_list_logic.sh"
bash "$ROOT/tests/test_manage_menu_navigation.sh"

echo "OK"
