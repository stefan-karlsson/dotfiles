#!/usr/bin/env bash

set -euo pipefail

[[ $# -eq 1 ]] || {
  printf 'usage: %s <rendered-updater>\n' "$0" >&2
  exit 2
}

updater="$1"
test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT

npx() {
  while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--skill" ]]; then
      shift
      mkdir -p "$HOME/.agents/skills/$1"
    fi
    shift
  done
}
export -f npx

HOME="$test_home" bash "$updater"

while IFS= read -r skill; do
  link="$test_home/.codex/skills/$skill"
  [[ -L "$link" ]] || {
    printf 'error: expected Codex skill link at %s\n' "$link" >&2
    exit 1
  }
  [[ "$(readlink "$link")" == "$test_home/.agents/skills/$skill" ]]
done < <(find "$test_home/.agents/skills" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
