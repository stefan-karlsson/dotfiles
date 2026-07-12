#!/usr/bin/env bash

set -euo pipefail

[[ $# -eq 1 ]] || {
  printf 'usage: %s <rendered-installer>\n' "$0" >&2
  exit 2
}

installer="$1"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

grep -Fq '"flameshot"' "$installer"
grep -Fq '"qt6-wayland"' "$installer"
grep -Fq '"dotnet-sdk-10.0"' "$installer"
grep -Fq '"tmux"' "$installer"
grep -Fq '"spotify"' "$installer"
grep -Fq '"mise"' "$installer"
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
touch "$test_root/vscode-stable" "$test_root/google-chrome-stable" "$test_root/github-cli-stable"

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
  "$installer" | sed '/^repository_prerequisites=()/q' > "$preflight"

dpkg() {
  [[ "$*" == "--print-architecture" ]] && printf 'amd64\n'
}
dpkg-query() {
  if [[ "$1" == "-S" ]]; then
    case "$2" in
      code|/usr/bin/code) printf 'code: %s\n' "$2" ;;
      google-chrome|/usr/bin/google-chrome) printf 'google-chrome-stable: %s\n' "$2" ;;
      onepassword|/usr/bin/1password|/opt/1Password/1password) printf '1password: %s\n' "$2" ;;
      op|/usr/bin/op) printf '1password-cli: %s\n' "$2" ;;
      gh|/usr/bin/gh) printf 'gh: %s\n' "$2" ;;
      *) return 1 ;;
    esac
    return
  fi
  case "${*: -1}" in
    code|google-chrome-stable|gh|1password|1password-cli)
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
export -f dpkg dpkg-query apt-cache snap flatpak onepassword op readlink code google-chrome gh

output="$(bash "$preflight")"
[[ "$output" == *"Adopting the existing official 1Password Stable apt installation"* ]]

sed -i 's/^Types: deb/# Types: deb/' "$test_root/etc/apt/sources.list.d/1password.sources"
commented_output="$(bash "$preflight")"
[[ "$commented_output" == *"Adopting the existing official 1Password Stable apt installation"* ]]

if APT_ORIGIN="https://packages.example.invalid" bash "$preflight" >"$test_root/conflicting.out" 2>&1; then
  printf 'error: conflicting 1Password package origin was accepted\n' >&2
  exit 1
fi
grep -Fq 'is unavailable from the official stable repository' "$test_root/conflicting.out"

mkdir -p "$test_root/bin"
ln -s /bin/true "$test_root/bin/op"
export -n -f op
if PATH="$test_root/bin:$PATH" bash "$preflight" >"$test_root/shadowed.out" 2>&1; then
  printf 'error: shadowing op command was accepted\n' >&2
  exit 1
fi
grep -Fq 'op resolves to' "$test_root/shadowed.out"
