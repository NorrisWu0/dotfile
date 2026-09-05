#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/setup.sh"
setup_parse_args "$@"

MODULE_LINKS=(
    "herdr/config.toml|$HOME/.config/herdr/config.toml"
)

setup_module_links

sync_herdr_plugins() {
    local plugins_file="$REPO_PATH/herdr/plugins.yaml"

    [[ -f "$plugins_file" ]] || return 0

    if ! command -v herdr >/dev/null 2>&1; then
        printf '  skipping plugins: herdr not found\n'
        return 0
    fi

    if ! command -v yq >/dev/null 2>&1; then
        printf '  skipping plugins: yq not found (install: https://github.com/mikefarah/yq)\n'
        return 0
    fi

    local installed
    installed="$(herdr plugin list --json 2>/dev/null | jq -r '.result.plugins // [] | .[].source | (.owner + "/" + .repo)' 2>/dev/null || true)"

    local plugin owner_repo
    while IFS= read -r plugin; do
        [[ -n "$plugin" ]] || continue
        owner_repo="$(printf '%s' "$plugin" | cut -d/ -f1-2)"
        if printf '%s\n' "$installed" | grep -Fxq "$owner_repo"; then
            printf 'plugin already installed: %s\n' "$plugin"
            continue
        fi
        if $DRY_RUN; then
            printf 'would install plugin: %s\n' "$plugin"
        else
            printf 'installing plugin: %s\n' "$plugin"
            herdr plugin install "$plugin" -y
        fi
    done < <(yq -r '.plugins[]' "$plugins_file")
}

sync_herdr_plugins
