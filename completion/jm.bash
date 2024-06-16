#compdef jm

[[ -n ${ZSH_VERSION} ]] && autoload bashcompinit

_jm_cmds=( backlight certinfo keymap offending xlock )
function _jm_completion {
  case $COMP_CWORD in
  1)
    COMPREPLY=($(compgen -W "${_jm_cmds[*]}" "${COMP_WORDS[1]}"))
    ;;
  2)
    if [[ ${COMP_WORDS[1]} == "keymap" ]]; then
      COMPREPLY=($(compgen -W "set toggle" ${COMP_WORDS[2]}))
    fi
    ;;
  *)
    ;;
  esac
}

complete -F _jm_completion jm
