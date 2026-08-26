#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/setup.sh"
setup_parse_args "$@"

if [[ ! -d "$HOME/.config/omarchy" ]]; then
    printf 'skipping omarchy: %s not found on this host\n' "$HOME/.config/omarchy"
    exit 0
fi

MODULE_LINKS=(
    "omarchy/branding/about.txt|$HOME/.config/omarchy/branding/about.txt"
    "omarchy/branding/screensaver.txt|$HOME/.config/omarchy/branding/screensaver.txt"
)

setup_module_links
