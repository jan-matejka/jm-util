#compdef jm

[[ -n ${ZSH_VERSION} ]] && autoload bashcompinit

_jm_cmds=(
  backlight
  certinfo
  claude
  container-env-setup
  exec
  find-git
  gh
  keymap
  lcpp
  offending
  p
  tmux-autosession
  version
  xlock
)

function _jm_completion {
  case $COMP_CWORD in
  1)
    COMPREPLY=($(compgen -W "${_jm_cmds[*]}" -- "${COMP_WORDS[1]}"))
    ;;
  2)
    if [[ ${COMP_WORDS[1]} == "keymap" ]]; then
      COMPREPLY=($(compgen -W "set toggle" -- "${COMP_WORDS[2]}"))
    elif [[ ${COMP_WORDS[1]} == "backlight" ]]; then
      COMPREPLY=($(compgen -W "--max" -- "${COMP_WORDS[2]}"))
    elif [[ ${COMP_WORDS[1]} == "certinfo" ]]; then
      COMPREPLY=($(compgen -W "-h -p" -- "${COMP_WORDS[2]}"))
    elif [[ ${COMP_WORDS[1]} == "claude" ]]; then
      COMPREPLY=($(compgen -W "-p --primary --no-workdir" -- ${COMP_WORDS[2]}))
    elif [[ ${COMP_WORDS[1]} == "gh" ]]; then
      COMPREPLY=($(compgen -W "pls-upi move-upi" -- "${COMP_WORDS[2]}"))
    elif [[ ${COMP_WORDS[1]} == "p" ]]; then
      COMPREPLY=($(compgen -W "debug name" -- "${COMP_WORDS[2]}"))
    fi
    ;;
  3)
    if [[ ${COMP_WORDS[2]} == "move-upi" ]]; then
      COMPREPLY=($(compgen -W "-n" -- "${COMP_WORDS[2]}"))
    elif [[ ${COMP_WORDS[1]} == "p" ]]; then
      if [[ ${COMP_WORDS[2]} == "debug" ]]; then
        COMPREPLY=($(compgen -W "$(podman ps --format '{{.ID}} {{.Names}}' --filter 'status=running')" -- "${COMP_WORDS[3]}"))
      fi
    fi
    ;;
  *)
    ;;
  esac
}

complete -F _jm_completion jm
