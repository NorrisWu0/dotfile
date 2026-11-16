#!/usr/bin/env bash

set -euo pipefail

repo="$(realpath "$(dirname "$0")/..")"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin" "$work/herdr"
cp "$repo/herdr/sync-plugins.sh" "$work/herdr/sync-plugins.sh"
cat > "$work/herdr/plugins.yaml" <<'YAML'
plugins:
  - example/plugins/one
YAML
cat > "$work/bin/herdr" <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
case "$*" in
    'plugin list --json')
        case "${FAKE_LIST:-}" in
            fail) printf 'list unavailable\n' >&2; exit 1 ;;
            malformed) printf '{}\n'; exit 0 ;;
        esac
        cat "$PLUGIN_TEST_WORK/inventory.json"
        ;;
    'plugin install example/plugins/one --yes')
        printf '%s\n' "$*" >> "$PLUGIN_TEST_WORK/calls"
        [[ "${FAKE_INSTALL:-}" != fail ]] || exit 1
        jq '.result.plugins += [{source: {kind: "github", owner: "example", repo: "plugins", subdir: "one"}}]' \
            "$PLUGIN_TEST_WORK/inventory.json" > "$PLUGIN_TEST_WORK/new.json"
        mv "$PLUGIN_TEST_WORK/new.json" "$PLUGIN_TEST_WORK/inventory.json"
        ;;
    *) printf 'Unexpected Herdr command: %s\n' "$*" >&2; exit 99 ;;
esac
BASH
chmod +x "$work/bin/herdr"
export PATH="$work/bin:$PATH"
export PLUGIN_TEST_WORK="$work"
# Another plugin from the same repo is not the requested subdirectory.
printf '%s\n' '{"result":{"plugins":[{"source":{"kind":"github","owner":"example","repo":"plugins","subdir":"two"}}]}}' > "$work/inventory.json"

output="$(bash "$work/herdr/sync-plugins.sh" --dry-run)"
[[ ! -e "$work/calls" ]]

# Failed or malformed listing must not become an empty successful inventory.
for failure in fail malformed; do
    if FAKE_LIST="$failure" bash "$work/herdr/sync-plugins.sh" >/dev/null 2>&1; then
        printf 'Unexpected success for %s plugin listing\n' "$failure" >&2
        exit 1
    fi
    [[ ! -e "$work/calls" ]]
done

if FAKE_INSTALL=fail bash "$work/herdr/sync-plugins.sh" > "$work/failed-output" 2>/dev/null; then
    printf 'Unexpected success for failed plugin installation\n' >&2
    exit 1
fi
rm "$work/calls"

output="$(bash "$work/herdr/sync-plugins.sh")"
jq -e '[.result.plugins[].source.subdir] | sort == ["one", "two"]' "$work/inventory.json" >/dev/null
output="$(bash "$work/herdr/sync-plugins.sh")"
[[ "$(wc -l < "$work/calls")" == 1 ]]

printf 'Herdr plugin checks passed.\n'
