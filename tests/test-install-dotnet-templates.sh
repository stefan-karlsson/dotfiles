#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
script="$(test_render_template 'home/.chezmoiscripts/run_onchange_after_18-install-dotnet-templates.sh.tmpl')"

mkdir -p "${test_root}/home" "${test_root}/empty"
: >"${test_root}/template-actions"
printf '%s\n' 'Unrelated.Templates' >"${test_root}/installed-templates"

# Records install versus update per template, which is the distinction the
# installer's idempotency turns on.
test_stub_command dotnet - <<'STUB'
if [[ "$1:$2" != 'new:install' ]]; then
  printf 'unexpected dotnet call: %s\n' "$*" >&2
  exit 1
fi
if grep -Fxq "$3" "${test_root}/installed-templates"; then
  action=update
else
  action=install
  printf '%s\n' "$3" >>"${test_root}/installed-templates"
fi
printf '%s %s\n' "${action}" "$3" >>"${test_root}/template-actions"
STUB

run_templates() {
  HOME="${test_root}/home" test_run_script "${script}"
}

run_templates
grep -Fxq 'install Amazon.Lambda.Templates' "${test_root}/template-actions"
grep -Fxq 'install Aspire.ProjectTemplates' "${test_root}/template-actions"
grep -Fxq 'Unrelated.Templates' "${test_root}/installed-templates"
[[ "$(wc -l < "${test_root}/installed-templates")" == 3 ]]

run_templates
[[ "$(wc -l < "${test_root}/template-actions")" == 4 ]]
grep -Fxq 'update Amazon.Lambda.Templates' "${test_root}/template-actions"
grep -Fxq 'update Aspire.ProjectTemplates' "${test_root}/template-actions"
[[ "$(wc -l < "${test_root}/installed-templates")" == 3 ]]
! grep -Fq 'Microsoft.DotNet.Web.ProjectTemplates' "${test_root}/template-actions"

# An empty PATH rather than the fixture's, so that the dotnet stub is out of
# reach and the installer meets a machine without the SDK.
if PATH="${test_root}/empty" HOME="${test_root}/home" bash "${script}" >/dev/null 2>&1; then
  printf 'expected missing dotnet to fail\n' >&2
  exit 1
fi

printf '.NET template installation checks passed\n'
