#!/usr/bin/env bash

# SC2154: the fixture assigns the temporary root.
# shellcheck disable=SC2154

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"

# A throwaway repository whose only remote is the HTTPS URL the bootstrap clones
# with, plus one remote that is not GitHub at all.
repository="${test_root}/repository"
git init -q "${repository}"
git -C "${repository}" remote add origin https://github.com/stefan-karlsson/dotfiles.git
git -C "${repository}" remote add elsewhere https://gitlab.com/example/thing.git

# Asks git itself which URL an operation uses, rather than trusting that a
# rewrite written into the configuration is a rewrite git applies. The system
# configuration is excluded so a host of its own cannot answer for it.
remote_url() {
  local gitconfig="$1"
  local remote="$2"
  shift 2

  GIT_CONFIG_GLOBAL="${gitconfig}" GIT_CONFIG_SYSTEM=/dev/null \
    git -C "${repository}" remote get-url "$@" "${remote}"
}

# GitHub transport is a safe machine default rather than a profile overlay, so
# every machine gets it: reads over HTTPS, writes over SSH.
for profile in "${test_no_persisted_profile}" "${test_profiles[@]}"; do
  gitconfig="$(test_render_template 'home/dot_gitconfig.tmpl' "${profile}")"

  # Reads stay on HTTPS, so a clone or fetch needs no key and no unlocked
  # 1Password. The bootstrap clones this way before 1Password is ever set up.
  fetch_url="$(remote_url "${gitconfig}" origin)"
  [[ "${fetch_url}" == 'https://github.com/stefan-karlsson/dotfiles.git' ]] || {
    printf 'the %s profile fetches from %s rather than over HTTPS\n' \
      "${profile}" "${fetch_url}" >&2
    exit 1
  }

  # Writes are rewritten to SSH, so they authenticate through the 1Password SSH
  # agent without the remote being rewritten on each machine.
  push_url="$(remote_url "${gitconfig}" --push origin)"
  [[ "${push_url}" == 'git@github.com:stefan-karlsson/dotfiles.git' ]] || {
    printf 'the %s profile pushes to %s rather than over SSH\n' \
      "${profile}" "${push_url}" >&2
    exit 1
  }

  # The rewrite is scoped to GitHub; it must not claim every forge.
  other_push_url="$(remote_url "${gitconfig}" --push elsewhere)"
  [[ "${other_push_url}" == 'https://gitlab.com/example/thing.git' ]] || {
    printf 'the %s profile rewrote a non-GitHub push URL to %s\n' \
      "${profile}" "${other_push_url}" >&2
    exit 1
  }

  # A plain insteadOf would drag reads onto SSH too, which is the failure this
  # configuration exists to avoid.
  if grep -Eq '^[[:space:]]*insteadOf' "${gitconfig}"; then
    printf 'the %s profile rewrites GitHub reads to SSH as well as writes\n' \
      "${profile}" >&2
    exit 1
  fi

  # HTTPS reads of a private repository still need a credential, and gh is what
  # supplies it.
  test_assert_file_contains 'helper = !/usr/bin/gh auth git-credential' "${gitconfig}"
done

printf 'GitHub transport checks passed\n'
