import {
  CustomEditor,
  type ExtensionAPI,
  type KeybindingsManager,
} from "@earendil-works/pi-coding-agent";
import {
  visibleWidth,
  type EditorTheme,
  type TUI,
} from "@earendil-works/pi-tui";

import {
  detachLeadingShellBang,
  highlightLeadingSlashToken,
  injectPromptSymbol,
  wrapWithRoundedBorder,
  type Paint,
} from "./render.js";

// Rounded, theme-following input textbox for Pi. Four columns of padding
// reserve room for a `>`/`!` prompt token, while a render post-pass turns
// Pi's horizontal rules into a rounded box. Native editing, autocomplete,
// history, IME, app shortcuts, and the active Pi theme remain intact.
//
// Override the normal prompt glyph with PI_INPUT_PREFIX. A single-cell glyph
// is required so the visual overlay does not disturb Pi's cursor math.
const configuredMarker = (process.env.PI_INPUT_PREFIX || ">").at(0) ?? ">";
const PROMPT_MARKER = visibleWidth(configuredMarker) === 1 ? configuredMarker : ">";
const EDITOR_PADDING = 4;
const BOLD = "\x1b[1m";
const RESET = "\x1b[0m";
const INVERSE_ON = "\x1b[7m";
const INVERSE_OFF = "\x1b[27m";

interface EditorColors {
  normal: Paint;
  focus: Paint;
  muted: Paint;
  shell: Paint;
  slashToken: Paint;
}

class RoundedPromptEditor extends CustomEditor {
  private readonly colors: EditorColors;

  constructor(
    tui: TUI,
    theme: EditorTheme,
    keybindings: KeybindingsManager,
  ) {
    const focus = theme.selectList.selectedText;
    const colors: EditorColors = {
      normal: theme.borderColor,
      focus,
      muted: theme.selectList.description,
      shell: focus,
      slashToken: (text) => `${BOLD}${focus(text)}${RESET}`,
    };
    super(tui, theme, keybindings, { paddingX: EDITOR_PADDING });
    this.colors = colors;
  }

  // Pi copies the default editor's padding immediately after the custom editor
  // factory returns. Keep four columns even when that default is 0.
  setPaddingX(padding: number): void {
    super.setPaddingX(Math.max(EDITOR_PADDING, padding));
  }

  render(width: number): string[] {
    const original = super.render(width);
    if (original.length < 3) return original;

    try {
      const lines = [...original];
      const text = this.getText();
      const isShell = text.startsWith("!");
      const isSlashCommand = !isShell && text.trimStart().startsWith("/");
      // Follow the active Pi theme: default border at rest, accent for slash
      // commands and shell mode.
      const border = isShell
        ? this.colors.shell
        : isSlashCommand
          ? this.colors.focus
          : this.colors.normal;

      let prompt = PROMPT_MARKER;
      const firstContentIndex = 1;
      const firstContent = lines[firstContentIndex];

      if (firstContent !== undefined) {
        if (isSlashCommand) {
          const highlighted = highlightLeadingSlashToken(firstContent, this.colors.slashToken);
          if (highlighted !== undefined) lines[firstContentIndex] = highlighted;
        }

        if (isShell) {
          const detached = detachLeadingShellBang(firstContent);
          lines[firstContentIndex] = detached.line;

          const bang = border("!");
          prompt = detached.cursorOnPrompt
            ? `${detached.hardwareCursorMarker}${INVERSE_ON}${bang}${INVERSE_OFF}`
            : bang;
        }

        const withPrompt = injectPromptSymbol(lines[firstContentIndex]!, prompt);
        if (withPrompt !== undefined) lines[firstContentIndex] = withPrompt;
      }

      const label = isShell
        ? ` ${BOLD}${border("! shell mode")}${RESET} `
        : undefined;
      return wrapWithRoundedBorder(lines, border, { label });
    } catch {
      // Cosmetic rendering must never make the editor unusable.
      return original;
    }
  }
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    if (ctx.mode !== "tui") return;

    ctx.ui.setEditorComponent(
      (tui, theme, keybindings) =>
        new RoundedPromptEditor(tui, theme, keybindings),
    );
  });
}
