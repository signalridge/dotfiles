const ANSI_SGR = /\u001B\[[0-9;]*m/g;

/** Zero-width marker used by pi-tui to place the hardware cursor for IME. */
export const HARDWARE_CURSOR_MARKER = "\x1b_pi:c\x07";

const INVERSE_BANG = /^\x1b\[7m!\x1b\[(?:0|27)m/;
const EDITOR_LEFT_PADDING = "    ";

export type Paint = (text: string) => string;

/** Exact upstream Kimi Code dark-editor palette (MoonshotAI/kimi-code). */
export const KIMI_DARK_EDITOR_RGB = {
  border: [90, 90, 90],
  primary: [79, 168, 255],
  muted: [107, 107, 107],
  shell: [189, 147, 249],
} as const;

/** Chalk-compatible true-colour painter without adding a runtime dependency. */
export function ansiRgb(
  red: number,
  green: number,
  blue: number,
  options: { readonly bold?: boolean } = {},
): Paint {
  for (const channel of [red, green, blue]) {
    if (!Number.isInteger(channel) || channel < 0 || channel > 255) {
      throw new RangeError(`Invalid RGB channel: ${channel}`);
    }
  }

  const foreground = `\x1b[38;2;${red};${green};${blue}m`;
  const open = options.bold ? `${foreground}\x1b[1m` : foreground;
  const close = options.bold ? "\x1b[22m\x1b[39m" : "\x1b[39m";

  return (text) => {
    // Reopen the requested style after embedded cursor/reset sequences, matching
    // Chalk's nesting behaviour when a slash token contains the block cursor.
    const nested = text.replace(ANSI_SGR, (sequence) => `${sequence}${open}`);
    return `${open}${nested}${close}`;
  };
}

export interface DetachedShellPrompt {
  line: string;
  cursorOnPrompt: boolean;
  hardwareCursorMarker: string;
  detached: boolean;
}

function stripSgr(text: string): string {
  return text.replace(ANSI_SGR, "");
}

/**
 * Remove Pi's semantic leading `!` from the rendered content row so it can be
 * displayed as a Kimi-style prompt token without changing the editor buffer.
 * The removed cell is restored at the right edge to preserve rendered width.
 */
export function detachLeadingShellBang(line: string): DetachedShellPrompt {
  if (!line.startsWith(EDITOR_LEFT_PADDING)) {
    return { line, cursorOnPrompt: false, hardwareCursorMarker: "", detached: false };
  }

  const prefix = line.slice(0, EDITOR_LEFT_PADDING.length);
  const originalRest = line.slice(EDITOR_LEFT_PADDING.length);
  let rest = originalRest;
  let hardwareCursorMarker = "";

  if (rest.startsWith(HARDWARE_CURSOR_MARKER)) {
    hardwareCursorMarker = HARDWARE_CURSOR_MARKER;
    rest = rest.slice(HARDWARE_CURSOR_MARKER.length);
  }

  const cursorBang = rest.match(INVERSE_BANG);
  if (cursorBang?.[0]) {
    return {
      line: prefix + rest.slice(cursorBang[0].length) + " ",
      cursorOnPrompt: true,
      hardwareCursorMarker,
      detached: true,
    };
  }

  if (hardwareCursorMarker === "" && rest.startsWith("!")) {
    return {
      line: prefix + rest.slice(1) + " ",
      cursorOnPrompt: false,
      hardwareCursorMarker: "",
      detached: true,
    };
  }

  return { line, cursorOnPrompt: false, hardwareCursorMarker: "", detached: false };
}

/**
 * Overlay a one-cell prompt symbol at column 2 while preserving Pi's editor
 * layout and cursor math. Requires the editor to use at least four columns of
 * horizontal padding.
 */
export function injectPromptSymbol(line: string, symbol: string): string | undefined {
  if (!line.startsWith(EDITOR_LEFT_PADDING)) return undefined;
  return `  ${symbol} ${line.slice(EDITOR_LEFT_PADDING.length)}`;
}

function stripVisualControls(text: string): string {
  return stripSgr(text).replaceAll(HARDWARE_CURSOR_MARKER, "");
}

function mapVisibleIndexToRaw(line: string, visibleIndex: number): number {
  const sgrAtCursor = new RegExp(ANSI_SGR.source, "y");
  let rawIndex = 0;
  let visibleCount = 0;

  while (rawIndex < line.length && visibleCount < visibleIndex) {
    if (line.startsWith(HARDWARE_CURSOR_MARKER, rawIndex)) {
      rawIndex += HARDWARE_CURSOR_MARKER.length;
      continue;
    }

    sgrAtCursor.lastIndex = rawIndex;
    const sgr = sgrAtCursor.exec(line);
    if (sgr !== null) {
      rawIndex += sgr[0].length;
      continue;
    }

    rawIndex++;
    visibleCount++;
  }

  return rawIndex;
}

/** Bold-colour the leading slash-command token, as Kimi's editor does. */
export function highlightLeadingSlashToken(line: string, paint: Paint): string | undefined {
  const visible = stripVisualControls(line);
  const slashIndex = visible.indexOf("/");
  if (slashIndex < 0) return undefined;

  for (let index = 0; index < slashIndex; index++) {
    if (visible[index] !== " " && visible[index] !== "\t") return undefined;
  }

  let tokenEnd = slashIndex + 1;
  while (tokenEnd < visible.length) {
    const character = visible[tokenEnd];
    if (character === " " || character === "\t") break;
    tokenEnd++;
  }

  const rawStart = mapVisibleIndexToRaw(line, slashIndex);
  const rawEnd = mapVisibleIndexToRaw(line, tokenEnd);
  return line.slice(0, rawStart) + paint(line.slice(rawStart, rawEnd)) + line.slice(rawEnd);
}

/**
 * Turn pi-tui's horizontal editor rules into Kimi-style rounded full borders.
 * Content and autocomplete rows retain their existing ANSI styling; only the
 * outer cells are replaced.
 */
export function wrapWithRoundedBorder(
  lines: string[],
  paint: Paint,
  options: { readonly label?: string } = {},
): string[] {
  let seenTop = false;

  return lines.map((line) => {
    const plain = stripSgr(line);
    if (plain.length > 0 && plain[0] === "─") {
      const isTop = !seenTop;
      const leftCorner = seenTop ? "╰" : "╭";
      const rightCorner = seenTop ? "╯" : "╮";
      seenTop = true;

      if (plain.length === 1) return paint(leftCorner);

      const middle = plain.slice(1, -1);
      if (isTop && options.label !== undefined && /^─+$/.test(middle)) {
        const labelWidth = stripSgr(options.label).length;
        if (labelWidth <= middle.length) {
          return (
            paint(leftCorner) +
            options.label +
            paint("─".repeat(middle.length - labelWidth)) +
            paint(rightCorner)
          );
        }
      }

      return paint(leftCorner + middle + rightCorner);
    }

    if (line.length === 0) return line;

    const first = line[0];
    const last = line.at(-1);
    const head = first === " " ? paint("│") : (first ?? "");
    const tail = line.length > 1 && last === " " ? paint("│") : (last ?? "");
    if (line.length === 1) return head;
    return head + line.slice(1, -1) + tail;
  });
}
