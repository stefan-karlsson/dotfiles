#!/usr/bin/env bash

set -euo pipefail

[[ $# -eq 1 ]] || {
  printf 'usage: %s <rendered-p10k-config>\n' "$0" >&2
  exit 2
}

p10k="$1"

grep -Fqx 'typeset -g POWERLEVEL9K_BACKGROUND=' "${p10k}"
grep -Fqx "  p10k segment -f '#8be9fd' -i '☸' -t \"\${context}:\${namespace}\"" "${p10k}"
grep -Fqx 'typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=' "${p10k}"
grep -Fqx "typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '" "${p10k}"
grep -Fqx 'typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=' "${p10k}"

for segment in DIR STATUS STATUS_OK STATUS_OK_PIPE STATUS_ERROR STATUS_ERROR_PIPE STATUS_ERROR_SIGNAL COMMAND_EXECUTION_TIME BACKGROUND_JOBS CUSTOM_KUBERNETES_CONTEXT TIME; do
  grep -Fqx "typeset -g POWERLEVEL9K_${segment}_BACKGROUND=" "${p10k}"
done
grep -Fqx 'typeset -g POWERLEVEL9K_VCS_{CLEAN,MODIFIED,UNTRACKED,CONFLICTED,LOADING}_BACKGROUND=' "${p10k}"

grep -Fqx "typeset -g POWERLEVEL9K_CUSTOM_KUBERNETES_CONTEXT_FOREGROUND='#8be9fd'" "${p10k}"
grep -Fqx "typeset -g POWERLEVEL9K_DIR_FOREGROUND='#f8f8f2'" "${p10k}"
grep -Fqx "typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND='#50fa7b'" "${p10k}"
grep -Fqx "typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND='#f1fa8c'" "${p10k}"
grep -Fqx "typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND='#ffb86c'" "${p10k}"
grep -Fqx "typeset -g POWERLEVEL9K_VCS_CONFLICTED_FOREGROUND='#ff5555'" "${p10k}"
grep -Fqx "typeset -g POWERLEVEL9K_VCS_LOADING_FOREGROUND='#8be9fd'" "${p10k}"
grep -Fqx "typeset -g POWERLEVEL9K_VCS_ACTIONFORMAT_FOREGROUND='#ff5555'" "${p10k}"
grep -Fqx "typeset -g POWERLEVEL9K_VCS_VISUAL_IDENTIFIER_COLOR='#50fa7b'" "${p10k}"
grep -Fqx "typeset -g POWERLEVEL9K_STATUS_OK_FOREGROUND='#50fa7b'" "${p10k}"
grep -Fqx "typeset -g POWERLEVEL9K_STATUS_OK_PIPE_FOREGROUND='#50fa7b'" "${p10k}"
grep -Fqx "typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND='#ff5555'" "${p10k}"
grep -Fqx "typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_FOREGROUND='#ff5555'" "${p10k}"
grep -Fqx "typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_FOREGROUND='#ff5555'" "${p10k}"
grep -Fqx "typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND='#ffb86c'" "${p10k}"
grep -Fqx "typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND='#ff79c6'" "${p10k}"
grep -Fqx "typeset -g POWERLEVEL9K_TIME_FOREGROUND='#8be9fd'" "${p10k}"

grep -Fqx "typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND='#50fa7b'" "${p10k}"
grep -Fqx "typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND='#ff5555'" "${p10k}"
grep -Fqx 'typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_{VIINS,VICMD,VIVIS,VIOWR}_BACKGROUND=' "${p10k}"

printf 'Powerlevel10k Dracula color checks passed\n'
