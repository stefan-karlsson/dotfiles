#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
script="$(test_render_template 'home/.chezmoiscripts/run_after_30-configure-ptyxis-font.sh.tmpl')"

printf '%s\n' true >"${test_root}/use-system-font"
printf '%s\n' "'Sans 11'" >"${test_root}/font-name"
printf '%s\n' "'1234'" >"${test_root}/default-profile-uuid"
printf '%s\n' "'tango'" >"${test_root}/palette"

test_stub_command ptyxis

# Ptyxis keys live under two schemas, the profile one addressed by path. Each
# preference is backed by one file, and a stored value that arrives quoted is
# written back quoted the way `gsettings get` reports it.
test_stub_command gsettings - <<'STUB'
case "$2" in
  org.gnome.Ptyxis) store="${test_root}/$3" ;;
  org.gnome.Ptyxis.Profile:*) store="${test_root}/palette" ;;
  *) printf 'unexpected schema: %s\n' "$2" >&2; exit 1 ;;
esac
[[ -f "${store}" ]] || {
  printf 'unexpected key: %s\n' "$*" >&2
  exit 1
}
case "$1" in
  get) cat "${store}" ;;
  set)
    if [[ "$(<"${store}")" == \'*\' ]]; then
      printf "'%s'\n" "$4" >"${store}"
    else
      printf '%s\n' "$4" >"${store}"
    fi
    ;;
  *) printf 'unexpected gsettings operation: %s\n' "$*" >&2; exit 1 ;;
esac
STUB

test_stub_command fc-match "printf '%s\\n' 'FiraCode Nerd Font Mono'"

configure_ptyxis_font() {
  test_reset_calls
  test_run_script "${script}"
}

configure_ptyxis_font

test_assert_called 'fc-match -f %{family[0]}'
test_assert_called 'gsettings set org.gnome.Ptyxis use-system-font false'
test_assert_called 'gsettings set org.gnome.Ptyxis font-name FiraCode Nerd Font Mono 13'
test_assert_called 'gsettings set org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/1234/ palette dracula'

# Already configured: the script compares before it writes.
configure_ptyxis_font
test_assert_not_called 'gsettings set'

printf 'Ptyxis developer font checks passed\n'
