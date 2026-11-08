#!/usr/bin/env bash

set -euo pipefail

repo="$(realpath "$(dirname "$0")/..")"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
export HOME="$work/home"
mkdir -p "$HOME/.config/hypr"

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

expect_status hypr not-synced
printf 'user config\n' > "$HOME/.config/hypr/looknfeel.lua"
expect_status hypr drifted
rm "$HOME/.config/hypr/looknfeel.lua"
ln -s "$repo/hypr/looknfeel.lua" "$HOME/.config/hypr/looknfeel.lua"
expect_status hypr synced
ln -s "$repo/hypr/bindings.conf" "$HOME/.config/hypr/bindings.conf"
expect_status hypr drifted

mkdir -p "$HOME/.config/omarchy/branding"
expect_status omarchy not-synced
ln -s "$repo/omarchy/branding/about.txt" "$HOME/.config/omarchy/branding/about.txt"
expect_status omarchy drifted
ln -s "$repo/omarchy/branding/screensaver.txt" "$HOME/.config/omarchy/branding/screensaver.txt"
expect_status omarchy synced

expect_status shell not-synced
mkdir -p "$HOME/.config/dotfile"
ln -s "$repo/shell" "$HOME/.config/dotfile/shell"
expect_status shell drifted
printf '%s\n' '[[ ! -r "$HOME/.config/dotfile/shell/.bashrc" ]] || source "$HOME/.config/dotfile/shell/.bashrc"' > "$HOME/.bashrc"
expect_status shell synced

# Status icons must match the reported sync state.
output="$(bash "$repo/setup-dotfile.sh" --repo-path "$repo" --status --module hypr --module nvim --module shell)"
[[ "$output" == *'hypr: ⚠️ drifted'* ]]
[[ "$output" == *'nvim: ❌ not-synced'* ]]
[[ "$output" == *'shell: ✅ synced'* ]]

# Cancelling the menu must not apply any module.
output="$(printf 'q\n' | bash "$repo/setup-dotfile.sh" --repo-path "$repo")"
[[ "$output" == *'Setup cancelled.'* ]]
[[ ! -e "$HOME/.config/tmux/tmux.conf" ]]

# Selecting only tmux must preserve a conflicting symlink and its target.
mkdir -p "$HOME/.config/tmux"
printf 'original\n' > "$work/original"
ln -s "$work/original" "$HOME/.config/tmux/tmux.conf"
printf '4\n' | bash "$repo/setup-dotfile.sh" --repo-path "$repo" >/dev/null
[[ "$(readlink "$HOME/.config/tmux/tmux.conf")" == "$repo/tmux/tmux.conf" ]]
backups=("$HOME"/.config/tmux/tmux.conf.bak-*)
[[ ${#backups[@]} == 1 && -L "${backups[0]}" ]]
[[ "$(readlink "${backups[0]}")" == "$work/original" ]]
[[ "$(cat "$work/original")" == original ]]
[[ ! -e "$HOME/.config/nvim" ]]

printf 'Setup adapter checks passed.\n'
