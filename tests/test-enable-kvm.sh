#!/usr/bin/env bash

# shellcheck disable=SC1091,SC2154

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
script="$(test_render_template 'home/.chezmoiscripts/run_onchange_after_15-enable-kvm.sh.tmpl')"

awk() {
  printf 'GenuineIntel\n'
}
getent() {
  [[ "$*" == "group kvm" ]]
}
id() {
  case "$1" in
    -un) printf 'test-user\n' ;;
    -nG) printf '%s\n' "${KVM_GROUPS:-test-user}" ;;
    *) return 1 ;;
  esac
}
modprobe() {
  printf '%s\n' "$1" >> "${MODPROBE_LOG}"
}
usermod() {
  printf '%s\n' "$*" >> "${USERMOD_LOG}"
}
grep() {
  if [[ "$*" == *'vmx /proc/cpuinfo' ]]; then
    [[ "${KVM_VMX_AVAILABLE:-1}" == 1 ]]
  else
    command grep "$@"
  fi
}
sudo() {
  case "$1" in
    modprobe)
      modprobe "$2"
      ;;
    tee)
      shift
      cat > "${MODULES_FILE}"
      ;;
    usermod)
      shift
      usermod "$@"
      ;;
    *)
      printf 'unexpected sudo call: %s\n' "$*" >&2
      return 1
      ;;
  esac
}
export -f awk getent grep id modprobe sudo usermod
export MODULES_FILE="${test_root}/chezmoi-kvm.conf"
export MODPROBE_LOG="${test_root}/modprobe.log"
export USERMOD_LOG="${test_root}/usermod.log"

output="$(KVM_GROUPS='test-user kvm' bash "${script}")"
[[ "${output}" == *'KVM is enabled for Docker Desktop using kvm_intel.'* ]]
grep -Fxq kvm "${MODPROBE_LOG}"
grep -Fxq kvm_intel "${MODPROBE_LOG}"
grep -Fxq $'kvm\nkvm_intel' "${MODULES_FILE}"
[[ ! -s "${USERMOD_LOG}" ]]

: > "${MODPROBE_LOG}"
: > "${MODULES_FILE}"
output="$(KVM_GROUPS='test-user sudo' bash "${script}")"
[[ "${output}" == *'Added test-user to the kvm group'* ]]
grep -Fxq -- '--append --groups kvm test-user' "${USERMOD_LOG}"
grep -Fxq kvm "${MODPROBE_LOG}"
grep -Fxq kvm_intel "${MODPROBE_LOG}"

: > "${MODPROBE_LOG}"
if KVM_VMX_AVAILABLE=0 KVM_GROUPS='test-user kvm' bash "${script}" > "${test_root}/no-vmx.out" 2>&1; then
  printf 'error: KVM setup succeeded without Intel VT-x\n' >&2
  exit 1
fi
grep -Fq 'Intel VT-x (vmx) is unavailable' "${test_root}/no-vmx.out"
[[ ! -s "${MODPROBE_LOG}" ]]

printf 'KVM configuration checks passed\n'
