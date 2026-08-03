#!/usr/bin/env bash

# Checks every program in the source state, plus the suite that tests them.
#
# The inventory is discovered from the source tree rather than kept in step by
# hand: a new script under home/.chezmoiscripts, a new command under
# home/dot_local/bin, or a new test is checked the moment it is committed. A
# source that looks like a program but matches no rule below is an error, so a
# new location cannot go unchecked either.
#
# Every program is rendered under every Bootstrap profile, and under none at all,
# because a profile overlay can change what a template produces. Identical
# renderings are checked once, and a checker that accepts a list of files is
# given all of them at once, because process startup dominates this pass.
#
# Rendered output is checked at shellcheck's default severity; the repository's
# stricter .shellcheckrc governs the shell sources that live in the tree.

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"

failures=()

check() {
  local label="$1"
  local output
  shift

  if output="$("$@" 2>&1)"; then
    return 0
  fi
  failures+=("${label}")
  printf '\nFAIL %s\n' "${label}" >&2
  printf '%s\n' "${output}" >&2
}

# Complete scripts carry a shebang; fragments are included into one, so they are
# checked as bash without.
scripts=()
shell_fragments=()
python_fragments=()
zsh_configs=()

mapfile -t sources < <(
  cd -- "${test_source_root}" &&
    find home \
      \( -path 'home/.chezmoiscripts/*' \
        -o -path 'home/dot_local/bin/*' \
        -o -name '*.sh' \
        -o -name '*.sh.tmpl' \
        -o -name '*.py' \
        -o -path 'home/dot_zshrc.tmpl' \
        -o -path 'home/dot_p10k.zsh' \) \
      -type f -print | LC_ALL=C sort
)

# Discovery runs in a process substitution, so its failure would otherwise look
# like a source tree with nothing in it.
((${#sources[@]} > 0)) || {
  printf 'no programs found under home/; discovery failed\n' >&2
  exit 1
}

declare -A checked_renderings=()
for source_path in "${sources[@]}"; do
  case "${source_path}" in
    home/.chezmoiscripts/* | home/dot_local/bin/*) bucket=scripts ;;
    home/.chezmoitemplates/*.sh) bucket=shell_fragments ;;
    home/.chezmoitemplates/*.py) bucket=python_fragments ;;
    home/dot_zshrc.tmpl | home/dot_p10k.zsh) bucket=zsh_configs ;;
    *)
      printf 'unclassified source: %s\n' "${source_path}" >&2
      printf 'add a rule above so it cannot go unchecked\n' >&2
      exit 1
      ;;
  esac
  declare -n bucket_files="${bucket}"

  for profile in "${test_no_persisted_profile}" "${test_profiles[@]}"; do
    if ! rendered="$(test_render_template "${source_path}" "${profile}")"; then
      failures+=("render ${source_path} under ${profile}")
      continue
    fi
    # Keyed per source, so that a profile which changes nothing is skipped while
    # two sources that happen to render alike are still each checked by name.
    digest="${source_path}:$(sha256sum "${rendered}" | cut -d ' ' -f 1)"
    [[ -z "${checked_renderings[${digest}]:-}" ]] || continue
    checked_renderings["${digest}"]=1
    bucket_files+=("${rendered}")
  done
  unset -n bucket_files
done

# `bash -n` takes one script; any further argument becomes a positional
# parameter of it rather than a second file to check, so syntax checks run one
# file at a time. shellcheck does take a list.
check_syntax() {
  local file

  for file in "$@"; do
    check "bash -n ${file#"${test_root}/rendered/"}" bash -n "${file}"
  done
}

check_syntax "${scripts[@]}" "${shell_fragments[@]}"
((${#scripts[@]} == 0)) ||
  check 'rendered scripts: shellcheck' shellcheck "${scripts[@]}"
((${#shell_fragments[@]} == 0)) ||
  check 'rendered shell fragments: shellcheck' shellcheck -s bash "${shell_fragments[@]}"
((${#python_fragments[@]} == 0)) ||
  check 'rendered python fragments: py_compile' python3 -m py_compile "${python_fragments[@]}"
if ((${#zsh_configs[@]} > 0)); then
  if command -v zsh >/dev/null 2>&1; then
    # zsh -n takes one script; further arguments become its positional parameters.
    for zsh_config in "${zsh_configs[@]}"; do
      check "rendered zsh configuration: ${zsh_config##*/}" zsh -n "${zsh_config}"
    done
  else
    printf 'warning: zsh is unavailable; skipped %s zsh configuration checks\n' \
      "${#zsh_configs[@]}" >&2
  fi
fi

# The bootstrap script and the test suite live in the tree, so they are checked
# where the repository's .shellcheckrc applies.
check 'install.sh' shellcheck "${test_source_root}/install.sh"

# The suite is checked at warning severity rather than the .shellcheckrc's
# `severity=style`, which it does not yet satisfy: the outstanding findings are
# style-only, overwhelmingly SC2250 (brace every expansion, including "$1"), and
# clearing ~500 of them across the suite is its own change. External sources are
# followed and resolved against each test's own directory so that the fixture's
# state is visible to the tests that use it.
check 'tests' shellcheck -x -P SCRIPTDIR --severity=warning "${test_source_root}"/tests/*.sh

if ((${#failures[@]} > 0)); then
  printf '\n%s source check(s) failed:\n' "${#failures[@]}" >&2
  printf '  %s\n' "${failures[@]}" >&2
  exit 1
fi

printf 'Checked %s sources under %s profiles and none (%s distinct renderings)\n' \
  "${#sources[@]}" "${#test_profiles[@]}" "${#checked_renderings[@]}"
