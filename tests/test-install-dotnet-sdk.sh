#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=test-helpers.sh
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_setup 1 "$@"
script="$1"

mkdir -p "${test_root}/bin" "${test_root}/home"
: > "${test_root}/installer-actions"

printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf "%s\n" "$*" >> "$TEST_ROOT/installer-actions"' \
  'mkdir -p "$HOME/.dotnet"' \
  'printf "#!/usr/bin/env bash\nprintf 10.0.301\n" > "$HOME/.dotnet/dotnet"' \
  'chmod +x "$HOME/.dotnet/dotnet"' > "${test_root}/fake-dotnet-install.sh"
chmod +x "${test_root}/fake-dotnet-install.sh"

printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf "%s\n" "$*" >> "$TEST_ROOT/installer-actions"' \
  'output=""' \
  'while (($# > 0)); do' \
  '  if [[ "$1" == "--output" ]]; then output="$2"; shift 2; else shift; fi' \
  'done' \
  '[[ -n "$output" ]]' \
  'cp "$TEST_ROOT/fake-dotnet-install.sh" "$output"' > "${test_root}/bin/curl"
chmod +x "${test_root}/bin/curl"

export TEST_ROOT="${test_root}"
PATH="${test_root}/bin:${PATH}" HOME="${test_root}/home" /usr/bin/bash "${script}"
grep -Fq -- '--version 10.0.301' "${test_root}/installer-actions"
grep -Fq -- '--install-dir' "${test_root}/installer-actions"
[[ "$(readlink "${test_root}/home/.local/bin/dotnet")" == "${test_root}/home/.dotnet/dotnet" ]]

printf '.NET SDK installation checks passed\n'
