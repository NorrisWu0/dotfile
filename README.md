# Dotfile

## Setup

Install Git, curl, tmux, and a recent [mise](https://mise.jdx.dev/getting-started.html)
with native dotfile support using your system's package manager first.

```bash
git clone https://github.com/norriswu0/dotfile ~/git/norriswu0/dotfile
cd ~/git/norriswu0/dotfile
mise trust ./mise.toml
mise install
mise dot status
mise dot diff
mise dot apply --dry-run
mise dot apply --yes
mise run herdr-plugins
```

The root `mise.toml` is the only deployment configuration. There is no setup
menu or adapter layer. Review `mise dot diff` and the dry-run before applying:
native mise protects conflicting regular files and nonempty directories without
`--force`, but can retarget an existing symlink. Move conflicting settings aside
yourself rather than forcing replacement. Shell edits add only missing source
lines, preserving existing settings and Omarchy defaults. Linked files change
immediately when edited in this repository.

| Package | Symlink |
| --------- | --------- |
| `nvim/` | `~/.config/nvim` |
| `tmux/tmux.conf` | `~/.config/tmux/tmux.conf` |
| `herdr/config.toml` | `~/.config/herdr/config.toml` |
| `agents/opencode/opencode.json` | `~/.config/opencode/opencode.json` (remote instructions and skills) |
| `agents/` | Shared instructions in `~/.agents/AGENTS.md`; skills in `~/.agents/skills` and `~/.claude/skills` |
| `shell/` | `~/.config/dotfile/shell` (shell profiles source personal settings) |
| `shell/ssh/devbox.conf` | `~/.ssh/config.d/devbox.conf` (included by SSH config on every machine) |
| Repository root | `~/.config/mise/conf.d/dotfile` (global mise folder fragment) |

OpenCode's application settings are tracked separately from terminal preferences
(`cli.json`), credentials, and runtime data. The shared `~/.agents/skills` link
remains available to agents that discover it; remote skills are not exclusive.

## Mise profiles

The agent instructions/skills, OpenCode settings, Herdr, Neovim,
tmux, and shell links use explicit native `symlink` entries. The same root
configuration declares additive Bash and Zsh profile line edits and its own
global registration.

From elsewhere, use `mise -C ~/git/norriswu0/dotfile dot apply --yes` (and the
same `-C` for status or tasks). To deploy or inspect just one target, name it:

```bash
mise -C ~/git/norriswu0/dotfile dot status ~/.config/nvim
mise -C ~/git/norriswu0/dotfile dot apply --dry-run ~/.config/nvim
mise -C ~/git/norriswu0/dotfile dot apply --yes ~/.config/nvim
```

Herdr plugin installation remains a separate substantive operation:
`mise run herdr-plugins`. Dotfile status describes links and edits, not plugins.

Native apply registers the checkout directory as
`~/.config/mise/conf.d/dotfile`, a mise
[folder fragment](https://mise.jdx.dev/configuration.html#conf-d-folders).
The fragment loads its own `mise.toml` beside the source directories, so plain
relative dotfile sources work both globally and with `-C` inside the checkout.
The plugin task canonicalizes `config_source` via `vars.dotfile_root` to find
the physical checkout.

Mise applies entries that deploy its own configuration first and reloads it
in the same run. The directory fragment works both inside and outside the checkout;
it does not replace an independent `~/.config/mise/config.toml`.
If a previous setup linked that global file directly to this checkout's
`mise.toml`, remove only that known obsolete link before applying (the devbox
Ansible role migrates it automatically). Leave independent user files and links
alone. A conflicting `conf.d/dotfile` is refused rather than replaced.
Do not set `MISE_GLOBAL_CONFIG_FILE`: that override disables global fragment
discovery.

These declarations deploy repository files only. They do not track application
history, sessions, caches, plugin installations, local configuration, credentials,
or other live runtime data. Existing non-conflicting links remain unchanged on
reruns. See mise's [dotfiles guide](https://mise.jdx.dev/dotfiles.html),
[reference](https://mise.jdx.dev/dotfiles/reference.html), and
[template variables](https://mise.jdx.dev/templates.html#variables).

## OS-specific configuration

Omarchy desktop files live under [`os/omarchy/`](os/omarchy/README.md).
They are manual-only: native mise deployment does not apply Hyprland, Waybar,
or branding configuration.
Existing desktop symlinks must point to the relocated files.

## Shell

Mise links `shell/` to `~/.config/dotfile/shell` and ensures both `~/.bashrc` and
`~/.zshrc` contain the corresponding source line. Existing profile contents and
Omarchy defaults are preserved. The exact source lines from previous shell
setup are reused, so migration and reruns do not duplicate them.
`mise dot apply --dry-run` previews the link and edits; `mise dot status` inspects
their state. A profile symlink is refused rather than replaced or followed;
review it and move its contents to a regular profile before applying.

Personal aliases live in `shell/alias.conf`. `shell/tools.conf` activates mise
and initializes zoxide when needed. Mise replaces nvm for Node.js management.
The `devbox` alias runs `ssh norris@devbox.hoki-sole.ts.net`; additional arguments
are passed to SSH, for example `devbox hostname`. An existing user alias is kept.

### Devbox SSH client

The root mise configuration deploys `shell/ssh/devbox.conf` on every machine,
including devbox itself. It links `~/.ssh/config.d/devbox.conf` and prepends
`Include ~/.ssh/config.d/devbox.conf` to `~/.ssh/config`, preserving existing
settings. The normal root apply is sufficient; there is no separate profile,
selection file, or opt-in mode.

To inspect or apply just these targets from the repository root:

```bash
mise dot apply --dry-run ~/.ssh/config.d/devbox.conf ~/.ssh/config/ssh.devbox
mise dot apply --yes ~/.ssh/config.d/devbox.conf ~/.ssh/config/ssh.devbox
```

Review conflicting destinations or a symlinked SSH config instead of forcing
replacement. Both `ssh devbox` and the `devbox` alias select Bitwarden's
`~/.bitwarden-ssh-agent.sock` without an `SSH_AUTH_SOCK` export; other hosts
keep their own authentication settings. To connect, install and connect
Tailscale, enable Bitwarden Desktop's SSH agent, and unlock the vault containing
your devbox key. Private keys stay in Bitwarden, and signing approval may still
be required. Deploying this configuration does not install or unlock Bitwarden.

### Personal tools

The root `mise.toml` pins personal CLI tools and language runtimes to exact
versions. Native dotfile apply registers its containing folder globally without
replacing an independent `~/.config/mise/config.toml`.
Project-specific `mise.toml` files can override these versions.

The baseline also installs Herdr and the AI CLIs: Claude Code (`claude`)
and OpenCode (`opencode`).

Neovim gets Go and TypeScript language servers from the LazyVim `lang.go` and
`lang.typescript` extras (`nvim/lazyvim.json`). Mason installs `gopls`, `vtsls`
and their formatters on first launch. Go is pinned here because Mason builds
`gopls` with it.

After native dotfile deployment, install or refresh the pinned tools:

```bash
mise trust ./mise.toml
mise install
exec "$SHELL"
```

Run `tools-check` (or `mise ls --current`) to see requested versions and which
are missing. Git, SSH, Tailscale, and tmux remain system-managed; credentials
stay outside the tool configuration.


## Tmux

Install the Tmux Plugin Manager once:

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Start or reload tmux, then press `Ctrl-Space` followed by `I` to install the configured plugins. `tmux-resurrect` saves sessions and `tmux-continuum` saves them every 10 minutes and restores the last state when tmux starts. Snapshots are stored under `~/.local/share/tmux/resurrect/` on this setup.

- Manual save: `Ctrl-Space`, then `Ctrl-S`
- Manual restore: `Ctrl-Space`, then `Ctrl-R`

## Herdr

`herdr/config.toml` uses a `ctrl+space` prefix with tmux-style bindings (alt+arrows for workspace/tab nav, alt+enter/alt+shift+enter splits, ctrl+alt+arrows pane focus). Plugins are declared in `herdr/plugins.yaml` as trusted `owner/repo[/subdir]@ref` entries. Pin published releases so their prebuilt installers do not require a compiler.

Run `mise run herdr-plugins` to install missing plugins, or
`bash herdr/sync-plugins.sh --dry-run` to preview the declarations without listing
or installing plugins. The standalone script uses only `herdr plugin list --json`
and `herdr plugin install <source> --yes --ref <ref>`; it never starts, stops, or
reloads a session. Installed sources are skipped only when both subdirectory and
requested ref match; changing a pin installs the requested release.
Plugin listing and installation errors fail setup instead of reporting success.
Missing `herdr`, `jq`, or Mike Farah's `yq` is an error; `mise install` supplies
the pinned versions. Plugin config/state remain outside the repository.

## Native deployment checks

With mise, OpenSSH, jq, and Mike Farah's yq available:

```bash
mise exec -- bash tests/native-mise.sh
mise exec -- bash tests/herdr-plugins.sh
```

The deployment checks use the real mise CLI with isolated HOME, XDG/mise
directories, and ancestor-config discovery. They exercise dry-run behavior,
declarative self-registration, global folder-fragment discovery, all common
links, rerun idempotence, additive shell preservation, and
preservation of conflicting regular files, directories, linked profiles, and
the data behind foreign symlinks.
They also check default SSH deployment, preservation of SSH settings, and
host-scoped authentication with real `ssh -G` configuration evaluation.
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
