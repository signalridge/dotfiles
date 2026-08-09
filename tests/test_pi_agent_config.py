#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
AGENT_DIR = ROOT / "dot_pi/agent/agents"


def frontmatter(path: Path) -> dict[str, str]:
    text = path.read_text()
    match = re.match(r"^---\n(.*?)\n---(?:\n|$)", text, re.S)
    assert match, f"missing frontmatter: {path}"
    values: dict[str, str] = {}
    for line in match.group(1).splitlines():
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        values[key.strip()] = value.strip().strip('"\'')
    return values


expected_agents = {
    "Explore",
    "Implement",
    "Plan",
    "Plan-deep",
    "Research",
    "Research-deep",
    "Review",
    "Review-deep",
    "Verify",
    "general-purpose",
}
agent_paths = {path.stem: path for path in AGENT_DIR.glob("*.md")}
assert set(agent_paths) == expected_agents, sorted(agent_paths)
agents = {name: frontmatter(path) for name, path in agent_paths.items()}

for name in ("Implement", "general-purpose"):
    config = agents[name]
    assert config["tools"] == "all", (name, config["tools"])
    assert config["model"] == "openai-codex/gpt-5.6-luna", (name, config["model"])
    assert config["thinking"] == "max", (name, config["thinking"])
    assert config["prompt_mode"] == "append", (name, config["prompt_mode"])
    assert "pi-dynamic-workflows" in config["exclude_extensions"], name

read_only = expected_agents - {"Implement", "general-purpose"}
for name in read_only:
    config = agents[name]
    tools = {tool.strip() for tool in config["tools"].split(",")}
    assert not ({"edit", "write"} & tools), (name, tools)
    denied = {tool.strip() for tool in config["disallowed_tools"].split(",")}
    assert {"readSeek_edit", "readSeek_write", "readSeek_rename", "hypa_shell"} <= denied, name
    assert "pi-dynamic-workflows" in config["exclude_extensions"], name
    assert config["prompt_mode"] == "replace", (name, config["prompt_mode"])

subagents = json.loads((ROOT / "dot_pi/agent/subagents.json").read_text())
assert subagents["maxConcurrent"] == 16
assert subagents["defaultMaxTurns"] == 0
assert subagents["graceTurns"] == 8
assert subagents["disableDefaultAgents"] is True
assert subagents["defaultJoinMode"] == "smart"

workflow = json.loads((ROOT / "dot_pi/workflows/settings.json").read_text())
assert workflow["keywordTriggerEnabled"] is False
assert workflow["defaultTokenBudget"] == 500_000
assert workflow["defaultConcurrency"] == 16
assert workflow["defaultAgentRetries"] == 1
assert workflow["persistAgentSessions"] is False
assert {"Agent", "get_subagent_result", "steer_subagent"} <= set(workflow["excludeSubagentTools"])

tiers = json.loads((ROOT / "dot_pi/workflows/model-tiers.json").read_text())["tiers"]
assert tiers == {
    "small": "openai-codex/gpt-5.6-luna:high",
    "medium": "openai-codex/gpt-5.6-luna:max",
    "big": "openai-codex/gpt-5.6-sol:xhigh",
}

pi_data = (ROOT / ".chezmoidata/pi.yaml").read_text()
assert "- npm:@quintinshaw/pi-dynamic-workflows" in pi_data
assert pi_data.count("max: high") >= 2

append_system = (ROOT / "dot_pi/agent/APPEND_SYSTEM.md").read_text()
assert "Route an already-bounded code change to Implement" in append_system
assert "omit `max_turns` by default" in append_system
assert "only when the user explicitly requests a hard turn limit" in append_system
assert "The chezmoi source tree forbids all worktrees" in append_system

worktree_guard = (ROOT / "dot_pi/agent/extensions/pi-worktree-guard.ts").read_text()
assert 'toolName === "workflow"' in worktree_guard
assert 'toolName === "agent"' in worktree_guard
assert "GIT_WORKTREE_ADD" in worktree_guard

print("test_pi_agent_config: OK")
