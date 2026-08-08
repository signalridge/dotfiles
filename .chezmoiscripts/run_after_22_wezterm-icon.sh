#!/bin/bash

set -euo pipefail

# Reapply the custom WezTerm app icon.
#
# Why this runs on every apply rather than run_onchange: the trigger we care
# about is the *bundle* being rebuilt, not this script changing. A cask upgrade
# (wezterm@nightly moves often) replaces /Applications/WezTerm.app wholesale and
# takes the custom-icon resource fork with it. Nothing in the source state
# changes when that happens, so run_onchange would never fire. The work here is
# a hash comparison, so the no-op path is cheap.

echo ":: [22] WezTerm icon"

APP="/Applications/WezTerm.app"
ICON="${XDG_CONFIG_HOME:-$HOME/.config}/wezterm/WezTerm.icns"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE="$STATE_DIR/wezterm-icon.sha256"

if [[ ! -d "$APP" ]]; then
    echo "    Skipped (WezTerm.app not installed)"
    exit 0
fi
if [[ ! -f "$ICON" ]]; then
    echo "    Skipped (icon not found: $ICON)"
    exit 0
fi

want="$(shasum -a 256 "$ICON" | cut -d' ' -f1)"
have="$(cat "$STATE" 2>/dev/null || true)"

# Finder records a custom icon as an "Icon\r" file carrying a resource fork.
# Presence is checked as well as the hash: after a cask upgrade the marker is
# gone even though the recorded hash still matches.
marker="$APP/Icon"$'\r'
if [[ -e "$marker" && "$want" == "$have" ]]; then
    echo "    Skipped (already applied)"
    exit 0
fi

# NSWorkspace.setIcon is the same mechanism as dragging an image onto the
# thumbnail in Finder's Get Info. macOS 26 honours a custom icon verbatim and
# skips the automatic legacy-icon processing that otherwise paints a specular
# rim around the artwork.
#
# Only this is touched. Overwriting Contents/Resources/*.icns would also change
# the icon, but it breaks the code-signature seal: spctl then reports "a sealed
# resource is missing or invalid" and Gatekeeper rejects the app. Adding the
# Icon\r file leaves Gatekeeper at "accepted" because the file is not part of
# the signed resource envelope.
jxa="$(mktemp "${TMPDIR:-/tmp}/wezterm-icon.XXXXXX")"
trap 'rm -f "$jxa"' EXIT
cat >"$jxa" <<'JXA'
ObjC.import('AppKit');
function run(argv) {
  var img = $.NSImage.alloc.initWithContentsOfFile(argv[0]);
  if (!img.js) { throw new Error('cannot load icon: ' + argv[0]); }
  if (!$.NSWorkspace.sharedWorkspace.setIconForFileOptions(img, argv[1], 0)) {
    throw new Error('setIcon returned false for ' + argv[1]);
  }
  return 'ok';
}
JXA

osascript -l JavaScript "$jxa" "$ICON" "$APP" >/dev/null

mkdir -p "$STATE_DIR"
tmp_state="$(mktemp "${STATE}.XXXXXX")"
printf '%s\n' "$want" >"$tmp_state"
mv "$tmp_state" "$STATE"

touch "$APP"
killall Dock 2>/dev/null || true

echo "    Applied (relaunch WezTerm to update its Dock tile)"
