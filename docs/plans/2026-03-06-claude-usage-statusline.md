# Claude Usage Statusline Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Append `5h:31% 7d:70%` Claude plan quota to the existing Claude Code statusline output.

**Architecture:** Shell script reads the oauth token from `~/.claude/.credentials.json`, calls `api.anthropic.com/api/oauth/usage` with a 5-minute cache at `/tmp/claude_usage_cache.json`, and appends the formatted usage to the existing statusline OUTPUT string.

**Tech Stack:** bash, curl, jq — no new dependencies.

---

### Task 1: Add usage fetch to statusline.sh

**Files:**
- Modify: `~/.claude/statusline.sh`

This file receives JSON via stdin and outputs a one-line status string. Currently ends with:
```
ctx:10% | tok:33k
```
We add `| 5h:31% 7d:70%` at the end.

**Step 1: Verify the API works manually**

```bash
TOKEN=$(jq -r '.claudeAiOauth.accessToken' ~/.claude/.credentials.json)
curl -s \
  -H "Authorization: Bearer $TOKEN" \
  -H "anthropic-beta: oauth-2025-04-20" \
  -H "User-Agent: claude-code/2.0.32" \
  "https://api.anthropic.com/api/oauth/usage" | jq '{five_hour, seven_day}'
```

Expected output:
```json
{
  "five_hour": { "utilization": 31, "resets_at": "..." },
  "seven_day":  { "utilization": 70, "resets_at": "..." }
}
```

**Step 2: Edit `~/.claude/statusline.sh`**

Add this block before the final `echo "$OUTPUT"` line:

```bash
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
      "https://api.anthropic.com/api/oauth/usage" > "$CACHE_FILE" 2>/dev/null || rm -f "$CACHE_FILE"
  fi
fi

if [[ -f "$CACHE_FILE" ]]; then
  FIVE_H=$(jq -r '.five_hour.utilization // empty' "$CACHE_FILE" 2>/dev/null)
  SEVEN_D=$(jq -r '.seven_day.utilization // empty' "$CACHE_FILE" 2>/dev/null)
  if [[ -n "$FIVE_H" && -n "$SEVEN_D" ]]; then
    OUTPUT="$OUTPUT | 5h:${FIVE_H}% 7d:${SEVEN_D}%"
  fi
fi
```

**Step 3: Test manually**

```bash
echo '{"model":{"display_name":"Sonnet 4.6"},"workspace":{"current_dir":"/tmp"},"context_window":{"used_percentage":10,"total_input_tokens":1000,"total_output_tokens":200}}' \
  | bash ~/.claude/statusline.sh
```

Expected output contains `| 5h:31% 7d:70%` at the end.

**Step 4: Verify caching works**

```bash
ls -la /tmp/claude_usage_cache.json  # should exist now
# Run again - should be instant (no API call)
time echo '{"model":{"display_name":"Sonnet 4.6"},"workspace":{"current_dir":"/tmp"},"context_window":{"used_percentage":10,"total_input_tokens":1000,"total_output_tokens":200}}' \
  | bash ~/.claude/statusline.sh
```

**Step 5: Commit**

```bash
cd ~/git/norriswu/dotfile
git add docs/plans/2026-03-06-claude-usage-statusline-design.md
git add docs/plans/2026-03-06-claude-usage-statusline.md
# statusline.sh is outside repo — commit the docs only
git commit -m "docs: add claude usage statusline plan"
```

Note: `~/.claude/statusline.sh` lives outside the dotfile repo. If you symlink it in future, commit it then.

---

### Task 2: (Optional) Add waybar widget

If you also want this visible in waybar (not just in the Claude Code statusline):

**Files:**
- Create: `waybar/indicators/claude-usage.sh`
- Modify: `waybar/config.jsonc`

**Step 1: Create `waybar/indicators/claude-usage.sh`**

```bash
#!/bin/bash
CACHE_FILE="/tmp/claude_usage_cache.json"
CACHE_AGE=300

if [[ ! -f "$CACHE_FILE" ]] || [[ $(( $(date +%s) - $(stat -c %Y "$CACHE_FILE") )) -gt $CACHE_AGE ]]; then
  TOKEN=$(jq -r '.claudeAiOauth.accessToken' ~/.claude/.credentials.json 2>/dev/null)
  if [[ -n "$TOKEN" ]]; then
    curl -s --max-time 3 \
      -H "Authorization: Bearer $TOKEN" \
      -H "anthropic-beta: oauth-2025-04-20" \
      -H "User-Agent: claude-code/2.0.32" \
      "https://api.anthropic.com/api/oauth/usage" > "$CACHE_FILE" 2>/dev/null || rm -f "$CACHE_FILE"
  fi
fi

if [[ -f "$CACHE_FILE" ]]; then
  FIVE_H=$(jq -r '.five_hour.utilization // empty' "$CACHE_FILE" 2>/dev/null)
  SEVEN_D=$(jq -r '.seven_day.utilization // empty' "$CACHE_FILE" 2>/dev/null)
  FIVE_RESET=$(jq -r '.five_hour.resets_at // empty' "$CACHE_FILE" 2>/dev/null)
  SEVEN_RESET=$(jq -r '.seven_day.resets_at // empty' "$CACHE_FILE" 2>/dev/null)
  if [[ -n "$FIVE_H" ]]; then
    TEXT="5h:${FIVE_H}% 7d:${SEVEN_D}%"
    TOOLTIP="Session resets: $FIVE_RESET\nWeekly resets: $SEVEN_RESET"
    echo "{\"text\":\"$TEXT\",\"tooltip\":\"$TOOLTIP\",\"class\":\"claude-usage\"}"
    exit 0
  fi
fi

echo '{"text":"","tooltip":"Claude usage unavailable"}'
```

**Step 2: Make executable**
```bash
chmod +x waybar/indicators/claude-usage.sh
```

**Step 3: Add to `waybar/config.jsonc`**

In `modules-right` array, add `"custom/claude-usage"` before `"tray"`.

Add the module config:
```jsonc
"custom/claude-usage": {
  "exec": "~/.config/waybar/indicators/claude-usage.sh",
  "return-type": "json",
  "interval": 300,
  "tooltip": true
},
```

**Step 4: Symlink the script (follows your flat symlink pattern)**

```bash
ln -sf ~/git/norriswu/dotfile/waybar/indicators/claude-usage.sh \
       ~/.config/waybar/indicators/claude-usage.sh
```

**Step 5: Reload waybar**
```bash
pkill waybar && waybar &
```

**Step 6: Commit**
```bash
cd ~/git/norriswu/dotfile
git add waybar/indicators/claude-usage.sh waybar/config.jsonc
git commit -m "feat: add claude usage waybar widget"
```
