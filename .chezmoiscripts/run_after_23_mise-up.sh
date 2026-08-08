#!/bin/bash

set -euo pipefail

# Upgrade mise-managed tools on a 7-day cadence.
#
# Script 07 is the install half and is a `run_onchange` — it fires only when the
# mise/aqua config hash changes. A tool requested as "latest" (pi, ccusage,
# agent-browser, impeccable, ...) is therefore resolved once at first install and
# then never moves again, however far upstream drifts. This script is the missing
# half: `mise up` re-resolves those requests and upgrades what is installed.
#
# NEVER pass --bump. It rewrites ~/.config/mise/config.toml to the new versions,
# and chezmoi owns that file (private_dot_config/mise/config.toml.tmpl) — the next
# apply would revert it and the two would fight every week. Plain `mise up` keeps
# the configured request untouched and only changes what lives under mise's
# install dir, so there is no chezmoi conflict.
#
# ORDERING: this runs after script 20 (pi extensions), so a pi CLI upgrade lands
# one apply ahead of the extension reconcile that follows it. Both steps are
# idempotent and weekly, so the lag is self-healing and costs nothing.
#
# CADENCE: 7-day interval, same idiom as script 10 (Homebrew). The timestamp is
# advanced only after a successful upgrade, so a failure is retried on the next
# apply instead of being suppressed for another week.

echo ":: [23] Upgrading mise tools"

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/chezmoi"
state_file="$state_dir/mise-up-last-success"
current_time="$(date +%s)"
update_interval=$((7 * 86400))
last_update=0
if [[ -f "$state_file" ]]; then
    last_update_raw="$(cat "$state_file" 2>/dev/null || true)"
    if [[ "$last_update_raw" =~ ^[0-9]+$ ]]; then
        last_update="$last_update_raw"
    fi
fi
days_ago=$(((current_time - last_update) / 86400))

if ((current_time - last_update <= update_interval)); then
    echo "    Skipped (last upgrade: ${days_ago} days ago)"
    exit 0
fi

# chezmoi may be rewriting dot-directories while this runs. If the working
# directory disappears mid-apply mise warns, so run from a stable dir (same
# precaution as script 07).
cd "$HOME"

# mise is aqua-managed and the user strips mise shims at the zshenv phase, so this
# non-interactive shell has neither mise nor its tool bins on PATH. Resolve the
# real binary from the aqua bin dir, then inject the tool bin dirs via `mise env`
# (not `activate`, which needs a shell hook that never fires here) — same idiom as
# scripts 07 and 20.
aqua_bin_dir="${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua}/bin"
if [[ -d "$aqua_bin_dir" ]]; then
    export PATH="$aqua_bin_dir:$PATH"
fi
mise_bin="$aqua_bin_dir/mise"
if [[ ! -x "$mise_bin" ]]; then
    mise_bin="$(command -v mise 2>/dev/null || true)"
fi
if [[ -z "$mise_bin" ]]; then
    echo "    Skipped (mise not found)"
    exit 0
fi
eval "$("$mise_bin" env -s bash)"

# npm-backed tools need npm during version resolution, and settings.npm sets bun
# as the installer. Bootstrap node the same way script 07 does if the runtime is
# not on PATH yet.
if ! command -v npm >/dev/null 2>&1; then
    "$mise_bin" install --yes node
    eval "$("$mise_bin" env -s bash)"
fi

echo "    Last upgrade: ${days_ago} days ago, checking for updates..."

# Keep transient registry/network failures non-fatal, but record success only, so
# the next apply retries a failure rather than waiting out the interval.
if "$mise_bin" up --yes && "$mise_bin" reshim; then
    umask 077
    mkdir -p "$state_dir"
    tmp_state="$(mktemp "${state_file}.XXXXXX")"
    printf '%s\n' "$current_time" >"$tmp_state"
    mv "$tmp_state" "$state_file"
    echo "    mise tools upgraded"
else
    echo "    Warning: 'mise up' failed (non-fatal); next apply will retry" >&2
fi
