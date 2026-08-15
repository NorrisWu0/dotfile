#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/setup.sh"
setup_parse_args "$@"

MODULE_LINKS=(
    "waybar/config.jsonc|$HOME/.config/waybar/config.jsonc"
    "waybar/style.css|$HOME/.config/waybar/style.css"
)

setup_module_links
