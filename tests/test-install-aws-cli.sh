#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=test-helpers.sh
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_require_args 1 "$@"
installer="$1"
grep -Fq 'awscli-exe-linux-x86_64.zip' "$installer"
grep -Fq 'awscli-exe-linux-x86_64.zip.sig' "$installer"
grep -Fq 'FB5DB77FD5C118B80511ADA8A6310ACC4672475C' "$installer"
grep -Fq 'gpg --batch --verify' "$installer"
grep -Fq 'installed outside this managed setup' "$installer"
