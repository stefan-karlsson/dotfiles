#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
installer="$(test_render_template 'home/.chezmoiscripts/run_onchange_before_13-install-ubuntu-snaps.sh.tmpl')"

grep -Fq '"rider|company"' "${installer}"
grep -Fq 'snapd is unavailable' "${installer}"
grep -Fq "sudo snap install \"\${snap_name}\" --classic" "${installer}"
grep -Fq "snap list \"\${snap_name}\"" "${installer}"

printf 'Ubuntu profile Snap installer tests passed\n'
