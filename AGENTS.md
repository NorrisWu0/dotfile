# AGENTS.md

Personal dotfiles for an Omarchy (Arch + Hyprland) machine. Configuration is deployed via symlinks.

## Symlinks are the source of truth

- `setup-dotfile.sh` resolves the repository and delegates deployment to each directory's `setup.sh`; `lib/setup.sh` owns shared symlink operations. Shell setup additionally adds source lines to existing profiles. If you add, move, or rename any deployed file/dir, update the relevant module setup script and README table.
- Verify script changes with `bash -n setup-dotfile.sh`, `bash -n lib/setup.sh`, `./tests/setup-adapters.sh`, and `./setup-dotfile.sh --repo-path . --dry-run`. Check live state with `--status`.
- Edits to files in this repo take effect immediately on the machine (targets are symlinks into the repo) — be careful with destructive changes.
- Each module's `setup.sh --sync-status` reports `synced`, `drifted`, or `not-synced` without making changes; `setup-dotfile.sh` uses this adapter contract for its menu.

## Directory ownership

- `agents/` — harness-agnostic AI agent config: instruction file + `agents/skills/*` (linked into `~/.agent/skills`, `~/.config/opencode/skills`, and Pi's global context/skills paths).
- `pi/` — Pi settings and custom subagent definitions, linked into `~/.pi/agent/`.
- `hypr/` — Hyprland config. `hypr/monitors.lua` is gitignored on purpose (per-device); never commit it.
- `waybar/` — custom waybar; `indicators/scratchpad-listener.sh` is a background daemon (needs `socat` + a live Hyprland session; setup script skips it otherwise). Restart waybar with `omarchy-restart-waybar`. Omarchy upstream defaults live at `~/.local/share/omarchy/config/waybar/` — diff against them after `omarchy-update`.
- `nvim/` — LazyVim config. `lazy-lock.json` is a plugin lockfile managed by lazy.nvim; don't hand-edit.
- `shell/` — additive Bash and Zsh settings: existing profiles source the linked entrypoints, which load sorted `*.conf` modules. `tools.yaml` is read by `tools-check` through `yq`.
- `blogs/` — standalone markdown notes, not deployed.

## Skills

- Each skill is `agents/skills/<name>/SKILL.md` with YAML frontmatter (`name`, `description`). The frontmatter description is what triggers skill loading — keep it action-oriented.

## Conventions

- Commits use conventional-commit style with the directory as scope: `feat(nvim): ...`, `fix(agents): ...`, `feat(setup): ...`.
- Behavioral agent rules (response style, plan mode, PR workflow) live in the instruction file under `agents/` deployed to `~/.config/opencode/AGENTS.md` — repo-structure guidance belongs here instead.
