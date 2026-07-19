#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=test-helpers.sh
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_setup 1 "$@"
script="$1"

mkdir -p "${test_root}/bin"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf "%s\\n" "$*" >> "$TEST_ROOT/lsof.log"' \
  'case "$*" in' \
  '  *"-iTCP:3000"*) printf "%s\\n" "$TARGET_PID" ;;' \
  '  *"-iTCP:8080"*) printf "%s\\n" "$TARGET_PID" ;;' \
  'esac' \
  > "${test_root}/bin/lsof"
chmod +x "${test_root}/bin/lsof"

sleep 30 &
target_pid=$!
trap 'kill "${target_pid}" 2>/dev/null || true; wait "${target_pid}" 2>/dev/null || true' EXIT

output="$(
  TEST_ROOT="${test_root}" \
  TARGET_PID="${target_pid}" \
  PATH="${test_root}/bin:/usr/bin:/bin" \
  bash "${script}" 3000 8080 3000
)"

[[ "${output}" == *"Stopping PID ${target_pid} (port(s): 3000, 8080)"* ]]
[[ "$(wc -l < "${test_root}/lsof.log")" == 4 ]]

if wait "${target_pid}" 2>/dev/null; then
  printf 'error: kill-port did not stop the test process\n' >&2
  exit 1
fi

no_listener_output="$(
  TEST_ROOT="${test_root}" \
  TARGET_PID="99999" \
  PATH="${test_root}/bin:/usr/bin:/bin" \
  bash "${script}" 9999
)"
[[ "${no_listener_output}" == 'No process is listening on port(s): 9999' ]]

if TEST_ROOT="${test_root}" PATH="${test_root}/bin:/usr/bin:/bin" bash "${script}" 0 > "${test_root}/invalid.out" 2>&1; then
  printf 'error: invalid port was accepted\n' >&2
  exit 1
fi
grep -Fq "invalid port '0'" "${test_root}/invalid.out"
