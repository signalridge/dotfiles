import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export interface ContextUsageSnapshot {
  tokens: number | null;
  contextWindow: number;
}

interface FileOperationsSnapshot {
  read: Set<string>;
  written: Set<string>;
  edited: Set<string>;
}

type SummaryGenerator = (typeof import("@earendil-works/pi-coding-agent"))["generateSummary"];

export interface EarlyCompactionOptions {
  generateSummary: SummaryGenerator;
  now?: () => number;
}

/** Independent headroom used to trigger early compaction during a tool loop. */
export const DEFAULT_RESERVE_TOKENS = 96_000;
/** generateSummary maps 80% of this reserve to the response cap: 8,192 tokens. */
export const SUMMARY_RESERVE_TOKENS = 10_240;
export const SUMMARY_REASONING_LEVEL = "low" as const;

const RESUME_MESSAGE =
  "Automatic mid-turn context compaction completed. Continue the current user task from the compaction summary without asking for confirmation.";

const COMPACTION_INSTRUCTIONS =
  "Preserve the current user goal, constraints, completed work, pending tool-loop actions, critical command and tool results, and all read or modified file paths so work can resume immediately.";

export function resolveReserveTokens(value = process.env.PI_EARLY_COMPACTION_RESERVE_TOKENS): number {
  if (value === undefined || value.trim() === "") return DEFAULT_RESERVE_TOKENS;
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed >= 0 ? Math.floor(parsed) : DEFAULT_RESERVE_TOKENS;
}

export function shouldCompactBeforeNextToolTurn(
  usage: ContextUsageSnapshot | undefined,
  stopReason: string | undefined,
  reserveTokens = DEFAULT_RESERVE_TOKENS,
): boolean {
  if (stopReason !== "toolUse" || !usage || usage.tokens === null || usage.contextWindow <= 0) {
    return false;
  }
  return usage.tokens > usage.contextWindow - reserveTokens;
}

function filesFromTag(summary: string | undefined, tag: "read-files" | "modified-files"): Set<string> {
  const files = new Set<string>();
  if (!summary) return files;

  const sections = summary.matchAll(new RegExp(`<${tag}>\\s*([\\s\\S]*?)\\s*</${tag}>`, "gi"));
  for (const section of sections) {
    for (const line of section[1].split("\n")) {
      const path = line.trim();
      if (path && path !== "(none)") files.add(path);
    }
  }
  return files;
}

function stripFileTags(summary: string): string {
  return summary
    .replace(/\n*<(?:read-files|modified-files)>\s*[\s\S]*?\s*<\/(?:read-files|modified-files)>/gi, "")
    .trimEnd();
}

export function mergeFileTracking(previousSummary: string | undefined, fileOps: FileOperationsSnapshot) {
  const modifiedFiles = new Set([
    ...filesFromTag(previousSummary, "modified-files"),
    ...fileOps.written,
    ...fileOps.edited,
  ]);
  const readFiles = new Set([...filesFromTag(previousSummary, "read-files"), ...fileOps.read]);
  for (const path of modifiedFiles) readFiles.delete(path);

  return {
    readFiles: [...readFiles].sort(),
    modifiedFiles: [...modifiedFiles].sort(),
  };
}

function appendFileTracking(
  summary: string,
  files: { readFiles: string[]; modifiedFiles: string[] },
): string {
  const readFiles = files.readFiles.length > 0 ? files.readFiles.join("\n") : "(none)";
  const modifiedFiles = files.modifiedFiles.length > 0 ? files.modifiedFiles.join("\n") : "(none)";
  return `${stripFileTags(summary)}\n\n<read-files>\n${readFiles}\n</read-files>\n\n<modified-files>\n${modifiedFiles}\n</modified-files>`;
}

export default function createEarlyCompaction(pi: ExtensionAPI, options: EarlyCompactionOptions) {
  const summarize = options.generateSummary;
  const now = options.now ?? Date.now;
  let active = false;
  let compacting = false;
  let startedAt = 0;

  const notify = (
    ctx: {
      hasUI: boolean;
      ui: { notify(message: string, level: "info" | "warning" | "error"): void };
    },
    message: string,
    level: "info" | "warning" | "error",
  ) => {
    try {
      if (active && ctx.hasUI) ctx.ui.notify(message, level);
    } catch {
      // A reload or session replacement invalidates captured extension contexts.
    }
  };

  pi.on("session_start", () => {
    active = true;
    compacting = false;
  });

  pi.on("session_shutdown", () => {
    active = false;
    compacting = false;
  });

  pi.on("session_before_compact", async (event, ctx) => {
    if (!compacting || event.reason !== "manual") return;

    const model = ctx.model;
    if (!model) return;

    const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
    if (!auth.ok) {
      notify(ctx, `Fast early-compaction auth failed; using Pi fallback: ${auth.error}`, "warning");
      return;
    }

    const { preparation, signal } = event;
    const messages = [...preparation.messagesToSummarize, ...preparation.turnPrefixMessages];
    notify(ctx, `Generating compact summary with ${model.id} (low reasoning, 8K output cap)`, "info");

    try {
      const summary = await summarize(
        messages,
        model,
        SUMMARY_RESERVE_TOKENS,
        auth.apiKey,
        auth.headers,
        signal,
        COMPACTION_INSTRUCTIONS,
        preparation.previousSummary,
        SUMMARY_REASONING_LEVEL,
        undefined,
        auth.env,
      );
      if (!summary.trim()) throw new Error("summary was empty");

      const files = mergeFileTracking(preparation.previousSummary, preparation.fileOps);
      return {
        compaction: {
          summary: appendFileTracking(summary, files),
          firstKeptEntryId: preparation.firstKeptEntryId,
          tokensBefore: preparation.tokensBefore,
          details: files,
        },
      };
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      notify(ctx, `Fast early compaction failed; using Pi fallback: ${message}`, "warning");
      return;
    }
  });

  pi.on("turn_end", (event, ctx) => {
    if (!active || compacting) return;

    const usage = ctx.getContextUsage();
    const reserveTokens = resolveReserveTokens();
    if (!shouldCompactBeforeNextToolTurn(usage, event.message.stopReason, reserveTokens)) return;

    compacting = true;
    startedAt = now();
    const tokensBefore = usage!.tokens!;
    const threshold = usage!.contextWindow - reserveTokens;
    const percent = Math.round((tokensBefore / usage!.contextWindow) * 100);

    notify(
      ctx,
      `Context ${percent}% (${tokensBefore.toLocaleString()} tokens); starting early compaction`,
      "warning",
    );

    ctx.compact({
      customInstructions: COMPACTION_INSTRUCTIONS,
      onComplete: (result) => {
        if (!active) return;
        compacting = false;
        const elapsedSeconds = Math.max(0, now() - startedAt) / 1000;
        const estimatedAfter = result.estimatedTokensAfter;
        const afterText =
          estimatedAfter === undefined ? "unknown" : `~${estimatedAfter.toLocaleString()} tokens`;
        notify(
          ctx,
          `Early compaction completed in ${elapsedSeconds.toFixed(1)}s (${tokensBefore.toLocaleString()} → ${afterText})`,
          "info",
        );
        try {
          pi.sendMessage(
            {
              customType: "pi-early-compaction-resume",
              content: RESUME_MESSAGE,
              display: false,
              details: { tokensBefore, threshold },
            },
            { triggerTurn: true, deliverAs: "steer" },
          );
        } catch {
          // The old extension runtime may have been invalidated during replacement.
        }
      },
      onError: (error) => {
        if (!active) return;
        compacting = false;
        notify(ctx, `Early compaction failed: ${error.message}`, "error");
      },
    });
  });
}
