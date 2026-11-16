#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/setup.sh"
setup_parse_args "$@"

setup_mise_module herdr

if ! $STATUS && ! $SYNC_STATUS; then
    if $DRY_RUN; then
        bash "$REPO_PATH/herdr/sync-plugins.sh" --dry-run
    else
        mise -C "$REPO_PATH" run herdr-plugins
    fi
fi
