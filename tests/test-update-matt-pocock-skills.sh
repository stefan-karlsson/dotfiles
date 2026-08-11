#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
updater="$(test_render_template 'home/dot_local/bin/executable_update-matt-pocock-skills.tmpl')"
test_home="${test_root}/home"

# The upstream collection installs the skills it still publishes and skips the
# rest; a name it does not carry simply does not arrive.
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

skills_toml="$(test_source_file 'home/.chezmoidata/matt-pocock-skills.toml')"

# Every agent reads skills from its own directory, so each configured directory
# carries a link per skill.
mapfile -t link_dirs < <(sed -n 's/^link_dirs = \[\(.*\)\]$/\1/p' "$skills_toml" |
  tr ',' '\n' | sed -n 's/^[[:space:]]*"\(.*\)"[[:space:]]*$/\1/p')
[[ ${#link_dirs[@]} -gt 0 ]] || {
  printf 'error: no link_dirs parsed from %s\n' "$skills_toml" >&2
  exit 1
}

HOME="$test_home" bash "$updater"

while IFS= read -r skill; do
  for link_dir in "${link_dirs[@]}"; do
    link="$test_home/$link_dir/$skill"
    [[ -L "$link" ]] || {
      printf 'error: expected skill link at %s\n' "$link" >&2
      exit 1
    }
    [[ "$(readlink "$link")" == "$test_home/.agents/skills/$skill" ]]
  done
done < <(find "$test_home/.agents/skills" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')

# A managed name the collection no longer publishes has to be reported, naming it,
# rather than leaving an agent link pointing at nothing.
unpublished="$(sed -n '/^names = \[$/,/^\]$/s/^  "\(.*\)",$/\1/p' "$skills_toml" | head -1)"
[[ -n "$unpublished" ]] || {
  printf 'error: no skill name parsed from %s\n' "$skills_toml" >&2
  exit 1
}
rm -rf "$test_home"
if HOME="$test_home" UNPUBLISHED_SKILL="$unpublished" bash "$updater" \
  >"${test_root}/unpublished.out" 2>&1; then
  printf 'error: a skill that never arrived was accepted\n' >&2
  exit 1
fi
grep -Fq "expected installed skill at ${test_home}/.agents/skills/${unpublished}" \
  "${test_root}/unpublished.out"
grep -Fq "${unpublished} was renamed or removed" "${test_root}/unpublished.out"
for link_dir in "${link_dirs[@]}"; do
  [[ ! -e "${test_home}/${link_dir}/${unpublished}" ]]
done
