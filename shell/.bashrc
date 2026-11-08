# Personal additions, loaded after the existing Bash configuration.
[[ $- != *i* ]] && return

case ":$PATH:" in
  *":${HOME}/.local/bin:"*) ;;
  *) PATH="$PATH:${HOME}/.local/bin" ;;
esac
case ":$PATH:" in
  *":${KREW_ROOT:-${HOME}/.krew}/bin:"*) ;;
  *) PATH="$PATH:${KREW_ROOT:-${HOME}/.krew}/bin" ;;
esac

SHELL_CONFIG_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SHELL_CONFIG_DIR="$(dirname "$SHELL_CONFIG_PATH")"

for config in "$SHELL_CONFIG_DIR"/*.conf; do
    [[ -f "$config" ]] || continue
    source "$config"
done

export PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end
