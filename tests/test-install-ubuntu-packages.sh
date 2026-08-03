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
grep -Fq 'https://repo.fortinet.com/repo/forticlient/8.0/ubuntu/' "$installer"
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
  fi
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
    code|google-chrome-stable|gh|mise|1password|1password-cli)
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
    -f\ 1password|*/usr/bin/1password) printf '/opt/1Password/1password\n' ;;
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
export -f dpkg dpkg-query apt-cache snap flatpak onepassword op readlink code google-chrome gh

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

ln -s /bin/true "$test_root/bin/op"
export -n -f op
if run_preflight >"$test_root/shadowed.out" 2>&1; then
  printf 'error: shadowing op command was accepted\n' >&2
  exit 1
fi
grep -Fq 'op resolves to' "$test_root/shadowed.out"
