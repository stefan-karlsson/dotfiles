#!/usr/bin/env bash

# SC2154: the fixture assigns the source root and temporary root.
# shellcheck disable=SC2154

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
packages="$(test_source_file 'home/.chezmoidata/packages.toml')"
installer="$(test_render_template 'home/.chezmoiscripts/run_onchange_before_10-install-ubuntu-packages.sh.tmpl')"
zshrc="$(test_render_template 'home/dot_zshrc.tmpl')"

# Terraform comes from HashiCorp's own apt channel, enrolled with the keyring path
# and the one-line source file HashiCorp's Linux install steps write, and its key
# is pinned like every other enrolled channel.
test_assert_file_contains 'https://apt.releases.hashicorp.com' "$installer"
test_assert_file_contains 'https://apt.releases.hashicorp.com/gpg' "$installer"
test_assert_file_contains 'D55C0D1AC78A8D8126CB631CFC9CA96ACA026560' "$installer"
test_assert_file_contains '[hashicorp]="/usr/share/keyrings/hashicorp-archive-keyring.gpg"' "$installer"
test_assert_file_contains '[hashicorp]="/etc/apt/sources.list.d/hashicorp.list"' "$installer"

# The channel is published per Ubuntu codename, and this release's codename is the
# suite the source file names.
test_assert_file_contains '[hashicorp]="resolute"' "$installer"

# The package is on the shared foundation, so every profile enrolls the channel
# and installs the same package.
test_assert_file_contains '[hashicorp]=""' "$installer"
for profile in "${test_profiles[@]}"; do
  profile_installer="$(test_render_template \
    'home/.chezmoiscripts/run_onchange_before_10-install-ubuntu-packages.sh.tmpl' "$profile")"
  test_assert_file_contains '"terraform|default"' "$profile_installer"
done

# The channel carries the current release and apt upgrades to it, so no version is
# pinned anywhere in the source state.
if grep -Eq '^terraform.*version|terraform_[0-9]' "$packages"; then
  printf 'error: the Terraform version is pinned\n' >&2
  exit 1
fi

# The Developer Shell completes terraform and the alias that stands for it once
# the package is installed.
test_assert_file_contains "alias tf='terraform'" "$zshrc"
test_assert_file_contains 'complete -o nospace -C "$(command -v terraform)" terraform tf' "$zshrc"

printf 'Terraform CLI checks passed\n'
