#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
script="$(test_render_template 'home/.chezmoiscripts/run_onchange_after_14-install-dotnet-sdk.sh.tmpl')"

mkdir -p "${test_root}/home"
: >"${test_root}/installer-actions"

# What curl fetches: the vendor's install script, which records how it was asked
# to install and leaves a dotnet behind.
cat >"${test_root}/fake-dotnet-install.sh" <<'INSTALLER'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${test_root}/installer-actions"
mkdir -p "${HOME}/.dotnet"
printf '#!/usr/bin/env bash\nprintf 10.0.301\n' >"${HOME}/.dotnet/dotnet"
chmod +x "${HOME}/.dotnet/dotnet"
INSTALLER
chmod 0755 "${test_root}/fake-dotnet-install.sh"

test_stub_command curl - <<'STUB'
output=""
while (($# > 0)); do
  if [[ "$1" == '--output' ]]; then output="$2"; shift 2; else shift; fi
done
[[ -n "${output}" ]] || exit 1
cp "${test_root}/fake-dotnet-install.sh" "${output}"
STUB

HOME="${test_root}/home" test_run_script "${script}"

test_assert_called 'curl'
grep -Fq -- '--version 10.0.301' "${test_root}/installer-actions"
grep -Fq -- '--install-dir' "${test_root}/installer-actions"
[[ "$(readlink "${test_root}/home/.local/bin/dotnet")" == "${test_root}/home/.dotnet/dotnet" ]]

printf '.NET SDK installation checks passed\n'
