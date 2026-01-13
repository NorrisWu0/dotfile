---
description: "Export conversation history to .claude/logs/YYYY-MM-DD-[description].txt. Example: /export-logfile feature-planning"
allowed-tools: Bash, Write
argument-hint: [description]
---

Export this entire conversation to a text file.

**Instructions:**
1. Create directory `.claude/logs` if not exists
2. Generate filename: `!`date +%Y-%m-%d`-$ARGUMENTS.txt`
3. Save to: `.claude/logs/[filename]`

**Content to include:**
- Full conversation history (user prompts + Claude responses)
- Code snippets and outputs
- Any decisions or conclusions made

**Format:** Plain text, readable, chronological order
