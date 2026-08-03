#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
command_script="$(test_render_template 'home/dot_local/bin/executable_install-unreal-engine')"

mkdir -p "${test_root}/home/Downloads"
test_stub_command sudo
test_stub_command xdg-open

install_unreal_engine() {
  HOME="${test_root}/home" \
    XDG_DATA_HOME="${test_root}/data" \
    test_run_script "${command_script}" "$@"
}

# Without the archive the command explains where to download it and opens the page.
if install_unreal_engine >"${test_root}/missing.out" 2>&1; then
  printf 'error: installer command accepted a missing archive\n' >&2
  exit 1
fi
grep -Fq 'Download the Unreal Engine 5.8 Linux ZIP' "${test_root}/missing.out"
test_assert_called 'xdg-open https://www.unrealengine.com/en-US/linux'

touch "${test_root}/home/Downloads/UnrealEngine-5.8.0-Linux.zip"
test_stub_command chezmoi
test_stub_command unreal-editor

test_reset_calls
install_unreal_engine --project TestProject
test_assert_called 'chezmoi apply'
test_assert_called 'unreal-editor --project TestProject'

printf 'Unreal Engine command checks passed\n'
