#!/usr/bin/env bash

# Runs every test in the suite.
#
# The list comes from the tree, so a new tests/test-*.sh runs as soon as it is
# committed. Each test names its own inputs through the fixture, so there is
# nothing to pass here.

set -euo pipefail

tests_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
failures=()
passed=0

for test_file in "${tests_dir}"/test-*.sh; do
  name="$(basename -- "${test_file}")"
  if output="$(bash "${test_file}" 2>&1)"; then
    printf 'ok   %s\n' "${name}"
    passed=$((passed + 1))
  else
    printf 'FAIL %s\n' "${name}"
    printf '%s\n' "${output}" | sed 's/^/     /'
    failures+=("${name}")
  fi
done

if ((${#failures[@]} > 0)); then
  printf '\n%s of %s tests failed:\n' \
    "${#failures[@]}" "$((passed + ${#failures[@]}))" >&2
  printf '  %s\n' "${failures[@]}" >&2
  exit 1
fi

printf '\nAll %s tests passed\n' "${passed}"
