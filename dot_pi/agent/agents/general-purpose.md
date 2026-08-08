---
# Ejected built-in `general-purpose`, model pinned per user request (2026-08-05): runs
# openai-codex/gpt-5.6-luna at thinking `max` — same native Codex OAuth provider as the
# parent, one price tier below the parent's gpt-5.6-sol so subagent fan-out stays cheap,
# with reasoning effort still at the top. It must NOT inherit later parent /model choices.
# This agent is a "parent twin": prompt_mode append + all builtin tools + EMPTY body, so
# it inherits the parent's full system prompt at runtime. Do NOT add a body or narrow
# tools; the only intended deviations from the built-in default are `model:`/`thinking:`
# and the `exclude_extensions:` line below.
#
# exclude_extensions does NOT narrow what this agent can do — the parent-twin guarantee
# is about prompt and tools, and none of the excluded extensions contribute a tool a
# child can use: four are pure TUI (a subagent session has no UI to draw into),
# herdr-pi-state already self-disables via PI_SUBAGENT_CHILD, pi-caffeinate duplicates a
# lock the parent already holds, and pi-goal's `/goal` autonomous loop must not run
# inside a child. Everything that carries real capability stays loaded.
# Deliberately NO max_turns here, unlike Explore/Plan: this agent does open-ended
# multi-step work and a turn ceiling would cut real tasks short.
description: "General-purpose agent for researching complex questions, searching for code, and executing multi-step tasks. When you are searching for a keyword or file and are not confident that you will find the right match in the first few tries use this agent to perform the search for you."
display_name: Agent
tools: all
model: openai-codex/gpt-5.6-luna
thinking: max
exclude_extensions: pi-statusline, pi-input-history, pi-input-prefix, tmux-state, herdr-pi-state, pi-caffeinate, pi-goal
prompt_mode: append
---
