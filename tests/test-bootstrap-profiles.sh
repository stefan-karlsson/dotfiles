#!/usr/bin/env bash

# shellcheck disable=SC1091,SC2016,SC2154

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
installer="$(test_source_file 'install.sh')"
config_template="$(test_source_file 'home/.chezmoi.toml.tmpl')"
gitconfig_template="$(test_source_file 'home/dot_gitconfig.tmpl')"

if bash "${installer}" --profile unknown >"${test_root}/invalid.out" 2>&1; then
  printf 'error: an unknown profile was accepted\n' >&2
  exit 1
fi
grep -Fq 'invalid profile "unknown"' "${test_root}/invalid.out"

if bash "${installer}" --profile private --switch-profile company >"${test_root}/conflict.out" 2>&1; then
  printf 'error: conflicting profile options were accepted\n' >&2
  exit 1
fi
grep -Fq 'cannot combine --profile with --switch-profile' "${test_root}/conflict.out"

rendered_config="$({
  chezmoi --config /dev/null --config-format toml execute-template --init \
    --promptChoice 'Which bootstrap profile should be active?=private' \
    --promptString 'Git author name=Company User' \
    --promptString 'Git author email=user@example.com' \
    <"${config_template}"
})"

grep -Fq '[data.profile]' <<<"${rendered_config}"
grep -Fq 'name = "private"' <<<"${rendered_config}"
grep -Fq '[data.profiles.private.user]' <<<"${rendered_config}"
grep -Fq 'name = "Company User"' <<<"${rendered_config}"
grep -Fq 'email = "user@example.com"' <<<"${rendered_config}"
grep -Fq '$profiles := get . "profiles"' "${gitconfig_template}"
grep -Fq '$selected_profile := get $profiles $profile_name' "${gitconfig_template}"

printf 'bootstrap profile tests passed\n'
