#!/usr/bin/env bash

# SC1090: the foundation's path is decided at run time by the fixture.
# SC2034/SC2154: the foundation reads and writes its records as globals in the
# caller's scope, so this test assigns them from outside the module.
# shellcheck disable=SC1090,SC2034,SC2154
set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
foundation_source="$(test_render_template 'home/.chezmoitemplates/ubuntu-package-foundation.sh')"
# Every script that includes the package foundation includes the shell foundation
# ahead of it, so the module's own diagnostics are available here too.
shell_foundation_source="$(test_render_template 'home/.chezmoitemplates/shell-foundation.sh')"
curl_log="${test_root}/curl.log"

source "$shell_foundation_source"
source "$foundation_source"

repository_uris[chrome]='https://dl.google.com/linux/chrome/deb/'
dpkg-query() {
  if [[ "$1" == "-W" && "$2" == '-f=${Version}' && "$3" == "google-chrome-stable" ]]; then
    printf '150.0.7871.114-1\n'
  else
    return 1
  fi
}
apt-cache() {
  [[ "$1" == "madison" && "$2" == "google-chrome-stable" ]] || return 1
  printf 'google-chrome-stable | 150.0.7871.114-1 | https://dl.google.com/linux/chrome/deb stable/main amd64 Packages\n'
}
installed_package_available_from_repository google-chrome-stable chrome

apt-cache() {
  [[ "$1" == "madison" && "$2" == "google-chrome-stable" ]] || return 1
  printf 'google-chrome-stable | 150.0.7871.124-1 | https://dl.google.com/linux/chrome/deb stable/main amd64 Packages\n'
}
if ! installed_package_available_from_repository google-chrome-stable chrome; then
  printf 'error: an installed older package was rejected despite an official upgrade candidate\n' >&2
  exit 1
fi

apt-cache() {
  [[ "$1" == "madison" && "$2" == "google-chrome-stable" ]] || return 1
  printf 'google-chrome-stable | 150.0.7871.113-1 | https://dl.google.com/linux/chrome/deb stable/main amd64 Packages\n'
}
if installed_package_available_from_repository google-chrome-stable chrome; then
  printf 'error: an installed package newer than the official candidate was accepted\n' >&2
  exit 1
fi

repository_labels[onepassword]="1Password Stable"
repository_uris[onepassword]="https://example.invalid/1password"
repository_key_urls[onepassword]="https://example.invalid/key.asc"
repository_key_files[onepassword]="$test_root/keyrings/1password.gpg"
repository_key_installs[onepassword]="dearmor_output"
repository_key_modes[onepassword]=""
repository_key_fingerprints[onepassword]="fixture-fingerprint"
repository_source_files[onepassword]="$test_root/sources/1password.list"
repository_marker_files[onepassword]="$test_root/markers/1password-stable"
repository_auxiliary_key_urls[onepassword]="https://example.invalid/key.asc"
repository_auxiliary_key_files[onepassword]="$test_root/debsig/1password.gpg"
repository_auxiliary_policy_urls[onepassword]="https://example.invalid/1password.pol"
repository_auxiliary_policy_files[onepassword]="$test_root/debsig/1password.pol"
repository_package_names[onepassword]="1password 1password-cli"
repository_command_bindings[onepassword]=""

sudo() {
  "$@"
}

legacy_source="$test_root/sources/1password.sources"
mkdir -p "$(dirname "$legacy_source")"
printf 'duplicate repository source\n' > "$legacy_source"
repository_legacy_source_files[onepassword]="$legacy_source"
remove_legacy_repository_sources onepassword
[[ ! -e "$legacy_source" ]]

metadata_source="$test_root/sources/google-chrome.sources"
repository_source_files[chrome]="$metadata_source"
repository_source_formats[chrome]='deb822'
repository_source_architectures[chrome]='amd64'
repository_uris[chrome]='https://dl.google.com/linux/chrome-stable/deb/'
repository_key_files[chrome]='/usr/share/keyrings/google-chrome.gpg'
printf '%s\n' \
  '### THIS FILE IS AUTOMATICALLY CONFIGURED ###' \
  'X-Repolib-Name: Google Chrome' \
  'Types: deb' \
  'URIs: https://dl.google.com/linux/chrome-stable/deb/' \
  'Suites: stable' \
  'Components: main' \
  'Architectures: amd64' \
  'Signed-By: /usr/share/keyrings/google-chrome.gpg' \
  > "$metadata_source"
repository_source_is_compatible chrome

vscode_metadata_source="$test_root/sources/vscode.sources"
repository_source_files[vscode]="$vscode_metadata_source"
printf '%s\n' \
  '### THIS FILE IS AUTOMATICALLY CONFIGURED ###' \
  'X-Repolib-Name: Visual Studio Code' \
  'Types: deb' \
  'URIs: https://packages.microsoft.com/repos/code' \
  'Suites: stable' \
  'Components: main' \
  'Architectures: amd64' \
  'Signed-By: /usr/share/keyrings/microsoft.gpg' \
  > "$vscode_metadata_source"
repository_source_is_compatible vscode || {
  printf 'error: an official narrower VS Code architecture list was rejected\n' >&2
  exit 1
}

repository_source_files[spotify]="$test_root/sources/spotify.sources"
repository_source_formats[spotify]='deb822'
repository_source_architectures[spotify]='amd64'
repository_components[spotify]='non-free'
repository_uris[spotify]='https://repository.spotify.com'
repository_key_files[spotify]='/etc/apt/keyrings/spotify-archive-keyring.gpg'
printf '%s\n' \
  'Types: deb' \
  'URIs: https://repository.spotify.com' \
  'Suites: stable' \
  'Components: non-free' \
  'Architectures: amd64' \
  'Signed-By: /etc/apt/keyrings/spotify-archive-keyring.gpg' \
  > "${repository_source_files[spotify]}"
repository_source_is_compatible spotify

curl() {
  printf '%s\n' "$1" >> "$curl_log"
  printf 'valid-key\n'
}

gpg() {
  local output_file=""

  if [[ " $* " == *" --show-keys "* ]]; then
    grep -Fq 'valid-key' "${@: -1}" || return 1
    printf 'fpr:::::::::fixture-fingerprint:\n'
    return 0
  fi

  while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--output" ]]; then
      output_file="$2"
      shift 2
    else
      shift
    fi
  done

  if [[ -n "$output_file" ]]; then
    cat > "$output_file"
  else
    cat
  fi
}

configure_repository onepassword
[[ -s "${repository_key_files[onepassword]}" ]]
[[ -s "${repository_auxiliary_key_files[onepassword]}" ]]
[[ -s "${repository_auxiliary_policy_files[onepassword]}" ]]
[[ -f "${repository_marker_files[onepassword]}" ]]
repository_source_matches onepassword

curl_count_before="$(wc -l < "$curl_log")"
configure_repository onepassword
curl_count_after="$(wc -l < "$curl_log")"
[[ "$curl_count_before" == "$curl_count_after" ]]

printf 'corrupt-key\n' > "${repository_key_files[onepassword]}"
configure_repository onepassword
curl_count_after_repair="$(wc -l < "$curl_log")"
[[ "$curl_count_after_repair" -gt "$curl_count_after" ]]

expected_source="$(repository_source onepassword)"
printf '# %s\n' "$expected_source" > "${repository_source_files[onepassword]}"
configure_repository onepassword
[[ "$(cat "${repository_source_files[onepassword]}")" == "$expected_source" ]]

dpkg-query() {
  if [[ "$1" == "-W" && "$*" == *'${db:Status-Status}'* ]]; then
    printf 'installed\n'
  elif [[ "$1" == "-W" && "$*" == *'${Version}'* ]]; then
    printf '8.12.26\n'
  else
    return 1
  fi
}

apt-cache() {
  printf '1password | 8.12.26 | %s stable/main amd64 Packages\n' "${repository_uris[onepassword]}"
}

repository_adopt_existing[onepassword]=true
rm -f "${repository_marker_files[onepassword]}"
fail_on_unmanaged_repository onepassword

printf 'conflicting source\n' > "${repository_source_files[onepassword]}"
if fail_on_unmanaged_repository onepassword > "$test_root/conflict.out" 2>&1; then
  printf 'error: conflicting repository was accepted\n' >&2
  exit 1
fi
grep -Fq 'conflicting apt repository' "$test_root/conflict.out"

# A bootstrap interrupted while dpkg configured 1Password leaves the package
# unpacked, which a rerun has to finish rather than read as a foreign install.
onepassword_status=half-configured
dpkg_configure_calls=0
dpkg-query() {
  if [[ "$1" == "-W" && "$*" == *'${db:Status-Status}'* ]]; then
    if [[ "${*: -1}" == "1password" ]]; then
      printf '%s\n' "$onepassword_status"
    else
      printf 'installed\n'
    fi
  elif [[ "$1" == "-W" && "$*" == *'${Version}'* ]]; then
    printf '8.12.26\n'
  else
    return 1
  fi
}
env() {
  while [[ "${1:-}" == *=* ]]; do
    shift
  done
  "$@"
}
dpkg() {
  [[ "$*" == "--configure --pending" ]] || return 1
  dpkg_configure_calls=$((dpkg_configure_calls + 1))
  onepassword_status=installed
}

package_install_interrupted 1password
resume_interrupted_repository_packages
(( dpkg_configure_calls == 1 ))
package_installed 1password

onepassword_status=half-configured
dpkg() {
  return 1
}
if (resume_interrupted_repository_packages) > "$test_root/interrupted.out" 2>&1; then
  printf 'error: a dpkg run that could not be finished was accepted\n' >&2
  exit 1
fi
grep -Fq 'dpkg could not finish installing 1password' "$test_root/interrupted.out"
