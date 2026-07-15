#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=test-helpers.sh
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_setup 1 "$@"
command_script="$1"

mkdir -p "${test_root}/bin" "${test_root}/home/Downloads"
printf '#!/usr/bin/env bash\nexit 0\n' >"${test_root}/bin/sudo"
printf '#!/usr/bin/env bash\nprintf "%s\\n" "$*" >>"${TEST_LOG}"\n' >"${test_root}/bin/xdg-open"
chmod +x "${test_root}/bin/sudo" "${test_root}/bin/xdg-open"
export TEST_LOG="${test_root}/actions.log"

if HOME="${test_root}/home" XDG_DATA_HOME="${test_root}/data" \
  PATH="${test_root}/bin:${PATH}" \
  bash "${command_script}" >"${test_root}/missing.out" 2>&1; then
  printf 'error: installer command accepted a missing archive\n' >&2
  exit 1
fi
grep -Fq 'Download the Unreal Engine 5.8 Linux ZIP' "${test_root}/missing.out"
grep -Fq 'https://www.unrealengine.com/en-US/linux' "${TEST_LOG}"

touch "${test_root}/home/Downloads/UnrealEngine-5.8.0-Linux.zip"
printf '#!/usr/bin/env bash\nprintf apply >>"${TEST_LOG}"\n' >"${test_root}/bin/chezmoi"
printf '#!/usr/bin/env bash\nprintf "editor:%s\\n" "$*" >>"${TEST_LOG}"\n' >"${test_root}/bin/unreal-editor"
chmod +x "${test_root}/bin/chezmoi" "${test_root}/bin/unreal-editor"
HOME="${test_root}/home" XDG_DATA_HOME="${test_root}/data" \
  PATH="${test_root}/bin:${PATH}" \
  bash "${command_script}" --project TestProject
grep -Fq 'apply' "${TEST_LOG}"
grep -Fq 'editor:--project TestProject' "${TEST_LOG}"

printf 'Unreal Engine command checks passed\n'
