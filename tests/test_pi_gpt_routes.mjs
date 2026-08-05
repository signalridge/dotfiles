import assert from "node:assert/strict";
import { readdir, readFile } from "node:fs/promises";

const piData = await readFile(new URL("../.chezmoidata/pi.yaml", import.meta.url), "utf8");
assert.match(piData, /^\s{4}defaultProvider: openai-codex$/m);
assert.match(piData, /^\s{4}defaultModel: gpt-5\.6-sol$/m);

// Every subagent runs on the parent's provider (openai-codex), one price tier down
// at gpt-5.6-luna, with reasoning effort pinned to `max` — user request 2026-08-05.
// No subagent may fall back to a gateway or a non-OpenAI provider.
const agentsDir = new URL("../dot_pi/agent/agents/", import.meta.url);
const agentFiles = (await readdir(agentsDir)).filter((name) => name.endsWith(".md"));
const routes = [];

for (const name of agentFiles) {
  const text = await readFile(new URL(name, agentsDir), "utf8");
  routes.push({
    name,
    model: text.match(/^model:\s*(\S+)$/m)?.[1],
    thinking: text.match(/^thinking:\s*(\S+)$/m)?.[1],
  });
}

assert.deepEqual(routes.map(({ name }) => name).sort(), [
  "Explore.md",
  "Plan.md",
  "general-purpose.md",
]);
for (const { name, model, thinking } of routes) {
  assert.equal(model, "openai-codex/gpt-5.6-luna", `${name} must run on openai-codex/gpt-5.6-luna`);
  assert.equal(thinking, "max", `${name} must pin thinking: max`);
}

// krill stays defined as a manual /model fallback for the same model.
assert.match(piData, /^\s{4}krill:(\s|#)/m);

console.log("test_pi_gpt_routes: OK");
