#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
script="$(test_render_template 'home/.chezmoiscripts/run_always_after_21-install-developer-font.sh.tmpl')"

mkdir -p "${test_root}/tmp"

test_stub_command curl - <<'STUB'
output=""
while (($# > 0)); do
  case "$1" in
    -o | --output) output="$2"; shift 2 ;;
    *) shift ;;
  esac
done
[[ -n "${output}" ]] && : >"${output}"
STUB

test_stub_command unzip - <<'STUB'
output_dir=""
while (($# > 0)); do
  if [[ "$1" == '-d' ]]; then
    output_dir="$2"
    shift 2
  else
    shift
  fi
done
mkdir -p "${output_dir}"
: >"${output_dir}/FiraCodeNerdFontMono-Regular.ttf"
STUB

test_stub_command fc-cache

run_installer() {
  test_reset_calls
  XDG_DATA_HOME="${test_root}/data" \
    TMPDIR="${test_root}/tmp" \
    test_run_script "${script}"
}

run_installer

test_assert_called '--connect-timeout 10'
test_assert_called '--max-time 600'
test_assert_called '--speed-time 60'

# Already installed: the font is not fetched again.
run_installer
test_assert_not_called 'curl'

# The already-installed path exits early; it must not leave a scratch directory.
[[ -z "$(ls -A "${test_root}/tmp")" ]] || {
  printf 'installer leaked a scratch directory: %s\n' "$(ls -A "${test_root}/tmp")" >&2
  exit 1
}

printf 'Developer font installer checks passed\n'
