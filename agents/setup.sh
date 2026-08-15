#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/setup.sh"
setup_parse_args "$@"

MODULE_LINKS=(
    "agents/AGENTS.md|$HOME/.config/opencode/AGENTS.md"
    "agents/skills|$HOME/.agent/skills"
    "agents/skills|$HOME/.config/opencode/skills"
)

setup_module_links
