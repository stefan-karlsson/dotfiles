#!/bin/bash

# This script must exit as fast as possible when pre-requisites are already
# met, so we only import the scripts-library when we really need it.

set -eu

is_universe_repository_added() {
  # Check if 'universe' is present in the sources list
  grep -q "universe" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null
}

wanted_packages=(
  gpg # used to decrypt the gpg keys of the apt repositories
  libfuse2t64             # !! Requried for installing DynamoDB NoSQL Workbench, remove when not needed as it has security issues
)

missing_packages=()

for package in "${wanted_packages[@]}"; do
  if ! command -v "${package}" >/dev/null; then
    missing_packages+=("${package}")
  fi
done

if [[ ${#missing_packages[@]} -eq 0 ]]; then
  exit 0
fi

# shellcheck source=../.chezmoitemplates/scripts-library
source "${CHEZMOI_SOURCE_DIR?}/.chezmoitemplates/scripts-library"

if ! is_universe_repository_added; then
  log_task "Adding universe APT repository"
  c sudo add-apt-repository universe -y
fi

log_task "Installing missing pre-requisites with APT: ${missing_packages[*]}"
c apt update
c env DEBIAN_FRONTEND=noninteractive apt install --yes --no-install-recommends "${missing_packages[@]}"
