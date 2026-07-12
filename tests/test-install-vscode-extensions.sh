#!/usr/bin/env bash

set -euo pipefail

[[ $# -eq 1 ]] || {
  printf 'usage: %s <rendered-installer>\n' "$0" >&2
  exit 2
}

installer="$1"
grep -Fq 'hediet.vscode-drawio' "$installer"
grep -Fq 'NODE_OPTIONS' "$installer"
grep -Fq -- '--no-deprecation' "$installer"
