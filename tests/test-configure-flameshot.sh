#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
script="$(test_render_template 'home/.chezmoiscripts/run_always_after_35-configure-flameshot.sh.tmpl')"

managed_path='/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/flameshot/'
state_dir="$test_root/state"
mkdir -p "$state_dir"
printf "['Print']\n" > "$state_dir/show-screenshot-ui"
printf '@as []\n' > "$state_dir/custom-keybindings"
: > "$state_dir/changes"

# The two keybinding schemas the script reads, the custom one addressed by path.
# Each preference is backed by one file, and every write is recorded so the
# script's read → compare → write cycle is observable.
test_stub_command gsettings - <<'STUB'
state_dir="${test_root}/state"
case "$1:$2:$3" in
  writable:org.gnome.shell.keybindings:show-screenshot-ui) exit 0 ;;
  writable:org.gnome.settings-daemon.plugins.media-keys:custom-keybindings) exit 0 ;;
  get:org.gnome.shell.keybindings:show-screenshot-ui)
    cat "${state_dir}/show-screenshot-ui"
    ;;
  get:org.gnome.settings-daemon.plugins.media-keys:custom-keybindings)
    cat "${state_dir}/custom-keybindings"
    ;;
  get:org.gnome.settings-daemon.plugins.media-keys.custom-keybinding\:*:name)
    cat "${state_dir}/name"
    ;;
  get:org.gnome.settings-daemon.plugins.media-keys.custom-keybinding\:*:command)
    cat "${state_dir}/command"
    ;;
  get:org.gnome.settings-daemon.plugins.media-keys.custom-keybinding\:*:binding)
    if [[ "$2" == *:/other/ ]]; then
      cat "${state_dir}/other-binding"
    else
      cat "${state_dir}/binding"
    fi
    ;;
  set:org.gnome.shell.keybindings:show-screenshot-ui)
    printf 'shell show-screenshot-ui=%s\n' "$4" >>"${state_dir}/changes"
    printf '%s\n' "$4" >"${state_dir}/show-screenshot-ui"
    ;;
  set:org.gnome.settings-daemon.plugins.media-keys:custom-keybindings)
    printf 'media custom-keybindings=%s\n' "$4" >>"${state_dir}/changes"
    printf '%s\n' "$4" >"${state_dir}/custom-keybindings"
    ;;
  set:org.gnome.settings-daemon.plugins.media-keys.custom-keybinding\:*:name)
    printf 'custom name=%s\n' "$4" >>"${state_dir}/changes"
    printf "'%s'\n" "$4" >"${state_dir}/name"
    ;;
  set:org.gnome.settings-daemon.plugins.media-keys.custom-keybinding\:*:command)
    printf 'custom command=%s\n' "$4" >>"${state_dir}/changes"
    printf "'%s'\n" "$4" >"${state_dir}/command"
    ;;
  set:org.gnome.settings-daemon.plugins.media-keys.custom-keybinding\:*:binding)
    printf 'custom binding=%s\n' "$4" >>"${state_dir}/changes"
    printf "'%s'\n" "$4" >"${state_dir}/binding"
    ;;
  *)
    printf 'unexpected gsettings call: %s\n' "$*" >&2
    exit 1
    ;;
esac
STUB

configure_flameshot() {
  HOME="$test_root/home" \
    XDG_CURRENT_DESKTOP=ubuntu:GNOME \
    DBUS_SESSION_BUS_ADDRESS=mock \
    test_run_script "$script"
}

configure_flameshot

grep -Fxq 'shell show-screenshot-ui=[]' "$state_dir/changes"
grep -Fxq "media custom-keybindings=['$managed_path']" "$state_dir/changes"
grep -Fxq "custom name=Flameshot screenshot capture" "$state_dir/changes"
grep -Fxq "custom command=$test_root/home/.local/bin/flameshot-gui" "$state_dir/changes"
grep -Fxq 'custom binding=Print' "$state_dir/changes"

: > "$state_dir/changes"
configure_flameshot
[[ ! -s "$state_dir/changes" ]]

printf "['$managed_path']\n" > "$state_dir/custom-keybindings"
printf "''\n" > "$state_dir/name"
printf "''\n" > "$state_dir/command"
printf "''\n" > "$state_dir/binding"
: > "$state_dir/changes"
configure_flameshot
grep -Fxq 'custom name=Flameshot screenshot capture' "$state_dir/changes"
grep -Fxq "custom command=$test_root/home/.local/bin/flameshot-gui" "$state_dir/changes"
grep -Fxq 'custom binding=Print' "$state_dir/changes"

printf "['$managed_path', '$managed_path']\n" > "$state_dir/custom-keybindings"
printf "'Flameshot screenshot capture'\n" > "$state_dir/name"
printf "'$test_root/home/.local/bin/flameshot-gui'\n" > "$state_dir/command"
printf "'Print'\n" > "$state_dir/binding"
: > "$state_dir/changes"
configure_flameshot
grep -Fxq "media custom-keybindings=['$managed_path']" "$state_dir/changes"

printf "['/other/']\n" > "$state_dir/custom-keybindings"
printf "'Print'\n" > "$state_dir/other-binding"
: > "$state_dir/changes"
if configure_flameshot >"$test_root/conflict.out" 2>&1; then
  printf 'error: existing Print shortcut was overwritten\n' >&2
  exit 1
fi
grep -Fq 'already owns Print' "$test_root/conflict.out"
[[ ! -s "$state_dir/changes" ]]

printf 'Flameshot screenshot capture checks passed\n'
