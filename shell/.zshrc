# Personal additions, loaded after the existing Zsh configuration.
case ":$PATH:" in
  *":${HOME}/.local/bin:"*) ;;
  *) PATH="$PATH:${HOME}/.local/bin" ;;
esac
case ":$PATH:" in
  *":${KREW_ROOT:-${HOME}/.krew}/bin:"*) ;;
  *) PATH="$PATH:${KREW_ROOT:-${HOME}/.krew}/bin" ;;
esac

export PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) PATH="$PATH:$PNPM_HOME/bin" ;;
esac

SHELL_CONFIG_PATH="$(readlink -f "${(%):-%N}")"
SHELL_CONFIG_DIR="$(dirname "$SHELL_CONFIG_PATH")"

for config in "$SHELL_CONFIG_DIR"/*.conf; do
    [[ -f "$config" ]] || continue
    source "$config"
done
