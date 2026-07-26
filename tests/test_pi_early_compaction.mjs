import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

import earlyCompaction, {
  DEFAULT_RESERVE_TOKENS,
  resolveReserveTokens,
  shouldCompactBeforeNextToolTurn,
} from "../dot_pi/agent/extensions/pi-early-compaction/index.ts";

assert.equal(DEFAULT_RESERVE_TOKENS, 96_000);
assert.equal(resolveReserveTokens(undefined), 96_000);
assert.equal(resolveReserveTokens("120000"), 120_000);
assert.equal(resolveReserveTokens("invalid"), 96_000);

const usage = (tokens) => ({ tokens, contextWindow: 372_000, percent: (tokens / 372_000) * 100 });
assert.equal(shouldCompactBeforeNextToolTurn(usage(276_000), "toolUse"), false);
assert.equal(shouldCompactBeforeNextToolTurn(usage(276_001), "toolUse"), true);
assert.equal(shouldCompactBeforeNextToolTurn(usage(371_000), "stop"), false);
assert.equal(
  shouldCompactBeforeNextToolTurn({ tokens: null, contextWindow: 372_000 }, "toolUse"),
  false,
);

const handlers = new Map();
const sentMessages = [];
const notifications = [];
const pi = {
  on(name, handler) {
    handlers.set(name, handler);
  },
  sendMessage(message, options) {
    sentMessages.push({ message, options });
  },
};
earlyCompaction(pi);

assert.ok(handlers.has("session_start"));
assert.ok(handlers.has("turn_end"));
handlers.get("session_start")({}, {});

let currentUsage = usage(280_000);
const compactCalls = [];
const ctx = {
  getContextUsage: () => currentUsage,
  compact: (options) => compactCalls.push(options),
  hasUI: true,
  ui: { notify: (message, level) => notifications.push({ message, level }) },
};

handlers.get("turn_end")({ message: { stopReason: "stop" } }, ctx);
assert.equal(compactCalls.length, 0, "completed answers must use Pi's normal agent_end path");

handlers.get("turn_end")({ message: { stopReason: "toolUse" } }, ctx);
assert.equal(compactCalls.length, 1);
assert.match(compactCalls[0].customInstructions, /pending tool-loop actions/);

handlers.get("turn_end")({ message: { stopReason: "toolUse" } }, ctx);
assert.equal(compactCalls.length, 1, "must not start duplicate compactions");

compactCalls[0].onComplete({ estimatedTokensAfter: 48_000 });
assert.equal(sentMessages.length, 1);
assert.equal(sentMessages[0].message.display, false);
assert.match(sentMessages[0].message.content, /Continue the current user task/);
assert.deepEqual(sentMessages[0].options, { triggerTurn: true, deliverAs: "steer" });
assert.ok(notifications.some(({ message }) => message.includes("Early compaction completed")));

currentUsage = usage(280_000);
handlers.get("turn_end")({ message: { stopReason: "toolUse" } }, ctx);
assert.equal(compactCalls.length, 2, "completion must re-arm the guard");
compactCalls[1].onError(new Error("test failure"));
assert.ok(notifications.some(({ message }) => message.includes("test failure")));

const piData = await readFile(new URL("../.chezmoidata/pi.yaml", import.meta.url), "utf8");
assert.match(piData, /^\s{6}reserveTokens: 96000$/m);

console.log("test_pi_early_compaction: OK");
