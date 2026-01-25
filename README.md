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