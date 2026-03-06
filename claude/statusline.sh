#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
# Git info
BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
if [[ -n "$BRANCH" ]]; then
  STAGED=$(git -C "$DIR" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
  MODIFIED=$(git -C "$DIR" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
  UNTRACKED=$(git -C "$DIR" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
  GIT_STATUS="$BRANCH +$STAGED ~$MODIFIED ?$UNTRACKED"
fi

# Build output: [Model] dir | branch +staged ~modified ?untracked
OUTPUT="[$MODEL] ${DIR##*/}"
[[ -n "$GIT_STATUS" ]] && OUTPUT="$OUTPUT | $GIT_STATUS"

# Claude plan quota (cached 5 min)
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
    OUTPUT="$OUTPUT | 5h:${FIVE_H}% 7d:${SEVEN_D}%"
  fi
fi

echo "$OUTPUT"
