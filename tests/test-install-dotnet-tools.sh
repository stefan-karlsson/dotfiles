#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=test-helpers.sh
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_setup 1 "$@"
script="$1"

mkdir -p "${test_root}/bin" "${test_root}/home" "${test_root}/empty"
: > "${test_root}/tool-actions"
printf '%s\n' 'amazon.lambda.tools' 'unrelated.tool' > "${test_root}/installed-tools"

printf '%s\n' \
  '#!/usr/bin/env bash' \
  'case "$1:$2:$3" in' \
  '  tool:list:--global)' \
  '    printf '\''{"version":1,"data":['\''' \
  '    first=true' \
  '    while IFS= read -r package; do' \
  '      [[ -n "$package" ]] || continue' \
  '      [[ "$first" == true ]] || printf ","' \
  '      printf '\''{"packageId":"%s"}'\'' "$package"' \
  '      first=false' \
  '    done < "$TEST_ROOT/installed-tools"' \
  '    printf '\'']}\n'\''' \
  '    ;;' \
  '  tool:update:--global|tool:install:--global)' \
  '    printf "%s %s\\n" "$2" "$4" >> "$TEST_ROOT/tool-actions"' \
  '    grep -Fxq "$4" "$TEST_ROOT/installed-tools" || printf "%s\\n" "$4" >> "$TEST_ROOT/installed-tools"' \
  '    ;;' \
  '  *) printf "unexpected dotnet call: %s\\n" "$*" >&2; exit 1 ;;' \
  'esac' > "${test_root}/bin/dotnet"
chmod +x "${test_root}/bin/dotnet"
mkdir -p "${test_root}/home/.dotnet"
cp "${test_root}/bin/dotnet" "${test_root}/home/.dotnet/dotnet"

export TEST_ROOT="${test_root}"
PATH="${test_root}/bin:${PATH}" HOME="${test_root}/home" bash "${script}"
grep -Fxq 'install dotnet-ef' "${test_root}/tool-actions"
grep -Fxq 'update Amazon.Lambda.Tools' "${test_root}/tool-actions"
grep -Fxq 'install Aspire.Cli' "${test_root}/tool-actions"
grep -Fxq 'unrelated.tool' "${test_root}/installed-tools"
! grep -Fq 'unrelated.tool' "${test_root}/tool-actions"

: > "${test_root}/tool-actions"
printf '%s\n' 'amazon.lambda.tools' 'dotnet-ef' 'aspire.cli' 'unrelated.tool' > "${test_root}/installed-tools"
PATH="${test_root}/bin:${PATH}" HOME="${test_root}/home" bash "${script}"
[[ "$(wc -l < "${test_root}/tool-actions")" == 3 ]]
! grep -Fq 'install ' "${test_root}/tool-actions"
! grep -Fq 'unrelated.tool' "${test_root}/tool-actions"

if PATH="${test_root}/empty" HOME="${test_root}/missing-home" /usr/bin/bash "${script}" >/dev/null 2>&1; then
  printf 'expected missing dotnet to fail\n' >&2
  exit 1
fi

printf 'Global .NET tool installation checks passed\n'
