#!/usr/bin/env bash

# SC2154: the fixture assigns the temporary root.
# shellcheck disable=SC2154

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"

ssh_config_template='home/private_dot_ssh/private_config.tmpl'

# The template branches on whether the 1Password agent socket exists, and reads
# it beneath the home directory, so a home of the test's own is the seam that
# chooses the branch. Only the home directory is redirected; the Bootstrap
# profile stays an argument to the fixture.
# The fixture names a rendering after its source and profile, so the two homes
# below would render over each other. Each is kept under the branch it came from.
render_ssh_config() {
  local profile="$1"
  local branch="$2"
  local home="${test_root}/home-${branch}"
  local kept="${test_root}/ssh-config-${branch}-${profile}"
  local rendered

  mkdir -p "${home}"
  if [[ "${branch}" == with-socket ]]; then
    mkdir -p "${home}/.1password"
    touch "${home}/.1password/agent.sock"
  fi
  rendered="$(HOME="${home}" test_render_template "${ssh_config_template}" "${profile}")"
  cp -- "${rendered}" "${kept}"
  printf '%s\n' "${kept}"
}

# Asks ssh what it resolves for github.com, rather than trusting that a keyword
# written into the configuration is a keyword ssh honours.
resolved_option() {
  local ssh_config="$1"
  local option="$2"

  # RequestTTY=no only keeps ssh from warning that this test is not a terminal;
  # -G resolves the configuration without connecting to anything.
  ssh -F "${ssh_config}" -o RequestTTY=no -G github.com | awk -v option="${option}" \
    '$1 == option { print $2; exit }'
}

# Which identity reaches GitHub is a safe machine default, so every profile
# resolves it the same way.
for profile in "${test_no_persisted_profile}" "${test_profiles[@]}"; do
  with_socket="$(render_ssh_config "${profile}" with-socket)"
  without_socket="$(render_ssh_config "${profile}" without-socket)"

  test_assert_file_contains 'StrictHostKeyChecking yes' "${with_socket}"
  test_assert_file_contains 'IdentityAgent ~/.1password/agent.sock' "${with_socket}"

  # IdentitiesOnly restricts ssh to the identity files the configuration names,
  # or to the default ones when it names none, even when an agent offers more.
  # Left on in the agent branch it hides the agent's key, and GitHub answers
  # publickey-denied while 1Password is unlocked and holding it.
  if grep -Eq '^[[:space:]]*IdentitiesOnly' "${with_socket}"; then
    printf 'the %s profile pins identity files while relying on the 1Password agent\n' \
      "${profile}" >&2
    exit 1
  fi
  resolved="$(resolved_option "${with_socket}" identitiesonly)"
  [[ "${resolved}" == 'no' ]] || {
    printf 'the %s profile resolves identitiesonly %s with the agent socket present\n' \
      "${profile}" "${resolved}" >&2
    exit 1
  }

  # Before 1Password is set up there is no agent to ask, so the configuration
  # falls back to a local key and pins it, which is what IdentitiesOnly is for.
  test_assert_file_contains 'IdentityFile ~/.ssh/id_ed25519' "${without_socket}"
  test_assert_file_contains 'AddKeysToAgent yes' "${without_socket}"
  test_assert_file_contains 'IdentitiesOnly yes' "${without_socket}"
  if grep -Eq '^[[:space:]]*IdentityAgent' "${without_socket}"; then
    printf 'the %s profile names an agent socket that does not exist\n' "${profile}" >&2
    exit 1
  fi
  resolved="$(resolved_option "${without_socket}" identitiesonly)"
  [[ "${resolved}" == 'yes' ]] || {
    printf 'the %s profile resolves identitiesonly %s with no agent socket\n' \
      "${profile}" "${resolved}" >&2
    exit 1
  }
done

printf 'GitHub SSH agent configuration checks passed\n'
