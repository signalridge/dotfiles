#!/bin/bash

set -euo pipefail

# Keep mbx's Cargo shim installed and current (see the mr-boxington entry in
# private_dot_config/mise/config.toml.tmpl). The mise config only installs mbx
# and puts the shim's directory first on PATH; the shim itself comes from
# `mbx setup`, once per machine and again whenever the installed mbx version
# changes (the Unix shim runs the version setup recorded, and script 22's
# `mise up` can replace that version). So this runs on every apply rather than
# as a run_onchange: `mbx setup --status` is cheap and exits non-zero only when
# the shim or the rust-analyzer check override is missing or out of date.
#
# MISE_SHELL is unset on purpose: inside an activated mise shell `mbx setup`
# would add a [wrappers.cargo] entry to a mise config, and that wrapper does
# not work with aqua-installed mise (it dispatches to aqua-proxy) and would
# fight the chezmoi-owned config.

echo ":: [23] mbx Cargo shim"

cd "$HOME"

aqua_bin_dir="${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua}/bin"
mise_cmd="$aqua_bin_dir/mise"
if [[ ! -x "$mise_cmd" ]]; then
    echo "    Skipped (aqua-managed mise not found)"
    exit 0
fi

mbx_dir="$("$mise_cmd" where mr-boxington 2>/dev/null || true)"
mbx="$mbx_dir/mbx"
if [[ -z "$mbx_dir" || ! -x "$mbx" ]]; then
    echo "    Skipped (mr-boxington not installed by mise yet)"
    exit 0
fi

if env -u MISE_SHELL "$mbx" setup --status >/dev/null 2>&1; then
    echo "    Up to date"
    exit 0
fi

env -u MISE_SHELL "$mbx" setup
