# WezTerm app icon

Replacement icon for `/Applications/WezTerm.app` on macOS 26 (Tahoe).

- Artwork: `../../private_dot_config/wezterm/WezTerm.icns` (deployed to `~/.config/wezterm/`)
- Applied by: `../../.chezmoiscripts/run_after_21_wezterm-icon.sh` (Finder custom icon via JXA)
- Generator: `wezterm-icon.swift` (offline only; nothing runs it during apply)

## Why

WezTerm ships only a legacy `terminal.icns` (no `.icon` bundle, `Assets.car` or
`CFBundleIconName`). Tahoe rescales such icons onto the 824/1024 grid and paints a
specular rim that reads as a light-grey outline at Dock sizes. A Finder _custom
icon_ is used verbatim and skips that processing.

## Do not replace `Contents/Resources/terminal.icns`

Overwriting a signed resource breaks the code-signature seal and Gatekeeper
(`spctl`) rejects the app. The custom-icon `Icon\r` file is outside the signed
envelope, so `spctl` still accepts it. A running app keeps its old Dock tile until
WezTerm is relaunched.

## Geometry and palette

- Body: Apple's continuous-corner rectangle, `824x824+100+100` in a 1024 canvas,
  radius 214.5 (fitted against `Calculator.app`).
- `>_` mark: proportions chained by φ (body : mark, mark width : height,
  chevron : bar, bar : gap; bar width : height = φ²); stroke = bar height.
- Mark raised 3% off centre to cancel the ink centroid sitting below centre.
- Two layouts: ≤32px single mark, ≥64px prompt plus two output rows; sizes ≤64px
  are unsharp-masked after Lanczos downscaling.
- Contrast level 3 ships (ink `#9F9CFF` on plate `#1A2227`, 6.66:1); level 1 is
  the smallest that clears WCAG AA. Measure contrast gated on alpha and locally
  around the ink.

## Regenerating

```sh
swiftc -O wezterm-icon.swift -o wezterm-icon
./wezterm-icon D large.png 3    # session layout, for >=64px
./wezterm-icon B small.png 3    # single mark, for <=32px
```

The third argument is the contrast level (0-3). Build the iconset from the two
images, run `iconutil -c icns`, and commit the result as `WezTerm.icns`; script `21`
re-applies it on the next apply via a hash comparison.
