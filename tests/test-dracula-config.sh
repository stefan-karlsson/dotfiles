#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=test-helpers.sh
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_require_args 1 "$@"
installer="$1"
grep -Fq 'https://github.com/dracula/gtk.git' "$installer"
grep -Fq 'https://github.com/dracula/tmux.git' "$installer"
grep -Fq 'https://github.com/dracula/wallpaper.git' "$installer"
grep -Fq 'gsettings set org.gnome.desktop.interface gtk-theme Dracula' "$installer"
grep -Fq 'gsettings set org.gnome.desktop.wm.preferences theme Dracula' "$installer"
grep -Fq 'gsettings set org.gnome.desktop.background picture-uri-dark' "$installer"
grep -Fq 'picture-options zoom' "$installer"
grep -Fq 'diff --quiet' "$installer"

printf 'Dracula installer checks passed\n'
