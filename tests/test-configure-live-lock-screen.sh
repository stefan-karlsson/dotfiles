#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
script="$(test_render_template 'home/.chezmoiscripts/run_always_after_29-configure-live-lock-screen.sh.tmpl')"

extension_root="${test_root}/home/.local/share/gnome-shell/extensions"
export LIVE_LOCKSCREEN_SCHEMA_DIR="${extension_root}/live-lockscreen@nick-redwill/schemas"
export BLUR_MY_SHELL_SCHEMA_DIR="${extension_root}/blur-my-shell@aunetx/schemas"
mkdir -p "${LIVE_LOCKSCREEN_SCHEMA_DIR}" "${BLUR_MY_SHELL_SCHEMA_DIR}"

printf '%s\n' 'old animation' >"${test_root}/animation-source"
printf '%s\n' 'true' >"${test_root}/blur-my-shell.blur"
printf '%s\n' "''" >"${test_root}/background-video-path"
printf '%s\n' '0' >"${test_root}/background-video-scaling-mode"
printf '%s\n' 'false' >"${test_root}/background-video-looped"
printf '%s\n' '25' >"${test_root}/background-audio-volume"
printf '%s\n' '500' >"${test_root}/background-fade-in-duration"
printf '%s\n' 'false' >"${test_root}/prompt-change-blur"
printf '%s\n' '20' >"${test_root}/prompt-blur-radius"
printf '%s\n' '0.65' >"${test_root}/prompt-blur-brightness"

# The pinned digest the installer demands; the sha256sum stub reports it for the
# fixture animation so the real comparison in the fetch foundation is exercised.
expected_animation_sha256="$(sed -n "s/^animation_sha256='\([a-f0-9]\{64\}\)'$/\1/p" "${script}")"
[[ -n "${expected_animation_sha256}" ]] || {
  printf 'could not read the pinned animation checksum from the installer\n' >&2
  exit 1
}
export EXPECTED_ANIMATION_SHA256="${expected_animation_sha256}"

test_stub_command curl - <<'STUB'
output=""
while (($# > 0)); do
  case "$1" in
    -o|--output) output="$2"; shift 2 ;;
    *) shift ;;
  esac
done
[[ -n "${output}" ]] || exit 1
cp "${test_root}/animation-source" "${output}"
STUB

test_stub_command sha256sum - <<'STUB'
# --check form: the cached animation matches only once it has been installed.
if [[ "$1" == '--check' ]]; then
  read -r _ checked_path
  [[ -r "${checked_path}" ]]
  exit
fi
# digest form: the fixture animation carries the digest the manifest pins.
printf '%s  %s\n' "${EXPECTED_ANIMATION_SHA256}" "$1"
STUB

# Two extensions, each with its own schema directory. A preference is backed by
# one file, so the script's read → compare → write cycle is observable, and a
# stored value that arrives quoted is written back quoted the way
# `gsettings get` reports it.
test_stub_command gsettings - <<'STUB'
case "$2" in
  org.gnome.shell.extensions.blur-my-shell.lockscreen)
    expected_schema_dir="${BLUR_MY_SHELL_SCHEMA_DIR}"
    store="${test_root}/blur-my-shell.$3"
    ;;
  org.gnome.shell.extensions.live-lockscreen)
    expected_schema_dir="${LIVE_LOCKSCREEN_SCHEMA_DIR}"
    store="${test_root}/$3"
    ;;
  *)
    printf 'unexpected schema: %s\n' "$2" >&2
    exit 1
    ;;
esac
[[ "${GSETTINGS_SCHEMA_DIR:-}" == "${expected_schema_dir}" ]] || {
  printf 'unexpected GSETTINGS_SCHEMA_DIR for %s: %s\n' "$2" "${GSETTINGS_SCHEMA_DIR:-}" >&2
  exit 1
}
[[ -f "${store}" ]] || {
  printf 'unexpected key: %s\n' "$*" >&2
  exit 1
}
case "$1" in
  writable) exit 0 ;;
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

configure_live_lock_screen() {
  test_reset_calls
  XDG_CURRENT_DESKTOP=ubuntu:GNOME \
    DESKTOP_SESSION=ubuntu \
    DBUS_SESSION_BUS_ADDRESS=mock \
    HOME="${test_root}/home" \
    XDG_DATA_HOME="${test_root}/home/.local/share" \
    test_run_script "${script}"
}

configure_live_lock_screen

test_assert_called 'curl'
test_assert_called 'gsettings set org.gnome.shell.extensions.live-lockscreen background-video-path'
test_assert_called 'gsettings set org.gnome.shell.extensions.live-lockscreen background-video-scaling-mode 2'
test_assert_called 'gsettings set org.gnome.shell.extensions.live-lockscreen background-video-looped true'
test_assert_called 'gsettings set org.gnome.shell.extensions.live-lockscreen background-audio-volume 0'
test_assert_called 'gsettings set org.gnome.shell.extensions.live-lockscreen background-fade-in-duration 0'
test_assert_called 'gsettings set org.gnome.shell.extensions.live-lockscreen prompt-change-blur true'
test_assert_called 'gsettings set org.gnome.shell.extensions.blur-my-shell.lockscreen blur false'
[[ -r "${test_root}/home/.local/share/gnome-shell/live-lock-screen/clouds-101-low-altitude.webm" ]]

# Already configured: the animation is not fetched again and nothing is written.
configure_live_lock_screen
test_assert_not_called 'curl'
test_assert_not_called 'gsettings set'

printf 'Live Lock Screen configuration checks passed\n'
