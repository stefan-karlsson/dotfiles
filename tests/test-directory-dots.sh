#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
zshrc="$(test_render_template 'home/dot_zshrc.tmpl')"

test_assert_file_contains 'zsh_define_parent_alias' "$zshrc"

if ! command -v zsh >/dev/null 2>&1; then
  printf 'warning: zsh is unavailable; skipped the dotted cd behaviour check\n' >&2
  exit 0
fi

# The block stands on its own, so the behaviour can be checked without starting a
# whole interactive shell. Anchored on its code rather than its comment.
block="${test_root}/parent-aliases.zsh"
sed -n '/^zsh_define_parent_alias() {/,/^unset zsh_parent_alias/p' "$zshrc" >"$block"
[[ -s "$block" ]]

deep="${test_root}/tree/a/b/c/d/e/f"
mkdir -p "$deep"

# Each further dot climbs one more level, from one up to five.
observed="$(zsh -f -c "
  source ${block@Q}
  setopt aliases
  for name in .. ... .... ..... ......; do
    ( cd ${deep@Q}; eval \"\${name}\"; print -r -- \"\${name} \${PWD##*/tree}\" )
  done
")"
read -r -d '' expected <<'EXPECTED' || true
.. /a/b/c/d/e
... /a/b/c/d
.... /a/b/c
..... /a/b
...... /a
EXPECTED
[[ "$observed" == "${expected%$'\n'}" ]] || {
  printf 'unexpected dotted cd behaviour:\n%s\n' "$observed" >&2
  exit 1
}

# A path argument is not an alias, so ../.. keeps its ordinary meaning.
observed="$(zsh -f -c "
  source ${block@Q}
  setopt aliases
  cd ${deep@Q}
  print -r -- \"\$(cd ../..; print -r -- \${PWD##*/tree})\"
")"
[[ "$observed" == '/a/b/c/d' ]]

# An alias the user already defined is left alone.
observed="$(zsh -f -c "alias -- '...=cd /'; source ${block@Q}; alias -L" | grep -F "alias ...=")"
[[ "$observed" == "alias ...='cd /'" ]] || {
  printf 'an existing alias was overwritten: %s\n' "$observed" >&2
  exit 1
}
