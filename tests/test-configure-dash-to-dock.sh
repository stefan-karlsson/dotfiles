#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
script="$(test_render_template 'home/.chezmoiscripts/run_always_after_28-configure-dash-to-dock.sh.tmpl')"

printf '%s\n' '48' >"${test_root}/dash-max-icon-size"
printf '%s\n' 'true' >"${test_root}/extend-height"

# Each Dash to Dock preference is backed by one file, so the script's
# read → compare → write cycle is observable.
test_stub_command gsettings - <<'STUB'
[[ "$2" == org.gnome.shell.extensions.dash-to-dock ]] || {
  printf 'unexpected schema: %s\n' "$2" >&2
  exit 1
}
[[ -f "${test_root}/$3" ]] || {
  printf 'unexpected key: %s\n' "$3" >&2
  exit 1
}
case "$1" in
  writable) exit 0 ;;
  get) cat "${test_root}/$3" ;;
  set) printf '%s\n' "$4" >"${test_root}/$3" ;;
  *) printf 'unexpected gsettings operation: %s\n' "$*" >&2; exit 1 ;;
esac
STUB

configure_dash_to_dock() {
  test_reset_calls
  XDG_CURRENT_DESKTOP=ubuntu:GNOME \
    DESKTOP_SESSION=ubuntu \
    test_run_script "${script}"
}

configure_dash_to_dock

[[ "$(<"${test_root}/dash-max-icon-size")" == '32' ]]
[[ "$(<"${test_root}/extend-height")" == 'false' ]]
test_assert_called 'gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 32'
test_assert_called 'gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false'

# Already configured: the script compares before it writes.
configure_dash_to_dock
test_assert_not_called 'gsettings set'

printf 'Dash to Dock configuration checks passed\n'
