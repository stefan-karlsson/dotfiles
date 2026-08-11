#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
installer="$(test_render_template 'home/.chezmoiscripts/run_always_after_19-install-nosql-workbench.sh.tmpl')"

grep -Fq 'https://dy9cqqaswpltd.cloudfront.net/NoSQL_Workbench.AppImage' "$installer"
grep -Fq 'https://dy9cqqaswpltd.cloudfront.net/latest-linux.yml' "$installer"
# The vendor's own checksum is what admits the download.
grep -Fq -- '--sha512-base64 "${published_sha512}"' "$installer"

test_home="${test_root}/home"
served="${test_root}/served.AppImage"
printf 'appimage payload\n' >"$served"
served_sha512="$(openssl dgst -sha512 -binary "$served" | base64 -w0)"

# The vendor: a manifest naming the current release, and the AppImage itself. The
# manifest repeats its checksum in an indented per-file block, which must not be
# mistaken for the top-level one.
manifest="${test_root}/latest-linux.yml"
{
  printf 'version: 3.20.3\n'
  printf 'files:\n'
  printf '  - url: NoSQL Workbench-linux-3.20.3.AppImage\n'
  printf '    sha512: aW5kZW50ZWQtaW1wb3N0b3I=\n'
  printf 'path: NoSQL Workbench-linux-3.20.3.AppImage\n'
  printf 'sha512: %s\n' "$served_sha512"
} >"$manifest"

test_stub_command curl - <<'STUB'
output=""
url=""
for argument in "$@"; do
  [[ "$argument" != http* ]] || url="$argument"
done
while (( $# > 0 )); do
  [[ "$1" != "--output" ]] || output="$2"
  shift
done
case "$url" in
  *latest-linux.yml) payload="${test_root}/latest-linux.yml" ;;
  *NoSQL_Workbench.AppImage) payload="${test_root}/served.AppImage" ;;
  *) exit 22 ;;
esac
if [[ -n "$output" ]]; then
  cat "$payload" >"$output"
else
  cat "$payload"
fi
STUB

run_installer() {
  HOME="$test_home" test_run_script "$installer"
}

output="$(run_installer)"
[[ "$output" == *'Installing NoSQL Workbench for DynamoDB 3.20.3'* ]]
[[ "$output" == *'3.20.3 is installed.'* ]]
[[ "$output" == *'needs a JRE 17 or newer'* ]]

appimage="${test_home}/.local/share/nosql-workbench/nosql-workbench.AppImage"
desktop="${test_home}/.local/share/applications/nosql-workbench.desktop"
[[ -x "$appimage" ]]
[[ "$(cat "$appimage")" == 'appimage payload' ]]
test_assert_file_contains "Exec=${appimage}" "$desktop"
test_assert_file_contains 'Categories=Development;Database;' "$desktop"
test_assert_file_contains 'Name=NoSQL Workbench for DynamoDB' "$desktop"
[[ "$(cat "${test_home}/.local/share/nosql-workbench/installed-version")" == '3.20.3' ]]

# The published version is already installed: the manifest is read, the AppImage
# is not fetched again.
test_reset_calls
output="$(run_installer)"
[[ "$output" == *'3.20.3 is already installed.'* ]]
test_assert_not_called 'NoSQL_Workbench.AppImage'

# A newer release replaces it.
sed -i 's/^version: 3.20.3$/version: 3.21.0/' "$manifest"
output="$(run_installer)"
[[ "$output" == *'3.21.0 is installed.'* ]]
[[ "$(cat "${test_home}/.local/share/nosql-workbench/installed-version")" == '3.21.0' ]]

# An AppImage that does not match the manifest's checksum is refused. The version
# has to move too, or the installer would rightly not fetch anything at all.
sed -i 's/^version: 3.21.0$/version: 3.22.0/' "$manifest"
printf 'tampered payload\n' >"$served"
if run_installer >"${test_root}/tampered.out" 2>&1; then
  printf 'error: an AppImage that failed its checksum was accepted\n' >&2
  exit 1
fi
grep -Fq 'checksum verification failed' "${test_root}/tampered.out"
