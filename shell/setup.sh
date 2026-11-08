#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/setup.sh"
setup_parse_args "$@"

shell_hook() {
    case "$1" in
        bash) printf '%s\n' '[[ ! -r "$HOME/.config/dotfile/shell/.bashrc" ]] || source "$HOME/.config/dotfile/shell/.bashrc"' ;;
        zsh) printf '%s\n' '[[ ! -r "$HOME/.config/dotfile/shell/.zshrc" ]] || source "$HOME/.config/dotfile/shell/.zshrc"' ;;
        *) printf 'Unsupported shell: %s\n' "$1" >&2; return 1 ;;
    esac
}

if $SYNC_STATUS; then
    MODULE_LINKS=("shell|$HOME/.config/dotfile/shell")
    setup_inspect_module_links
    hooks=0
    for selected_shell in bash zsh; do
        profile="$HOME/.${selected_shell}rc"
        if [[ -f "$profile" ]] && grep -Fxq -- "$(shell_hook "$selected_shell")" "$profile"; then
            ((hooks+=1))
        elif [[ -L "$profile" ]]; then
            resolved="$(realpath "$profile" 2>/dev/null || true)"
            if [[ -z "$resolved" || "$resolved" == "$REPO_PATH/shell/.${selected_shell}rc" ]]; then
                SYNC_CONFLICT=1
            fi
        fi
    done
    if (( SYNC_CONFLICT )); then
        printf 'drifted\n'
    elif (( SYNC_MATCHED && hooks )); then
        printf 'synced\n'
    elif (( SYNC_MATCHED || hooks )); then
        printf 'drifted\n'
    else
        printf 'not-synced\n'
    fi
    exit 0
fi

if $STATUS; then
    setup_link_status "$REPO_PATH/shell" "$HOME/.config/dotfile/shell"
    for selected_shell in bash zsh; do
        profile="$HOME/.${selected_shell}rc"
        if [[ -f "$profile" ]] && grep -Fxq -- "$(shell_hook "$selected_shell")" "$profile"; then
            printf 'ok       %s (personal settings enabled)\n' "$profile"
        else
            printf 'missing  %s (personal settings hook)\n' "$profile"
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

    printf 'Which shells should load personal settings? [bash,zsh] (default: %s): ' "$detected_shell" >&2
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

setup_shell() {
    local selected_shell="$1"
    local profile="$HOME/.${selected_shell}rc"
    local source="$REPO_PATH/shell/.${selected_shell}rc"
    local hook resolved backup candidate previous=""

    hook="$(shell_hook "$selected_shell")"
    if [[ -f "$profile" ]] && grep -Fxq -- "$hook" "$profile"; then
        printf 'already enabled: %s\n' "$profile"
        return 0
    fi

    if [[ -L "$profile" ]]; then
        resolved="$(realpath "$profile" 2>/dev/null || true)"
        if [[ "$resolved" == "$(realpath "$source")" ]]; then
            for candidate in "$profile".bak-*; do
                [[ -f "$candidate" && ! -L "$candidate" ]] && previous="$candidate"
            done
            if $DRY_RUN; then
                printf 'would replace legacy profile link and restore existing defaults: %s\n' "$profile"
            else
                backup="$(setup_backup_path "$profile")"
                mv "$profile" "$backup"
                if [[ -n "$previous" ]]; then
                    cp -p "$previous" "$profile"
                elif [[ "$selected_shell" == bash && -r /usr/share/omarchy/etc-overrides/dot.bashrc ]]; then
                    cp /usr/share/omarchy/etc-overrides/dot.bashrc "$profile"
                else
                    : > "$profile"
                fi
                printf 'replaced legacy profile link: %s (backup: %s)\n' "$profile" "$backup"
            fi
        elif [[ ! -f "$profile" ]]; then
            printf 'cannot update broken profile link: %s\n' "$profile" >&2
            return 1
        else
            if $DRY_RUN; then
                backup="$(setup_backup_path "$profile")"
                printf 'would backup profile link: %s -> %s\n' "$profile" "$backup"
                printf 'would copy linked profile to user config: %s\n' "$profile"
            else
                backup="$(setup_backup_path "$profile")"
                mv "$profile" "$backup"
                cp -pL "$backup" "$profile"
                printf 'copied linked profile: %s (backup: %s)\n' "$profile" "$backup"
            fi
        fi
    fi

    # A restored legacy backup may already contain the hook.
    if ! $DRY_RUN && [[ -f "$profile" ]] && grep -Fxq -- "$hook" "$profile"; then
        printf 'already enabled: %s\n' "$profile"
        return 0
    fi

    if $DRY_RUN; then
        printf 'would add personal settings hook: %s\n' "$profile"
    else
        if [[ -f "$profile" ]]; then
            backup="$(setup_backup_path "$profile")"
            cp -p "$profile" "$backup"
            printf 'backed up profile: %s -> %s\n' "$profile" "$backup"
        fi
        printf '\n%s\n' "$hook" >> "$profile"
        printf 'enabled personal settings: %s\n' "$profile"
    fi
}

for selected_shell in "${selected_shells[@]}"; do
    shell_hook "$selected_shell" >/dev/null
done

setup_link "$REPO_PATH/shell" "$HOME/.config/dotfile/shell" "$DRY_RUN"
for selected_shell in "${selected_shells[@]}"; do
    setup_shell "$selected_shell"
done
