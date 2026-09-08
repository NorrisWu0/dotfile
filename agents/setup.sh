#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/setup.sh"
setup_parse_args "$@"

MODULE_LINKS=(
    "agents/AGENTS.md|$HOME/.config/opencode/AGENTS.md"
    "agents/skills|$HOME/.config/opencode/skills"
    "agents/AGENTS.md|$HOME/.agents/AGENTS.md"
    "agents/skills|$HOME/.agents/skills"
    "agents/AGENTS.md|$HOME/.pi/agent/AGENTS.md"
    "agents/skills|$HOME/.pi/agent/skills"
)

setup_module_links
