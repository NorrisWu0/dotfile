# Dotfile

## Setup

```bash
git clone https://github.com/norriswu0/dotfile ~/git/norriswu0/dotfile
cd ~/git/norriswu0/dotfile
./setup-dotfile.sh --repo-path ~/git/norriswu0/dotfile
```

Existing configs are backed up to `.orig` before being replaced. Use `--dry-run` to preview changes, `--list` to check current symlink state.

| Package | Symlink |
|---------|---------|
| `hypr/` | `~/.config/hypr` |
| `waybar/` | `~/.config/waybar` |
| `nvim/` | `~/.config/nvim` |
| `omarchy/branding/` | `~/.config/omarchy/branding` |
| `agent/` | `~/.claude/CLAUDE.md` + `~/.claude/skills/*` (harness-agnostic) |
| `claude/` | `~/.claude/` (harness-specific config: settings, plugins, statusline) |

## Waybar (Omarchy)

Custom waybar config with expanded system metrics:
- All tray icons visible (no hidden drawer)
- CPU/memory usage percentages
- Battery with percentage and wattage (↑ charging, ↓ discharging)
- Clock: `YYYY MMM DD Day HH:MM`
- Scratchpad indicator (auto-started via `hypr/autostart.conf`)

**Dependencies:**
```bash
sudo pacman -S openbsd-netcat  # required by scratchpad-listener.sh
```

```bash
omarchy-restart-waybar
```

**Syncing with upstream:** Omarchy defaults live at `~/.local/share/omarchy/config/waybar/`. After `omarchy-update`, diff against defaults and merge new features as needed.

## Claude Code

Custom status line and plugin configs.

**Status line shows:** `[Model] dir | branch +staged ~modified ?untracked | ctx:% | tok:count`

**Plugins enabled:**
- `frontend-design@claude-plugins-official`
- `superpowers@claude-plugins-official`

Plugin cache auto-downloads on restart - only config files tracked.

**Custom skills:**
- `document` - Generate user-facing docs via `/document`
  - Directory-level scoping (depth = zoom)
  - Question headings, concise + educational
  - 5 min read target, splits if longer
  - Suggests documentation after significant edits
- `skill-research` - Evaluate skills before installing via `/skill-research <topic>`
  - Searches GitHub first, then web
  - Checks stars, forks, activity, author
  - Trust score based on metrics
  - Detailed report on request
- `make-pr` - Create PRs with clear descriptions via `/make-pr`
  - Detects project template or uses default
  - Under 3 min read, high-level language
  - TL;DR, Key changes, Testing, What else sections
  - Human-only confirmation checkbox
