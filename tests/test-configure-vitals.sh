#!/usr/bin/env bash

set -euo pipefail

[[ $# -eq 1 ]] || {
  printf 'usage: %s <rendered-vitals-config-script>\n' "$0" >&2
  exit 2
}

script="$1"
test_root="$(mktemp -d)"
trap 'rm -rf "${test_root}"' EXIT
export test_root

mkdir -p "${test_root}/home/.local/share/gnome-shell/extensions/Vitals@CoreCoding.com/schemas"
printf '%s\n' "['_memory_usage_']" > "${test_root}/hot-sensors"
printf '%s\n' '1' > "${test_root}/position"
: > "${test_root}/changes"

gsettings() {
  local operation="$1"
  local schema="$2"
  local key="$3"
  local value="${4:-}"

  [[ "${GSETTINGS_SCHEMA_DIR:-}" == "${test_root}/home/.local/share/gnome-shell/extensions/Vitals@CoreCoding.com/schemas" ]] || {
    printf 'unexpected GSETTINGS_SCHEMA_DIR: %s\n' "${GSETTINGS_SCHEMA_DIR:-}" >&2
    return 1
  }

  [[ "${schema}" == 'org.gnome.shell.extensions.vitals' ]] || {
    printf 'unexpected schema: %s\n' "${schema}" >&2
    return 1
  }

  case "${operation}:${key}" in
    writable:hot-sensors|writable:position-in-panel)
      return 0
      ;;
    get:hot-sensors)
      cat "${test_root}/hot-sensors"
      ;;
    get:position-in-panel)
      cat "${test_root}/position"
      ;;
    set:hot-sensors)
      printf '%s\n' "${value}" > "${test_root}/hot-sensors"
      printf '%s\n' "$*" >> "${test_root}/changes"
      ;;
    set:position-in-panel)
      printf '%s\n' "${value}" > "${test_root}/position"
      printf '%s\n' "$*" >> "${test_root}/changes"
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
  DBUS_SESSION_BUS_ADDRESS=mock \
  HOME="${test_root}/home" \
  bash "${script}"

grep -Fq "set org.gnome.shell.extensions.vitals hot-sensors ['_memory_usage_', '_system_load_1m_', '__network-rx_max__']" "${test_root}/changes"
grep -Fq 'set org.gnome.shell.extensions.vitals position-in-panel 2' "${test_root}/changes"

: > "${test_root}/changes"
XDG_CURRENT_DESKTOP=ubuntu:GNOME \
  DESKTOP_SESSION=ubuntu \
  DBUS_SESSION_BUS_ADDRESS=mock \
  HOME="${test_root}/home" \
  bash "${script}"
[[ ! -s "${test_root}/changes" ]]

printf 'Vitals configuration checks passed\n'
