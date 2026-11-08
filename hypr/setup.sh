#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/setup.sh"
setup_parse_args "$@"

if [[ ! -d "$HOME/.config/hypr" ]]; then
    if $SYNC_STATUS; then
        printf 'not-synced\n'
        exit 0
    fi
    printf 'skipping hypr: %s not found on this host\n' "$HOME/.config/hypr"
    exit 0
fi

MODULE_LINKS=(
    "hypr/looknfeel.lua|$HOME/.config/hypr/looknfeel.lua"
)

if $SYNC_STATUS; then
    setup_inspect_module_links
    for name in bindings.conf looknfeel.conf hyprlock.conf; do
        target="$HOME/.config/hypr/$name"
        if [[ -L "$target" && "$(realpath -m "$target")" == "$REPO_PATH/hypr/$name" ]]; then
            SYNC_CONFLICT=1
        fi
    done
    setup_print_sync_status
    exit 0
fi

for name in bindings.conf looknfeel.conf hyprlock.conf; do
    target="$HOME/.config/hypr/$name"
    if [[ -L "$target" && "$(realpath -m "$target")" == "$REPO_PATH/hypr/$name" ]]; then
        if $STATUS; then
            printf 'obsolete %s -> %s\n' "$target" "$(readlink "$target")"
        elif $DRY_RUN; then
            printf 'would remove obsolete link: %s\n' "$target"
        else
            rm "$target"
            printf 'removed obsolete link: %s\n' "$target"
        fi
    fi
done

setup_module_links
