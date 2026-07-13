#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=test-helpers.sh
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_require_args 1 "$@"
config="$1"
grep -Fxq '[General]' "$config"
grep -Eq '^savePath=.*/Pictures/Screenshots$' "$config"
grep -Fxq 'savePathFixed=false' "$config"
grep -Fxq 'saveAsFileExtension=.png' "$config"
grep -Fxq 'filenamePattern=%F_%H-%M-%S' "$config"
grep -Fxq 'showDesktopNotification=true' "$config"
grep -Fxq 'startupLaunch=true' "$config"
grep -Fxq 'showStartupLaunchMessage=false' "$config"
