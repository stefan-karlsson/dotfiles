#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=test-helpers.sh
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_require_args 1 "$@"
zshrc="$1"
test_setup 0

plugin_root="$test_root/home/.local/share/zsh/plugins"
mkdir -p "$plugin_root"/{zsh-autosuggestions,zsh-syntax-highlighting,you-should-use,zsh-bat} "$test_root/bin"
cp "$zshrc" "$test_root/home/.zshrc"

printf '%s\n' 'zsh_autosuggestions_loaded=1' > "$plugin_root/zsh-autosuggestions/zsh-autosuggestions.zsh"
printf '%s\n' '_zsh_highlight() { :; }' > "$plugin_root/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
printf '%s\n' 'you_should_use_loaded=1' > "$plugin_root/you-should-use/you-should-use.plugin.zsh"
cat > "$plugin_root/zsh-bat/zsh-bat.plugin.zsh" <<'EOF'
if command -v batcat >/dev/null 2>&1; then
  alias rcat="$(which cat)"
  alias cat="$(which batcat)"
fi
EOF

printf '#!/usr/bin/env bash\n' > "$test_root/bin/batcat"
chmod +x "$test_root/bin/batcat"

output="$({
  HOME="$test_root/home" \
  ZDOTDIR="$test_root/home" \
  XDG_DATA_HOME="$test_root/home/.local/share" \
  PATH="$test_root/bin:/usr/bin:/bin" \
  /usr/bin/zsh -dfic '
    alias ga=existing
    source "$ZDOTDIR/.zshrc"
    print -r -- "${aliases[g]}"
    print -r -- "${aliases[ga]}"
    print -r -- "${aliases[cat]}"
    print -r -- "$zsh_autosuggestions_loaded"
    print -r -- "$you_should_use_loaded"
    (( $+functions[_zsh_highlight] )) && print -r -- syntax-highlighting-loaded
  '
} 2>/dev/null)"

expected="git
existing
$test_root/bin/batcat
1
1
syntax-highlighting-loaded"
[[ "$output" == "$expected" ]] || {
  printf 'unexpected Zsh plugin integration output:\n%s\n' "$output" >&2
  exit 1
}

test_assert_file_contains 'zsh_plugin_source "zsh-autosuggestions" "zsh-autosuggestions.zsh"' "$zshrc"
test_assert_file_contains 'zsh_plugin_source "zsh-syntax-highlighting" "zsh-syntax-highlighting.zsh"' "$zshrc"
test_assert_file_contains 'git push --set-upstream origin' "$zshrc"
test_assert_file_contains 'defaultBranch = main' home/dot_gitconfig.tmpl

noninteractive_output="$({
  HOME="${test_root}/home" \
  ZDOTDIR="${test_root}/home" \
  XDG_DATA_HOME="${test_root}/home/.local/share" \
  PATH="${test_root}/bin:/usr/bin:/bin" \
  /usr/bin/zsh -dfc '
    source "$ZDOTDIR/.zshrc"
    (( $+functions[_zsh_highlight] || $+functions[ysu_message] )) && exit 1
    print -r -- noninteractive-shell-preserved
  '
} 2>/dev/null)"
[[ "$noninteractive_output" == noninteractive-shell-preserved ]]

missing_plugin_home="${test_root}/missing-plugin-home"
mkdir -p "${missing_plugin_home}"
cp "$zshrc" "$missing_plugin_home/.zshrc"
missing_plugin_output="$({
  HOME="${missing_plugin_home}" \
  ZDOTDIR="${missing_plugin_home}" \
  XDG_DATA_HOME="${missing_plugin_home}/.local/share" \
  PATH="/usr/bin:/bin" \
  /usr/bin/zsh -dfic '
    source "$ZDOTDIR/.zshrc"
    print -r -- missing-plugin-shell-preserved
  '
} 2>/dev/null)"
[[ "$missing_plugin_output" == missing-plugin-shell-preserved ]]
