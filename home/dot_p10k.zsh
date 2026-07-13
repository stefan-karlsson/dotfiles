# Managed lean Powerlevel10k preset for the Developer Shell, using the free
# Dracula palette while preserving the repository's existing prompt layout.
typeset -g POWERLEVEL9K_MODE=nerdfont-v3
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=false
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs prompt_char)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time background_jobs custom_kubernetes_context time)

# Keep every segment transparent so the prompt uses the Dracula terminal background instead
# of Powerlevel10k's default blue, black, and white segment fills.
typeset -g POWERLEVEL9K_BACKGROUND=
typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=
typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '
typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=
typeset -g POWERLEVEL9K_ICON_PADDING=none

# Show only the locally selected kubeconfig context and namespace. kubectl's
# config subcommands do not contact a cluster, and failures are intentionally
# hidden so a missing or unavailable kubeconfig never breaks the prompt.
function prompt_custom_kubernetes_context() {
  (( $+commands[kubectl] )) || return

  local context namespace
  context="$(kubectl config current-context 2>/dev/null)" || return
  [[ -n "${context}" ]] || return
  namespace="$(kubectl config view --minify -o 'jsonpath={..namespace}' 2>/dev/null)"
  [[ -n "${namespace}" ]] || namespace=default

  p10k segment -f '#8be9fd' -i '☸' -t "${context}:${namespace}"
}

typeset -g POWERLEVEL9K_CUSTOM_KUBERNETES_CONTEXT='prompt_custom_kubernetes_context'
typeset -g POWERLEVEL9K_CUSTOM_KUBERNETES_CONTEXT_BACKGROUND=
typeset -g POWERLEVEL9K_CUSTOM_KUBERNETES_CONTEXT_FOREGROUND='#8be9fd'
typeset -g POWERLEVEL9K_CUSTOM_KUBERNETES_CONTEXT_VISUAL_IDENTIFIER_EXPANSION='☸'

typeset -g POWERLEVEL9K_DIR_BACKGROUND=
typeset -g POWERLEVEL9K_DIR_FOREGROUND='#f8f8f2'
typeset -g POWERLEVEL9K_DIR_SHORTEN_STRATEGY=truncate_to_unique
typeset -g POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER=false
typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=80

typeset -g POWERLEVEL9K_VCS_{CLEAN,MODIFIED,UNTRACKED,CONFLICTED,LOADING}_BACKGROUND=
typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND='#50fa7b'
typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND='#f1fa8c'
typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND='#ffb86c'
typeset -g POWERLEVEL9K_VCS_CONFLICTED_FOREGROUND='#ff5555'
typeset -g POWERLEVEL9K_VCS_LOADING_FOREGROUND='#8be9fd'
typeset -g POWERLEVEL9K_VCS_ACTIONFORMAT_FOREGROUND='#ff5555'
typeset -g POWERLEVEL9K_VCS_VISUAL_IDENTIFIER_COLOR='#50fa7b'
typeset -g POWERLEVEL9K_VCS_LOADING_TEXT=''

typeset -g POWERLEVEL9K_STATUS_BACKGROUND=
typeset -g POWERLEVEL9K_STATUS_OK_BACKGROUND=
typeset -g POWERLEVEL9K_STATUS_OK_PIPE_BACKGROUND=
typeset -g POWERLEVEL9K_STATUS_ERROR_BACKGROUND=
typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_BACKGROUND=
typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_BACKGROUND=
typeset -g POWERLEVEL9K_STATUS_OK=false
typeset -g POWERLEVEL9K_STATUS_OK_FOREGROUND='#50fa7b'
typeset -g POWERLEVEL9K_STATUS_OK_PIPE_FOREGROUND='#50fa7b'
typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND='#ff5555'
typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_FOREGROUND='#ff5555'
typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_FOREGROUND='#ff5555'
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND=
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND='#ffb86c'
typeset -g POWERLEVEL9K_BACKGROUND_JOBS_BACKGROUND=
typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND='#ff79c6'
typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M}'
typeset -g POWERLEVEL9K_TIME_BACKGROUND=
typeset -g POWERLEVEL9K_TIME_FOREGROUND='#8be9fd'

typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_CONTENT_EXPANSION='❯'
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIINS_CONTENT_EXPANSION='❯'
typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_{VIINS,VICMD,VIVIS,VIOWR}_BACKGROUND=
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND='#50fa7b'
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND='#ff5555'

(( ! $+functions[p10k] )) || p10k reload
