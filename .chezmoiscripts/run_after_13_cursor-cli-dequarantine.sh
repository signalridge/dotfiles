#!/bin/bash

set -euo pipefail

# cursor-cli ships Anysphere-signed native modules (merkle-tree-napi.*.node etc).
# On (re)install macOS/MDM tags the extracted files with com.apple.quarantine;
# Gatekeeper then refuses to dlopen them ("code signature ... not valid for use
# in process: library load disallowed by system policy") and `cursor-agent`
# crashes at startup. Homebrew 6 removed quarantine handling (no --no-quarantine
# / no_quarantine arg), so the reliable fix is to strip the flag after install.
#
# Runs after the brew-related scripts (02 darwin-rebuild install, 10 brew upgrade)
# on every apply; idempotent and a no-op when nothing is quarantined or off-macOS.

[[ "$(uname -s)" == "Darwin" ]] || exit 0

echo ":: [13] De-quarantining cursor-cli native modules"

stripped=0
for prefix in /opt/homebrew /usr/local; do
    for pkg in "$prefix"/Caskroom/cursor-cli/*/dist-package; do
        [[ -d "$pkg" ]] || continue
        if xattr -dr com.apple.quarantine "$pkg" 2>/dev/null; then
            stripped=1
        fi
    done
done

if [[ "$stripped" -eq 1 ]]; then
    echo "    Stripped com.apple.quarantine from cursor-cli"
else
    echo "    Skipped (cursor-cli not installed)"
fi
