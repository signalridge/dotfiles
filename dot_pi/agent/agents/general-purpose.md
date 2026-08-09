---
description: "Open-ended multi-step work that requires WRITING as well as reading — implement a change, run and iterate on tests, drive a task through to completion. This is the ONLY agent in the roster that can modify files. Use it when a task needs both investigation and execution, or when no specialized agent fits. Do NOT use it to search for code (Explore is faster and cheaper), to design a change that does not exist yet (Plan), or to judge existing code (Review — which cannot accidentally edit what it is judging)."
display_name: Agent
tools: all
model: openai-codex/gpt-5.6-luna
thinking: max
exclude_extensions: pi-statusline, pi-input-history, pi-input-prefix, tmux-state, herdr-pi-state, pi-caffeinate, pi-goal, pi-welcome
prompt_mode: append
---
