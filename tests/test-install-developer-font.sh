#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=test-helpers.sh
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_setup 1 "$@"
script="$1"

mkdir -p "${test_root}/bin"
: > "${test_root}/curl.log"

cat >"${test_root}/bin/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "${CURL_LOG}"
output=""
while (( $# > 0 )); do
  case "$1" in
    -o|--output) output="$2"; shift 2 ;;
    *) shift ;;
  esac
done
[[ -n "${output}" ]] && : > "${output}"
EOF
chmod +x "${test_root}/bin/curl"

cat >"${test_root}/bin/unzip" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
output_dir=""
while (( $# > 0 )); do
  if [[ "$1" == "-d" ]]; then
    output_dir="$2"
    shift 2
  else
    shift
  fi
done
mkdir -p "${output_dir}"
: > "${output_dir}/FiraCodeNerdFontMono-Regular.ttf"
EOF
chmod +x "${test_root}/bin/unzip"

cat >"${test_root}/bin/fc-cache" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "${test_root}/bin/fc-cache"

export CURL_LOG="${test_root}/curl.log"
mkdir -p "${test_root}/tmp"

run_installer() {
  PATH="${test_root}/bin:${PATH}" \
    XDG_DATA_HOME="${test_root}/data" \
    TMPDIR="${test_root}/tmp" \
    bash "${script}"
}

run_installer

grep -Fq -- '--connect-timeout 10' "${test_root}/curl.log"
grep -Fq -- '--max-time 600' "${test_root}/curl.log"
grep -Fq -- '--speed-time 60' "${test_root}/curl.log"

: > "${test_root}/curl.log"
run_installer
[[ ! -s "${test_root}/curl.log" ]]

# The already-installed path exits early; it must not leave a scratch directory.
[[ -z "$(ls -A "${test_root}/tmp")" ]] || {
  printf 'installer leaked a scratch directory: %s\n' "$(ls -A "${test_root}/tmp")" >&2
  exit 1
}

printf 'Developer font installer checks passed\n'
