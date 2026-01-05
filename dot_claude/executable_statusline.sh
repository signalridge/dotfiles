#!/bin/bash
# Claude Code custom statusline
# Displays: model icon, git repo/branch, folder path, hostname, context %, cost

set -euo pipefail

# ==============================================================================
# Constants
# ==============================================================================

# Colors (ANSI escape codes)
readonly CYAN='\033[36m'
readonly GREEN='\033[32m'
readonly YELLOW='\033[33m'
readonly MAGENTA='\033[35m'
readonly RESET='\033[0m'

# Icons (Nerd Font - octal escape for bash compatibility)
ICON_GIT=$(printf "\357\207\223")        #
ICON_FOLDER=$(printf "\357\201\273")     #
ICON_CHART=$(printf "\357\202\200")      #
ICON_COST=$(printf "\357\205\225")       #
ICON_GOOGLE=$(printf "\357\206\240")     #
ICON_APPLE=$(printf "\357\205\271")      #
ICON_NIXOS=$(printf "\357\214\223")      #
ICON_DEBIAN=$(printf "\357\214\206")     #
ICON_LINUX=$(printf "\357\205\274")      #
ICON_OPUS=$(printf "\363\260\230\250")   # 󰘨
ICON_SONNET=$(printf "\363\260\216\210") # 󰎈
ICON_HAIKU=$(printf "\363\260\257\210")  # 󰯈
readonly ICON_GIT ICON_FOLDER ICON_CHART ICON_COST ICON_GOOGLE \
         ICON_APPLE ICON_NIXOS ICON_DEBIAN ICON_LINUX \
         ICON_OPUS ICON_SONNET ICON_HAIKU

# ==============================================================================
# Parse input JSON
# ==============================================================================

raw=$(cat)

model_id=$(jq -r '.model.id // ""' <<< "$raw")
cost=$(jq -r '.cost.total_cost_usd // 0' <<< "$raw")
project_dir=$(jq -r '.workspace.project_dir // ""' <<< "$raw")
current_dir=$(jq -r '.workspace.current_dir // ""' <<< "$raw")
ctx_size=$(jq -r '.context_window.context_window_size // 0' <<< "$raw")
ctx_input=$(jq -r '.context_window.current_usage.input_tokens // 0' <<< "$raw")
ctx_cache_create=$(jq -r '.context_window.current_usage.cache_creation_input_tokens // 0' <<< "$raw")
ctx_cache_read=$(jq -r '.context_window.current_usage.cache_read_input_tokens // 0' <<< "$raw")

# ==============================================================================
# Build statusline components
# ==============================================================================

# Model icon and color
model_icon=""
model_color=""
case "$model_id" in
  *opus*)   model_icon="$ICON_OPUS"; model_color="$MAGENTA" ;;
  *sonnet*) model_icon="$ICON_SONNET"; model_color="$CYAN" ;;
  *haiku*)  model_icon="$ICON_HAIKU"; model_color="$GREEN" ;;
esac

# Provider (Vertex AI)
provider_info=""
[[ -n "${CLAUDE_CODE_USE_VERTEX:-}" ]] && provider_info=" ${ICON_GOOGLE}"

# Combined model info: icon + model_id + provider
model_info=""
if [[ -n "$model_icon" ]]; then
  model_info="${model_color}${model_icon} ${model_id}${provider_info}${RESET} "
elif [[ -n "$model_id" ]]; then
  model_info="${model_id}${provider_info} "
fi

# Git info
repo_name=$(basename "$project_dir")
branch=""
git_root="$project_dir"
is_git_repo=false

if git -C "$project_dir" rev-parse --show-toplevel &>/dev/null; then
  is_git_repo=true
  git_root=$(git -C "$project_dir" rev-parse --show-toplevel 2>/dev/null)
  repo_name=$(basename "$git_root")
  branch_name=$(git -C "$project_dir" branch --show-current 2>/dev/null)
  [[ -n "$branch_name" ]] && branch="@$branch_name"
fi

# Hostname
host=$(hostname -s)
[[ "$host" == *[Mm]acbook* ]] && host="macbook"

# OS icon
os_icon=""
if [[ "$OSTYPE" == darwin* ]]; then
  os_icon="$ICON_APPLE"
elif [[ "$OSTYPE" == linux* ]]; then
  if [[ -f /etc/os-release ]]; then
    os_release=$(tr '[:upper:]' '[:lower:]' < /etc/os-release)
    case "$os_release" in
      *nixos*)  os_icon="$ICON_NIXOS" ;;
      *debian*) os_icon="$ICON_DEBIAN" ;;
      *)        os_icon="$ICON_LINUX" ;;
    esac
  else
    os_icon="$ICON_LINUX"
  fi
fi

# Folder info (relative paths when cd'd)
folder_info=""
folder_parts=()

if [[ "$project_dir" != "$git_root" && -n "$git_root" ]]; then
  start_folder="${project_dir#"$git_root"/}"
  [[ -n "$start_folder" && "$start_folder" != "$project_dir" ]] && folder_parts+=("$start_folder")
fi

if [[ "$current_dir" != "$project_dir" ]]; then
  current_folder="${current_dir#"$project_dir"/}"
  [[ -n "$current_folder" && "$current_folder" != "$current_dir" ]] && folder_parts+=("$current_folder")
fi

if [[ ${#folder_parts[@]} -gt 0 ]]; then
  folder_str=$(IFS=' → '; echo "${folder_parts[*]}")
  folder_info=" ${YELLOW}${ICON_FOLDER} ${folder_str}${RESET}"
fi

# Project icon
project_icon="$ICON_FOLDER"
$is_git_repo && project_icon="$ICON_GIT"

# Context usage percentage
context_info=""
if [[ "$ctx_size" -gt 0 ]]; then
  tokens=$((ctx_input + ctx_cache_create + ctx_cache_read))
  if [[ "$tokens" -gt 0 ]]; then
    pct=$((tokens * 100 / ctx_size))
    context_info=" ${MAGENTA}${ICON_CHART} ${pct}%${RESET}"
  fi
fi

# Cost
cost_info=""
if (( $(echo "$cost > 0" | bc -l) )); then
  cost_info=" ${YELLOW}${ICON_COST}$(printf '%.2f' "$cost")${RESET}"
fi

# ==============================================================================
# Output
# ==============================================================================

echo -e "${model_info}${CYAN}${project_icon} ${repo_name}${branch}${RESET}${folder_info} ${GREEN}${os_icon} ${host}${RESET}${context_info}${cost_info}"
