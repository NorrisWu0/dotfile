#!/bin/bash
[ -z "$HYPRLAND_INSTANCE_SIGNATURE" ] && exit 1

socket="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

pkill -f "scratchpad-listener.sh" -x --older-than 1s 2>/dev/null || true

nc -U "$socket" | while IFS= read -r line; do
  case "$line" in
    activespecial*)
      pkill -RTMIN+11 waybar
      ;;
  esac
done
