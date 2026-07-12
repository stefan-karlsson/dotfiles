#!/usr/bin/env bash

set -euo pipefail

[[ $# -eq 1 ]] || {
  printf 'usage: %s <rendered-config>\n' "$0" >&2
  exit 2
}

config="$1"
grep -Fxq '[General]' "$config"
grep -Eq '^savePath=.*/Pictures/Screenshots$' "$config"
grep -Fxq 'savePathFixed=false' "$config"
grep -Fxq 'saveAsFileExtension=.png' "$config"
grep -Fxq 'filenamePattern=%F_%H-%M-%S' "$config"
grep -Fxq 'showDesktopNotification=true' "$config"
grep -Fxq 'startupLaunch=true' "$config"
grep -Fxq 'showStartupLaunchMessage=false' "$config"
