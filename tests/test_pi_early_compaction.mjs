import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

import earlyCompaction, {
  DEFAULT_RESERVE_TOKENS,
  mergeFileTracking,
  resolveReserveTokens,
  shouldCompactBeforeNextToolTurn,
  SUMMARY_REASONING_LEVEL,
  SUMMARY_RESERVE_TOKENS,
} from "../dot_pi/agent/extensions/pi-early-compaction/core.ts";

assert.equal(DEFAULT_RESERVE_TOKENS, 96_000);
assert.equal(SUMMARY_RESERVE_TOKENS, 10_240);
assert.equal(SUMMARY_REASONING_LEVEL, "low");
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

assert.deepEqual(
  mergeFileTracking(
    "<read-files>\nold-read\nlater-modified\n</read-files>\n<modified-files>\nold-modified\n</modified-files>",
    {
      read: new Set(["new-read", "old-modified"]),
      written: new Set(["new-written"]),
      edited: new Set(["later-modified"]),
    },
  ),
  {
    readFiles: ["new-read", "old-read"],
    modifiedFiles: ["later-modified", "new-written", "old-modified"],
  },
);

const handlers = new Map();
const sentMessages = [];
const notifications = [];
const summaryCalls = [];
let clock = 1_000;
const pi = {
  on(name, handler) {
    handlers.set(name, handler);
  },
  sendMessage(message, options) {
    sentMessages.push({ message, options });
  },
};
earlyCompaction(pi, {
  now: () => clock,
  generateSummary: async (...args) => {
    summaryCalls.push(args);
    return "## Goal\nContinue safely.\n\n<read-files>\nstale-output\n</read-files>";
  },
});

assert.ok(handlers.has("session_start"));
assert.ok(handlers.has("session_shutdown"));
assert.ok(handlers.has("session_before_compact"));
assert.ok(handlers.has("turn_end"));
handlers.get("session_start")({}, {});

let currentUsage = usage(280_000);
const compactCalls = [];
const ctx = {
  getContextUsage: () => currentUsage,
  compact: (options) => compactCalls.push(options),
  hasUI: true,
  model: {
    id: "gpt-5.6-sol",
    provider: "krill",
    reasoning: true,
    maxTokens: 128_000,
  },
  modelRegistry: {
    getApiKeyAndHeaders: async () => ({
      ok: true,
      apiKey: "test-key",
      headers: { "x-test": "yes" },
      env: { TEST_ENV: "yes" },
    }),
  },
  ui: { notify: (message, level) => notifications.push({ message, level }) },
};

const preparation = {
  messagesToSummarize: [{ role: "user", content: "old context", timestamp: 1 }],
  turnPrefixMessages: [{ role: "assistant", content: [], stopReason: "stop", timestamp: 2 }],
  tokensBefore: 280_000,
  firstKeptEntryId: "kept-entry",
  previousSummary:
    "## Goal\nOld goal.\n\n<read-files>\nold-read\nlater-modified\n</read-files>\n\n<modified-files>\nold-modified\n</modified-files>",
  fileOps: {
    read: new Set(["new-read"]),
    written: new Set(["new-written"]),
    edited: new Set(["later-modified"]),
  },
  settings: { enabled: true, reserveTokens: 96_000, keepRecentTokens: 16_000 },
};
const compactEvent = {
  reason: "manual",
  preparation,
  signal: new AbortController().signal,
};

assert.equal(
  await handlers.get("session_before_compact")(compactEvent, ctx),
  undefined,
  "manual compaction must remain untouched when early compaction is not active",
);

handlers.get("turn_end")({ message: { stopReason: "stop" } }, ctx);
assert.equal(compactCalls.length, 0, "completed answers must use Pi's normal agent_end path");

handlers.get("turn_end")({ message: { stopReason: "toolUse" } }, ctx);
assert.equal(compactCalls.length, 1);
assert.match(compactCalls[0].customInstructions, /pending tool-loop actions/);
assert.ok(notifications.some(({ message }) => message.includes("starting early compaction")));

handlers.get("turn_end")({ message: { stopReason: "toolUse" } }, ctx);
assert.equal(compactCalls.length, 1, "must not start duplicate compactions");

const customResult = await handlers.get("session_before_compact")(compactEvent, ctx);
assert.equal(summaryCalls.length, 1);
assert.equal(summaryCalls[0][0].length, 2, "split-turn history must use one summary request");
assert.equal(summaryCalls[0][2], 10_240);
assert.equal(summaryCalls[0][8], "low");
assert.equal(summaryCalls[0][9], undefined, "use completeSimple instead of the main streaming transport");
assert.deepEqual(customResult.compaction.details, {
  readFiles: ["new-read", "old-read"],
  modifiedFiles: ["later-modified", "new-written", "old-modified"],
});
assert.equal((customResult.compaction.summary.match(/<read-files>/g) ?? []).length, 1);
assert.doesNotMatch(customResult.compaction.summary, /stale-output/);
assert.match(customResult.compaction.summary, /new-written/);

clock = 4_500;
compactCalls[0].onComplete({ estimatedTokensAfter: 48_000 });
assert.equal(sentMessages.length, 1);
assert.equal(sentMessages[0].message.display, false);
assert.match(sentMessages[0].message.content, /Continue the current user task/);
assert.deepEqual(sentMessages[0].options, { triggerTurn: true, deliverAs: "steer" });
assert.ok(notifications.some(({ message }) => message.includes("completed in 3.5s")));

currentUsage = usage(280_000);
handlers.get("turn_end")({ message: { stopReason: "toolUse" } }, ctx);
assert.equal(compactCalls.length, 2, "completion must re-arm the guard");
compactCalls[1].onError(new Error("test failure"));
assert.ok(notifications.some(({ message }) => message.includes("test failure")));

handlers.get("turn_end")({ message: { stopReason: "toolUse" } }, ctx);
assert.equal(compactCalls.length, 3);
handlers.get("session_shutdown")({}, ctx);
compactCalls[2].onComplete({ estimatedTokensAfter: 40_000 });
assert.equal(sentMessages.length, 1, "stale callbacks must not resume a replaced session");

const piData = await readFile(new URL("../.chezmoidata/pi.yaml", import.meta.url), "utf8");
assert.match(piData, /^\s{6}reserveTokens: 96000$/m);

console.log("test_pi_early_compaction: OK");
