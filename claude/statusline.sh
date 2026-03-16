#!/bin/bash
input=$(cat)

# ── Line 1: Model + Directory + Git branch ───────────────────────────────────
MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)

LINE1="[$MODEL] ${DIR##*/}"
[[ -n "$BRANCH" ]] && LINE1="$LINE1 | $BRANCH"

# ── Line 2: Context window bar + Plan quota ───────────────────────────────────
CTX_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0')

build_bar() {
  local pct=$1 width=$2
  local filled=$(( pct * width / 100 )) empty=$(( width - pct * width / 100 ))
  local bar=""
  for (( i=0; i<filled; i++ )); do bar+="█"; done
  for (( i=0; i<empty; i++ )); do bar+="░"; done

  local reset="\033[0m"
  local color
  if (( pct >= 80 )); then
    color="\033[31m"   # red
  elif (( pct >= 50 )); then
    color="\033[33m"   # yellow
  else
    color="\033[32m"   # green
  fi

  echo -e "[${color}${bar}${reset}] ${pct}%"
}

# Reserve space for "[] XX%  5h:XXX% 7d:XXX%" — ~22 chars; rest goes to bar
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
BAR_WIDTH=$(( TERM_WIDTH - 22 ))
[[ $BAR_WIDTH -lt 10 ]] && BAR_WIDTH=10

LINE2=$(build_bar "$CTX_PCT" "$BAR_WIDTH")

CACHE_FILE="/tmp/claude_usage_cache.json"
CACHE_AGE=300

if [[ ! -f "$CACHE_FILE" ]] || [[ $(( $(date +%s) - $(stat -c %Y "$CACHE_FILE") )) -gt $CACHE_AGE ]]; then
  TOKEN=$(jq -r '.claudeAiOauth.accessToken' ~/.claude/.credentials.json 2>/dev/null)
  if [[ -n "$TOKEN" ]]; then
    curl -s --max-time 3 \
      -H "Authorization: Bearer $TOKEN" \
      -H "anthropic-beta: oauth-2025-04-20" \
      -H "User-Agent: claude-code/2.0.32" \
      "https://api.anthropic.com/api/oauth/usage" > "${CACHE_FILE}.tmp" 2>/dev/null \
      && mv "${CACHE_FILE}.tmp" "$CACHE_FILE" \
      || rm -f "${CACHE_FILE}.tmp"
  fi
fi

if [[ -f "$CACHE_FILE" ]]; then
  FIVE_H=$(jq -r '.five_hour.utilization // empty' "$CACHE_FILE" 2>/dev/null)
  SEVEN_D=$(jq -r '.seven_day.utilization // empty' "$CACHE_FILE" 2>/dev/null)
  if [[ -n "$FIVE_H" && -n "$SEVEN_D" ]]; then
    colorize() {
      local pct=$1 label=$2
      local reset="\033[0m" color
      if (( pct >= 80 )); then color="\033[31m"
      elif (( pct >= 50 )); then color="\033[33m"
      else color="\033[32m"; fi
      echo -e "${label}:${color}${pct}%${reset}"
    }
    LINE2="$LINE2  $(colorize "$FIVE_H" "5h") $(colorize "$SEVEN_D" "7d")"
  fi
fi

echo "$LINE1"
echo "$LINE2"
