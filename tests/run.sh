#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

# Tests rewrite HOME to isolated temp dirs. Ensure chezmoi follows those per-test
# configs instead of any runner-provided global XDG config path.
unset XDG_CONFIG_HOME || true

echo "== Running bootstrap tests =="

python3 "$ROOT/tests/test_setup_encryption_key.py"
bash "$ROOT/tests/test_init_args.sh"
bash "$ROOT/tests/test_github_https_normalization.sh"
bash "$ROOT/tests/test_install_nix_arch.sh"
bash "$ROOT/tests/test_setup_gopass.sh"
bash "$ROOT/tests/test_cursor_agent_install.sh"
bash "$ROOT/tests/test_pinned_downloads.sh"
python3 "$ROOT/tests/test_update_versions.py"
bash "$ROOT/tests/test_herdr_plugins.sh"
bash "$ROOT/tests/test_herdr_integrations.sh"
bash "$ROOT/tests/test_pi_extension_update.sh"
node --experimental-strip-types "$ROOT/tests/test_pi_worktree_guard.mjs"
bash "$ROOT/tests/test_pi_fork_upstream_watch.sh"
bash "$ROOT/tests/test_mise_up.sh"
bash "$ROOT/tests/test_keys_manage_nonmenu.sh"
bash "$ROOT/tests/test_keys_manage_setops.sh"
bash "$ROOT/tests/test_skill_activate.sh"
bash "$ROOT/tests/test_social_post_cli.sh"
bash "$ROOT/tests/test_reddit_submit_cli.sh"
node --experimental-strip-types "$ROOT/tests/test_pi_statusline_context_refresh.mjs"
node --experimental-strip-types "$ROOT/tests/test_pi_theme_editor.mjs"
bash "$ROOT/tests/test_codex_connector_plugins.sh"
bash "$ROOT/tests/test_codex_model_selection.sh"
bash "$ROOT/tests/test_tmux_ai_status.sh"
bash "$ROOT/tests/test_aicommit_message_parsing.sh"
bash "$ROOT/tests/test_manage_list_logic.sh"
bash "$ROOT/tests/test_manage_menu_navigation.sh"

echo "OK"
