#!/usr/bin/env bash

set -euo pipefail

[[ $# -eq 1 ]] || {
  printf 'usage: %s <rendered-script>\n' "$0" >&2
  exit 2
}

script="$1"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

mkdir -p "$test_root/bin" "$test_root/home/.local/share/gnome-shell/extensions"
mkdir -p "$test_root/home/.local/share/gnome-shell/extensions/appindicatorsupport@rgcjonas.gmail.com"
: > "$test_root/install.log"
: > "$test_root/enable.log"
: > "$test_root/disable.log"
: > "$test_root/uninstall.log"
: > "$test_root/download.log"
printf '%s\n' "['existing@example.com', 'appindicatorsupport@rgcjonas.gmail.com', 'ubuntu-appindicators@ubuntu.com']" > "$test_root/enabled-extensions"

printf '%s\n' '#!/usr/bin/env bash' 'printf "GNOME Shell 50.1\\n"' > "$test_root/bin/gnome-shell"
printf '%s\n' '#!/usr/bin/env bash' 'exec /usr/bin/jq "$@"' > "$test_root/bin/jq"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'set -euo pipefail' \
  'url=""' \
  'output=""' \
  'while (($#)); do' \
  '  case "$1" in' \
  '    -o) output="$2"; shift 2 ;;' \
  '    http*) url="$1"; shift ;;' \
  '    *) shift ;;' \
  '  esac' \
  'done' \
  'if [[ "$url" == *"format=zip"* ]]; then' \
  '  printf "%s\\n" "$url" >> "$TEST_ROOT/download.log"' \
  '  : > "$output"' \
  'elif [[ "$url" == *"/versions/"* ]]; then' \
  '  printf "%s\\n" '\''{"results":[{"status":3,"version":105,"shell_versions":[{"major":50,"minor":-1,"patch":-1}]}],"next":null}'\''' \
  'else' \
  '  printf "unexpected curl URL: %s\\n" "$url" >&2' \
  '  exit 1' \
  'fi' > "$test_root/bin/curl"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'set -euo pipefail' \
  'case "$1" in' \
  '  install) printf "install\\n" >> "$TEST_ROOT/install.log" ;;' \
  '  disable) printf "%s\\n" "$2" >> "$TEST_ROOT/disable.log"; sed -i -e "s/, '\''appindicatorsupport@rgcjonas.gmail.com'\''//" -e "s/, '\''ubuntu-appindicators@ubuntu.com'\''//" "$TEST_ROOT/enabled-extensions" ;;' \
  '  uninstall) printf "%s\\n" "$2" >> "$TEST_ROOT/uninstall.log"; rm -rf "$TEST_ROOT/home/.local/share/gnome-shell/extensions/$2" ;;' \
  '  enable) printf "%s\\n" "$2" >> "$TEST_ROOT/enable.log" ;;' \
  '  *) printf "unexpected gnome-extensions command: %s\\n" "$*" >&2; exit 1 ;;' \
  'esac' > "$test_root/bin/gnome-extensions"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'set -euo pipefail' \
  'case "$1:$2:$3" in' \
  '  get:org.gnome.shell:enabled-extensions) cat "$TEST_ROOT/enabled-extensions" ;;' \
  '  set:org.gnome.shell:enabled-extensions) printf "%s\\n" "$4" > "$TEST_ROOT/enabled-extensions"; printf "%s\\n" "$4" >> "$TEST_ROOT/enable.log" ;;' \
  '  *) printf "unexpected gsettings command: %s\\n" "$*" >&2; exit 1 ;;' \
  'esac' > "$test_root/bin/gsettings"
chmod +x "$test_root/bin/"*
export TEST_ROOT="$test_root"

run_installer() {
  HOME="$test_root/home" \
  XDG_DATA_HOME="$test_root/home/.local/share" \
  XDG_CURRENT_DESKTOP=ubuntu:GNOME \
  DESKTOP_SESSION=ubuntu \
  DBUS_SESSION_BUS_ADDRESS=mock \
  XDG_RUNTIME_DIR="$test_root/runtime" \
  PATH="$test_root/bin:$PATH" \
    bash "$script" "$@"
}

run_installer
[[ "$(wc -l < "$test_root/install.log")" == 4 ]]
[[ "$(wc -l < "$test_root/enable.log")" == 6 ]]
enabled_extensions="$(cat "$test_root/enabled-extensions")"
grep -Fq 'existing@example.com' <<<"$enabled_extensions"
grep -Fq "dash-to-dock@micxgx.gmail.com" <<<"$enabled_extensions"
grep -Fq "blur-my-shell@aunetx" <<<"$enabled_extensions"
grep -Fq "Vitals@CoreCoding.com" <<<"$enabled_extensions"
grep -Fq "live-lockscreen@nick-redwill" <<<"$enabled_extensions"
! grep -Fq "appindicatorsupport@rgcjonas.gmail.com" <<<"$enabled_extensions"
! grep -Fq "ubuntu-appindicators@ubuntu.com" <<<"$enabled_extensions"
grep -Fq 'format=zip' "$test_root/download.log"

for extension in dash-to-dock@micxgx.gmail.com blur-my-shell@aunetx Vitals@CoreCoding.com live-lockscreen@nick-redwill; do
  mkdir -p "$test_root/home/.local/share/gnome-shell/extensions/$extension"
  printf '{"version":105}\n' > "$test_root/home/.local/share/gnome-shell/extensions/$extension/metadata.json"
done

: > "$test_root/install.log"
: > "$test_root/enable.log"
run_installer >/dev/null
[[ ! -s "$test_root/install.log" ]]
[[ ! -s "$test_root/enable.log" ]]

grep -Fxq 'appindicatorsupport@rgcjonas.gmail.com' "$test_root/disable.log"
grep -Fxq 'ubuntu-appindicators@ubuntu.com' "$test_root/disable.log"
grep -Fxq 'appindicatorsupport@rgcjonas.gmail.com' "$test_root/uninstall.log"

printf 'GNOME Shell extension installer checks passed\n'
