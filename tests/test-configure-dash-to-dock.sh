#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=test-helpers.sh
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_setup 1 "$@"
script="$1"
export test_root

: > "${test_root}/gsettings.log"
printf '%s\n' '48' > "${test_root}/icon-size"
printf '%s\n' 'true' > "${test_root}/extend-height"

gsettings() {
  local operation="$1"
  local schema="$2"
  local key="$3"

  [[ "${schema}" == 'org.gnome.shell.extensions.dash-to-dock' ]] || {
    printf 'unexpected schema: %s\n' "${schema}" >&2
    return 1
  }

  case "${operation}:${key}" in
    writable:dash-max-icon-size|writable:extend-height)
      return 0
      ;;
    get:dash-max-icon-size)
      cat "${test_root}/icon-size"
      ;;
    get:extend-height)
      cat "${test_root}/extend-height"
      ;;
    set:dash-max-icon-size)
      printf '%s\n' "$4" > "${test_root}/icon-size"
      printf '%s\n' "$*" >> "${test_root}/gsettings.log"
      ;;
    set:extend-height)
      printf '%s\n' "$4" > "${test_root}/extend-height"
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
  bash "${script}"

icon_size="$(cat "${test_root}/icon-size")"
extend_height="$(cat "${test_root}/extend-height")"
[[ "${icon_size}" == '32' ]]
[[ "${extend_height}" == 'false' ]]
grep -Fq 'set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 32' "${test_root}/gsettings.log"
grep -Fq 'set org.gnome.shell.extensions.dash-to-dock extend-height false' "${test_root}/gsettings.log"

: > "${test_root}/gsettings.log"
XDG_CURRENT_DESKTOP=ubuntu:GNOME \
  DESKTOP_SESSION=ubuntu \
  PATH="/usr/bin:/bin:${PATH}" \
  bash "${script}"
[[ ! -s "${test_root}/gsettings.log" ]]

printf 'Dash to Dock configuration checks passed\n'
