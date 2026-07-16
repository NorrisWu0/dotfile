#!/usr/bin/env bash

set -euo pipefail

# --- helpers ---

usage() {
    cat <<EOF
Usage: $(basename "$0") --repo-path <path> [--dry-run] [--list]

Options:
  --repo-path <path>  Path to the dotfile repo root
  --dry-run           Show what would be linked without making changes
  --list              Show current state of all managed symlinks
  -h, --help          Show this help
EOF
    exit 0
}

info()    { printf "  %s\n" "$*"; }
ok()      { printf "\033[32m  ✓\033[0m %s\n" "$*"; }
warn()    { printf "\033[33m  !\033[0m %s\n" "$*"; }
err()     { printf "\033[31m  ✗\033[0m %s\n" "$*"; }
dry()     { printf "\033[36m  ~\033[0m %s\n" "$*"; }
section() { printf "\n\033[1m%s\033[0m\n" "$*"; }

# --- parse args ---

REPO_PATH=""
DRY_RUN=false
LIST=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-path) REPO_PATH="${2:-}"; shift 2 ;;
        --dry-run)   DRY_RUN=true; shift ;;
        --list)      LIST=true; shift ;;
        -h|--help)   usage ;;
        *) printf "Unknown option: %s\n" "$1" >&2; usage ;;
    esac
done

if [[ -z "$REPO_PATH" ]]; then
    printf "No --repo-path provided. Use current directory (%s)? [y/n] " "$(pwd)" >&2
    read -r reply
    if [[ "$reply" == "y" || "$reply" == "Y" ]]; then
        REPO_PATH="$(pwd)"
    else
        printf "Aborted.\n" >&2
        exit 1
    fi
fi

# Expand ~ and resolve to absolute path
REPO_PATH="${REPO_PATH/#\~/$HOME}"
REPO_PATH="$(realpath "$REPO_PATH" 2>/dev/null || echo "$REPO_PATH")"

if [[ ! -d "$REPO_PATH" ]]; then
    printf "Error: repo path does not exist: %s\n" "$REPO_PATH" >&2
    exit 1
fi

# --- symlink definitions: "source_relative_to_repo|target" ---

declare -a LINKS=(
    "hypr|$HOME/.config/hypr"
    "waybar|$HOME/.config/waybar"
    "nvim|$HOME/.config/nvim"
    "omarchy/branding|$HOME/.config/omarchy/branding"
    "agent/AGENTS.md|$HOME/.claude/CLAUDE.md"
    "agent/AGENTS.md|$HOME/.config/opencode/AGENTS.md"
    "agent/skills|$HOME/.agent/skills"
    "agent/skills|$HOME/.claude/skills"
    "agent/skills|$HOME/.config/opencode/skills"
    "claude/settings.json|$HOME/.claude/settings.json"
    "claude/statusline.sh|$HOME/.claude/statusline.sh"
    "claude/plugins/known_marketplaces.json|$HOME/.claude/plugins/known_marketplaces.json"
)

# --- list mode ---

if $LIST; then
    section "Managed symlinks (repo: $REPO_PATH)"
    for entry in "${LINKS[@]}"; do
        src="$REPO_PATH/${entry%%|*}"
        target="${entry##*|}"

        if [[ -L "$target" ]]; then
            actual="$(readlink "$target")"
            if [[ "$actual" == "$src" ]]; then
                ok "$target → $actual"
            else
                warn "$target → $actual  (expected: $src)"
            fi
        elif [[ -e "$target" ]]; then
            err "$target  (exists but is not a symlink)"
        else
            err "$target  (missing)"
        fi
    done
    exit 0
fi

# --- setup mode ---

if $DRY_RUN; then
    section "Dry run — no changes will be made (repo: $REPO_PATH)"
else
    section "Setting up dotfile symlinks (repo: $REPO_PATH)"
fi

errors=0

for entry in "${LINKS[@]}"; do
    rel="${entry%%|*}"
    src="$REPO_PATH/$rel"
    target="${entry##*|}"
    parent="$(dirname "$target")"

    # Validate source exists in repo
    if [[ ! -e "$src" ]]; then
        err "$rel — source not found in repo, skipping"
        (( errors++ )) || true
        continue
    fi

    # Create parent directory if needed
    if [[ ! -d "$parent" ]]; then
        if $DRY_RUN; then
            dry "mkdir -p $parent"
        else
            mkdir -p "$parent"
        fi
    fi

    # Handle existing target
    if [[ -L "$target" ]]; then
        actual="$(readlink "$target")"
        if [[ "$actual" == "$src" ]]; then
            ok "$target  (already linked)"
            continue
        else
            if $DRY_RUN; then
                dry "ln -sf $src $target  (relink from $actual)"
            else
                ln -sf "$src" "$target"
                ok "$target → $src  (relinked from $actual)"
            fi
            continue
        fi
    elif [[ -e "$target" ]]; then
        backup="${target}.orig"
        if $DRY_RUN; then
            dry "mv $target $backup"
            dry "ln -s $src $target  (backed up existing)"
        else
            mv "$target" "$backup"
            ln -s "$src" "$target"
            ok "$target → $src  (backed up existing to $(basename "$backup"))"
        fi
        continue
    fi

    # Create symlink
    if $DRY_RUN; then
        dry "ln -s $src $target"
    else
        ln -s "$src" "$target"
        ok "$target → $src"
    fi
done

echo ""
if (( errors > 0 )); then
    warn "$errors item(s) skipped — review warnings above"
else
    if $DRY_RUN; then
        info "Dry run complete. Run without --dry-run to apply."
    else
        info "All done."
    fi
fi

# --- listener health check ---

if ! $DRY_RUN && ! $LIST; then
    section "Checking background listeners"
    listener="$REPO_PATH/waybar/indicators/scratchpad-listener.sh"
    if pgrep -f "scratchpad-listener.sh" &>/dev/null; then
        ok "scratchpad-listener is running"
    else
        warn "scratchpad-listener is not running — starting it now"
        nohup bash "$listener" &>/dev/null &
        sleep 0.5
        if pgrep -f "scratchpad-listener.sh" &>/dev/null; then
            ok "scratchpad-listener started"
        else
            err "scratchpad-listener failed to start — check $listener"
        fi
    fi
fi
