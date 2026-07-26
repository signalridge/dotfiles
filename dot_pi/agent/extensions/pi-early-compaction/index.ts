import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export interface ContextUsageSnapshot {
  tokens: number | null;
  contextWindow: number;
}

/** Mirrors ~/.pi/agent/settings.json compaction.reserveTokens. */
export const DEFAULT_RESERVE_TOKENS = 96_000;

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

export default function (pi: ExtensionAPI) {
  let compacting = false;

  pi.on("session_start", () => {
    compacting = false;
  });

  pi.on("turn_end", (event, ctx) => {
    if (compacting) return;

    const usage = ctx.getContextUsage();
    const reserveTokens = resolveReserveTokens();
    if (!shouldCompactBeforeNextToolTurn(usage, event.message.stopReason, reserveTokens)) return;

    compacting = true;
    const tokensBefore = usage!.tokens!;
    const threshold = usage!.contextWindow - reserveTokens;
    const percent = Math.round((tokensBefore / usage!.contextWindow) * 100);

    if (ctx.hasUI) {
      ctx.ui.notify(
        `Context ${percent}% (${tokensBefore.toLocaleString()} tokens); compacting before the next tool turn`,
        "warning",
      );
    }

    ctx.compact({
      customInstructions: COMPACTION_INSTRUCTIONS,
      onComplete: (result) => {
        compacting = false;
        if (ctx.hasUI) {
          ctx.ui.notify(
            `Early compaction completed (${tokensBefore.toLocaleString()} → ~${result.estimatedTokensAfter.toLocaleString()} tokens)`,
            "info",
          );
        }
        pi.sendMessage(
          {
            customType: "pi-early-compaction-resume",
            content: RESUME_MESSAGE,
            display: false,
            details: { tokensBefore, threshold },
          },
          { triggerTurn: true, deliverAs: "steer" },
        );
      },
      onError: (error) => {
        compacting = false;
        if (ctx.hasUI) {
          ctx.ui.notify(`Early compaction failed: ${error.message}`, "error");
        }
      },
    });
  });
}
