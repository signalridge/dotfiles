---
# Ejected built-in `general-purpose`, model pinned per user request (2026-07-29): runs
# openai-codex/gpt-5.6-sol (native Codex OAuth, same swap as the parent default),
# matching the parent default, and must NOT inherit later parent
# /model choices (for example glm-5.2 for a 1M window). This agent is a "parent twin":
# prompt_mode append + all builtin tools + EMPTY body, so it inherits the parent's
# full system prompt at runtime. Do NOT add a body or narrow tools; the only intended
# deviation from the built-in default is the `model:` line below.
description: "General-purpose agent for researching complex questions, searching for code, and executing multi-step tasks. When you are searching for a keyword or file and are not confident that you will find the right match in the first few tries use this agent to perform the search for you."
display_name: Agent
tools: all
model: openai-codex/gpt-5.6-sol
prompt_mode: append
---
