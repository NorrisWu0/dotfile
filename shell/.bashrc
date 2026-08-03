# Keep the Bash entrypoint small; modules live beside this file.
PATH="${HOME:-~}/.local/bin:${KREW_ROOT:-${HOME}/.krew}/bin:$PATH"

# If not running interactively, don't load interactive shell configuration.
[[ $- != *i* ]] && return

SHELL_CONFIG_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SHELL_CONFIG_DIR="$(dirname "$SHELL_CONFIG_PATH")"

for config in "$SHELL_CONFIG_DIR"/*.conf; do
    [[ -f "$config" ]] || continue
    source "$config"
done

PS1='[\u@\h \W]\$ '
