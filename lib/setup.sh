#!/usr/bin/env bash

setup_usage() {
    cat <<EOF
Usage: $(basename "$0") --repo-path <path> [--dry-run] [--status] [--sync-status]

Options:
  --repo-path <path>  Path to the dotfile repo root
  --dry-run           Show what would be linked without making changes
  --status            Show the current state of managed symlinks
  --sync-status       Print synced, drifted, or not-synced
EOF
}

setup_parse_args() {
    REPO_PATH=""
    DRY_RUN=false
    STATUS=false
    SYNC_STATUS=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --repo-path) REPO_PATH="${2:-}"; shift 2 ;;
            --dry-run)   DRY_RUN=true; shift ;;
            --status)    STATUS=true; shift ;;
            --sync-status) SYNC_STATUS=true; shift ;;
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
            mkdir -p "$parent" || return 1
        fi
    fi

    if [[ -L "$target" ]]; then
        actual="$(readlink "$target")" || return 1
        if [[ "$actual" == "$source" ]]; then
            printf 'already linked: %s -> %s\n' "$target" "$source"
            return 0
        fi
        backup="$(setup_backup_path "$target")"
        if [[ "$dry_run" == true ]]; then
            printf 'would backup: %s -> %s\n' "$target" "$backup"
            printf 'would link: %s -> %s\n' "$target" "$source"
        else
            mv "$target" "$backup" || return 1
            ln -s "$source" "$target" || return 1
            printf 'linked: %s -> %s (backup: %s)\n' "$target" "$source" "$backup"
        fi
        return 0
    fi

    if [[ -e "$target" ]]; then
        if [[ -f "$source" && -f "$target" ]] && cmp -s "$source" "$target"; then
            if [[ "$dry_run" == true ]]; then
                printf 'would replace identical file: %s -> %s\n' "$target" "$source"
            else
                rm "$target" || return 1
                ln -s "$source" "$target" || return 1
                printf 'linked: %s -> %s (identical, no backup)\n' "$target" "$source"
            fi
            return 0
        fi

        backup="$(setup_backup_path "$target")"
        if [[ "$dry_run" == true ]]; then
            printf 'would backup: %s -> %s\n' "$target" "$backup"
            printf 'would link: %s -> %s\n' "$target" "$source"
        else
            mv "$target" "$backup" || return 1
            ln -s "$source" "$target" || return 1
            printf 'linked: %s -> %s (backup: %s)\n' "$target" "$source" "$backup"
        fi
        return 0
    fi

    if [[ "$dry_run" == true ]]; then
        printf 'would link: %s -> %s\n' "$target" "$source"
    else
        ln -s "$source" "$target" || return 1
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

# Sets SYNC_MATCHED and SYNC_CONFLICT for the declared managed links.
setup_inspect_module_links() {
    local entry rel source target actual
    SYNC_MATCHED=0
    SYNC_CONFLICT=0
    for entry in "${MODULE_LINKS[@]}"; do
        rel="${entry%%|*}"
        source="$REPO_PATH/$rel"
        target="${entry##*|}"
        if [[ ! -e "$source" ]]; then
            printf 'missing source: %s\n' "$source" >&2
            return 1
        fi
        if [[ -L "$target" ]]; then
            actual="$(readlink "$target")" || return 1
            if [[ "$actual" == "$source" ]]; then
                ((SYNC_MATCHED+=1))
            else
                SYNC_CONFLICT=1
            fi
        elif [[ -e "$target" ]]; then
            SYNC_CONFLICT=1
        fi
    done
}

setup_print_sync_status() {
    if (( SYNC_CONFLICT )); then
        printf 'drifted\n'
    elif (( SYNC_MATCHED == ${#MODULE_LINKS[@]} )); then
        printf 'synced\n'
    elif (( SYNC_MATCHED == 0 )); then
        printf 'not-synced\n'
    else
        printf 'drifted\n'
    fi
}

setup_module_links() {
    local entry rel source target
    local errors=0

    if $SYNC_STATUS; then
        setup_inspect_module_links
        setup_print_sync_status
        return
    fi

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

# Discover module files by source directory and associated edits by their
# module-prefixed IDs in the same declaring config. Mise owns the only inventory.
setup_mise_module() {
    local module="$1" tool inventory entries targets_text state
    local -a targets=() args=(dot apply --yes)

    for tool in mise jq; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            printf '%s is required for %s setup; install the pinned tools first\n' "$tool" "$module" >&2
            return 1
        fi
    done

    inventory="$(mise -C "$REPO_PATH" dot status --json)" || return 1
    entries="$(jq -ce --arg source "$REPO_PATH/$module" --arg module "$module" '
        [.files[] | select(.origin.source != null) |
            select(.origin.source == $source or (.origin.source | startswith($source + "/")))] as $files
        | ($files | map(.origin.config) | unique) as $configs
        | $files + [.edits[] |
            select(.origin.config as $config | $configs | index($config)) |
            select(.edit | split(":")[1] | startswith($module + ".")) |
            . + {target: .path, is_edit: true}]
        | if length == 0 then error("no dotfile declarations for module")
          elif any(.[]; .state == "source_missing") then error("module source missing")
          elif any(.[]; .state != "applied" and .state != "missing" and .state != "differs")
          then error("unsupported dotfile state") else . end
    ' <<< "$inventory")" || return 1
    targets_text="$(jq -r --arg home "$HOME" '
        .[].target | if startswith("~/") then $home + .[1:] else . end
    ' <<< "$entries")" || return 1
    mapfile -t targets <<< "$targets_text"

    if $SYNC_STATUS; then
        state="$(jq -r '
            if all(.[]; .state == "applied") then "synced"
            elif all(.[]; .state == "missing") then "not-synced"
            else "drifted" end
        ' <<< "$entries")" || return 1
        printf '%s\n' "$state"
    elif $STATUS; then
        mise -C "$REPO_PATH" dot status "${targets[@]}"
    else
        if $DRY_RUN; then
            args+=(--dry-run)
        elif jq -e 'any(.[]; .is_edit != true and .state == "differs")' <<< "$entries" >/dev/null; then
            printf 'Conflicting %s configuration; review and move it aside before applying\n' "$module" >&2
            return 1
        fi
        mise -C "$REPO_PATH" "${args[@]}" "${targets[@]}"
    fi
}
