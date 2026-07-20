#!/usr/bin/env bash

# shellcheck disable=SC1091,SC2154

set -euo pipefail

# shellcheck source=test-helpers.sh
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_setup 1 "$@"
script="$1"

export HOME="${test_root}/home"
export GPG_STATE="${test_root}/gpg-generated"
export GPG_LOG="${test_root}/gpg.log"
export PASS_LOG="${test_root}/pass.log"
mkdir -p "${HOME}"

gpg() {
  printf '%s\n' "$*" >> "${GPG_LOG}"
  if [[ "$*" == *"--generate-key"* ]]; then
    touch "${GPG_STATE}"
    return 0
  fi
  if [[ -e "${GPG_STATE}" ]]; then
    printf '%s\n' 'sec:u:3072:1:0123456789ABCDEF:1700000000::::::scESC:::'
  fi
}

pass() {
  [[ "$1" == init && "$2" == 0123456789ABCDEF ]] || {
    printf 'unexpected pass call: %s\n' "$*" >&2
    return 1
  }
  printf '%s\n' "$*" >> "${PASS_LOG}"
  mkdir -p "${PASSWORD_STORE_DIR}"
  printf '%s\n' "$2" > "${PASSWORD_STORE_DIR}/.gpg-id"
}

export -f gpg pass

run_script() {
  script --quiet --return --command "bash '${script}'" /dev/null
}

first_output="$(run_script)"
[[ "${first_output}" == *'Starting the interactive GPG key generator'* ]]
[[ "${first_output}" == *'Initializing pass for Docker Desktop with GPG key 0123456789ABCDEF'* ]]
grep -Fq -- '--generate-key' "${GPG_LOG}"
grep -Fxq -- 'init 0123456789ABCDEF' "${PASS_LOG}"
grep -Fxq -- '0123456789ABCDEF' "${HOME}/.password-store/.gpg-id"

: > "${GPG_LOG}"
: > "${PASS_LOG}"
second_output="$(run_script)"
[[ "${second_output}" == *'pass is already initialized'* ]]
[[ ! -s "${PASS_LOG}" ]]
if grep -Fq -- '--generate-key' "${GPG_LOG}"; then
  printf 'error: an existing pass store caused GPG key generation\n' >&2
  exit 1
fi

rm -rf "${HOME}/.password-store"
: > "${GPG_LOG}"
: > "${PASS_LOG}"
reuse_output="$(run_script)"
[[ "${reuse_output}" == *'Reusing existing GPG key 0123456789ABCDEF'* ]]
[[ ! -s "${GPG_LOG}" ]] || ! grep -Fq -- '--generate-key' "${GPG_LOG}"
grep -Fxq -- 'init 0123456789ABCDEF' "${PASS_LOG}"

printf 'pass initialization checks passed\n'
