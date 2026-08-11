#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
script="$(test_render_template 'home/.chezmoiscripts/run_onchange_after_18-install-mise-tools.sh.tmpl')"

# mise exec -- <command> runs the command in the toolchain it manages; every other
# invocation is recorded and does nothing.
test_stub_command mise - <<'STUB'
if [[ "${1:-}" == "exec" && "${2:-}" == "--" ]]; then
  shift 2
  "$@"
fi
STUB
test_stub_command corepack ''
test_stub_command pnpm 'printf "10.24.0\n"'
test_stub_command yarn 'printf "4.12.0\n"'

output="$(test_run_script "$script")"

test_assert_called 'mise install'
test_assert_called 'corepack enable'
# The package managers must be asked for at their latest major, not left at the
# versions bundled with the Node release.
test_assert_called 'corepack install --global pnpm@latest yarn@latest'
[[ "$output" == *'pnpm 10.24.0 is available.'* ]]
[[ "$output" == *'yarn 4.12.0 is available.'* ]]

# A shim that does not answer is a failed installation, not a warning.
test_reset_calls
test_stub_command pnpm 'exit 1'
if test_run_script "$script" >"${test_root}/broken.out" 2>&1; then
  printf 'error: an unavailable package manager was accepted\n' >&2
  exit 1
fi
grep -Fq 'pnpm is unavailable after corepack installed it' "${test_root}/broken.out"
