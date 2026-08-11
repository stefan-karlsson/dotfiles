#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
installer="$(test_render_template 'home/.chezmoiscripts/run_onchange_before_10-install-ubuntu-packages.sh.tmpl')"

grep -Fq '"pass|default"' "$installer"
grep -Fq '"flameshot|default"' "$installer"
grep -Fq '"bruno|default"' "$installer"
grep -Fq '"build-essential|default"' "$installer"
grep -Fq '"clang-20|default"' "$installer"
grep -Fq '"cmake|default"' "$installer"
grep -Fq '"lld-20|default"' "$installer"
grep -Fq '"ninja-build|default"' "$installer"
grep -Fq '"libvulkan-dev|default"' "$installer"
grep -Fq '"vulkan-tools|default"' "$installer"
grep -Fq '"qt6-wayland|default"' "$installer"
grep -Fq '"dotnet-sdk-10.0|default"' "$installer"
grep -Fq '"tmux|default"' "$installer"
grep -Fq '"wl-clipboard|default"' "$installer"
grep -Fq '"snapd|company"' "$installer"
grep -Fq '"forticlient|company"' "$installer"
grep -Fq '"spotify"' "$installer"
grep -Fq '"mise"' "$installer"
grep -Fq '"docker-ce|default"' "$installer"
grep -Fq '"docker-compose-plugin|default"' "$installer"
grep -Fq '"kubectl|default"' "$installer"
grep -Fq '"helm|default"' "$installer"
grep -Fq '"kubectx|default"' "$installer"
grep -Fq 'https://download.docker.com/linux/ubuntu' "$installer"
grep -Fq 'https://pkgs.k8s.io/core:/stable:/v1.36/deb/' "$installer"
grep -Fq 'https://packages.buildkite.com/helm-linux/helm-debian/any/' "$installer"
grep -Fq 'http://debian.usebruno.com/' "$installer"
# FortiClient is pinned to the branch the company EMS manages, and the branch it
# was moved off is kept so an apply can replace what that branch installed.
grep -Fq 'https://repo.fortinet.com/repo/forticlient/7.2/ubuntu/' "$installer"
grep -Fq '[forticlient]="https://repo.fortinet.com/repo/forticlient/8.0/ubuntu/"' "$installer"
grep -Fq 'remove_superseded_repository_packages' "$installer"

# The Intune Portal and the Edge it depends on belong to the company laptop only.
grep -Fq '"intune-portal|company"' "$installer"
grep -Fq '"microsoft-edge-stable|company"' "$installer"
grep -Fq '[microsoft_prod]="company"' "$installer"
grep -Fq '[microsoft_edge]="company"' "$installer"
grep -Fq 'https://packages.microsoft.com/ubuntu/26.04/prod' "$installer"
# Edge's own postinstall script rewrites its source file on every upgrade, so the
# channel and keyring enrolled here are the ones that script writes.
grep -Fq 'https://packages.microsoft.com/repos/edge-stable' "$installer"
grep -Fq '[microsoft_edge]="https://packages.microsoft.com/repos/edge"' "$installer"
# Microsoft signs this Ubuntu release with its 2025 key and the Edge channel with
# the legacy one, so the two channels must not share a keyring.
grep -Fq '[microsoft_prod]="/usr/share/keyrings/microsoft-2025.gpg"' "$installer"
grep -Fq 'AA86F75E427A19DD33346403EE4D7792F748182B' "$installer"
grep -Fq '[microsoft_edge]="/usr/share/keyrings/microsoft-edge.gpg"' "$installer"
# Microsoft's Ubuntu channel also carries kubectl, so either enrolled channel may
# supply it, and the apt pin that briefly held it to one of them is removed.
grep -Fq '[kubernetes]="true"' "$installer"
grep -Fq '[kubernetes]="/etc/apt/preferences.d/kubernetes.pref"' "$installer"
# Microsoft's own installer, and Edge's postinstall script, enroll these channels
# as .list files that apt would otherwise read alongside the managed sources.
grep -Fq '[microsoft_prod]="/etc/apt/sources.list.d/microsoft-prod.list"' "$installer"
grep -Fq '[microsoft_edge]="/etc/apt/sources.list.d/microsoft-edge.list"' "$installer"
if grep -Fq '"nodejs"' "$installer" || grep -Fq '"npm"' "$installer"; then
  printf 'error: system Node packages must be managed through mise\n' >&2
  exit 1
fi

mkdir -p "$test_root/etc/apt/sources.list.d"
printf 'ID=ubuntu\nVERSION_ID=26.04\n' > "$test_root/os-release"
printf '%s\n' \
  'Types: deb' \
  'URIs: https://downloads.1password.com/linux/debian/amd64' \
  'Suites: stable' \
  'Components: main' \
  'Architectures: amd64' \
  'Signed-By: /usr/share/keyrings/1password-archive-keyring.gpg' \
  > "$test_root/etc/apt/sources.list.d/1password.sources"
printf '%s\n' \
  'deb [arch=amd64 signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main' \
  > "$test_root/etc/apt/sources.list.d/github-cli.list"
touch "$test_root/vscode-stable" "$test_root/google-chrome-stable" "$test_root/github-cli-stable" "$test_root/mise-stable"

preflight="$test_root/preflight.sh"
sed \
  -e "s|/etc/os-release|$test_root/os-release|g" \
  -e "s|/etc/apt/sources.list.d/vscode.sources|$test_root/etc/apt/sources.list.d/vscode.sources|" \
  -e "s|/etc/apt/sources.list.d/google-chrome.sources|$test_root/etc/apt/sources.list.d/google-chrome.sources|" \
  -e "s|/etc/apt/sources.list.d/github-cli.list|$test_root/etc/apt/sources.list.d/github-cli.list|" \
  -e "s|/etc/apt/sources.list.d/1password.sources|$test_root/etc/apt/sources.list.d/1password.sources|" \
  -e "s|/var/lib/chezmoi/vscode-stable|$test_root/vscode-stable|" \
  -e "s|/var/lib/chezmoi/google-chrome-stable|$test_root/google-chrome-stable|" \
  -e "s|/var/lib/chezmoi/github-cli-stable|$test_root/github-cli-stable|" \
  -e "s|/var/lib/chezmoi/1password-stable|$test_root/1password-stable|" \
  -e "s|/var/lib/chezmoi/mise-stable|$test_root/mise-stable|" \
  "$installer" | sed -n '1,/^repository_prerequisites=()/p' > "$preflight"

mkdir -p "$test_root/bin"
for command_name in cat sed awk dpkg; do
  ln -s "$(command -v "$command_name")" "$test_root/bin/$command_name"
done
preflight_shell="$(command -v bash)"
run_preflight() {
  PATH="$test_root/bin" "$preflight_shell" "$preflight"
}

dpkg() {
  if [[ "$*" == "--print-architecture" ]]; then
    printf 'amd64\n'
  elif [[ "$1" == "--compare-versions" ]]; then
    command dpkg "$@"
  elif [[ "$*" == "--configure --pending" ]]; then
    printf '%s\n' "$*" >> "$test_root/dpkg.log"
    ONEPASSWORD_STATUS=installed
  fi
}
sudo() {
  "$@"
}
env() {
  while [[ "${1:-}" == *=* ]]; do
    shift
  done
  "$@"
}
dpkg-query() {
  if [[ "$1" == "-S" ]]; then
    case "$2" in
      code|/usr/bin/code) printf 'code: %s\n' "$2" ;;
      google-chrome|/usr/bin/google-chrome) printf 'google-chrome-stable: %s\n' "$2" ;;
      onepassword|/usr/bin/1password|/opt/1Password/1password) printf '1password: %s\n' "$2" ;;
      op|/usr/bin/op) printf '1password-cli: %s\n' "$2" ;;
      gh|/usr/bin/gh) printf 'gh: %s\n' "$2" ;;
      mise|/usr/bin/mise) printf 'mise: %s\n' "$2" ;;
      *) return 1 ;;
    esac
    return
  fi
  case "${*: -1}" in
    1password)
      if [[ "$*" == *'${Version}'* ]]; then
        printf '8.12.26\n'
      else
        printf '%s\n' "${ONEPASSWORD_STATUS:-installed}"
      fi
      ;;
    code|google-chrome-stable|gh|mise|1password-cli)
      if [[ "$*" == *'${Version}'* ]]; then
        printf '8.12.26\n'
      else
        printf 'installed\n'
      fi
      ;;
    *)
      return 1
      ;;
  esac
}
apt-cache() {
  package="${*: -1}"
  case "${package}" in
    code) origin="https://packages.microsoft.com/repos/code" ;;
    google-chrome-stable) origin="https://dl.google.com/linux/chrome-stable/deb/" ;;
    gh) origin="https://cli.github.com/packages" ;;
    mise) origin="https://mise.jdx.dev/deb" ;;
    1password|1password-cli) origin="https://downloads.1password.com/linux/debian/amd64" ;;
    *) origin="${APT_ORIGIN:-https://downloads.1password.com/linux/debian/amd64}" ;;
  esac
  printf '%s | 8.12.26 | %s stable/main amd64 Packages\n' \
    "$package" "${APT_ORIGIN:-$origin}"
}
snap() {
  return 1
}
flatpak() {
  return 1
}
onepassword() {
  :
}
op() {
  :
}
readlink() {
  case "$*" in
    -f\ code) printf '/usr/bin/code\n' ;;
    -f\ google-chrome) printf '/usr/bin/google-chrome\n' ;;
    -f\ gh) printf '/usr/bin/gh\n' ;;
    *1password) printf '/opt/1Password/1password\n' ;;
    -f\ op|*/usr/bin/op) printf '/usr/bin/op\n' ;;
    *) command readlink "$@" ;;
  esac
}
code() {
  :
}
google-chrome() {
  :
}
gh() {
  :
}
# These stay shell functions rather than fixture command stubs: several of them
# delegate to the real command with `command dpkg "$@"`, which a stub of the same
# name on PATH cannot do without calling itself, and the preflight run below
# depends on a function outranking the PATH entry it shadows.
export -f dpkg dpkg-query apt-cache snap flatpak onepassword op readlink code google-chrome gh \
  sudo env

output="$(run_preflight)"
[[ "$output" == *"Adopting the existing official 1Password Stable apt installation"* ]]

sed -i 's/^Types: deb/# Types: deb/' "$test_root/etc/apt/sources.list.d/1password.sources"
commented_output="$(run_preflight)"
[[ "$commented_output" == *"Adopting the existing official 1Password Stable apt installation"* ]]

if APT_ORIGIN="https://packages.example.invalid" run_preflight >"$test_root/conflicting.out" 2>&1; then
  printf 'error: conflicting 1Password package origin was accepted\n' >&2
  exit 1
fi
grep -Fq 'is unavailable from the official stable repository' "$test_root/conflicting.out"

# A bootstrap that failed while dpkg configured 1Password leaves the desktop
# command on PATH with the package unpacked but not installed. A rerun finishes
# that dpkg run instead of rejecting the command it left behind.
ln -s /bin/true "$test_root/bin/1password"
interrupted_output="$(ONEPASSWORD_STATUS=half-configured run_preflight)"
[[ "$interrupted_output" == *"Completing the interrupted installation of 1password"* ]]
test_assert_file_contains '--configure --pending' "$test_root/dpkg.log"

if ONEPASSWORD_STATUS=not-installed run_preflight >"$test_root/foreign.out" 2>&1; then
  printf 'error: a 1password command without a managed package was accepted\n' >&2
  exit 1
fi
grep -Fq '1password resolves to' "$test_root/foreign.out"
grep -Fq 'not-installed' "$test_root/foreign.out"
rm "$test_root/bin/1password"

ln -s /bin/true "$test_root/bin/op"
export -n -f op
if run_preflight >"$test_root/shadowed.out" 2>&1; then
  printf 'error: shadowing op command was accepted\n' >&2
  exit 1
fi
grep -Fq 'op resolves to' "$test_root/shadowed.out"
