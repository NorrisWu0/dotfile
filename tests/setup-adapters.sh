#!/usr/bin/env bash

set -euo pipefail

repo="$(realpath "$(dirname "$0")/..")"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
export HOME="$work/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$work/cache"
export XDG_DATA_HOME="$work/data"
export XDG_STATE_HOME="$work/state"
export MISE_CONFIG_DIR="$HOME/.config/mise"
unset MISE_GLOBAL_CONFIG_FILE
export MISE_CACHE_DIR="$work/cache/mise"
export MISE_DATA_DIR="$work/data/mise"
export MISE_STATE_DIR="$work/state/mise"
export MISE_TRUSTED_CONFIG_PATHS="$repo"
export MISE_CEILING_PATHS="$(dirname "$repo")"
export MISE_AUTO_INSTALL_DISABLE=1
mkdir -p "$HOME/.config"

status() {
    bash "$repo/$1/setup.sh" --repo-path "$repo" --sync-status
}

expect_status() {
    local actual
    actual="$(status "$1")"
    if [[ "$actual" != "$2" ]]; then
        printf '%s: expected %s, got %s\n' "$1" "$2" "$actual" >&2
        exit 1
    fi
}

# Desktop modules are deliberately unavailable, including explicit selection.
for module in hypr waybar omarchy; do
    if bash "$repo/setup-dotfile.sh" --module "$module" --dry-run >/dev/null 2>&1; then
        printf 'Desktop module unexpectedly accepted: %s\n' "$module" >&2
        exit 1
    fi
done

expect_status shell not-synced
mkdir -p "$HOME/.config/dotfile"
ln -s "$repo/shell" "$HOME/.config/dotfile/shell"
expect_status shell drifted
bash_hook='[[ ! -r "$HOME/.config/dotfile/shell/.bashrc" ]] || source "$HOME/.config/dotfile/shell/.bashrc"'
zsh_hook='[[ ! -r "$HOME/.config/dotfile/shell/.zshrc" ]] || source "$HOME/.config/dotfile/shell/.zshrc"'
printf '%s\n' '# personal Bash settings' 'export KEEP_BASH=1' "$bash_hook" > "$HOME/.bashrc"
cp "$HOME/.bashrc" "$work/bash-profile"
printf '%s\n' '# personal Zsh settings' 'export KEEP_ZSH=1' > "$HOME/.zshrc"
cp "$HOME/.zshrc" "$work/zsh-original"
expect_status shell drifted
mkdir -p "$HOME/.config/mise"
ln -s "$repo/mise.toml" "$HOME/.config/mise/config.toml"
expect_status shell drifted
bash "$repo/shell/setup.sh" --repo-path "$repo" --dry-run >/dev/null
[[ -L "$HOME/.config/mise/config.toml" ]]
[[ ! -e "$HOME/.config/mise/conf.d/dotfile" ]]
cmp -s "$HOME/.bashrc" "$work/bash-profile"
cmp -s "$HOME/.zshrc" "$work/zsh-original"
bash "$repo/shell/setup.sh" --repo-path "$repo" >/dev/null
[[ ! -e "$HOME/.config/mise/config.toml" && ! -L "$HOME/.config/mise/config.toml" ]]
[[ -L "$HOME/.config/mise/conf.d/dotfile" ]]
[[ "$(readlink -f "$HOME/.config/mise/conf.d/dotfile")" == "$repo" ]]
expect_status shell synced
cmp -s "$HOME/.bashrc" "$work/bash-profile"
[[ "$(grep -Fxc -- "$zsh_hook" "$HOME/.zshrc")" == 1 ]]
grep -Fxq 'export KEEP_ZSH=1' "$HOME/.zshrc"
cp "$HOME/.zshrc" "$work/zsh-profile"
bash "$repo/shell/setup.sh" --repo-path "$repo" >/dev/null
expect_status shell synced
cmp -s "$HOME/.bashrc" "$work/bash-profile"
cmp -s "$HOME/.zshrc" "$work/zsh-profile"
[[ ! -e "$HOME/.config/nvim" && ! -e "$HOME/.agents/AGENTS.md" ]]

# Losing either declared hook is drift; repairing it preserves personal settings.
cp "$work/zsh-original" "$HOME/.zshrc"
expect_status shell drifted
bash "$repo/shell/setup.sh" --repo-path "$repo" >/dev/null
expect_status shell synced
cmp -s "$HOME/.zshrc" "$work/zsh-profile"

# Profile symlinks are conflicts, not permission to change another config.
rm "$HOME/.zshrc"
cp "$work/zsh-original" "$work/linked-zsh"
ln -s "$work/linked-zsh" "$HOME/.zshrc"
expect_status shell drifted
if bash "$repo/shell/setup.sh" --repo-path "$repo" >/dev/null 2>&1; then
    printf 'Shell setup unexpectedly edited a linked profile\n' >&2
    exit 1
fi
[[ "$(readlink "$HOME/.zshrc")" == "$work/linked-zsh" ]]
cmp -s "$work/linked-zsh" "$work/zsh-original"
rm "$HOME/.zshrc"
cp "$work/zsh-profile" "$HOME/.zshrc"
expect_status shell synced


# Independent global configs, including symlinks, are never retired.
printf '[vars]\nuser_config = "preserved"\n' > "$work/personal.toml"
ln -s "$work/personal.toml" "$HOME/.config/mise/config.toml"
bash "$repo/shell/setup.sh" --repo-path "$repo" >/dev/null
[[ "$(readlink "$HOME/.config/mise/config.toml")" == "$work/personal.toml" ]]
cmp -s "$work/personal.toml" "$HOME/.config/mise/config.toml"
rm "$HOME/.config/mise/config.toml"
cp "$work/personal.toml" "$HOME/.config/mise/config.toml"
bash "$repo/shell/setup.sh" --repo-path "$repo" >/dev/null
[[ ! -L "$HOME/.config/mise/config.toml" ]]
cmp -s "$work/personal.toml" "$HOME/.config/mise/config.toml"

# A pre-existing fragment directory is a conflict, not something to back up or replace.
rm "$HOME/.config/mise/conf.d/dotfile"
mkdir "$HOME/.config/mise/conf.d/dotfile"
printf 'preserved\n' > "$HOME/.config/mise/conf.d/dotfile/user-file"
expect_status shell drifted
if bash "$repo/shell/setup.sh" --repo-path "$repo" >/dev/null 2>&1; then
    printf 'Shell setup unexpectedly replaced a conflicting mise folder\n' >&2
    exit 1
fi
[[ "$(cat "$HOME/.config/mise/conf.d/dotfile/user-file")" == preserved ]]
rm "$HOME/.config/mise/conf.d/dotfile/user-file"
rmdir "$HOME/.config/mise/conf.d/dotfile"
bash "$repo/shell/setup.sh" --repo-path "$repo" >/dev/null
expect_status shell synced


# Cancelling the menu must not apply any module.
output="$(printf 'q\n' | bash "$repo/setup-dotfile.sh" --repo-path "$repo")"
[[ ! -e "$HOME/.config/tmux/tmux.conf" ]]

# Selecting only tmux must preserve a conflicting symlink and its target.
mkdir -p "$HOME/.config/tmux"
printf 'original\n' > "$work/original"
ln -s "$work/original" "$HOME/.config/tmux/tmux.conf"
if printf '2\n' | bash "$repo/setup-dotfile.sh" --repo-path "$repo" >/dev/null 2>&1; then
    printf 'Tmux setup unexpectedly replaced a conflicting link\n' >&2
    exit 1
fi
[[ "$(readlink "$HOME/.config/tmux/tmux.conf")" == "$work/original" ]]
rm "$HOME/.config/tmux/tmux.conf"
bash "$repo/tmux/setup.sh" --repo-path "$repo" >/dev/null
expect_status tmux synced
[[ "$(cat "$work/original")" == original ]]
[[ ! -e "$HOME/.config/nvim" ]]

# Migrated adapters discover their inventory from mise, including when the same
# config is loaded through the global folder fragment created above.
expect_status agents not-synced
expect_status herdr not-synced
expect_status nvim not-synced
bash "$repo/setup-dotfile.sh" --repo-path "$repo" --module agents --dry-run >/dev/null
[[ ! -e "$HOME/.agents/AGENTS.md" ]]
mkdir -p "$HOME/.agents"
printf 'keep my instructions\n' > "$HOME/.agents/AGENTS.md"
expect_status agents drifted
if bash "$repo/agents/setup.sh" --repo-path "$repo" >/dev/null 2>&1; then
    printf 'Agent setup unexpectedly replaced a conflicting config\n' >&2
    exit 1
fi
[[ ! -L "$HOME/.agents/AGENTS.md" ]]
[[ "$(cat "$HOME/.agents/AGENTS.md")" == 'keep my instructions' ]]
rm "$HOME/.agents/AGENTS.md"
bash "$repo/agents/setup.sh" --repo-path "$repo" >/dev/null
expect_status agents synced
bash "$repo/agents/setup.sh" --repo-path "$repo" >/dev/null
expect_status agents synced
[[ ! -e "$HOME/.config/nvim" ]]
[[ ! -e "$HOME/.config/herdr/config.toml" ]]

mkdir -p "$HOME/.config/nvim"
printf 'keep my editor config\n' > "$HOME/.config/nvim/user.lua"
if bash "$repo/nvim/setup.sh" --repo-path "$repo" >/dev/null 2>&1; then
    printf 'Neovim setup unexpectedly replaced a conflicting directory\n' >&2
    exit 1
fi
[[ "$(cat "$HOME/.config/nvim/user.lua")" == 'keep my editor config' ]]
rm "$HOME/.config/nvim/user.lua"
rmdir "$HOME/.config/nvim"
bash "$repo/setup-dotfile.sh" --repo-path "$repo" --module nvim >/dev/null
expect_status nvim synced
mise -C "$repo" dot apply --yes "$HOME/.config/herdr/config.toml" >/dev/null
expect_status herdr synced

expected_links=(
    "agents/AGENTS.md|$HOME/.config/opencode/AGENTS.md"
    "agents/AGENTS.md|$HOME/.omp/agent/AGENTS.md"
    "agents/AGENTS.md|$HOME/.agents/AGENTS.md"
    "agents/AGENTS.md|$HOME/.pi/agent/AGENTS.md"
    "agents/skills|$HOME/.config/opencode/skills"
    "agents/skills|$HOME/.agents/skills"
    "agents/skills|$HOME/.pi/agent/skills"
    "agents/skills|$HOME/.claude/skills"
    "herdr/config.toml|$HOME/.config/herdr/config.toml"
    "nvim|$HOME/.config/nvim"
    "tmux/tmux.conf|$HOME/.config/tmux/tmux.conf"
    "shell|$HOME/.config/dotfile/shell"
)
for entry in "${expected_links[@]}"; do
    [[ -L "${entry#*|}" ]]
    [[ "$(readlink -f "${entry#*|}")" == "$repo/${entry%%|*}" ]]
done

# Outside the checkout, folder-relative sources must resolve to the same
# repository sources. No history tracking, credentials, or runtime trees.
mise -C "$work" dot apply --yes >/dev/null
inventory="$(mise -C "$work" dot status --json)"
jq -e '
    (.files | length) == 12 and (.edits | length) == 2 and
    all(.files[]; .mode == "symlink" and .state == "applied") and
    all(.edits[]; .state == "applied")
' <<< "$inventory" >/dev/null
sources="$(jq -r '.files[].origin.source' <<< "$inventory")"
while IFS= read -r source; do
    case "$(realpath "$source")" in
        "$repo/agents/AGENTS.md"|"$repo/agents/skills"|"$repo/herdr/config.toml"|"$repo/nvim"|"$repo/tmux/tmux.conf"|"$repo/shell") ;;
        *) printf 'Unexpected global dotfile source: %s\n' "$source" >&2; exit 1 ;;
    esac
done <<< "$sources"
for entry in "${expected_links[@]}"; do
    [[ -L "${entry#*|}" ]]
    [[ "$(readlink -f "${entry#*|}")" == "$repo/${entry%%|*}" ]]
done

printf 'Setup adapter checks passed.\n'
