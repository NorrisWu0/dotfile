#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/setup.sh"
setup_parse_args "$@"

MODULE_LINKS=(
    "pi/settings.json|$HOME/.pi/agent/settings.json"
    "pi/agents|$HOME/.pi/agent/agents"
    "pi/extensions|$HOME/.pi/agent/extensions"
)

setup_module_links
