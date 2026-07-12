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
  [[ "$*" == "-un" ]] && printf 'test-user\n'
}
getent() {
  [[ "$*" == "group sudo" ]] && printf 'sudo:x:27:%s\n' "${SUDO_MEMBERS:-}"
}
sudo() {
  [[ "${SUDO_FAIL:-}" != 1 ]] || return 1
  printf '%s\n' "$*" >> "$SUDO_LOG"
}
export -f id getent sudo
export SUDO_LOG="$test_root/sudo.log"

output="$(SUDO_MEMBERS='' bash "$script")"
[[ "$output" == *"Added test-user to the sudo group"* ]]
grep -Fxq -- '-v' "$SUDO_LOG"
grep -Fxq -- 'usermod -aG sudo test-user' "$SUDO_LOG"

: > "$SUDO_LOG"
output="$(SUDO_MEMBERS='test-user' bash "$script")"
[[ "$output" == *"test-user is already in the sudo group"* ]]
grep -Fxq -- '-v' "$SUDO_LOG"

if SUDO_MEMBERS='' SUDO_FAIL=1 bash "$script" >"$test_root/failure.out" 2>&1; then
  printf 'error: sudo failure was accepted\n' >&2
  exit 1
fi
grep -Fq 'use an existing administrator account or Ubuntu recovery/root access' "$test_root/failure.out"
