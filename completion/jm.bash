#compdef yt

[[ -n ${ZSH_VERSION} ]] && autoload bashcompinit

_yt_cmds=( backlight certinfo keymap offending xlock )
function _yt_completion {
  case $COMP_CWORD in
  1)
    COMPREPLY=($(compgen -W "${_yt_cmds[*]}" "${COMP_WORDS[1]}"))
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

complete -F _yt_completion yt
