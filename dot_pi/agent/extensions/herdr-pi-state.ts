// @ts-nocheck
// herdr-pi-state — resume-safe pi→herdr agent-status reporter.
//
// Replaces herdr's bundled `pi` integration (`herdr-agent-state.ts`), which stops
// reporting after an in-process session switch (/resume, /new, /reload, /fork).
// Root cause of the bundled one: it gates ALL reporting behind
// `session_start → (hasUI===true) → rootSession=true`, and every agent_start/
// agent_end handler early-returns unless rootSession is set. When pi rebinds the
// extension runtime for a session switch, that gate never re-arms (session_start
// is not reliably re-delivered with hasUI to the rebound instance), so the pane
// is stuck reporting nothing and herdr — which hands this source
// "full_lifecycle_hook_authority" and skips screen detection — shows a stale idle.
//
// This version is hardened:
//   * Enables on load (HERDR env present, not a subagent child) — no session_start gate.
//   * Reports ACTIVE unless a session_start explicitly says headless (hasUI===false).
//   * Drives "working" from per-turn events (turn_start / before_provider_request /
//     agent_start / tool_execution_start / message_start) that fire on every turn,
//     not just the once-per-message agent_start — so it recovers right after a resume.
//   * Idle on turn_end / agent_end (debounced), reconciled by a 1s isIdle() poll.
//   * Only releases herdr authority on a real quit (reason==="quit"), like the original.
//
// herdr grants authority to the source id, not the file: `remote/pi.toml` declares
// `aliases = ["herdr:pi"]`, so reporting as source "herdr:pi" keeps full authority
// even though the bundled hook file is uninstalled. Do NOT run
// `herdr integration install pi` alongside this — two reporters on source "herdr:pi"
// fight. The chezmoi sync script (run_after_14_sync-herdr-integrations) uninstalls it.
//
// Managed by chezmoi: dot_pi/agent/extensions/herdr-pi-state.ts. Tunables:
//   HERDR_PI_IDLE_DEBOUNCE_MS (default 250), HERDR_PI_POLL_MS (default 1000),
//   HERDR_PI_DEBUG=1 → append a trace to ~/.pi/agent/herdr-pi-state.log.

import { createConnection } from "node:net";
import { appendFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const HERDR_ENV = process.env.HERDR_ENV;
const socketPath = process.env.HERDR_SOCKET_PATH;
const paneId = process.env.HERDR_PANE_ID;
const isSubagentChild = process.env.PI_SUBAGENT_CHILD === "1";
const source = "herdr:pi";

const DEBUG = process.env.HERDR_PI_DEBUG === "1";
const logPath = join(homedir(), ".pi", "agent", "herdr-pi-state.log");
function log(...parts: unknown[]): void {
  if (!DEBUG) return;
  try {
    appendFileSync(
      logPath,
      `${new Date().toISOString()} [pid ${process.pid}] ${parts.join(" ")}\n`,
    );
  } catch {
    /* ignore */
  }
}
function safeIdle(ctx: any): string {
  try {
    return String(ctx?.isIdle?.());
  } catch {
    return "err";
  }
}
log(
  "MODULE-EVAL pane=" +
    paneId +
    " enabled=" +
    enabled() +
    " child=" +
    isSubagentChild +
    " HERDR_ENV=" +
    HERDR_ENV,
);

function parseDurationEnv(name: string, fallback: number): number {
  const raw = process.env[name];
  if (!raw) return fallback;
  const parsed = Number.parseInt(raw, 10);
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : fallback;
}
const idleDebounceMs = parseDurationEnv("HERDR_PI_IDLE_DEBOUNCE_MS", 250);
const pollMs = parseDurationEnv("HERDR_PI_POLL_MS", 1000);

function enabled(): boolean {
  return HERDR_ENV === "1" && !!socketPath && !!paneId && !isSubagentChild;
}

// ---- herdr socket plumbing (same wire protocol as the bundled integration) ----

// Sequence numbers are herdr's staleness gate: it drops any report whose seq is
// <= the last it saw for the pane. herdr resets a pane on session switch
// (/new, /resume) using a CURRENT wall-clock seq, so a fixed load-time base +1
// would be out-ranked and silently dropped afterward. Track current wall-clock
// each call so our reports always out-rank herdr's session-reset (and any other
// process sharing this pane, which all seed from the same clock).
let reportSeq = Date.now() * 1000;
function nextReportSeq(): number {
  reportSeq = Math.max(reportSeq + 1, Date.now() * 1000);
  return reportSeq;
}

function sendRequestAttempt(
  request: unknown,
  timeoutMs: number,
): Promise<boolean> {
  if (!enabled()) return Promise.resolve(true);
  return new Promise((resolve) => {
    let done = false;
    let timer: ReturnType<typeof setTimeout> | undefined;
    const finish = (delivered: boolean) => {
      if (done) return;
      done = true;
      if (timer) clearTimeout(timer);
      socket.destroy();
      resolve(delivered);
    };
    const socket = createConnection(socketPath!);
    socket.on("error", () => finish(false));
    socket.on("connect", () => socket.write(`${JSON.stringify(request)}\n`));
    socket.on("data", () => finish(true));
    socket.on("end", () => finish(false));
    timer = setTimeout(() => finish(false), timeoutMs);
    timer.unref?.();
  });
}
async function sendRequest(request: unknown): Promise<void> {
  const m = (request as any)?.method;
  const st = (request as any)?.params?.state ?? "";
  if (await sendRequestAttempt(request, 500)) {
    log("SEND ok", m, st);
    return;
  }
  const ok = await sendRequestAttempt(request, 1500);
  log("SEND", ok ? "ok-retry" : "FAILED", m, st);
}

let currentAgentSessionPath: string | undefined;
let currentAgentSessionId: string | undefined;
function updateSessionRef(ctx: any): void {
  try {
    const file = ctx?.sessionManager?.getSessionFile?.();
    currentAgentSessionPath =
      typeof file === "string" && file.startsWith("/")
        ? file
        : currentAgentSessionPath;
  } catch {
    /* keep previous */
  }
  try {
    const id = ctx?.sessionManager?.getSessionId?.();
    currentAgentSessionId =
      typeof id === "string" && id.length > 0 ? id : currentAgentSessionId;
  } catch {
    /* keep previous */
  }
}
function sessionRef(): Record<string, unknown> {
  if (currentAgentSessionPath)
    return { agent_session_path: currentAgentSessionPath };
  if (currentAgentSessionId) return { agent_session_id: currentAgentSessionId };
  return {};
}

function reportSession(): Promise<void> {
  const ref = sessionRef();
  if (!ref.agent_session_path && !ref.agent_session_id)
    return Promise.resolve();
  return sendRequest({
    id: `${source}:session:${Date.now()}:${Math.random().toString(36).slice(2)}`,
    method: "pane.report_agent_session",
    params: {
      pane_id: paneId,
      source,
      agent: "pi",
      seq: nextReportSeq(),
      ...ref,
    },
  });
}
function reportState(
  state: "working" | "blocked" | "idle",
  message?: string,
): Promise<void> {
  return sendRequest({
    id: `${source}:${Date.now()}:${Math.random().toString(36).slice(2)}`,
    method: "pane.report_agent",
    params: {
      pane_id: paneId,
      source,
      agent: "pi",
      state,
      message,
      seq: nextReportSeq(),
      // NOTE: deliberately NO session ref here. herdr applies report_agent to the
      // pane by pane_id regardless of session. Tagging state with a session path
      // breaks after /new: herdr still associates the pane with the pre-/new
      // session (our post-switch report_agent_session had an empty path because
      // the new session file didn't exist yet), so a state report tagged with the
      // NEW session is treated as a different session and dropped. Omitting it
      // makes state apply to the pane unconditionally.
    },
  });
}
function releaseAgent(): Promise<void> {
  return sendRequest({
    id: `${source}:release:${Date.now()}:${Math.random().toString(36).slice(2)}`,
    method: "pane.release_agent",
    params: { pane_id: paneId, source, agent: "pi", seq: nextReportSeq() },
  });
}

// ---- serialized send queue so state reports never interleave out of order ----

let queued:
  | { state: "working" | "blocked" | "idle"; message?: string }
  | undefined;
let sending = false;
async function drain(): Promise<void> {
  if (sending) return;
  sending = true;
  try {
    while (queued) {
      const next = queued;
      queued = undefined;
      await reportState(next.state, next.message);
    }
  } finally {
    sending = false;
    if (queued) void drain();
  }
}

export default function (pi: any) {
  if (!enabled()) {
    log("EXPORT-CALL skipped (enabled=false)");
    return;
  }
  log("EXPORT-CALL registering handlers on pi");

  let active = true; // report unless a session_start proves this is headless
  let working = false;
  let blockedCount = 0;
  let blockedMessage: string | undefined;
  let lastState: "working" | "blocked" | "idle" | undefined;
  let lastCtx: any;
  let idleTimer: ReturnType<typeof setTimeout> | undefined;

  function desired(): "working" | "blocked" | "idle" {
    if (blockedCount > 0) return "blocked";
    return working ? "working" : "idle";
  }
  function publish(force = false): void {
    if (!active) return;
    const state = desired();
    if (!force && state === lastState) return;
    lastState = state;
    queued = {
      state,
      message: state === "blocked" ? blockedMessage : undefined,
    };
    log("publish", state);
    if (!sending) void drain();
  }
  function markWorking(): void {
    if (idleTimer) {
      clearTimeout(idleTimer);
      idleTimer = undefined;
    }
    working = true;
    publish();
  }
  function scheduleIdle(): void {
    if (idleTimer) clearTimeout(idleTimer);
    idleTimer = setTimeout(() => {
      idleTimer = undefined;
      working = false;
      publish();
    }, idleDebounceMs);
    idleTimer.unref?.();
  }
  let lastReportedSessionPath: string | undefined;
  function sync(ctx: any): void {
    if (ctx) lastCtx = ctx;
    updateSessionRef(lastCtx);
    // Re-bind herdr's pane to the current session whenever it changes. After a
    // /new or /resume, herdr keeps the pane bound to the pre-switch session
    // (often idle) and periodically overrides our reported state from it —
    // causing working/idle flicker — until we re-send report_agent_session with
    // the new path. That path only exists once the new session has been written
    // (i.e. on the first turn after the switch), so re-report on change here.
    if (
      currentAgentSessionPath &&
      currentAgentSessionPath !== lastReportedSessionPath
    ) {
      lastReportedSessionPath = currentAgentSessionPath;
      void reportSession();
    }
  }

  pi.on("session_start", (event: any, ctx: any) => {
    log(
      "EVT session_start reason=" +
        event?.reason +
        " hasUI=" +
        ctx?.hasUI +
        " isIdle=" +
        safeIdle(ctx),
    );
    sync(ctx);
    if (ctx?.hasUI === false) {
      active = false;
      log("session_start", event?.reason, "hasUI=false -> inactive");
      return;
    }
    active = true;
    void reportSession();
    const idle = ctx?.isIdle?.();
    working = idle === false;
    log("session_start", event?.reason, "idle=", String(idle));
    publish(true);
    // herdr's session-switch reset (/new, /resume, /reload, /fork) is async and
    // drops source reports for a few seconds afterward. Re-assert the current
    // state a few times so herdr converges once its reset settles.
    if (event?.reason && event.reason !== "startup") {
      for (const ms of [1200, 2800, 4800, 7000]) {
        const t = setTimeout(() => {
          if (active) publish(true);
        }, ms);
        t.unref?.();
      }
    }
  });

  // Per-turn "working" signals — these fire on every turn, so a resumed session
  // starts reporting again on its very next activity even if agent_start was missed.
  for (const ev of [
    "turn_start",
    "before_provider_request",
    "agent_start",
    "tool_execution_start",
    "message_start",
  ]) {
    pi.on(ev, (_event: any, ctx: any) => {
      log("EVT", ev, "active=" + active, "isIdle=" + safeIdle(ctx));
      if (!active) return;
      sync(ctx);
      markWorking();
    });
  }
  // Idle ONLY on agent_end — the outer boundary of a whole user-message run.
  // NOT turn_end: that fires between LLM turns and around tool calls mid-run, so
  // treating it as idle blinks the status to idle between turns ("gaps"). Staying
  // working for the entire agent_start..agent_end span keeps multi-turn/tool tasks
  // continuous.
  for (const ev of ["agent_end"]) {
    pi.on(ev, (_event: any, ctx: any) => {
      log("EVT", ev, "active=" + active, "isIdle=" + safeIdle(ctx));
      if (!active) return;
      sync(ctx);
      scheduleIdle();
    });
  }

  // Blocked (e.g. permission/interview prompts) via the shared herdr event bus.
  pi.events?.on?.("herdr:blocked", (data: any) => {
    if (!active) return;
    if (!data?.active) {
      blockedCount = Math.max(0, blockedCount - 1);
      if (blockedCount === 0) blockedMessage = undefined;
    } else {
      blockedCount += 1;
      blockedMessage = data.label;
    }
    publish();
  });

  pi.on("session_shutdown", async (event: any) => {
    if (event?.reason === "quit") {
      if (idleTimer) clearTimeout(idleTimer);
      log("session_shutdown quit -> release");
      await releaseAgent();
    } else {
      log("session_shutdown", event?.reason, "-> keep authority");
    }
  });

  // Reconciliation poll: trust pi's own isIdle() to catch any missed transition
  // (the safety net that makes a resume/new impossible to leave permanently wrong).
  let pollTicks = 0;
  const poll = setInterval(() => {
    pollTicks += 1;
    if (pollTicks % 5 === 0)
      log(
        "poll-tick active=" +
          active +
          " working=" +
          working +
          " isIdle=" +
          safeIdle(lastCtx),
      );
    if (!active) return;
    // Heartbeat: re-assert the event-driven state every ~2s so herdr converges
    // after its async /new/resume reset (which drops reports for a few seconds).
    // No ctx.isIdle() reconciliation: it is unreliable mid-turn (returns true
    // intermittently during streaming) and caused working/idle flicker. Working
    // and idle are driven reliably by turn events instead.
    if (pollTicks % 2 === 0) publish(true);
  }, pollMs);
  poll.unref?.();

  log("loaded pane=" + paneId);
}
