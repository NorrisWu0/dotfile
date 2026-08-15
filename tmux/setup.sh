#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/setup.sh"
setup_parse_args "$@"

MODULE_LINKS=(
    "tmux/tmux.conf|$HOME/.config/tmux/tmux.conf"
)

setup_module_links
