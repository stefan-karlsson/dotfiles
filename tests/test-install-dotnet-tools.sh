#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
script="$(test_render_template 'home/.chezmoiscripts/run_onchange_after_18-install-dotnet-tools.sh.tmpl')"

mkdir -p "${test_root}/home/.dotnet" "${test_root}/empty"
: >"${test_root}/tool-actions"
printf '%s\n' 'amazon.lambda.tools' 'unrelated.tool' >"${test_root}/installed-tools"

# Reports the installed set the way `dotnet tool list` does, and records install
# versus update per tool, which is the distinction the installer's idempotency
# turns on.
test_stub_command dotnet - <<'STUB'
case "$1:$2:$3" in
  tool:list:--global)
    printf '{"version":1,"data":['
    first=true
    while IFS= read -r package; do
      [[ -n "${package}" ]] || continue
      [[ "${first}" == true ]] || printf ','
      printf '{"packageId":"%s"}' "${package}"
      first=false
    done <"${test_root}/installed-tools"
    printf ']}\n'
    ;;
  tool:update:--global | tool:install:--global)
    printf '%s %s\n' "$2" "$4" >>"${test_root}/tool-actions"
    grep -Fxq "$4" "${test_root}/installed-tools" ||
      printf '%s\n' "$4" >>"${test_root}/installed-tools"
    ;;
  *)
    printf 'unexpected dotnet call: %s\n' "$*" >&2
    exit 1
    ;;
esac
STUB
cp "${test_root}/bin/dotnet" "${test_root}/home/.dotnet/dotnet"

HOME="${test_root}/home" test_run_script "${script}"
grep -Fxq 'install dotnet-ef' "${test_root}/tool-actions"
grep -Fxq 'update Amazon.Lambda.Tools' "${test_root}/tool-actions"
grep -Fxq 'install Aspire.Cli' "${test_root}/tool-actions"
grep -Fxq 'unrelated.tool' "${test_root}/installed-tools"
! grep -Fq 'unrelated.tool' "${test_root}/tool-actions"

: >"${test_root}/tool-actions"
printf '%s\n' 'amazon.lambda.tools' 'dotnet-ef' 'aspire.cli' 'unrelated.tool' >"${test_root}/installed-tools"
HOME="${test_root}/home" test_run_script "${script}"
[[ "$(wc -l < "${test_root}/tool-actions")" == 3 ]]
! grep -Fq 'install ' "${test_root}/tool-actions"
! grep -Fq 'unrelated.tool' "${test_root}/tool-actions"

# An empty PATH rather than the fixture's, so that the dotnet stub is out of
# reach and the installer meets a machine without the SDK.
if PATH="${test_root}/empty" HOME="${test_root}/missing-home" bash "${script}" >/dev/null 2>&1; then
  printf 'expected missing dotnet to fail\n' >&2
  exit 1
fi

printf 'Global .NET tool installation checks passed\n'
