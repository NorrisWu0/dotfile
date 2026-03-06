# Claude Usage Statusline Integration

## Goal

Append Claude plan quota (`5h:31% 7d:70%`) to the existing Claude Code statusline without requiring manual `/usage` checks.

## API

- **Endpoint:** `GET https://api.anthropic.com/api/oauth/usage`
- **Auth:** `Authorization: Bearer <token>` from `~/.claude/.credentials.json` (`.claudeAiOauth.accessToken`)
- **Header:** `anthropic-beta: oauth-2025-04-20`
- **Response:** `{ five_hour: { utilization, resets_at }, seven_day: { utilization, resets_at } }`

## Output Format

```
[Sonnet 4.6] dotfile | feat/branch +1 ~2 ?0 | ctx:10% | tok:33k | 5h:31% 7d:70%
```

## Caching

- Cache file: `/tmp/claude_usage_cache.json`
- TTL: 5 minutes (300s) — stale on first run or after TTL expires
- On API failure: silently skip the usage section

## Changes

- `~/.claude/statusline.sh` — add usage fetch + cache logic, append to OUTPUT
