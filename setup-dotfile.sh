#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<EOF
Usage: $(basename "$0") [--repo-path <path>] [--module <name> ... | --all] [--dry-run | --status]

Options:
  --repo-path <path>  Path to the dotfile repo root (default: script directory)
  --module <name>     Select a module (repeatable)
  --all               Select all modules
  --dry-run           Show what would be linked without making changes
  --status            Show sync status of selected modules
  -h, --help          Show this help
EOF
    exit 0
}

info() { printf "  %s\n" "$*"; }
warn() { printf "\033[33m  !\033[0m %s\n" "$*"; }
err() { printf "\033[31m  ✗\033[0m %s\n" "$*"; }
section() { printf "\n\033[1m%s\033[0m\n" "$*"; }

REPO_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
STATUS=false
ALL=false
MODULES=(hypr waybar nvim tmux herdr omarchy agents pi shell)
SELECTED=()

while [[ $# -gt 0 ]]; do
    case "$1" in
    --repo-path | --module)
        if [[ $# -lt 2 || -z "$2" || "$2" == --* ]]; then
            printf 'Missing value for %s\n' "$1" >&2
            exit 1
        fi
        if [[ "$1" == --repo-path ]]; then
            REPO_PATH="$2"
        else
            SELECTED+=("$2")
        fi
        shift 2
        ;;
    --all)
        ALL=true
        shift
        ;;
    --dry-run)
        DRY_RUN=true
        shift
        ;;
    --status)
        STATUS=true
        shift
        ;;
    -h | --help) usage ;;
    *)
        printf 'Unknown option: %s\n' "$1" >&2
        exit 1
        ;;
    esac
done


REPO_PATH="${REPO_PATH/#\~/$HOME}"
REPO_PATH="$(realpath "$REPO_PATH" 2>/dev/null || echo "$REPO_PATH")"

if [[ ! -d "$REPO_PATH" ]]; then
    printf 'Error: repo path does not exist: %s\n' "$REPO_PATH" >&2
    exit 1
fi

if $ALL && ((${#SELECTED[@]})); then
    printf '%s\n' '--all cannot be combined with --module' >&2
    exit 1
fi
if $STATUS && $DRY_RUN; then
    printf '%s\n' '--status cannot be combined with --dry-run' >&2
    exit 1
fi

for selected in "${SELECTED[@]}"; do
    found=false
    for module in "${MODULES[@]}"; do
        if [[ "$selected" == "$module" ]]; then
            found=true
            break
        fi
    done
    if ! $found; then
        printf 'Unknown module: %s\n' "$selected" >&2
        exit 1
    fi
done

# Normalize selection to module order and avoid running duplicates.
if $ALL || { ((${#SELECTED[@]} == 0)) && { $STATUS || $DRY_RUN; }; }; then
    SELECTED=("${MODULES[@]}")
elif ((${#SELECTED[@]})); then
    requested=("${SELECTED[@]}")
    SELECTED=()
    for module in "${MODULES[@]}"; do
        for selected in "${requested[@]}"; do
            if [[ "$module" == "$selected" ]]; then
                SELECTED+=("$module")
                break
            fi
        done
    done
fi

sync_status() {
    local script="$REPO_PATH/$1/setup.sh" result
    if [[ -x "$script" ]] &&
        result="$("$script" --repo-path "$REPO_PATH" --sync-status && printf '.')"; then
        case "$result" in
            $'synced\n.') printf 'synced' ; return ;;
            $'drifted\n.') printf 'drifted' ; return ;;
            $'not-synced\n.') printf 'not-synced' ; return ;;
        esac
    fi
    printf 'unknown'
}

status_label() {
    local state
    state="$(sync_status "$1")"
    case "$state" in
        synced) printf '✅ %s' "$state" ;;
        drifted) printf '⚠️ %s' "$state" ;;
        not-synced) printf '❌ %s' "$state" ;;
        *) printf '❔ %s' "$state" ;;
    esac
}

show_status() {
    local module
    for module in "$@"; do
        printf '  %s: %s\n' "$module" "$(status_label "$module")"
    done
}

select_modules_gum() {
    local module choice result
    local -a entries=()

    for module in "${MODULES[@]}"; do
        entries+=("$(printf '%-10s %s' "$module" "$(status_label "$module")")")
    done

    section "Select modules (repo: $REPO_PATH)"
    if ! result="$(gum choose --no-limit --height 9 \
        --header 'Arrows: move  x: select  Enter: confirm  Esc: cancel' \
        --cursor '> ' --cursor-prefix '[ ] ' \
        --selected-prefix '[x] ' --unselected-prefix '[ ] ' \
        "${entries[@]}")"; then
        return 1
    fi

    while IFS= read -r choice; do
        [[ -n "$choice" ]] || continue
        SELECTED+=("${choice%%[[:space:]]*}")
    done <<< "$result"
    ((${#SELECTED[@]} > 0))
}

select_modules() {
    local i reply choice valid
    local -a choices=() picked=()
    if [[ -t 0 && -t 1 && "${TERM:-dumb}" != dumb ]] && command -v gum >/dev/null 2>&1; then
        select_modules_gum
        return $?
    fi
    section "Select modules (repo: $REPO_PATH)"
    for i in "${!MODULES[@]}"; do
        printf '  %d) %s: %s\n' "$((i + 1))" "${MODULES[i]}" "$(status_label "${MODULES[i]}")"
    done
    while :; do
        printf 'Choose numbers separated by spaces or commas, all, or q: ' >&2
        if ! read -r reply; then
            return 1
        fi
        case "$reply" in
            q|Q) return 1 ;;
            all|ALL) SELECTED=("${MODULES[@]}"); return 0 ;;
        esac
        reply="${reply//,/ }"
        read -r -a choices <<< "$reply"
        valid=true
        picked=()
        ((${#choices[@]})) || valid=false
        for choice in "${choices[@]}"; do
            if [[ ! "$choice" =~ ^[1-9][0-9]*$ ]] ||
                ((${#choice} > 2)) || ((10#$choice > ${#MODULES[@]})); then
                valid=false
                break
            fi
            picked+=("${MODULES[10#$choice - 1]}")
        done
        if $valid; then
            for module in "${MODULES[@]}"; do
                for choice in "${picked[@]}"; do
                    if [[ "$module" == "$choice" ]]; then
                        SELECTED+=("$module")
                        break
                    fi
                done
            done
            return 0
        fi
        printf 'Invalid selection.\n' >&2
    done
}

run_module() {
    local module="$1"
    local script="$REPO_PATH/$module/setup.sh"
    local -a args=(--repo-path "$REPO_PATH")

    if $DRY_RUN; then
        args+=(--dry-run)
    fi

    if [[ ! -x "$script" ]]; then
        err "$module/setup.sh — missing or not executable"
        return 1
    fi

    section "$module"
    "$script" "${args[@]}"
}

install_prerequisites() {
    local spec command package reply
    local -a missing_packages=() missing_tools=()
    local missing_omnictl=false

    for spec in curl:curl jq:jq zoxide:zoxide gh:github-cli tmux:tmux \
        kubectl:kubectl talosctl:talosctl yq:go-yq; do
        command="${spec%%:*}"
        package="${spec#*:}"
        if ! command -v "$command" >/dev/null 2>&1; then
            missing_tools+=("$command")
            missing_packages+=("$package")
        fi
    done
    if ! command -v nvm >/dev/null 2>&1 &&
        [[ ! -r /usr/share/nvm/init-nvm.sh && ! -r "${NVM_DIR:-$HOME/.nvm}/nvm.sh" &&
           ! -r "${XDG_CONFIG_HOME:-$HOME/.config}/nvm/nvm.sh" ]]; then
        missing_tools+=(nvm)
        missing_packages+=(nvm)
    fi
    if ! command -v omnictl >/dev/null 2>&1 && [[ ! -x "$HOME/.local/bin/omnictl" ]]; then
        missing_tools+=(omnictl)
        missing_omnictl=true
    fi

    section "Prerequisites"
    if ((${#missing_tools[@]})); then
        info "Missing: ${missing_tools[*]}"
    else
        info "All prerequisites are available."
    fi
    if $DRY_RUN; then
        info "Would ask whether to install missing prerequisites."
        return 0
    fi

    while :; do
        printf 'Do you want to install missing prerequisites? [y/N] ' >&2
        read -r reply || reply=""
        case "$reply" in
            y|Y|yes|YES) break ;;
            n|N|no|NO|"") info "Skipping prerequisite installation."; return 0 ;;
            *) printf 'Please answer y or n.\n' >&2 ;;
        esac
    done

    if ((${#missing_packages[@]})); then
        if command -v omarchy >/dev/null 2>&1; then
            omarchy pkg add "${missing_packages[@]}" || return 1
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --needed -- "${missing_packages[@]}" || return 1
        else
            err "Installing prerequisites requires Omarchy or Arch Linux."
            return 1
        fi
    fi
    if $missing_omnictl; then
        bash "$REPO_PATH/shell/install-omnictl.sh" || return 1
    fi
}

if $STATUS; then
    section "Module sync status (repo: $REPO_PATH)"
    show_status "${SELECTED[@]}"
    exit 0
fi

if ((${#SELECTED[@]} == 0)); then
    if ! select_modules; then
        info "Setup cancelled."
        exit 0
    fi
fi

if $DRY_RUN; then
    section "Dry run — no changes will be made (repo: $REPO_PATH)"
else
    section "Setting up dotfiles (repo: $REPO_PATH)"
fi

for module in "${SELECTED[@]}"; do
    if [[ "$module" == shell ]]; then
        if ! install_prerequisites; then
            err "Prerequisite installation failed; setup stopped."
            exit 1
        fi
        break
    fi
done

errors=0
for module in "${SELECTED[@]}"; do
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
