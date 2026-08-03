#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"

installer='home/.chezmoiscripts/run_always_after_21-configure-slay-cli.sh.tmpl'
vendor_path='/opt/SlayZone/resources/bin/slay'
slay_cli_source="${test_root}/opt/SlayZone/resources/bin/slay"

install -d -m 0755 "$(dirname -- "${slay_cli_source}")"
printf '#!/usr/bin/env bash\n' >"${slay_cli_source}"
chmod 0755 "${slay_cli_source}"

# The installer names the CLI's absolute vendor path, which no seam redirects and
# no test may create. Only that path is rewritten here: the Bootstrap profile is
# an argument to the fixture, not a substitution.
configure_slay_cli() {
  local profile="$1"
  local home="$2"
  local rendered
  local redirected="${test_root}/installer-${profile}.sh"

  rendered="$(test_render_template "${installer}" "${profile}")"
  sed "s|${vendor_path}|${slay_cli_source}|g" "${rendered}" >"${redirected}"
  HOME="${home}" test_run_script "${redirected}"
}

# The SlayZone CLI belongs to the private profile overlay.
private_home="${test_root}/private-home"
private_link="${private_home}/.local/bin/slay"
report="$(configure_slay_cli private "${private_home}")"

[[ -L "${private_link}" ]]
[[ "$(readlink -f "${private_link}")" == "$(readlink -f "${slay_cli_source}")" ]]
[[ "${report}" == *"${private_link}"* ]]
[[ "${report}" == *'Node 24+ is provided by mise'* ]]

# Rerunning leaves the existing link in place.
configure_slay_cli private "${private_home}" >/dev/null
[[ -L "${private_link}" ]]

# A link to something else is an unmanaged CLI the installer must not adopt.
ln -sf /bin/true "${private_link}"
if configure_slay_cli private "${private_home}" >/dev/null 2>&1; then
  printf 'the installer adopted an unmanaged SlayZone CLI link\n' >&2
  exit 1
fi
rm -f "${private_link}"

# Under every other profile the CLI is not installed at all.
for profile in default company; do
  other_home="${test_root}/${profile}-home"
  configure_slay_cli "${profile}" "${other_home}"
  [[ ! -e "${other_home}/.local/bin/slay" ]]
done

# The Developer Shell loads the CLI's completions when it is present.
test_assert_file_contains \
  'source <(slay completions zsh 2>/dev/null)' \
  "$(test_render_template 'home/dot_zshrc.tmpl')"

printf 'SlayZone CLI tests passed\n'
