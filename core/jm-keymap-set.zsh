#! /usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude

check-arg "name" ${1:-}
name=$1

lines=(${(@f)"$(<$JM_CONFIG_HOME/keymap/$name)"}) || exit 1
: ${NOTIFY=dzen2 -sa c -xs 1 -p 1}
NOTIFY=(${(ps: :)NOTIFY})

rc=0
for line in ${lines}; do
  setxkbmap ${(ps: :)line}
  rc=$(( $rc + $? ))
  # setxkbmap -print
done

(( $rc > 0 )) && {
  printf "%s: failed to set keymap $name" $0 | $NOTIFY
  exit 1
}

echo "keymap: $name" | $NOTIFY
