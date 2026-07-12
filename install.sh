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

task() {
  printf '\n==> %s\n' "$*" >&2
}

info() {
  printf '%s\n' "$*" >&2
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

  task "Installing bootstrap prerequisites"
  sudo apt-get update
  sudo env DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
    ca-certificates \
    curl \
    git \
    gpg \
    nodejs \
    npm \
    openssh-client \
    wget
}

install_chezmoi() {
  task "Installing chezmoi ${CHEZMOI_VERSION}"
  mkdir -p "${BIN_DIR}"
  download https://get.chezmoi.io | sh -s -- -b "${BIN_DIR}" -t "v${CHEZMOI_VERSION}"
}

update_or_initialize() {
  chezmoi="${BIN_DIR}/chezmoi"

  if [ -e "${SOURCE_DIR}" ]; then
    task "Updating existing dotfiles source state"
    [ -d "${SOURCE_DIR}/.git" ] || fail "existing source path is not a Git repository: ${SOURCE_DIR}"
    status="$(git -C "${SOURCE_DIR}" status --porcelain)" || fail "cannot inspect source repository"
    [ -z "${status}" ] || fail "source repository has uncommitted changes; resolve them before bootstrapping"

    git -C "${SOURCE_DIR}" fetch --quiet origin "${DOTFILES_BRANCH}"
    git -C "${SOURCE_DIR}" merge --ff-only "origin/${DOTFILES_BRANCH}"
    task "Applying managed dotfiles"
    "${chezmoi}" apply --init
    return
  fi

  task "Initializing and applying managed dotfiles"
  "${chezmoi}" init --apply --branch "${DOTFILES_BRANCH}" "${DOTFILES_REPO}"
}

configure_zsh_account_shell() {
  login_user="$(id -un)"
  zsh_path="$(command -v zsh || true)"
  [ -n "${zsh_path}" ] || fail "zsh was not installed by the dotfiles apply step"

  current_shell="$(getent passwd "${login_user}" | cut -d: -f7)"
  [ -n "${current_shell}" ] || fail "cannot determine the account shell for ${login_user}"

  if [ "${current_shell}" = "${zsh_path}" ]; then
    info "Zsh is already the account shell for ${login_user}."
    return
  fi

  task "Setting Zsh as the account shell for ${login_user}"
  sudo chsh -s "${zsh_path}" "${login_user}"
}

print_next_steps() {
  printf '\nBootstrap complete.\n' >&2
  printf '%s\n' "- Sign out and back in to start new terminals in Zsh." >&2
  printf '%s\n' "- Sign in to 1Password, enable CLI integration and the SSH agent, then run verify-1password-setup." >&2
  printf '%s\n' "- Configure your GitHub SSH key using ${SOURCE_DIR}/README.md." >&2
}

start_developer_shell() {
  if [ ! -t 0 ] || [ ! -t 1 ]; then
    info "Start a new terminal session to enter the Developer Shell."
    return
  fi

  task "Starting the Developer Shell"
  zsh_path="$(command -v zsh)" || fail "zsh is unavailable after bootstrap"
  exec "${zsh_path}" -l
}

require_ubuntu_2604
task "Preparing the Ubuntu 26.04 developer workstation"
info "You may be prompted for your sudo password to install packages and set Zsh as your account shell."
install_prerequisites
install_chezmoi
export PATH="${BIN_DIR}:${PATH}"
update_or_initialize
configure_zsh_account_shell
print_next_steps
start_developer_shell
