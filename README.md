# Dotfile

## Setup

[GNU Stow](https://www.gnu.org/software/stow/) symlinks files to `~`, keeping dotfiles version-controlled in one place.

```bash
brew install stow
stow -t ~ .
```

Stow creates symlinks, not copies. Changes are instant. Re-run `stow` only when adding new files.

## Waybar (Omarchy)

Custom waybar config with expanded system metrics:
- All tray icons visible (no hidden drawer)
- CPU/memory usage percentages
- Battery with percentage and wattage (↑ charging, ↓ discharging)
- Clock: `YYYY MMM DD Day HH:MM`

```bash
rm -rf ~/.config/waybar
stow -t ~ waybar
omarchy-restart-waybar
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