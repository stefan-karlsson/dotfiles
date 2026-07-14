#!/usr/bin/env bash

set -euo pipefail

config="$1"
diff_section="$(sed -n '/^\[diff\]$/,/^\[/p' "${config}")"

grep -Fqx 'command = "diff"' <<<"${diff_section}"
grep -Fqx 'args = ["--unified"]' <<<"${diff_section}"
if grep -Fq 'args = ["--wait", "--diff"]' <<<"${diff_section}"; then
  printf 'the diff command must not wait for an editor window\n' >&2
  exit 1
fi

printf 'Chezmoi diff configuration checks passed\n'
