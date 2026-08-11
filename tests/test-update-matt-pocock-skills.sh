#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
updater="$(test_render_template 'home/dot_local/bin/executable_update-matt-pocock-skills.tmpl')"
test_home="${test_root}/home"

# The upstream collection installs the skills it still publishes and skips the
# rest, so a name it no longer carries simply does not arrive.
npx() {
  while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--skill" ]]; then
      shift
      [[ "$1" == "${UNPUBLISHED_SKILL:-}" ]] || mkdir -p "$HOME/.agents/skills/$1"
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

# A managed name the collection no longer publishes has to be reported, naming it,
# rather than leaving a Codex link pointing at nothing.
unpublished="$(sed -n 's/^  "\(.*\)",$/\1/p' \
  "$(test_source_file 'home/.chezmoidata/matt-pocock-skills.toml')" | head -1)"
rm -rf "$test_home"
if HOME="$test_home" UNPUBLISHED_SKILL="$unpublished" bash "$updater" \
  >"${test_root}/unpublished.out" 2>&1; then
  printf 'error: a skill that never arrived was accepted\n' >&2
  exit 1
fi
grep -Fq "expected installed skill at ${test_home}/.agents/skills/${unpublished}" \
  "${test_root}/unpublished.out"
grep -Fq "${unpublished} was renamed or removed" "${test_root}/unpublished.out"
[[ ! -e "${test_home}/.codex/skills/${unpublished}" ]]
