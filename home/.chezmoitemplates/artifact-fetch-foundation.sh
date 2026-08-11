# Fetching and verifying remote artifacts for managed workstation applications.
#
# Requires fail() from shell-foundation.sh. Include it after `set -euo pipefail`:
# the scratch directory is created and its cleanup registered at include time, so
# no early exit can leak it. This module owns the EXIT trap, and including scripts
# must not install their own.
#
# The scratch directory is private (0700). A caller whose installer runs under a
# different account — apt drops to _apt to read a staged .deb — widens it itself.

artifact_scratch_cleanup() {
  [[ -z "${artifact_scratch_directory:-}" ]] || rm -rf "${artifact_scratch_directory}"
  artifact_scratch_directory=""
}

artifact_scratch_directory="$(mktemp -d "${TMPDIR:-/tmp}/chezmoi-artifact.XXXXXX")"
trap artifact_scratch_cleanup EXIT

artifact_scratch_dir() {
  printf '%s\n' "${artifact_scratch_directory}"
}

# One transport policy for every managed download: fail loudly, follow redirects,
# retry a few times, and never hang on a dead connection.
artifact_transport_options=(
  --fail
  --silent
  --show-error
  --location
  --retry 3
  --retry-delay 2
  --retry-all-errors
  --connect-timeout 10
)

# Files get a generous ceiling because artifacts range from a small zip to a
# multi-hundred-megabyte .deb, so the stall floor rather than the ceiling is what
# aborts a wedged transfer. This is deliberately more patient than the 15s floor
# and 60-120s ceilings the individual installers used before they shared a policy.
artifact_file_transport_options=(
  --speed-limit 1024
  --speed-time 60
  --max-time 600
)

# Responses read as text are small — an API page or an installer script — so the
# ceiling alone is a tight enough guard and no stall floor is needed.
artifact_text_transport_options=(
  --max-time 60
)

# artifact_reject SOFT_FAIL MESSAGE... — abort, or warn and return 1 when soft.
artifact_reject() {
  local soft_fail="$1"
  shift

  if [[ "${soft_fail}" == "true" ]]; then
    printf 'warning: %s\n' "$*" >&2
    return 1
  fi
  fail "$*"
}

# artifact_discard SOFT_FAIL PATH MESSAGE... — reject, and remove the artifact so
# a caller cannot install what failed its proof.
artifact_discard() {
  local soft_fail="$1"
  local discarded="$2"
  shift 2

  rm -f "${discarded}"
  artifact_reject "${soft_fail}" "$*"
}

# fetch_artifact_text --url URL [--header HEADER] — write the response to stdout.
fetch_artifact_text() {
  local url=""
  local headers=()

  while (( $# > 0 )); do
    case "$1" in
      --url) url="$2"; shift 2 ;;
      --header) headers+=(--header "$2"); shift 2 ;;
      *) fail "fetch_artifact_text: unsupported option $1" ;;
    esac
  done

  [[ -n "${url}" ]] || fail "fetch_artifact_text: --url is required"

  curl "${artifact_transport_options[@]}" "${artifact_text_transport_options[@]}" \
    ${headers[@]+"${headers[@]}"} "${url}"
}

# fetch_verified_artifact --url URL --dest PATH --label LABEL [--header HEADER]
#     [--sha256 HEX] [--sha512-base64 BASE64]
#     [--signature-url URL --key-file PATH --fingerprint FPR] [--soft-fail]
#
# Download an artifact and refuse to hand it back unless it matches every proof the
# caller demanded. Without --sha256 or --signature-url the artifact is trusted on
# its official HTTPS URL alone and says so, per ADR 0003.
#
# Fatal on failure unless --soft-fail, which warns and returns 1 instead so the
# caller can degrade rather than abort.
fetch_verified_artifact() {
  local url="" destination="" label=""
  local sha256="" sha512_base64="" signature_url="" key_file="" fingerprint=""
  local soft_fail="false"
  local headers=()

  while (( $# > 0 )); do
    case "$1" in
      --url) url="$2"; shift 2 ;;
      --dest) destination="$2"; shift 2 ;;
      --label) label="$2"; shift 2 ;;
      --header) headers+=(--header "$2"); shift 2 ;;
      --sha256) sha256="$2"; shift 2 ;;
      # The form an Electron vendor publishes in its update manifest.
      --sha512-base64) sha512_base64="$2"; shift 2 ;;
      --signature-url) signature_url="$2"; shift 2 ;;
      --key-file) key_file="$2"; shift 2 ;;
      --fingerprint) fingerprint="$2"; shift 2 ;;
      --soft-fail) soft_fail="true"; shift ;;
      *) fail "fetch_verified_artifact: unsupported option $1" ;;
    esac
  done

  [[ -n "${url}" ]] || fail "fetch_verified_artifact: --url is required"
  [[ -n "${destination}" ]] || fail "fetch_verified_artifact: --dest is required"
  [[ -n "${label}" ]] || fail "fetch_verified_artifact: --label is required"

  if [[ -n "${signature_url}" ]]; then
    [[ -n "${key_file}" ]] || fail "fetch_verified_artifact: --signature-url requires --key-file"
    [[ -n "${fingerprint}" ]] || fail "fetch_verified_artifact: --signature-url requires --fingerprint"
    # Checked before spending a download on an artifact that cannot be verified.
    [[ -s "${key_file}" ]] || fail "${label} signing key is missing at ${key_file}"
  fi

  if [[ -z "${sha256}" && -z "${sha512_base64}" && -z "${signature_url}" ]]; then
    printf 'warning: %s publishes no checksum or signature; using only its official HTTPS URL\n' \
      "${label}" >&2
  fi

  curl "${artifact_transport_options[@]}" "${artifact_file_transport_options[@]}" \
    ${headers[@]+"${headers[@]}"} "${url}" --output "${destination}" ||
    artifact_discard "${soft_fail}" "${destination}" \
      "${label} could not be downloaded from ${url}" || return 1

  if [[ -n "${sha256}" ]]; then
    local actual_sha256
    actual_sha256="$(sha256sum "${destination}" | awk '{print $1}')"
    [[ "${actual_sha256}" == "${sha256}" ]] ||
      artifact_discard "${soft_fail}" "${destination}" \
        "${label} checksum verification failed; expected ${sha256}, got ${actual_sha256}" || return 1
  fi

  if [[ -n "${sha512_base64}" ]]; then
    local actual_sha512_base64
    actual_sha512_base64="$(openssl dgst -sha512 -binary "${destination}" | base64 -w0)"
    [[ "${actual_sha512_base64}" == "${sha512_base64}" ]] ||
      artifact_discard "${soft_fail}" "${destination}" \
        "${label} checksum verification failed; expected ${sha512_base64}, got ${actual_sha512_base64}" || return 1
  fi

  # Every proof the caller demanded is checked; a passing one never excuses another.
  if [[ -n "${signature_url}" ]]; then
    local signature_path="${destination}.sig"
    curl "${artifact_transport_options[@]}" "${artifact_file_transport_options[@]}" \
      "${signature_url}" --output "${signature_path}" ||
      artifact_discard "${soft_fail}" "${destination}" \
        "${label} signature could not be downloaded from ${signature_url}" || return 1

    # Verify against the managed keyring alone, never the user's own trust store.
    local gnupg_home
    gnupg_home="$(mktemp -d "${artifact_scratch_directory}/gnupg.XXXXXX")"
    chmod 0700 "${gnupg_home}"

    local actual_fingerprint
    actual_fingerprint="$(GNUPGHOME="${gnupg_home}" gpg --batch --quiet --show-keys --with-colons \
      "${key_file}" | awk -F: '$1 == "fpr" { print $10; exit }')"
    [[ "${actual_fingerprint}" == "${fingerprint}" ]] ||
      artifact_discard "${soft_fail}" "${destination}" \
        "${label} signing key fingerprint does not match the manifest; expected ${fingerprint}, got ${actual_fingerprint:-unknown}" || return 1

    GNUPGHOME="${gnupg_home}" gpg --batch --quiet --import "${key_file}" >/dev/null 2>&1 ||
      artifact_discard "${soft_fail}" "${destination}" \
        "${label} signing key could not be imported" || return 1
    GNUPGHOME="${gnupg_home}" gpg --batch --verify "${signature_path}" "${destination}" >/dev/null 2>&1 ||
      artifact_discard "${soft_fail}" "${destination}" \
        "${label} signature verification failed" || return 1
  fi
}
