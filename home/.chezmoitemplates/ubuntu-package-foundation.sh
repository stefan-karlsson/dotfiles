{{- /* Shared Ubuntu package-source policy. Keep this file source-only: it is rendered into standalone scripts. */ -}}
{{- $profile_data := get . "profile" | default (dict) -}}
{{- $profile_name := get $profile_data "name" | default "default" -}}
profile_name={{ $profile_name | quote }}
case "${profile_name}" in
  default|private|company) ;;
  *) fail "invalid persisted bootstrap profile: ${profile_name}" ;;
esac

# shellcheck disable=SC2034
repository_names=(
{{- range .packages.ubuntu.repositories }}
  {{ .name | quote }}
{{- end }}
)

declare -A repository_labels=(
{{- range .packages.ubuntu.repositories }}
  [{{ .name }}]={{ .label | quote }}
{{- end }}
)
declare -A repository_profiles=(
{{- range .packages.ubuntu.repositories }}
  [{{ .name }}]={{ get . "profile" | default "" | quote }}
{{- end }}
)
declare -A repository_uris=(
{{- range .packages.ubuntu.repositories }}
  [{{ .name }}]={{ .repository_uri | quote }}
{{- end }}
)
declare -A repository_key_urls=(
{{- range .packages.ubuntu.repositories }}
  [{{ .name }}]={{ .key_url | quote }}
{{- end }}
)
declare -A repository_key_files=(
{{- range .packages.ubuntu.repositories }}
  [{{ .name }}]={{ .key_file | quote }}
{{- end }}
)
declare -A repository_key_installs=(
{{- range .packages.ubuntu.repositories }}
  [{{ .name }}]={{ .key_install | quote }}
{{- end }}
)
declare -A repository_key_modes=(
{{- range .packages.ubuntu.repositories }}
  [{{ .name }}]={{ .key_mode | default "" | quote }}
{{- end }}
)
declare -A repository_key_fingerprints=(
{{- range .packages.ubuntu.repositories }}
  [{{ .name }}]={{ join " " .key_fingerprints | quote }}
{{- end }}
)
declare -A repository_source_files=(
{{- range .packages.ubuntu.repositories }}
  [{{ .name }}]={{ .source_file | quote }}
{{- end }}
)
declare -A repository_legacy_source_files=(
{{- range .packages.ubuntu.repositories }}
  [{{ .name }}]={{ join " " .legacy_source_files | quote }}
{{- end }}
)
declare -A repository_source_formats=(
{{- range .packages.ubuntu.repositories }}
  [{{ .name }}]={{ .source_format | quote }}
{{- end }}
)
declare -A repository_source_architectures=(
{{- range .packages.ubuntu.repositories }}
  [{{ .name }}]={{ .source_architectures | default .source_architecture | default "" | quote }}
{{- end }}
)
declare -A repository_source_suites=(
{{- range .packages.ubuntu.repositories }}
  [{{ .name }}]={{ .source_suite | default "stable" | quote }}
{{- end }}
)
declare -A repository_components=(
{{- range .packages.ubuntu.repositories }}
  [{{ .name }}]={{ .components | default "main" | quote }}
{{- end }}
)
declare -A repository_marker_files=(
{{- range .packages.ubuntu.repositories }}
  [{{ .name }}]={{ .marker_file | quote }}
{{- end }}
)
declare -A repository_package_names=(
{{- range .packages.ubuntu.repositories }}
  [{{ .name }}]={{ join " " .package_names | quote }}
{{- end }}
)
declare -A repository_command_bindings=(
{{- range .packages.ubuntu.repositories }}
  [{{ .name }}]={{ join " " .command_bindings | quote }}
{{- end }}
)
declare -A command_display_names=(
{{- range .packages.ubuntu.repositories }}
  {{- range .command_labels }}
  [{{ index (splitList ":" .) 0 }}]={{ index (splitList ":" .) 1 | quote }}
  {{- end }}
{{- end }}
)
declare -A repository_adopt_existing=(
{{- range .packages.ubuntu.repositories }}
  [{{ .name }}]={{ .adopt_existing | quote }}
{{- end }}
)
declare -A repository_auxiliary_key_urls=(
{{- range .packages.ubuntu.repositories }}
  [{{ .name }}]={{ .auxiliary_key_url | default "" | quote }}
{{- end }}
)
declare -A repository_auxiliary_key_files=(
{{- range .packages.ubuntu.repositories }}
  [{{ .name }}]={{ .auxiliary_key_file | default "" | quote }}
{{- end }}
)
declare -A repository_auxiliary_policy_urls=(
{{- range .packages.ubuntu.repositories }}
  [{{ .name }}]={{ .auxiliary_policy_url | default "" | quote }}
{{- end }}
)
declare -A repository_auxiliary_policy_files=(
{{- range .packages.ubuntu.repositories }}
  [{{ .name }}]={{ .auxiliary_policy_file | default "" | quote }}
{{- end }}
)

repository_enabled() {
  local repository_name="$1"
  local required_profile="${repository_profiles[$repository_name]}"
  [[ -z "${required_profile}" || "${required_profile}" == "${profile_name}" ]]
}

package_installed() {
  [[ "$(dpkg-query -W -f='${db:Status-Status}' "$1" 2>/dev/null || true)" == "installed" ]]
}

installed_package_available_from_repository() {
  local package_name="$1"
  local repository_name="$2"
  local installed_version
  local candidate_version

  installed_version="$(dpkg-query -W -f='${Version}' "$package_name" 2>/dev/null || true)"
  [[ -n "${installed_version}" ]] || return 1

  # An older package is valid when the official repository can upgrade it;
  # requiring the exact installed version breaks normal apt updates.
  while IFS= read -r candidate_version; do
    dpkg --compare-versions "${candidate_version}" ge "${installed_version}" &&
      return 0
  done < <(
    apt-cache madison "${package_name}" 2>/dev/null | awk -F '|' \
      -v repository_uri="${repository_uris[$repository_name]%/}" '
        {
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
          if (index($3, repository_uri)) print $2
        }
      '
  )
  return 1
}

command_owned_by_package() {
  local command_name="$1"
  local package_name="$2"
  local command_path
  local package_owner

  command_path="$(command -v "${command_name}" 2>/dev/null)" || return 1
  command_path="$(readlink -f "${command_path}")"
  package_owner="$(dpkg-query -S "${command_path}" 2>/dev/null || true)"
  package_owner="${package_owner%%:*}"
  [[ "${package_owner}" == "${package_name}" ]]
}

repository_source() {
  local repository_name="$1"
  local source_format="${repository_source_formats[$repository_name]}"
  local key_file="${repository_key_files[$repository_name]}"
  local repository_uri="${repository_uris[$repository_name]}"

  case "${source_format}" in
    deb822)
cat <<EOF
Types: deb
URIs: ${repository_uri}
Suites: ${repository_source_suites[$repository_name]}
Components: ${repository_components[$repository_name]}
Architectures: ${repository_source_architectures[$repository_name]}
Signed-By: ${key_file}
EOF
      ;;
    deb)
      if [[ "${repository_source_suites[$repository_name]}" != "/" && -n "${repository_components[$repository_name]}" ]]; then
        printf 'deb [arch=%s signed-by=%s] %s %s %s\n' \
          "${repository_source_architectures[$repository_name]}" \
          "${key_file}" \
          "${repository_uri}" \
          "${repository_source_suites[$repository_name]}" \
          "${repository_components[$repository_name]}"
      else
        printf 'deb [arch=%s signed-by=%s] %s %s\n' \
          "${repository_source_architectures[$repository_name]}" \
          "${key_file}" \
          "${repository_uri}" \
          "${repository_source_suites[$repository_name]}"
      fi
      ;;
    *)
      printf 'error: unsupported source format for %s\n' "${repository_name}" >&2
      return 1
      ;;
  esac
}

repository_source_has_expected_content() {
  local repository_name="$1"
  local allow_commented="${2:-false}"
  local source_file="${repository_source_files[$repository_name]}"
  local expected_source
  local existing_source

  [[ -f "${source_file}" ]] || return 1
  expected_source="$(repository_source "${repository_name}")"
  existing_source="$(cat "${source_file}")"
  [[ "${existing_source}" == "${expected_source}" ]] ||
    [[ "${allow_commented}" == "true" && "${existing_source}" == "# ${expected_source}" ]]
}

repository_source_matches() {
  repository_source_has_expected_content "$1"
}

repository_source_is_compatible() {
  local repository_name="$1"
  local source_file="${repository_source_files[$repository_name]}"
  local expected_source
  local existing_source
  local source_without_comments
  local expected_architectures
  local actual_architectures
  local architecture
  local normalized_source

  [[ -f "${source_file}" ]] || return 1
  expected_source="$(repository_source "${repository_name}")"
  existing_source="$(cat "${source_file}")"
  source_without_comments="$(sed '/^[[:space:]]*#/d;/^[[:space:]]*X-[^:]*:[[:space:]]*/d;/^[[:space:]]*$/d' "${source_file}")"
  [[ "${existing_source}" == "${expected_source}" ]] ||
    [[ "${existing_source}" == "# ${expected_source}" ]] ||
    [[ "${source_without_comments}" == "${expected_source}" ]] || {
      [[ "${repository_source_formats[$repository_name]}" == "deb822" ]] || return 1
      expected_architectures="${repository_source_architectures[$repository_name]}"
      actual_architectures="$(awk -F: '$1 == "Architectures" { sub(/^[[:space:]]*/, "", $2); print $2 }' <<<"${source_without_comments}")"
      [[ -n "${expected_architectures}" && -n "${actual_architectures}" ]] || return 1
      for architecture in ${actual_architectures}; do
        [[ " ${expected_architectures} " == *" ${architecture} "* ]] || return 1
      done
      normalized_source="$(awk -v expected="${expected_architectures}" '
        /^Architectures:[[:space:]]*/ { print "Architectures: " expected; next }
        { print }
      ' <<<"${source_without_comments}")"
      [[ "${normalized_source}" == "${expected_source}" ]]
    }
}

remove_legacy_repository_sources() {
  local repository_name="$1"
  local source_file="${repository_source_files[$repository_name]}"
  local legacy_source_file
  local legacy_source_files=()

  read -r -a legacy_source_files <<< "${repository_legacy_source_files[$repository_name]}"
  for legacy_source_file in "${legacy_source_files[@]}"; do
    [[ -n "${legacy_source_file}" && "${legacy_source_file}" != "${source_file}" ]] || continue
    if [[ -e "${legacy_source_file}" ]]; then
      printf 'Removing legacy apt source %s\n' "${legacy_source_file}"
      sudo rm -f "${legacy_source_file}"
    fi
  done
}

repository_key_is_valid() {
  local repository_name="$1"
  local key_file="${repository_key_files[$repository_name]}"
  local fingerprints
  local expected_fingerprint
  local expected_fingerprints=()

  [[ -s "${key_file}" ]] || return 1
  fingerprints="$(gpg --batch --quiet --show-keys --with-colons "${key_file}" 2>/dev/null | awk -F: '$1 == "fpr" { print $10 }')" || return 1
  read -r -a expected_fingerprints <<< "${repository_key_fingerprints[$repository_name]}"
  for expected_fingerprint in "${expected_fingerprints[@]}"; do
    grep -Fqx "${expected_fingerprint}" <<<"${fingerprints}" && return 0
  done
  return 1
}

repository_auxiliary_key_is_valid() {
  local repository_name="$1"
  local key_file="${repository_auxiliary_key_files[$repository_name]}"
  local fingerprints
  local expected_fingerprint
  local expected_fingerprints=()

  [[ -z "${key_file}" ]] && return 0
  [[ -s "${key_file}" ]] || return 1
  fingerprints="$(gpg --batch --quiet --show-keys --with-colons "${key_file}" 2>/dev/null | awk -F: '$1 == "fpr" { print $10 }')" || return 1
  read -r -a expected_fingerprints <<< "${repository_key_fingerprints[$repository_name]}"
  for expected_fingerprint in "${expected_fingerprints[@]}"; do
    grep -Fqx "${expected_fingerprint}" <<<"${fingerprints}" && return 0
  done
  return 1
}

repository_has_installed_package() {
  local repository_name="$1"
  local package_name
  local package_names=()

  read -r -a package_names <<< "${repository_package_names[$repository_name]}"
  for package_name in "${package_names[@]}"; do
    package_installed "${package_name}" && return 0
  done
  return 1
}

repository_has_installed_command() {
  local repository_name="$1"
  local command_binding
  local command_name
  local command_bindings=()

  read -r -a command_bindings <<< "${repository_command_bindings[$repository_name]}"
  for command_binding in "${command_bindings[@]}"; do
    command_name="${command_binding%%:*}"
    command -v "${command_name}" >/dev/null 2>&1 && return 0
  done
  return 1
}

fail_on_unmanaged_repository() {
  local repository_name="$1"
  local source_file="${repository_source_files[$repository_name]}"
  local marker_file="${repository_marker_files[$repository_name]}"
  local label="${repository_labels[$repository_name]}"
  local package_name
  local package_names=()
  local command_binding
  local command_bindings=()
  local command_name
  local command_package

  read -r -a package_names <<< "${repository_package_names[$repository_name]}"
  read -r -a command_bindings <<< "${repository_command_bindings[$repository_name]}"

  if repository_has_installed_package "${repository_name}" && [[ ! -e "${marker_file}" && "${repository_adopt_existing[$repository_name]}" != "true" ]]; then
    printf 'error: %s is installed outside this managed setup; migrate it before continuing\n' "${label}" >&2
    return 1
  fi

  if repository_has_installed_package "${repository_name}" && [[ ! -e "${marker_file}" && "${repository_adopt_existing[$repository_name]}" == "true" ]]; then
    [[ -f "${source_file}" ]] || {
      printf 'error: %s is installed without its official apt repository; migrate it before continuing\n' "${label}" >&2
      return 1
    }
    repository_source_is_compatible "${repository_name}" || {
      printf 'error: %s is installed with a conflicting apt repository; migrate it before continuing\n' "${label}" >&2
      return 1
    }
    printf 'Adopting the existing official %s apt installation\n' "${label}"
  fi

  for package_name in "${package_names[@]}"; do
    if package_installed "${package_name}" && ! installed_package_available_from_repository "${package_name}" "${repository_name}"; then
      printf 'error: installed %s is unavailable from the official stable repository\n' "${package_name}" >&2
      return 1
    fi
  done

  if repository_has_installed_command "${repository_name}"; then
    for command_binding in "${command_bindings[@]}"; do
      command_name="${command_binding%%:*}"
      command_package="${command_binding#*:}"
      if command -v "${command_name}" >/dev/null 2>&1; then
        if ! package_installed "${command_package}"; then
          printf 'error: %s resolves to an unmanaged command\n' "${command_name}" >&2
          return 1
        fi
        if ! command_owned_by_package "${command_name}" "${command_package}"; then
          command_path="$(command -v "${command_name}")"
          printf 'error: %s resolves to %s, which is not owned by the managed package\n' \
            "${command_name}" "${command_path}" >&2
          return 1
        fi
      fi
    done
  fi
}

install_repository_key() {
  local repository_name="$1"
  local key_file="${repository_key_files[$repository_name]}"
  local key_url="${repository_key_urls[$repository_name]}"

  repository_key_is_valid "${repository_name}" && return 0
  printf 'Configuring the %s signing key\n' "${repository_labels[$repository_name]}"
  sudo install -d -m 0755 "$(dirname "${key_file}")"
  case "${repository_key_installs[$repository_name]}" in
    dearmor_tee)
      curl -fsSL "${key_url}" | gpg --dearmor | sudo tee "${key_file}" >/dev/null
      ;;
    dearmor_output)
      curl -fsSL "${key_url}" | sudo gpg --batch --yes --dearmor --output "${key_file}"
      ;;
    raw_tee)
      curl -fsSL "${key_url}" | sudo tee "${key_file}" >/dev/null
      ;;
    *)
      printf 'error: unsupported key installation for %s\n' "${repository_name}" >&2
      return 1
      ;;
  esac
  if [[ -n "${repository_key_modes[$repository_name]}" ]]; then
    sudo chmod "${repository_key_modes[$repository_name]}" "${key_file}"
  fi
}

install_repository_auxiliary_files() {
  local repository_name="$1"
  local auxiliary_key_url="${repository_auxiliary_key_urls[$repository_name]}"
  local auxiliary_key_file="${repository_auxiliary_key_files[$repository_name]}"
  local auxiliary_policy_url="${repository_auxiliary_policy_urls[$repository_name]}"
  local auxiliary_policy_file="${repository_auxiliary_policy_files[$repository_name]}"

  if [[ -n "${auxiliary_policy_file}" && ! -s "${auxiliary_policy_file}" ]]; then
    printf 'Configuring the %s package policy\n' "${repository_labels[$repository_name]}"
    sudo install -d -m 0755 "$(dirname "${auxiliary_policy_file}")"
    curl -fsSL "${auxiliary_policy_url}" | sudo tee "${auxiliary_policy_file}" >/dev/null
  fi
  if [[ -n "${auxiliary_key_file}" ]] && ! repository_auxiliary_key_is_valid "${repository_name}"; then
    sudo install -d -m 0755 "$(dirname "${auxiliary_key_file}")"
    curl -fsSL "${auxiliary_key_url}" | sudo gpg --batch --yes --dearmor --output "${auxiliary_key_file}"
  fi
}

configure_repository() {
  local repository_name="$1"
  local source_file="${repository_source_files[$repository_name]}"
  local marker_file="${repository_marker_files[$repository_name]}"
  local expected_source
  local existing_source=""

  expected_source="$(repository_source "${repository_name}")"
  if [[ -e "${source_file}" ]]; then
    existing_source="$(cat "${source_file}")"
    if ! repository_source_is_compatible "${repository_name}"; then
      printf 'error: %s is not the expected official apt repository\n' "${source_file}" >&2
      return 1
    fi
  fi

  install_repository_key "${repository_name}"
  install_repository_auxiliary_files "${repository_name}"
  if [[ "${existing_source}" != "${expected_source}" ]]; then
    sudo install -d -m 0755 "$(dirname "${source_file}")"
    sudo tee "${source_file}" >/dev/null <<<"${expected_source}"
  fi
  remove_legacy_repository_sources "${repository_name}"
  if [[ ! -e "${marker_file}" ]]; then
    sudo install -d -m 0755 "$(dirname "${marker_file}")"
    sudo touch "${marker_file}"
  fi
}

verify_repository() {
  local repository_name="$1"
  local package_name
  local command_binding
  local command_name
  local expected_package
  local package_names=()
  local command_bindings=()

  [[ -f "${repository_marker_files[$repository_name]}" ]] || {
    printf 'error: %s is not managed by chezmoi\n' "${repository_labels[$repository_name]}" >&2
    return 1
  }
  repository_source_matches "${repository_name}" || {
    printf 'error: %s is not the managed official apt repository\n' "${repository_source_files[$repository_name]}" >&2
    return 1
  }
  read -r -a package_names <<< "${repository_package_names[$repository_name]}"
  read -r -a command_bindings <<< "${repository_command_bindings[$repository_name]}"
  for package_name in "${package_names[@]}"; do
    package_installed "${package_name}" || {
      printf 'error: the managed %s package is not installed\n' "${package_name}" >&2
      return 1
    }
    installed_package_available_from_repository "${package_name}" "${repository_name}" || {
      printf 'error: the installed %s version is unavailable from the official stable repository\n' "${package_name}" >&2
      return 1
    }
  done
  for command_binding in "${command_bindings[@]}"; do
    command_name="${command_binding%%:*}"
    expected_package="${command_binding#*:}"
    command_owned_by_package "${command_name}" "${expected_package}" || {
      printf 'error: the %s command is not owned by the managed package\n' "${command_display_names[$command_name]:-${command_name}}" >&2
      return 1
    }
  done
}
