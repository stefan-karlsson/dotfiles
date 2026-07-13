#!/usr/bin/env bash

set -euo pipefail

[[ $# -eq 1 ]] || {
  printf 'usage: %s <rendered-zshrc>\n' "$0" >&2
  exit 2
}

zshrc="$1"
test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT

cp "$zshrc" "$test_home/.zshrc"
mkdir -p "$test_home/.local/bin"
for command_name in codex chezmoi; do
  printf '#!/usr/bin/env bash\n' > "$test_home/.local/bin/$command_name"
  chmod +x "$test_home/.local/bin/$command_name"
done
mkdir -p "$test_home/.dotnet/tools"
printf '#!/usr/bin/env bash\n' > "$test_home/.dotnet/tools/aspire"
chmod +x "$test_home/.dotnet/tools/aspire"

output="$(
  HOME="$test_home" \
  ZDOTDIR="$test_home" \
  PATH=/usr/bin:/bin \
  /usr/bin/zsh -dfic '
    source "$ZDOTDIR/.zshrc"
    command -v codex
    command -v chezmoi
    command -v aspire
  ' 2>/dev/null
)"

[[ "$output" == "$test_home/.local/bin/codex
$test_home/.local/bin/chezmoi
$test_home/.dotnet/tools/aspire" ]]
