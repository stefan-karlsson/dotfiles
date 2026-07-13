#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=test-helpers.sh
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_require_args 2 "$@"
zshrc="$1"
p10k="$2"

grep -Fq "alias k='kubectl'" "$zshrc"
grep -Fq 'kubectl completion zsh' "$zshrc"
grep -Fq 'compdef _kubectl k' "$zshrc"
grep -Fq 'helm completion zsh' "$zshrc"
grep -Fq "alias kx='kubectx'" "$zshrc"
grep -Fq "alias kn='kubens'" "$zshrc"
grep -Fq 'POWERLEVEL9K_CUSTOM_KUBERNETES_CONTEXT' "$p10k"
grep -Fq 'kubectl config current-context' "$p10k"
grep -Fq 'kubectl config view --minify' "$p10k"
