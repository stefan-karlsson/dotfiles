#!/usr/bin/env bash

set -euo pipefail

[[ $# -eq 1 ]] || {
  printf 'usage: %s <rendered-installer>\n' "$0" >&2
  exit 2
}

installer="$1"
grep -Fq 'slack-desktop-4.50.143-amd64.deb' "$installer"
grep -Fq 'obsidian_1.12.7_amd64.deb' "$installer"
grep -Fq 'drawio-amd64-30.3.6.deb' "$installer"
grep -Fq 'manifest expects package' "$installer"
grep -Fq 'discord-1.0.146.deb' "$installer"
grep -Fq 'dbeaver-ce-26.1.2-linux-x86_64.deb' "$installer"
grep -Fq 'devtoys_linux_x64.deb' "$installer"
grep -Fq '|/var/lib/chezmoi/devtoys-stable|||devtoys' "$installer"
grep -Fq 'SlayZone-amd64.deb' "$installer"
grep -Fq '17934df614c13091e85434eb4ba1a4e7f85d29baa5450d57bba0f57acaed9323' "$installer"
grep -Fq '|/var/lib/chezmoi/slayzone-stable|||' "$installer"
grep -Fq '3644e3ef19bcd23db4d17f7c73311b5245429391a2a48b361da93375f59712b0' "$installer"
grep -Fq '4df35ffe4cd7b2652771d9e55fc4e0ad4fb7bf55fbfab303da7c86b83af2dd82' "$installer"
grep -Fq 'a499db1b1e9277e936b2ab978b54c41fe07ace4df57e8586e75c766326e5c562' "$installer"
grep -Fq 'installed outside this managed setup' "$installer"
grep -Fq 'does not publish a manifest checksum' "$installer"
grep -Fq 'resolves to an unmanaged command' "$installer"
grep -Fq 'chmod 0755 "${temporary_dir}"' "$installer"
