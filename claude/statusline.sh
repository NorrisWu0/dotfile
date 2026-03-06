#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
CONTEXT=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
TOKENS_IN=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
TOKENS_OUT=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')

# Git info
BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
if [[ -n "$BRANCH" ]]; then
  STAGED=$(git -C "$DIR" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
  MODIFIED=$(git -C "$DIR" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
  UNTRACKED=$(git -C "$DIR" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
  GIT_STATUS="$BRANCH +$STAGED ~$MODIFIED ?$UNTRACKED"
fi

# Format tokens (k for thousands)
TOTAL_TOKENS=$((TOKENS_IN + TOKENS_OUT))
if [[ $TOTAL_TOKENS -ge 1000 ]]; then
  TOKENS_DISPLAY="$((TOTAL_TOKENS / 1000))k"
else
  TOKENS_DISPLAY="$TOTAL_TOKENS"
fi

# Build output: [Model] dir | branch +staged ~modified ?untracked | context% | tokens
OUTPUT="[$MODEL] ${DIR##*/}"
[[ -n "$GIT_STATUS" ]] && OUTPUT="$OUTPUT | $GIT_STATUS"
OUTPUT="$OUTPUT | ctx:${CONTEXT}% | tok:${TOKENS_DISPLAY}"

echo "$OUTPUT"
