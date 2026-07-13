require_gnome_session() {
  case ":${XDG_CURRENT_DESKTOP:-}${DESKTOP_SESSION:-}": in
    *[Gg][Nn][Oo][Mm][Ee]*) ;;
    *) exit 0 ;;
  esac
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
