#!/usr/bin/env bash

# SC2016: probe bodies are deliberately unexpanded here and evaluated in the child.
# SC2310: failure paths are exercised inside conditionals on purpose.
# SC2312: diagnostics inline the captured log for readability.
# SC2154: test_root is assigned by test_setup.
# shellcheck disable=SC2016,SC2310,SC2312,SC2154
set -euo pipefail

# shellcheck disable=SC1091 # resolved at runtime, next to this script
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_setup 1 "$@"
foundation_source="$1"

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

# The foundation owns the EXIT trap, so every probe sources it in a child shell
# rather than in this one.
probe() {
  local body="$1"
  local probe_script="${test_root}/probe.sh"

  {
    printf '#!/usr/bin/env bash\n'
    printf 'set -euo pipefail\n'
    printf 'fail() { printf '"'"'error: %%s\\n'"'"' "$*" >&2; exit 1; }\n'
    printf 'source %q\n' "${foundation_source}"
    printf '%s\n' "${body}"
  } >"${probe_script}"

  PATH="${test_root}/bin:${PATH}" CURL_LOG="${curl_log}" bash "${probe_script}"
}

mkdir -p "${test_root}/bin"
curl_log="${test_root}/curl.log"
: >"${curl_log}"

# Fake curl: logs its arguments, writes the fixture body to -o or to stdout.
cat >"${test_root}/bin/curl" <<'CURL'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${CURL_LOG}"
output=""
url=""
while (( $# > 0 )); do
  case "$1" in
    -o|--output) output="$2"; shift 2 ;;
    http*) url="$1"; shift ;;
    *) shift ;;
  esac
done
if [[ "${url}" == *"/missing"* ]]; then
  printf 'curl: (22) not found\n' >&2
  exit 22
fi
body="artifact-body-for ${url}"
if [[ -n "${output}" ]]; then
  printf '%s' "${body}" >"${output}"
else
  printf '%s' "${body}"
fi
CURL
chmod +x "${test_root}/bin/curl"

# ── artifact_scratch_dir ─────────────────────────────────────────────────────
scratch_dir="$(probe '
first="$(artifact_scratch_dir)"
second="$(artifact_scratch_dir)"
[[ -d "${first}" ]] || fail "scratch directory was not created"
[[ "${first}" == "${second}" ]] || fail "scratch directory was not reused"
# Staged artifacts are private unless the including script widens them.
mode="$(stat -c %a "${first}")"
[[ "${mode}" == "700" ]] || fail "scratch directory mode is ${mode}, expected 700"
printf "%s\n" "${first}"
')"
[[ -n "${scratch_dir}" ]] || fail "probe reported no scratch directory"
[[ ! -e "${scratch_dir}" ]] || fail "scratch directory survived process exit: ${scratch_dir}"

# ── fetch_artifact_text ──────────────────────────────────────────────────────
: >"${curl_log}"
body="$(probe 'fetch_artifact_text --url https://example.invalid/api --header "Accept: application/json"')"
[[ "${body}" == "artifact-body-for https://example.invalid/api" ]] ||
  fail "fetch_artifact_text did not return the response body: ${body}"

for option in --fail --silent --show-error --location --retry 3 --retry-all-errors \
  '--connect-timeout 10' '--max-time 60' '--header Accept: application/json'; do
  grep -Fq -- "${option}" "${curl_log}" ||
    fail "fetch_artifact_text omitted the transport option: ${option}"
done

# ── fetch_verified_artifact: no proof demanded ───────────────────────────────
: >"${curl_log}"
staged="$(probe '
destination="$(artifact_scratch_dir)/plain.bin"
fetch_verified_artifact --url https://example.invalid/plain.bin --dest "${destination}" --label "Plain artifact"
[[ -s "${destination}" ]] || fail "artifact was not written to --dest"
printf "%s\n" "$(cat "${destination}")"
')"
[[ "${staged}" == "artifact-body-for https://example.invalid/plain.bin" ]] ||
  fail "fetch_verified_artifact did not stage the response body: ${staged}"
for option in '--max-time 600' '--speed-limit 1024' '--speed-time 60'; do
  grep -Fq -- "${option}" "${curl_log}" ||
    fail "fetch_verified_artifact omitted the file transport option: ${option}"
done

# A transport failure is fatal by default.
: >"${curl_log}"
if probe '
fetch_verified_artifact --url https://example.invalid/missing --dest "$(artifact_scratch_dir)/x" --label "Missing artifact"
' >/dev/null 2>&1; then
  fail "fetch_verified_artifact ignored a transport failure"
fi

# ── fetch_verified_artifact: --sha256 ────────────────────────────────────────
# Expected digest comes from sha256sum over the fixture body, not from the module.
expected_sha256="$(printf '%s' 'artifact-body-for https://example.invalid/checked.bin' |
  sha256sum | awk '{print $1}')"

probe "
destination=\"\$(artifact_scratch_dir)/checked.bin\"
fetch_verified_artifact --url https://example.invalid/checked.bin --dest \"\${destination}\" \
  --label 'Checked artifact' --sha256 ${expected_sha256}
[[ -s \"\${destination}\" ]] || fail 'verified artifact was discarded'
" >/dev/null || fail "fetch_verified_artifact rejected a matching checksum"

mismatch_output="${test_root}/mismatch.log"
if probe "
fetch_verified_artifact --url https://example.invalid/checked.bin \
  --dest \"\$(artifact_scratch_dir)/checked.bin\" \
  --label 'Checked artifact' --sha256 0000000000000000000000000000000000000000000000000000000000000000
" >"${mismatch_output}" 2>&1; then
  fail "fetch_verified_artifact accepted a mismatched checksum"
fi
grep -Fq 'Checked artifact' "${mismatch_output}" ||
  fail "checksum failure did not name the artifact: $(cat "${mismatch_output}")"

# No published checksum: allowed, but the limitation must stay visible (ADR 0003).
unverified_output="${test_root}/unverified.log"
probe '
fetch_verified_artifact --url https://example.invalid/plain.bin \
  --dest "$(artifact_scratch_dir)/plain.bin" --label "Unchecked artifact"
' >/dev/null 2>"${unverified_output}" || fail "fetch_verified_artifact required a checksum"
grep -Fq 'Unchecked artifact' "${unverified_output}" ||
  fail "missing checksum was not reported for the artifact"
grep -Fqi 'no checksum or signature' "${unverified_output}" ||
  fail "missing proof was not reported accurately: $(cat "${unverified_output}")"

# ── fetch_verified_artifact: --signature-url ─────────────────────────────────
# Fake gpg: reports the fingerprint recorded in the key file, refuses signatures
# whose body mentions "badsig", and records the GNUPGHOME it was handed.
cat >"${test_root}/bin/gpg" <<'GPG'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "${GNUPGHOME:-unset}" >>"${GNUPGHOME_LOG}"
mode=""
arguments=()
while (( $# > 0 )); do
  case "$1" in
    --show-keys) mode="show-keys"; shift ;;
    --verify) mode="verify"; shift ;;
    --import) mode="import"; shift ;;
    --batch|--quiet|--yes|--with-colons) shift ;;
    *) arguments+=("$1"); shift ;;
  esac
done
case "${mode}" in
  show-keys) printf 'fpr:::::::::%s:\n' "$(cat "${arguments[0]}")" ;;
  verify) grep -Fq badsig "${arguments[0]}" && exit 1 || exit 0 ;;
  import) exit 0 ;;
  *) exit 2 ;;
esac
GPG
chmod +x "${test_root}/bin/gpg"

gnupghome_log="${test_root}/gnupghome.log"
: >"${gnupghome_log}"
key_file="${test_root}/signing-key.asc"
printf 'AAAA1111BBBB2222CCCC3333DDDD4444EEEE5555' >"${key_file}"

signature_probe() {
  local signature_path="$1"
  local expected_fingerprint="$2"
  GNUPGHOME_LOG="${gnupghome_log}" probe "
destination=\"\$(artifact_scratch_dir)/signed.zip\"
fetch_verified_artifact --url https://example.invalid/signed.zip --dest \"\${destination}\" \
  --label 'Signed artifact' \
  --signature-url ${signature_path} --key-file ${key_file} --fingerprint ${expected_fingerprint}
[[ -s \"\${destination}\" ]] || fail 'verified artifact was discarded'
"
}

signature_probe https://example.invalid/good.sig AAAA1111BBBB2222CCCC3333DDDD4444EEEE5555 >/dev/null ||
  fail "fetch_verified_artifact rejected a valid signature"
grep -Fq "chezmoi-artifact" "${gnupghome_log}" ||
  fail "signature verification did not use an ephemeral GNUPGHOME: $(cat "${gnupghome_log}")"

bad_fingerprint_output="${test_root}/bad-fingerprint.log"
if signature_probe https://example.invalid/good.sig 9999999999999999999999999999999999999999 \
  >"${bad_fingerprint_output}" 2>&1; then
  fail "fetch_verified_artifact accepted an unexpected signing key fingerprint"
fi
grep -Fq 'Signed artifact' "${bad_fingerprint_output}" ||
  fail "fingerprint failure did not name the artifact"

bad_signature_output="${test_root}/bad-signature.log"
if signature_probe https://example.invalid/badsig.sig AAAA1111BBBB2222CCCC3333DDDD4444EEEE5555 \
  >"${bad_signature_output}" 2>&1; then
  fail "fetch_verified_artifact accepted an invalid signature"
fi
grep -Fq 'Signed artifact' "${bad_signature_output}" ||
  fail "signature failure did not name the artifact"

# A signed artifact needs no checksum warning.
signed_output="${test_root}/signed.log"
signature_probe https://example.invalid/good.sig AAAA1111BBBB2222CCCC3333DDDD4444EEEE5555 \
  >/dev/null 2>"${signed_output}"
grep -Fqi 'does not publish a manifest checksum' "${signed_output}" &&
  fail "signature verification still warned about a missing checksum"

# Demanding both proofs must check both, not silently drop one.
both_output="${test_root}/both.log"
if probe "
fetch_verified_artifact --url https://example.invalid/checked.bin \
  --dest \"\$(artifact_scratch_dir)/both.bin\" --label 'Doubly proven artifact' \
  --sha256 ${expected_sha256} \
  --signature-url https://example.invalid/badsig.sig --key-file ${key_file} \
  --fingerprint AAAA1111BBBB2222CCCC3333DDDD4444EEEE5555
" >"${both_output}" 2>&1; then
  fail "a matching checksum masked an invalid signature"
fi

# ── fetch_verified_artifact: --soft-fail ─────────────────────────────────────
# A soft failure returns non-zero so the caller keeps control, and discards the
# artifact rather than leaving an unverified file behind.
soft_output="${test_root}/soft.log"
soft_result="$(probe '
destination="$(artifact_scratch_dir)/soft.bin"
if fetch_verified_artifact --url https://example.invalid/checked.bin --dest "${destination}" \
  --label "Soft artifact" \
  --sha256 0000000000000000000000000000000000000000000000000000000000000000 --soft-fail; then
  fail "soft failure reported success"
fi
[[ -e "${destination}" ]] && fail "soft failure left the unverified artifact in place"
printf "caller still running\n"
' 2>"${soft_output}")" || fail "--soft-fail aborted the caller instead of returning"
[[ "${soft_result}" == "caller still running" ]] ||
  fail "--soft-fail did not return control to the caller: ${soft_result}"
grep -Fq 'warning' "${soft_output}" ||
  fail "--soft-fail did not warn: $(cat "${soft_output}")"

# A soft transport failure behaves the same way.
probe '
if fetch_verified_artifact --url https://example.invalid/missing \
  --dest "$(artifact_scratch_dir)/missing.bin" --label "Soft missing" --soft-fail; then
  fail "soft transport failure reported success"
fi
printf "caller still running\n"
' >/dev/null 2>&1 || fail "--soft-fail aborted the caller on a transport failure"

printf 'Artifact fetch foundation checks passed\n'
