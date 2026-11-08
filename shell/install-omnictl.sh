#!/usr/bin/env bash

set -euo pipefail

case "${1:-}" in
    '') dry_run=false ;;
    --dry-run) dry_run=true ;;
    *) printf 'Usage: bash %s [--dry-run]\n' "$0" >&2; exit 1 ;;
esac

if command -v omnictl >/dev/null 2>&1; then
    printf 'omnictl already available: %s\n' "$(command -v omnictl)"
    exit 0
fi

target="$HOME/.local/bin/omnictl"
if [[ -x "$target" && ! -d "$target" ]]; then
    printf 'omnictl already installed: %s (add its directory to PATH if needed)\n' "$target"
    exit 0
fi
if [[ -e "$target" || -L "$target" ]]; then
    printf 'omnictl target already exists; not replacing: %s\n' "$target" >&2
    exit 1
fi

version=v1.9.1
case "$(uname -s):$(uname -m)" in
    Linux:x86_64)
        arch=amd64
        checksum=66c7a844c45e01fa5933f8b9db56c19d23eca65db441d56d0312316e683bb8e2
        ;;
    Linux:aarch64)
        arch=arm64
        checksum=9c10475ebcfe17a6276fa8e149076937a1a91492efc272b62eb5a03c37f0c7ec
        ;;
    *)
        printf 'omnictl: unsupported platform: %s %s\n' "$(uname -s)" "$(uname -m)" >&2
        exit 1
        ;;
esac

url="https://github.com/siderolabs/omni/releases/download/$version/omnictl-linux-$arch"
if $dry_run; then
    printf 'would install omnictl %s from %s to %s\n' "$version" "$url" "$target"
    exit 0
fi

mkdir -p "${target%/*}"
download="$(mktemp "${target%/*}/.omnictl.XXXXXXXX")"
trap 'rm -f "$download"' EXIT

curl -fsSL "$url" -o "$download"
if ! printf '%s  %s\n' "$checksum" "$download" | sha256sum --check --status; then
    printf 'omnictl: checksum verification failed\n' >&2
    exit 1
fi
chmod 755 "$download"
ln "$download" "$target"
printf 'installed omnictl %s: %s\n' "$version" "$target"
