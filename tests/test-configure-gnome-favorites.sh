#!/usr/bin/env bash

set -euo pipefail

[[ $# -eq 1 ]] || {
  printf 'usage: %s <rendered-script>\n' "$0" >&2
  exit 2
}

script="$1"
test_root="$(mktemp -d)"
trap 'rm -rf "${test_root}"' EXIT
export test_root

printf '%s\n' "['firefox_firefox.desktop', 'existing.desktop', 'google-chrome.desktop']" > "${test_root}/favorites"
: > "${test_root}/gsettings.log"

gsettings() {
  local operation="$1"
  local schema="$2"
  local key="$3"

  [[ "${schema}" == 'org.gnome.shell' && "${key}" == 'favorite-apps' ]] || {
    printf 'unexpected gsettings call: %s\n' "$*" >&2
    return 1
  }

  case "${operation}" in
    writable)
      return 0
      ;;
    get)
      cat "${test_root}/favorites"
      ;;
    set)
      printf '%s\n' "$4" > "${test_root}/favorites"
      printf '%s\n' "$*" >> "${test_root}/gsettings.log"
      ;;
    *)
      printf 'unexpected gsettings operation: %s\n' "$*" >&2
      return 1
      ;;
  esac
}

export -f gsettings

XDG_CURRENT_DESKTOP=ubuntu:GNOME \
  DESKTOP_SESSION=ubuntu \
  PATH="/usr/bin:/bin:${PATH}" \
  bash "${script}"

favorites="$(cat "${test_root}/favorites")"
expected="['existing.desktop', 'google-chrome.desktop', 'dbeaver-ce.desktop', 'slack.desktop', 'slayzone.desktop', 'devtoys.desktop', 'obsidian.desktop', 'drawio.desktop']"
[[ "${favorites}" == "${expected}" ]]
grep -Fq 'set org.gnome.shell favorite-apps' "${test_root}/gsettings.log"

: > "${test_root}/gsettings.log"
XDG_CURRENT_DESKTOP=ubuntu:GNOME \
  DESKTOP_SESSION=ubuntu \
  PATH="/usr/bin:/bin:${PATH}" \
  bash "${script}"
[[ ! -s "${test_root}/gsettings.log" ]]

printf 'GNOME favorites configuration checks passed\n'
