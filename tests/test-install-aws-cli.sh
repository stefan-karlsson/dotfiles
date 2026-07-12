#!/usr/bin/env bash

set -euo pipefail

[[ $# -eq 1 ]] || {
  printf 'usage: %s <rendered-installer>\n' "$0" >&2
  exit 2
}

installer="$1"
grep -Fq 'awscli-exe-linux-x86_64.zip' "$installer"
grep -Fq 'awscli-exe-linux-x86_64.zip.sig' "$installer"
grep -Fq 'FB5DB77FD5C118B80511ADA8A6310ACC4672475C' "$installer"
grep -Fq 'gpg --batch --verify' "$installer"
grep -Fq 'installed outside this managed setup' "$installer"
