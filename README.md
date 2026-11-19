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
./setup-dotfile.sh --module nvim --dry-run  # Preview one module
./setup-dotfile.sh --module nvim            # Set up one module
./setup-dotfile.sh --all --dry-run          # Preview all modules
```

`--module` can be repeated; `--all` selects every module. When the shell module
is selected, setup asks whether to install missing system prerequisites: curl,
git, tmux, and mise. It supports Omarchy/Arch and apt-based systems; the devbox
already has mise's apt repository configured.
`--dry-run` and `--status` never install tools or ask this question.

The `agents`, `herdr`, `nvim`, `tmux`, and `shell` adapters delegate to mise's
declarative dotfiles configuration. They refuse conflicting existing files,
directories, and symlinks; review and move those aside yourself before applying.
They never pass `--force`. Shell profile edits add only missing source lines,
preserving existing settings. Shell's separate mise folder-fragment bootstrap
also refuses conflicts.

| Package | Symlink |
| --------- | --------- |
| `nvim/` | `~/.config/nvim` |
| `tmux/tmux.conf` | `~/.config/tmux/tmux.conf` |
| `herdr/config.toml` | `~/.config/herdr/config.toml` |
| `agents/` | Shared instructions in `~/.config/opencode/AGENTS.md`, `~/.agents/AGENTS.md`, `~/.omp/agent/AGENTS.md`, and `~/.pi/agent/AGENTS.md`; skills in `~/.agents/skills`, `~/.config/opencode/skills`, `~/.pi/agent/skills`, and `~/.claude/skills` |
| `pi/` | `~/.pi/agent/settings.json` + custom subagents in `~/.pi/agent/agents` |
| `shell/` | `~/.config/dotfile/shell` (shell profiles source personal settings) |
| Repository root | `~/.config/mise/conf.d/dotfile` (mise folder fragment, part of shell setup) |

OMP loads the shared instructions when a new default-profile session starts.
OMP task subagents do not inherit `AGENTS.md`.

## Mise profiles

The agent instruction/skill, Herdr, Neovim, tmux, and shell configuration links
are declared only in the root `mise.toml` under `[dotfiles]`, with explicit
`symlink` mode. The same table declares additive Bash and Zsh profile line edits.
Install mise itself first, then install the pinned tools before applying profiles:

```bash
mise trust ./mise.toml
mise install
mise dot status
mise dot apply --dry-run
mise dot apply --yes
mise run herdr-plugins
```

From elsewhere, use `mise -C ~/git/norriswu0/dotfile dot apply --yes` (and the
same `-C` for status or tasks). The module menu still supports selecting just
`agents`, `herdr`, `nvim`, `tmux`, or `shell`; these adapters discover their targets
from mise, so they do not maintain a second inventory. Associated edits use
module-prefixed IDs (for example, `shell.bash`) in the same declaring config.
Herdr setup also synchronizes plugins after its config link is applied.
Status describes managed links and edits, not plugin installation.

Shell setup registers the checkout directory as
`~/.config/mise/conf.d/dotfile`, a mise
[folder fragment](https://mise.jdx.dev/configuration.html#conf-d-folders).
The fragment loads its own `mise.toml` beside the source directories, so plain
relative dotfile sources work both globally and with `-C` inside the checkout.
The plugin task canonicalizes `config_source` via `vars.dotfile_root` to find
the physical checkout.

Rerun `./shell/setup.sh --repo-path "$PWD"` to migrate the previous setup.
It removes `~/.config/mise/config.toml` only if that file is a symlink resolving
to this checkout's `mise.toml`. Independent global files and links remain
untouched, and a conflicting `conf.d/dotfile` is refused rather than replaced.
Do not set `MISE_GLOBAL_CONFIG_FILE` for this layout: that override disables
global fragment discovery.

These declarations deploy repository files only. They do not track application
history, sessions, caches, plugin installations, local configuration, credentials,
or other live runtime data. Existing non-conflicting links remain unchanged on
reruns. See mise's [dotfiles guide](https://mise.jdx.dev/dotfiles.html),
[reference](https://mise.jdx.dev/dotfiles/reference.html), and
[template variables](https://mise.jdx.dev/templates.html#variables).

## OS-specific configuration

Omarchy desktop files live under [`os/omarchy/`](os/omarchy/README.md).
They are manual-only: the setup menu, `--all`, the legacy manifest, and mise
profile deployment do not apply Hyprland, Waybar, or branding configuration.
Existing desktop symlinks must point to the relocated files.

## Shell

Mise links `shell/` to `~/.config/dotfile/shell` and ensures both `~/.bashrc` and
`~/.zshrc` contain the corresponding source line. Existing profile contents and
Omarchy defaults are preserved. The exact source lines from previous shell
setup are reused, so migration and reruns do not duplicate them.
`--dry-run` previews the link and both edits; `--status` checks all three plus
the mise fragment. A profile symlink is refused rather than replaced or followed;
review it and move its contents to a regular profile before applying.
Shell setup only bootstraps the mise folder fragment and retires the old global
file link; mise owns shell deployment and profile editing. The legacy
`noctlrc.yaml` manifest now registers only the fragment. Use shell setup for migration.

Personal aliases live in `shell/alias.conf`. `shell/tools.conf` activates mise
and initializes zoxide when needed. Mise replaces nvm for Node.js management.
The `devbox` alias runs `ssh norris@devbox.hoki-sole.ts.net`; additional arguments
are passed to SSH, for example `devbox hostname`. An existing user alias is kept.

The root `mise.toml` pins personal CLI tools and language runtimes to exact
versions. Shell setup registers its containing folder as global configuration
without replacing an independent `~/.config/mise/config.toml`.
Project-specific `mise.toml` files can override these versions.

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

Each portable configuration directory owns a `setup.sh` adapter. The root setup
script delegates to `nvim/setup.sh`, `tmux/setup.sh`, `herdr/setup.sh`,
`agents/setup.sh`, `pi/setup.sh`, and `shell/setup.sh`.


## Tmux

Install the Tmux Plugin Manager once:

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Start or reload tmux, then press `Ctrl-Space` followed by `I` to install the configured plugins. `tmux-resurrect` saves sessions and `tmux-continuum` saves them every 10 minutes and restores the last state when tmux starts. Snapshots are stored under `~/.local/share/tmux/resurrect/` on this setup.

- Manual save: `Ctrl-Space`, then `Ctrl-S`
- Manual restore: `Ctrl-Space`, then `Ctrl-R`

## Herdr

`herdr/config.toml` uses a `ctrl+space` prefix with tmux-style bindings (alt+arrows for workspace/tab nav, alt+enter/alt+shift+enter splits, ctrl+alt+arrows pane focus). Plugins are declared in `herdr/plugins.yaml` — add one trusted `owner/repo[/subdir]` per entry.

Run `mise run herdr-plugins` to install missing plugins, or
`bash herdr/sync-plugins.sh --dry-run` to preview the declarations without listing
or installing plugins. The standalone script uses only `herdr plugin list --json`
and `herdr plugin install <source> --yes`; it never starts, stops, or reloads a
session. Already installed sources (including their subdirectory) are skipped.
Plugin listing and installation errors fail setup instead of reporting success.
Missing `herdr`, `jq`, or Mike Farah's `yq` is an error; `mise install` supplies
the pinned versions. Plugin config/state remain outside the repository.

## Setup contract checks

With mise, jq, and Mike Farah's yq available:

```bash
mise exec -- bash tests/setup-adapters.sh
mise exec -- bash tests/herdr-plugins.sh
```

The adapter checks use an isolated home and mise state with the real mise CLI,
including folder-fragment discovery, selective apply, reruns, old-file-link
migration, exact legacy hook reuse, additive profile preservation, and conflict
preservation. An interactive Bash startup check exercises the `devbox` alias with
an SSH stub, including argument forwarding, without connecting to the host.
The plugin checks exercise list/install behavior with a controlled Herdr
executable; they do not install third-party code or touch running sessions.

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
