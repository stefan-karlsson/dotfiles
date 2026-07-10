#!/bin/sh

set -eu

readonly CHEZMOI_VERSION="2.71.0"
readonly DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/stefan-karlsson/dotfiles.git}"
readonly DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"
readonly SOURCE_DIR="${HOME}/.local/share/chezmoi"
readonly BIN_DIR="${HOME}/.local/bin"

fail() {
  printf '%s\n' "error: $*" >&2
  exit 1
}

download() {
  url="$1"

  if command -v curl >/dev/null 2>&1; then
    curl -fsLS "${url}"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "${url}"
  else
    fail "curl or wget is required to start the bootstrap"
  fi
}

require_ubuntu_2604() {
  [ -r /etc/os-release ] || fail "cannot identify the operating system"
  # shellcheck disable=SC1091
  . /etc/os-release
  [ "${ID:-}" = "ubuntu" ] || fail "this bootstrap supports Ubuntu only"
  [ "${VERSION_ID:-}" = "26.04" ] || fail "this bootstrap supports Ubuntu 26.04 only"
}

install_prerequisites() {
  command -v sudo >/dev/null 2>&1 || fail "sudo is required to install Ubuntu packages"

  sudo apt-get update
  sudo env DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
    ca-certificates \
    curl \
    git \
    openssh-client \
    wget
}

install_chezmoi() {
  mkdir -p "${BIN_DIR}"
  download https://get.chezmoi.io | sh -s -- -b "${BIN_DIR}" -t "v${CHEZMOI_VERSION}"
}

update_or_initialize() {
  chezmoi="${BIN_DIR}/chezmoi"

  if [ -e "${SOURCE_DIR}" ]; then
    [ -d "${SOURCE_DIR}/.git" ] || fail "existing source path is not a Git repository: ${SOURCE_DIR}"
    status="$(git -C "${SOURCE_DIR}" status --porcelain)" || fail "cannot inspect source repository"
    [ -z "${status}" ] || fail "source repository has uncommitted changes; resolve them before bootstrapping"

    git -C "${SOURCE_DIR}" fetch --quiet origin "${DOTFILES_BRANCH}"
    git -C "${SOURCE_DIR}" merge --ff-only "origin/${DOTFILES_BRANCH}"
    "${chezmoi}" apply --init
    return
  fi

  "${chezmoi}" init --apply --branch "${DOTFILES_BRANCH}" "${DOTFILES_REPO}"
}

require_ubuntu_2604
install_prerequisites
install_chezmoi
export PATH="${BIN_DIR}:${PATH}"
update_or_initialize
