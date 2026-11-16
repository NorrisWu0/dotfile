# Omarchy desktop configuration

These files are manual-only. They are excluded from `setup-dotfile.sh`, its
`--all` selection, `noctlrc.yaml`, and mise profile deployment.

- `hypr/looknfeel.lua`: zero window gaps and 1px borders; monitor settings stay per-device.
- `waybar/`: custom status bar with CPU, memory, battery, and clock displays; requires Omarchy's desktop and theme assets.
- `branding/`: custom about and screensaver artwork.

Existing desktop symlinks must be updated to these relocated source paths.
No desktop configuration is installed by the portable or devbox setup.
