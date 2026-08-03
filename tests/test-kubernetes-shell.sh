#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
zshrc="$(test_render_template 'home/dot_zshrc.tmpl')"
p10k="$(test_render_template 'home/dot_p10k.zsh')"

test_assert_file_contains "alias k='kubectl'" "$zshrc"
test_assert_file_contains 'kubectl completion zsh' "$zshrc"
test_assert_file_contains 'compdef _kubectl k' "$zshrc"
grep -Fq 'helm completion zsh' "$zshrc"
grep -Fq "alias kx='kubectx'" "$zshrc"
grep -Fq "alias kn='kubens'" "$zshrc"
grep -Fq 'POWERLEVEL9K_CUSTOM_KUBERNETES_CONTEXT' "$p10k"
grep -Fq 'kubectl config current-context' "$p10k"
grep -Fq 'kubectl config view --minify' "$p10k"
