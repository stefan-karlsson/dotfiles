#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
verifier_source="$(test_render_template 'home/dot_local/bin/executable_verify-1password-setup.tmpl')"
test_home="${test_root}/home"
socket_pid=""
test_on_exit '[[ -z "${socket_pid}" ]] || kill "${socket_pid}" 2>/dev/null'

mkdir -p "$test_home/.1password"
mkdir -p "$test_home/etc/apt/sources.list.d" "$test_home/var/lib/chezmoi"
mkdir -p "$test_home/bin"
printf '#!/usr/bin/env bash\nexit 0\n' > "$test_home/bin/1password"
printf '#!/usr/bin/env bash\n[[ "$*" == "vault list" ]]\n' > "$test_home/bin/op"
chmod +x "$test_home/bin/1password" "$test_home/bin/op"
touch "$test_home/var/lib/chezmoi/1password-stable"
printf '%s\n' \
  'Types: deb' \
  'URIs: https://downloads.1password.com/linux/debian/amd64' \
  'Suites: stable' \
  'Components: main' \
  'Architectures: amd64' \
  'Signed-By: /usr/share/keyrings/1password-archive-keyring.gpg' \
  > "$test_home/etc/apt/sources.list.d/1password.sources"
verifier="$test_home/verify-1password-setup"
sed \
  -e "s|/etc/apt/sources.list.d/1password.sources|$test_home/etc/apt/sources.list.d/1password.sources|" \
  -e "s|/var/lib/chezmoi/1password-stable|$test_home/var/lib/chezmoi/1password-stable|" \
  "$verifier_source" > "$verifier"
python3 -c 'import socket, sys, time; s = socket.socket(socket.AF_UNIX); s.bind(sys.argv[1]); s.listen(); time.sleep(30)' \
  "$test_home/.1password/agent.sock" &
# shellcheck disable=SC2034 # read by the teardown registered above
socket_pid="$!"
for _ in {1..50}; do
  [[ -S "$test_home/.1password/agent.sock" ]] && break
  sleep 0.02
done

dpkg-query() {
  if [[ "$1" == "-S" ]]; then
    case "$2" in
      */1password) printf '1password: %s\n' "$2" ;;
      */op) printf '1password-cli: %s\n' "$2" ;;
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
ssh() {
  [[ "$*" == *"git@github.com"* ]] || return 2
  printf "Hi test-user! You've successfully authenticated, but GitHub does not provide shell access.\n" >&2
  return 1
}
export -f dpkg-query apt-cache ssh

default_output="$(HOME="$test_home" PATH="$test_home/bin:$PATH" bash "$verifier")"
[[ "$default_output" == *"1Password CLI access is working."* ]]
[[ "$default_output" == *"1Password SSH agent socket is available."* ]]
[[ "$default_output" != *"GitHub SSH authentication is working."* ]]

github_output="$(HOME="$test_home" PATH="$test_home/bin:$PATH" bash "$verifier" --github)"
[[ "$github_output" == *"GitHub SSH authentication is working."* ]]

mkdir -p "$test_home/shadow-bin"
ln -s /bin/true "$test_home/shadow-bin/op"
if HOME="$test_home" PATH="$test_home/shadow-bin:$test_home/bin:$PATH" bash "$verifier" >"$test_home/shadowed.out" 2>&1; then
  printf 'error: shadowing op command was accepted\n' >&2
  exit 1
fi
grep -Fq '1Password CLI command is not owned by the managed package' "$test_home/shadowed.out"
