#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/setup.sh"
setup_parse_args "$@"

if [[ ! -d "$HOME/.config/waybar" ]]; then
    printf 'skipping waybar: %s not found on this host\n' "$HOME/.config/waybar"
    exit 0
fi

MODULE_LINKS=(
    "waybar/config.jsonc|$HOME/.config/waybar/config.jsonc"
    "waybar/style.css|$HOME/.config/waybar/style.css"
)

setup_module_links
