#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
script="$(test_render_template 'home/.chezmoiscripts/run_always_after_18-configure-dotnet-dev-certificate.sh.tmpl')"

mkdir -p "${test_root}/home" "${test_root}/empty"
: >"${test_root}/actions"

# Records the trust store locations the script exports alongside each call, since
# pointing dotnet at the user's NSS database is the behaviour under test.
test_stub_command dotnet - <<'STUB'
printf '%s %s %s\n' "$*" "${DOTNET_DEV_CERTS_NSSDB_PATHS}" "${SSL_CERT_DIR}" \
  >>"${test_root}/actions"
case "$*" in
  'dev-certs https --check --trust')
    [[ -f "${test_root}/trusted" ]]
    ;;
  'dev-certs https --trust')
    touch "${test_root}/trusted"
    ;;
  *)
    printf 'unexpected dotnet call: %s\n' "$*" >&2
    exit 1
    ;;
esac
STUB
test_stub_command openssl
test_stub_command certutil

run_certificate_setup() {
  HOME="${test_root}/home" test_run_script "${script}"
}

run_certificate_setup
grep -Fq 'dev-certs https --check --trust' "${test_root}/actions"
grep -Fq 'dev-certs https --trust' "${test_root}/actions"
grep -Fq "${test_root}/home/.pki/nssdb" "${test_root}/actions"
grep -Fq "${test_root}/home/.aspnet/dev-certs/trust:/usr/lib/ssl/certs" "${test_root}/actions"
[[ -d "${test_root}/home/.pki/nssdb" ]]

# Already trusted: the certificate is checked but not reissued.
action_count="$(wc -l < "${test_root}/actions")"
run_certificate_setup
[[ "$(wc -l < "${test_root}/actions")" == $((action_count + 1)) ]]
tail -n 1 "${test_root}/actions" | grep -Fq 'dev-certs https --check --trust'

# An empty PATH rather than the fixture's, so that the dotnet stub is out of
# reach and the script meets a machine without the SDK.
if PATH="${test_root}/empty" HOME="${test_root}/home" bash "${script}" >/dev/null 2>&1; then
  printf 'expected missing dotnet to fail\n' >&2
  exit 1
fi

printf '.NET developer certificate configuration checks passed\n'
