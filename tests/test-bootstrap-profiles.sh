#!/usr/bin/env bash

# shellcheck disable=SC1091,SC2154

set -euo pipefail

# shellcheck source=test-helpers.sh
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_setup 0

if bash install.sh --profile unknown >"${test_root}/invalid.out" 2>&1; then
  printf 'error: an unknown profile was accepted\n' >&2
  exit 1
fi
grep -Fq 'invalid profile "unknown"' "${test_root}/invalid.out"

if bash install.sh --profile private --switch-profile company >"${test_root}/conflict.out" 2>&1; then
  printf 'error: conflicting profile options were accepted\n' >&2
  exit 1
fi
grep -Fq 'cannot combine --profile with --switch-profile' "${test_root}/conflict.out"

rendered_config="$({
  chezmoi --config /dev/null --config-format toml execute-template --init \
    --promptChoice 'Which bootstrap profile should be active?=private' \
    --promptString 'Git author name=Company User' \
    --promptString 'Git author email=user@example.com' \
    < home/.chezmoi.toml.tmpl
})"

grep -Fq '[data.profile]' <<<"${rendered_config}"
grep -Fq 'name = "private"' <<<"${rendered_config}"
grep -Fq '[data.profiles.private.user]' <<<"${rendered_config}"
grep -Fq 'name = "Company User"' <<<"${rendered_config}"
grep -Fq 'email = "user@example.com"' <<<"${rendered_config}"
grep -Fq '$profiles := get . "profiles"' home/dot_gitconfig.tmpl
grep -Fq '$selected_profile := get $profiles $profile_name' home/dot_gitconfig.tmpl

printf 'bootstrap profile tests passed\n'
