# AGENTS.md

Personal dotfiles for an Omarchy (Arch + Hyprland) machine. No build, test, or lint tooling — everything is config deployed via symlinks.

## Symlinks are the source of truth

- `setup-dotfile.sh` owns all deployment: the `LINKS` array maps `repo-relative-path|target`. If you add, move, or rename any deployed file/dir, update `LINKS` and the README table, or the symlink silently breaks (`--list` reports it).
- Verify script changes with `bash -n setup-dotfile.sh` and `./setup-dotfile.sh --repo-path . --dry-run`. Check live state with `--list`.
- Edits to files in this repo take effect immediately on the machine (targets are symlinks into the repo) — be careful with destructive changes.

## Directory ownership

- `agent/` — harness-agnostic AI agent config: instruction file + `agent/skills/*` (linked into `~/.agent/skills`, `~/.claude/skills`, and `~/.config/opencode/skills` simultaneously).
- `claude/` — Claude-Code-specific: `settings.json`, `statusline.sh`, plugin marketplace config, `agents/`. Plugin caches are not tracked; only config is.
- `hypr/` — Hyprland config. `hypr/monitors.conf` is gitignored on purpose (per-device); never commit it.
- `waybar/` — custom waybar; `indicators/scratchpad-listener.sh` is a background daemon (needs `openbsd-netcat`). Restart waybar with `omarchy-restart-waybar`. Omarchy upstream defaults live at `~/.local/share/omarchy/config/waybar/` — diff against them after `omarchy-update`.
- `nvim/` — LazyVim config. `lazy-lock.json` is a plugin lockfile managed by lazy.nvim; don't hand-edit.
- `blogs/` — standalone markdown notes, not deployed.

## Skills

- Each skill is `agent/skills/<name>/SKILL.md` with YAML frontmatter (`name`, `description`). The frontmatter description is what triggers skill loading — keep it action-oriented.

## Conventions

- Commits use conventional-commit style with the directory as scope: `feat(nvim): ...`, `fix(agent): ...`, `feat(setup): ...`.
- Behavioral agent rules (response style, plan mode, PR workflow) live in the instruction file under `agent/` deployed to `~/.claude/CLAUDE.md` — repo-structure guidance belongs here instead.
