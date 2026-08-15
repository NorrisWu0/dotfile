#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/setup.sh"
setup_parse_args "$@"

if $STATUS; then
    for selected_shell in bash zsh; do
        case "$selected_shell" in
            bash) source="$REPO_PATH/shell/.bashrc"; target="$HOME/.bashrc" ;;
            zsh) source="$REPO_PATH/shell/.zshrc"; target="$HOME/.zshrc" ;;
        esac
        setup_link_status "$source" "$target"
    done
    exit 0
fi

prompt_shells() {
    local detected_shell="$(basename "${SHELL:-bash}")"
    case "$detected_shell" in
        bash|zsh) ;;
        *) detected_shell="bash" ;;
    esac

    printf 'Which shells should be linked? [bash,zsh] (default: %s): ' "$detected_shell" >&2
    read -r selection || selection=""
    selection="${selection:-$detected_shell}"
    read -ra selected_shells <<< "${selection//,/ }"
    printf '%s\n' "${selected_shells[@]}"
}

if $DRY_RUN; then
    selected_shells=(bash zsh)
elif command -v fzf >/dev/null 2>&1 && [[ -t 0 && -t 1 ]]; then
    mapfile -t selected_shells < <(
        printf '%s\n' bash zsh | fzf \
            --height=~8 \
            --layout=reverse \
            --border \
            --prompt='Shells > ' \
            --header='Use arrows or mouse; Tab toggles multiple shells' \
            --multi
    )
else
    mapfile -t selected_shells < <(prompt_shells)
fi

if ((${#selected_shells[@]} == 0)); then
    printf 'No shell profiles selected; nothing changed.\n'
    exit 0
fi

link_shell() {
    local selected_shell="$1"
    local source target actual backup

    case "$selected_shell" in
        bash)
        source="$REPO_PATH/shell/.bashrc"
        target="$HOME/.bashrc"
        ;;
    zsh)
        source="$REPO_PATH/shell/.zshrc"
        target="$HOME/.zshrc"
            ;;
        *)
            printf 'Unsupported shell: %s\n' "$selected_shell" >&2
            return 1
            ;;
    esac

    setup_link "$source" "$target" "$DRY_RUN"
}

for selected_shell in "${selected_shells[@]}"; do
    link_shell "$selected_shell"
done
