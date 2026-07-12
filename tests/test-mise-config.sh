#!/usr/bin/env bash

set -euo pipefail

[[ $# -eq 1 ]] || {
  printf 'usage: %s <mise-config>\n' "$0" >&2
  exit 2
}

config="$1"
grep -Fq 'version = "lts"' "$config"
grep -Fq 'corepack = true' "$config"
grep -Fq '"npm:@anthropic-ai/claude-code" = { version = "latest", allow_builds = ["@anthropic-ai/claude-code"] }' "$config"
grep -Fq 'idiomatic_version_file_enable_tools = ["node"]' "$config"
