-- WezTerm -- https://wezterm.org/config/lua/config/index.html
--
-- Ported from the previous Ghostty config, then filled out. Every key binding
-- here is CMD-based on purpose: AeroSpace owns ~45 alt/alt-shift combinations
-- in this setup, so alt is left alone entirely.

local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

-- ── Appearance ─────────────────────────────────────────────────────────────
-- "Dracula (Official)", NOT "Dracula": wezterm ships both, and the plain one is
-- a different palette -- bg #1e1f29, ansi black #000000, ansi white #bbbbbb,
-- bright black #555555, and brights 1-6 identical to the normal colours. TUIs
-- that use bright-vs-normal to express active-vs-inactive (herdr's tab strip)
-- lose that distinction entirely and look washed out. The Official variant is
-- the palette Ghostty used and the one baked into the Terminal.app profile.
config.color_scheme = "Dracula (Official)"

-- CaskaydiaCove is a Nerd Font, so icons come from the primary face; the
-- fallbacks below only cover codepoints it lacks (e.g. U+23F4/U+23F5).
--
-- Body weight is DemiBold rather than Regular: FreeType (what wezterm uses)
-- renders lighter than the CoreText rasteriser Terminal.app uses, so at the same
-- nominal weight wezterm looks noticeably thinner. Stepping the body face up one
-- notch closes that gap far better than any hinting knob. Bold stays distinct
-- because font_rules below pin it to the real Bold face, and italics inherit the
-- body weight (verified: they resolve to SemiBoldItalic, not RegularItalic).
config.font = wezterm.font_with_fallback({
  { family = "CaskaydiaCove NFM", weight = "DemiBold" },
  -- CaskaydiaCove, Menlo and Apple Color Emoji all lack CJK, so without an
  -- explicit entry here every Chinese character came from whatever wezterm
  -- picked on its own. PingFang SC is the macOS system Chinese face and is what
  -- Terminal.app falls back to, so this keeps the two looking the same.
  { family = "PingFang SC", weight = "Medium" },
  "Apple Color Emoji",
  "Menlo",
})
config.font_size = 14

-- "Normal", not "Light": Light uses a lighter hinting algorithm and made the
-- text visibly thinner, which is the opposite of what was wanted here. The
-- weight bump above is what actually closes the gap with Terminal.app.
-- (freetype_load_flags already defaults to NO_HINTING at this DPI.)
config.freetype_load_target = "Normal"

-- These faces are separate static files (SemiBold 600 and Bold 700 are distinct),
-- so ask for Bold explicitly rather than letting a weight search land on SemiBold.
config.font_rules = {
  { intensity = "Bold", font = wezterm.font("CaskaydiaCove NFM", { weight = "Bold" }) },
  {
    intensity = "Bold",
    italic = true,
    font = wezterm.font("CaskaydiaCove NFM", { weight = "Bold", italic = true }),
  },
  { italic = true, font = wezterm.font("CaskaydiaCove NFM", { italic = true }) },
}

-- Ghostty: window-padding-x = 12,8 / window-padding-y = 0,2
-- Ghostty had top = 0, but there the tabs sat in the macOS titlebar. Here the
-- tab bar is drawn by wezterm directly above the content, so 0 puts the first
-- row flush against it.
--
-- The horizontal pair is deliberately wider than Ghostty's and symmetric: the
-- prompt sat almost flush against the window edge otherwise. No scrollbar is
-- enabled, so `right` is pure breathing room and matching `left` keeps text
-- centred. Bumping these costs columns, not just margin -- each ~8.4px here is
-- one cell of the 14pt CaskaydiaCove face -- so keep them in that ballpark.
config.window_padding = { left = 20, right = 20, top = 6, bottom = 2 }

-- No separate title bar -- the traffic-light buttons move into the tab bar.
-- Closest equivalent to Ghostty's `macos-titlebar-style = tabs`, and the thing
-- macOS Terminal.app cannot do at all. Use "TITLE | RESIZE" for a normal bar.
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"

-- true = the native-looking bar drawn with a proportional font; false = the
-- "retro" bar drawn out of terminal cells in the main monospace font, which
-- looks out of place on macOS.
config.use_fancy_tab_bar = true
-- MUST stay false while window_decorations uses INTEGRATED_BUTTONS: the
-- minimise/maximise/close buttons live inside the tab bar, so hiding the bar
-- when only one tab is open leaves them nowhere to go and they end up over the
-- first row of terminal content, shifting the prompt and cursor.
config.hide_tab_bar_if_only_one_tab = false
-- macOS puts the traffic lights on the left; the default is the right.
config.integrated_title_button_alignment = "Left"
config.tab_bar_at_bottom = false
config.tab_max_width = 32

-- With the fancy bar it is `window_frame` that styles the strip; Roboto is
-- bundled with wezterm and is what gives it the native proportional look.
config.window_frame = {
  font = wezterm.font({ family = "Roboto", weight = "Bold" }),
  font_size = 12,
  active_titlebar_bg = "#282a36",
  inactive_titlebar_bg = "#282a36",
}
-- These merge on top of `color_scheme` rather than replacing it, so only the tab
-- bar is overridden here. `background` is deliberately absent: it is documented
-- as applying only to the retro bar, so setting it while use_fancy_tab_bar is
-- true would be dead config that reads as if it were doing something.
config.colors = {
  tab_bar = {
    inactive_tab_edge = "#44475a",
    active_tab = { bg_color = "#44475a", fg_color = "#f8f8f2", intensity = "Bold" },
    inactive_tab = { bg_color = "#282a36", fg_color = "#6272a4" },
    inactive_tab_hover = { bg_color = "#44475a", fg_color = "#bd93f9", italic = false },
    new_tab = { bg_color = "#282a36", fg_color = "#6272a4" },
    new_tab_hover = { bg_color = "#44475a", fg_color = "#bd93f9" },
  },
}

config.default_cursor_style = "SteadyBlock"
config.scrollback_lines = 100000

-- ── Behaviour ──────────────────────────────────────────────────────────────
config.audible_bell = "Disabled"
config.window_close_confirmation = "NeverPrompt"
config.exit_behavior = "Close"

-- AeroSpace tiles every window, so growing the window on Cmd-+ just fights it.
config.adjust_window_size_when_changing_font_size = false

-- ── Input ──────────────────────────────────────────────────────────────────
-- Ghostty: macos-option-as-alt = true. WezTerm frames this as "do not let the
-- OS compose a character from Option", which is what makes Option act as Alt.
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

-- Ghostty: mouse-hide-while-typing = false
config.hide_mouse_cursor_when_typing = false

config.keys = {
  -- Ghostty: keybind = shift+enter=text:\n  (multi-line input in TUIs/agents)
  { key = "Enter", mods = "SHIFT", action = act.SendString("\n") },

  -- Splits (iTerm-style)
  { key = "d", mods = "CMD", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "d", mods = "CMD|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "w", mods = "CMD|SHIFT", action = act.CloseCurrentPane({ confirm = false }) },

  -- Pane focus / resize -- CMD+arrows, since alt belongs to AeroSpace
  { key = "LeftArrow", mods = "CMD", action = act.ActivatePaneDirection("Left") },
  { key = "RightArrow", mods = "CMD", action = act.ActivatePaneDirection("Right") },
  { key = "UpArrow", mods = "CMD", action = act.ActivatePaneDirection("Up") },
  { key = "DownArrow", mods = "CMD", action = act.ActivatePaneDirection("Down") },
  { key = "LeftArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Left", 3 }) },
  { key = "RightArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Right", 3 }) },
  { key = "UpArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Up", 3 }) },
  { key = "DownArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Down", 3 }) },
  { key = "z", mods = "CMD|SHIFT", action = act.TogglePaneZoomState },

  -- Search, copy mode, quick select
  { key = "f", mods = "CMD", action = act.Search("CurrentSelectionOrEmptyString") },
  { key = "x", mods = "CMD|SHIFT", action = act.ActivateCopyMode },
  { key = "p", mods = "CMD|SHIFT", action = act.QuickSelect },

  -- Clear scrollback the way Cmd+K behaves elsewhere on macOS
  { key = "k", mods = "CMD", action = act.ClearScrollback("ScrollbackAndViewport") },
}

-- Tab titles: index + foreground process, instead of the raw pane title (which
-- is usually a long command line or shell path).
wezterm.on("format-tab-title", function(tab)
  local pane = tab.active_pane
  local proc = pane.foreground_process_name or ""
  proc = proc:gsub("^.*/", "") -- basename
  if proc == "" then
    proc = (pane.title or ""):gsub("^.*/", "")
  end
  return string.format("  %d  %s  ", tab.tab_index + 1, proc)
end)

-- CMD+1..9 jumps to a tab.
for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = "CMD",
    action = act.ActivateTab(i - 1),
  })
end

return config
