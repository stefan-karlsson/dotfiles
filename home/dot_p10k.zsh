# Managed lean Powerlevel10k preset for the Developer Shell, using the free
# Dracula palette while preserving the repository's existing prompt layout.
typeset -g POWERLEVEL9K_MODE=nerdfont-v3
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=false
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs prompt_char)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time background_jobs custom_kubernetes_context time)

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

  p10k segment -f 81 -i '☸' -t "${context}:${namespace}"
}

typeset -g POWERLEVEL9K_CUSTOM_KUBERNETES_CONTEXT='prompt_custom_kubernetes_context'
typeset -g POWERLEVEL9K_CUSTOM_KUBERNETES_CONTEXT_FOREGROUND=81
typeset -g POWERLEVEL9K_CUSTOM_KUBERNETES_CONTEXT_VISUAL_IDENTIFIER_EXPANSION='☸'

typeset -g POWERLEVEL9K_DIR_FOREGROUND=141
typeset -g POWERLEVEL9K_DIR_SHORTEN_STRATEGY=truncate_to_unique
typeset -g POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER=false
typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=80

typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=84
typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=228
typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=228
typeset -g POWERLEVEL9K_VCS_CONFLICTED_FOREGROUND=203
typeset -g POWERLEVEL9K_VCS_LOADING_TEXT=''

typeset -g POWERLEVEL9K_STATUS_OK=false
typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=203
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=228
typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M}'
typeset -g POWERLEVEL9K_TIME_FOREGROUND=61

typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_CONTENT_EXPANSION='❯'
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIINS_CONTENT_EXPANSION='❯'
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_FOREGROUND=84
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIINS_FOREGROUND=203

(( ! $+functions[p10k] )) || p10k reload
