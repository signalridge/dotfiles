#!/usr/bin/env bash
# Claude Code status line — Dracula-themed, mirroring the Starship prompt style.
# Receives JSON on stdin.

input=$(cat)

# ── Extract fields ────────────────────────────────────────────────────────────
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
branch=$(echo "$input" | jq -r '
  if .workspace.repo then
    .workspace.repo.owner + "/" + .workspace.repo.name
  else "" end')
worktree=$(echo "$input" | jq -r '.workspace.git_worktree // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
effort=$(echo "$input" | jq -r '.effort.level // ""')

# ── Dracula ANSI colours (256-colour approximations) ─────────────────────────
# cyan   #8be9fd  → \e[38;5;117m
# pink   #ff79c6  → \e[38;5;212m
# purple #bd93f9  → \e[38;5;141m
# green  #50fa7b  → \e[38;5;84m
# orange #ffb86c  → \e[38;5;215m
# yellow #f1fa8c  → \e[38;5;228m
# reset
RST='\e[0m'
CYAN='\e[38;5;117m'
PINK='\e[38;5;212m'
PURPLE='\e[38;5;141m'
GREEN='\e[38;5;84m'
ORANGE='\e[38;5;215m'
YELLOW='\e[38;5;228m'
BOLD='\e[1m'

# ── Directory: shorten $HOME to ~ ─────────────────────────────────────────────
home="${HOME:-/root}"
short_cwd="${cwd/#$home/\~}"

# ── Git branch via git (more accurate than repo field alone) ─────────────────
git_branch=""
if git_branch_raw=$(git -C "$cwd" branch --show-current 2>/dev/null); then
    git_branch="$git_branch_raw"
fi

# ── Build output ──────────────────────────────────────────────────────────────
out=""

#  directory (bold cyan)
out+="${BOLD}${CYAN}${short_cwd}${RST}"

#  git branch (bold pink with  symbol)
if [[ -n "$git_branch" ]]; then
    out+="  ${BOLD}${PINK} ${git_branch}${RST}"
fi

#  worktree indicator (bold purple), mirrors starship right_format custom.worktree
if [[ -n "$worktree" ]]; then
    out+="  ${BOLD}${PURPLE}wt:${worktree}${RST}"
fi

#  repo (owner/name) when present and no local branch info is enough
if [[ -z "$git_branch" && -n "$branch" ]]; then
    out+="  ${BOLD}${PINK} ${branch}${RST}"
fi

#  model (green)
if [[ -n "$model" ]]; then
    out+="  ${BOLD}${GREEN}${model}${RST}"
fi

#  effort level when set and not default
if [[ -n "$effort" && "$effort" != "medium" ]]; then
    out+="  ${BOLD}${ORANGE}effort:${effort}${RST}"
fi

#  context usage (yellow) — only after first API response
if [[ -n "$used_pct" ]]; then
    printf_pct=$(printf '%.0f' "$used_pct")
    out+="  ${BOLD}${YELLOW}ctx:${printf_pct}%${RST}"
fi

printf "%b\n" "$out"
