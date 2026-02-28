#!/bin/bash
is_open=$(hyprctl monitors -j 2>/dev/null | jq -r '[.[].specialWorkspace.name] | any(. == "special:scratchpad")' 2>/dev/null || echo "false")

if [ "$is_open" = "true" ]; then
  echo '{"text": "󰘸", "tooltip": "Scratchpad open", "class": "active"}'
else
  echo '{"text": "󰘸", "tooltip": "Scratchpad hidden", "class": "inactive"}'
fi
