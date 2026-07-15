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
  if [[ "$1" == "-o" ]]; then
    output="$2"
    shift 2
  else
    shift
  fi
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
PATH="${test_root}/bin:${PATH}" \
  XDG_DATA_HOME="${test_root}/data" \
  bash "${script}"

grep -Fq -- '--connect-timeout 10' "${test_root}/curl.log"
grep -Fq -- '--max-time 120' "${test_root}/curl.log"
grep -Fq -- '--speed-time 15' "${test_root}/curl.log"

: > "${test_root}/curl.log"
PATH="${test_root}/bin:${PATH}" \
  XDG_DATA_HOME="${test_root}/data" \
  bash "${script}"
[[ ! -s "${test_root}/curl.log" ]]

printf 'Developer font installer checks passed\n'
