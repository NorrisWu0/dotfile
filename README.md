# Dotfile

## Setup

Each package is a flat directory symlinked directly to its target:

| Package | Symlink |
|---------|---------|
| `hypr/` | `~/.config/hypr` |
| `waybar/` | `~/.config/waybar` |
| `nvim/` | `~/.config/nvim` |
| `omarchy/branding/` | `~/.config/omarchy/branding` |

```bash
ln -s ~/git/norriswu0/dotfile/hypr ~/.config/hypr
ln -s ~/git/norriswu0/dotfile/waybar ~/.config/waybar
ln -s ~/git/norriswu0/dotfile/nvim ~/.config/nvim
ln -s ~/git/norriswu0/dotfile/omarchy/branding ~/.config/omarchy/branding
```

Changes to files in this repo apply instantly. No stow required.

## Waybar (Omarchy)

Custom waybar config with expanded system metrics:
- All tray icons visible (no hidden drawer)
- CPU/memory usage percentages
- Battery with percentage and wattage (↑ charging, ↓ discharging)
- Clock: `YYYY MMM DD Day HH:MM`
- Scratchpad indicator (requires `indicators/scratchpad-listener.sh` running)

```bash
omarchy-restart-waybar
~/.config/waybar/indicators/scratchpad-listener.sh &
```

**Syncing with upstream:** Omarchy defaults live at `~/.local/share/omarchy/config/waybar/`. After `omarchy-update`, diff against defaults and merge new features as needed.

## Claude Code

Custom status line and plugin configs.

**Status line shows:** `[Model] dir | branch +staged ~modified ?untracked | ctx:% | tok:count`

**Plugins enabled:**
- `frontend-design@claude-plugins-official`
- `superpowers@claude-plugins-official`

```bash
# Symlink configs (not using stow - direct symlinks)
ln -sf ~/git/norriswu/dotfile/.claude/CLAUDE.md ~/.claude/CLAUDE.md
ln -sf ~/git/norriswu/dotfile/.claude/settings.json ~/.claude/settings.json
ln -sf ~/git/norriswu/dotfile/.claude/statusline.sh ~/.claude/statusline.sh
mkdir -p ~/.claude/plugins ~/.claude/skills
ln -sf ~/git/norriswu/dotfile/.claude/plugins/installed_plugins.json ~/.claude/plugins/
ln -sf ~/git/norriswu/dotfile/.claude/plugins/known_marketplaces.json ~/.claude/plugins/
ln -sf ~/git/norriswu/dotfile/.claude/skills/document ~/.claude/skills/
ln -sf ~/git/norriswu/dotfile/.claude/skills/skill-research ~/.claude/skills/
ln -sf ~/git/norriswu/dotfile/.claude/skills/make-pr ~/.claude/skills/
```

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