#!/usr/bin/env bash

# Fixture module for the shell test suite.
#
# This is the seam between a rendered script and its test. A test names a source
# template and a Bootstrap profile; the fixture renders it, runs it against
# stubbed commands, and records what it called:
#
#   script + profile → executable + call log
#
# Tests state which script and which profile they mean. The profile is an
# argument, never a substitution into rendered text, and no test invokes chezmoi
# or builds its own stub directory or call log. Application-specific command
# behaviour stays in the test, as the body of a stub.
#
# Three tests do still rewrite one thing in the rendered text: an absolute
# vendor or system path that the script names outright and no test may create
# (test-slay-cli.sh, test-verify-1password-setup.sh,
# test-install-ubuntu-packages.sh). Giving those scripts a root override, the way
# the Slack and Obsidian installers already take one, would close the last gap —
# but that changes shipped scripts, so it is a decision of its own.

# Assigned by test_setup and exported for stub bodies. Declared here so tests
# that follow this file with a `# shellcheck source=fixture.sh` directive
# resolve them.
test_root=''
test_call_log=''

# The chezmoi source root, resolved from this file rather than the working
# directory, so a test renders the same way wherever it is invoked from.
test_source_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# Every Bootstrap profile a script may be rendered under.
test_profiles=(default private company)

# The additional rendering `none` means no profile has been persisted yet — the
# state a machine is in before chezmoi records a choice — where every template
# falls back to the Default profile.
test_no_persisted_profile=none

# The Huntress account key the fixture persists for every profile, so that a test
# can assert what the company profile's installer was handed without repeating
# the literal the configuration below writes.
test_huntress_account_key=test-huntress-account-key

# The work identity the fixture persists for every profile, so that a test can
# assert what the Atlassian CLI and the company Git identity are pointed at
# without repeating the literals the configuration below writes.
test_work_email=work@example.invalid
test_work_gitlab_host=gitlab.example.invalid

test_exit_commands=()

test_setup() {
  (($# == 0)) || {
    printf 'usage: %s takes no arguments; it names its own inputs\n' "$0" >&2
    exit 2
  }

  test_root="$(mktemp -d)"
  trap test_teardown EXIT
  test_call_log="${test_root}/calls.log"
  mkdir -p "${test_root}/bin" "${test_root}/rendered"
  : >"${test_call_log}"
  export test_root test_call_log
}

# Registers shell code to run when the test exits, before the temporary root is
# removed. The fixture owns the exit path, so a test that needs to stop a
# process it started adds to the teardown rather than replacing it.
test_on_exit() {
  test_exit_commands+=("$1")
}

test_teardown() {
  local command

  for command in ${test_exit_commands[@]+"${test_exit_commands[@]}"}; do
    eval "${command}" || true
  done
  rm -rf "${test_root}"
}

# Renders a source template under a Bootstrap profile and prints the path to the
# result. The profile defaults to the Default profile.
#
# The result mirrors the source tree beneath the profile, so two sources sharing
# a basename cannot collide and a checker's diagnostics name both the profile and
# the source they came from.
test_render_template() {
  local source_path="$1"
  local profile="${2:-default}"
  local source_file="${test_source_root}/${source_path}"
  local rendered

  test_assert_profile "${profile}" || return 1
  [[ -f "${source_file}" ]] || {
    printf 'no such source template: %s\n' "${source_path}" >&2
    return 1
  }

  rendered="${test_root}/rendered/${profile}/${source_path%.tmpl}"
  mkdir -p -- "${rendered%/*}"
  chezmoi \
    --config "$(test_profile_config "${profile}")" \
    --config-format toml \
    --no-tty \
    --source "${test_source_root}" \
    execute-template --file "${source_file}" >"${rendered}" || {
    printf 'could not render %s under the %s profile\n' "${source_path}" "${profile}" >&2
    return 1
  }
  chmod 0755 -- "${rendered}"
  printf '%s\n' "${rendered}"
}

# Prints the path to a source file that is read rather than rendered, such as a
# static configuration file the source state ships verbatim.
test_source_file() {
  local source_path="$1"
  local source_file="${test_source_root}/${source_path}"

  [[ -f "${source_file}" ]] || {
    printf 'no such source file: %s\n' "${source_path}" >&2
    return 1
  }
  printf '%s\n' "${source_file}"
}

# Installs a command stub on the fixture PATH. Every call it receives is
# appended to the call log; the optional body supplies the behaviour the script
# under test needs and may use "${test_root}" and the call's arguments. Pass the
# body as `-` to read it from stdin, which keeps a body containing quotes
# readable as a here-document.
test_stub_command() {
  local name="$1"
  local body="${2:-}"
  local stub="${test_root}/bin/${name}"

  [[ "${body}" != '-' ]] || body="$(cat)"

  cat >"${stub}" <<STUB
#!/usr/bin/env bash
set -uo pipefail
printf '%s\n' "${name} \$*" >>${test_call_log@Q}
${body}
STUB
  chmod 0755 -- "${stub}"
}

# Runs a script against the stubbed commands, with its calls recorded. Callers
# add their own environment as a prefix assignment.
test_run_script() {
  local script="$1"
  shift

  PATH="${test_root}/bin:${PATH}" bash "${script}" "$@"
}

test_reset_calls() {
  : >"${test_call_log}"
}

test_assert_called() {
  local expected="$1"

  grep -Fq -- "${expected}" "${test_call_log}" || {
    printf 'expected a call matching %s; the script called:\n' "${expected}" >&2
    test_report_calls
    return 1
  }
}

test_assert_not_called() {
  local unexpected="$1"

  grep -Fq -- "${unexpected}" "${test_call_log}" || return 0
  printf 'unexpected call matching %s; the script called:\n' "${unexpected}" >&2
  test_report_calls
  return 1
}

test_assert_file_contains() {
  local expected="$1"
  local file="$2"

  grep -Fq -- "${expected}" "${file}" || {
    printf 'expected %s to contain %s\n' "${file}" "${expected}" >&2
    return 1
  }
}

test_report_calls() {
  if [[ -s "${test_call_log}" ]]; then
    sed 's/^/  /' "${test_call_log}" >&2
  else
    printf '  (nothing)\n' >&2
  fi
}

test_assert_profile() {
  local profile="$1"
  local known

  [[ "${profile}" != "${test_no_persisted_profile}" ]] || return 0
  for known in "${test_profiles[@]}"; do
    [[ "${profile}" == "${known}" ]] && return 0
  done
  printf 'unknown bootstrap profile: %s\n' "${profile}" >&2
  return 1
}

# Writes the chezmoi configuration that pins the active Bootstrap profile, and
# prints its path. Identity-sensitive values are supplied for every profile so
# that any template renders, whichever profile is active.
test_profile_config() {
  local profile="$1"
  local config="${test_root}/chezmoi-${profile}.toml"
  local known

  [[ -f "${config}" ]] || {
    {
      if [[ "${profile}" != "${test_no_persisted_profile}" ]]; then
        printf '[data.profile]\n'
        printf 'name = "%s"\n' "${profile}"
      fi
      for known in "${test_profiles[@]}"; do
        printf '\n[data.profiles.%s.user]\n' "${known}"
        printf 'name = "Test User"\n'
        printf 'email = "test@example.invalid"\n'
        printf '\n[data.profiles.%s.huntress]\n' "${known}"
        printf 'account_key = "%s"\n' "${test_huntress_account_key}"
        printf '\n[data.profiles.%s.work]\n' "${known}"
        printf 'email = "%s"\n' "${test_work_email}"
        printf 'gitlab_host = "%s"\n' "${test_work_gitlab_host}"
      done
    } >"${config}"
  }
  printf '%s\n' "${config}"
}
