#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=test-helpers.sh
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_require_args 1 "$@"
installer="$1"
grep -Fq 'hediet.vscode-drawio' "$installer"
grep -Fq 'dracula-theme.theme-dracula' "$installer"
grep -Fq 'NODE_OPTIONS' "$installer"
grep -Fq -- '--no-deprecation' "$installer"
