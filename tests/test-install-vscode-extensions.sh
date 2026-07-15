#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=test-helpers.sh
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_require_args 1 "$@"
installer="$1"
grep -Fq 'hediet.vscode-drawio' "$installer"
grep -Fq 'anthropic.claude-code' "$installer"
grep -Fq 'microsoft-aspire.aspire-vscode' "$installer"
grep -Fq 'bruno-api-client.bruno' "$installer"
grep -Fq 'ms-vscode.cpptools-extension-pack' "$installer"
grep -Fq 'ms-dotnettools.csdevkit' "$installer"
grep -Fq 'dracula-theme.theme-dracula' "$installer"
grep -Fq 'openai.chatgpt' "$installer"
grep -Fq 'NODE_OPTIONS' "$installer"
grep -Fq -- '--no-deprecation' "$installer"
