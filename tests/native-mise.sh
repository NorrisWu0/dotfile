#!/usr/bin/env bash

set -euo pipefail

repo="$(realpath "$(dirname "$0")/..")"
mise="$(command -v mise)"
ssh="$(command -v ssh)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# Never discover the caller's global, system, or ancestor project configuration.
unset MISE_GLOBAL_CONFIG_FILE MISE_GLOBAL_CONFIG_ROOT MISE_ENV MISE_CONFIG_FILE
export MISE_SYSTEM_CONFIG_FILE="$work/system.toml"
export MISE_TRUSTED_CONFIG_PATHS="$repo"
export MISE_CEILING_PATHS="$(dirname "$repo"):$work"
export MISE_AUTO_INSTALL_DISABLE=1

new_home() {
    local name="$1"
    export HOME="$work/$name/home"
    export XDG_CONFIG_HOME="$HOME/.config"
    export XDG_CACHE_HOME="$work/$name/cache"
    export XDG_DATA_HOME="$work/$name/data"
    export XDG_STATE_HOME="$work/$name/state"
    export MISE_CONFIG_DIR="$XDG_CONFIG_HOME/mise"
    export MISE_CACHE_DIR="$XDG_CACHE_HOME/mise"
    export MISE_DATA_DIR="$XDG_DATA_HOME/mise"
    export MISE_STATE_DIR="$XDG_STATE_HOME/mise"
    mkdir -p "$HOME" "$MISE_CONFIG_DIR"
}

expect_conflict() {
    local target="$1"
    if "$mise" -C "$repo" dot apply --yes "$target" >"$work/conflict.log" 2>&1; then
        printf 'Unexpectedly accepted conflicting target: %s\n' "$target" >&2
        cat "$work/conflict.log" >&2
        exit 1
    fi
}

bash_hook='[[ ! -r "$HOME/.config/dotfile/shell/.bashrc" ]] || source "$HOME/.config/dotfile/shell/.bashrc"'
zsh_hook='[[ ! -r "$HOME/.config/dotfile/shell/.zshrc" ]] || source "$HOME/.config/dotfile/shell/.zshrc"'

new_home common
printf '%s\n' '# personal Bash settings' 'export KEEP_BASH=1' "$bash_hook" >"$HOME/.bashrc"
printf '%s\n' '# personal Zsh settings' 'export KEEP_ZSH=1' >"$HOME/.zshrc"
cp "$HOME/.bashrc" "$work/bash-original"
cp "$HOME/.zshrc" "$work/zsh-original"
cp "$HOME/.zshrc" "$work/zsh-expected"
printf '%s\n' "$zsh_hook" >>"$work/zsh-expected"
mkdir -p "$HOME/.ssh"
printf '%s\n' '# personal SSH settings' 'Host other' '    HostName other.example.invalid' \
    '    IdentityAgent /personal-agent' 'Host *' '    IdentityAgent /fallback-agent' >"$HOME/.ssh/config"
cp "$HOME/.ssh/config" "$work/ssh-original"
printf '%s\n' 'Include ~/.ssh/config.d/devbox.conf' >"$work/ssh-expected"
cat "$work/ssh-original" >>"$work/ssh-expected"
printf '[vars]\nuser_config = "preserved"\n' >"$MISE_CONFIG_DIR/config.toml"
cp "$MISE_CONFIG_DIR/config.toml" "$work/global-original"

# Dry-run must not register itself, deploy anything, or change existing profiles.
"$mise" -C "$repo" dot apply --dry-run >"$work/dry-run.log"
[[ ! -e "$MISE_CONFIG_DIR/conf.d/dotfile" && ! -L "$MISE_CONFIG_DIR/conf.d/dotfile" ]]
[[ ! -e "$HOME/.config/nvim" && ! -e "$HOME/.pi/agent/settings.json" ]]
cmp -s "$HOME/.bashrc" "$work/bash-original"
cmp -s "$HOME/.zshrc" "$work/zsh-original"
cmp -s "$MISE_CONFIG_DIR/config.toml" "$work/global-original"
cmp -s "$HOME/.ssh/config" "$work/ssh-original"
[[ ! -e "$HOME/.ssh/config.d/devbox.conf" && ! -L "$HOME/.ssh/config.d/devbox.conf" ]]

# One real native apply deploys its own configuration and every common contract.
"$mise" -C "$repo" dot apply --yes
links=(
    '.config/mise/conf.d/dotfile|.'
    '.config/opencode/AGENTS.md|agents/AGENTS.md'
    '.omp/agent/AGENTS.md|agents/AGENTS.md'
    '.agents/AGENTS.md|agents/AGENTS.md'
    '.pi/agent/AGENTS.md|agents/AGENTS.md'
    '.config/opencode/skills|agents/skills'
    '.agents/skills|agents/skills'
    '.pi/agent/skills|agents/skills'
    '.claude/skills|agents/skills'
    '.omp/agent/skills|agents/skills'
    '.pi/agent/settings.json|pi/settings.json'
    '.pi/agent/agents|pi/agents'
    '.pi/agent/extensions|pi/extensions'
    '.config/herdr/config.toml|herdr/config.toml'
    '.config/nvim|nvim'
    '.config/tmux/tmux.conf|tmux/tmux.conf'
    '.config/dotfile/shell|shell'
    '.ssh/config.d/devbox.conf|shell/ssh/devbox.conf'
)
for entry in "${links[@]}"; do
    target="$HOME/${entry%%|*}"
    source="$repo/${entry#*|}"
    [[ -L "$target" && "$(realpath "$target")" == "$(realpath "$source")" ]]
done
cmp -s "$HOME/.bashrc" "$work/bash-original"
cmp -s "$HOME/.zshrc" "$work/zsh-expected"
cmp -s "$MISE_CONFIG_DIR/config.toml" "$work/global-original"
cmp -s "$HOME/.ssh/config" "$work/ssh-expected"
[[ ! -e "$HOME/.config/hypr" && ! -e "$HOME/.config/waybar" ]]

# Outside the checkout, only the registered folder fragment supplies this inventory.
inventory="$("$mise" -C "$work" dot status --json)"
jq -e '
    (.files | length) == 18 and (.edits | length) == 3 and
    all(.files[]; .mode == "symlink" and .state == "applied") and
    all(.edits[]; .state == "applied")
' <<<"$inventory" >/dev/null
"$mise" -C "$work" dot status --missing
"$mise" -C "$work" dot apply --yes
cmp -s "$HOME/.bashrc" "$work/bash-original"
cmp -s "$HOME/.zshrc" "$work/zsh-expected"
cmp -s "$MISE_CONFIG_DIR/config.toml" "$work/global-original"
cmp -s "$HOME/.ssh/config" "$work/ssh-expected"
for entry in "${links[@]}"; do
    [[ "$(realpath "$HOME/${entry%%|*}")" == "$(realpath "$repo/${entry#*|}")" ]]
done

# Evaluate real OpenSSH configuration without connecting or starting an agent.
ssh_config="$("$ssh" -G -F "$HOME/.ssh/config" devbox)"
grep -Fxq 'hostname devbox.hoki-sole.ts.net' <<<"$ssh_config"
grep -Fxq 'user norris' <<<"$ssh_config"
agent="$(grep '^identityagent ' <<<"$ssh_config")"
[[ "${agent##*/}" == '.bitwarden-ssh-agent.sock' ]]
ssh_config="$("$ssh" -G -F "$HOME/.ssh/config" other)"
grep -Fxq 'hostname other.example.invalid' <<<"$ssh_config"
grep -Fxq 'identityagent /personal-agent' <<<"$ssh_config"
ssh_config="$("$ssh" -G -F "$HOME/.ssh/config" unrelated)"
grep -Fxq 'identityagent /fallback-agent' <<<"$ssh_config"

# Replacing the independent global file by a personal link must also preserve it.
rm "$MISE_CONFIG_DIR/config.toml"
ln -s "$work/global-original" "$MISE_CONFIG_DIR/config.toml"
"$mise" -C "$work" dot apply --yes
[[ "$(readlink "$MISE_CONFIG_DIR/config.toml")" == "$work/global-original" ]]
cmp -s "$MISE_CONFIG_DIR/config.toml" "$work/global-original"

# Missing hooks are repaired additively rather than replacing either profile.
cp "$work/zsh-original" "$HOME/.zshrc"
if "$mise" -C "$work" dot status --missing "$HOME/.zshrc"; then
    printf 'Missing shell hook unexpectedly reported applied\n' >&2
    exit 1
fi
"$mise" -C "$work" dot apply --yes "$HOME/.zshrc"
cmp -s "$HOME/.zshrc" "$work/zsh-expected"
cmp -s "$HOME/.bashrc" "$work/bash-original"

# Regular-file and directory conflicts preserve the destination and user data.
new_home conflicts
mkdir -p "$HOME/.agents" "$HOME/.config/nvim" "$HOME/.config/tmux"
printf 'personal instructions\n' >"$HOME/.agents/AGENTS.md"
cp "$HOME/.agents/AGENTS.md" "$work/agent-original"
expect_conflict "$HOME/.agents/AGENTS.md"
[[ ! -L "$HOME/.agents/AGENTS.md" ]]
cmp -s "$HOME/.agents/AGENTS.md" "$work/agent-original"
printf 'personal editor configuration\n' >"$HOME/.config/nvim/user.lua"
cp "$HOME/.config/nvim/user.lua" "$work/nvim-original"
expect_conflict "$HOME/.config/nvim"
[[ ! -L "$HOME/.config/nvim" ]]
cmp -s "$HOME/.config/nvim/user.lua" "$work/nvim-original"
printf 'personal tmux configuration\n' >"$work/tmux-original"
ln -s "$work/tmux-original" "$HOME/.config/tmux/tmux.conf"
# Native mise may retarget the link, but must not modify its former target.
"$mise" -C "$repo" dot apply --yes "$HOME/.config/tmux/tmux.conf"
printf 'personal tmux configuration\n' >"$work/tmux-expected"
cmp -s "$work/tmux-original" "$work/tmux-expected"

# Editing either linked profile must not follow it into someone else's file.
for shell in bash zsh; do
    cp "$work/$shell-original" "$work/linked-$shell"
    ln -s "$work/linked-$shell" "$HOME/.${shell}rc"
    expect_conflict "$HOME/.${shell}rc"
    [[ "$(readlink "$HOME/.${shell}rc")" == "$work/linked-$shell" ]]
    cmp -s "$work/linked-$shell" "$work/$shell-original"
done

# SSH line edits also refuse to follow a linked personal configuration.
mkdir -p "$HOME/.ssh"
cp "$work/ssh-original" "$work/linked-ssh"
ln -s "$work/linked-ssh" "$HOME/.ssh/config"
expect_conflict "$HOME/.ssh/config"
[[ "$(readlink "$HOME/.ssh/config")" == "$work/linked-ssh" ]]
cmp -s "$work/linked-ssh" "$work/ssh-original"

# Self-registration has the same no-overwrite behavior as every other link.
mkdir -p "$MISE_CONFIG_DIR/conf.d/dotfile"
printf 'keep this directory\n' >"$MISE_CONFIG_DIR/conf.d/dotfile/user-file"
cp "$MISE_CONFIG_DIR/conf.d/dotfile/user-file" "$work/fragment-original"
expect_conflict "$MISE_CONFIG_DIR/conf.d/dotfile"
[[ ! -L "$MISE_CONFIG_DIR/conf.d/dotfile" ]]
cmp -s "$MISE_CONFIG_DIR/conf.d/dotfile/user-file" "$work/fragment-original"

printf 'Native mise deployment checks passed.\n'
