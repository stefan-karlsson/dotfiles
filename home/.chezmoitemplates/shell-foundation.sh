fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  local command_name="$1"
  local message="${2:-${command_name} is unavailable}"

  command -v "${command_name}" >/dev/null 2>&1 || fail "${message}"
}

skip_without_command() {
  local command_name="$1"
  local message="$2"

  if ! command -v "${command_name}" >/dev/null 2>&1; then
    printf 'warning: %s\n' "${message}" >&2
    exit 0
  fi
}
