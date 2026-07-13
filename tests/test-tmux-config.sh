#!/usr/bin/env bash

set -euo pipefail

[[ $# -eq 1 ]] || {
  printf 'usage: %s <tmux-config>\n' "$0" >&2
  exit 2
}

config="$1"
grep -Fq 'set -g mouse on' "$config"
grep -Fq 'set -g focus-events on' "$config"
grep -Fq 'set -g default-terminal "tmux-256color"' "$config"
grep -Fq 'terminal-features ",*:RGB"' "$config"
grep -Fq "run-shell -b '~/.local/share/dracula/tmux/dracula.tmux'" "$config"
grep -Fq 'set -g @dracula-show-powerline true' "$config"
grep -Fq 'new-window -c "#{pane_current_path}"' "$config"
