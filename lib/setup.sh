#!/usr/bin/env bash

setup_usage() {
    cat <<EOF
Usage: $(basename "$0") --repo-path <path> [--dry-run] [--status]

Options:
  --repo-path <path>  Path to the dotfile repo root
  --dry-run           Show what would be linked without making changes
  --status            Show the current state of managed symlinks
EOF
}

setup_parse_args() {
    REPO_PATH=""
    DRY_RUN=false
    STATUS=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --repo-path) REPO_PATH="${2:-}"; shift 2 ;;
            --dry-run)   DRY_RUN=true; shift ;;
            --status)    STATUS=true; shift ;;
            -h|--help)
                setup_usage
                exit 0
                ;;
            *)
                printf 'Unknown option: %s\n' "$1" >&2
                setup_usage >&2
                return 2
                ;;
        esac
    done

    if [[ -z "$REPO_PATH" || ! -d "$REPO_PATH" ]]; then
        printf 'A valid --repo-path is required\n' >&2
        return 2
    fi

    REPO_PATH="${REPO_PATH/#\~/$HOME}"
    REPO_PATH="$(realpath "$REPO_PATH" 2>/dev/null || echo "$REPO_PATH")"
}

setup_backup_path() {
    local target="$1"
    local timestamp candidate suffix

    timestamp="$(date +%Y%m%d%H%M%S)"
    candidate="${target}.bak-${timestamp}"
    suffix=1
    while [[ -e "$candidate" || -L "$candidate" ]]; do
        candidate="${target}.bak-${timestamp}.${suffix}"
        ((suffix++))
    done
    printf '%s\n' "$candidate"
}

setup_link() {
    local source="$1"
    local target="$2"
    local dry_run="$3"
    local parent actual backup parent_real source_real

    if [[ ! -e "$source" ]]; then
        printf 'missing source: %s\n' "$source" >&2
        return 1
    fi

    parent="$(dirname "$target")"

    # Refuse self-referential links: when the target's parent is a symlink into
    # the repo (e.g. ~/.config/hypr -> <repo>/hypr), ln -sf would write through
    # it and link the source back to itself. Convert the parent to a real
    # directory instead.
    parent_real="$(realpath "$parent" 2>/dev/null || printf '%s' "$parent")"
    source_real="$(realpath "$source" 2>/dev/null || printf '%s' "$source")"
    if [[ "$parent_real/$(basename "$target")" == "$source_real" ]]; then
        printf 'refusing self-referential link: %s -> %s (parent is a symlink into the repo?)\n' "$target" "$source" >&2
        return 1
    fi

    if [[ ! -d "$parent" ]]; then
        if [[ "$dry_run" == true ]]; then
            printf 'would mkdir -p %s\n' "$parent"
        else
            mkdir -p "$parent"
        fi
    fi

    if [[ -L "$target" ]]; then
        actual="$(readlink "$target")"
        if [[ "$actual" == "$source" ]]; then
            printf 'already linked: %s -> %s\n' "$target" "$source"
            return 0
        fi
        if [[ "$dry_run" == true ]]; then
            printf 'would relink: %s -> %s\n' "$target" "$source"
        else
            ln -sf "$source" "$target"
            printf 'relinked: %s -> %s\n' "$target" "$source"
        fi
        return 0
    fi

    if [[ -e "$target" ]]; then
        if [[ -f "$source" && -f "$target" ]] && cmp -s "$source" "$target"; then
            if [[ "$dry_run" == true ]]; then
                printf 'would replace identical file: %s -> %s\n' "$target" "$source"
            else
                rm "$target"
                ln -s "$source" "$target"
                printf 'linked: %s -> %s (identical, no backup)\n' "$target" "$source"
            fi
            return 0
        fi

        backup="$(setup_backup_path "$target")"
        if [[ "$dry_run" == true ]]; then
            printf 'would backup: %s -> %s\n' "$target" "$backup"
            printf 'would link: %s -> %s\n' "$target" "$source"
        else
            mv "$target" "$backup"
            ln -s "$source" "$target"
            printf 'linked: %s -> %s (backup: %s)\n' "$target" "$source" "$backup"
        fi
        return 0
    fi

    if [[ "$dry_run" == true ]]; then
        printf 'would link: %s -> %s\n' "$target" "$source"
    else
        ln -s "$source" "$target"
        printf 'linked: %s -> %s\n' "$target" "$source"
    fi
}

setup_link_status() {
    local source="$1"
    local target="$2"
    local actual

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
}

setup_module_links() {
    local entry rel source target
    local errors=0

    for entry in "${MODULE_LINKS[@]}"; do
        rel="${entry%%|*}"
        source="$REPO_PATH/$rel"
        target="${entry##*|}"

        if $STATUS; then
            setup_link_status "$source" "$target"
        elif ! setup_link "$source" "$target" "$DRY_RUN"; then
            ((errors++)) || true
        fi
    done

    return "$errors"
}
