#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
installer="$(test_render_template 'home/.chezmoiscripts/run_onchange_after_19-install-vscode-extensions.sh.tmpl')"
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
