#!/usr/bin/env bash

# The fixture module's own test.
#
# The seam under test: a test names a source template and a Bootstrap profile
# and gets back a runnable script plus a log of the commands it called. Nothing
# here edits rendered text, and nothing reaches into the fixture's internals.

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"

# The marker every profile-aware script renders. Reading it is how this test
# observes which profile the fixture rendered under.
profile_marker() {
  local profile="$1"

  printf 'profile_name="%s"' "${profile}"
}

expect_failure() {
  local description="$1"
  shift

  if "$@" >/dev/null 2>&1; then
    printf 'expected a failure: %s\n' "${description}" >&2
    exit 1
  fi
}

# ── the profile is an argument, not a text substitution ──────────────────────
slay_cli_installer='home/.chezmoiscripts/run_always_after_21-configure-slay-cli.sh.tmpl'

default_render="$(test_render_template "${slay_cli_installer}")"
test_assert_file_contains "$(profile_marker default)" "${default_render}"

private_render="$(test_render_template "${slay_cli_installer}" private)"
test_assert_file_contains "$(profile_marker private)" "${private_render}"

company_render="$(test_render_template "${slay_cli_installer}" company)"
test_assert_file_contains "$(profile_marker company)" "${company_render}"

# Before any profile is persisted, a template falls back to the Default profile.
bare_render="$(test_render_template "${slay_cli_installer}" "${test_no_persisted_profile}")"
test_assert_file_contains "$(profile_marker default)" "${bare_render}"

# Renders under different profiles coexist, so one test can exercise several.
[[ "${default_render}" != "${private_render}" ]]
[[ "${private_render}" != "${company_render}" ]]
test_assert_file_contains "$(profile_marker default)" "${default_render}"

# A rendered script is runnable as-is.
bash -n "${private_render}"

# ── the fixture refuses inputs it cannot render ──────────────────────────────
expect_failure 'unknown profile' test_render_template "${slay_cli_installer}" nonsuch
expect_failure 'missing source template' test_render_template 'home/.chezmoiscripts/nonsuch.sh.tmpl'
expect_failure 'missing source file' test_source_file 'home/nonsuch'

# ── source files that are read rather than rendered ──────────────────────────
tmux_config="$(test_source_file 'home/dot_tmux.conf')"
[[ "${tmux_config}" == /* && -r "${tmux_config}" ]]

# Rendering does not depend on the caller's working directory.
(
  cd /
  cwd_render="$(test_render_template "${slay_cli_installer}" private)"
  test_assert_file_contains "$(profile_marker private)" "${cwd_render}"
)

# ── stubbed commands and the call log ───────────────────────────────────────
test_stub_command quiet
test_stub_command counter 'printf "%s\n" counted >>"${test_root}/counted"'
test_stub_command refuser 'exit 7'
# A body read from stdin may contain quotes of either kind.
test_stub_command quoter - <<'STUB'
if [[ "$1" == 'both' ]]; then
  printf '%s\n' "it's \"quoted\"" >"${test_root}/quoted"
fi
STUB

cat >"${test_root}/subject.sh" <<'SUBJECT'
#!/usr/bin/env bash
set -euo pipefail
quiet one two
counter
quoter both
refuser || printf 'refuser exited %s\n' "$?"
SUBJECT

test_run_script "${test_root}/subject.sh" >"${test_root}/subject.out"

test_assert_called 'quiet one two'
test_assert_called 'counter'
test_assert_not_called 'quiet three'
test_assert_file_contains 'refuser exited 7' "${test_root}/subject.out"
test_assert_file_contains 'counted' "${test_root}/counted"
test_assert_file_contains 'it'"'"'s "quoted"' "${test_root}/quoted"

# Stubs answer the script under test, not the test's own shell.
expect_failure 'stub reachable outside the fixture PATH' command -v quiet

# Arguments reach the script under test.
cat >"${test_root}/echoes.sh" <<'ECHOES'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*"
ECHOES
[[ "$(test_run_script "${test_root}/echoes.sh" alpha beta)" == 'alpha beta' ]]

# ── the call-log assertions fail when they should ────────────────────────────
expect_failure 'assert_called on a call that never happened' test_assert_called 'never-called'
expect_failure 'assert_not_called on a logged call' test_assert_not_called 'quiet one two'

test_reset_calls
test_assert_not_called 'quiet one two'
expect_failure 'assert_called after the log was reset' test_assert_called 'counter'

# ── the fixture owns the exit path ──────────────────────────────────────────
marker="${test_root}/torn-down"
child_root="$(
  bash -c '
    set -euo pipefail
    . "$1/fixture.sh"
    test_setup
    test_on_exit "printf ran >\"$2\""
    printf "%s\n" "${test_root}"
  ' bash "$(dirname -- "${BASH_SOURCE[0]}")" "${marker}"
)"
test_assert_file_contains 'ran' "${marker}"
[[ ! -e "${child_root}" ]]

printf 'Test fixture checks passed\n'
