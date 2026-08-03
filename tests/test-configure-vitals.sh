#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
script="$(test_render_template 'home/.chezmoiscripts/run_always_after_28-configure-vitals.sh.tmpl')"

extension_dir="${test_root}/home/.local/share/gnome-shell/extensions/Vitals@CoreCoding.com"
mkdir -p "${extension_dir}/schemas"
printf '%s\n' "['_memory_usage_']" >"${test_root}/hot-sensors"
printf '%s\n' '1' >"${test_root}/position-in-panel"

# Vitals ships its own schema, so every call must carry the extension's schema
# directory. Each preference is backed by one file.
export EXPECTED_SCHEMA_DIR="${extension_dir}/schemas"
test_stub_command gsettings - <<'STUB'
[[ "${GSETTINGS_SCHEMA_DIR:-}" == "${EXPECTED_SCHEMA_DIR}" ]] || {
  printf 'unexpected GSETTINGS_SCHEMA_DIR: %s\n' "${GSETTINGS_SCHEMA_DIR:-}" >&2
  exit 1
}
[[ "$2" == org.gnome.shell.extensions.vitals ]] || {
  printf 'unexpected schema: %s\n' "$2" >&2
  exit 1
}
[[ -f "${test_root}/$3" ]] || {
  printf 'unexpected key: %s\n' "$3" >&2
  exit 1
}
case "$1" in
  writable) exit 0 ;;
  get) cat "${test_root}/$3" ;;
  set) printf '%s\n' "$4" >"${test_root}/$3" ;;
  *) printf 'unexpected gsettings operation: %s\n' "$*" >&2; exit 1 ;;
esac
STUB

configure_vitals() {
  test_reset_calls
  XDG_CURRENT_DESKTOP=ubuntu:GNOME \
    DESKTOP_SESSION=ubuntu \
    DBUS_SESSION_BUS_ADDRESS=mock \
    HOME="${test_root}/home" \
    test_run_script "${script}"
}

configure_vitals

test_assert_called "gsettings set org.gnome.shell.extensions.vitals hot-sensors ['_memory_usage_', '_processor_usage_', '__network-rx_max__', '__temperature_avg__']"
test_assert_called 'gsettings set org.gnome.shell.extensions.vitals position-in-panel 2'

# Already configured: the script compares before it writes.
configure_vitals
test_assert_not_called 'gsettings set'

printf 'Vitals configuration checks passed\n'
