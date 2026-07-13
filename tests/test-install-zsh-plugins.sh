#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=test-helpers.sh
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_require_args 1 "$@"
installer="$1"

test_assert_file_contains 'https://github.com/zsh-users/zsh-autosuggestions.git' "$installer"
test_assert_file_contains 'e52ee8ca55bcc56a17c828767a3f98f22a68d4eb' "$installer"
test_assert_file_contains 'https://github.com/zsh-users/zsh-syntax-highlighting.git' "$installer"
test_assert_file_contains 'db085e4661f6aafd24e5acb5b2e17e4dd5dddf3e' "$installer"
test_assert_file_contains 'https://github.com/MichaelAquilina/zsh-you-should-use.git' "$installer"
test_assert_file_contains 'ff371d6a11b653e1fa8dda4e61c896c78de26bfa' "$installer"
test_assert_file_contains 'https://github.com/fdellwing/zsh-bat.git' "$installer"
test_assert_file_contains '467337613c1c220c0d01d69b19d2892935f43e9f' "$installer"
test_assert_file_contains 'status --porcelain --untracked-files=all --ignored' "$installer"
test_assert_file_contains 'clone --depth=1 --no-checkout' "$installer"
test_assert_file_contains 'fetch --depth=1 origin' "$installer"
test_assert_file_contains 'checkout --detach --force' "$installer"

test_setup 0
plugin_root="${test_root}/home/.local/share/zsh/plugins/zsh-autosuggestions"
mkdir -p "${plugin_root}"
git -C "${plugin_root}" init --quiet
git -C "${plugin_root}" config user.email test@example.invalid
git -C "${plugin_root}" config user.name 'Zsh Plugin Test'
git -C "${plugin_root}" remote add origin https://github.com/zsh-users/zsh-autosuggestions.git
printf '*.local\n' > "${plugin_root}/.gitignore"
git -C "${plugin_root}" add .gitignore
git -C "${plugin_root}" commit --quiet -m fixture
printf 'local change\n' > "${plugin_root}/ignored.local"

if HOME="${test_root}/home" XDG_DATA_HOME="${test_root}/home/.local/share" bash "${installer}" >"${test_root}/installer.log" 2>&1; then
  printf 'expected the installer to reject an ignored local checkout change\n' >&2
  exit 1
fi
test_assert_file_contains 'has local changes' "${test_root}/installer.log"
