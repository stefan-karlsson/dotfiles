#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"

config_template='home/.chezmoi.toml.tmpl'

# The work identity is the company profile's alone. Every value is prompted for
# and recorded in the machine-local configuration.
test_assert_file_contains \
  'promptStringOnce . $profile_work_email_key "Work email for company repositories and the Atlassian CLI"' \
  "$(test_source_file "${config_template}")"
test_assert_file_contains \
  'promptStringOnce . $profile_work_gitlab_host_key "Company GitLab host"' \
  "$(test_source_file "${config_template}")"
test_assert_file_contains \
  'promptStringOnce . $profile_work_atlassian_site_key "Company Atlassian site host"' \
  "$(test_source_file "${config_template}")"

# The company profile commits under the work address inside the company
# repository tree, and authenticates to the company GitLab host through glab.
company="$(test_render_template 'home/dot_gitconfig.tmpl' company)"

test_assert_file_contains "[credential \"https://${test_work_gitlab_host}\"]" "$company"
test_assert_file_contains 'helper = !/usr/bin/glab auth git-credential' "$company"
test_assert_file_contains '[includeIf "gitdir:~/repos/gitlab/"]' "$company"
test_assert_file_contains 'path = ~/.gitconfig-work' "$company"

# The include has to sit below [user], because git applies includes where they
# appear and the later value is the one that wins.
user_line="$(grep -n '^\[user\]' "$company" | cut -d: -f1)"
include_line="$(grep -n '^\[includeIf' "$company" | cut -d: -f1)"
if ((include_line < user_line)); then
  printf 'the includeIf is above [user], so the work address would not win\n' >&2
  exit 1
fi

# GitHub keeps its own credential helpers, which the company overlay adds to
# rather than replaces.
test_assert_file_contains '[credential "https://github.com"]' "$company"
test_assert_file_contains 'helper = !/usr/bin/gh auth git-credential' "$company"

work="$(test_render_template 'home/dot_gitconfig-work.tmpl' company)"
test_assert_file_contains "email = \"${test_work_email}\"" "$work"
test_assert_file_contains '[user]' "$work"

# No other profile carries any of it. The work file renders empty, which is what
# makes chezmoi remove the target rather than leave an empty one behind.
for profile in default private "${test_no_persisted_profile}"; do
  other="$(test_render_template 'home/dot_gitconfig.tmpl' "${profile}")"
  for rule in 'glab auth git-credential' 'includeIf' '.gitconfig-work'; do
    if grep -Fq -- "${rule}" "${other}"; then
      printf 'the %s profile gitconfig carries %s\n' "${profile}" "${rule}" >&2
      exit 1
    fi
  done

  other_work="$(test_render_template 'home/dot_gitconfig-work.tmpl' "${profile}")"
  if [[ -s "${other_work}" ]]; then
    printf 'the %s profile rendered a work identity file:\n' "${profile}" >&2
    sed 's/^/  /' "${other_work}" >&2
    exit 1
  fi
done

# The work identity reaches the templates as prompted data rather than as text.
# The templated forms are what carry the host and the address, and no address
# literal appears in any of the three files.
test_assert_file_contains \
  '[credential "https://{{ $work_gitlab_host }}"]' \
  "$(test_source_file 'home/dot_gitconfig.tmpl')"
test_assert_file_contains \
  'email = {{ $work_email | quote }}' \
  "$(test_source_file 'home/dot_gitconfig-work.tmpl')"

# Every address these files set has to come from a template expression. A quoted
# value straight after `email =` is the shape a hardcoded address takes, and it is
# checked rather than the address itself, which is not in the tree to grep for.
# The GitHub SSH URL in the same file is deliberately not matched by this.
for source_path in \
  "${config_template}" \
  'home/dot_gitconfig.tmpl' \
  'home/dot_gitconfig-work.tmpl'; do
  source_file="$(test_source_file "${source_path}")"
  if grep -Eq '^[[:space:];#]*email[[:space:]]*=[[:space:]]*"' "${source_file}"; then
    printf '%s sets an address literal rather than reading prompted data\n' \
      "${source_path}" >&2
    exit 1
  fi
done
