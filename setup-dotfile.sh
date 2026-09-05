#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<EOF
Usage: $(basename "$0") --repo-path <path> [--dry-run] [--status]

Options:
  --repo-path <path>  Path to the dotfile repo root
  --dry-run           Show what would be linked without making changes
  --status            Show current state of all managed symlinks
  -h, --help          Show this help
EOF
    exit 0
}

info()    { printf "  %s\n" "$*"; }
warn()    { printf "\033[33m  !\033[0m %s\n" "$*"; }
err()     { printf "\033[31m  ✗\033[0m %s\n" "$*"; }
section() { printf "\n\033[1m%s\033[0m\n" "$*"; }

REPO_PATH=""
DRY_RUN=false
STATUS=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-path) REPO_PATH="${2:-}"; shift 2 ;;
        --dry-run)   DRY_RUN=true; shift ;;
        --status)    STATUS=true; shift ;;
        -h|--help)   usage ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; usage ;;
    esac
done

if [[ -z "$REPO_PATH" ]]; then
    printf 'No --repo-path provided. Use current directory (%s)? [y/n] ' "$(pwd)" >&2
    read -r reply || reply="n"
    if [[ "$reply" == "y" || "$reply" == "Y" ]]; then
        REPO_PATH="$(pwd)"
    else
        printf 'Aborted.\n' >&2
        exit 1
    fi
fi

REPO_PATH="${REPO_PATH/#\~/$HOME}"
REPO_PATH="$(realpath "$REPO_PATH" 2>/dev/null || echo "$REPO_PATH")"

if [[ ! -d "$REPO_PATH" ]]; then
    printf 'Error: repo path does not exist: %s\n' "$REPO_PATH" >&2
    exit 1
fi

MODULES=(hypr waybar nvim tmux herdr omarchy agents shell)

run_module() {
    local module="$1"
    local script="$REPO_PATH/$module/setup.sh"
    local -a args=(--repo-path "$REPO_PATH")

    if $DRY_RUN; then
        args+=(--dry-run)
    fi
    if $STATUS; then
        args+=(--status)
    fi

    if [[ ! -x "$script" ]]; then
        err "$module/setup.sh — missing or not executable"
        return 1
    fi

    section "$module"
    "$script" "${args[@]}"
}

if $STATUS; then
    section "Managed symlinks (repo: $REPO_PATH)"
    for module in "${MODULES[@]}"; do
        run_module "$module" || true
    done
    exit 0
fi

if $DRY_RUN; then
    section "Dry run — no changes will be made (repo: $REPO_PATH)"
else
    section "Setting up dotfiles (repo: $REPO_PATH)"
fi

errors=0
for module in "${MODULES[@]}"; do
    if ! run_module "$module"; then
        ((errors++)) || true
    fi
done

echo ""
if ((errors > 0)); then
    warn "$errors module(s) failed — review errors above"
    exit 1
fi

if $DRY_RUN; then
    info 'Dry run complete. Run without --dry-run to apply.'
else
    info 'All done.'
fi
