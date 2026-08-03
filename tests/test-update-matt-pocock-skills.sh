#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
updater="$(test_render_template 'home/dot_local/bin/executable_update-matt-pocock-skills.tmpl')"
test_home="${test_root}/home"

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
