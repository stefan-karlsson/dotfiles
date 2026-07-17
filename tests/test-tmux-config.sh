#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=test-helpers.sh
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_require_args 1 "$@"
config="$1"
grep -Fq 'set -g mouse on' "$config"
grep -Fq 'set -g focus-events on' "$config"
grep -Fq 'set -g default-terminal "tmux-256color"' "$config"
grep -Fq 'terminal-features ",*:RGB"' "$config"
grep -Fq 'set -g mode-keys vi' "$config"
grep -Fq 'set -g set-clipboard external' "$config"
grep -Fq 'set -s copy-command "wl-copy"' "$config"
grep -Fq "run-shell -b '~/.local/share/dracula/tmux/dracula.tmux'" "$config"
grep -Fq 'set -g @dracula-show-powerline true' "$config"
grep -Fq 'new-window -c "#{pane_current_path}"' "$config"
grep -Fq 'copy-mode-vi v send-keys -X begin-selection' "$config"
grep -Fq 'copy-mode-vi y send-keys -X copy-pipe-and-cancel' "$config"
grep -Fq 'copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel' "$config"
