#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
script="$(test_render_template 'home/.chezmoiscripts/run_always_after_27-install-gnome-shell-extensions.sh.tmpl')"

extensions_dir="${test_root}/home/.local/share/gnome-shell/extensions"
mkdir -p "${extensions_dir}/appindicatorsupport@rgcjonas.gmail.com"
printf '%s\n' "['existing@example.com', 'appindicatorsupport@rgcjonas.gmail.com', 'ubuntu-appindicators@ubuntu.com']" \
  >"${test_root}/enabled-extensions"

test_stub_command gnome-shell "printf 'GNOME Shell 50.1\\n'"
test_stub_command jq 'exec /usr/bin/jq "$@"'

# Serves the extension metadata the installer queries, and an empty zip for the
# download it decides to make.
test_stub_command curl - <<'STUB'
url=""
output=""
while (($#)); do
  case "$1" in
    -o | --output) output="$2"; shift 2 ;;
    http*) url="$1"; shift ;;
    *) shift ;;
  esac
done
if [[ "${url}" == *'format=zip'* ]]; then
  : >"${output}"
elif [[ "${url}" == *'/versions/'* ]]; then
  printf '%s\n' '{"results":[{"status":3,"version":105,"shell_versions":[{"major":50,"minor":-1,"patch":-1}]}],"next":null}'
else
  printf 'unexpected curl URL: %s\n' "${url}" >&2
  exit 1
fi
STUB

# Disabling drops the extension from the enabled list, and uninstalling removes
# its directory, so the installer sees the effect of its own calls.
test_stub_command gnome-extensions - <<'STUB'
case "$1" in
  install) ;;
  disable)
    sed -i \
      -e "s/, 'appindicatorsupport@rgcjonas.gmail.com'//" \
      -e "s/, 'ubuntu-appindicators@ubuntu.com'//" \
      -e "s/, 'ubuntu-dock@ubuntu.com'//" \
      "${test_root}/enabled-extensions"
    ;;
  info)
    [[ "$2" == 'ubuntu-dock@ubuntu.com' ]]
    printf 'State: ERROR\n'
    ;;
  uninstall) rm -rf "${test_root}/home/.local/share/gnome-shell/extensions/$2" ;;
  enable) ;;
  *) printf 'unexpected gnome-extensions command: %s\n' "$*" >&2; exit 1 ;;
esac
STUB

test_stub_command gsettings - <<'STUB'
case "$1:$2:$3" in
  get:org.gnome.shell:enabled-extensions) cat "${test_root}/enabled-extensions" ;;
  set:org.gnome.shell:enabled-extensions) printf '%s\n' "$4" >"${test_root}/enabled-extensions" ;;
  *) printf 'unexpected gsettings command: %s\n' "$*" >&2; exit 1 ;;
esac
STUB

# shellcheck disable=SC2120 # extra arguments are optional
run_installer() {
  test_reset_calls
  HOME="${test_root}/home" \
    XDG_DATA_HOME="${test_root}/home/.local/share" \
    XDG_CURRENT_DESKTOP=ubuntu:GNOME \
    DESKTOP_SESSION=ubuntu \
    DBUS_SESSION_BUS_ADDRESS=mock \
    XDG_RUNTIME_DIR="${test_root}/runtime" \
    test_run_script "${script}" "$@"
}

run_installer
[[ "$(grep -c '^gnome-extensions install' "${test_call_log}")" == 4 ]]
# Extensions are enabled by writing the shell's enabled-extensions key, not with
# `gnome-extensions enable`.
[[ "$(grep -c '^gsettings set org.gnome.shell enabled-extensions' "${test_call_log}")" == 6 ]]
test_assert_not_called 'gnome-extensions enable'
enabled_extensions="$(cat "${test_root}/enabled-extensions")"
grep -Fq 'existing@example.com' <<<"${enabled_extensions}"
grep -Fq 'dash-to-dock@micxgx.gmail.com' <<<"${enabled_extensions}"
grep -Fq 'blur-my-shell@aunetx' <<<"${enabled_extensions}"
grep -Fq 'Vitals@CoreCoding.com' <<<"${enabled_extensions}"
grep -Fq 'live-lockscreen@nick-redwill' <<<"${enabled_extensions}"
! grep -Fq 'appindicatorsupport@rgcjonas.gmail.com' <<<"${enabled_extensions}"
! grep -Fq 'ubuntu-appindicators@ubuntu.com' <<<"${enabled_extensions}"
test_assert_called 'format=zip'

# The conflicting Ubuntu extensions are disabled, and the one we ship a
# replacement for is removed outright.
test_assert_called 'gnome-extensions disable appindicatorsupport@rgcjonas.gmail.com'
test_assert_called 'gnome-extensions disable ubuntu-appindicators@ubuntu.com'
test_assert_called 'gnome-extensions disable ubuntu-dock@ubuntu.com'
test_assert_called 'gnome-extensions uninstall appindicatorsupport@rgcjonas.gmail.com'

for extension in dash-to-dock@micxgx.gmail.com blur-my-shell@aunetx Vitals@CoreCoding.com live-lockscreen@nick-redwill; do
  mkdir -p "${extensions_dir}/${extension}"
  printf '{"version":105}\n' >"${extensions_dir}/${extension}/metadata.json"
done

# Already installed and enabled: nothing is fetched, installed, or written again.
run_installer >/dev/null
test_assert_not_called 'gnome-extensions install'
test_assert_not_called 'gsettings set'
test_assert_not_called 'format=zip'

printf 'GNOME Shell extension installer checks passed\n'
