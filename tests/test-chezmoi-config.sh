#!/usr/bin/env bash

# SC2154: the fixture assigns the source root and temporary root.
# shellcheck disable=SC2154
set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
config="$(test_source_file 'home/.chezmoi.toml.tmpl')"
diff_section="$(sed -n '/^\[diff\]$/,/^\[/p' "${config}")"

# An external file-comparison tool cannot represent an entry that does not exist
# yet, and an editor invoked here would block the terminal.
if grep -Fq 'command' <<<"${diff_section}"; then
  printf 'the diff configuration must not name an external command\n' >&2
  exit 1
fi

# The state a new laptop is in: nothing the source state manages exists yet, so
# every managed directory is still to be created.
rendered_config="${test_root}/chezmoi.toml"
chezmoi --config /dev/null --config-format toml execute-template --init \
  --promptChoice 'Which bootstrap profile should be active?=default' \
  --promptString 'Git author name=Test User' \
  --promptString 'Git author email=test@example.invalid' \
  <"${config}" >"${rendered_config}"

destination="${test_root}/destination"
mkdir -p "${destination}"
if ! chezmoi --config "${rendered_config}" --config-format toml --no-tty \
  --source "${test_source_root}" --destination "${destination}" diff \
  >"${test_root}/diff.out" 2>&1; then
  printf 'chezmoi diff failed against a destination where nothing is applied yet:\n' >&2
  tail -5 "${test_root}/diff.out" >&2
  exit 1
fi
if grep -Fq 'No such file or directory' "${test_root}/diff.out"; then
  printf 'chezmoi diff reported a missing path of its own making:\n' >&2
  grep -F 'No such file or directory' "${test_root}/diff.out" >&2
  exit 1
fi
test_assert_file_contains 'b/.config/1Password/ssh/agent.toml' "${test_root}/diff.out"

printf 'Chezmoi diff configuration checks passed\n'
