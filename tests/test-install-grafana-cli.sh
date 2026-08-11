#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
installer="$(test_render_template 'home/.chezmoiscripts/run_onchange_after_17-install-grafana-cli.sh.tmpl')"
zshrc="$(test_render_template 'home/dot_zshrc.tmpl')"

grep -Fq 'https://github.com/grafana/gcx/releases/download/v1.0.0/gcx_1.0.0_linux_amd64.tar.gz' "$installer"
grep -Fq 'c88c65958d19d83dc3a192a2a5037e08307a9c776019f24249b89f369c9c4d41' "$installer"
grep -Fq 'resolves to an unmanaged installation' "$installer"

# The archive must be admitted on its checksum, not merely downloaded from an
# official URL: the release publishes a checksums file, so the pin is checkable.
grep -Fq -- '--sha256 "${expected_sha256}"' "$installer"

# The vendor's install.sh is what the pinned archive replaces, so no rendering may
# reach for it.
! grep -Fq 'install.sh' "$installer"

# The Developer Shell completes gcx once the binary is on PATH.
test_assert_file_contains 'gcx completion zsh' "$zshrc"

# The installer names absolute system paths that no seam redirects and no test may
# create. Only those paths are rewritten here.
bin_dir="${test_root}/usr/local/bin"
marker_file="${test_root}/var/lib/chezmoi/grafana-cli"
served_version="${test_root}/vendor/version"
redirected="${test_root}/installer.sh"

sed \
  -e "s|/usr/local/bin|${bin_dir}|g" \
  -e "s|/var/lib/chezmoi/grafana-cli|${marker_file}|g" \
  "$installer" >"$redirected"

# The release archive: a gcx reporting the version the pinned URL served, in the
# form the real binary reports it.
install -d -m 0755 "${test_root}/vendor"
printf '1.0.0\n' >"$served_version"

test_stub_command curl - <<'STUB'
output=""
while (( $# > 0 )); do
  [[ "$1" != "--output" ]] || output="$2"
  shift
done
[[ -z "${output}" ]] || printf 'archive\n' >"${output}"
STUB
# The checksum the manifest pins, so the artifact the stubbed download produced
# passes verification the way the real archive does.
test_stub_command sha256sum \
  'printf "c88c65958d19d83dc3a192a2a5037e08307a9c776019f24249b89f369c9c4d41  %s\n" "$1"'
test_stub_command tar - <<'STUB'
destination=""
while (( $# > 0 )); do
  [[ "$1" != "--directory" ]] || destination="$2"
  shift
done
version="$(cat "${test_root}/vendor/version")"
cat >"${destination}/gcx" <<GCX
#!/usr/bin/env bash
printf 'gcx version ${version} built from 45e64ca on 2026-07-28T12:01:50Z\n'
GCX
chmod 0755 "${destination}/gcx"
STUB
test_stub_command sudo '"$@"'

# An isolated PATH. The installer refuses to adopt a gcx it did not
# install and a host of its own may have one.
for command_name in bash mktemp rm awk sed install touch dirname mkdir cat chmod printf; do
  ln -s "$(command -v "${command_name}")" "${test_root}/bin/${command_name}"
done

run_installer() {
  PATH="${test_root}/bin" bash "$redirected"
}

# A new laptop, where the pinned release is what lands.
output="$(run_installer)"
[[ "$output" == *'Grafana CLI 1.0.0 is installed.'* ]]
[[ -x "${bin_dir}/gcx" ]]
[[ -e "$marker_file" ]]

# A rerun keeps what is installed and spends no download on it.
test_reset_calls
output="$(run_installer)"
[[ "$output" == *'Grafana CLI 1.0.0 is already installed.'* ]]
test_assert_not_called curl

# A release other than the pinned one is a failure, whichever way the versions
# diverged. The binary is removed and the marker kept, the state a managed laptop
# is in when the pin moved, so the installer reaches for the archive again.
rm -f "${bin_dir}/gcx"
printf '1.1.0\n' >"$served_version"
if run_installer >"${test_root}/mismatch.out" 2>&1; then
  printf 'error: a release other than the pinned one was accepted\n' >&2
  exit 1
fi
grep -Fq 'reported version 1.1.0 after installing 1.0.0' "${test_root}/mismatch.out"

# Having rejected that release, the installer must still own what it laid down:
# a rerun replaces it rather than reading its own work as unmanaged.
printf '1.0.0\n' >"$served_version"
output="$(run_installer)"
[[ "$output" == *'Grafana CLI 1.0.0 is installed.'* ]]

# A gcx no marker accounts for is left alone rather than overwritten.
rm -f "$marker_file"
if run_installer >"${test_root}/unmanaged.out" 2>&1; then
  printf 'error: an unmanaged gcx was overwritten\n' >&2
  exit 1
fi
grep -Fq 'resolves to an unmanaged installation' "${test_root}/unmanaged.out"

printf 'Grafana CLI installer checks passed\n'
