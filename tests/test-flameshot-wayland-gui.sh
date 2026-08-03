#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
wrapper="$(test_render_template 'home/dot_local/bin/executable_flameshot-gui')"

# Reports the Qt platform the wrapper selected for it.
test_stub_command flameshot - <<'STUB'
printf 'platform=%s args=%s\n' "${QT_QPA_PLATFORM:-unset}" "$*"
STUB

wayland_output="$(XDG_SESSION_TYPE=wayland test_run_script "$wrapper" --test)"
[[ "$wayland_output" == 'platform=wayland args=gui --test' ]]

x11_output="$(XDG_SESSION_TYPE=x11 test_run_script "$wrapper" --test)"
[[ "$x11_output" == 'platform=unset args=gui --test' ]]
