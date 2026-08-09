import { existsSync, readFileSync } from "node:fs";
import { dirname, join, parse, resolve } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const CONSTITUTION_MARKERS = ["NO git worktrees. Ever.", "NEVER run `git worktree add`"];
const WORKTREE_ISOLATION = /\bisolation\b\s*:\s*(["'`])worktree\1/i;
const GIT_WORKTREE_ADD = /\bgit\b[^\n;&|]{0,300}\bworktree\s+add\b/i;

function containsConstitution(path: string): boolean {
  if (!existsSync(path)) return false;
  try {
    const content = readFileSync(path, "utf8");
    return CONSTITUTION_MARKERS.every((marker) => content.includes(marker));
  } catch {
    return false;
  }
}

export function findWorktreeForbiddenRoot(cwd: string): string | undefined {
  let current = resolve(cwd);
  const filesystemRoot = parse(current).root;

  while (true) {
    if (
      existsSync(join(current, ".chezmoidata")) &&
      (containsConstitution(join(current, "AGENTS.md")) ||
        containsConstitution(join(current, "CLAUDE.md")))
    ) {
      return current;
    }
    if (current === filesystemRoot) return undefined;
    current = dirname(current);
  }
}

export function workflowRequestsWorktree(script: unknown): boolean {
  return typeof script === "string" && WORKTREE_ISOLATION.test(script);
}

export function commandAddsWorktree(command: unknown): boolean {
  return typeof command === "string" && GIT_WORKTREE_ADD.test(command);
}

export default function piWorktreeGuard(pi: ExtensionAPI): void {
  pi.on("tool_call", (event, ctx) => {
    const root = findWorktreeForbiddenRoot(ctx.cwd);
    if (!root) return;

    const input = event.input as Record<string, unknown>;
    const toolName = event.toolName.toLowerCase();
    let attempted = false;

    if (toolName === "workflow") {
      attempted = workflowRequestsWorktree(input.script);
    } else if (toolName === "agent") {
      attempted = input.isolation === "worktree";
    } else if (toolName === "bash" || toolName === "hypa_shell") {
      attempted = commandAddsWorktree(input.command);
    }

    if (!attempted) return;
    return {
      block: true,
      reason:
        `Worktree creation is forbidden in the chezmoi source tree (${root}). ` +
        "Retry in the shared current checkout without isolation or branch switching.",
    };
  });
}
