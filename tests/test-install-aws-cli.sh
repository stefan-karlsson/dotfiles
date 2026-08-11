#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
installer="$(test_render_template 'home/.chezmoiscripts/run_onchange_after_17-install-aws-cli.sh.tmpl')"
grep -Fq 'awscli-exe-linux-x86_64.zip' "$installer"
grep -Fq 'awscli-exe-linux-x86_64.zip.sig' "$installer"
grep -Fq 'FB5DB77FD5C118B80511ADA8A6310ACC4672475C' "$installer"
grep -Fq 'installed outside this managed setup' "$installer"

# The installer must demand signature verification, not merely be able to do it.
grep -Fq -- '--signature-url "${signature_url}"' "$installer"
grep -Fq -- '--fingerprint "${expected_fingerprint}"' "$installer"
grep -Fq -- '--key-file "${key_file}"' "$installer"

# The committed keyring must be the key that fingerprint pins, or the pin proves
# nothing.
gpg --batch --show-keys --with-colons "$(test_source_file 'home/dot_local/share/aws-cli/aws-cli-team.asc')" |
  awk -F: '$1 == "fpr" { print $10; exit }' |
  grep -Fqx 'FB5DB77FD5C118B80511ADA8A6310ACC4672475C'

# The manifest names a floor, and the installer must carry one.
grep -Eq 'minimum_version="[0-9]+\.[0-9]+\.[0-9]+"' "$installer"

# The installer names absolute vendor and system paths that no seam redirects and
# no test may create. Only those paths are rewritten here.
install_dir="${test_root}/usr/local/aws-cli"
bin_dir="${test_root}/usr/local/bin"
marker_file="${test_root}/var/lib/chezmoi/aws-cli-v2"
test_home="${test_root}/home"
served_version="${test_root}/vendor/version"
redirected="${test_root}/installer.sh"

sed \
  -e "s|/usr/local/aws-cli|${install_dir}|g" \
  -e "s|/usr/local/bin|${bin_dir}|g" \
  -e "s|/var/lib/chezmoi/aws-cli-v2|${marker_file}|g" \
  "$installer" >"$redirected"

# The signing key the installer refuses to download without.
install -d -m 0755 "${test_home}/.local/share/aws-cli"
printf 'managed keyring\n' >"${test_home}/.local/share/aws-cli/aws-cli-team.asc"

# The vendor archive: an installer that lays down an aws reporting the version the
# official URL served when it ran, the way a real installation records it.
install -d -m 0755 "${test_root}/vendor/aws"
cat >"${test_root}/vendor/aws/install" <<'VENDOR'
#!/usr/bin/env bash
set -euo pipefail
target=""
while (( $# > 0 )); do
  case "$1" in
    --install-dir) target="$2"; shift 2 ;;
    *) shift ;;
  esac
done
version="$(cat "${test_root}/vendor/version")"
mkdir -p "${target}/v2/current/bin"
cat >"${target}/v2/current/bin/aws" <<AWS
#!/usr/bin/env bash
printf 'aws-cli/${version} Python/3.13.0 Linux/6.17.0 exe/x86_64 prompt/off\n'
AWS
chmod 0755 "${target}/v2/current/bin/aws"
VENDOR
chmod 0755 "${test_root}/vendor/aws/install"

test_stub_command curl - <<'STUB'
output=""
while (( $# > 0 )); do
  [[ "$1" != "--output" ]] || output="$2"
  shift
done
[[ -z "${output}" ]] || printf 'artifact\n' >"${output}"
STUB
test_stub_command gpg - <<'STUB'
if [[ " $* " == *" --show-keys "* ]]; then
  printf 'fpr:::::::::FB5DB77FD5C118B80511ADA8A6310ACC4672475C:\n'
fi
exit 0
STUB
test_stub_command unzip - <<'STUB'
destination=""
while (( $# > 0 )); do
  [[ "$1" != "-d" ]] || destination="$2"
  shift
done
cp -R "${test_root}/vendor/aws" "${destination}/aws"
STUB
test_stub_command sudo '"$@"'

# An isolated PATH. The installer refuses to adopt an aws it did not
# install and a host of its own may have one.
for command_name in bash mktemp rm awk sed dpkg install touch dirname mkdir cp cat chmod; do
  ln -s "$(command -v "${command_name}")" "${test_root}/bin/${command_name}"
done

run_installer() {
  PATH="${test_root}/bin" HOME="${test_home}" bash "$redirected"
}

# A new laptop, where the official URL serves a release newer than the floor. The
# latest is what the workstation wants, so a newer version is not an error.
printf '2.36.0\n' >"$served_version"
output="$(run_installer)"
[[ "$output" == *'AWS CLI v2 2.36.0 is installed.'* ]]
[[ -e "$marker_file" ]]

# A rerun keeps what is installed and spends no download on it.
test_reset_calls
output="$(run_installer)"
[[ "$output" == *'AWS CLI v2 2.36.0 is already installed.'* ]]
test_assert_not_called curl

# A release older than the floor stays a failure.
rm -rf "$install_dir" "$marker_file"
printf '2.30.0\n' >"$served_version"
if run_installer >"${test_root}/older.out" 2>&1; then
  printf 'error: a release older than the supported floor was accepted\n' >&2
  exit 1
fi
grep -Fq 'older than the supported' "${test_root}/older.out"

# Having rejected that release, the installer must still own what it laid down:
# a rerun replaces it rather than reading its own work as unmanaged.
printf '2.36.0\n' >"$served_version"
output="$(run_installer)"
[[ "$output" == *'AWS CLI v2 2.36.0 is installed.'* ]]

printf 'AWS CLI installer checks passed\n'
