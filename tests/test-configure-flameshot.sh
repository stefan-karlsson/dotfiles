#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=test-helpers.sh
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_setup 1 "$@"
script="$1"

managed_path='/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/flameshot/'
state_dir="$test_root/state"
mkdir -p "$state_dir"
printf "['Print']\n" > "$state_dir/show-screenshot-ui"
printf '@as []\n' > "$state_dir/custom-keybindings"
: > "$state_dir/changes"
export state_dir

gsettings() {
  local operation="$1"
  local schema="$2"
  local key="$3"
  local value="${4:-}"

  case "$operation:$schema:$key" in
    writable:org.gnome.shell.keybindings:show-screenshot-ui)
      return 0
      ;;
    writable:org.gnome.settings-daemon.plugins.media-keys:custom-keybindings)
      return 0
      ;;
    get:org.gnome.shell.keybindings:show-screenshot-ui)
      cat "$state_dir/show-screenshot-ui"
      ;;
    get:org.gnome.settings-daemon.plugins.media-keys:custom-keybindings)
      cat "$state_dir/custom-keybindings"
      ;;
    get:org.gnome.settings-daemon.plugins.media-keys.custom-keybinding\:*:name)
      cat "$state_dir/name"
      ;;
    get:org.gnome.settings-daemon.plugins.media-keys.custom-keybinding\:*:command)
      cat "$state_dir/command"
      ;;
    get:org.gnome.settings-daemon.plugins.media-keys.custom-keybinding\:*:binding)
      if [[ "$schema" == *:/other/ ]]; then
        cat "$state_dir/other-binding"
      else
        cat "$state_dir/binding"
      fi
      ;;
    set:org.gnome.shell.keybindings:show-screenshot-ui)
      printf 'shell show-screenshot-ui=%s\n' "$value" >> "$state_dir/changes"
      printf '%s\n' "$value" > "$state_dir/show-screenshot-ui"
      ;;
    set:org.gnome.settings-daemon.plugins.media-keys:custom-keybindings)
      printf 'media custom-keybindings=%s\n' "$value" >> "$state_dir/changes"
      printf '%s\n' "$value" > "$state_dir/custom-keybindings"
      ;;
    set:org.gnome.settings-daemon.plugins.media-keys.custom-keybinding\:*:name)
      printf 'custom name=%s\n' "$value" >> "$state_dir/changes"
      printf '%s\n' "'$value'" > "$state_dir/name"
      ;;
    set:org.gnome.settings-daemon.plugins.media-keys.custom-keybinding\:*:command)
      printf 'custom command=%s\n' "$value" >> "$state_dir/changes"
      printf '%s\n' "'$value'" > "$state_dir/command"
      ;;
    set:org.gnome.settings-daemon.plugins.media-keys.custom-keybinding\:*:binding)
      printf 'custom binding=%s\n' "$value" >> "$state_dir/changes"
      printf '%s\n' "'$value'" > "$state_dir/binding"
      ;;
    *)
      printf 'unexpected gsettings call: %s %s %s %s\n' "$operation" "$schema" "$key" "$value" >&2
      return 1
      ;;
  esac
}
export -f gsettings
mkdir -p "$test_root/bin"
printf '#!/usr/bin/env bash\ngsettings "$@"\n' > "$test_root/bin/gsettings"
chmod +x "$test_root/bin/gsettings"

HOME="$test_root/home" \
XDG_CURRENT_DESKTOP=ubuntu:GNOME \
DBUS_SESSION_BUS_ADDRESS=mock \
PATH="$test_root/bin:$PATH" \
  bash "$script"

grep -Fxq 'shell show-screenshot-ui=[]' "$state_dir/changes"
grep -Fxq "media custom-keybindings=['$managed_path']" "$state_dir/changes"
grep -Fxq "custom name=Flameshot screenshot capture" "$state_dir/changes"
grep -Fxq "custom command=$test_root/home/.local/bin/flameshot-gui" "$state_dir/changes"
grep -Fxq 'custom binding=Print' "$state_dir/changes"

: > "$state_dir/changes"
HOME="$test_root/home" \
XDG_CURRENT_DESKTOP=ubuntu:GNOME \
DBUS_SESSION_BUS_ADDRESS=mock \
PATH="$test_root/bin:$PATH" \
  bash "$script"
[[ ! -s "$state_dir/changes" ]]

printf "['$managed_path']\n" > "$state_dir/custom-keybindings"
printf "''\n" > "$state_dir/name"
printf "''\n" > "$state_dir/command"
printf "''\n" > "$state_dir/binding"
: > "$state_dir/changes"
HOME="$test_root/home" \
XDG_CURRENT_DESKTOP=ubuntu:GNOME \
DBUS_SESSION_BUS_ADDRESS=mock \
PATH="$test_root/bin:$PATH" \
  bash "$script"
grep -Fxq 'custom name=Flameshot screenshot capture' "$state_dir/changes"
grep -Fxq "custom command=$test_root/home/.local/bin/flameshot-gui" "$state_dir/changes"
grep -Fxq 'custom binding=Print' "$state_dir/changes"

printf "['$managed_path', '$managed_path']\n" > "$state_dir/custom-keybindings"
printf "'Flameshot screenshot capture'\n" > "$state_dir/name"
printf "'$test_root/home/.local/bin/flameshot-gui'\n" > "$state_dir/command"
printf "'Print'\n" > "$state_dir/binding"
: > "$state_dir/changes"
HOME="$test_root/home" \
XDG_CURRENT_DESKTOP=ubuntu:GNOME \
DBUS_SESSION_BUS_ADDRESS=mock \
PATH="$test_root/bin:$PATH" \
  bash "$script"
grep -Fxq "media custom-keybindings=['$managed_path']" "$state_dir/changes"

printf "['/other/']\n" > "$state_dir/custom-keybindings"
printf "'Print'\n" > "$state_dir/other-binding"
: > "$state_dir/changes"
if HOME="$test_root/home" XDG_CURRENT_DESKTOP=ubuntu:GNOME DBUS_SESSION_BUS_ADDRESS=mock PATH="$test_root/bin:$PATH" \
  bash "$script" > "$test_root/conflict.out" 2>&1; then
  printf 'error: existing Print shortcut was overwritten\n' >&2
  exit 1
fi
grep -Fq 'already owns Print' "$test_root/conflict.out"
[[ ! -s "$state_dir/changes" ]]
