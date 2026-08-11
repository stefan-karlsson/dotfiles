#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"
installer="$(test_render_template 'home/.chezmoiscripts/run_onchange_before_12-install-ubuntu-deb-artifacts.sh.tmpl')"
grep -Fq 'k9s_linux_amd64.deb' "$installer"
grep -Fq '56b539a509eb2d6357cf4f575ed38c089f0e4880c95f79a70196b54f14954908' "$installer"
grep -Fq 'docker-desktop-amd64.deb' "$installer"
grep -Fq '4d27b37bfe3f5fceafdf9ffd1db07006d3388e823567dc64c8aa04a6f5c738d9' "$installer"
grep -Fq '|/var/lib/chezmoi/docker-desktop-stable|||' "$installer"
grep -Fq 'slack-desktop-4.50.143-amd64.deb' "$installer"
grep -Fq 'obsidian_1.12.7_amd64.deb' "$installer"
grep -Fq 'drawio-amd64-30.3.6.deb' "$installer"
grep -Fq 'manifest expects package' "$installer"
grep -Fq 'discord-1.0.146.deb' "$installer"
grep -Fq 'dbeaver-ce-26.1.4-linux-x86_64.deb' "$installer"
grep -Fq 'devtoys_linux_x64.deb' "$installer"
grep -Fq '|/var/lib/chezmoi/devtoys-stable|||devtoys|default|' "$installer"
grep -Fq 'SlayZone-amd64.deb' "$installer"
grep -Fq '17934df614c13091e85434eb4ba1a4e7f85d29baa5450d57bba0f57acaed9323' "$installer"
grep -Fq '|/var/lib/chezmoi/slayzone-stable|||' "$installer"
grep -Fq '3644e3ef19bcd23db4d17f7c73311b5245429391a2a48b361da93375f59712b0' "$installer"
grep -Fq '4df35ffe4cd7b2652771d9e55fc4e0ad4fb7bf55fbfab303da7c86b83af2dd82' "$installer"
grep -Fq '5f7a9b0bf726175a7d02cd8f093807829241ed21f23dca6557326e8764a35a32' "$installer"
grep -Fq 'installed outside this managed setup' "$installer"
grep -Fq 'publishes no checksum or signature' "$installer"
grep -Fq 'resolves to an unmanaged command' "$installer"
# Staged artifacts must stay traversable by the _apt account apt drops to.
grep -Fq 'chmod 0755 "${temporary_dir}"' "$installer"
# Every artifact is fetched through the shared verification interface.
grep -Fq -- '--sha256 "${expected_sha256}"' "$installer"

# GitLab's CLI belongs to the company laptop, carries the checksum from its own
# release, and must not be adopted from the Snap that also publishes it.
grep -Fq 'glab_1.112.0_linux_amd64.deb|71eb77a13dd57f3add103e979b20dbd9f4730bcaf9501ae2e8ac14cb4585c707|/var/lib/chezmoi/glab-stable|glab||glab|company' "$installer"

# The CLI half of DevToys is installed on every laptop, as the application is.
grep -Fq 'devtoys.cli_linux_x64.deb' "$installer"
grep -Fq '|devtoys.cli|default|' "$installer"

# Compass is installed on every laptop, and MongoDB signs it rather than
# publishing a checksum: its signature is checked against MongoDB's own key, which
# is admitted only on the pinned fingerprint.
grep -Fq 'mongodb-compass_1.49.14_amd64.deb' "$installer"
grep -Fq '|mongodb-compass|default|' "$installer"
grep -Fq 'mongodb-compass_1.49.14_amd64.deb.sig|https://pgp.mongodb.com/compass.asc|AB1B92FFBE0D3740425DAD16A8130EC3F9F5F923' "$installer"
grep -Fq -- '--signature-url "${signature_url}"' "$installer"
grep -Fq -- '--fingerprint "${signature_key_fingerprint}"' "$installer"
grep -Fq -- 'fetch_artifact_text --url "${signature_key_url}"' "$installer"
