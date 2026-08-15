#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/setup.sh"
setup_parse_args "$@"

MODULE_LINKS=(
    "hypr/bindings.conf|$HOME/.config/hypr/bindings.conf"
    "hypr/looknfeel.conf|$HOME/.config/hypr/looknfeel.conf"
    "hypr/hyprlock.conf|$HOME/.config/hypr/hyprlock.conf"
)

setup_module_links
