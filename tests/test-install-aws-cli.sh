#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
installer="$(test_render_template 'home/.chezmoiscripts/run_onchange_after_17-install-aws-cli.sh.tmpl')"
grep -Fq 'awscli-exe-linux-x86_64.zip' "$installer"
grep -Fq 'awscli-exe-linux-x86_64.zip.sig' "$installer"
grep -Fq 'FB5DB77FD5C118B80511ADA8A6310ACC4672475C' "$installer"
grep -Fq 'installed outside this managed setup' "$installer"

# The installer must demand signature verification, not merely be able to do it.
grep -Fq -- '--signature-url "${signature_url}"' "$installer"
grep -Fq -- '--fingerprint "${expected_fingerprint}"' "$installer"
grep -Fq -- '--key-file "${key_file}"' "$installer"

# The committed keyring must be the key that fingerprint pins, or the pin proves
# nothing.
gpg --batch --show-keys --with-colons "$(test_source_file 'home/dot_local/share/aws-cli/aws-cli-team.asc')" |
  awk -F: '$1 == "fpr" { print $10; exit }' |
  grep -Fqx 'FB5DB77FD5C118B80511ADA8A6310ACC4672475C'

printf 'AWS CLI installer checks passed\n'
