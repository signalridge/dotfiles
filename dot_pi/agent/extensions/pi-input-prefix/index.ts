import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { CustomEditor } from "@earendil-works/pi-coding-agent";

// Codex-style leading prompt marker for pi's input textbox.
//
// pi has NO config key for an input prefix: the interactive editor
// (pi-tui Editor.render) draws only the text with left padding — no marker,
// and footer.json `promptInput.prefix` is dead config (pi reads settings.json
// only). The supported way to customize the input component is the extension
// API `ctx.ui.setEditorComponent(factory)` (ExtensionContext passed to event
// handlers), which the docs recommend driving by subclassing CustomEditor.
//
// The marker is rendered BOLD for a heavier look. Default glyph is "❯".
// Override the glyph:  env PI_INPUT_PREFIX (single-width char recommended).
// Disable entirely:    remove this extension dir + restart pi.

// First code point of the configured marker, then a space -> 2 visible columns.
const MARKER = (process.env.PI_INPUT_PREFIX || "❯").at(0) ?? "❯";
const PREFIX = MARKER + " ";
const PREFIX_COLS = 2;
const BOLD = "\x1b[1m";
const RESET = "\x1b[0m";

class PrefixEditor extends CustomEditor {
  // The host forces setPaddingX(defaultEditor.getPaddingX()) right after the
  // factory runs (interactive-mode setCustomEditorComponent), and the default
  // is 0. Floor it so there are always >= PREFIX_COLS left-padding columns to
  // overwrite, keeping text columns and cursor math untouched.
  setPaddingX(padding: number): void {
    super.setPaddingX(Math.max(PREFIX_COLS, padding));
  }

  render(width: number): string[] {
    const lines = super.render(width);
    try {
      // lines[0] = top border; lines[1] = first content line (always present:
      // an empty editor still renders one cursor line). The content line begins
      // with `paddingX` literal spaces, so replacing the first PREFIX_COLS of
      // them with an equal-width bold+colored marker preserves total visible
      // width (ANSI styling is zero-width; RESET keeps the input text clean).
      if (lines.length >= 2 && this.getPaddingX() >= PREFIX_COLS) {
        const color = this.borderColor ?? ((s: string) => s);
        lines[1] =
          `${BOLD}${color(PREFIX)}${RESET}` + lines[1].slice(PREFIX_COLS);
      }
    } catch {
      // A cosmetic overlay must never break the input box: fall through to the
      // untouched super.render() output on any error.
    }
    return lines;
  }
}

export default function (pi: ExtensionAPI) {
  // ctx.ui.setEditorComponent swaps the editor live (preserving text, border
  // color, keybindings, autocomplete). `ui` lives on the ExtensionContext
  // passed to the handler, NOT on the top-level ExtensionAPI.
  pi.on("session_start", (_event, ctx) => {
    try {
      ctx.ui.setEditorComponent(
        (tui, theme, keybindings) => new PrefixEditor(tui, theme, keybindings),
      );
    } catch {
      // Non-interactive mode: no editor to swap.
    }
  });
}
