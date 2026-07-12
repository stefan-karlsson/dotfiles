#!/usr/bin/env bash

set -euo pipefail

[[ $# -eq 1 ]] || {
  printf 'usage: %s <rendered-foundation>\n' "$0" >&2
  exit 2
}

foundation_source="$1"
test_root="$(mktemp -d)"
curl_log="$test_root/curl.log"
trap 'rm -rf "$test_root"' EXIT

source "$foundation_source"

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
