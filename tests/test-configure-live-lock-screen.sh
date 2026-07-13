#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=test-helpers.sh
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_setup 1 "$@"
script="$1"
export test_root

mkdir -p "${test_root}/bin" "${test_root}/home/.local/share/gnome-shell/extensions/live-lockscreen@nick-redwill/schemas"
printf '%s\n' "old animation" > "${test_root}/animation-source"
: > "${test_root}/download.log"
: > "${test_root}/changes"
printf '%s\n' "''" > "${test_root}/background-video-path"
printf '%s\n' '0' > "${test_root}/background-video-scaling-mode"
printf '%s\n' 'false' > "${test_root}/background-video-looped"
printf '%s\n' '25' > "${test_root}/background-audio-volume"
printf '%s\n' '500' > "${test_root}/background-fade-in-duration"
printf '%s\n' 'false' > "${test_root}/prompt-change-blur"
printf '%s\n' '20' > "${test_root}/prompt-blur-radius"
printf '%s\n' '0.65' > "${test_root}/prompt-blur-brightness"

printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf "%s\n" "$*" >> "$TEST_ROOT/download.log"' \
  'cp "$TEST_ROOT/animation-source" "$6"' > "${test_root}/bin/curl"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  '[[ "$1" == "--check" && "$2" == "--status" && "$3" == "-" ]]' > "${test_root}/bin/sha256sum"
chmod +x "${test_root}/bin/curl" "${test_root}/bin/sha256sum"

gsettings() {
  local operation="$1"
  local schema="$2"
  local key="$3"
  local value="${4:-}"

  [[ "${schema}" == 'org.gnome.shell.extensions.live-lockscreen' ]] || {
    printf 'unexpected schema: %s\n' "${schema}" >&2
    return 1
  }
  [[ "${GSETTINGS_SCHEMA_DIR:-}" == "${test_root}/home/.local/share/gnome-shell/extensions/live-lockscreen@nick-redwill/schemas" ]] || {
    printf 'unexpected GSETTINGS_SCHEMA_DIR: %s\n' "${GSETTINGS_SCHEMA_DIR:-}" >&2
    return 1
  }

  case "${operation}:${key}" in
    writable:background-video-path|writable:background-video-looped|writable:background-audio-volume)
      return 0
      ;;
    get:background-video-path|get:background-video-scaling-mode|get:background-video-looped|get:background-audio-volume|get:background-fade-in-duration|get:prompt-change-blur|get:prompt-blur-radius|get:prompt-blur-brightness)
      cat "${test_root}/${key}"
      ;;
    set:background-video-path|set:background-video-scaling-mode|set:background-video-looped|set:background-audio-volume|set:background-fade-in-duration|set:prompt-change-blur|set:prompt-blur-radius|set:prompt-blur-brightness)
      if [[ "${key}" == 'background-video-path' ]]; then
        printf "'%s'\n" "${value}" > "${test_root}/${key}"
      else
        printf '%s\n' "${value}" > "${test_root}/${key}"
      fi
      printf '%s\n' "$*" >> "${test_root}/changes"
      ;;
    *)
      printf 'unexpected gsettings call: %s\n' "$*" >&2
      return 1
      ;;
  esac
}

export -f gsettings
export TEST_ROOT="${test_root}"

run_configure() {
  XDG_CURRENT_DESKTOP=ubuntu:GNOME \
    DESKTOP_SESSION=ubuntu \
    DBUS_SESSION_BUS_ADDRESS=mock \
    HOME="${test_root}/home" \
    XDG_DATA_HOME="${test_root}/home/.local/share" \
    PATH="${test_root}/bin:${PATH}" \
    bash "${script}"
}

run_configure

[[ "$(wc -l < "${test_root}/download.log")" == 1 ]]
grep -Fq 'set org.gnome.shell.extensions.live-lockscreen background-video-path' "${test_root}/changes"
grep -Fq 'set org.gnome.shell.extensions.live-lockscreen background-video-scaling-mode 2' "${test_root}/changes"
grep -Fq 'set org.gnome.shell.extensions.live-lockscreen background-video-looped true' "${test_root}/changes"
grep -Fq 'set org.gnome.shell.extensions.live-lockscreen background-audio-volume 0' "${test_root}/changes"
grep -Fq 'set org.gnome.shell.extensions.live-lockscreen background-fade-in-duration 800' "${test_root}/changes"
grep -Fq 'set org.gnome.shell.extensions.live-lockscreen prompt-change-blur true' "${test_root}/changes"
[[ -r "${test_root}/home/.local/share/gnome-shell/live-lock-screen/clouds-101-low-altitude.webm" ]]

: > "${test_root}/changes"
run_configure
[[ "$(wc -l < "${test_root}/download.log")" == 1 ]]
[[ ! -s "${test_root}/changes" ]]

printf 'Live Lock Screen configuration checks passed\n'
