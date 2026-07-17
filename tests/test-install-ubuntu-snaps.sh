#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_require_args 1 "$@"
installer="$1"

grep -Fq '"rider|company"' "${installer}"
grep -Fq 'snapd is unavailable' "${installer}"
grep -Fq "sudo snap install \"\${snap_name}\" --classic" "${installer}"
grep -Fq "snap list \"\${snap_name}\"" "${installer}"

printf 'Ubuntu profile Snap installer tests passed\n'
