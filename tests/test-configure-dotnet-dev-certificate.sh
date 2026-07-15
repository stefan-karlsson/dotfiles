#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=test-helpers.sh
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_setup 1 "$@"
script="$1"

mkdir -p "${test_root}/bin" "${test_root}/home" "${test_root}/empty"
: > "${test_root}/actions"

printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf "%s %s %s\\n" "$*" "${DOTNET_DEV_CERTS_NSSDB_PATHS}" "${SSL_CERT_DIR}" >> "${TEST_ROOT}/actions"' \
  'case "$*" in' \
  '  "dev-certs https --check --trust")' \
  '    [[ -f "${TEST_ROOT}/trusted" ]]' \
  '    ;;' \
  '  "dev-certs https --trust")' \
  '    touch "${TEST_ROOT}/trusted"' \
  '    ;;' \
  '  *)' \
  '    printf "unexpected dotnet call: %s\\n" "$*" >&2' \
  '    exit 1' \
  '    ;;' \
  'esac' > "${test_root}/bin/dotnet"
chmod +x "${test_root}/bin/dotnet"
ln -s /bin/true "${test_root}/bin/openssl"
ln -s /bin/true "${test_root}/bin/certutil"

export TEST_ROOT="${test_root}"
run_certificate_setup() {
  PATH="${test_root}/bin:${PATH}" HOME="${test_root}/home" /usr/bin/bash "${script}"
}

run_certificate_setup
grep -Fq 'dev-certs https --check --trust' "${test_root}/actions"
grep -Fq 'dev-certs https --trust' "${test_root}/actions"
grep -Fq "${test_root}/home/.pki/nssdb" "${test_root}/actions"
grep -Fq "${test_root}/home/.aspnet/dev-certs/trust:/usr/lib/ssl/certs" "${test_root}/actions"
[[ -d "${test_root}/home/.pki/nssdb" ]]

action_count="$(wc -l < "${test_root}/actions")"
run_certificate_setup
[[ "$(wc -l < "${test_root}/actions")" == $((action_count + 1)) ]]
tail -n 1 "${test_root}/actions" | grep -Fq 'dev-certs https --check --trust'

if PATH="${test_root}/empty" HOME="${test_root}/home" /usr/bin/bash "${script}" >/dev/null 2>&1; then
  printf 'expected missing dotnet to fail\n' >&2
  exit 1
fi

printf '.NET developer certificate configuration checks passed\n'
