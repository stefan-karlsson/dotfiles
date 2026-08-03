#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
config="$(test_source_file 'home/dot_config/mise/config.toml')"
grep -Fq 'version = "lts"' "$config"
grep -Fq 'corepack = true' "$config"
grep -Fq '"npm:@anthropic-ai/claude-code" = { version = "latest", allow_builds = ["@anthropic-ai/claude-code"] }' "$config"
grep -Fq 'idiomatic_version_file_enable_tools = ["node"]' "$config"
