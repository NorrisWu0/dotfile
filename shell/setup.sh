#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/setup.sh"
setup_parse_args "$@"
MISE_FRAGMENT="$HOME/.config/mise/conf.d/dotfile"
MISE_LEGACY_CONFIG="$HOME/.config/mise/config.toml"

legacy_mise_link() {
    [[ -L "$MISE_LEGACY_CONFIG" ]] &&
        [[ "$(realpath "$MISE_LEGACY_CONFIG" 2>/dev/null || true)" == "$REPO_PATH/mise.toml" ]]
}

inspect_mise_fragment() {
    if [[ -L "$MISE_FRAGMENT" ]] &&
        [[ "$(realpath "$MISE_FRAGMENT" 2>/dev/null || true)" == "$REPO_PATH" ]]; then
        ((SYNC_MATCHED+=1))
    elif [[ -e "$MISE_FRAGMENT" || -L "$MISE_FRAGMENT" ]]; then
        SYNC_CONFLICT=1
    fi
    if legacy_mise_link; then
        SYNC_CONFLICT=1
    fi
}

setup_mise_fragment() {
    if [[ -L "$MISE_FRAGMENT" ]] &&
        [[ "$(realpath "$MISE_FRAGMENT" 2>/dev/null || true)" == "$REPO_PATH" ]]; then
        printf 'already linked: %s -> %s\n' "$MISE_FRAGMENT" "$REPO_PATH"
    elif [[ -e "$MISE_FRAGMENT" || -L "$MISE_FRAGMENT" ]]; then
        printf 'conflicting mise folder fragment: %s; review and move it aside before setup\n' "$MISE_FRAGMENT" >&2
        return 1
    elif $DRY_RUN; then
        printf 'would link mise folder fragment: %s -> %s\n' "$MISE_FRAGMENT" "$REPO_PATH"
    else
        mkdir -p "$(dirname "$MISE_FRAGMENT")"
        ln -s "$REPO_PATH" "$MISE_FRAGMENT"
        printf 'linked mise folder fragment: %s -> %s\n' "$MISE_FRAGMENT" "$REPO_PATH"
    fi

    # Only retire our old file link, never an independent user configuration.
    if legacy_mise_link; then
        if $DRY_RUN; then
            printf 'would remove legacy mise config link: %s\n' "$MISE_LEGACY_CONFIG"
        else
            rm "$MISE_LEGACY_CONFIG"
            printf 'removed legacy mise config link: %s\n' "$MISE_LEGACY_CONFIG"
        fi
    fi
}

if $SYNC_STATUS; then
    module_state="$(setup_mise_module shell)"
    SYNC_MATCHED=0
    SYNC_CONFLICT=0
    inspect_mise_fragment
    if (( SYNC_CONFLICT )) || [[ "$module_state" == drifted ]]; then
        printf 'drifted\n'
    elif [[ "$module_state" == synced ]] && (( SYNC_MATCHED == 1 )); then
        printf 'synced\n'
    elif [[ "$module_state" == not-synced ]] && (( SYNC_MATCHED == 0 )); then
        printf 'not-synced\n'
    else
        printf 'drifted\n'
    fi
elif $STATUS; then
    setup_mise_module shell
    if [[ -L "$MISE_FRAGMENT" ]] &&
        [[ "$(realpath "$MISE_FRAGMENT" 2>/dev/null || true)" == "$REPO_PATH" ]]; then
        printf 'ok       %s -> %s\n' "$MISE_FRAGMENT" "$REPO_PATH"
    elif [[ -e "$MISE_FRAGMENT" || -L "$MISE_FRAGMENT" ]]; then
        printf 'conflict %s (mise folder fragment)\n' "$MISE_FRAGMENT"
    else
        printf 'missing  %s (mise folder fragment)\n' "$MISE_FRAGMENT"
    fi
    if legacy_mise_link; then
        printf 'legacy   %s (will remove old repository file link)\n' "$MISE_LEGACY_CONFIG"
    fi
else
    setup_mise_fragment
    setup_mise_module shell
fi
