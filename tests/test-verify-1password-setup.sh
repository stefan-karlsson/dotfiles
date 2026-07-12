#!/usr/bin/env bash

set -euo pipefail

[[ $# -eq 1 ]] || {
  printf 'usage: %s <rendered-verifier>\n' "$0" >&2
  exit 2
}

verifier_source="$1"
test_home="$(mktemp -d)"
socket_pid=""
cleanup() {
  [[ -z "$socket_pid" ]] || kill "$socket_pid" 2>/dev/null || true
  rm -rf "$test_home"
}
trap cleanup EXIT

mkdir -p "$test_home/.1password"
mkdir -p "$test_home/etc/apt/sources.list.d" "$test_home/var/lib/chezmoi"
touch "$test_home/var/lib/chezmoi/1password-stable"
printf '%s\n' \
  'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' \
  > "$test_home/etc/apt/sources.list.d/1password.list"
verifier="$test_home/verify-1password-setup"
sed \
  -e "s|/etc/apt/sources.list.d/1password.list|$test_home/etc/apt/sources.list.d/1password.list|" \
  -e "s|/var/lib/chezmoi/1password-stable|$test_home/var/lib/chezmoi/1password-stable|" \
  "$verifier_source" > "$verifier"
python3 -c 'import socket, sys, time; s = socket.socket(socket.AF_UNIX); s.bind(sys.argv[1]); s.listen(); time.sleep(30)' \
  "$test_home/.1password/agent.sock" &
socket_pid="$!"
for _ in {1..50}; do
  [[ -S "$test_home/.1password/agent.sock" ]] && break
  sleep 0.02
done

dpkg-query() {
  if [[ "$1" == "-S" ]]; then
    case "$2" in
      onepassword|/usr/bin/1password) printf '1password: %s\n' "$2" ;;
      op|/usr/bin/op) printf '1password-cli: %s\n' "$2" ;;
      *) return 1 ;;
    esac
    return
  fi
  if [[ "$*" == *"1password"* || "$*" == *"1password-cli"* ]]; then
    if [[ "$*" == *'${Version}'* ]]; then
      printf '8.12.26\n'
    else
      printf 'installed\n'
    fi
    return
  fi
  return 1
}
apt-cache() {
  package="${*: -1}"
  printf '%s | 8.12.26 | https://downloads.1password.com/linux/debian/amd64 stable/main amd64 Packages\n' "$package"
}
onepassword() {
  :
}
op() {
  [[ "$*" == "vault list" ]]
}
ssh() {
  [[ "$*" == *"git@github.com"* ]] || return 2
  printf "Hi test-user! You've successfully authenticated, but GitHub does not provide shell access.\n" >&2
  return 1
}
export -f dpkg-query apt-cache onepassword op ssh

default_output="$(HOME="$test_home" bash "$verifier")"
[[ "$default_output" == *"1Password CLI access is working."* ]]
[[ "$default_output" == *"1Password SSH agent socket is available."* ]]
[[ "$default_output" != *"GitHub SSH authentication is working."* ]]

github_output="$(HOME="$test_home" bash "$verifier" --github)"
[[ "$github_output" == *"GitHub SSH authentication is working."* ]]

mkdir -p "$test_home/bin"
ln -s /bin/true "$test_home/bin/op"
export -n -f op
if HOME="$test_home" PATH="$test_home/bin:$PATH" bash "$verifier" >"$test_home/shadowed.out" 2>&1; then
  printf 'error: shadowing op command was accepted\n' >&2
  exit 1
fi
grep -Fq '1Password CLI command is not owned by the managed package' "$test_home/shadowed.out"
