#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=test-helpers.sh
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_setup 1 "$@"
script="$1"

systemctl() {
  [[ "$*" == "--user enable docker-desktop.service" ]] || {
    printf 'unexpected systemctl call: %s\n' "$*" >&2
    return 1
  }
  printf '%s\n' "$*" >> "${SYSTEMCTL_LOG}"
}
export SYSTEMCTL_LOG="${test_root}/systemctl.log"
export -f systemctl

output="$(bash "${script}")"
[[ "${output}" == *'Docker Desktop is enabled to start on sign-in'* ]]
grep -Fxq -- '--user enable docker-desktop.service' "${test_root}/systemctl.log"

printf 'Docker Desktop configuration checks passed\n'
