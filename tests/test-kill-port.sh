#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
script="$(test_render_template 'home/dot_local/bin/executable_kill-port')"

# Reports the target process as the listener on the two ports under test.
test_stub_command lsof - <<'STUB'
case "$*" in
  *"-iTCP:3000"* | *"-iTCP:8080"*) printf '%s\n' "${TARGET_PID}" ;;
esac
STUB

sleep 30 &
target_pid=$!
test_on_exit 'kill "${target_pid}" 2>/dev/null; wait "${target_pid}" 2>/dev/null'

output="$(TARGET_PID="${target_pid}" test_run_script "${script}" 3000 8080 3000)"

[[ "${output}" == *"Stopping PID ${target_pid} (port(s): 3000, 8080)"* ]]
[[ "$(grep -c '^lsof ' "${test_call_log}")" == 4 ]]

if wait "${target_pid}" 2>/dev/null; then
  printf 'error: kill-port did not stop the test process\n' >&2
  exit 1
fi

no_listener_output="$(TARGET_PID=99999 test_run_script "${script}" 9999)"
[[ "${no_listener_output}" == 'No process is listening on port(s): 9999' ]]

if test_run_script "${script}" 0 >"${test_root}/invalid.out" 2>&1; then
  printf 'error: invalid port was accepted\n' >&2
  exit 1
fi
grep -Fq "invalid port '0'" "${test_root}/invalid.out"
