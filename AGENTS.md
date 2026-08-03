# AGENTS.md

Personal dotfiles for an Omarchy (Arch + Hyprland) machine. No build, test, or lint tooling — everything is config deployed via symlinks.

## Symlinks are the source of truth

- `setup-dotfile.sh` owns general deployment: the `LINKS` array maps `repo-relative-path|target`. `shell/setup.sh` owns the selected shell profile link. If you add, move, or rename any deployed file/dir, update the relevant setup script and README table.
- Verify script changes with `bash -n setup-dotfile.sh`, `bash -n shell/setup.sh`, and `./setup-dotfile.sh --repo-path . --dry-run`. Check live state with `--list`.
- Edits to files in this repo take effect immediately on the machine (targets are symlinks into the repo) — be careful with destructive changes.

## Directory ownership

- `agents/` — harness-agnostic AI agent config: instruction file + `agents/skills/*` (linked into `~/.agent/skills`, `~/.claude/skills`, and `~/.config/opencode/skills` simultaneously).
- `claude/` — Claude-Code-specific: `settings.json`, `statusline.sh`, plugin marketplace config, `agents/`. Plugin caches are not tracked; only config is.
- `hypr/` — Hyprland config. `hypr/monitors.conf` is gitignored on purpose (per-device); never commit it.
- `waybar/` — custom waybar; `indicators/scratchpad-listener.sh` is a background daemon (needs `socat` + a live Hyprland session; setup script skips it otherwise). Restart waybar with `omarchy-restart-waybar`. Omarchy upstream defaults live at `~/.local/share/omarchy/config/waybar/` — diff against them after `omarchy-update`.
- `nvim/` — LazyVim config. `lazy-lock.json` is a plugin lockfile managed by lazy.nvim; don't hand-edit.
- `shell/` — composable Bash and Zsh entrypoints and shared modules. Shell entrypoints source sorted `*.conf` files; `tools.yaml` is read by `tools.conf` through `yq`.
- `blogs/` — standalone markdown notes, not deployed.

## Skills

- Each skill is `agents/skills/<name>/SKILL.md` with YAML frontmatter (`name`, `description`). The frontmatter description is what triggers skill loading — keep it action-oriented.

## Conventions

- Commits use conventional-commit style with the directory as scope: `feat(nvim): ...`, `fix(agents): ...`, `feat(setup): ...`.
- Behavioral agent rules (response style, plan mode, PR workflow) live in the instruction file under `agents/` deployed to `~/.claude/CLAUDE.md` — repo-structure guidance belongs here instead.
