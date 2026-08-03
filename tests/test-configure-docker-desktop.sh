#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
script="$(test_render_template 'home/.chezmoiscripts/run_onchange_after_17-configure-docker-desktop.sh.tmpl')"

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
