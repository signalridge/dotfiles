/**
 * Persistent History + Ctrl+R Fuzzy Popup (fzf / atuin style)
 *
 * - Loads recent prompts from previous sessions into up/down history on startup.
 * - Ctrl+R opens a large two-pane popup: a filterable list on the left (row
 *   number + age + one-line summary) and the FULL text of the highlighted entry
 *   on the right, `fzf --preview` style. Newest entry sits at the top.
 *
 * Hotkeys while searching:
 * - ↑ / Ctrl+P / Ctrl+S : move up (toward newer)
 * - ↓ / Ctrl+N / Ctrl+R : move down (toward older — "press ctrl+R again to go further back")
 * - Ctrl+D / Ctrl+U     : scroll the preview pane
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
  wrapTextWithAnsi,
  type Component,
  type Focusable,
  type TUI,
} from "@earendil-works/pi-tui";

const MAX_MESSAGES = 100;

/** Popup footprint, as a fraction of the terminal. */
const POPUP_WIDTH = "90%";
const POPUP_MAX_HEIGHT = "85%";
/** Same fraction as POPUP_MAX_HEIGHT — used to size the list to the popup. */
const POPUP_HEIGHT_FRACTION = 0.85;

/** Share of the popup interior handed to the preview pane. */
const PREVIEW_FRACTION = 0.42;
/** Columns the preview never drops below, and the list never drops below. */
const MIN_PREVIEW_WIDTH = 24;
const MIN_LIST_WIDTH = 30;
/** Under this total width there is no room to split; the list goes full-width. */
const MIN_WIDTH_FOR_PREVIEW = 76;

/** Ceiling on the list height, so a very tall terminal does not get an absurd popup. */
const MAX_LIST_ROWS = 40;

/** Width of the right-aligned age column ("now", "59m", "23h", "364d"). */
const AGE_WIDTH = 4;

interface HistoryEntry {
  text: string;
  /** Epoch ms taken from the session entry that recorded this prompt. */
  timestamp?: number;
}

// ─── Extension Entry ───────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  let historyCache: HistoryEntry[] = [];
  let historyReady: Promise<void> = Promise.resolve();
  let loadGeneration = 0;

  pi.on("session_start", (_event, ctx) => {
    const generation = ++loadGeneration;
    historyCache = [];

    // Do not block later session_start handlers: the Kimi editor must replace
    // Pi's bootstrap editor immediately instead of waiting for session I/O.
    historyReady = loadRecentPrompts(ctx.cwd, MAX_MESSAGES)
      .then((items) => {
        if (generation !== loadGeneration) return;
        historyCache = items;
        if (items.length === 0) return;

        const prevComponentFactory = ctx.ui.getEditorComponent();
        ctx.ui.setEditorComponent((tui, theme, keybindings) => {
          const editor =
            prevComponentFactory?.(tui, theme, keybindings) ??
            new CustomEditor(tui, theme, keybindings);

          for (let i = items.length - 1; i >= 0; i--) {
            editor.addToHistory?.(items[i]!.text);
          }
          return editor;
        });
      })
      .catch(() => undefined);
  });

  pi.on("session_shutdown", () => {
    loadGeneration++;
    historyReady = Promise.resolve();
  });

  // Ctrl+R: fuzzy history popup (fzf / atuin style)
  pi.registerShortcut("ctrl+r", {
    description: "Fuzzy popup search through prompt history",
    handler: async (ctx) => {
      // If invoked during startup, wait for the background history scan rather
      // than briefly reporting an empty history.
      await historyReady;
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
            width: POPUP_WIDTH,
            minWidth: 40,
            maxHeight: POPUP_MAX_HEIGHT,
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

/** Compact age for the list gutter; "" when the session recorded no timestamp. */
function relativeAge(timestamp: number | undefined, now: number): string {
  if (timestamp === undefined) return "";
  const diff = now - timestamp;
  if (diff < 60_000) return "now";
  const minutes = Math.floor(diff / 60_000);
  if (minutes < 60) return `${minutes}m`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h`;
  const days = Math.floor(hours / 24);
  if (days < 365) return `${days}d`;
  return `${Math.floor(days / 365)}y`;
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
 * fzf-style two-pane popup. The list filters live as you type; the pane on the
 * right always shows the full, unsquashed text of the highlighted entry, which
 * is the whole point — one-line summaries cannot tell two long prompts apart.
 *
 * Layout (newest entry first, so the list reads top-down like a transcript):
 *   ╭─ history ────────────────────────┬──────────────────╮
 *   │    1  5m   newest match          │ full text of the │
 *   │ ▌  2  2h   selected match        │ highlighted      │
 *   │    3  1d   older match           │ entry, wrapped   │
 *   │ > query█                    2/57 │ and scrollable   │
 *   │ ↑↓ move · enter accept · …       │                  │
 *   ╰──────────────────────────────────┴──────────────────╯
 */
export class HistoryPopupComponent implements Component, Focusable {
  private _focused = false;
  private readonly input = new Input();

  private query = "";
  /** Indices into `history` that match the query, newest-first. */
  private matchIndices: number[] = [];
  /** Pointer into `matchIndices`; 0 = newest match = top row. */
  private matchPointer = 0;
  /** First visible preview line; reset whenever the selection moves. */
  private previewOffset = 0;

  constructor(
    private readonly tui: TUI,
    private readonly theme: any,
    private readonly history: HistoryEntry[],
    private readonly done: Done,
  ) {
    this.input.onEscape = () => this.done(null);
    this.input.onSubmit = () => {
      this.done(this.getCurrentEntry()?.text ?? null);
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
      if (fuzzyMatch(this.history[i]!.text, this.query)) {
        matches.push(i);
      }
    }
    this.matchIndices = matches;
    if (resetPointer) this.matchPointer = 0;
    if (this.matchPointer >= this.matchIndices.length) {
      this.matchPointer = Math.max(0, this.matchIndices.length - 1);
    }
    this.previewOffset = 0;
  }

  private getCurrentEntry(): HistoryEntry | undefined {
    if (this.matchIndices.length === 0) return undefined;
    return this.history[this.matchIndices[this.matchPointer]!];
  }

  /** Move up the list, i.e. toward newer entries (clamped). */
  private moveUp(): void {
    if (this.matchIndices.length === 0) return;
    this.matchPointer = Math.max(this.matchPointer - 1, 0);
    this.previewOffset = 0;
  }

  /** Move down the list, i.e. toward older entries (clamped). */
  private moveDown(): void {
    if (this.matchIndices.length === 0) return;
    this.matchPointer = Math.min(
      this.matchPointer + 1,
      this.matchIndices.length - 1,
    );
    this.previewOffset = 0;
  }

  handleInput(data: string): void {
    // Newer: ↑ / Ctrl+P (previous line) / Ctrl+S (forward-search counterpart)
    if (
      matchesKey(data, Key.up) ||
      matchesKey(data, Key.ctrl("p")) ||
      matchesKey(data, Key.ctrl("s"))
    ) {
      this.moveUp();
      this.tui.requestRender();
      return;
    }

    // Older: ↓ / Ctrl+N (next line) / Ctrl+R (press again to search further back)
    if (
      matchesKey(data, Key.down) ||
      matchesKey(data, Key.ctrl("n")) ||
      matchesKey(data, Key.ctrl("r"))
    ) {
      this.moveDown();
      this.tui.requestRender();
      return;
    }

    // Preview scrolling — half a pane per press, like less/fzf.
    if (matchesKey(data, Key.ctrl("d"))) {
      this.previewOffset += Math.max(1, Math.floor(this.layout().rows / 2));
      this.tui.requestRender();
      return;
    }
    if (matchesKey(data, Key.ctrl("u"))) {
      this.previewOffset = Math.max(
        0,
        this.previewOffset - Math.max(1, Math.floor(this.layout().rows / 2)),
      );
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

  /**
   * Rows the list gets, derived from the live terminal height. `render` only
   * receives a width, and the overlay sizes itself to whatever we return, so
   * the height budget has to be reconstructed from the same fraction the
   * overlay caps us at, minus the frame (2) and the query + help lines (2).
   */
  private layout(): { rows: number; showHelp: boolean } {
    const terminalRows = process.stdout.rows ?? 24;
    // Must mirror the overlay's own maths exactly: it resolves "85%" as
    // floor(termHeight * 85 / 100) and then hard-truncates anything taller with
    // `overlayLines.slice(0, maxHeight)` — from the BOTTOM, which would eat the
    // query line and leave a popup you cannot type into. So the cap is a
    // ceiling to fit under, never something to pad up to.
    const cap = Math.floor(terminalRows * POPUP_HEIGHT_FRACTION);
    // The frame (2) and the query line (1) are non-negotiable; the help line is
    // the first thing to drop when the terminal cannot afford it.
    const showHelp = cap >= 5;
    const rows = Math.max(
      1,
      Math.min(MAX_LIST_ROWS, cap - 3 - (showHelp ? 1 : 0)),
    );
    return { rows, showHelp };
  }

  /** Visible window over matchIndices, selection kept centered where possible. */
  private windowBounds(rows: number): { start: number; end: number } {
    const total = this.matchIndices.length;
    const size = Math.min(rows, total);
    const half = Math.floor(size / 2);
    const start = Math.max(
      0,
      Math.min(this.matchPointer - half, Math.max(0, total - size)),
    );
    return { start, end: Math.min(start + size, total) };
  }

  /** Render one list row. The selected row becomes a full-width highlight bar. */
  private renderRow(
    matchIdx: number,
    isSelected: boolean,
    width: number,
    indexWidth: number,
    now: number,
  ): string {
    const t = this.theme;
    const entry = this.history[this.matchIndices[matchIdx]!]!;
    const text = toSingleLinePreview(entry.text);

    const marker = isSelected ? "▌ " : "  ";
    const gutter = `${String(matchIdx + 1).padStart(indexWidth)} ${relativeAge(
      entry.timestamp,
      now,
    ).padStart(AGE_WIDTH)}  `;
    const textWidth = Math.max(
      1,
      width - visibleWidth(marker) - visibleWidth(gutter),
    );

    if (!isSelected) {
      return (
        t.fg("border", marker) +
        t.fg("dim", gutter) +
        t.fg("muted", truncateToWidth(text, textWidth))
      );
    }

    // Highlight matched chars, then pad to full width so the bar spans the row.
    const body = highlightMatch(text, this.query, t, textWidth);
    const used =
      visibleWidth(marker) + visibleWidth(gutter) + visibleWidth(body);
    const pad = " ".repeat(Math.max(0, width - used));
    return t.bg(
      "selectedBg",
      t.fg("accent", marker) + t.fg("dim", gutter) + body + pad,
    );
  }

  /** Full text of the selected entry, wrapped to the pane and scroll-clamped. */
  private renderPreview(width: number, height: number): string[] {
    const t = this.theme;
    const entry = this.getCurrentEntry();
    if (!entry || height <= 0) return [];

    const wrapped = wrapTextWithAnsi(entry.text, width);
    const maxOffset = Math.max(0, wrapped.length - height);
    // Clamp here rather than in the key handler: the pane height is only known
    // at render time, so Ctrl+D cannot know where the end is.
    this.previewOffset = Math.min(this.previewOffset, maxOffset);

    const lines = wrapped
      .slice(this.previewOffset, this.previewOffset + height)
      .map((line) => t.fg("text", line));

    if (maxOffset > 0 && lines.length > 0) {
      // Spend the last row on a scroll indicator — without it, a truncated
      // preview is indistinguishable from a short prompt.
      const remaining = maxOffset - this.previewOffset;
      const hint =
        remaining > 0
          ? `↓ ${remaining} more line${remaining === 1 ? "" : "s"} · ctrl+d/u`
          : "↑ ctrl+u to scroll back";
      lines[lines.length - 1] = t.fg("dim", truncateToWidth(hint, width));
    }
    return lines;
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
    const { rows, showHelp } = this.layout();
    const now = Date.now();

    // Two-pane frame spends 7 columns on chrome: "│ " + list + " │ " + preview + " │".
    // Single-pane spends 4: "│ " + list + " │".
    const twoPane = width >= MIN_WIDTH_FOR_PREVIEW;
    const usable = twoPane ? Math.max(10, width - 7) : Math.max(10, width - 4);
    let previewWidth = 0;
    let listWidth = usable;
    if (twoPane) {
      previewWidth = Math.max(
        MIN_PREVIEW_WIDTH,
        Math.min(
          Math.floor(usable * PREVIEW_FRACTION),
          usable - MIN_LIST_WIDTH,
        ),
      );
      listWidth = usable - previewWidth;
    }

    // ── Left pane: list + query + help ───────────────────────────────────────
    const left: string[] = [];
    if (total === 0) {
      left.push(t.fg("warning", "no match"));
      while (left.length < rows) left.push("");
    } else {
      const indexWidth = Math.max(2, String(total).length);
      const { start, end } = this.windowBounds(rows);
      for (let i = start; i < end; i++) {
        left.push(
          this.renderRow(
            i,
            i === this.matchPointer,
            listWidth,
            indexWidth,
            now,
          ),
        );
      }
      while (left.length < rows) left.push("");
    }

    // The Input renders its OWN "> " prompt and pads to the width it is handed,
    // so the counter has to live in columns withheld from it — appending to a
    // full-width render is what produced the old "> >" bug.
    const counter = ` ${total > 0 ? `${this.matchPointer + 1}/${total}` : "0/0"}`;
    const queryWidth = Math.max(4, listWidth - visibleWidth(counter));
    left.push((this.input.render(queryWidth)[0] ?? "") + t.fg("dim", counter));
    if (showHelp) {
      left.push(
        t.fg("dim", "↑↓ move · enter accept · ctrl+d/u preview · esc cancel"),
      );
    }

    // ── Right pane: full text of the selection ───────────────────────────────
    const preview = twoPane
      ? this.renderPreview(previewWidth, left.length)
      : [];

    // ── Frame ────────────────────────────────────────────────────────────────
    const title = " history ";
    const body = left.map((line, i) => {
      const listCell = border("│") + " " + this.fit(line, listWidth) + " ";
      if (!twoPane) return listCell + border("│");
      return (
        listCell +
        border("│") +
        " " +
        this.fit(preview[i] ?? "", previewWidth) +
        " " +
        border("│")
      );
    });

    if (!twoPane) {
      const dashes = Math.max(0, width - 3 - visibleWidth(title));
      return [
        border("╭─" + title + "─".repeat(dashes) + "╮"),
        ...body,
        border("╰" + "─".repeat(Math.max(0, width - 2)) + "╯"),
      ];
    }

    // Tee the borders where the panes meet so the split reads as one frame.
    const leadIn = listWidth + 3 - 2 - visibleWidth(title);
    const top =
      leadIn >= 0
        ? "╭─" +
          title +
          "─".repeat(leadIn) +
          "┬" +
          "─".repeat(previewWidth + 2) +
          "╮"
        : "╭" +
          "─".repeat(listWidth + 2) +
          "┬" +
          "─".repeat(previewWidth + 2) +
          "╮";
    const bottom =
      "╰" +
      "─".repeat(listWidth + 2) +
      "┴" +
      "─".repeat(previewWidth + 2) +
      "╯";

    return [border(top), ...body, border(bottom)];
  }

  invalidate(): void {
    this.input.invalidate();
  }
}

// ─── History Collection ────────────────────────────────────────────────────────

function parseTimestamp(value: unknown): number | undefined {
  if (typeof value !== "string") return undefined;
  const ms = Date.parse(value);
  return Number.isNaN(ms) ? undefined : ms;
}

/** Collect user messages from the current session branch (for up-to-date search). */
function collectBranchHistory(ctx: any): HistoryEntry[] {
  const history: HistoryEntry[] = [];
  try {
    for (const entry of ctx.sessionManager.getBranch()) {
      if (entry.type !== "message") continue;
      const message = entry.message as Record<string, any>;
      if (message.role !== "user") continue;
      const text = extractText(message.content)?.trim();
      if (text && text.length > 0) {
        history.push({ text, timestamp: parseTimestamp(entry.timestamp) });
      }
    }
  } catch {}
  return history.reverse(); // newest first
}

/** Merge branch history (current session) with cached cross-session history, deduplicated. */
function mergeHistory(
  branchHistory: HistoryEntry[],
  cached: HistoryEntry[],
): HistoryEntry[] {
  const seen = new Set<string>();
  const merged: HistoryEntry[] = [];
  for (const entry of [...branchHistory, ...cached]) {
    if (seen.has(entry.text)) continue;
    seen.add(entry.text);
    merged.push(entry);
  }
  return merged;
}

async function loadRecentPrompts(
  cwd: string,
  maxMessages: number,
): Promise<HistoryEntry[]> {
  try {
    const sessions = await SessionManager.list(cwd);
    const sorted = sessions.sort(
      (a, b) => b.modified.getTime() - a.modified.getTime(),
    );
    const allMessages: HistoryEntry[] = [];
    const seen = new Set<string>();

    for (const session of sorted) {
      if (allMessages.length >= maxMessages) break;
      const userMessages = extractUserMessages(session.path);
      for (const msg of userMessages) {
        if (allMessages.length >= maxMessages) break;
        const trimmed = msg.text.trim();
        if (trimmed && !seen.has(trimmed)) {
          seen.add(trimmed);
          allMessages.push({ text: trimmed, timestamp: msg.timestamp });
        }
      }
    }
    return allMessages;
  } catch {
    return [];
  }
}

function extractUserMessages(sessionPath: string): HistoryEntry[] {
  try {
    const entries = SessionManager.open(sessionPath).getEntries();
    const messages: HistoryEntry[] = [];
    for (const entry of entries) {
      if (entry.type !== "message" || entry.message.role !== "user") continue;
      const text = extractText(entry.message.content);
      if (text) {
        messages.push({ text, timestamp: parseTimestamp(entry.timestamp) });
      }
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
