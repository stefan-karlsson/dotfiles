#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
script="$(test_render_template 'home/.chezmoiscripts/run_onchange_after_16-configure-docker.sh.tmpl')"

# id answers two different questions. With a user operand it reads the group
# database, which usermod has just written; without one it reports the calling
# process's own groups, which a login session fixed at sign-in. The two disagree
# for the whole of the run that adds the account to the docker group.
id() {
  case "$1" in
    -un) printf 'test-user\n' ;;
    -nG)
      if (($# > 1)); then
        cat "$DATABASE_GROUPS"
      else
        printf '%s\n' "$SESSION_GROUPS"
      fi
      ;;
    *) return 1 ;;
  esac
}
getent() {
  [[ "$*" == "group docker" ]]
}
# The daemon socket is reachable by root, or by a process whose own groups carry
# the docker membership.
docker() {
  [[ "$1" == "info" && "${DAEMON_RESPONDS:-true}" == true ]] || return 1
  [[ "${as_root:-false}" == true ]] || id -nG | tr ' ' '\n' | grep -Fqx docker
}
systemctl() {
  printf '%s\n' "$*" >> "$SYSTEMCTL_LOG"
}
usermod() {
  printf '%s\n' "$*" >> "$USERMOD_LOG"
  printf 'test-user docker\n' > "$DATABASE_GROUPS"
}
sudo() {
  local as_root=true

  printf '%s\n' "$*" >> "$SUDO_LOG"
  "$@"
}
export -f id getent docker systemctl usermod sudo
export SYSTEMCTL_LOG="$test_root/systemctl.log"
export USERMOD_LOG="$test_root/usermod.log"
export SUDO_LOG="$test_root/sudo.log"
export DATABASE_GROUPS="$test_root/database-groups"
export SESSION_GROUPS='test-user'

reset_logs() {
  : > "$SYSTEMCTL_LOG"
  : > "$USERMOD_LOG"
  : > "$SUDO_LOG"
}

# A new laptop: the account is not in the docker group yet, so this run adds it
# and cannot use it. The Engine is still verified, through root.
reset_logs
printf 'test-user\n' > "$DATABASE_GROUPS"
output="$(SESSION_GROUPS='test-user' bash "$script")"
[[ "$output" == *'Adding test-user to the docker group'* ]]
[[ "$output" == *'current shell does not have the docker group yet'* ]]
[[ "$output" == *'Docker Engine is enabled and running.'* ]]
grep -Fxq -- '--append --groups docker test-user' "$USERMOD_LOG"
grep -Fxq 'enable --now docker' "$SYSTEMCTL_LOG"
grep -Fxq 'is-active --quiet docker' "$SYSTEMCTL_LOG"
grep -Fxq 'docker info' "$SUDO_LOG"

# A machine that has been signed in to since: nothing to add, and no notice.
reset_logs
printf 'test-user docker\n' > "$DATABASE_GROUPS"
output="$(SESSION_GROUPS='test-user docker' bash "$script")"
[[ "$output" == *'Docker Engine is enabled and running.'* ]]
[[ "$output" != *'sign out and back in'* ]]
[[ ! -s "$USERMOD_LOG" ]]
grep -Fxq 'docker info' "$SUDO_LOG"

# A daemon that is enabled but does not answer stays a failure.
reset_logs
if DAEMON_RESPONDS=false SESSION_GROUPS='test-user docker' bash "$script" \
  >"$test_root/daemon.out" 2>&1; then
  printf 'error: an Engine that does not answer was accepted\n' >&2
  exit 1
fi
grep -Fq 'docker info failed' "$test_root/daemon.out"
