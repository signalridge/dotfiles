/**
 * Persistent History + Ctrl+R Fuzzy Popup (fzf / atuin style)
 *
 * - Loads recent prompts from previous sessions into up/down history on startup.
 * - Ctrl+R opens a full-screen-width popup listing history with live fuzzy
 *   filtering — a scrollable list of candidates, not a single-line prompt.
 *
 * Hotkeys while searching:
 * - ↑ / Ctrl+P / Ctrl+R : move to older match
 * - ↓ / Ctrl+N / Ctrl+S : move to newer match
 * - <type>              : fuzzy-filter (subsequence, space = multi-token)
 * - Enter               : accept selection (fills editor)
 * - Esc / Ctrl+G / Ctrl+C : cancel
 */

import {
  CustomEditor,
  SessionManager,
  type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";
import type { UserMessage } from "@earendil-works/pi-ai";
import {
  Input,
  Key,
  matchesKey,
  truncateToWidth,
  visibleWidth,
  type Component,
  type Focusable,
  type TUI,
} from "@earendil-works/pi-tui";

const MAX_MESSAGES = 100;

/** Number of history rows shown in the popup list at once. */
const LIST_ROWS = 10;

// ─── Extension Entry ───────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  let historyCache: string[] = [];

  pi.on("session_start", async (_event, ctx) => {
    const items = await loadRecentPrompts(ctx.cwd, MAX_MESSAGES);
    historyCache = items;

    if (items.length === 0) return;

    const prevComponentFactory = ctx.ui.getEditorComponent();
    ctx.ui.setEditorComponent((tui, theme, keybindings) => {
      const editor =
        prevComponentFactory?.(tui, theme, keybindings) ??
        new CustomEditor(tui, theme, keybindings);

      for (let i = items.length - 1; i >= 0; i--) {
        editor.addToHistory?.(items[i]!);
      }
      return editor;
    });
  });

  // Ctrl+R: fuzzy history popup (fzf / atuin style)
  pi.registerShortcut("ctrl+r", {
    description: "Fuzzy popup search through prompt history",
    handler: async (ctx) => {
      // Merge cached history with current session's branch history
      const branchHistory = collectBranchHistory(ctx);
      const merged = mergeHistory(branchHistory, historyCache);

      if (merged.length === 0) {
        ctx.ui.notify("No prompt history yet.", "info");
        return;
      }

      const selected = await ctx.ui.custom<string | null>(
        (tui, theme, _kb, done) => {
          return new HistoryPopupComponent(tui, theme, merged, done);
        },
        {
          overlay: true,
          overlayOptions: {
            anchor: "center",
            width: "70%",
            minWidth: 40,
            maxHeight: "80%",
          },
        },
      );

      if (selected === null) return;
      ctx.ui.setEditorText(selected);
    },
  });
}

// ─── Fuzzy History Popup ───────────────────────────────────────────────────────

type Done = (value: string | null) => void;

/** Subsequence fuzzy match: all chars in needle appear in haystack in order. */
function subsequence(haystack: string, needle: string): boolean {
  let hi = 0;
  for (let ni = 0; ni < needle.length; ni++) {
    const idx = haystack.indexOf(needle[ni], hi);
    if (idx === -1) return false;
    hi = idx + 1;
  }
  return true;
}

function fuzzyMatch(item: string, query: string): boolean {
  if (!query) return true;
  const lower = item.toLowerCase();
  const tokens = query.toLowerCase().split(/\s+/).filter(Boolean);
  return tokens.every((t) => subsequence(lower, t));
}

function toSingleLinePreview(text: string): string {
  return text.replace(/\s+/g, " ").trim();
}

/** Highlight matched characters (subsequence) with underline + accent color. */
function highlightMatch(
  text: string,
  query: string,
  theme: any,
  maxWidth: number,
): string {
  // Truncate plain text first to ensure it fits
  const truncated = truncateToWidth(text, maxWidth);
  // Strip any ANSI that truncateToWidth might have added for ellipsis
  const plain = truncated.replace(/\x1b\[[0-9;]*m/g, "");

  if (!query) return theme.fg("text", plain);

  // Find positions of subsequence-matched characters
  const lower = plain.toLowerCase();
  const tokens = query.toLowerCase().split(/\s+/).filter(Boolean);
  const matchPositions = new Set<number>();

  for (const token of tokens) {
    let hi = 0;
    for (let ni = 0; ni < token.length; ni++) {
      const idx = lower.indexOf(token[ni], hi);
      if (idx !== -1) {
        matchPositions.add(idx);
        hi = idx + 1;
      }
    }
  }

  // Build styled string — group consecutive chars to reduce ANSI overhead
  let result = "";
  let i = 0;
  while (i < plain.length) {
    if (matchPositions.has(i)) {
      // Collect consecutive matched chars
      let j = i;
      while (j < plain.length && matchPositions.has(j)) j++;
      // Accent color + underline
      result += `\x1b[4m${theme.fg("accent", plain.slice(i, j))}\x1b[24m`;
      i = j;
    } else {
      // Collect consecutive non-matched chars
      let j = i;
      while (j < plain.length && !matchPositions.has(j)) j++;
      result += theme.fg("text", plain.slice(i, j));
      i = j;
    }
  }
  return result;
}

/**
 * fzf / atuin style popup: a scrollable list of history candidates that filters
 * live as you type, with the selected row rendered as a full-width highlight bar.
 *
 * Layout (top → bottom, anchored to the bottom of the screen):
 *   ┌ older matches …
 *   │ ▌ selected match      ← full-width highlight bar
 *   └ newer matches …       ← newest match sits just above the prompt
 *   > query█                              1/57
 *   ↑ older · ↓ newer · enter accept · esc cancel
 */
class HistoryPopupComponent implements Component, Focusable {
  private _focused = false;
  private readonly input = new Input();

  private query = "";
  /** Indices into `history` that match the query, newest-first. */
  private matchIndices: number[] = [];
  /** Pointer into `matchIndices`; 0 = newest match. */
  private matchPointer = 0;

  constructor(
    private readonly tui: TUI,
    private readonly theme: any,
    private readonly history: string[],
    private readonly done: Done,
  ) {
    this.input.onEscape = () => this.done(null);
    this.input.onSubmit = () => {
      const match = this.getCurrentMatch();
      this.done(match ?? null);
    };
    this.recomputeMatches(true);
  }

  get focused(): boolean {
    return this._focused;
  }

  set focused(value: boolean) {
    this._focused = value;
    this.input.focused = value;
  }

  private recomputeMatches(resetPointer: boolean): void {
    const matches: number[] = [];
    for (let i = 0; i < this.history.length; i++) {
      if (fuzzyMatch(this.history[i]!, this.query)) {
        matches.push(i);
      }
    }
    this.matchIndices = matches;
    if (resetPointer) this.matchPointer = 0;
    if (this.matchPointer >= this.matchIndices.length) {
      this.matchPointer = Math.max(0, this.matchIndices.length - 1);
    }
  }

  private getCurrentMatch(): string | undefined {
    if (this.matchIndices.length === 0) return undefined;
    const index = this.matchIndices[this.matchPointer];
    return this.history[index!];
  }

  /** Move selection toward older entries (clamped). */
  private moveOlder(): void {
    if (this.matchIndices.length === 0) return;
    this.matchPointer = Math.min(
      this.matchPointer + 1,
      this.matchIndices.length - 1,
    );
  }

  /** Move selection toward newer entries (clamped). */
  private moveNewer(): void {
    if (this.matchIndices.length === 0) return;
    this.matchPointer = Math.max(this.matchPointer - 1, 0);
  }

  handleInput(data: string): void {
    // Older: ↑ / Ctrl+P / Ctrl+R
    if (
      matchesKey(data, Key.up) ||
      matchesKey(data, Key.ctrl("p")) ||
      matchesKey(data, Key.ctrl("r"))
    ) {
      this.moveOlder();
      this.tui.requestRender();
      return;
    }

    // Newer: ↓ / Ctrl+N / Ctrl+S
    if (
      matchesKey(data, Key.down) ||
      matchesKey(data, Key.ctrl("n")) ||
      matchesKey(data, Key.ctrl("s"))
    ) {
      this.moveNewer();
      this.tui.requestRender();
      return;
    }

    // Cancel: Ctrl+G / Ctrl+C (Esc is handled via input.onEscape)
    if (matchesKey(data, Key.ctrl("g")) || matchesKey(data, Key.ctrl("c"))) {
      this.done(null);
      return;
    }

    const before = this.input.getValue();
    this.input.handleInput(data);
    const after = this.input.getValue();

    if (after !== before) {
      this.query = after;
      this.recomputeMatches(true);
    }

    this.tui.requestRender();
  }

  /** Compute the visible window [start, end) over matchIndices, selection centered. */
  private windowBounds(): { start: number; end: number } {
    const total = this.matchIndices.length;
    const size = Math.min(LIST_ROWS, total);
    const half = Math.floor(size / 2);
    const start = Math.max(
      0,
      Math.min(this.matchPointer - half, Math.max(0, total - size)),
    );
    return { start, end: Math.min(start + size, total) };
  }

  /** Render one history row. Selected rows become a full-width highlight bar. */
  private renderRow(
    matchIdx: number,
    isSelected: boolean,
    width: number,
  ): string {
    const t = this.theme;
    const text = toSingleLinePreview(
      this.history[this.matchIndices[matchIdx]!]!,
    );
    const prefix = isSelected ? "▌ " : "  ";
    const textWidth = Math.max(1, width - visibleWidth(prefix));

    if (!isSelected) {
      const body = truncateToWidth(text, textWidth);
      return t.fg("muted", prefix) + t.fg("dim", body);
    }

    // Highlight matched chars, then pad to full width so the bar spans the row.
    const body = highlightMatch(text, this.query, t, textWidth);
    const used = visibleWidth(prefix) + visibleWidth(body);
    const pad = " ".repeat(Math.max(0, width - used));
    return t.bg("selectedBg", t.fg("accent", prefix) + body + pad);
  }

  /** Pad or truncate a (possibly ANSI-styled) string to exactly `w` columns. */
  private fit(text: string, w: number): string {
    const vis = visibleWidth(text);
    if (vis > w) return truncateToWidth(text, w);
    return text + " ".repeat(w - vis);
  }

  render(width: number): string[] {
    const t = this.theme;
    const border = (s: string) => t.fg("border", s);
    const total = this.matchIndices.length;

    // Interior width inside the frame: "│ " + content + " │"  ⇒  width - 4.
    const inner = Math.max(10, width - 4);

    // ── Content lines, each rendered to `inner` columns ──────────────────────
    const content: string[] = [];
    if (total === 0) {
      // Keep the box height stable so the prompt doesn't jump around.
      for (let i = 0; i < LIST_ROWS - 1; i++) content.push("");
      content.push(t.fg("warning", "no match"));
    } else {
      const { start, end } = this.windowBounds();
      // Build rows newest-first, then reverse so the newest match sits at the
      // bottom of the list, right above the prompt.
      const rows: string[] = [];
      for (let i = start; i < end; i++) {
        rows.push(this.renderRow(i, i === this.matchPointer, inner));
      }
      rows.reverse();
      while (rows.length < LIST_ROWS) rows.unshift("");
      content.push(...rows);
    }

    // Prompt line — the Input component renders its OWN "> " prompt and pads to
    // `inner`, so we must NOT prepend another "> " (that caused the "> >" bug).
    content.push(this.input.render(inner)[0] ?? "");

    // Status / help line: counter + key hints.
    const counter = total > 0 ? `${this.matchPointer + 1}/${total}` : "0/0";
    content.push(
      t.fg("dim", `${counter}  ↑ older · ↓ newer · enter accept · esc cancel`),
    );

    // ── Frame it as a floating dialog ────────────────────────────────────────
    const title = " 🔍 history ";
    const dashes = Math.max(0, width - 3 - visibleWidth(title));
    const top = border("╭─" + title + "─".repeat(dashes) + "╮");
    const bottom = border("╰" + "─".repeat(Math.max(0, width - 2)) + "╯");
    const framed = content.map(
      (line) => border("│") + " " + this.fit(line, inner) + " " + border("│"),
    );

    return [top, ...framed, bottom];
  }

  invalidate(): void {
    this.input.invalidate();
  }
}

// ─── History Collection ────────────────────────────────────────────────────────

/** Collect user messages from the current session branch (for up-to-date search). */
function collectBranchHistory(ctx: any): string[] {
  const history: string[] = [];
  try {
    for (const entry of ctx.sessionManager.getBranch()) {
      if (entry.type !== "message") continue;
      const message = entry.message as Record<string, any>;
      if (message.role !== "user") continue;
      const text = extractText(message.content)?.trim();
      if (text && text.length > 0) history.push(text);
    }
  } catch {}
  return history.reverse(); // newest first
}

/** Merge branch history (current session) with cached cross-session history, deduplicated. */
function mergeHistory(branchHistory: string[], cached: string[]): string[] {
  const seen = new Set<string>();
  const merged: string[] = [];
  for (const item of branchHistory) {
    if (!seen.has(item)) {
      seen.add(item);
      merged.push(item);
    }
  }
  for (const item of cached) {
    if (!seen.has(item)) {
      seen.add(item);
      merged.push(item);
    }
  }
  return merged;
}

async function loadRecentPrompts(
  cwd: string,
  maxMessages: number,
): Promise<string[]> {
  try {
    const sessions = await SessionManager.list(cwd);
    const sorted = sessions.sort(
      (a, b) => b.modified.getTime() - a.modified.getTime(),
    );
    const allMessages: string[] = [];
    const seen = new Set<string>();

    for (const session of sorted) {
      if (allMessages.length >= maxMessages) break;
      const userMessages = extractUserMessages(session.path);
      for (const msg of userMessages) {
        if (allMessages.length >= maxMessages) break;
        const trimmed = msg.trim();
        if (trimmed && !seen.has(trimmed)) {
          seen.add(trimmed);
          allMessages.push(trimmed);
        }
      }
    }
    return allMessages;
  } catch {
    return [];
  }
}

function extractUserMessages(sessionPath: string): string[] {
  try {
    const entries = SessionManager.open(sessionPath).getEntries();
    const messages: string[] = [];
    for (const entry of entries) {
      if (entry.type !== "message" || entry.message.role !== "user") continue;
      const text = extractText(entry.message.content);
      if (text) messages.push(text);
    }
    // Reverse so newest messages come first within each session
    return messages.reverse();
  } catch {
    return [];
  }
}

function extractText(content: UserMessage["content"]): string | null {
  if (typeof content === "string") return content || null;
  return (
    content.find(
      (c): c is { type: "text"; text: string } =>
        c.type === "text" && typeof c.text === "string" && c.text.length > 0,
    )?.text ?? null
  );
}
