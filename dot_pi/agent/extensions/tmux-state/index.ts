import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { homedir } from "node:os";
import { join } from "node:path";

// Bridge Pi's session lifecycle into the shared tmux AI-agent status indicator
// (~/.local/bin/tmux-ai-agent-state), so a `pi` pane reports busy/idle exactly
// like the `claude` and `codex` panes. Pi has no native hooks (the hooks API
// became the extensions API in v0.31.0), so this replaces codex's
// [[hooks.SessionStart]] / [[hooks.Stop]] config blocks.
//
// Best-effort by design: status collection must never disrupt or block the
// session, so every invocation swallows its errors.
const STATE_SCRIPT = join(homedir(), ".local", "bin", "tmux-ai-agent-state");

export default function (pi: ExtensionAPI) {
  const setState = async (state: "busy" | "idle"): Promise<void> => {
    try {
      await pi.exec(STATE_SCRIPT, ["pi", state], { timeout: 2000 });
    } catch {
      // ignore: the tmux indicator is non-essential
    }
  };

  pi.on("session_start", () => setState("idle"));
  pi.on("before_agent_start", () => setState("busy"));
  pi.on("agent_end", () => setState("idle"));
  pi.on("session_shutdown", () => setState("idle"));
}
