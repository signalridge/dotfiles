import assert from "node:assert/strict";
import { readdir, readFile } from "node:fs/promises";

const piData = await readFile(new URL("../.chezmoidata/pi.yaml", import.meta.url), "utf8");
assert.match(piData, /^\s{4}defaultProvider: openai-codex$/m);
assert.match(piData, /^\s{4}defaultModel: gpt-5\.6-sol$/m);

const agentsDir = new URL("../dot_pi/agent/agents/", import.meta.url);
const agentFiles = (await readdir(agentsDir)).filter((name) => name.endsWith(".md"));
const gptRoutes = [];

for (const name of agentFiles) {
  const text = await readFile(new URL(name, agentsDir), "utf8");
  const model = text.match(/^model:\s*(\S+)$/m)?.[1];
  if (model?.includes("gpt-")) gptRoutes.push({ name, model });
}

assert.deepEqual(gptRoutes, [
  { name: "Plan.md", model: "openai-codex/gpt-5.6-sol" },
  { name: "general-purpose.md", model: "openai-codex/gpt-5.6-sol" },
]);
assert.ok(gptRoutes.every(({ model }) => model.startsWith("openai-codex/")));

// krill stays defined as a manual /model fallback for the same model.
assert.match(piData, /^\s{4}krill:(\s|#)/m);

console.log("test_pi_gpt_routes: OK");
