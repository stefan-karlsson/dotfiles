#!/usr/bin/env bash

# shellcheck disable=SC1091,SC2016,SC2154

set -euo pipefail

# shellcheck source=test-helpers.sh
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_require_args 2 "$@"
installer="$1"
zshrc="$2"

grep -Fq 'slay_cli_source="/opt/SlayZone/resources/bin/slay"' "${installer}"
grep -Fq 'slay_cli_target="${HOME}/.local/bin/slay"' "${installer}"
grep -Fq 'mkdir -p "$(dirname "${slay_cli_target}")"' "${installer}"
grep -Fq 'ln -s "${slay_cli_source}" "${slay_cli_target}"' "${installer}"
grep -Fq '[[ "${profile_name}" == "private" ]] || exit 0' "${installer}"
grep -Fq 'Node 24+ is provided by mise' "${installer}"
grep -Fq 'source <(slay completions zsh 2>/dev/null)' "${zshrc}"

test_setup 0
source_root="${test_root}/opt/SlayZone/resources/bin"
mkdir -p "${source_root}"
printf '#!/usr/bin/env bash\n' > "${source_root}/slay"
chmod 0755 "${source_root}/slay"

private_installer="${test_root}/private-installer.sh"
sed \
  -e "s|/opt/SlayZone/resources/bin/slay|${source_root}/slay|g" \
  -e 's/profile_name="default"/profile_name="private"/' \
  "${installer}" > "${private_installer}"
chmod 0755 "${private_installer}"
HOME="${test_root}/home" bash "${private_installer}"
[[ -L "${test_root}/home/.local/bin/slay" ]]
linked_source="$(readlink -f "${test_root}/home/.local/bin/slay")"
expected_source="$(readlink -f "${source_root}/slay")"
[[ "${linked_source}" == "${expected_source}" ]]
HOME="${test_root}/home" bash "${private_installer}"

HOME="${test_root}/company-home" bash "${installer}"
[[ ! -e "${test_root}/company-home/.local/bin/slay" ]]

printf 'SlayZone CLI tests passed\n'
