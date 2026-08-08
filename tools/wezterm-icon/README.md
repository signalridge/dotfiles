# WezTerm app icon

Replacement icon for `/Applications/WezTerm.app` on macOS 26 (Tahoe).

- Artwork: `../../private_dot_config/wezterm/WezTerm.icns` (deployed to `~/.config/wezterm/`)
- Applied by: `../../.chezmoiscripts/run_after_22_wezterm-icon.sh`
- Generator: `wezterm-icon.swift`

## Why

WezTerm ships only a legacy `terminal.icns` — no `.icon` bundle, no `Assets.car`,
no `CFBundleIconName`. Tahoe puts such icons through automatic processing: it
rescales the artwork onto the 824/1024 grid and paints a specular rim along the
silhouette. On WezTerm's flat dark artwork that rim reads as a light-grey outline.
Measured at the top edge of the 1024px rendition:

| y   | shipped `.icns` | as macOS rendered it |
| --- | --------------- | -------------------- |
| 100 | `#2B383E`       | `#8E969B`            |
| 104 | `#2B383E`       | `#798286`            |
| 108 | `#2B383E`       | `#626D71`            |
| 120 | `#2B383E`       | `#2B383E`            |

The artwork itself contains no light pixels — the rim is entirely system-applied.
It is invisible at 16–32px (where the shipped icon is nearly full-bleed) and
obvious at Dock sizes, which is why it appears only some of the time.

Setting a Finder _custom icon_ makes macOS use the artwork verbatim and skip that
processing entirely.

## Do not replace `Contents/Resources/terminal.icns`

That also changes the icon, but it breaks the code-signature seal:

| change                    | `codesign --verify` | `spctl` (gates launching)                              |
| ------------------------- | ------------------- | ------------------------------------------------------ |
| add `Icon\r` only         | fails (`detritus`)  | **accepted**                                           |
| overwrite `terminal.icns` | fails               | **rejected** (`sealed resource is missing or invalid`) |

The `Icon\r` file is not part of the signed resource envelope, so Gatekeeper
still accepts the notarised bundle. Overwriting a signed resource does not.

A consequence: a _running_ app draws its own Dock tile from `CFBundleIconFile`,
so the Dock keeps the old icon until WezTerm is relaunched. Finder, Get Info,
Spotlight and Launchpad pick the custom icon up immediately.

## Geometry

Measured from a native Tahoe icon rather than guessed — `Calculator.app`'s
silhouette is exactly `824x824+100+100` in a 1024 canvas. The corner is Apple's
continuous curve, not a superellipse (fitting one gives an exponent that drifts
between 4.3 and 4.7 depending on the sample point), so the shape is drawn with
SwiftUI's `RoundedRectangle(style: .continuous)`. Fitting the radius against that
silhouette gives **214.5**, with a residual of 460 px — 0.044% of the canvas,
i.e. antialiasing noise along the perimeter.

The `>_` mark is derived from φ, not hand-tuned. Measurements are of the _inked_
box: a round-capped stroke spills `stroke/2` past its layout frame, and ignoring
that is what makes nominally golden proportions come out wrong.

| relation                  | ratio                       |
| ------------------------- | --------------------------- |
| body : mark width         | φ                           |
| mark width : mark height  | φ                           |
| chevron width : bar width | φ                           |
| bar width : gap           | φ                           |
| bar width : bar height    | φ²                          |
| stroke                    | = bar height (`chevW / φ³`) |

Stroke equalling bar thickness is a typographic rule rather than a geometric one:
`>` and `_` in one typeface share a stroke weight.

The mark is raised 3% off geometric centre. That is not taste — the rendered ink
centroid sits 23.8px _below_ centre (the bar rests on the baseline), so the rise
cancels it. The same measurement puts the centroid 52.9px _left_ of centre, which
is why the large-size layout does not simply shift up-left: an off-centre mark
with no reason for the empty space reads as misaligned. The output rows give that
space a purpose instead.

## Contrast

To re-measure, separate ink from plate by HSL saturation and compare the two
means as a WCAG ratio. Two traps make the naive version of that wrong:

- **Gate on alpha.** The body covers 824 of the 1024 canvas. Counting the
  transparent corners as plate pixels reports 4.01:1 where the real figure is
  3.12:1 — the RGB behind full transparency is `000000` and drags the mean down.
- **Measure locally.** The plate is a vertical gradient and the mark is not
  centred, so the whole-icon average is not what sits behind the glyph. Sample
  the plate only within the ink's bounding box plus a small margin.

The shipped palette is level 3 of four in the generator:

| level | ink           | plate top     | local ratio |
| ----- | ------------- | ------------- | ----------- |
| 0     | `#5F5BFA`     | `#2B383E`     | 3.12:1      |
| 1     | `#7B78FF`     | `#232E34`     | 4.76:1      |
| 2     | `#8C89FF`     | `#1E272C`     | 5.30:1      |
| **3** | **`#9F9CFF`** | **`#1A2227`** | **6.66:1**  |

Level 1 is the smallest change that clears WCAG AA (4.5:1) and holds closest to
WezTerm's `#4D49ED`; level 3 is what ships, chosen for legibility over hue
fidelity. Its ink reads as a pale periwinkle rather than the brand indigo — a
deliberate trade, not an oversight. Drop to level 1 or 2 to pull the hue back.

## Two layouts in one `.icns`

| slots | layout                                                   |
| ----- | -------------------------------------------------------- |
| ≤32px | single `>_` mark                                         |
| ≥64px | prompt at the start position, two rows of output beneath |

Split by physical pixels, so 32pt@2x (64px) gets the large layout while 32pt@1x
(32px) gets the small one. The session layout collapses into an indistinct blob
at 16px; the single mark stays legible. Sizes ≤64px are unsharp-masked after
Lanczos downscaling to recover stroke definition.

## Regenerating

```sh
swiftc -O wezterm-icon.swift -o wezterm-icon
./wezterm-icon D large.png 3    # session layout, for >=64px
./wezterm-icon B small.png 3    # single mark, for <=32px
```

The third argument is the contrast level from the table above. `A`–`D` are the
placement studies (`A` box-centred, `B` optically centred, `C` up-left,
`D` session); `B` and `D` are the two that ship.

Then build the iconset — small slots from `small.png`, large from `large.png` —
and `iconutil -c icns`. The script picks the result up on the next `chezmoi apply`
via a hash comparison.
