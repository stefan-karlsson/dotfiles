#!/usr/bin/env bash

# Checks every program in the source state, plus the suite that tests them.
#
# The inventory is discovered from the source tree rather than kept in step by
# hand: a new script under home/.chezmoiscripts, a new command under
# home/dot_local/bin, or a new test is checked the moment it is committed. A
# source that looks like a program but matches no rule below is an error, so a
# new location cannot go unchecked either.
#
# Every program is rendered under every Bootstrap profile, and under none at all;
# a profile overlay changes what a template produces. Identical renderings are
# checked once, and a checker that accepts a list of files is given all of them at
# once.
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
# checked as bash without. A vendor script is neither: it is a third-party
# program this repository ships verbatim; what runs as root is what the vendor
# published. Its style is not ours to correct and shellcheck is not run over it.
# It is checked for syntax, where it lives rather than rendered: a wrapper reads
# it raw rather than as a template.
scripts=()
shell_fragments=()
vendor_scripts=()
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

# Discovery runs in a process substitution. Its failure looks like a source tree
# with nothing in it.
((${#sources[@]} > 0)) || {
  printf 'no programs found under home/; discovery failed\n' >&2
  exit 1
}

declare -A checked_renderings=()
for source_path in "${sources[@]}"; do
  case "${source_path}" in
    home/.chezmoiscripts/* | home/dot_local/bin/*) bucket=scripts ;;
    home/.chezmoitemplates/vendor/*.sh) bucket=vendor_scripts ;;
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

  # A vendor script is read raw rather than rendered. Rendering it here checks
  # something no apply produces.
  if [[ "${bucket}" == vendor_scripts ]]; then
    bucket_files+=("${test_source_root}/${source_path}")
    unset -n bucket_files
    continue
  fi

  for profile in "${test_no_persisted_profile}" "${test_profiles[@]}"; do
    if ! rendered="$(test_render_template "${source_path}" "${profile}")"; then
      failures+=("render ${source_path} under ${profile}")
      continue
    fi
    # Keyed per source. A profile that changes nothing is skipped, and two sources
    # that render alike are each checked by name.
    digest="${source_path}:$(sha256sum "${rendered}" | cut -d ' ' -f 1)"
    [[ -z "${checked_renderings[${digest}]:-}" ]] || continue
    checked_renderings["${digest}"]=1
    bucket_files+=("${rendered}")
  done
  unset -n bucket_files
done

# `bash -n` takes one script; any further argument becomes a positional
# parameter of it rather than a second file to check, and syntax checks run one
# file at a time. shellcheck does take a list.
check_syntax() {
  local file
  local label

  for file in "$@"; do
    label="${file#"${test_root}/rendered/"}"
    check "bash -n ${label#"${test_source_root}/"}" bash -n "${file}"
  done
}

check_syntax "${scripts[@]}" "${shell_fragments[@]}" \
  ${vendor_scripts[@]+"${vendor_scripts[@]}"}
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
# followed and resolved against each test's own directory, which makes the
# fixture's state visible to the tests that use it.
check 'tests' shellcheck -x -P SCRIPTDIR --severity=warning "${test_source_root}"/tests/*.sh

if ((${#failures[@]} > 0)); then
  printf '\n%s source check(s) failed:\n' "${#failures[@]}" >&2
  printf '  %s\n' "${failures[@]}" >&2
  exit 1
fi

printf 'Checked %s sources under %s profiles and none (%s distinct renderings)\n' \
  "${#sources[@]}" "${#test_profiles[@]}" "${#checked_renderings[@]}"
