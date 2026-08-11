#!/usr/bin/env bash

# SC2154: the fixture assigns the source root and temporary root.
# shellcheck disable=SC2154

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
packages="$(test_source_file 'home/.chezmoidata/packages.toml')"
config_template="$(test_source_file 'home/.chezmoi.toml.tmpl')"
installer="$(test_render_template 'home/.chezmoiscripts/run_onchange_before_10-install-ubuntu-packages.sh.tmpl' company)"
zshrc="$(test_render_template 'home/dot_zshrc.tmpl')"

# The CLI comes from Atlassian's own apt channel rather than the bare binary the
# same vendor serves from a "latest" URL, so it receives ordinary apt updates and
# its key is pinned like every other enrolled channel.
test_assert_file_contains 'https://acli.atlassian.com/linux/deb' "$installer"
test_assert_file_contains 'https://acli.atlassian.com/gpg/public-key.asc' "$installer"
test_assert_file_contains 'A99C71D268433EDC13CC885FFA73568DB7ADDBBB' "$installer"
test_assert_file_contains '/etc/apt/keyrings/acli-archive-keyring.gpg' "$installer"
test_assert_file_contains '/etc/apt/sources.list.d/acli.list' "$installer"
test_assert_file_contains '"acli|company"' "$installer"

# The unofficial jira-cli is not what this installs, under any name.
! grep -Fq 'ankitpokhrel' "$installer"
! grep -Fq 'ankitpokhrel' "$packages"

# The channel belongs to the company profile overlay, so no other profile
# enrolls it or installs the package.
for profile in default private; do
  other="$(test_render_template \
    'home/.chezmoiscripts/run_onchange_before_10-install-ubuntu-packages.sh.tmpl' "$profile")"
  if grep -Fq "\"acli|${profile}\"" "$other"; then
    printf 'the %s profile installs acli\n' "$profile" >&2
    exit 1
  fi
done

# The Developer Shell completes acli once the package is installed, and exports
# no credential of its own.
test_assert_file_contains 'acli completion zsh' "$zshrc"
! grep -Fq 'API_TOKEN' "$zshrc"

# The work identity is recorded once and asked for on the company profile alone.
# One address serves both the Atlassian CLI and commits in company repositories.
test_assert_file_contains 'promptStringOnce . $profile_work_email_key "Work email for company repositories and the Atlassian CLI"' "$config_template"

company_config="$(
  chezmoi --config /dev/null --config-format toml execute-template --init \
    --promptChoice 'Which bootstrap profile should be active?=company' \
    --promptString 'Git author name=Company User' \
    --promptString 'Git author email=user@example.com' \
    --promptString 'Huntress account key=company-account-key' \
    --promptString 'Work email for company repositories and the Atlassian CLI=company@example.invalid' \
    --promptString 'Company GitLab host=gitlab.example.invalid' \
    <"${config_template}"
)"
grep -Fq '[data.profiles.company.work]' <<<"${company_config}"
grep -Fq 'email = "company@example.invalid"' <<<"${company_config}"

# Every other profile renders without being asked for a work identity at all,
# which an unsupplied prompt would otherwise fail on.
for profile in default private; do
  other_config="$(
    chezmoi --config /dev/null --config-format toml execute-template --init \
      --promptChoice "Which bootstrap profile should be active?=${profile}" \
      --promptString 'Git author name=Test User' \
      --promptString 'Git author email=test@example.invalid' \
      <"${config_template}"
  )"
  if grep -Fq '.work]' <<<"${other_config}"; then
    printf 'the %s profile recorded a work identity\n' "${profile}" >&2
    exit 1
  fi
done

# The login command carries the managed site and account, and refuses to hold the
# token that goes with them.
login="$(test_render_template 'home/dot_local/bin/executable_jira-login.tmpl' company)"
test_assert_file_contains 'qliro.atlassian.net' "$login"
test_assert_file_contains "${test_work_email}" "$login"

test_stub_command acli ''

# A token piped in is handed to acli with the site and account filled in, and
# never as a process argument, where every other process on the machine could
# read it out of the process table.
printf 'test-token' | test_run_script "$login" >/dev/null
test_assert_called "acli jira auth login --site qliro.atlassian.net --email ${test_work_email} --token"
if grep -Fq 'test-token' "${test_call_log}"; then
  printf 'the API token was passed as an argument\n' >&2
  exit 1
fi

# Browser sign-in carries the account itself, so it names neither the site nor
# the recorded email.
test_reset_calls
test_run_script "$login" --web </dev/null >/dev/null
test_assert_called 'acli jira auth login --web'
test_assert_not_called '--site'

# Every other profile refuses outright: the CLI is not installed there.
default_login="$(test_render_template 'home/dot_local/bin/executable_jira-login.tmpl' default)"
test_reset_calls
if printf 'test-token' | test_run_script "$default_login" >"${test_root}/default.out" 2>&1; then
  printf 'the default profile signed in to the company Atlassian site\n' >&2
  exit 1
fi
grep -Fq 'belongs to the company profile' "${test_root}/default.out"
test_assert_not_called 'acli jira auth login'

printf 'Atlassian CLI checks passed\n'
