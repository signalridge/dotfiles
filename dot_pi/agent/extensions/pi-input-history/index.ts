/**
 * Persistent History + Ctrl+R Reverse Search
 *
 * - Loads recent prompts from previous sessions into up/down history on startup.
 * - Ctrl+R opens a reverse search overlay (fuzzy subsequence matching).
 *
 * Hotkeys while searching:
 * - Ctrl+R / ↑ : older match
 * - Ctrl+S / ↓ : newer match
 * - Enter      : accept match (fills editor)
 * - Esc/Ctrl+G : cancel
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
  type Component,
  type Focusable,
  type TUI,
} from "@earendil-works/pi-tui";

const MAX_MESSAGES = 100;

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

  // Ctrl+R: reverse search
  pi.registerShortcut("ctrl+r", {
    description: "Reverse search through prompt history",
    handler: async (ctx) => {
      // Merge cached history with current session's branch history
      const branchHistory = collectBranchHistory(ctx);
      const merged = mergeHistory(branchHistory, historyCache);

      if (merged.length === 0) {
        ctx.ui.notify("No prompt history yet.", "info");
        return;
      }

      const selected = await ctx.ui.custom<string | null>((tui, theme, _kb, done) => {
        return new ReverseSearchComponent(tui, theme, merged, done);
      }, { overlay: true, overlayOptions: { anchor: "bottom-center", width: "100%" } });

      if (selected === null) return;
      ctx.ui.setEditorText(selected);
    },
  });
}

// ─── Reverse Search Component ──────────────────────────────────────────────────

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
function highlightMatch(text: string, query: string, theme: any, maxWidth: number): string {
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

class ReverseSearchComponent implements Component, Focusable {
  private _focused = false;
  private readonly input = new Input();

  private query = "";
  private matchIndices: number[] = [];
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

  private cycleOlder(): void {
    if (this.matchIndices.length === 0) return;
    this.matchPointer = (this.matchPointer + 1) % this.matchIndices.length;
  }

  private cycleNewer(): void {
    if (this.matchIndices.length === 0) return;
    this.matchPointer = (this.matchPointer - 1 + this.matchIndices.length) % this.matchIndices.length;
  }

  handleInput(data: string): void {
    if (matchesKey(data, Key.ctrl("r")) || matchesKey(data, Key.up)) {
      this.cycleOlder();
      this.tui.requestRender();
      return;
    }

    if (matchesKey(data, Key.ctrl("s")) || matchesKey(data, Key.down)) {
      this.cycleNewer();
      this.tui.requestRender();
      return;
    }

    if (matchesKey(data, Key.ctrl("g"))) {
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

  render(width: number): string[] {
    const t = this.theme;
    const currentMatch = this.getCurrentMatch();

    // Reserve space for prefix and counter (use fixed max counter width)
    const prefix = "(reverse-search) ";
    const maxCounterWidth = 10; // " [xx/xx]" is enough
    const availableWidth = Math.max(10, width - prefix.length - maxCounterWidth);

    const counterText = this.matchIndices.length > 0
      ? ` [${this.matchPointer + 1}/${this.matchIndices.length}]`
      : " [0/0]";

    const matchPreview = currentMatch
      ? highlightMatch(toSingleLinePreview(currentMatch), this.query, t, availableWidth)
      : t.fg("warning", "no match");

    const counter = t.fg("dim", counterText);

    const header =
      t.fg("accent", prefix) +
      matchPreview +
      counter;

    const inputLine = truncateToWidth(this.input.render(width)[0] ?? "", width);
    const help = truncateToWidth(t.fg("dim", "ctrl+r/↑ older • ctrl+s/↓ newer • enter accept • esc cancel"), width);

    return [truncateToWidth(header, width), inputLine, help];
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
