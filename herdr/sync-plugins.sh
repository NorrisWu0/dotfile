#!/usr/bin/env bash

set -euo pipefail

dry_run=false
case "${1:-}" in
    --dry-run) dry_run=true; shift ;;
    -h|--help)
        printf 'Usage: bash %s [--dry-run]\n' "$0"
        exit 0
        ;;
esac
if (($#)); then
    printf 'Unknown argument: %s\n' "$1" >&2
    exit 2
fi

plugins_file="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/plugins.yaml"
for tool in yq jq; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        printf 'Herdr plugin sync requires %s; run mise install first\n' "$tool" >&2
        exit 1
    fi
done
plugins="$(yq -o=json '.plugins' "$plugins_file" | jq -ce '
    if type == "array" and all(.[]; type == "string" and length > 0)
    then . else error("plugins.yaml must contain a plugins array of source strings") end
')"

installed='[]'
if ! $dry_run; then
    if ! command -v herdr >/dev/null 2>&1; then
        printf 'Herdr plugin sync requires herdr; run mise install first\n' >&2
        exit 1
    fi
    if ! inventory="$(herdr plugin list --json)"; then
        printf 'Cannot list Herdr plugins; plugin sync stopped without installing anything\n' >&2
        exit 1
    fi
    installed="$(jq -ce '
        .result.plugins | if type != "array" then error("invalid Herdr plugin list response")
        else [.[] | .source | select(.kind == "github") |
            ([.owner, .repo, (.subdir // "")] | map(select(. != "")) | join("/")) +
            (if .requested_ref then "@" + .requested_ref else "" end)] end
    ' <<< "$inventory")"
fi

while IFS= read -r plugin; do
    source="$plugin"
    args=()
    if [[ "$plugin" == *@* ]]; then
        source="${plugin%@*}"
        args=(--ref "${plugin##*@}")
    fi
    if jq -e --arg source "$plugin" 'index($source) != null' <<< "$installed" >/dev/null; then
        printf 'Herdr plugin already installed: %s\n' "$plugin"
    elif $dry_run; then
        printf 'Would install Herdr plugin if missing: %s\n' "$plugin"
    else
        if ! herdr plugin install "$source" --yes "${args[@]}"; then
            printf 'Failed to install Herdr plugin: %s\n' "$plugin" >&2
            exit 1
        fi
        printf 'Installed Herdr plugin: %s\n' "$plugin"
        installed="$(jq -c --arg source "$plugin" '. + [$source]' <<< "$installed")"
    fi
done < <(jq -r '.[]' <<< "$plugins")
