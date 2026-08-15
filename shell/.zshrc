# Keep the Zsh entrypoint small; modules live beside this file.
path=("${HOME}/.local/bin" "${KREW_ROOT:-${HOME}/.krew}/bin" $path)

SHELL_CONFIG_PATH="$(readlink -f "${(%):-%N}")"
SHELL_CONFIG_DIR="$(dirname "$SHELL_CONFIG_PATH")"

for config in "$SHELL_CONFIG_DIR"/*.conf; do
    [[ -f "$config" ]] || continue
    source "$config"
done
