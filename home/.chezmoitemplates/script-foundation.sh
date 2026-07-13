fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  local command_name="$1"
  local message="${2:-${command_name} is unavailable}"

  command -v "${command_name}" >/dev/null 2>&1 || fail "${message}"
}

require_gnome_session() {
  case ":${XDG_CURRENT_DESKTOP:-}${DESKTOP_SESSION:-}": in
    *[Gg][Nn][Oo][Mm][Ee]*) ;;
    *) exit 0 ;;
  esac
}

skip_without_command() {
  local command_name="$1"
  local message="$2"

  if ! command -v "${command_name}" >/dev/null 2>&1; then
    printf 'warning: %s\n' "${message}" >&2
    exit 0
  fi
}

set_gsetting_if_changed() {
  local schema="$1"
  local key="$2"
  local value="$3"
  local expected="$4"

  if [[ "$(gsettings get "${schema}" "${key}")" != "${expected}" ]]; then
    gsettings set "${schema}" "${key}" "${value}"
  fi
}
