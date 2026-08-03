#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<EOF
Usage: $(basename "$0") [--dry-run] [--list]

Options:
  --dry-run  Show both shell links without making changes
  --list     Show the current state of both shell profile links
  -h, --help Show this help
EOF
    exit 0
}

DRY_RUN=false
LIST=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --list) LIST=true; shift ;;
        -h|--help) usage ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; usage ;;
    esac
done

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if $LIST; then
    for selected_shell in bash zsh; do
        case "$selected_shell" in
            bash) source="$SCRIPT_DIR/.bashrc"; target="$HOME/.bashrc" ;;
            zsh) source="$SCRIPT_DIR/.zshrc"; target="$HOME/.zshrc" ;;
        esac

        if [[ -L "$target" ]]; then
            actual="$(readlink "$target")"
            if [[ "$actual" == "$source" ]]; then
                printf 'ok       %s -> %s\n' "$target" "$source"
            else
                printf 'mismatch %s -> %s (expected %s)\n' "$target" "$actual" "$source"
            fi
        elif [[ -e "$target" ]]; then
            printf 'file     %s (not a symlink)\n' "$target"
        else
            printf 'missing  %s\n' "$target"
        fi
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
            source="$SCRIPT_DIR/.bashrc"
            target="$HOME/.bashrc"
            ;;
        zsh)
            source="$SCRIPT_DIR/.zshrc"
            target="$HOME/.zshrc"
            ;;
        *)
            printf 'Unsupported shell: %s\n' "$selected_shell" >&2
            return 1
            ;;
    esac

    if [[ ! -f "$source" ]]; then
        printf 'Error: shell configuration does not exist: %s\n' "$source" >&2
        return 1
    fi

    if $DRY_RUN; then
        printf 'Would link %s -> %s\n' "$target" "$source"
        return 0
    fi

    if [[ -L "$target" ]]; then
        actual="$(readlink "$target")"
        if [[ "$actual" == "$source" ]]; then
            printf '%s is already linked to %s\n' "$target" "$source"
            return 0
        fi
        ln -sf "$source" "$target"
        printf 'Relinked %s -> %s\n' "$target" "$source"
    elif [[ -e "$target" ]]; then
        backup="${target}.orig"
        mv "$target" "$backup"
        ln -s "$source" "$target"
        printf 'Linked %s -> %s (backed up existing file to %s)\n' \
            "$target" "$source" "$backup"
    else
        ln -s "$source" "$target"
        printf 'Linked %s -> %s\n' "$target" "$source"
    fi
}

for selected_shell in "${selected_shells[@]}"; do
    link_shell "$selected_shell"
done
