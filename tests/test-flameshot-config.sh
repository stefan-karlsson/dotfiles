#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
config="$(test_render_template 'home/dot_config/flameshot/flameshot.ini.tmpl')"
grep -Fxq '[General]' "$config"
grep -Eq '^savePath=.*/Pictures/Screenshots$' "$config"
grep -Fxq 'savePathFixed=false' "$config"
grep -Fxq 'saveAsFileExtension=.png' "$config"
grep -Fxq 'filenamePattern=%F_%H-%M-%S' "$config"
grep -Fxq 'showDesktopNotification=true' "$config"
grep -Fxq 'startupLaunch=true' "$config"
grep -Fxq 'showStartupLaunchMessage=false' "$config"
