# Dotfile

## Setup

```bash
git clone https://github.com/norriswu0/dotfile ~/git/norriswu0/dotfile
cd ~/git/norriswu0/dotfile
./setup-dotfile.sh --repo-path ~/git/norriswu0/dotfile
```

Differing existing configs are backed up to `.bak-YYYYMMDDHHMMSS` before being replaced; identical files are linked without a backup. Backups are ignored by Git. Use `--dry-run` to preview changes, `--status` to check current symlink state.

| Package | Symlink |
|---------|---------|
| `hypr/` | `~/.config/hypr` |
| `waybar/` | `~/.config/waybar` |
| `nvim/` | `~/.config/nvim` |
| `tmux/tmux.conf` | `~/.config/tmux/tmux.conf` |
| `herdr/config.toml` | `~/.config/herdr/config.toml` |
| `omarchy/branding/` | `~/.config/omarchy/branding` |
| `agents/` | `~/.config/opencode/AGENTS.md` + skills in `~/.agent/skills`, `~/.config/opencode/skills` |

## Bash

`shell/.bashrc` and `shell/.zshrc` are shell-specific entrypoints that source
all `shell/*.conf` modules in sorted order. `setup-dotfile.sh` invokes
`shell/setup.sh` to choose which profiles to link. The standalone
`./shell/setup.sh` command can also be rerun independently. If `fzf` is
installed, the setup chooser supports arrow keys, mouse selection, and
multi-select. Aliases live in
`alias.conf`, while `tools.conf` reads the tool registry from `tools.yaml`
using `yq`. `shell/setup.sh --dry-run` previews both shell profile links.

Each configuration directory owns a `setup.sh` adapter. The root setup script
resolves the repository path, then delegates to `hypr/setup.sh`,
`waybar/setup.sh`, `nvim/setup.sh`, `tmux/setup.sh`, `herdr/setup.sh`,
`omarchy/setup.sh`,
`agents/setup.sh`, and `shell/setup.sh`.

Run `tools-check` from an interactive Bash session to check configured tools
and see official installation links for missing tools. If `yq` is unavailable,
tool initialization is skipped with an installation hint.

## Waybar (Omarchy)

Custom waybar config with expanded system metrics:
- All tray icons visible (no hidden drawer)
- CPU/memory usage percentages
- Battery with percentage and wattage (↑ charging, ↓ discharging)
- Clock: `YYYY MMM DD Day HH:MM`
- Scratchpad indicator (auto-started via `hypr/autostart.conf`)

**Dependencies:**
```bash
sudo pacman -S socat  # required by scratchpad-listener.sh
```

```bash
omarchy-restart-waybar
```

**Syncing with upstream:** Omarchy defaults live at `~/.local/share/omarchy/config/waybar/`. After `omarchy-update`, diff against defaults and merge new features as needed.

## Tmux

Install the Tmux Plugin Manager once:

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Start or reload tmux, then press `Ctrl-Space` followed by `I` to install the configured plugins. `tmux-resurrect` saves sessions and `tmux-continuum` saves them every 10 minutes and restores the last state when tmux starts. Snapshots are stored under `~/.local/share/tmux/resurrect/` on this setup.

- Manual save: `Ctrl-Space`, then `Ctrl-S`
- Manual restore: `Ctrl-Space`, then `Ctrl-R`

## Herdr

`herdr/config.toml` uses a `ctrl+space` prefix with tmux-style bindings (alt+arrows for workspace/tab nav, alt+enter/alt+shift+enter splits, ctrl+alt+arrows pane focus). Plugins are declared in `herdr/plugins.yaml` and synced by `herdr/setup.sh` via `herdr plugin install` — add one `owner/repo[/subdir]` per line and rerun setup.

## Claude Code

Custom status line and plugin configs.

**Status line shows:** `[Model] dir | branch +staged ~modified ?untracked | ctx:% | tok:count`

**Plugins enabled:**
- `frontend-design@claude-plugins-official`
- `superpowers@claude-plugins-official`

Plugin cache auto-downloads on restart - only config files tracked.

**Custom skills:**
- `make-pr` - Create PRs with clear descriptions via `/make-pr`
  - Detects project template or uses default
  - Under 3 min read, high-level language
  - Why, TL;DR, Key changes, Testing, What else sections
  - Human-only confirmation checkbox
