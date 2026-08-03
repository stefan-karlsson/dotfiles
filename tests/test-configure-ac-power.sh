#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=test-helpers.sh
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_setup 1 "$@"
script="$1"
export test_root

printf '%s\n' '300' > "${test_root}/sleep-inactive-ac-timeout"
printf '%s\n' "'suspend'" > "${test_root}/sleep-inactive-ac-type"
printf '%s\n' "'suspend'" > "${test_root}/lid-close-ac-action"
printf '%s\n' 'true' > "${test_root}/logout-enabled"
: > "${test_root}/gsettings.log"

gsettings() {
  local operation="$1"
  local schema="$2"
  local key="$3"
  local value="${4:-}"

  case "${operation}:${schema}:${key}" in
    writable:org.gnome.settings-daemon.plugins.power:sleep-inactive-ac-timeout|\
    writable:org.gnome.settings-daemon.plugins.power:sleep-inactive-ac-type|\
    writable:org.gnome.settings-daemon.plugins.power:lid-close-ac-action|\
    writable:org.gnome.desktop.screensaver:logout-enabled)
      return 0
      ;;
    get:org.gnome.settings-daemon.plugins.power:sleep-inactive-ac-timeout|\
    get:org.gnome.settings-daemon.plugins.power:sleep-inactive-ac-type|\
    get:org.gnome.settings-daemon.plugins.power:lid-close-ac-action|\
    get:org.gnome.desktop.screensaver:logout-enabled)
      cat "${test_root}/${key}"
      ;;
    set:org.gnome.settings-daemon.plugins.power:sleep-inactive-ac-timeout|\
    set:org.gnome.settings-daemon.plugins.power:sleep-inactive-ac-type|\
    set:org.gnome.settings-daemon.plugins.power:lid-close-ac-action|\
    set:org.gnome.desktop.screensaver:logout-enabled)
      case "${key}" in
        sleep-inactive-ac-type|lid-close-ac-action)
          printf "'%s'\n" "${value}" > "${test_root}/${key}"
          ;;
        *)
          printf '%s\n' "${value}" > "${test_root}/${key}"
          ;;
      esac
      printf '%s\n' "$*" >> "${test_root}/gsettings.log"
      ;;
    *)
      printf 'unexpected gsettings call: %s\n' "$*" >&2
      return 1
      ;;
  esac
}

export -f gsettings

XDG_CURRENT_DESKTOP=ubuntu:GNOME \
  DESKTOP_SESSION=ubuntu \
  PATH="/usr/bin:/bin:${PATH}" \
  test_run_script "${script}"

ac_timeout="$(<"${test_root}/sleep-inactive-ac-timeout")"
ac_sleep_type="$(<"${test_root}/sleep-inactive-ac-type")"
ac_lid_action="$(<"${test_root}/lid-close-ac-action")"
logout_enabled="$(<"${test_root}/logout-enabled")"
[[ "${ac_timeout}" == '0' ]]
[[ "${ac_sleep_type}" == "'nothing'" ]]
[[ "${ac_lid_action}" == "'nothing'" ]]
[[ "${logout_enabled}" == 'false' ]]
grep -Fq 'set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type nothing' "${test_root}/gsettings.log"
grep -Fq 'set org.gnome.settings-daemon.plugins.power lid-close-ac-action nothing' "${test_root}/gsettings.log"
grep -Fq 'set org.gnome.desktop.screensaver logout-enabled false' "${test_root}/gsettings.log"

: > "${test_root}/gsettings.log"
XDG_CURRENT_DESKTOP=ubuntu:GNOME \
  DESKTOP_SESSION=ubuntu \
  PATH="/usr/bin:/bin:${PATH}" \
  test_run_script "${script}"
[[ ! -s "${test_root}/gsettings.log" ]]

printf 'AC power configuration checks passed\n'
