#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
script="$(test_render_template 'home/.chezmoiscripts/run_always_after_31-configure-ac-power.sh.tmpl')"

printf '%s\n' '300' >"${test_root}/sleep-inactive-ac-timeout"
printf '%s\n' "'suspend'" >"${test_root}/sleep-inactive-ac-type"
printf '%s\n' "'suspend'" >"${test_root}/lid-close-ac-action"
printf '%s\n' 'true' >"${test_root}/logout-enabled"

# Each preference is backed by one file. A stored value that arrives quoted is a
# GVariant string, so it is written back quoted the way `gsettings get` reports
# it; anything else round-trips verbatim.
test_stub_command gsettings - <<'STUB'
[[ -f "${test_root}/$3" ]] || {
  printf 'unexpected key: %s\n' "$*" >&2
  exit 1
}
case "$1" in
  writable) exit 0 ;;
  get) cat "${test_root}/$3" ;;
  set)
    if [[ "$(<"${test_root}/$3")" == \'*\' ]]; then
      printf "'%s'\n" "$4" >"${test_root}/$3"
    else
      printf '%s\n' "$4" >"${test_root}/$3"
    fi
    ;;
  *) printf 'unexpected gsettings operation: %s\n' "$*" >&2; exit 1 ;;
esac
STUB

configure_ac_power() {
  test_reset_calls
  XDG_CURRENT_DESKTOP=ubuntu:GNOME \
    DESKTOP_SESSION=ubuntu \
    test_run_script "${script}"
}

configure_ac_power

[[ "$(<"${test_root}/sleep-inactive-ac-timeout")" == '0' ]]
[[ "$(<"${test_root}/sleep-inactive-ac-type")" == "'nothing'" ]]
[[ "$(<"${test_root}/lid-close-ac-action")" == "'nothing'" ]]
[[ "$(<"${test_root}/logout-enabled")" == 'false' ]]
test_assert_called 'gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type nothing'
test_assert_called 'gsettings set org.gnome.settings-daemon.plugins.power lid-close-ac-action nothing'
test_assert_called 'gsettings set org.gnome.desktop.screensaver logout-enabled false'

# Already configured: the script compares before it writes.
configure_ac_power
test_assert_not_called 'gsettings set'

printf 'AC power configuration checks passed\n'
