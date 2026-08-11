#!/usr/bin/env bash

# SC2154: the fixture assigns the source root, temporary root, and account key.
# shellcheck disable=SC2154

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"

installer_template='home/.chezmoiscripts/run_onchange_after_13-install-huntress-agent.sh.tmpl'
vendor_installer="$(test_source_file 'home/.chezmoitemplates/vendor/huntress-linux-install.sh')"

# systemd is the record of what is installed, so a unit is enabled here by the
# file the stub below reads.
enable_service() {
  mkdir -p "${test_root}/enabled"
  touch "${test_root}/enabled/$1"
}

disable_services() {
  rm -rf "${test_root}/enabled"
}

test_stub_command systemctl - <<'STUB'
if [[ "$1" == "is-enabled" ]]; then
  [[ -e "${test_root}/enabled/$2" ]]
  exit $?
fi
exit 0
STUB

# Stands in for the vendor installer running as root: it records the script and
# the keys it was handed, then enables both units the way a real registration
# does. The control files let a test make it fail, or return without installing
# anything.
test_stub_command sudo - <<'STUB'
[[ "$1" == "bash" ]] || exit 1
cp "$2" "${test_root}/handed-installer.sh"
shift 2
account_key=""
organization_key=""
while (($# > 0)); do
  case "$1" in
    -a) account_key="$2"; shift 2 ;;
    -o) organization_key="$2"; shift 2 ;;
    *) shift ;;
  esac
done
printf '%s\n' "${account_key}" >"${test_root}/handed-account-key"
printf '%s\n' "${organization_key}" >"${test_root}/handed-organization-key"
[[ ! -e "${test_root}/installer-fails" ]] || exit 1
[[ ! -e "${test_root}/installer-installs-nothing" ]] || exit 0
mkdir -p "${test_root}/enabled"
touch "${test_root}/enabled/huntress-agent" "${test_root}/enabled/huntress-updater"
STUB

# Nothing may reach the network at apply time: the installer is in the source
# state, so a fetch here would mean the wrapper went looking for another copy.
test_stub_command curl 'exit 1'
test_stub_command wget 'exit 1'

install_huntress_agent() {
  local script="$1"

  TMPDIR="${test_root}" test_run_script "${script}"
}

# The Huntress EDR agent belongs to the company profile overlay, so no other
# profile installs it and no other profile is asked for an account key.
for profile in default private "${test_no_persisted_profile}"; do
  script="$(test_render_template "${installer_template}" "${profile}")"
  test_reset_calls
  output="$(install_huntress_agent "${script}")"
  [[ -z "${output}" ]] || {
    printf 'the %s profile reported %s\n' "${profile}" "${output}" >&2
    exit 1
  }
  test_assert_not_called sudo
done

company_script="$(test_render_template "${installer_template}" company)"

# A company laptop with no agent yet: the installer runs as root, against the
# Qliro organization, with the account key the configuration recorded.
test_reset_calls
disable_services
output="$(install_huntress_agent "${company_script}")"
[[ "${output}" == *'is installed and registered with the qliro organization'* ]]
test_assert_called "-a ${test_huntress_account_key} -o qliro"
[[ "$(cat "${test_root}/handed-account-key")" == "${test_huntress_account_key}" ]]
[[ "$(cat "${test_root}/handed-organization-key")" == 'qliro' ]]
test_assert_not_called curl
test_assert_not_called wget

# What ran as root must be the installer this repository ships, not a copy
# fetched at apply time. The heredoc that carries it adds one trailing newline.
diff "${vendor_installer}" <(sed -e '$ { /^$/d }' "${test_root}/handed-installer.sh") || {
  printf 'root was handed an installer that is not the committed vendor script\n' >&2
  exit 1
}

# Registering an agent that is already registered would claim a second portal
# record for this laptop, so an existing installation is left alone.
test_reset_calls
output="$(install_huntress_agent "${company_script}")"
[[ "${output}" == *'already installed'* ]]
test_assert_not_called sudo

# An installation that only got as far as the agent is not an installation, so a
# rerun finishes it.
test_reset_calls
disable_services
enable_service huntress-agent
install_huntress_agent "${company_script}" >/dev/null
test_assert_called 'sudo bash'

# A failing installer fails the apply rather than reporting success.
test_reset_calls
disable_services
touch "${test_root}/installer-fails"
if install_huntress_agent "${company_script}" >/dev/null 2>&1; then
  printf 'a failing vendor installer was reported as a successful install\n' >&2
  exit 1
fi
rm -f "${test_root}/installer-fails"

# An installer that exits cleanly without installing the services is a failure
# too, so a silent non-installation cannot pass for a registered agent.
disable_services
touch "${test_root}/installer-installs-nothing"
if install_huntress_agent "${company_script}" >"${test_root}/silent.out" 2>&1; then
  printf 'an installer that installed nothing was reported as a successful install\n' >&2
  exit 1
fi
grep -Fq 'huntress-agent is not enabled' "${test_root}/silent.out"
rm -f "${test_root}/installer-installs-nothing"

# The account key is machine-local configuration rather than repository content,
# so a company laptop that has not recorded one is told how to record it. Only
# that key is rewritten here; the Bootstrap profile is an argument to the
# fixture, not a substitution.
keyless_script="${test_root}/keyless-installer.sh"
sed 's/^account_key=.*/account_key=""/' "${company_script}" >"${keyless_script}"
grep -Fqx 'account_key=""' "${keyless_script}"
disable_services
if install_huntress_agent "${keyless_script}" >"${test_root}/keyless.out" 2>&1; then
  printf 'a company laptop with no recorded account key was installed anyway\n' >&2
  exit 1
fi
grep -Fq 'no Huntress account key is recorded' "${test_root}/keyless.out"

# The configuration records the account key once, and asks for it on the company
# profile alone.
config_template="$(test_source_file 'home/.chezmoi.toml.tmpl')"
grep -Fq 'promptStringOnce . $profile_huntress_key "Huntress account key"' "${config_template}"

company_config="$(
  chezmoi --config /dev/null --config-format toml execute-template --init \
    --promptChoice 'Which bootstrap profile should be active?=company' \
    --promptString 'Git author name=Company User' \
    --promptString 'Git author email=user@example.com' \
    --promptString 'Huntress account key=company-account-key' \
    --promptString 'Work email for company repositories and the Atlassian CLI=company@example.invalid' \
    --promptString 'Company GitLab host=gitlab.example.invalid' \
    --promptString 'Company Atlassian site host=company.atlassian.example' \
    <"${config_template}"
)"
grep -Fq '[data.profiles.company.huntress]' <<<"${company_config}"
grep -Fq 'account_key = "company-account-key"' <<<"${company_config}"

# Every other profile renders without being asked for a key at all, which an
# unsupplied prompt would otherwise fail on.
for profile in default private; do
  other_config="$(
    chezmoi --config /dev/null --config-format toml execute-template --init \
      --promptChoice "Which bootstrap profile should be active?=${profile}" \
      --promptString 'Git author name=Test User' \
      --promptString 'Git author email=test@example.invalid' \
      <"${config_template}"
  )"
  if grep -Fq 'huntress' <<<"${other_config}"; then
    printf 'the %s profile recorded a Huntress account key\n' "${profile}" >&2
    exit 1
  fi
done

printf 'Huntress EDR agent installer checks passed\n'
