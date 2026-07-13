#!/bin/sh

set -eu

readonly CHEZMOI_VERSION="2.71.0"
readonly DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/stefan-karlsson/dotfiles.git}"
readonly DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"
readonly SOURCE_DIR="${HOME}/.local/share/chezmoi"
readonly BIN_DIR="${HOME}/.local/bin"
readonly PROFILE_PROMPT="Which bootstrap profile should be active?"

profile_argument=""
switch_profile_argument=""

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

usage() {
  cat >&2 <<'EOF'
Usage: install.sh [--profile default|private|company]
       install.sh --switch-profile default|private|company

Without --profile, an existing installation keeps its persisted profile and a
new installation uses the default profile only. Switching an existing profile
requires --switch-profile.
EOF
}

require_valid_profile() {
  case "$1" in
    default|private|company) return 0 ;;
    *) fail "invalid profile \"$1\"; choose default, private, or company" ;;
  esac
}

parse_arguments() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --profile)
        [ "$#" -ge 2 ] || fail "--profile requires default, private, or company"
        [ -z "${profile_argument}" ] || fail "--profile was provided more than once"
        profile_argument="$2"
        shift 2
        ;;
      --switch-profile)
        [ "$#" -ge 2 ] || fail "--switch-profile requires default, private, or company"
        [ -z "${switch_profile_argument}" ] || fail "--switch-profile was provided more than once"
        switch_profile_argument="$2"
        shift 2
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        usage
        fail "unknown argument: $1"
        ;;
    esac
  done

  if [ -n "${profile_argument}" ]; then
    require_valid_profile "${profile_argument}"
  fi
  if [ -n "${switch_profile_argument}" ]; then
    require_valid_profile "${switch_profile_argument}"
  fi
  [ -z "${profile_argument}" ] || [ -z "${switch_profile_argument}" ] ||
    fail "cannot combine --profile with --switch-profile"
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
    jq \
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

    current_profile="$(persisted_profile "${chezmoi}")"
    requested_profile="${profile_argument:-${current_profile}}"
    if [ -n "${switch_profile_argument}" ]; then
      requested_profile="${switch_profile_argument}"
      [ "${requested_profile}" != "${current_profile}" ] ||
        fail "${requested_profile} is already the persisted profile; use --profile for a normal rerun"
      task "Switching bootstrap profile from ${current_profile} to ${requested_profile}"
    elif [ "${requested_profile}" != "${current_profile}" ]; then
      fail "${current_profile} is already persisted; use --switch-profile ${requested_profile} to switch profiles"
    fi

    apply_existing_profile "${chezmoi}" "${requested_profile}"
    return
  fi

  task "Initializing and applying managed dotfiles"
  requested_profile="${profile_argument:-default}"
  [ -z "${switch_profile_argument}" ] || fail "cannot switch profile before the first bootstrap"
  "${chezmoi}" init --apply --branch "${DOTFILES_BRANCH}" \
    --promptChoice "${PROFILE_PROMPT}=${requested_profile}" \
    "${DOTFILES_REPO}"
}

apply_existing_profile() {
  chezmoi="$1"
  requested_profile="$2"
  config_file="${XDG_CONFIG_HOME:-${HOME}/.config}/chezmoi/chezmoi.toml"
  backup_file="$(mktemp)"
  had_config=false

  if [ -f "${config_file}" ]; then
    cp -p "${config_file}" "${backup_file}"
    had_config=true
  fi

  restore_config() {
    if [ "${had_config}" = true ]; then
      install -m 0600 "${backup_file}" "${config_file}"
    else
      rm -f "${config_file}"
    fi
    rm -f "${backup_file}"
  }

  task "Persisting bootstrap profile ${requested_profile}"
  if ! "${chezmoi}" init --promptChoice "${PROFILE_PROMPT}=${requested_profile}"; then
    restore_config
    fail "could not persist bootstrap profile ${requested_profile}; the previous profile was restored"
  fi

  task "Applying managed dotfiles"
  if ! "${chezmoi}" apply --init; then
    restore_config
    fail "could not apply bootstrap profile ${requested_profile}; the previous profile was restored"
  fi
  rm -f "${backup_file}"
}

persisted_profile() {
  chezmoi="$1"
  data="$(${chezmoi} data --format=json 2>/dev/null || true)"
  [ -n "${data}" ] || {
    printf '%s\n' "default"
    return
  }

  profile="$(printf '%s\n' "${data}" | jq -r '.profile.name // "default"' 2>/dev/null || true)"
  case "${profile}" in
    default|private|company) ;;
    *) fail "invalid persisted profile \"${profile}\"; repair the local chezmoi configuration" ;;
  esac
  printf '%s\n' "${profile}"
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
  printf '%s\n' "- Authenticate GitHub CLI with gh auth login --web --git-protocol ssh --skip-ssh-key." >&2
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

parse_arguments "$@"
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
