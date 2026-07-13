#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=test-helpers.sh
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_setup 1 "$@"
script="$1"
export test_root

mkdir -p "${test_root}/bin"
printf '%s\n' true > "${test_root}/use-system-font"
printf '%s\n' "'Sans 11'" > "${test_root}/font-name"
printf '%s\n' "'1234'" > "${test_root}/default-profile-uuid"
printf '%s\n' "'tango'" > "${test_root}/palette"
: > "${test_root}/changes"
: > "${test_root}/fc-match.log"
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "${test_root}/bin/ptyxis"
chmod +x "${test_root}/bin/ptyxis"

gsettings() {
  local operation="$1"
  local schema="$2"
  local key="$3"
  local value="${4:-}"

  case "${operation}:${schema}:${key}" in
    get:org.gnome.Ptyxis:use-system-font)
      cat "${test_root}/use-system-font"
      ;;
    get:org.gnome.Ptyxis:font-name)
      cat "${test_root}/font-name"
      ;;
    get:org.gnome.Ptyxis:default-profile-uuid)
      cat "${test_root}/default-profile-uuid"
      ;;
    get:org.gnome.Ptyxis.Profile:*:palette)
      cat "${test_root}/palette"
      ;;
    set:org.gnome.Ptyxis:use-system-font)
      printf '%s\n' "${value}" > "${test_root}/use-system-font"
      printf 'set %s %s %s\n' "${schema}" "${key}" "${value}" >> "${test_root}/changes"
      ;;
    set:org.gnome.Ptyxis:font-name)
      printf "'%s'\n" "${value}" > "${test_root}/font-name"
      printf 'set %s %s %s\n' "${schema}" "${key}" "${value}" >> "${test_root}/changes"
      ;;
    set:org.gnome.Ptyxis.Profile:*:palette)
      printf "'%s'\n" "${value}" > "${test_root}/palette"
      printf 'set %s %s %s\n' "${schema}" "${key}" "${value}" >> "${test_root}/changes"
      ;;
    *)
      printf 'unexpected gsettings call: %s\n' "$*" >&2
      return 1
      ;;
  esac
}

fc-match() {
  printf '%s\n' "$*" >> "${test_root}/fc-match.log"
  printf '%s\n' 'FiraCode Nerd Font Mono'
}

export -f gsettings fc-match

PATH="${test_root}/bin:${PATH}" bash "${script}"
grep -Fq -- '-f %{family[0]}' "${test_root}/fc-match.log"
grep -Fq -- 'FiraCode Nerd Font Mono' "${test_root}/fc-match.log"
grep -Fxq 'set org.gnome.Ptyxis use-system-font false' "${test_root}/changes"
grep -Fxq 'set org.gnome.Ptyxis font-name FiraCode Nerd Font Mono 13' "${test_root}/changes"
grep -Fxq 'set org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/1234/ palette dracula' "${test_root}/changes"

: > "${test_root}/changes"
PATH="${test_root}/bin:${PATH}" bash "${script}"
[[ ! -s "${test_root}/changes" ]]

printf 'Ptyxis developer font checks passed\n'
