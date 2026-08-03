#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
installer="$(test_render_template 'home/.chezmoiscripts/run_always_after_30-install-unreal-engine.sh.tmpl')"

grep -Fq 'download the Linux ZIP' "${installer}"
grep -Fq 'UNREAL_ENGINE_ARCHIVE' "${installer}"

mkdir -p "${test_root}/home/Downloads"
touch "${test_root}/home/Downloads/UnrealEngine-5.8.0-Linux.zip"

# Unpacks a minimal engine tree: the editor binary, a version file, and the
# toolchain setup script the installer runs afterwards.
test_stub_command unzip - <<'STUB'
destination=""
while (($# > 0)); do
  if [[ "$1" == '-d' ]]; then
    destination="$2"
    shift 2
  else
    shift
  fi
done
root="${destination}/UnrealEngine-5.8.0"
mkdir -p "${root}/Engine/Binaries/Linux" "${root}/Engine/Build/BatchFiles/Linux"
touch "${root}/Engine/Binaries/Linux/UnrealEditor"
chmod +x "${root}/Engine/Binaries/Linux/UnrealEditor"
printf '{"MajorVersion": 5, "MinorVersion": 8}\n' >"${root}/Engine/Build/Build.version"
printf '#!/usr/bin/env bash\nexit 0\n' >"${root}/Engine/Build/BatchFiles/Linux/SetupToolchain.sh"
chmod +x "${root}/Engine/Build/BatchFiles/Linux/SetupToolchain.sh"
STUB

install_engine() {
  HOME="${test_root}/home" \
    XDG_DATA_HOME="${test_root}/data" \
    test_run_script "${installer}"
}

install_engine

engine_root="${test_root}/data/unreal-engine/5.8"
[[ -x "${engine_root}/Engine/Binaries/Linux/UnrealEditor" ]]
[[ -f "${engine_root}/.chezmoi-managed" ]]
[[ -f "${engine_root}/.chezmoi-toolchain-configured" ]]

second_run="$(install_engine 2>&1)"
[[ "${second_run}" == *"already installed"* ]]

printf 'Unreal Engine installer checks passed\n'
