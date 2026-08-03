#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"

installer='home/.chezmoiscripts/run_always_after_29-configure-gnome-favorites.sh.tmpl'
initial_favorites="['firefox_firefox.desktop', 'existing.desktop', 'google-chrome.desktop']"
shared_favorites="'existing.desktop', 'google-chrome.desktop', 'bruno.desktop', 'docker-desktop.desktop'"

declare -A expected_favorites=(
  [default]="[${shared_favorites}]"
  [private]="[${shared_favorites}, 'slayzone.desktop', 'obsidian.desktop']"
  [company]="[${shared_favorites}, 'dbeaver-ce.desktop', 'slack.desktop', 'devtoys.desktop', 'drawio.desktop']"
)

# The favourites list, backed by one file so the script's read → compare → write
# cycle is observable.
test_stub_command gsettings - <<'STUB'
[[ "$2" == org.gnome.shell && "$3" == favorite-apps ]] || {
  printf 'unexpected gsettings key: %s\n' "$*" >&2
  exit 1
}
case "$1" in
  writable) exit 0 ;;
  get) cat "${test_root}/favorites" ;;
  set) printf '%s\n' "$4" >"${test_root}/favorites" ;;
  *) printf 'unexpected gsettings operation: %s\n' "$*" >&2; exit 1 ;;
esac
STUB

configure_favorites() {
  local script="$1"

  test_reset_calls
  XDG_CURRENT_DESKTOP=ubuntu:GNOME \
    DESKTOP_SESSION=ubuntu \
    test_run_script "${script}"
}

assert_favorites() {
  local expected="$1"
  local actual
  actual="$(<"${test_root}/favorites")"

  [[ "${actual}" == "${expected}" ]] || {
    printf 'expected favorites %s\n     but read %s\n' "${expected}" "${actual}" >&2
    return 1
  }
}

for profile in "${test_profiles[@]}"; do
  script="$(test_render_template "${installer}" "${profile}")"
  printf '%s\n' "${initial_favorites}" >"${test_root}/favorites"

  configure_favorites "${script}"
  assert_favorites "${expected_favorites[${profile}]}"
  test_assert_called 'gsettings set org.gnome.shell favorite-apps'

  # Already configured: the script compares before it writes.
  configure_favorites "${script}"
  test_assert_not_called 'gsettings set'
done

printf 'GNOME favorites configuration checks passed\n'
