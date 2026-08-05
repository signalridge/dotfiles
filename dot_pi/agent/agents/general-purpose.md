---
# Ejected built-in `general-purpose`, model pinned per user request (2026-08-05): runs
# openai-codex/gpt-5.6-luna at thinking `max` — same native Codex OAuth provider as the
# parent, one price tier below the parent's gpt-5.6-sol so subagent fan-out stays cheap,
# with reasoning effort still at the top. It must NOT inherit later parent /model choices.
# This agent is a "parent twin": prompt_mode append + all builtin tools + EMPTY body, so
# it inherits the parent's full system prompt at runtime. Do NOT add a body or narrow
# tools; the only intended deviations from the built-in default are `model:`/`thinking:`.
description: "General-purpose agent for researching complex questions, searching for code, and executing multi-step tasks. When you are searching for a keyword or file and are not confident that you will find the right match in the first few tries use this agent to perform the search for you."
display_name: Agent
tools: all
model: openai-codex/gpt-5.6-luna
thinking: max
prompt_mode: append
---
