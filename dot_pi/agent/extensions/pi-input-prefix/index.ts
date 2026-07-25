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
  ansiRgb,
  detachLeadingShellBang,
  highlightLeadingSlashToken,
  injectPromptSymbol,
  KIMI_DARK_EDITOR_RGB,
  wrapWithRoundedBorder,
  type Paint,
} from "./render.js";

// Kimi Code-style input textbox for Pi. Kimi's editor is also built on
// pi-tui: four columns of padding reserve room for a `>`/`!` prompt token,
// while a render post-pass turns Pi's horizontal rules into a rounded box.
// This keeps Pi's native editing, autocomplete, history, IME, and app-level
// shortcuts intact.
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

interface KimiEditorColors {
  normal: Paint;
  focus: Paint;
  muted: Paint;
  shell: Paint;
  slashToken: Paint;
}

const KIMI_EDITOR_COLORS: KimiEditorColors = {
  normal: ansiRgb(...KIMI_DARK_EDITOR_RGB.border),
  focus: ansiRgb(...KIMI_DARK_EDITOR_RGB.primary),
  muted: ansiRgb(...KIMI_DARK_EDITOR_RGB.muted),
  shell: ansiRgb(...KIMI_DARK_EDITOR_RGB.shell),
  slashToken: ansiRgb(...KIMI_DARK_EDITOR_RGB.primary, { bold: true }),
};

class KimiStyleEditor extends CustomEditor {
  private readonly colors: KimiEditorColors;

  constructor(
    tui: TUI,
    theme: EditorTheme,
    keybindings: KeybindingsManager,
    colors: KimiEditorColors,
  ) {
    const kimiTheme: EditorTheme = {
      ...theme,
      borderColor: colors.normal,
      selectList: {
        ...theme.selectList,
        selectedPrefix: colors.focus,
        selectedText: colors.focus,
        description: colors.muted,
        scrollInfo: colors.muted,
        noMatch: colors.muted,
      },
    };
    super(tui, kimiTheme, keybindings, { paddingX: EDITOR_PADDING });
    this.colors = colors;
  }

  // Pi copies the default editor's padding immediately after the custom editor
  // factory returns. Keep Kimi's four-column layout even when that default is 0.
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
      // Use Kimi Code's exact dark palette rather than Pi's thinking-level
      // border: neutral at rest, primary for slash commands, violet in shell mode.
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
        new KimiStyleEditor(tui, theme, keybindings, KIMI_EDITOR_COLORS),
    );
  });
}
