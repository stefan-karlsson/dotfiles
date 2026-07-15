#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=test-helpers.sh
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_setup 1 "$@"
installer="$1"

grep -Fq 'download the Linux ZIP' "${installer}"
grep -Fq 'UNREAL_ENGINE_ARCHIVE' "${installer}"

mkdir -p "${test_root}/bin" "${test_root}/home/Downloads"
touch "${test_root}/home/Downloads/UnrealEngine-5.8.0-Linux.zip"

printf '#!/usr/bin/env bash\nset -euo pipefail\ndestination=""\nwhile (( $# > 0 )); do\n  if [[ "$1" == "-d" ]]; then\n    destination="$2"\n    shift 2\n  else\n    shift\n  fi\ndone\nroot="${destination}/UnrealEngine-5.8.0"\nmkdir -p "${root}/Engine/Binaries/Linux" "${root}/Engine/Build/BatchFiles/Linux"\ntouch "${root}/Engine/Binaries/Linux/UnrealEditor"\nchmod +x "${root}/Engine/Binaries/Linux/UnrealEditor"\nprintf '\''{"MajorVersion": 5, "MinorVersion": 8}\n'\'' >"${root}/Engine/Build/Build.version"\nprintf '\''#!/usr/bin/env bash\nexit 0\n'\'' >"${root}/Engine/Build/BatchFiles/Linux/SetupToolchain.sh"\nchmod +x "${root}/Engine/Build/BatchFiles/Linux/SetupToolchain.sh"\n' >"${test_root}/bin/unzip"
chmod +x "${test_root}/bin/unzip"

HOME="${test_root}/home" \
XDG_DATA_HOME="${test_root}/data" \
PATH="${test_root}/bin:${PATH}" \
  bash "${installer}"

engine_root="${test_root}/data/unreal-engine/5.8"
[[ -x "${engine_root}/Engine/Binaries/Linux/UnrealEditor" ]]
[[ -f "${engine_root}/.chezmoi-managed" ]]
[[ -f "${engine_root}/.chezmoi-toolchain-configured" ]]

second_run="$({
  HOME="${test_root}/home" \
  XDG_DATA_HOME="${test_root}/data" \
  PATH="${test_root}/bin:${PATH}" \
    bash "${installer}"
} 2>&1)"
[[ "${second_run}" == *"already installed"* ]]

printf 'Unreal Engine installer checks passed\n'
