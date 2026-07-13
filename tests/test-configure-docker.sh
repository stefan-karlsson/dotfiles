#!/usr/bin/env bash

set -euo pipefail

[[ $# -eq 1 ]] || {
  printf 'usage: %s <rendered-script>\n' "$0" >&2
  exit 2
}

script="$1"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

id() {
  case "$1" in
    docker) return 0 ;;
    -un) printf 'test-user\n' ;;
    -nG) printf '%s\n' "${DOCKER_GROUPS:-test-user}" ;;
    *) return 1 ;;
  esac
}
getent() {
  [[ "$*" == "group docker" ]]
}
docker() {
  [[ "$1" == "info" ]]
}
systemctl() {
  printf '%s\n' "$*" >> "$SYSTEMCTL_LOG"
}
usermod() {
  printf '%s\n' "$*" >> "$USERMOD_LOG"
}
sudo() {
  "$@"
}
export -f id getent docker systemctl usermod sudo
export SYSTEMCTL_LOG="$test_root/systemctl.log"
export USERMOD_LOG="$test_root/usermod.log"

output="$(DOCKER_GROUPS='test-user docker' bash "$script")"
[[ "$output" == *'Docker Engine is enabled and running.'* ]]
grep -Fxq 'enable --now docker' "$SYSTEMCTL_LOG"
grep -Fxq 'is-active --quiet docker' "$SYSTEMCTL_LOG"
[[ ! -s "$USERMOD_LOG" ]]

: > "$SYSTEMCTL_LOG"
: > "$USERMOD_LOG"
output="$(DOCKER_GROUPS='test-user sudo' bash "$script")"
[[ "$output" == *'Adding test-user to the docker group'* ]]
[[ "$output" == *'current shell does not have the docker group yet'* ]]
grep -Fxq -- '--append --groups docker test-user' "$USERMOD_LOG"
grep -Fxq 'enable --now docker' "$SYSTEMCTL_LOG"
grep -Fxq 'is-active --quiet docker' "$SYSTEMCTL_LOG"
