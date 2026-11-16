# Dotfile

## Setup

```bash
git clone https://github.com/norriswu0/dotfile ~/git/norriswu0/dotfile
cd ~/git/norriswu0/dotfile
./setup-dotfile.sh
```

The menu shows each module's status and lets you select what to set up:

- ✅ `synced`: all managed links and hooks are in place.
- ⚠️ `drifted`: some settings are missing or point elsewhere.
- ❌ `not-synced`: none of the module's settings are installed.
- ❔ `unknown`: the module's status could not be determined.

When `gum` is available in an interactive terminal, use arrows to move, `x` to
select, Enter to confirm, and Esc to cancel. Otherwise, the numbered menu is
used; `gum` is optional.

Status checks managed links and profile hooks, not plugin installation or
compatibility with a system upgrade. Linked files change immediately when
edited in this repository.

For non-interactive selection:

```bash
./setup-dotfile.sh --status                 # Status of every module
./setup-dotfile.sh --module hypr --dry-run  # Preview one module
./setup-dotfile.sh --module hypr            # Set up one module
./setup-dotfile.sh --all --dry-run          # Preview all modules
```

`--module` can be repeated; `--all` selects every module. When the shell module
is selected, setup asks whether to install missing system prerequisites: curl,
git, tmux, and mise. It supports Omarchy/Arch and apt-based systems; the devbox
already has mise's apt repository configured.
`--dry-run` and `--status` never install tools or ask this question.

Differing existing files and symlinks are backed up to `.bak-YYYYMMDDHHMMSS`
before replacement; identical files are linked without a backup.

| Package | Symlink |
| --------- | --------- |
| `hypr/looknfeel.lua` | `~/.config/hypr/looknfeel.lua` |
| `waybar/` | `~/.config/waybar` |
| `nvim/` | `~/.config/nvim` |
| `tmux/tmux.conf` | `~/.config/tmux/tmux.conf` |
| `herdr/config.toml` | `~/.config/herdr/config.toml` |
| `omarchy/branding/` | `~/.config/omarchy/branding` |
| `agents/` | Shared instructions in `~/.config/opencode/AGENTS.md`, `~/.agents/AGENTS.md`, `~/.omp/agent/AGENTS.md`, and `~/.pi/agent/AGENTS.md`; skills in `~/.agents/skills`, `~/.config/opencode/skills`, and `~/.pi/agent/skills` |
| `pi/` | `~/.pi/agent/settings.json` + custom subagents in `~/.pi/agent/agents` |
| `shell/` | `~/.config/dotfile/shell` (shell profiles source personal settings) |
| `mise.toml` | `~/.config/mise/config.toml` (part of shell setup) |

OMP loads the shared instructions when a new default-profile session starts.
OMP task subagents do not inherit `AGENTS.md`.

## Hyprland

The appearance override sets window gaps to zero and borders to 1px. All other
settings come from Omarchy. Monitor configuration remains per-device.

## Shell

Shell setup links `shell/` to `~/.config/dotfile/shell` and adds a source line
to the selected Bash or Zsh profiles. Existing profile contents and Omarchy
defaults are preserved; existing profiles are backed up before editing.
Rerunning setup does not add the line twice. `--dry-run` previews both profiles,
and `--status` checks the managed links and source lines.
The `noctlrc.yaml` manifest only creates the links; run shell setup to add the
profile source lines.

Personal aliases live in `shell/alias.conf`. `shell/tools.conf` activates mise
and initializes zoxide when needed. Mise replaces nvm for Node.js management.

The root `mise.toml` pins personal CLI tools and language runtimes to exact
versions. Shell setup links it as global configuration, backing up any differing
existing file. Project-specific `mise.toml` files can override these versions.

The baseline also installs Herdr and the AI CLIs: Claude Code (`claude`),
oh-my-pi (`omp`), and OpenCode (`opencode`).

After shell setup, install the pinned tools:

```bash
mise trust ./mise.toml
mise install
exec "$SHELL"
```

Run `tools-check` (or `mise ls --current`) to see requested versions and which
are missing. Git, SSH, Tailscale, and tmux remain system-managed; credentials
stay outside the tool configuration.

Each configuration directory owns a `setup.sh` adapter. The root setup script
resolves the repository path, then delegates to `hypr/setup.sh`,
`waybar/setup.sh`, `nvim/setup.sh`, `tmux/setup.sh`, `herdr/setup.sh`,
`omarchy/setup.sh`,
`agents/setup.sh`, `pi/setup.sh`, and `shell/setup.sh`.


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
- `markdown-documentation` - Apply documentation style and reusable layouts when editing Markdown
