/**
 * Kimi-Code-style startup card for pi.
 *
 * Kimi Code opens with a rounded full-width card: a brand mark, a one-line
 * "what to do next", and an aligned label column of session facts. This
 * extension reproduces that layout with pi's own data and the active pi theme,
 * so nothing here carries Kimi's palette or its brand mark.
 *
 * It ADDS to pi's startup rather than replacing it. `quietStartup` must stay
 * false: the same flag also gates showLoadedResources(), so silencing the
 * header deletes the [Context]/[Skills]/[Extensions]/[Themes] listing with it.
 * So pi keeps the key hints, the onboarding line, the ctrl+o expansion and the
 * resource listing; this card carries only what pi does not show — directory,
 * branch, session, model, context budget and tool counts. It deliberately
 * repeats none of pi's hints, so nothing is printed twice.
 *
 * The card is a CUSTOM ENTRY, not a widget: it lands in the transcript, scrolls
 * away as the conversation grows, and survives a reload — exactly how Kimi's
 * behaves. Facts are captured once at session_start and stored in the entry, so
 * a resumed session redraws the card as it was, not as it would be today.
 */

import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { basename, join } from "node:path";

import {
  DefaultResourceLoader,
  getAgentDir,
  VERSION,
  type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";
import {
  truncateToWidth,
  visibleWidth,
  wrapTextWithAnsi,
  type Component,
} from "@earendil-works/pi-tui";

const ENTRY_TYPE = "welcome-card";

/** Two rows of blocks that read as π — pi's own mark, not Kimi's. */
const LOGO = ["█████", " █ █ "];

/** Columns of padding inside the card, matching Kimi's roomy interior. */
const PAD = 3;

/** Narrowest card worth drawing; below this the labels crowd out every value. */
const MIN_WIDTH = 24;

/** Sentinel row rendered as a blank line, separating the card's two groups. */
const GAP: [string, string] = ["", ""];

interface WelcomeData {
  rows: [string, string][];
}

// ─── Fact Collection ───────────────────────────────────────────────────────────

function tildify(path: string): string {
  const home = homedir();
  return path === home || path.startsWith(`${home}/`)
    ? `~${path.slice(home.length)}`
    : path;
}

/** `main [+392 -202]`, or undefined outside a repo. Best-effort and never throws. */
function gitSummary(cwd: string): string | undefined {
  const git = (args: string[]): string | undefined => {
    try {
      return execFileSync("git", args, {
        cwd,
        encoding: "utf8",
        timeout: 1000,
        stdio: ["ignore", "pipe", "ignore"],
      }).trim();
    } catch {
      return undefined;
    }
  };

  const branch = git(["rev-parse", "--abbrev-ref", "HEAD"]);
  if (!branch) return undefined;

  // --numstat over HEAD covers staged + unstaged; untracked files are excluded
  // on purpose, matching what `git diff` itself reports.
  const numstat = git(["diff", "HEAD", "--numstat"]);
  if (!numstat) return branch;

  let added = 0;
  let removed = 0;
  for (const line of numstat.split("\n")) {
    const [a, r] = line.split("\t");
    // Binary files report "-" for both counts.
    added += Number.parseInt(a ?? "", 10) || 0;
    removed += Number.parseInt(r ?? "", 10) || 0;
  }
  return added || removed ? `${branch} [+${added} -${removed}]` : branch;
}

/**
 * `compaction.reserveTokens` from settings.json. ExtensionContext does not carry
 * settings, so this reads the same file pi does — the trigger point is worth the
 * one stat() because it, not the raw window, is what a long session runs into.
 */
function readReserveTokens(): number | undefined {
  try {
    const raw = readFileSync(join(getAgentDir(), "settings.json"), "utf8");
    const value = JSON.parse(raw)?.compaction?.reserveTokens;
    return typeof value === "number" ? value : undefined;
  } catch {
    return undefined;
  }
}

function formatTokens(n: number): string {
  if (n >= 1_000_000)
    return `${(n / 1_000_000).toFixed(n % 1_000_000 === 0 ? 0 : 1)}M`;
  if (n >= 1_000) return `${Math.round(n / 1_000)}K`;
  return String(n);
}

function collect(pi: ExtensionAPI, ctx: any): WelcomeData {
  const rows: [string, string][] = [];
  const push = (label: string, value: string | undefined) => {
    if (value) rows.push([label, value]);
  };

  const trusted = (() => {
    try {
      return ctx.isProjectTrusted() ? "" : "  (untrusted)";
    } catch {
      return "";
    }
  })();
  push("Directory", tildify(ctx.cwd) + trusted);
  push("Branch", gitSummary(ctx.cwd));

  // Only a NAME is worth a row. The raw session id is a timestamp glued to a
  // uuid; it is unreadable, identical in shape every time, and pushes the
  // interesting rows down. Kimi leaves this blank for a fresh session.
  push("Session", pi.getSessionName?.() || "(new)");

  const model = ctx.model;
  if (model) {
    const id = model.id ?? model.modelId ?? "unknown";
    const provider = model.provider ?? model.providerId;
    const thinking = ctx.thinkingLevel
      ? ` · thinking ${ctx.thinkingLevel}`
      : "";
    push("Model", `${provider ? `${provider} / ` : ""}${id}${thinking}`);

    const window = model.contextWindow ?? model.contextLength;
    if (typeof window === "number" && window > 0) {
      // Pi compacts at contextWindow - reserveTokens; surfacing the trigger up
      // front is the one number that actually governs a long session.
      const reserve = readReserveTokens();
      const trigger =
        typeof reserve === "number" && reserve > 0 && reserve < window
          ? ` · compacts at ${formatTokens(window - reserve)}`
          : "";
      push("Budget", `${formatTokens(window)}${trigger}`);
    }
  }

  try {
    const all = pi.getAllTools?.() ?? [];
    const active = pi.getActiveTools?.() ?? [];
    if (all.length) {
      push("Tools", `${active.length} active of ${all.length}`);
    }
  } catch {}

  push("Version", VERSION);
  return { rows };
}

/**
 * The loaded-resource listing, taken from pi's OWN loader rather than a
 * directory scan of our own: `quietStartup` silences pi's `[Skills]` /
 * `[Extensions]` / `[Themes]` / `[Context]` block (one flag gates both the
 * header and showLoadedResources), so the card has to carry it — but it should
 * carry pi's answer, not a second opinion that drifts the moment pi changes how
 * it resolves packages or project scope.
 *
 * Verified against `pi --verbose` on 2026-08-09: same skills, same themes, same
 * extension count. Only the extension LABELS are ours (pi's
 * getCompactNonPackageExtensionLabel is internal), hence labelExtension below.
 */
async function collectResources(cwd: string): Promise<[string, string][]> {
  const rows: [string, string][] = [];
  try {
    const agentDir = getAgentDir();
    const loader = new DefaultResourceLoader({ cwd, agentDir });
    // The getters return empty until reload() populates them.
    await loader.reload();

    const list = (values: string[]) =>
      values
        .filter(Boolean)
        .sort((a, b) => a.localeCompare(b))
        .join(", ");
    const push = (label: string, value: string) => {
      if (value) rows.push([label, value]);
    };

    push(
      "Context",
      // pi's [Context] is the AGENTS.md files PLUS the system-prompt sources
      // (e.g. ~/.pi/agent/APPEND_SYSTEM.md). Omitting the latter was the one
      // place this listing disagreed with `pi --verbose`.
      list([
        ...loader.getAgentsFiles().agentsFiles.map((f) => basename(f.path)),
        ...loader.getAppendSystemPromptSources().map((s) => basename(s.path)),
        ...(loader.getSystemPromptSource()
          ? [basename(loader.getSystemPromptSource()!.path)]
          : []),
      ]),
    );
    push("Skills", list(loader.getSkills().skills.map((s) => s.name)));
    push("Prompts", list(loader.getPrompts().prompts.map((p: any) => p.name)));
    push("Themes", list(loader.getThemes().themes.map((t: any) => t.name)));
    push(
      "Extensions",
      list(
        (loader.getExtensions().extensions ?? [])
          .filter((e: any) => !e.hidden)
          .map((e: any) => labelExtension(e.path, agentDir)),
      ),
    );
  } catch {
    // A missing listing is not worth failing a session start over.
  }
  return rows;
}

/**
 * `~/.pi/agent/extensions/pi-input-history/index.ts` -> `pi-input-history`,
 * `.../herdr-pi-state.ts` -> `herdr-pi-state.ts`, anything deeper or installed
 * from a package -> its own basename. Mirrors what pi prints closely enough to
 * be recognisable; the SET of extensions is authoritative either way.
 */
function labelExtension(path: string, agentDir: string): string {
  const root = join(agentDir, "extensions") + "/";
  if (path.startsWith(root)) {
    const rest = path.slice(root.length);
    const segments = rest.split("/");
    if (segments.length === 2 && segments[1] === "index.ts")
      return segments[0]!;
    if (segments.length === 1) return segments[0]!;
  }
  const packaged = path.match(/node_modules\/((?:@[^/]+\/)?[^/]+)\//);
  return packaged?.[1] ?? basename(path);
}

// ─── Card Component ────────────────────────────────────────────────────────────

export class WelcomeCard implements Component {
  constructor(
    private readonly data: WelcomeData,
    private readonly theme: any,
  ) {}

  /** Pad or truncate a (possibly styled) string to exactly `w` columns. */
  private fit(text: string, w: number): string {
    const vis = visibleWidth(text);
    if (vis > w) return truncateToWidth(text, w);
    return text + " ".repeat(w - vis);
  }

  render(width: number): string[] {
    const t = this.theme;
    const border = (s: string) => t.fg("border", s);
    // Full width, like Kimi's — the card lines up with the input box below it.
    const outer = Math.max(MIN_WIDTH, width);
    const inner = outer - 2; // interior between the two vertical rules

    const line = (content: string) =>
      border("│") + this.fit(content, inner) + border("│");
    const blank = () => line("");

    const pad = " ".repeat(PAD);
    const body: string[] = [blank()];

    // Brand block: two logo rows sitting beside the title and subtitle.
    const logoWidth = Math.max(...LOGO.map(visibleWidth));
    body.push(
      line(
        pad +
          t.fg("accent", LOGO[0]!.padEnd(logoWidth)) +
          pad +
          t.bold(t.fg("text", "Welcome to pi")),
      ),
    );
    body.push(
      line(
        pad +
          t.fg("accent", LOGO[1]!.padEnd(logoWidth)) +
          pad +
          t.fg("muted", "Send /help for help information."),
      ),
    );
    body.push(blank());

    // Aligned label column — the detail that makes Kimi's card read as a table
    // rather than a list.
    // Colon included in the pad, then a single space — the longest label ends up
    // exactly one column from its value, like Kimi's.
    const labelWidth =
      Math.max(...this.data.rows.map(([l]) => visibleWidth(l))) + 2;
    for (const [label, value] of this.data.rows) {
      if (label === GAP[0] && value === GAP[1]) {
        body.push(blank());
        continue;
      }
      const gutter = pad + `${label}:`.padEnd(labelWidth);
      const room = Math.max(8, inner - visibleWidth(gutter) - PAD);
      // Resource lists are long; wrap them under the value column instead of
      // truncating, or "Extensions" silently loses most of its entries.
      const [head, ...tail] = wrapTextWithAnsi(value, room);
      body.push(line(t.fg("dim", gutter) + t.fg("text", head ?? "")));
      for (const cont of tail) {
        body.push(line(" ".repeat(visibleWidth(gutter)) + t.fg("text", cont)));
      }
    }
    body.push(blank());

    const rule = (l: string, r: string) => border(l + "─".repeat(inner) + r);
    return [rule("╭", "╮"), ...body, rule("╰", "╯")];
  }

  invalidate(): void {}
}

// ─── Extension Entry ───────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  pi.registerEntryRenderer<WelcomeData>(
    ENTRY_TYPE,
    (entry, _options, theme) => {
      const data = entry.data;
      if (!data?.rows?.length) return undefined;
      return new WelcomeCard(data, theme);
    },
  );

  pi.on("session_start", async (_event, ctx) => {
    if (ctx.mode !== "tui") return;

    // A resumed session already carries its card; appending on every
    // session_start would stack a fresh one on top at each reload.
    try {
      for (const entry of ctx.sessionManager.getEntries()) {
        if (
          entry.type === "custom" &&
          (entry as any).customType === ENTRY_TYPE
        ) {
          return;
        }
      }
    } catch {}

    try {
      const data = collect(pi, ctx);
      const resources = await collectResources(ctx.cwd);
      if (resources.length) {
        // GAP is the sentinel for a blank row: session facts above, what pi
        // loaded below, so the card reads as two groups rather than one wall.
        data.rows.push(GAP, ...resources);
      }
      pi.appendEntry<WelcomeData>(ENTRY_TYPE, data);
    } catch {
      // A missing card is not worth failing a session start over.
    }
  });
}
