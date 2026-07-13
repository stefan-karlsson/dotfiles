#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=test-helpers.sh
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_require_args 1 "$@"
config="$1"
grep -Fq 'version = "lts"' "$config"
grep -Fq 'corepack = true' "$config"
grep -Fq '"npm:@anthropic-ai/claude-code" = { version = "latest", allow_builds = ["@anthropic-ai/claude-code"] }' "$config"
grep -Fq 'idiomatic_version_file_enable_tools = ["node"]' "$config"
